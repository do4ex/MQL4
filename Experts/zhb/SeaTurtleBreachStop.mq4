#property copyright "zouhaibo"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#include <CommonService.mqh>
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
//  海龟交易系统的实现，包括短时突破，长时间保护，定时退出，使用限价停止单
// 短期突破 上次突破盈利，下次就略过，
// 长期突破，不设置保护性
// 定时退出，把交易让给时间
// 谨记，因为大多数交易都是亏损的，所有盈利的时候必须不能干扰
// 订单状态  blank=空仓 ，blank_profit上一单盈利的空仓，half半仓，full满仓
//enum ORDER_STATUS { 1=BLANK,2=BLANK_PROFIT,3=HALF,4=FULL};
enum RUN_MODE_EUNM {NormalMode,BuyOnlyMode, SellOnlyMode};
const input RUN_MODE_EUNM RUN_MODE=NormalMode;


// 满仓数量
input int fullNum = 4;
// 交易币对
string symbol = Symbol();
//input string symbol = Symbol();
// 突破
input int openDayVal = 55;
// 价格跌破 10日最低即退出
input int exitTakeProfitDay = 20;
// atr 取值范围
input int atrValRange = 20;
// 是否进行保护性，如果开启，那么protectedOpenDayVal 将生效
input bool protectedFlag = false;
// 如果上一次盈利，这一次则不交易，但是又突破了55日的，那么进行加仓
input int protectedOpenDayVal = 55;
bool protectedStartFlag = false;
input int protectedExitTakeProfitDay = 20;
// 加仓系数，每次加 addPosition * atr值
input double addPosition = 0.5;
// 退出策略 价格下跌 exitStopLossRate * atr 就进行退出
input double exitStopLossRate = 2;
// k线间隔
input int period = PERIOD_D1;
// 定时退出, 是否开启定时退出
input bool openTimingExit = false;
// 定时退出间隔
input int timingExit = 60;
const string COMMENT = "STBS";
int magicNumber = 10001;

// 下单量, 根据自己资金量，人工控制下单量
extern double myLots = 0.01;

// 是否开启自动下单资金控制, 默认不开启，注意跑历史数据一般需要开启
extern bool lotsAutoIncrement = false;

// 下单基准，如果 1000 对应 0.01， 2000 对应0.02
input double moneyUnitRate = 100000;

// 停止级别，当账户为 ecn账户时的挂单距离
input double defaultStopLevel = 50;

// 常量 0 没有所有订单，1没有市价单有限价单，2=上一次盈利的突破没有限价单，3=半仓， 4=满仓
const int INIT =0, INIT_PROFIT =1 ,BLANK =2, HALF=3, FULL = 4;

double atrVal = 0;

Order buyOrders[];
// 买单 限价停止
Order buyStopOrders[];
//卖单
Order sellOrders[];

Order sellStopOrders[];

Order historyOrders[];

// 订单方向
int orderType;
// 上一次订单组
int lastTicket = 0 ;

int orderStatus;


bool initAtrVal(int bar = 1) {

	double value = iATR(symbol,period,atrValRange,bar);
    atrVal = NormalizeDouble(value,5);
	printf("initAtrVal value: %g,   atrVal:  %g ",  value,  atrVal);
	if (!Math:: gt(atrVal,0)){
        printf("init AtrVal failture atrVal: %g",atrVal);
        // 初始化atrVal失败，终止程序运行
        ExpertRemove();

    }
    return Math:: gt(atrVal,0);
}

double getHighPrice(int inteval){
    int highBar = iHighest(symbol,period,MODE_HIGH,inteval,0);
    return iHigh(symbol,period,highBar);
}
   // 获取最低价格
double getLowPrice(int inteval){
    int lowBar = iLowest(symbol,period,MODE_LOW,inteval,0);
    double lowPrice = iLow(symbol,period,lowBar);
    return lowPrice;
}

Order getLastOrder() {
      // 拿到最后的订单
    return ArraySize(buyOrders) >0 ? buyOrders[ArraySize(buyOrders) -1] : sellOrders[ArraySize(sellOrders) -1];
}

