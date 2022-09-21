#define VERSION "2.00" 
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   VERSION
#property strict

// enum
enum RUN_MODE_EUNM {NormalMode, SleepMode, BuyOnlyMode, SellOnlyMode,
 CloseBuyMode, CloseSellMode, CloseAllMode, MinimizeBuyTpMode,
 MinimizeSellTpMode, MinimizeAllTpMode, SetBuyTpMode, SetSellTpMode};
enum STRATEGY_EUNM {EURUSD, GBPJPY, GBPJPYFIB, GBPJPYFIB2, EURUSD_GBPJPY};

// input
const input RUN_MODE_EUNM RUN_MODE=NormalMode;
const input STRATEGY_EUNM STRATEGY_EUNM_INPUT=EURUSD;
const input bool AUTO_MULTIPLE=true;
const input uint MULTIPLE=1;
const input uint MIN_BALANCE=4000;
const input uint UNIT_BALANCE=5000;
const input double TP_SETTING;
const input bool IGNORE_MAGIC_NUMBER=true;
const input bool AUTO_SL=true;
// constant
const int SLIPPAGE = 3;
const string COMMENT = "EA";

struct Config {
  string name;
  string symbol;
  double weights[25];
  double steps[25];
  double tpMargins[25];
  int magicNumber;
  string begin;
  string end;
  string MonBegin;
  string FriEnd;
};
// settings
Config configs[] = {
  {
    "EURUSD",
    "EURUSD.s",
    {1,1,2,3,4,5,8,11,15,21,29,30,30,30,30,30,30,30,30,30,30,30,30,30,30},
    {75,75,75,75,75,75,75,75,75,75,75,75,55,55,55,55,55,55,55,55,55,55,55,55,55},
    {120,28,27,26,25,24,23,22,21,20,19,18,17,16,15,14,13,12,11,10,9,8,7,6,5},
    1001,
    "03:30:00", // 8:30
    "21:30:00", // 2:30
    "05:30:00", // 10:30
    "15:30:00" // 20:30
  },
  {
    "GBPJPY",
    "GBPJPY.s",
    {1,1,2,3,4,5,8,11,15,21,29,30,30,30,30,30,30,30,30,30,30,30,30,30,30},
    {50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50,50},
    {50,28,27,26,25,24,23,22,21,20,19,18,17,16,15,14,13,12,11,10,9,8,7,6,5},
    1002,
    "00:10:00", // 5:10
    "23:10:00", // 4:10
    "05:00:00", // 10:00
    "20:30:00" // 1:30
  },
  {
    "GBPJPYFIB",
    "GBPJPY.s",
    {1,1,2,3,5,8,13,21,34,55,55,55,55,55,55,55,55,55,55,55},
    {40,40,40,40,40,40,40,40,40,40,40,40,40,40,40,40,40,40,40,30},
    {40,20,19,18,17,16,15,14,13,12,11,10,9,8,7,6,5,4,3,2},
    1002,
    "00:10:00", // 5:10
    "23:10:00", // 4:10
    "05:00:00", // 10:00
    "20:30:00" // 1:30
  },
  {
    "GBPJPYFIB2",
    "GBPJPY.s",
    {1,1,2,3,5,8,13,21,34,55},
    {50,50,50,50,50,50,50,50,50,50},
    {50,10,9,8,7,6,5,4,3,2},
    1002,
    "00:10:00", // 5:10
    "23:10:00", // 4:10
    "05:00:00", // 10:00
    "20:30:00" // 1:30
  }
};

