#property copyright "zouhaibo"
#property link      "https://www.mql5.com"

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+

struct Order {
  int ticket;
  int orderType;
  double openPrice;
  double tp;
  double profit;
  double sl;
  datetime openTime;
  double lots;
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

class OrderService{
	public:
		// 选中最后的订单
       static bool selectLastOrder(string newSymbol,int magicNumber) {
        		// 选择最后一个订单
            for(int temp = OrdersTotal()-1; temp >= 0; temp--){
                if(OrderSelect(temp,SELECT_BY_POS)){
                    if(OrderSymbol() == newSymbol && OrderMagicNumber() == magicNumber){
                        // 选中最后下单的该交易对
                        return true;
                    }
                }
            }
            return false;
        }
		// 选中最开始的订单
       static bool selectFirstOrder(string newSymbol,int magicNumber) {
        		// 选择最后一个订单
            for(int temp = 0; temp < OrdersTotal(); temp++){
                if(OrderSelect(temp,SELECT_BY_POS)){
                    if(OrderSymbol() == newSymbol && OrderMagicNumber() == magicNumber){
                        // 选中开始下单的该交易对
                        return true;
                    }
                }
            }
            return false;
        }

        // 获取订单总数
       static int getOrderTotal(string newSymbol,int magicNumber) {

        	int total = 0;

        	for(int temp = OrdersTotal()-1; temp >= 0; temp--){
                if(OrderSelect(temp,SELECT_BY_POS)){
                    if(OrderSymbol() == newSymbol && OrderMagicNumber() == magicNumber){
                        // 选中最后下单的该交易对
                        total ++;
                    }
                }
        	}
        	return total;
        }
        // 关闭所有的订单
        static bool closeAllAndReturnProfit(string symbol,int magicNumber) {
           double profit = 0;

           for(int i = OrdersTotal()-1; i >=0; i--){
                if(OrderSelect(i,SELECT_BY_POS)){

                    if(symbol == OrderSymbol() && OrderMagicNumber() == magicNumber){
                        profit += OrderProfit();
                        bool res ;
                        if(OrderType() == OP_BUY){
                             res =OrderClose(OrderTicket(), OrderLots(),Trade:: bid(symbol), 0,clrYellow);//平仓
                        }else{
                             res =OrderClose(OrderTicket(), OrderLots(),Trade:: ask(symbol), 0,clrYellow);//平仓
                        }
                        if(!res){
                           printf("close order error orderticket: %i  Error: %i",OrderTicket(),GetLastError());
                        }
                    }
               }else{
                   printf("not select order index : %i    GetLastError: %i", i,GetLastError());
               }
           }
           return profit > 0;
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
		static int buyMarket(string symbol, double lots, int magicNumber,string COMMENT) {
			if(Math::eq(lots, 0)) return 0;
			int ticket=OrderSend(symbol,OP_BUY,lots,Trade::ask(symbol),0,0,0,COMMENT,magicNumber,0,clrBlue);
			if(ticket<0) {
				printf("#%i %s buyMarket error=%i, lots=%g", ticket, symbol, GetLastError(), lots);
			}
			return ticket;
		}
		static int sellMarket(string symbol, double lots, int magicNumber,string COMMENT) {
			if(Math::eq(lots, 0)) return 0;
			int ticket=OrderSend(symbol,OP_SELL,lots,Trade::bid(symbol),0,0,0,COMMENT,magicNumber,0,clrRed);
			if(ticket<0) {
				printf("#%i %s sellMarket error=%i, lots=%g", ticket, symbol, GetLastError(), lots);
			}
			return ticket;
		}
		static int buyStop(string symbol,double price, double lots, int magicNumber,string COMMENT) {
			if(Math::eq(lots, 0)) return 0;
			int ticket=OrderSend(symbol,OP_BUYSTOP,lots,price,0,0,0,COMMENT,magicNumber,0,clrCoral);
			if(ticket<0) {
				printf("#%i %s buyStop error=%i, lots=%g", ticket, symbol, GetLastError(), lots);
			}
			return ticket;
		}
		static int buyLimit(string symbol,double price, double lots, int magicNumber,string COMMENT) {
			if(Math::eq(lots, 0)) return 0;
			int ticket=OrderSend(symbol,OP_BUYLIMIT,lots,price,0,0,0,COMMENT,magicNumber,0,clrCoral);
			if(ticket<0) {
				printf("#%i %s buyLimit error=%i, lots=%g", ticket, symbol, GetLastError(), lots);
			}
			return ticket;
		}
		static int sellStop(string symbol,double price, double lots, int magicNumber,string COMMENT) {
			if(Math::eq(lots, 0)) return 0;
			int ticket=OrderSend(symbol,OP_SELLSTOP,lots, price ,0,0,0,COMMENT,magicNumber,0,clrRed);
			if(ticket<0) {
				printf("#%i %s sellStop error=%i, lots=%g", ticket, symbol, GetLastError(), lots);
			}
			return ticket;
		}
		static int sellLimit(string symbol,double price, double lots, int magicNumber,string COMMENT) {
			if(Math::eq(lots, 0)) return 0;
			int ticket=OrderSend(symbol,OP_SELLLIMIT,lots, price ,0,0,0,COMMENT,magicNumber,0,clrRed);
			if(ticket<0) {
				printf("#%i %s sellLimit error=%i, lots=%g", ticket, symbol, GetLastError(), lots);
			}
			return ticket;
		}

		static void modify(int ticket, double tp,double sl) {
			bool res=OrderModify(ticket,0,sl,tp,0,clrOrange);
			if(!res) printf("#%i modify error=%i, tp=%g , sl= %g", ticket, GetLastError(), tp, sl);
		}

		static void modifyStop(int ticket, double price,double tp,double stopLoss) {
			bool res=OrderModify(ticket,price,stopLoss,tp,0,clrOrange);
			if(!res) printf("#%i modify error=%i, tp=%g , stopLoss= %g", ticket, GetLastError(), tp, stopLoss);
		}
		static void close(int ticket, double lots) {
			if(Math::eq(lots, 0)) return;
			bool res=OrderClose(ticket,lots,0,0,clrYellow);
			if(!res) printf("#%i close error=%i lots=%g", ticket, GetLastError(), lots);
		}

		 static void loadOrders(Order &orders[], string symbol, int orderType, int magicNumber) {
	          ArrayFree(orders);
	          for(int i=0; i<OrdersTotal(); i++) {
	            if(!OrderSelect(i,SELECT_BY_POS)) break;
	            if(OrderSymbol() != symbol) continue;
	            if(OrderMagicNumber() != magicNumber) continue;
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
          order.orderType = OrderType();
          order.profit = OrderProfit();
          order.sl = OrderStopLoss();
          return order;
        }

};


// abr 指标
class MarketUtil{

	double getAtrVal(string symbol,int period, int range, int bar = 1) {

    	double value = iATR(symbol,period,range,bar);
        value = NormalizeDouble(value,5);
        return value;
    }

};
