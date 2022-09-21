#property copyright "zouhaibo"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#include <CommonService.mqh>
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
//  海龟交易系统的实现，包括短时突破，长时间保护，定时退出
// 短期突破 上次突破盈利，下次就略过，
// 长期突破，不设置保护性
// 定时退出，把交易让给时间
// 谨记，因为大多数交易都是亏损的，所有盈利的时候必须不能干扰
// 订单状态  blank=空仓 ，blank_profit上一单盈利的空仓，half半仓，full满仓
//enum ORDER_STATUS { 1=BLANK,2=BLANK_PROFIT,3=HALF,4=FULL};

int orderStatus = 1;
// 满仓数量
input int fullNum = 4;
// 交易币对
string symbol = Symbol();
//input string symbol = Symbol();
// 突破
input int openDayVal = 3;
// 是否进行保护性，如果开启，那么protectedOpenDayVal 将生效
input bool protectedFlag = false;
// 如果上一次盈利，这一次则不交易，但是又突破了55日的，那么进行加仓
input int protectedOpenDayVal = 55;
// 加仓系数，每次加 addPosition * atr值
input double addPosition = 0.5;
// 退出策略 价格下跌 exitStopLossRate * atr 就进行退出
input double exitStopLossRate = 2;
// 价格跌破 10日最低即退出
input int exitTakeProfitDay = 2;
// k线间隔
input int period = PERIOD_M1;
// 定时退出, 是否开启定时退出
input bool openTimingExit = false;
// 定时退出间隔
input int timingExit = 60;
// constant 滑点
const int SLIPPAGE = 3;
const string COMMENT = "EA";
int magicNumber = 10001;

// 下单量, 根据自己资金量，人工控制下单量
extern double myLots = 0.01;

// 是否开启下单资金控制, 默认不开启，注意跑历史数据一般需要开启
extern bool lotsControl = false;

// 下单基准，如果 1000 对应 0.01， 2000 对应0.02
input double moneyUnitRate = 100000;

// 常量
const int BLANK =1,BLANK_PROFIT=2, HALF=3, FULL =  4;


double atrVal = 0;

bool initAtrVal(int bar = 0) {


	double value = iATR(symbol,period,openDayVal,bar);
    atrVal = NormalizeDouble(value,5);
	printf("initAtrVal value: %g,   atrVal:  %g ",  value,  atrVal);
	if (!Math:: gt(atrVal,0)){
        printf("init AtrVal failture atrVal: %g",atrVal);
        // 初始化atrVal失败，终止程序运行
        ExpertRemove();

    }
    return Math:: gt(atrVal,0);
}



class Handle {

	protected:
		//向上突破
		bool breakHighPrice(int inteval) {
            int highBar = iHighest(symbol,period,MODE_HIGH,inteval,1);
            double highPrice = iHigh(symbol,period,highBar);

            if(Math:: gt(MarketInfo(symbol,MODE_ASK),highPrice)){
                return true;
            }
            return false;

        }
        // 向下突破
        bool breakLowPrice(int inteval) {

            int lowBar = iLowest(symbol,period,MODE_LOW,inteval,1);
            double lowPrice = iLow(symbol,period,lowBar);
            if(Math:: gt(lowPrice,MarketInfo(symbol,MODE_BID))){
                return true;
            }
            return false;
        }

