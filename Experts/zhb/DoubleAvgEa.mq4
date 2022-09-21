//+------------------------------------------------------------------+
//|                                                       EaTest.mq4 |
//|                                                         zouhaibo |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
/*
货币对：EUR/USD 时间周期：M30 技术指标： 双平均移动线
开仓条件：买入条件
平仓条件：*/
#property copyright "zhb"
#property link "QQ:921795"
#property strict
#include <CommonService.mqh>
// 开启下跌止损
input bool stopLossEnable= false;
// 下跌 止损比例, 下跌多少百分比进行平仓
input double stopLossAtrRate = 5.0;

 // 资金风险, 该值越大, 那么风险越高
input double maxRisk = 30;
string symbol= Symbol();
input int period = PERIOD_D1;
input int maMin = 50;
input int maMax = 260;

input int atrDateVal =20;
// 移动止盈参数 moveTakeProfit 开始移动止损  moveTakeRate下跌比例
input bool moveTakeFlag = false;
input double moveTakeProfit = 0.04;
input double moveTakeRate = 0.02;

input double myLots = 0.01;


double atrVal = 0.0;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+


bool initAtrVal(int bar = 0) {

	double value = iATR(symbol,period,atrDateVal,bar);
    atrVal = NormalizeDouble(value,5);
	printf("initAtrVal value: %g,   atrVal:  %g ",  value,  atrVal);
	if (!Math:: gt(atrVal,0)){
        printf("init AtrVal failture atrVal: %g",atrVal);
        // 初始化atrVal失败，终止程序运行
        ExpertRemove();

    }
    return Math:: gt(atrVal,0);
}

int OnInit()
  {
//--- create timer
   EventSetTimer(60);
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- destroy timer
   EventKillTimer();

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
    ticket();
  }



//+------------------------------------------------------------------+

// 移动止损

double stopTakePrice = 0.0;

void ticket() {

	setLable("时间栏","星期"+ DayOfWeek()+" 市场时间："+ Year()+"-"+ Month()+ "-"+ Day()+ "-"+ Hour()+ ":"+ Minute()+
	":"+Seconds(), 200,0,9,"Verdana",Red);

	setLable("信息栏","市场信号："+ returnMarketInfomation()+ " 当前订单盈亏： "+ DoubleToStr(OrderProfit(),2),5,20,10,
	"Verdana",Blue);

	if(OrdersTotal()== 1){

        OrderSelect(0,SELECT_BY_POS);// 选当前订单

		// // 移动止损 如果开启移动止损， 那么对移动止损进行操作
		if(moveTakeFlag){
			// 第一次上涨超过幅度
			double marketPrice =  OrderType() == OP_BUY? MarketInfo(symbol,MODE_ASK) : MarketInfo(symbol,MODE_BID);
			if(stopTakePrice == 0.0){
				double takePrice = NormalizeDouble(OrderOpenPrice() * stopLossAtrRate,5) + OrderOpenPrice();
				if(takePrice < marketPrice ){

					stopTakePrice = marketPrice;
					// bool res=OrderModify(ticket,0,stopLoss,tp,0,clrOrange);
					double stopLossPrice = marketPrice- (marketPrice - OrderOpenPrice()) *moveTakeRate ;
					OrderModify(OrderTicket(),OrderLots(),stopLossPrice,0,0,clrOrange);
					return ;
				}

			}else{

				if(marketPrice > stopTakePrice){
					stopTakePrice = marketPrice;
					double stopLossPrice = marketPrice- (marketPrice - OrderOpenPrice()) * moveTakeRate;
	                OrderModify(OrderTicket(),OrderLots(),stopLossPrice,0,0,clrOrange);
	                return ;
				}

			}

		}


        // 买单如果下穿，直接平仓
        if(Symbol() == symbol  && OrderType() == OP_BUY
                && returnMarketInfomation() == "sell"){

            OrderClose(OrderTicket(),OrderLots(),Bid,0,clrBlue);

            return ;
        }
        // 或者卖单上穿，进行平仓
        if(Symbol() == symbol && OrderType() == OP_SELL
                && returnMarketInfomation() == "buy"){

            OrderClose(OrderTicket(),OrderLots(),Ask,0,clrBlue);

            return ;
        }

	// 开仓操作
    }else if (OrdersTotal() == 0){

		stopTakePrice = 0;

		if(returnMarketInfomation() == "buy"){
			// 止损价格, 下跌百分率stopLossAtrRate  最低50倍杠杆
			Print(" returnMarketInfomation is buy ");
			if(stopLossEnable){

				if(!initAtrVal()){
					return;
				}
				// 止损价格 = 当前市价- atrVal*
				double stopBuyPrice = MarketInfo(symbol,MODE_BID) - atrVal* stopLossAtrRate;
				int ticket = OrderSend(Symbol(),OP_BUY,lotsOptimized(),MarketInfo(symbol,MODE_ASK) ,0,stopBuyPrice,0);
				if(ticket< 0){
					Print("GetLastError: "+ GetLastError());
				}

			}else{
				int ticket =  OrderSend(Symbol(),OP_BUY,lotsOptimized(),MarketInfo(symbol,MODE_ASK) ,0,0,0);
				if(ticket <0){
					Print("GetLastError: "+ GetLastError());
				}
			}

		}
		if(returnMarketInfomation() == "sell"){
			Print(" returnMarketInfomation is buy ");
			// 止损价格 1手 211
			if(stopLossEnable){
				// 是否开启止损
				if(!initAtrVal()){
                    return;
                }
				double stopSellPrice =MarketInfo(symbol,MODE_ASK) +  atrVal* stopLossAtrRate;
				int ticket = OrderSend(Symbol(),OP_SELL,lotsOptimized(),MarketInfo(symbol,MODE_BID) ,0,stopSellPrice,0);
				if(ticket< 0){
                    Print("GetLastError: "+ GetLastError());
                }
			}else{
				int ticket =OrderSend(Symbol(),OP_SELL,lotsOptimized(),MarketInfo(symbol,MODE_BID) ,0,0,0);
				if(ticket< 0){
					Print("GetLastError: "+ GetLastError());
				}
			}
		}

		return ;

    }else{

        Print("发生了错误，订单数量为："+ OrdersTotal());
    }

    return ;

}