Order getFirstOrder() {
      // 拿到最后的订单
    return ArraySize(buyOrders) >0 ? buyOrders[0] : sellOrders[0];
}


 // 计算开仓手数
double calcLots() {

	// 计算资金，采用累加原则

	if(!lotsAutoIncrement){
		return myLots;
	}

	double tempLots = NormalizeDouble(AccountBalance()/ moneyUnitRate,3);

	int temp = tempLots * 100;

	if(tempLots > myLots){
//				printf("current accountBalance:  %g   temp: %i   tempLots: %g ",AccountBalance() ,temp, tempLots);
		myLots = temp * 0.01;
	}

	return myLots;
}

// 允许的赢利点
double availableTp(double tp, int orderType) {

	double stopLevel = Trade::stopLevel(symbol);
	if(Math::eq(stopLevel,0)){
		stopLevel = defaultStopLevel;
	}
	if(orderType == OP_BUY){
		// 最小盈利价格
		double minTp = Math::add(Trade::bid(symbol), stopLevel * Trade::point(symbol) *2);
		return tp < minTp ? minTp : tp;
	}
	// 卖单 最大盈利价格
	 double maxTp = Math::sub(Trade::ask(symbol), stopLevel *Trade::point(symbol) *2);
     return tp > maxTp ? maxTp : tp;
}

// 当价格差距 大于 （Trade::stopLevel(symbol)*Trade::point(symbol) *4）时候，改变价格

bool needChangePrice(double dscPrice,double openPrice) {

	double stopLevel = Trade::stopLevel(symbol);
    if(Math::eq(stopLevel,0)){
        stopLevel = defaultStopLevel;
    }
	double val = MathAbs(dscPrice) - MathAbs(openPrice);
	double range = stopLevel * Trade::point(symbol) * 2;
	return MathAbs(val) > range;
}

// 允许的止损点
double availableSl(double sl,int orderType){

	double stopLevel = Trade::stopLevel(symbol);
    if(Math::eq(stopLevel,0)){
        stopLevel = defaultStopLevel;
    }
	if(orderType == OP_SELL){
		// 最大止损价格
        double maxSl = Math::add(Trade::ask(symbol), stopLevel*Trade::point(symbol)*2);
        return sl < maxSl ? maxSl : sl;
    }
	//买单 最小止损价格
	 double minSl = Math::sub(Trade::bid(symbol), stopLevel*Trade::point(symbol)*2);
     return sl < minSl ? sl : minSl;
}



class Handle {

	public:
		virtual bool support() {
			return false;
		}
		virtual void execute() {
			printf("Handle.execute");
		}
};
// 初始化
class InitHandle: public Handle {

	public:
	    bool support() {
	        return orderStatus == INIT;
		}
		void execute() {

			// 有挂单，的情况，

			protectedStartFlag = false;

			// 下限价单
			//  buyStop(string symbol,double price, double lots, int magicNumber,string COMMENT)
			//
			if(RUN_MODE == BuyOnlyMode || RUN_MODE == NormalMode){
				double highPrice = getHighPrice(openDayVal);
				highPrice = NormalizeDouble(highPrice,MarketInfo(symbol,MODE_DIGITS));
				Trade:: buyStop(symbol,availableTp(highPrice,OP_BUY),calcLots(),magicNumber,COMMENT);
				printf("InitHandle execuete ,orderStatus: %i, highPrice: %g, availableTp: %g ",orderStatus, highPrice,availableTp(highPrice,OP_BUY));
			}

			if(RUN_MODE == SellOnlyMode || RUN_MODE == NormalMode){
				double lowPrice = getLowPrice(openDayVal);
				lowPrice = NormalizeDouble(lowPrice,MarketInfo(symbol,MODE_DIGITS));
				Trade:: sellStop(symbol,availableTp(lowPrice,OP_SELL),calcLots(),magicNumber,COMMENT);
				printf("InitHandle execuete ,orderStatus: %i, lowPrice: %g, availableTp: %g",orderStatus,lowPrice,availableTp(lowPrice,OP_SELL));
			}

		}
};
// 趋势保护
class InitProfitHandle: public Handle {
	public:
	    bool support() {
			return orderStatus == INIT_PROFIT;
		}
		void execute() {

			protectedStartFlag = true;
			// 下限价单
            //  buyStop(string symbol,double price, double lots, int magicNumber,string COMMENT)
            if(RUN_MODE == BuyOnlyMode || RUN_MODE == NormalMode){
	            double highPrice = getHighPrice(protectedOpenDayVal);
	            highPrice = NormalizeDouble(highPrice,MarketInfo(symbol,MODE_DIGITS));
	           Trade:: buyStop(symbol,availableTp(highPrice,OP_BUY),calcLots(),magicNumber,COMMENT);
               printf("InitProfitHandle execuete ,orderStatus: %i, highPrice: %g, availableTp(highPrice): %g ",orderStatus, highPrice,availableTp(highPrice,OP_BUY));

            }
			if(RUN_MODE == SellOnlyMode || RUN_MODE == NormalMode){
                double lowPrice = getLowPrice(protectedOpenDayVal);
                lowPrice = NormalizeDouble(lowPrice,MarketInfo(symbol,MODE_DIGITS));
                Trade:: sellStop(symbol,availableTp(lowPrice,OP_SELL),calcLots(),magicNumber,COMMENT);
                printf("InitProfitHandle execuete ,orderStatus: %i, lowPrice: %g, availableTp: %g",orderStatus,lowPrice,availableTp(lowPrice,OP_SELL));
            }
		}
};
class BlankHandle: public Handle {

