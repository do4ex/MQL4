/*
货币对：EUR/USD 时间周期：M30 技术指标：鳄鱼三线 8，5，3
趋势指标+震荡指标 开仓条件：买入条件 鳄鱼三线成顺序 用Force指标过滤盘整行情
平仓条件：鳄鱼线交叉 */
#property copyright "laoyee"
#property link "QQ:921795"
extern int StopLoss=40;
extern int TakeProfit=0;
extern double MaxRisk=30;//资金风险1=1%
extern double Filter=0.35;//Force指标过滤参数
double Alligator_jaw,Alligator_teeth,Alligator_lips, Envelops21_upper,
Envelops21_lower,Force3;
int start()
{
  OrderSelect(0, SELECT_BY_POS);//选当前订单
  //显示市场信息
  SetLable("时间栏","星期" + DayOfWeek() + " 市场时间：" +
  Year() + "-" + Month() + "-" + Day() + " " + Hour() + ":" + Minute()
                  + ":" + Seconds(), 200, 0, 9, "Verdana", Red);
  SetLable("信息栏", "市场信号：" + ReturnMarketInfomation() + " 当前订单盈亏："
          + DoubleToStr(OrderProfit(), 2), 5, 20, 10, "Verdana", Blue);
  //周五20点停止交易，盈利订单平仓
  if (DayOfWeek() == 5 && Hour() >= 20 && Minute() >= 0)
  {
      if (OrderProfit() > 0)
      {
          OrderClose(OrderTicket(), OrderLots(), Ask, 0);
      }
      return (0);
  }
  //新开仓订单时间不足一个时间周期，不做任何操作返回
  if (TimeCurrent() - OrderOpenTime() <= PERIOD_M30 * 60)
  {
      return (0);
  }
  double sl_buy = Ask - StopLoss * Point;
  double tp_buy = Ask + TakeProfit * Point;
  double sl_sell = Bid + StopLoss * Point;
  double tp_sell = Bid - TakeProfit * Point;
  if (StopLoss == 0)
  {
      sl_buy = 0;
      sl_sell = 0;
  }
  if (TakeProfit == 0)
  {
      tp_buy = 0;
      tp_sell = 0;
  } //开仓操作
  if (Symbol() == "EURUSD" && OrdersTotal() == 0)//EURUSD货币对，没有订单，则开仓
  {
      if (ReturnMarketInfomation() == "Buy")
      {
          OrderSend(Symbol(), OP_BUY, LotsOptimized(MaxRisk), Ask, 0, sl_buy, tp_buy);
      }
      if (ReturnMarketInfomation() == "Sell")
      {
          OrderSend(Symbol(), OP_SELL, LotsOptimized(MaxRisk), Bid, 0, sl_sell, tp_sell);
      }
  } //平仓操作
  if (OrderProfit() > 0)//止盈操作
  {
      if (Symbol() == "EURUSD" && OrdersTotal() == 1 && OrderType() == OP_BUY
              && ReturnMarketInfomation() == "DownCross")
      {
          OrderClose(OrderTicket(), OrderLots(), Ask, 0);
      }
      if (Symbol() == "EURUSD" && OrdersTotal() == 1 && OrderType() == OP_SELL
              && ReturnMarketInfomation() == "UpCross")
      {
          OrderClose(OrderTicket(), OrderLots(), Bid, 0);
      }
  }
  if (OrderProfit() < 0)//止损操作
  {
      if (Symbol() == "EURUSD" && OrdersTotal() == 1 && OrderType() == OP_BUY && Alligator_lips < Alligator_jaw)
      {
          OrderClose(OrderTicket(), OrderLots(), Ask, 0);
      }
      if (Symbol() == "EURUSD" && OrdersTotal() == 1 && OrderType() == OP_SELL && Alligator_lips > Alligator_jaw)
      {
          OrderClose(OrderTicket(), OrderLots(), Bid, 0);
      }
  }
  return (0);
}

