//+------------------------------------------------------------------+
//|                                                       EaTest.mq4 |
//|                                                         zouhaibo |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
/*
货币对：EUR/USD 时间周期：M30 技术指标： 平均移动线
开仓条件：买入条件
平仓条件：*/
#property copyright "zhb"
#property link "QQ:921795"
#property strict
// 下跌 止损比例
input double stopLossRate = 0.01;
input int takeProfit = 0;
extern double maxRisk = 30; // 资金风险1=1%
string symbol= Symbol();
input int intervel = PERIOD_D1;
input int maMin = 100;
input int maMax = 350;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
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
int ticket() {

	setLable("时间栏","星期"+ DayOfWeek()+" 市场时间："+ Year()+"-"+ Month()+ "-"+ Day()+ "-"+ Hour()+ ":"+ Minute()+
	":"+Seconds(), 200,0,9,"Verdana",Red);

	setLable("信息栏","市场信号："+ returnMarketInfomation()+ " 当前订单盈亏： "+ DoubleToStr(OrderProfit(),2),5,20,10,
	"Verdana",Blue);

	if(OrdersTotal()== 1){
        OrderSelect(0,SELECT_BY_POS);// 选当前订单
        // 买单如果下穿，直接平仓
        if(Symbol() == symbol  && OrderType() == OP_BUY
        && returnMarketInfomation() == "closeBuy"){
            OrderClose(OrderTicket(),OrderLots(),Bid,0,clrBlue);
            return (0);
        }
        // 或者卖单上穿，进行平仓
        if(Symbol() == symbol && OrderType() == OP_SELL
        && returnMarketInfomation() == "closeSell"){
            OrderClose(OrderTicket(),OrderLots(),Ask,0,clrBlue);
            return (0);
        }

	// 开仓操作
    }else if (OrdersTotal() == 0){

		if(returnMarketInfomation() == "buy"){
			// 止损价格
			double stopBuyPrice = MarketInfo(symbol,MODE_BID) - NormalizeDouble(MarketInfo(symbol,MODE_ASK) * stopLossRate,5);
			int ticket = OrderSend(Symbol(),OP_BUY,lotsOptimized(),MarketInfo(symbol,MODE_ASK) ,0,stopBuyPrice,0);
		}
		if(returnMarketInfomation() == "sell"){
			// 止损价格 1手 211
			double stopSellPrice =MarketInfo(symbol,MODE_BID) +  NormalizeDouble(MarketInfo(symbol,MODE_BID) * stopLossRate,5);
			OrderSend(Symbol(),OP_SELL,lotsOptimized(),MarketInfo(symbol,MODE_BID) ,0,stopSellPrice,0);
		}

		return (0);

    }else{

        Print("发生了错误，订单数量为："+ OrdersTotal());
    }

    return (0);

}

/*
函数：优化保证金，确定开仓量，进行风险控制 根据风险riskValue计算开仓量
如果出现亏损订单，则下一单开仓量减半
*/
double lotsOptimized() {

	double lots = NormalizeDouble((AccountBalance()* maxRisk/100)/MarketInfo(symbol,MODE_MARGINREQUIRED),2)/10;
	// 最大可开仓手数
	if(lots < 0.01){
		lots = 0;
		Print("保证金余额不足！");
	}
	// todo 如果上一单亏损，进行减半处理？
//	OrderSelect(OrdersHistoryTotal()-1,SELECT_BY_POS,MODE_HISTORY);
//	if(OrderProfit() < 0){
//		lots = 0.01;
//	}
	return (lots);

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
	double newPriceMax = NormalizeDouble(iMA(symbol,intervel,maMax,0,MODE_SMA,PRICE_CLOSE,0),4);
	double  newPriceMin= NormalizeDouble(iMA(symbol,intervel,maMin,0,MODE_SMA,PRICE_CLOSE,0),4);

	double newPriceMaxEma = NormalizeDouble(iMA(symbol,intervel,maMax,0,MODE_EMA,PRICE_CLOSE,0),4);
	double  newPriceMinEma= NormalizeDouble(iMA(symbol,intervel,maMin,0,MODE_EMA,PRICE_CLOSE,0),4);

	// 上一个均线数据
	double oldPriceMax = NormalizeDouble(iMA(symbol,intervel,maMax,0,MODE_SMA,PRICE_CLOSE,1),4);
	double oldPriceMin = NormalizeDouble(iMA(symbol,intervel,maMin,0,MODE_SMA,PRICE_CLOSE,1),4);

	double oldPriceMaxEma = NormalizeDouble(iMA(symbol,intervel,maMax,0,MODE_EMA,PRICE_CLOSE,1),4);
	double oldPriceMinEma = NormalizeDouble(iMA(symbol,intervel,maMin,0,MODE_EMA,PRICE_CLOSE,1),4);

	// 上穿
	if(newPriceMin > newPriceMax && oldPriceMin <= oldPriceMax ){
		marketInfoResult = "buy";
	}
	// ema
	if(newPriceMinEma > newPriceMaxEma && oldPriceMinEma <= oldPriceMaxEma){
		marketInfoResult = "closeSell";
	}

	// 下穿
	if(newPriceMin < newPriceMax && oldPriceMin >= oldPriceMax){
		marketInfoResult = "sell";
	}

	if(newPriceMinEma < newPriceMaxEma && oldPriceMinEma >= oldPriceMaxEma){
		marketInfoResult = "closeBuy";
	}

	return (marketInfoResult);

}