struct Order {
  int ticket;
  double openPrice;
  double tp;
  datetime openTime;
  double lots;
};
struct Layer {
  int level;
  double totalLots; // 总手数
  double maxSpacing; // 最大距离
};
class Math {
  public:
    static bool eq(double a, double b) {
      return fabs(a-b) < 0.000000001;
    }
    static bool gt(double a, double b) {
      return a-b > 0.000000001;
    }
    static bool ge(double a, double b) {
      return eq(a, b) || gt(a, b);
    }
    static double add(double a,double b) {
      return (a*MathPow(10,12)+b*MathPow(10,12))/MathPow(10,12);
    }
    static double sub(double a,double b) {
      return add(a, -b);
    }
};
class Arrays {
  public:
    template<typename T>
    static void remove(T &arr[], int index) {
      T tempArray[];
      //Lets copy index 0-4 as the input index is to remove index 5
      ArrayCopy(tempArray,arr,0,0,index);
      //Now Copy index 6-9, start from 6  as the input index is to remove index 5
      ArrayCopy(tempArray,arr,index,(index+1));
      //copy Array back
      ArrayFree(arr);
      ArrayCopy(arr,tempArray);
    }
    template<typename T>
    static void append(T &arr[], T &t) {
      ArrayResize(arr, ArraySize(arr)+1);
      arr[ArraySize(arr)-1]=t;
    }
    template<typename T>
    static bool contains(T &arr[], T item) {
      for(int i=0; i<ArraySize(arr); i++) {
        if(arr[i] == item) {
          return true;
        }
      }
      return false;
    }
};
class Tools {
  public:
    static datetime GMT3(string localStr) {
      datetime localTime = StringToTime(localStr);
      datetime currentTime = TimeCurrent();
      if(TimeDay(currentTime) == TimeDay(localTime)) {
        return localTime;
      }
      int day1 = 3600*24;
      return localTime-day1;
    }
    static void createLine(string symbol, string name, int orderType, double price) {
      string objName = symbol+"_"+name+"_"+IntegerToString(orderType);
      ObjectCreate(objName, OBJ_HLINE, 0, 0, price);
      ObjectSet(objName, OBJPROP_COLOR, clrYellow);
    }
    static void deleteLine(string symbol, string name, int orderType) {
      string objName = symbol+"_"+name+"_"+IntegerToString(orderType);
      ObjectDelete(objName);
    }
};
class Trade {
  public:
    static double bid(string symbol) {
      return MarketInfo(symbol, MODE_BID);
    }
    static double ask(string symbol) {
      return MarketInfo(symbol, MODE_ASK);
    }
    static double point(string symbol) {
      // 最大精度: 0.00001=1e5
      return MarketInfo(symbol, MODE_POINT);
    }
    static double minLot(string symbol) {
      // 最小手数
      return MarketInfo(symbol, MODE_MINLOT);
    }
    static double stopLevel(string symbol) {
      // 最小止损间隔
      return MarketInfo(symbol, MODE_STOPLEVEL);
    }
    static int buyMarket(string symbol, double lots, int magicNumber) {
      if(Math::eq(lots, 0)) return 0;
      int ticket=OrderSend(symbol,OP_BUY,lots,0,SLIPPAGE,0,0,COMMENT,magicNumber,0,clrBlue);
      if(ticket<0) {
        printf("#%i %s buyMarket error=%i, lots=%g", ticket, symbol, GetLastError(), lots);
      }
      return ticket;
    }
    static int sellMarket(string symbol, double lots, int magicNumber) {
      if(Math::eq(lots, 0)) return 0;
      int ticket=OrderSend(symbol,OP_SELL,lots,0,SLIPPAGE,0,0,COMMENT,magicNumber,0,clrRed);
      if(ticket<0) {
        printf("#%i %s sellMarket error=%i, lots=%g", ticket, symbol, GetLastError(), lots);
      }
      return ticket;
    }
    static void modify(int ticket, double tp) {
      bool res=OrderModify(ticket,0,0,tp,0,clrOrange);
      if(!res) printf("#%i modify error=%i, tp=%g", ticket, GetLastError(), tp);
    }
    static void close(int ticket, double lots) {
      if(Math::eq(lots, 0)) return;
      bool res=OrderClose(ticket,lots,0,0,clrYellow);
      if(!res) printf("#%i close error=%i lots=%g", ticket, GetLastError(), lots);
    }
    static void loadOrders(Order &orders[], string symbol, int orderType, int magicNumber) {
      ArrayFree(orders);
      for(int i=0; i<OrdersTotal(); i++) {
        if(!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) break;
        if(OrderSymbol() != symbol) continue;
        if(!IGNORE_MAGIC_NUMBER && OrderMagicNumber() != magicNumber) continue;
        Order order = buildOrder(OrderTicket());
        if(OrderType() == orderType) {
          Arrays::append(orders, order);
        }
      }
    }
    static Order buildOrder(int ticket) {
      Order order = {};
      order.ticket = OrderTicket();
      order.tp = OrderTakeProfit();
      order.openPrice = OrderOpenPrice();
      order.openTime = OrderOpenTime();
      order.lots = OrderLots();
      return order;
    }
};