/* 函数：优化保证金，确定开仓量，进行风险控制 根据风险值RiskValue计算开仓量
如果出现亏损订单，则下一单开仓量减半 */
double LotsOptimized(double RiskValue){

  double iLots = NormalizeDouble((AccountBalance() * RiskValue / 100) / MarketInfo(Symbol(),
   MODE_MARGINREQUIRED), 2);
  //最大可开仓手数
  if (iLots < 0.01)
  {
      iLots = 0;
      Print("保证金余额不足！");
  }
  OrderSelect(OrdersHistoryTotal() - 1, SELECT_BY_POS, MODE_HISTORY);
  if (OrderProfit() < 0)
  {
      iLots = 0.01;//上一个订单亏损，本次开仓量减半
  }
  return (iLots);
}

/* 函数：在屏幕上显示标签 LableName：标签名称；LableDoc：文本内容；LableX：标签X位置；LableY：标签Y位置； DocSize：文本字号；DocStyle：
文本字体；DocColor：文本颜色 */
void SetLable(string LableName, string LableDoc, int LableX, int LableY,
int DocSize, string DocStyle,color DocColor)
{
  ObjectCreate(LableName, OBJ_LABEL, 0, 0, 0);
  ObjectSetText(LableName, LableDoc, DocSize, DocStyle, DocColor);
  ObjectSet(LableName, OBJPROP_XDISTANCE, LableX);
  ObjectSet(LableName, OBJPROP_YDISTANCE, LableY);
}
/* 函数：返回市场信息 获取技术指标参数，通过比对，返回市场信息：
Buy-买入信号，sell-卖出信号，
Rise-涨势行情，Fall-跌势行情， UpCross-向上翻转，
DownCross-向下反转,反转信号为平仓信号 */

string ReturnMarketInfomation()
{
  string MktInfo = "N/A";
  //读取指标数值
  Alligator_jaw = NormalizeDouble(iAlligator("EURUSD", 30, 8, 0, 5, 0, 3, 0,
   MODE_EMA, PRICE_WEIGHTED, MODE_GATORJAW, 0), 4);
  Alligator_teeth = NormalizeDouble(iAlligator("EURUSD", 30, 8, 0, 5, 0, 3, 0,
  MODE_EMA, PRICE_WEIGHTED, MODE_GATORTEETH, 0), 4);
  Alligator_lips = NormalizeDouble(iAlligator("EURUSD", 30, 8, 0, 5, 0, 3, 0,
  MODE_EMA, PRICE_WEIGHTED, MODE_GATORLIPS, 0), 4);
  double Alligator_jaw_1 = NormalizeDouble(iAlligator("EURUSD", 30, 8, 0, 5, 0, 3, 0,
   MODE_EMA, PRICE_WEIGHTED, MODE_GATORJAW, 1), 4);
  double Alligator_teeth_1 = NormalizeDouble(iAlligator("EURUSD", 30, 8, 0, 5, 0, 3, 0,
  MODE_EMA, PRICE_WEIGHTED, MODE_GATORTEETH, 1), 4);
  double Alligator_lips_1 = NormalizeDouble(iAlligator("EURUSD", 30, 8, 0, 5, 0, 3, 0,
  MODE_EMA, PRICE_WEIGHTED, MODE_GATORLIPS, 1), 4);
  Force3 = NormalizeDouble(iForce("EURUSD", 30, 3, MODE_EMA, PRICE_WEIGHTED, 0), 4);
  //指标分析，返回市场信息 ||Force3<-FilterForce3>Filter ||
  if (Alligator_lips > Alligator_teeth && Alligator_lips_1 <= Alligator_teeth_1)
  {
      MktInfo = "UpCross";
  }
  if (Alligator_lips < Alligator_teeth && Alligator_lips_1 >= Alligator_teeth_1)
  {
      MktInfo = "DownCross";
  }
  if (Alligator_lips > Alligator_teeth && Alligator_teeth > Alligator_jaw)
  {
      MktInfo = "Rise";
  }
  if (Alligator_lips < Alligator_teeth && Alligator_teeth < Alligator_jaw)
  {
      MktInfo = "Fall";
  }
  if (Force3 > Filter && MktInfo == "Rise")
  {
      MktInfo = "Buy";
  }
  if (Force3 < -Filter && MktInfo == "Fall")
  {
      MktInfo = "Sell";
  }
  return (MktInfo);
}