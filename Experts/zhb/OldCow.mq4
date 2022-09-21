#property copyright "zouhaibo"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#include <CommonService.mqh>
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
// 老牛均线系统， 取一个均线数据
// 去前两日的均线数据，如果是大于，就买入，如果是小于，就卖出


// 交易币对
string symbol = Symbol();
//input string symbol = Symbol();
// k线间隔
input int period = PERIOD_D1;

// constant 滑点
const int SLIPPAGE = 3;
const string COMMENT = "EA";
int magicNumber = 10002;
// 下单量, 根据自己资金量，人工控制下单量
extern double myLots = 0.01;

input int ma = 50;

const string BUY = "buy", SELL = "sell", NO_MARKET = "no_market", EXIT = "exit", DO_NOTHING = "do_nothing";


int OnInit() {


	return 0;

}

void OnTick() {


	int orderTotalNum = OrderService:: getOrderTotal(symbol,magicNumber);

	if(orderTotalNum == 0){

		string marketMsg = getMarketMsg();

		if(marketMsg == BUY){
			Trade::buyMarket(symbol,myLots,magicNumber,COMMENT);
		}

		if(marketMsg == SELL){
			Trade::sellMarket(symbol,myLots,magicNumber,COMMENT);
		}


	}else {
		if(!OrderService:: selectLastOrder(symbol,magicNumber)){
			PrintFormat("selectLastOrder error ");
			return ;
		}
		if(OrderType() == OP_BUY){

			if(getExitMarketMsg(OrderType()) == EXIT){
				PrintFormat(" orderTotalNum : %i, marketMsg: %s",orderTotalNum,getExitMarketMsg(OrderType()));
				OrderService::closeAllAndReturnProfit(symbol,magicNumber);

			}

		}else if(OrderType() == OP_SELL){

			if(getExitMarketMsg(OrderType()) == EXIT){
				PrintFormat(" orderTotalNum : %i, marketMsg: %s",orderTotalNum,getExitMarketMsg(OrderType()));
				OrderService::closeAllAndReturnProfit(symbol,magicNumber);
			}
		}
	}



}


void OnDeinit(const int reason)
{
//--- destroy timer
   EventKillTimer();

   Print("OnDeinit method execute");

}

// 获取市场行情
string getMarketMsg() {


	double ma1Price = NormalizeDouble(iMA(symbol,period,ma,0,MODE_EMA,PRICE_CLOSE,1),5);

	double ma2Price = NormalizeDouble(iMA(symbol,period,ma,0,MODE_EMA,PRICE_CLOSE,2),5);

	double ma3Price = NormalizeDouble(iMA(symbol,period,ma,0,MODE_EMA,PRICE_CLOSE,3),5);

	double ma4Price = NormalizeDouble(iMA(symbol,period,ma,0,MODE_EMA,PRICE_CLOSE,4),5);


	if(ma1Price> ma2Price && ma2Price>ma3Price && ma3Price>ma4Price){
		PrintFormat("BUY m1: %g,m2:%g, m3: %g,m4:%g",ma1Price,ma2Price,ma3Price,ma4Price);
		return BUY;
	}

	if(ma4Price>ma3Price && ma3Price > ma2Price && ma2Price>ma1Price){
		PrintFormat("SELL m1: %g,m2:%g, m3: %g,m4:%g",ma1Price,ma2Price,ma3Price,ma4Price);
		return SELL;
	}

	return NO_MARKET;

}

string getExitMarketMsg(int orderType) {

	double ma1Price = NormalizeDouble(iMA(symbol,period,ma,0,MODE_EMA,PRICE_CLOSE,1),5);

	double ma2Price = NormalizeDouble(iMA(symbol,period,ma,0,MODE_EMA,PRICE_CLOSE,2),5);

	// 下跌
	if(orderType == OP_BUY){
		if(Math:: gt(ma2Price,ma1Price) ){
            return EXIT;
        }
	}

	// 上涨
	if(orderType == OP_SELL){

		if(Math:: gt(ma1Price,ma2Price)){
			return EXIT;
		}
	}

	return DO_NOTHING;

}