class Mt {
  protected:
    Layer getLayer(double spacing) {
      for(int i=0; i<ArraySize(layers); i++) {
        if(Math::gt(layers[i].maxSpacing, spacing)) return layers[i];
      }
      Layer layer = layers[ArraySize(layers)-1];
      return layer;
    }
    // 订单最大价格
    double getMaxPrice() {
      double _maxPrice = 0;
      for(int i=0; i<ArraySize(orders); i++) {
        double openPrice = orders[i].openPrice;
        if(Math::gt(openPrice, _maxPrice)) _maxPrice = openPrice;
      }
      return _maxPrice;
    }
    // 订单最小价格
    double getMinPrice() {
      double maxDouble = 1.7 * MathPow(10,308);
      double _minPrice = maxDouble;
      for(int i=0; i<ArraySize(orders); i++) {
        double openPrice = orders[i].openPrice;
        if(Math::gt(_minPrice, openPrice)) _minPrice = openPrice;
      }
      return _minPrice;
    }
    // 价格间距
    double getMaxSpacing() {
      return Math::gt(minPrice, maxPrice) ? 0 : Math::sub(maxPrice, minPrice);
    }
    double getTotalLots() {
      double sum = 0;
      for(int i=0; i<ArraySize(orders); i++) {
        sum += orders[i].lots;
      }
      return sum;
    }
    // 是否有设置止盈
     bool isTpMissing() {
      for(int i=0; i<ArraySize(orders); i++) {
        // 每一个都没有设置止盈
        if(Math::eq(orders[i].tp, 0)) return true;
      }
      return false;
    }
    void initLayers(const double &_weights[], const double &_steps[]) {
      ArrayFree(layers);
      ArrayResize(layers, ArraySize(_weights));
      double lotsSum = 0;
      double spacingSum = 0;
      for(int i=0; i<ArraySize(_weights); i++) {
        // 手数进行叠加
        lotsSum = Math::add(lotsSum, _weights[i]*unitLot);
        // 间距进行叠加
        spacingSum = Math::add(spacingSum, _steps[i]*point);
        Layer layer = {};
        layer.level = i+1;
        layer.totalLots = lotsSum;
        layer.maxSpacing = spacingSum;
        layers[i]=layer;
        // printf("level=%i, totalLots=%g, maxSpacing=%g",layer.level,lotsSum,spacingSum);
      }
    }
    void closeAll() {
      for(int i=ArraySize(orders)-1; i>=0; i--) {
        Trade::close(orders[i].ticket, orders[i].lots);
      }
    }
  public:
    int orderType; // OP_BUY=0, OP_SELL=1
    // 系统配置
    double minLot; // 最小下单量
    double point; // 最大精度
    double stopLevel; // 最小止损点
    // 策略配置
    Config config;
    // 其他参数
    double autoSL;
    double unitLot; // 单位手数
    double currentPrice;
    double maxPrice;
    double minPrice;
    double currentSpacing; // 当前间距 买卖不一样
    double maxSpacing; // 订单组内价格最大间距
    Layer currentLayer;
    Layer nextLayer;
    
    Order orders[];
    Layer layers[];

    // Mt() {}
    void init(uint _multiple, Config &_config, bool _autoSL) {
      this.config = _config;
      this.autoSL=_autoSL;
      
      this.minLot = Trade::minLot(config.symbol);
      this.point = Trade::point(config.symbol);
      this.stopLevel = Trade::stopLevel(config.symbol);
      this.unitLot = _multiple*minLot;
      initLayers(config.weights, config.steps);
    }