/*
函数：优化保证金，确定开仓量，进行风险控制 根据风险riskValue计算开仓量
如果出现亏损订单，则下一单开仓量减半

//  /  MarketInfo(symbol,MODE_MARGINREQUIRED) 要求买1标准手的保证金余额。以现价( 卖出价 )返回一个标准手的价格
*/
double lotsOptimized() {
	// 手数 = 余额 * maxRisk/100   /  MarketInfo(symbol,MODE_MARGINREQUIRED)
//	double lots = NormalizeDouble((AccountBalance()* maxRisk/100)/MarketInfo(symbol,MODE_MARGINREQUIRED),2)/10;
//	// 最大可开仓手数
//	if(lots < 0.01){
//		lots = 0;
//		Print("保证金余额不足！");
//	}
	// todo 如果上一单亏损，进行减半处理？
//	OrderSelect(OrdersHistoryTotal()-1,SELECT_BY_POS,MODE_HISTORY);
//	if(OrderProfit() < 0){
//		lots = 0.01;
//	}
	return myLots;

}

/* 函数：在屏幕上显示标签 LableName：标签名称；LableDoc：文本内容；LableX：标签X位置；LableY：标签Y位置；
 DocSize：文本字号；DocStyle：
文本字体；DocColor：文本颜色 */

void setLable(string lableName,string lableDoc,int lableX,int lableY,
int docSize,string docStyle,color docColor) {

	ObjectCreate(lableName,OBJ_LABEL,0,0,0);
	ObjectSetText(lableName,lableDoc,docSize,docStyle,docColor);
	ObjectSet(lableName,OBJPROP_XDISTANCE,lableX);
	ObjectSet(lableName,OBJPROP_YDISTANCE,lableY);

}
/*
返回市场信息，获取技术指标参数，通过比对，返回市场信息：
Buy- 买入信号，sell -卖出信号，
Rise- 涨势行情， Fall- 跌势行情， UpCross- 向上翻转
DownCross -- 向下反转，反转信号为平仓信号
*/
string returnMarketInfomation() {

	string marketInfoResult = "N/A";
	// 最新的均线数据
	double newPriceMax = NormalizeDouble(iMA(symbol,period,maMax,0,MODE_SMA,PRICE_CLOSE,0),4);
	double  newPriceMin= NormalizeDouble(iMA(symbol,period,maMin,0,MODE_SMA,PRICE_CLOSE,0),4);

	// 上一个均线数据
	double oldPriceMax = NormalizeDouble(iMA(symbol,period,maMax,0,MODE_SMA,PRICE_CLOSE,1),4);
	double oldPriceMin = NormalizeDouble(iMA(symbol,period,maMin,0,MODE_SMA,PRICE_CLOSE,1),4);

	// 上穿
	if(newPriceMin > newPriceMax && oldPriceMin <= oldPriceMax ){
		marketInfoResult = "buy";
	}
	// 下穿
	if(newPriceMin < newPriceMax && oldPriceMin >= oldPriceMax){
		marketInfoResult = "sell";
	}
	return (marketInfoResult);

}