        // 计算开仓手数
        double calcLots() {

			// 计算资金，采用累加原则

			if(!lotsControl){
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
};


// 如果是空仓
class BlankHandle : public Handle {

	public:
	 void execute() {
			// 破高
			if(breakHighPrice(openDayVal)){
				// 立即买入
				if(!initAtrVal()){
                    return;
                }

				printf("BlankHandle first buy order artval: %g    calcLots: %g",  atrVal ,calcLots());
				Trade::buyMarket(symbol,calcLots(),magicNumber,COMMENT);
				//设置状态
				orderStatus = HALF;
			}
			// 破低，做空
			if(breakLowPrice(openDayVal)){
				if(!initAtrVal()){
                    return;
                }
				printf("BlankHandle first sell order artval: %g   calcLots: %g",  atrVal,calcLots());
				Trade::sellMarket(symbol,calcLots(),magicNumber,COMMENT);
				orderStatus = HALF;
			}
		}

};

// 上一次盈利的空仓
class BlankProfitHandle : public Handle {
	public:
//		virtual bool mathOrderStatus(ORDER_STATUS orderStatus) {
//			return orderStatus == BLANK_PROFIT;
//		}
	 void execute() {
			// 破高
            if(breakHighPrice(protectedOpenDayVal)){
                // 立即买入
                if(!initAtrVal()){
                    return;
                }
				printf("BlankProfitHandle first buy order artval: %g    calcLots: %g",  atrVal ,calcLots());
                Trade::buyMarket(symbol,calcLots(),magicNumber,COMMENT);
                orderStatus = HALF;

            }
            // 破低，做空
            if(breakLowPrice(protectedOpenDayVal)){
               if(!initAtrVal()){
                   return;
               }
				printf("BlankProfitHandle first sell order artval: %g   calcLots: %g",  atrVal,calcLots());
                Trade::sellMarket(symbol,calcLots(),magicNumber,COMMENT);
                orderStatus = HALF;
            }

		}
};


// 半仓
class HalfHandle : public Handle{

	public:
        void execute() {
			//上涨
			int ordertotalNum = OrderService::getOrderTotal(symbol,magicNumber);
			if(ordertotalNum == 0){
				printf("HalfHandle error orderStatus: %i", orderStatus);
				orderStatus = BLANK;
				return;
			}
			// 加仓满4次，但是状态不对
			if(ordertotalNum >= fullNum){
				printf("HalfHandle error orderStatus:  %i,  ordersTotal: %i", orderStatus,ordertotalNum);
				orderStatus = FULL;
				return;
			}

			bool res = OrderService::selectLastOrder(symbol,magicNumber);
			if(!res){
                printf("orderStatus error not found order orderStatus: %i ",orderStatus);
                return;
            }

			// 买单 价格上涨

			if(OrderType() == OP_BUY){
				// 买单
				double spotVal =  OrderOpenPrice() - Trade:: bid(symbol);
				// 大于0 下跌
				if(Math::gt(spotVal,exitStopLossRate * atrVal)){
					// 平掉所有订单，修改状态
					printf("buyOrder half stop loss orderOpenPrice:  %g   currentPrice: %g   atrVal: %g", OrderOpenPrice(), Trade:: bid(symbol), atrVal);
					printf("res=%i, symbol=%s, ticket=%i", res, symbol, OrderTicket());
                    if(MathAbs(OrderOpenPrice()-Trade:: bid(symbol))/OrderOpenPrice() > 0.3) printf("=============================================================================");
					OrderService::closeAllAndReturnProfit(symbol,magicNumber);
					// 手数累加
					orderStatus = BLANK;
					return;
				}
				spotVal = Trade:: bid(symbol) -OrderOpenPrice();
				if(Math::gt(spotVal,addPosition * atrVal)){
					// 加仓
					printf("buyOrder half add money orderOpenPrice: %g   currentPrice: %g   atrVal: %g" , OrderOpenPrice(), Trade:: bid(symbol),atrVal);
					printf("res=%i, symbol=%s, ticket=%i", res, symbol, OrderTicket());
                    if(MathAbs(OrderOpenPrice()-Trade:: bid(symbol))/OrderOpenPrice() > 0.3) printf("=============================================================================");
                    Trade::buyMarket(symbol,calcLots(),magicNumber,COMMENT);
					 if(OrderService::getOrderTotal(symbol,magicNumber) == fullNum){
	                    orderStatus = FULL;
	                    return;
	                }
				}
			}else{
				double spotVal =  OrderOpenPrice() - Trade:: ask(symbol);

				// 大于0 上涨
				if(Math::gt(spotVal,addPosition * atrVal)){
                    // 加仓
                    printf("sellOrder half add money orderOpenPrice: %g   currentPrice: %g    atrVal: %g", OrderOpenPrice(), Trade:: ask(symbol), atrVal);
                    printf("res=%i, symbol=%s, ticket=%i", res, symbol, OrderTicket());
                    if(MathAbs(OrderOpenPrice()-Trade:: bid(symbol))/OrderOpenPrice() > 0.3) printf("=============================================================================");
                    Trade::sellMarket(symbol,calcLots(),magicNumber,COMMENT);
                    if(OrderService:: getOrderTotal(symbol,magicNumber) == fullNum ){
                        orderStatus = FULL;
                        return;
                    }
                }

                spotVal = Trade::ask(symbol) - OrderOpenPrice();
                if(Math::gt(spotVal, exitStopLossRate * atrVal)){
                    // 平仓
                    printf("symbol=%s, ticket=%i", symbol, OrderTicket());
                    printf("sellOrder half stop loss orderOpenPrice: %g   currentPrice: %g   atrVal: %g ", OrderOpenPrice() ,  Trade:: ask(symbol) , atrVal);
                    printf("res=%i, symbol=%s, ticket=%i", res, symbol, OrderTicket());
                    if(MathAbs(OrderOpenPrice()-Trade:: bid(symbol))/OrderOpenPrice() > 0.3) printf("=============================================================================");
                    OrderService::closeAllAndReturnProfit(symbol,magicNumber);
                    orderStatus = BLANK;
                    return;
                }

			}
        }

};
// 满仓
class FullHandle : public Handle{

	public:
		void setStatus(bool val) {

			if(protectedFlag){
				if(val){
					orderStatus = BLANK_PROFIT;
				}else{
					orderStatus = BLANK;
				}
			}else{
				orderStatus = BLANK;
			}

		}
        void execute() {

			// 状态判断
			int ordertotalNum = OrderService:: getOrderTotal(symbol,magicNumber);
			if(ordertotalNum == 0){
				printf("orderStatus error  current ordersTotal: %i  current status: %i ",ordertotalNum, orderStatus);
				orderStatus = BLANK;
				return;
			}
			if(ordertotalNum < fullNum){
				printf("orderStatus error  current ordersTotal: %i  current status: %i ",ordertotalNum, orderStatus);
				orderStatus = 	HALF;
				return;
			}
			// 选中一个订单
			bool res=OrderService:: selectLastOrder(symbol,magicNumber);
			if(!res){
                printf("orderStatus error not found order orderStatus: %i ",orderStatus);
                return;
            }


            if(openTimingExit){
                // 定时退出
	           int bar = iBarShift(symbol,period,OrderOpenTime());
	                // 大于定时退出时间
	           if(bar >= timingExit){

	              printf("ORDER timingExit  lastOrderPrice: %g ,   currentPrice: %g,  exitTakeProfitDay: %i  ", OrderOpenPrice(),  Trade:: bid(symbol) , exitTakeProfitDay);
	              bool profitFlag = OrderService:: closeAllAndReturnProfit(symbol,magicNumber);
	              setStatus(profitFlag);
	              return;
	           }
            }


			if(OrderType() == OP_BUY){
                // 买单
                double spotVal =  OrderOpenPrice()-Trade:: bid(symbol);
                // 大于0 下跌
                if(Math::gt(spotVal,exitStopLossRate * atrVal)){
                    // 平掉所有订单，修改状态
                    printf("buyOrder full stop loss orderOpenPrice: %g  , currentPrice: %g ", OrderOpenPrice(), Trade:: bid(symbol));
                    printf("res=%i, symbol=%s, ticket=%i", res, symbol, OrderTicket());
                    if(MathAbs(OrderOpenPrice()-Trade:: bid(symbol))/OrderOpenPrice() > 0.3) printf("=============================================================================");
					OrderService:: closeAllAndReturnProfit(symbol,magicNumber);
                    orderStatus = BLANK;
                    return;
                }
                // 如果没有开启定时退出
                if(!openTimingExit){

	                if(breakLowPrice(exitTakeProfitDay)){
						// 价格向下突破了
	                    printf("buyOrder breakLowPrice  lastOrderPrice: %g ,   currentPrice: %g,  exitTakeProfitDay: %i  ", OrderOpenPrice(),  Trade:: bid(symbol) , exitTakeProfitDay);
	                    bool profitFlag = OrderService:: closeAllAndReturnProfit(symbol,magicNumber);
	                    setStatus(profitFlag);
	                    return;
	                }
                }


            }else{
                double spotVal = Trade::ask(symbol) - OrderOpenPrice();
                if(Math::gt(spotVal, exitStopLossRate * atrVal)){
                    // 平仓
                    printf("sellOrder full stop loss orderOpenPrice: %g,   currentPrice: %g ", OrderOpenPrice(), Trade:: ask(symbol));
                    printf("symbol=%s, ticket=%i", symbol, OrderTicket());
                    OrderService:: closeAllAndReturnProfit(symbol,magicNumber);
                    orderStatus = BLANK;
                    return;
                }
				// 如果没有开启定时退出
				if(!openTimingExit){
	                if(breakHighPrice(exitTakeProfitDay)){
	                    printf("buyOrder breakHighPrice  lastOrderPrice: %g ,  currentPrice: %g,  exitTakeProfitDay:  %i ", OrderOpenPrice(),  Trade:: bid(symbol),exitTakeProfitDay);
	                    printf("symbol=%s, ticket=%i", symbol, OrderTicket());
	                    bool profitFlag = OrderService:: closeAllAndReturnProfit(symbol,magicNumber);
	                    setStatus(profitFlag);

	                    return;
	                }
				}

            }
        }

};



int OnInit() {


	// 初始化状态， 如果已经有订单了 根据订单数量初始化状态， atrVal
	int ordertotalNum = OrderService:: getOrderTotal(symbol,magicNumber);

    if(ordertotalNum > 0){

        // 计算相差时间，计算准确的  atr值
        if(OrderService::selectLastOrder(symbol,magicNumber)){

            datetime orderTime = OrderOpenTime();
            int bar = iBarShift(symbol,period,OrderOpenTime());
            if(!initAtrVal(bar)){
                return (0);
            }

            if(ordertotalNum < fullNum){
                orderStatus = HALF;
            }else if(ordertotalNum >= fullNum){
                orderStatus = FULL;
            }
        }
    }

    // 初始化 手数

    if(lotsControl){

	    double tempLots = NormalizeDouble(AccountBalance()/ moneyUnitRate,3);
	    int temp = tempLots * 100;

	    myLots = temp * 0.01;

	    if(myLots < MarketInfo(symbol,MODE_MINLOT)){
	        printf("init myLots error myLots: %g ",myLots);
	        myLots = MarketInfo(symbol,MODE_MINLOT);
	    }
    }

    printf("init myLots value: %g   and orderStatus: %i   OrdersTotal(): %i   initAtrVal : %g", myLots, orderStatus, ordertotalNum, atrVal);


    return (0);

}

BlankHandle *blankHandle= new BlankHandle();
BlankProfitHandle *blankProfitHandle = new BlankProfitHandle();
HalfHandle *halfHandle = new HalfHandle();
FullHandle *fullHandle = new FullHandle();


void OnTick() {

	 if(!IsTradeAllowed()) {
	    // Print("trade is not allowed");
	    return;
	  }

	 RefreshRates();

	if(orderStatus == BLANK){
		blankHandle.execute();
	}else if(orderStatus == BLANK_PROFIT){
		blankProfitHandle.execute();
	}else if(orderStatus == HALF){
		halfHandle.execute();
	}else if(orderStatus == FULL){
		fullHandle.execute();
	}


}

void OnDeinit(const int reason)
{
//--- destroy timer
    delete blankHandle;
   	delete blankProfitHandle;
   	delete halfHandle;
   	delete fullHandle;

}