    void reloadOrders() {
      Trade::loadOrders(orders, config.symbol, orderType, config.magicNumber);
      this.currentPrice = getCurrentPrice();
      this.maxPrice = getMaxPrice();
      this.minPrice = getMinPrice();
      this.currentSpacing = getCurrentSpacing();
      this.maxSpacing = getMaxSpacing();

      Layer _currentLayer = getLayer(maxSpacing);
      uint _multiple = multiple();

      if(unitLot != _multiple*minLot) {
        printf("%s unitLot %g => %g", config.symbol, unitLot, _multiple*minLot);
        initLayers(config.weights, config.steps);
      }
      if(currentLayer.level != _currentLayer.level) {
        printf("%s currentLayer %i => %i", config.symbol, currentLayer.level, _currentLayer.level);
      }

      this.unitLot = _multiple*minLot;
      this.currentLayer=_currentLayer;

	  // 当前亏损间距 大于 当前层的最大价差
      if(currentSpacing >= currentLayer.maxSpacing) {
        // 生成下一个 层
        this.nextLayer=getLayer(currentSpacing);
      } else {
        if(currentLayer.level < ArraySize(layers)) {
          this.nextLayer=layers[currentLayer.level];
        } else {
          this.nextLayer=layers[ArraySize(layers)-1];
        }
      }
    }

    void tick() {
      reloadOrders();
      if(ArraySize(orders) > 0) {
        // (买单)currentSpacing = 订单组最大价格- 当前价格   maxSpacing = 订单最大价格- 订单组最小价格
        //(卖单)currentSpacing =  当前价格 -订单组最小价格
        if(currentSpacing >= currentLayer.maxSpacing) { // spacing up to max
          double totalLots = getTotalLots();
          // 是否为最后一层
          if(Math::ge(currentLayer.level, layers[ArraySize(layers)-1].level)) { // lot up to limit
            // stop loss, send mail
            Print("stop loss!");
            sendMail("Alert", "stop loss!");
            if(autoSL) closeAll();
          } else {
            // 不为最后一层 ,进行加仓
            double lots = Math::sub(nextLayer.totalLots, totalLots);
            if(Math::gt(lots, 0)) {
              // 反向加仓
              newOrder(lots);
              printf("%s totalLots: %g => %g", config.symbol, totalLots, nextLayer.totalLots);
            }
          }
        }
        // 第一次进来
      } else {
        // 正向加仓
        if(!isSleep(config)) {
          newOrder(layers[0].totalLots);
        }
      }
      // 计算止盈
      if(isTpMissing()) {
        updateTp(isSleep(config));
      }
      Tools::deleteLine(config.symbol, "nextOpenPrice", orderType);
      Tools::createLine(config.symbol, "nextOpenPrice", orderType, nextOpenPrice());
    }

	// 计算均价
    double weightedAverage() {
      double denominator = 0;
      double numerator = 0;
      for(int i=0; i<ArraySize(orders); i++) {
        // 计算总价格
        denominator = Math::add(denominator, orders[i].openPrice * orders[i].lots);
        // 计算总手数
        numerator = Math::add(numerator, orders[i].lots);
      }
      if(numerator == 0) return 0;
      // 平均开仓价格
      return denominator/numerator;
    }
	// 设置止盈
    void updateTp(bool isMin=false) {
        // 加载 订单
      reloadOrders();
      // 重新设置止盈
      setTp(availableTp(calcTp(isMin)));
    }
	// 设置止盈
    void setTp(double tp) {
      if(Math::ge(0, tp)) {
        printf("error setTp: tp=%g", tp);
        return;
      }
      reloadOrders();
      for(int i=0; i<ArraySize(orders); i++) {
        if(Math::eq(orders[i].tp, tp)) continue;
        Trade::modify(orders[i].ticket, tp);
      }
    }

    void close() {
      reloadOrders();
      closeAll();
    }

    virtual double getCurrentPrice() = 0;
    virtual double nextOpenPrice() = 0;
    virtual double getCurrentSpacing() = 0;
    virtual void newOrder(double lots) = 0;
    virtual double calcTp(bool isMin) = 0;
    virtual double availableTp(double tp) = 0;
};

class BuyMt : public Mt {
  public:
    BuyMt() {orderType=OP_BUY;}
    double getCurrentPrice() {
      return Trade::ask(config.symbol);
    }
    double nextOpenPrice() {
      return Math::sub(maxPrice, currentLayer.maxSpacing);
    }