	public:
	    bool support() {
			return orderStatus == BLANK;
		}
		void execute() {
			 if(ArraySize(buyStopOrders) >0){
                double highPrice = getHighPrice(protectedStartFlag? protectedOpenDayVal:  openDayVal);
                highPrice = NormalizeDouble(highPrice,MarketInfo(symbol,MODE_DIGITS));
                Order buyStopOrder = buyStopOrders[0];
                if(needChangePrice(highPrice,buyStopOrder.openPrice)){
                    Trade::modifyStop(buyStopOrder.ticket,availableTp(highPrice,OP_BUY),0,0);
                    printf("BlankHandle  buyStopOrders ,orderStatus: %i, highPrice: %g, availableTp: %g, buyOrderPrice: %g",orderStatus,highPrice,availableTp(highPrice,OP_BUY),buyStopOrder.openPrice);
                }
            }

            if(ArraySize(sellStopOrders) >0){
                Order sellStopOrder = sellStopOrders[0];
                double lowPrice = getLowPrice(protectedStartFlag? protectedOpenDayVal: openDayVal);
                lowPrice = NormalizeDouble(lowPrice,MarketInfo(symbol,MODE_DIGITS));
                if(needChangePrice(lowPrice,sellStopOrder.openPrice)){
                    Trade::modifyStop(sellStopOrder.ticket,availableTp(lowPrice,OP_SELL),0,0);
                    printf("BlankHandle  sellStopOrder ,orderStatus: %i, lowPrice: %g, availableTp: %g, sellOrderPrice: %g",orderStatus,lowPrice,availableTp(lowPrice,OP_SELL),sellStopOrder.openPrice);
                }
            }
		}
};
class HalfBuyHandle: public Handle {

