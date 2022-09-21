#property copyright "zouhaibo"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#include <CommonService.mqh>
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
// atr通道突破系统


string symbol = Symbol();

// 移动平均线
input int ma =350;
// k线单位
input int period = PERIOD_D1;
// atr 均值 取值范围
input int atrRange = 10;

input double lots = 0.01;

input double atrMaxRate =4.0;
input double atrExitRate =2.0;
input double atrMinRate = 4.0;


const int SLIPPAGE = 3;
const string COMMENT = "atr-channel";
int magicNumber = 10087;

const string BUY = "buy", SELL = "sell", NO_MARKET = "no_market", EXIT = "exit", DO_NOTHING = "do_nothing";

double atrVal = 0.0;



bool initAtrVal(int bar = 0) {


	double value = iATR(symbol,period,atrRange,bar);
    atrVal = NormalizeDouble(value,5);
//	printf("initAtrVal value: %g,   atrVal:  %g ",  value,  atrVal);
	if (!Math:: gt(atrVal,0)){
        printf("init AtrVal failture atrVal: %g",atrVal);
        // 初始化atrVal失败，终止程序运行
        ExpertRemove();

    }
    return Math:: gt(atrVal,0);
}




// 计算手数
double calcLots() {
	return lots;
}

int OnInit() {

	// 初始化 atr， 如果失败，退出程序
	if(!initAtrVal()){
	    return (0);
	}
	return 0;

}

void OnTick() {

	// 初始化 atr， 如果失败，退出程序
	if(!initAtrVal()){
	    return;
	}

	int orderTotalNum = OrderService::getOrderTotal(symbol,magicNumber);

	if(orderTotalNum == 0){


		string marketOpenSigal = getMarketOpenSigal();
		if(marketOpenSigal == NO_MARKET){
			return;
		}
		if(marketOpenSigal == BUY){
			Trade:: buyMarket(symbol, calcLots(), magicNumber,COMMENT);
		}

		if(marketOpenSigal == SELL){
			Trade:: sellMarket(symbol, calcLots(), magicNumber,COMMENT);
		}


	}else{

		if( !OrderService:: selectLastOrder(symbol,magicNumber)){
			PrintFormat("selectLastOrder failture ");
			return;
		}
		string  marketExitSigal = getMarketExitSigal(OrderType());

		if(marketExitSigal == EXIT){
			// 平掉所有订单
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


// 获取市场交易 的信号
string getMarketOpenSigal(){

	// 获取平均移动
	double maPrice = NormalizeDouble(iMA(symbol,period,ma,0,MODE_SMA,PRICE_MEDIAN,0),4);

	// 当前价格
	double buyPrice =  MarketInfo(symbol,MODE_BID);
	double sellPrice =  MarketInfo(symbol,MODE_ASK);

	// 通道顶部
	double channelHighPrice = atrVal * atrMaxRate + maPrice;
	// 通道底部
	double channelLowPrice = maPrice -  atrVal * atrMinRate;

	if(sellPrice > channelHighPrice){
		return SELL;
	}

	if(buyPrice < channelLowPrice ){
		return BUY;
	}

	return NO_MARKET;

}

// 获取市场退出的信号
string getMarketExitSigal(int opType) {

	// 移动平均线价格
	double maPrice = NormalizeDouble(iMA(symbol,period,ma,0,MODE_SMA,PRICE_MEDIAN,0),4);
	// 如果是买单
	if(opType == OP_BUY){

		double currentPrice = MarketInfo(symbol,MODE_ASK);

		if(currentPrice > (maPrice + (atrVal * atrExitRate))){
			return EXIT;
		}

	}else if(opType == OP_SELL){
		double currentPrice = MarketInfo(symbol,MODE_BID);
		if(currentPrice < (maPrice - (atrVal * atrExitRate))){
			return EXIT;
		}
	}

	return DO_NOTHING;

}