    // 当前间距 = 订单组最大价格 - 当前价格
    double getCurrentSpacing() {
      if(ArraySize(orders) == 0) return 0;
      double spacing = Math::sub(maxPrice, currentPrice);
      return Math::gt(spacing, 0) ? spacing : 0;
    }
    void newOrder(double lots) {
      Trade::buyMarket(config.symbol, lots, config.magicNumber);
    }
    // 计算止盈价格 止盈价格= 均价 + (手数对应的盈利点)* point;
    double calcTp(bool isMin) {
      if(isMin) {
        return Math::add(weightedAverage(), config.tpMargins[ArraySize(config.tpMargins)-1]*point);
      }
      return Math::add(weightedAverage(), config.tpMargins[currentLayer.level-1]*point);
    }
    // 允许的赢利点
    double availableTp(double tp) {
      double minTp = Math::add(Trade::ask(config.symbol), stopLevel*point);
      return tp < minTp ? minTp : tp;
    }
};

class SellMt : public Mt {
  public:
    SellMt() {orderType=OP_SELL;}
    double getCurrentPrice() {
      return Trade::bid(config.symbol);
    }
    double nextOpenPrice() {
      return Math::add(minPrice, currentLayer.maxSpacing);
    }
    double getCurrentSpacing() {
      if(ArraySize(orders) == 0) return 0;
      double spacing = Math::sub(currentPrice, minPrice);
      return Math::gt(spacing, 0) ? spacing : 0;
    }
    void newOrder(double lots) {
      Trade::sellMarket(config.symbol, lots, config.magicNumber);
    };
    // 计算止盈
    double calcTp(bool isMin) {
      if(isMin) {
        return Math::sub(weightedAverage(), config.tpMargins[ArraySize(config.tpMargins)-1]*point);  
      }
      return Math::sub(weightedAverage(), config.tpMargins[currentLayer.level-1]*point);
    }
    double availableTp(double tp) {
      double maxTp = Math::sub(Trade::ask(config.symbol), stopLevel*point);
      return tp > maxTp ? maxTp : tp;
    }
};

BuyMt buyMtList[];
SellMt sellMtList[];

int OnInit() {
  ObjectsDeleteAll();
  Print("Version: ", VERSION);
  printf("RUN_MODE: %s, STRATEGY_EUNM: %s", EnumToString(RUN_MODE), EnumToString(STRATEGY_EUNM_INPUT));
  PrintFormat("MIN_BALANCE: %i, UNIT_BALANCE: %i, multiple: %i", MIN_BALANCE, UNIT_BALANCE, multiple());
  Print("IsTradeAllowed: ", IsTradeAllowed());
  // printf("Bid: %g, Ask: %g", Trade::bid("XAUUSD.s"), Trade::ask("XAUUSD.s"));
  if(IsTesting()) Print("I am testing now");
  
  if(!initMtList()) {
    Print("initMtList failed! ");
    return(INIT_FAILED);
  }

  if(RUN_MODE == CloseBuyMode) {
    for(int i=0; i<ArraySize(buyMtList); i++) buyMtList[i].close();
  } else if(RUN_MODE == CloseSellMode) {
    for(int i=0; i<ArraySize(sellMtList); i++) sellMtList[i].close();
  } else if(RUN_MODE == CloseAllMode) {
    for(int i=0; i<ArraySize(buyMtList); i++) buyMtList[i].close();
    for(int i=0; i<ArraySize(sellMtList); i++) sellMtList[i].close();
  } else if(RUN_MODE == MinimizeBuyTpMode) {
    for(int i=0; i<ArraySize(buyMtList); i++) buyMtList[i].updateTp(true);
  } else if(RUN_MODE == MinimizeSellTpMode) {
    for(int i=0; i<ArraySize(sellMtList); i++) sellMtList[i].updateTp(true);
  } else if(RUN_MODE == MinimizeAllTpMode) {
    for(int i=0; i<ArraySize(buyMtList); i++) buyMtList[i].updateTp(true);
    for(int i=0; i<ArraySize(sellMtList); i++) sellMtList[i].updateTp(true);
  } else if(RUN_MODE == SetBuyTpMode) {
    for(int i=0; i<ArraySize(buyMtList); i++) buyMtList[i].setTp(TP_SETTING);
  } else if(RUN_MODE == SetSellTpMode) {
    for(int i=0; i<ArraySize(sellMtList); i++) sellMtList[i].setTp(TP_SETTING);
  }
  return(INIT_SUCCEEDED);
}