	public:
	    bool support() {
			return orderStatus == HALF && orderType == OP_BUY;
		}
		void execute() {

			Order lastOrder = getLastOrder();
			// 删除反向的挂单
			if(ArraySize(sellStopOrders) >0){
				for(int i=0; i< ArraySize(sellStopOrders); i++){
					if(!OrderDelete(sellStopOrders[i].ticket,clrBlack)){
	                    printf("HalfBuyHandle error delete order ,order tickte: %i",buyStopOrders[i].ticket);
	                }
				}
			}
			// 有新的订单成交了， 重新计算止损
			if(lastTicket != lastOrder.ticket){

				Order firstOrder = getFirstOrder();
				int bar = iBarShift(symbol,period,firstOrder.openTime);
				initAtrVal(bar+1);

				// 止损价格
				double atrProtectedPrice = lastOrder.openPrice - (atrVal * exitStopLossRate);
				atrProtectedPrice = NormalizeDouble(atrProtectedPrice,MarketInfo(symbol,MODE_DIGITS));

				for(int i=0; i< ArraySize(buyOrders); i++){
					// modify(int ticket, double tp,double stopLoss)
					Order order = buyOrders[i];
					 if(needChangePrice(atrProtectedPrice,order.sl)){
					    Trade::modify(order.ticket,0,availableSl(atrProtectedPrice,OP_BUY));
                     }
				}
				lastTicket = lastOrder.ticket;
			}

			// 查看限价单
			if(ArraySize(buyOrders) <fullNum && ArraySize(buyStopOrders) == 0){
				double price = lastOrder.openPrice + addPosition * atrVal;
				price = NormalizeDouble(price,MarketInfo(symbol,MODE_DIGITS));
				Trade:: buyStop(symbol,availableTp(price,OP_BUY),calcLots(),magicNumber,COMMENT);
				printf("HalfBuyHandle execuete ,orderStatus: %i, price: %g, availableTp: %g, currentBuyPrice: %g, atrVal: %g",orderStatus,price,availableTp(price,OP_BUY),Trade::bid(symbol),atrVal);
			}

		}
};


class HalfSellHandle: public Handle {

	public:
	    bool support() {
			return orderStatus == HALF && orderType == OP_SELL;
		}
		void execute() {
			Order lastOrder = getLastOrder();
			// 删除反向的挂单
			if(ArraySize(buyStopOrders) >0){
				for(int i=0; i< ArraySize(buyStopOrders); i++){
					if(!OrderDelete(buyStopOrders[i].ticket,clrBlack)){
						printf("HalfSellHandle error delete order ,order tickte: %i",buyStopOrders[i].ticket);
					}
				}
			}
			// 有新的订单成交了， 重新计算止损
			if(lastTicket != lastOrder.ticket){

				Order firstOrder = getFirstOrder();
				int bar = iBarShift(symbol,period,firstOrder.openTime);
				initAtrVal(bar+1);

				// 止损价格
				double atrProtectedPrice = lastOrder.openPrice + (atrVal * exitStopLossRate);
				atrProtectedPrice = NormalizeDouble(atrProtectedPrice,MarketInfo(symbol,MODE_DIGITS));

				for(int i=0; i< ArraySize(sellOrders); i++){

					Order order = sellOrders[i];
					if(needChangePrice(atrProtectedPrice,order.sl)){
						Trade::modify(order.ticket,0,availableSl(atrProtectedPrice,OP_SELL));
					}
				}
				lastTicket = lastOrder.ticket;
			}
			// 查看限价单
			if(ArraySize(sellOrders) <fullNum &&  ArraySize(sellStopOrders) == 0){

				double price = lastOrder.openPrice - addPosition * atrVal;
				price = NormalizeDouble(price,MarketInfo(symbol,MODE_DIGITS));
				Trade:: sellStop(symbol,availableTp(price,OP_SELL),calcLots(),magicNumber,COMMENT);

				printf("HalfSellHandle execuete ,orderStatus: %i, price: %g, availableTp: %g ,currentSellPrice: %g , atrVal: %g",orderStatus,price,availableTp(price,OP_SELL), Trade::ask(symbol),atrVal);

			}

		}
};


class FullBuyHandle: public Handle {

	public:
	    bool support() {
			return orderStatus == FULL && orderType == OP_BUY;
		}

		void setStatus(bool val) {

            if(protectedFlag){
                if(val){
                    orderStatus = INIT_PROFIT;
                }else{
                    orderStatus = INIT;
                }
            }else{
                orderStatus = INIT;
            }
        }

