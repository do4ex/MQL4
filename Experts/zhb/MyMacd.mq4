#property copyright "zouhaibo"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#include <CommonService.mqh>
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
//  macd 根据macd的值进行下单

// 交易币对
string symbol = Symbol() ;
// k线间隔
input int period = PERIOD_H4;
// constant
const int SLIPPAGE = 5;
const string COMMENT = "myMacd";
int magicNumber = 20002;
const string BUY = "buy", SELL = "sell", NO_MARKET = "no_market", EXIT = "exit", DO_NOTHING = "do_nothing";
// 下单量, 根据自己资金量，人工控制下单量
extern double myLots = 0.1;

// macd1 与 macd2 的差异
input double openOrderMacd12Rate = 0.2;

input double closeOrderMacd12Rate = 0.2;

input double buyLimitMacdVal = -0.001;

input double sellLimitMacdVal = 0.001;

input double buyExitMacd1Val = 0.003;

input double sellExitMacd1Val = -0.003;

datetime lastOrderTime;


string getMarketMsg() {


	double macd1 = iMACD(symbol, period, 5, 13, 1, PRICE_CLOSE, MODE_SIGNAL, 1);
	double macd2 = iMACD(symbol, period, 5, 13, 1, PRICE_CLOSE, MODE_SIGNAL, 2);
	double macd3 = iMACD(symbol, period, 5, 13, 1, PRICE_CLOSE, MODE_SIGNAL, 3);


	// 用于过滤一些 小的上涨和下跌
	double subVal = NormalizeDouble((macd1- macd2)/macd1,6);
	subVal = MathAbs(subVal);
	// 买


	if(Math:: gt(macd1, macd2) &&  subVal > openOrderMacd12Rate){
		if(macd1 > buyLimitMacdVal ){
			PrintFormat(" getMarketMsg ..  macd1 : %g , macd2: %g , macd3: %g , subVal: %g",macd1,macd2,macd3,subVal);
			return BUY;
		}
	}
	if (Math:: gt(macd2, macd1) && subVal > openOrderMacd12Rate){
		if(macd1 < sellLimitMacdVal){
			PrintFormat(" getMarketMsg ..  macd1 : %g , macd2: %g , macd3: %g , subVal: %g",macd1,macd2,macd3,subVal);
			return SELL;
		}
	}
	return NO_MARKET;

}

// 获取市场退出的信号
string getMarketExitSigal(int opType) {

	// 移动平均线价格
    double macd0 = iMACD(symbol, period, 5, 13, 1, PRICE_CLOSE, MODE_SIGNAL, 0);
	double macd1 = iMACD(symbol, period, 5, 13, 1, PRICE_CLOSE, MODE_SIGNAL, 1);
    double macd2 = iMACD(symbol, period, 5, 13, 1, PRICE_CLOSE, MODE_SIGNAL, 2);
    double macd3 = iMACD(symbol, period, 5, 13, 1, PRICE_CLOSE, MODE_SIGNAL, 3);
    double macd4 = iMACD(symbol, period, 5, 13, 1, PRICE_CLOSE, MODE_SIGNAL, 4);
    double macd5 = iMACD(symbol, period, 5, 13, 1, PRICE_CLOSE, MODE_SIGNAL, 5);
    double macd6 = iMACD(symbol, period, 5, 13, 1, PRICE_CLOSE, MODE_SIGNAL, 6);

	// 求 macd 最近5条线的均值
	double macdAvgPrice = (macd2+ macd3+ macd4+ macd5+ macd6)/5;

	macdAvgPrice = NormalizeDouble(macdAvgPrice,6);


	double subVal = NormalizeDouble((macd1- macd2)/macd1,6);
    subVal = MathAbs(subVal);
	//  -5 -10 /2 = -7.5 * 0.2
	// -10 - 1.55
	// 如果是买单
	if(opType == OP_BUY){

		//  macd1 : -0.000684078 , macd2: -0.000969825 , macd3: 0.000310936
		if(Math:: gt(macd2 , macd1) && subVal > closeOrderMacd12Rate ){
			PrintFormat("OP_BUY1  getMarketExitSigal ..  macd1 : %g , macd2: %g , macd3: %g , subVal: %g ",macd1,macd2,macd3,subVal);
			return EXIT;
		}
		// 持续衰减
		if (macd1 < macdAvgPrice &&  macd1 < macd2 && macd2 < macd3){
			PrintFormat("OP_BUY2  getMarketExitSigal ..  macd1 : %g , macd2: %g , macd3: %g , subVal: %g ",macd1,macd2,macd3,subVal);
			return EXIT;
		}

	}else if(opType == OP_SELL){

		if(Math:: gt(macd1, macd2) && subVal > closeOrderMacd12Rate ){
			PrintFormat(" OP_SELL1  getMarketExitSigal .. macd1 : %g , macd2: %g , macd3: %g , subVal: %g",macd1,macd2,macd3,subVal);
	        return EXIT;
	    }
	    if(macd1> macdAvgPrice &&  macd1 > macd2 && macd2 > macd3){
			PrintFormat(" OP_SELL2  getMarketExitSigal .. macd1 : %g , macd2: %g , macd3: %g , subVal: %g",macd1,macd2,macd3,subVal);
			return EXIT;
	    }
	}
	return DO_NOTHING;

}



int OnInit() {


	return 0;

}

void OnTick() {


	// 每次下单，下一个单

	int ordertotalNum = OrderService:: getOrderTotal(symbol,magicNumber);
	if(ordertotalNum == 0){
		// 获取行情，是否需要下单
		string marketMsg = getMarketMsg();

		if(marketMsg == BUY){
			Trade:: buyMarket(symbol,myLots,magicNumber,COMMENT);
		}else if(marketMsg == SELL){
			Trade:: sellMarket(symbol, myLots,magicNumber,COMMENT);
		}

	}else{

		if(!OrderService:: selectLastOrder(symbol,magicNumber)){
            printf("selectLastOrder error : %i ", GetLastError());
            return;
        }
		string exitSigal = getMarketExitSigal(OrderType());

		if(exitSigal == EXIT){
			OrderService:: closeAllAndReturnProfit(symbol,magicNumber);
		}


	}

}


void OnDeinit(const int reason)
{
//--- destroy timer
   EventKillTimer();

   Print("OnDeinit method execute");

}