void OnTick() {
  if(!IsTradeAllowed()) {
    // Print("trade is not allowed");
    return;
  }
  if(!balanceEnough()) return;

  RefreshRates();

  if(RUN_MODE == NormalMode || RUN_MODE == SleepMode) {
    for(int i=0; i<ArraySize(buyMtList); i++) buyMtList[i].tick();
    for(int i=0; i<ArraySize(sellMtList); i++) sellMtList[i].tick();
  } else if(RUN_MODE == BuyOnlyMode) {
    for(int i=0; i<ArraySize(buyMtList); i++) buyMtList[i].tick();
  } else if(RUN_MODE == SellOnlyMode) {
    for(int i=0; i<ArraySize(sellMtList); i++) sellMtList[i].tick();
  }
}

bool initMtList() {
  string configNames[];
  int size = StringSplit(EnumToString(STRATEGY_EUNM_INPUT), StringGetCharacter("_", 0), configNames);
  ArrayResize(buyMtList, size);
  ArrayResize(sellMtList, size);
  int matchCount = 0;
  for(int i=0; i<ArraySize(configNames); i++) {
    string configName = configNames[i];
    for(int j=0; j<ArraySize(configs); j++) {
      if(configs[j].name == configName) {
        Config config = configs[j];
        string symbol = config.symbol;
        printf("configName=%s, symbol=%s, stopLevel=%g, minLot=%g, sleep=%d", configName, symbol, Trade::stopLevel(symbol), Trade::minLot(symbol), isSleep(config));
        buyMtList[i].init(multiple(), config, AUTO_SL);
        sellMtList[i].init(multiple(), config, AUTO_SL);
        matchCount++;
      }
    }
  }
  return matchCount == size;
}

bool balanceEnough() {
  if(AccountBalance() < MIN_BALANCE) {
    Print(AccountBalance());
    PrintFormat("balance not enough, balance: %g ,expect: %i", AccountBalance(), MIN_BALANCE);
    return false;
  }
  if(multiple() == 0) {
    PrintFormat("balance not enough, balance: %g ,expect: %i", AccountBalance(), MIN_BALANCE);
    return false;
  }
  return true;
}
uint multiple() {
  if(AUTO_MULTIPLE) {
    double balance = AccountBalance();
    uint multiple = uint(MathFloor(balance/UNIT_BALANCE));
    if(multiple == 0 && balance > MIN_BALANCE) {
      return 1;
    }
    return multiple;
  }
  return MULTIPLE;
}
bool isSleep(Config &config) {
  if(RUN_MODE == SleepMode) return true;
  datetime currentTime = TimeCurrent();
  datetime clock0 = Tools::GMT3("00:00:00"); // 5:00
  datetime clock24 = Tools::GMT3("23:59:59")+1; // 5:00
  datetime begin = Tools::GMT3(config.begin);
  datetime end = Tools::GMT3(config.end);
  datetime laterBegin = Tools::GMT3(config.MonBegin);
  datetime earlierEnd = Tools::GMT3(config.FriEnd);

  int week = TimeDayOfWeek(currentTime);
  if(week == 1) {
    // begin later
    return (clock0 < currentTime && currentTime < laterBegin) || (end < currentTime && currentTime < clock24);
  }
  if(week > 1 && week < 5) {
    // normal
    return (clock0 < currentTime && currentTime < begin) || (end < currentTime && currentTime < clock24);
  } 
  if(week == 5) {
    // close earlier
    return (clock0 < currentTime && currentTime < begin) || (earlierEnd < currentTime && currentTime < clock24);
  }
  // sleep
  return true;
}

datetime lastMailTime;
void sendMail(string title, string content) {
  int minSecondInterval = 3600;
  if(!Math::gt(TimeCurrent()-lastMailTime, minSecondInterval)) {
    PrintFormat("mail send too frequently, please resend %s seconds after", TimeCurrent()-lastMailTime);
  }
  bool sended = SendMail(title, content);
  Print("mail sended, success: ", sended);
  if(sended) lastMailTime = TimeCurrent();
}