		void execute() {

			Order lastOrder = getLastOrder();
			// 如果开启定时退出
			if(openTimingExit){

				 // 定时退出
               int bar = iBarShift(symbol,period,lastOrder.openTime);
                    // 大于定时退出时间
               if(bar >= timingExit){
                  printf("ORDER timingExit  lastOrderPrice: %g ,   currentPrice: %g,  lastOrder.openTime: %s  ", lastOrder.openPrice,  Trade:: bid(symbol) , TimeToStr(lastOrder.openTime));
                  bool profitFlag = OrderService:: closeAllAndReturnProfit(symbol,magicNumber);
                  setStatus(profitFlag);
               }
				return;
			}

			// 设置止损

            // 止损价格 atr 价格
            double atrProtectedPrice = lastOrder.openPrice - (atrVal * exitStopLossRate);
			atrProtectedPrice = NormalizeDouble(atrProtectedPrice,MarketInfo(symbol,MODE_DIGITS));
            // 止盈价格
		    double lowPrice = getLowPrice(protectedStartFlag? protectedExitTakeProfitDay: exitTakeProfitDay);
			lowPrice = NormalizeDouble(lowPrice,MarketInfo(symbol,MODE_DIGITS));

			double stopPrice  = Math::ge(atrProtectedPrice, lowPrice)? atrProtectedPrice : lowPrice;

            for(int i=0; i< ArraySize(buyOrders); i++){
                // modify(int ticket, double tp,double stopLoss)
                Order order = buyOrders[i];

                if (needChangePrice(stopPrice,order.sl)){
                    Trade::modify(order.ticket,0,availableSl(stopPrice,OP_BUY));
                }

            }
		}
};
class FullSellHandle: public Handle {

	public:
	    bool support() {
			return orderStatus == FULL && orderType == OP_SELL;
		}

		void setStatus(bool val) {

            if(protectedFlag){
                if(val){
                    orderStatus = INIT_PROFIT;
                }else{
                    orderStatus = INIT;
                }
            }else{
                orderStatus = INIT;
            }
        }

		void execute() {

			Order lastOrder = getLastOrder();
			// 如果开启定时退出
			if(openTimingExit){

				 // 定时退出
               int bar = iBarShift(symbol,period,lastOrder.openTime);
                    // 大于定时退出时间
               if(bar >= timingExit){
                  printf("ORDER timingExit  lastOrderPrice: %g ,   currentPrice: %g,  lastOrder.openTime: %s  ", lastOrder.openPrice,  Trade:: bid(symbol) , TimeToStr(lastOrder.openTime));
                  bool profitFlag = OrderService:: closeAllAndReturnProfit(symbol,magicNumber);
                  setStatus(profitFlag);
               }
				return;
			}

			// 设置止损
            // 止损价格 atr 价格
            double atrProtectedPrice = lastOrder.openPrice + (atrVal * exitStopLossRate);
			atrProtectedPrice = NormalizeDouble(atrProtectedPrice,MarketInfo(symbol,MODE_DIGITS));
            // 突破价格
		    double highPrice = getHighPrice(protectedStartFlag? protectedExitTakeProfitDay: exitTakeProfitDay);
			highPrice = NormalizeDouble(highPrice,MarketInfo(symbol,MODE_DIGITS));

			// 突破价格低于 最小止盈价格时， 设置止盈
			double stopPrice  = Math::ge(highPrice, atrProtectedPrice) ? atrProtectedPrice : highPrice;

            for(int i=0; i< ArraySize(sellOrders); i++){
                // modify(int ticket, double tp,double stopLoss)
                Order order = sellOrders[i];

                if (needChangePrice(stopPrice,order.sl)){
                    Trade::modify(order.ticket,0,availableSl(stopPrice,OP_SELL));
                }

            }
		}
};



Handle *handles[7];



int OnInit() {

//     EventSetTimer(100);
	 if(!IsTradeAllowed()) {
        // Print("trade is not allowed");
        return 0;
     }

    RefreshRates();
	initWork();


	// 如果有订单，初始化atr状态
	if(ArraySize(buyOrders)> 0 || ArraySize(sellOrders) >0){

		Order firstOrder = getFirstOrder();
        // 拿到最先的订单
		PrintFormat("init firstOrder orderTicket: %i", firstOrder.ticket);

        // 计算相差时间，计算准确的  atr值
        int bar = iBarShift(symbol,period,firstOrder.openTime);

        if(!initAtrVal(bar+1)){
            return (0);
        }
	}


	handles[0] = new InitHandle();
    handles[1] = new BlankHandle();
    handles[2] = new HalfBuyHandle();
    handles[3] = new HalfSellHandle();
    handles[4] = new FullBuyHandle();
    handles[5] = new FullSellHandle();
    handles[6] = new InitProfitHandle();


	return 0;
}

