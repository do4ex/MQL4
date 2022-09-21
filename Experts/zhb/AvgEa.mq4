//+------------------------------------------------------------------+
//|                                                       EaTest.mq4 |
//|                                                         zouhaibo |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
/*
货币对：EUR/USD 时间周期：M30 技术指标：鳄鱼三线 8，5，3
趋势指标+震荡指标 开仓条件：买入条件 鳄鱼三线成顺序 用Force指标过滤盘整行情
平仓条件：鳄鱼线交叉 */
#property copyright "zhb"
#property link "QQ:921795"
#property strict
extern int stopLoss = 0;
extern int takeProfit = 0;
extern double maxRisk = 30; // 资金风险1=1%
extern double filter=0.35; // force指标过滤参数
string eurUsd= "EURUSD";
input int timeintervel = PERIOD_D1;
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
   start1();
  }

//+------------------------------------------------------------------+
int start1() {

	setLable("时间栏","星期"+ DayOfWeek()+" 市场时间："+ Year()+"-"+ Month()+ "-"+ Day()+ "-"+ Hour()+ ":"+ Minute()+
	":"+Seconds(), 200,0,9,"Verdana",Red);

	setLable("信息栏","市场信号："+ returnMarketInfomation()+ " 当前订单盈亏： "+ DoubleToStr(OrderProfit(),2),5,20,10,
	"Verdana",Blue);

	// 买单 止损价格，止盈价格
	double stopBuyPrice = Ask - stopLoss * Point;
	double profitBuyPrice = Ask + stopLoss * Point;

	// 卖单 止损价格，止盈价格
	double stopSellPrice = Bid + stopLoss * Point;
	double profitSellPrice = Bid - stopLoss* Point;

	if(stopLoss == 0){
		stopBuyPrice = 0;
		stopSellPrice = 0;
	}
	if(takeProfit == 0 ){
		profitBuyPrice =0;
		profitSellPrice =0;
	}

	if(OrdersTotal()== 1){
        OrderSelect(0,SELECT_BY_POS);// 选当前订单
		// 新开仓订单时间不足一直时间周期，不错任何操作返回
//		if(TimeCurrent() - OrderOpenTime() <= PERIOD_M30 * 60){
//			return (0);
//		}
		// 周五20点停止交易，盈利订单平仓
//        if(DayOfWeek() == 5 && Hour() >= 20 && Minute() >=0){
//            if(OrderProfit() > 0){
//
//                if(OrderType() == OP_BUY){
//                    OrderClose(OrderTicket(),OrderLots(),Bid,0,clrBlue);
//                }else{
//                    OrderClose(OrderTicket(),OrderLots(),Ask,0,clrBlue);
//                }
//                return (0);
//            }
//        }

        // 买单如果下穿，直接平仓
        if(Symbol() == eurUsd  && OrderType() == OP_BUY
        && returnMarketInfomation() == "sell"){
            OrderClose(OrderTicket(),OrderLots(),Bid,0,clrBlue);
            return (0);
        }
        // 或者卖单上穿，进行平仓
        if(Symbol() == eurUsd && OrderType() == OP_SELL
        && returnMarketInfomation() == "buy"){
            OrderClose(OrderTicket(),OrderLots(),Ask,0,clrBlue);
            return (0);
        }


	// 开仓操作
    }else if (OrdersTotal() == 0){

		if(returnMarketInfomation() == "buy"){
			OrderSend(Symbol(),OP_BUY,lotsOptimized(maxRisk),Ask,0,stopBuyPrice,profitBuyPrice);
		}
		if(returnMarketInfomation() == "sell"){
			OrderSend(Symbol(),OP_SELL,lotsOptimized(maxRisk),Bid,0,stopSellPrice,profitSellPrice);
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
double lotsOptimized(double riskValue) {

	double lots = NormalizeDouble((AccountBalance()* riskValue/100)/
	MarketInfo(Symbol(),MODE_MARGINREQUIRED),2)/10;
	// 最大可开仓手数
	if(lots < 0.01){
		lots = 0;
		Print("保证金余额不足！");
	}
	// 如果上一单亏损，进行减半处理？
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

//double  iMA(
//   string       symbol,           // symbol
//   int          timeframe,        // timeframe
//   int          ma_period,        // MA averaging period
//   int          ma_shift,         // MA shift
//   int          ma_method,        // averaging method
//   int          applied_price,    // applied price
//   int          shift             // shift
//   );
	// 最新的均线数据
	double newPrice350 = NormalizeDouble(iMA(eurUsd,timeintervel,350,0,MODE_SMA,PRICE_CLOSE,0),4);
	double  newPrice100= NormalizeDouble(iMA(eurUsd,timeintervel,100,0,MODE_SMA,PRICE_CLOSE,0),4);

	// 上一个均线数据
	double oldPrice350 = NormalizeDouble(iMA(eurUsd,timeintervel,350,0,MODE_SMA,PRICE_CLOSE,1),4);
	double oldPrice100 = NormalizeDouble(iMA(eurUsd,timeintervel,100,0,MODE_SMA,PRICE_CLOSE,1),4);


	if(newPrice100 > newPrice350 && oldPrice100 <= oldPrice350 ){
		marketInfoResult = "buy";
	}
	if(newPrice100 < newPrice350 && oldPrice100 >= oldPrice350){
		marketInfoResult = "sell";
	}
	return (marketInfoResult);

}