// 是否满足保护突破条件
bool enableProtectedDay() {

	if(protectedFlag){

		// 上次订单是盈利的

		if(ArraySize(historyOrders) == 0){
			printf("histtoryOrderSize: %i", ArraySize(historyOrders));
			return false;
		}

		double profit =0.0;
	    for(int i = 0; i < ArraySize(historyOrders); i++){

	        Order historyOrder = historyOrders[i];
            if(OrderSelect(historyOrder.ticket,SELECT_BY_TICKET,MODE_HISTORY)){
                profit += OrderProfit();
            }
        }
		printf("histtoryOrderSize: %i, totalProfit: %g", ArraySize(historyOrders), profit);
		ArrayFree(historyOrders);
		return profit > 0;
	}

	return false;

}


int prefixOrderTotalNum =0;
// 初始化执行状态
void initWork (){

	 // 重新加载订单
    Trade:: loadOrders(buyOrders,symbol,OP_BUY,magicNumber);
    Trade:: loadOrders(sellOrders,symbol,OP_SELL,magicNumber);

    Trade:: loadOrders(buyStopOrders,symbol,OP_BUYSTOP,magicNumber);
    Trade:: loadOrders(sellStopOrders,symbol,OP_SELLSTOP,magicNumber);

    if(ArraySize(buyOrders) >0 && ArraySize(sellOrders)) {
        printf("trade failture, buyOrdersSize: %i, sellOrdersSize: %i",ArraySize(buyOrders),ArraySize(sellOrders));
        ExpertRemove();
        // 退出程序
        return;
    }

	int orderTotalNum = ArraySize(buyOrders) + ArraySize(sellOrders);
	int orderStopTotalNum = ArraySize(buyStopOrders) + ArraySize(sellStopOrders);

	if(orderTotalNum ==0 && orderStopTotalNum ==0 ){
		// 没有所有订单
		if(orderStatus != INIT_PROFIT){
			orderStatus = enableProtectedDay()? INIT_PROFIT :INIT;
		}
		lastTicket = 0;
	}else if(orderTotalNum ==0 && orderStopTotalNum ==1 && prefixOrderTotalNum > 0 ){
		// 删除挂单  已经成交的被止损，剩下一个单子
		if(ArraySize(buyStopOrders) >0){
            OrderDelete(buyStopOrders[0].ticket,clrBlack);
        }else{
            OrderDelete(sellStopOrders[0].ticket,clrBlack);
        }
		orderStatus = INIT;
		lastTicket =0;
	}else if(orderTotalNum ==0 && orderStopTotalNum > 0 ){
		// 如有上次突破的盈利限制设置
		orderStatus = BLANK;
		lastTicket = 0;
	}else if(orderTotalNum > 0 && orderTotalNum < fullNum){
		// 半仓
		if(ArraySize(buyOrders)>0){
			orderType = OP_BUY;
		}else{
			orderType = OP_SELL;
		}
		orderStatus = HALF;
	}else if (orderTotalNum >= fullNum){
		if(ArraySize(buyOrders)>0){
             orderType = OP_BUY;
        }else{
             orderType = OP_SELL;
        }
        orderStatus = FULL;
	}
	prefixOrderTotalNum = orderTotalNum;


}



void OnTick() {

	initWork();

    if(ArraySize(buyOrders)>0){
		ArrayFree(historyOrders);
        ArrayCopy(historyOrders,buyOrders,0,0,ArraySize(buyOrders));
    }
    if(ArraySize(sellOrders) >0){
		ArrayFree(historyOrders);
        ArrayCopy(historyOrders,sellOrders,0,0,ArraySize(sellOrders));
    }


	for(int i=0; i< ArraySize(handles); i++){
		if(handles[i].support()){
            handles[i].execute();
        }
	}



}



void OnDeinit(const int reason)
{
	EventKillTimer();
    Print("OnDeinit method execute");
    for(int i = 0; i< ArraySize(handles); i++){
        delete handles[i];
    }

}
