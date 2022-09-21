class CTrader {
    public:
        const string SYMBOL;
        const int MAGIC_NUMBER;
        const double MINI_LOT;
        int buyCount;
        int sellCount;
        double buyLot;
        double sellLot;
        
        CTrader(int _magicNumber): SYMBOL(Symbol()), MAGIC_NUMBER(_magicNumber), MINI_LOT(miniLot()) {}
        CTrader(string _symbol, int _magicNumber): SYMBOL(_symbol), MAGIC_NUMBER(_magicNumber), MINI_LOT(miniLot()) {}

        double ask() {
            return MarketInfo(SYMBOL, MODE_ASK);
        }
        double bid() {
            return MarketInfo(SYMBOL, MODE_BID);
        }
        double spread() {
            return MarketInfo(SYMBOL, MODE_SPREAD);
        }
        double point() {
            return MarketInfo(SYMBOL, MODE_POINT);
        }
        double digits() {
            return MarketInfo(SYMBOL, MODE_DIGITS);
        }
        double stopLevel() {
            return MarketInfo(SYMBOL, MODE_STOPLEVEL);
        }
        double miniLot() {
            return MarketInfo(SYMBOL, MODE_MINLOT);
        }
        
        int buy(double _orderLots, double _stoploss=0, double _takeprofit=0, string _comment=NULL) {
            if(NormalizeDouble(_orderLots, 2)==0) return 0;
            if(NormalizeDouble(_orderLots, 2)<MINI_LOT) return 0;
            int ticket=OrderSend(SYMBOL,OP_BUY,_orderLots,ask(),3,_stoploss,_takeprofit,_comment,MAGIC_NUMBER,0,Blue);
            if(ticket>0) {
                buyCount++;
                buyLot+=_orderLots;
            }
            else printf("ticket=%i, type=buy, lots=%g, symbol=%s, price=%g, sl=%g, tp=%g, error=%i", ticket, _orderLots, SYMBOL, ask(), _stoploss, _takeprofit, GetLastError());
            return ticket;
        }

        int sell(double _orderLots, double _stoploss=0, double _takeprofit=0, string _comment=NULL) {
            if(NormalizeDouble(_orderLots, 2)==0) return 0;
            if(NormalizeDouble(_orderLots, 2)<MINI_LOT) return 0;
            int ticket=OrderSend(SYMBOL,OP_SELL,_orderLots,bid(),3,_stoploss,_takeprofit,_comment,MAGIC_NUMBER,0,Red);
            if(ticket>0) {
                sellCount++;
                sellLot+=_orderLots;
            }
            else printf("ticket=%i, type=sell, lots=%g, symbol=%s, price=%g, sl=%g, tp=%g, error=%i", ticket, _orderLots, SYMBOL, bid(), _stoploss, _takeprofit, GetLastError());
            return ticket;
        }

        void closeByTicket(int ticket) {
            if(OrderTicket()!=ticket && !OrderSelect(ticket,SELECT_BY_POS,MODE_TRADES)) return;
            if(OrderMagicNumber()!=MAGIC_NUMBER) return;
            bool success;
            if(OrderType()==OP_BUY) {
                success=OrderClose(OrderTicket(),OrderLots(),bid(),0,Yellow);
                if(success) {
                    buyCount--;
                    buyLot-=OrderLots();
                }
                else printf("close buy error: ticket=%i, lots=%g, symbol=%s, price=%g", OrderTicket(), OrderLots(), OrderSymbol(), bid());
            }
            if(OrderType()==OP_SELL) {
                success=OrderClose(OrderTicket(),OrderLots(),ask(),0,Orange);
                if(success) {
                    sellCount--;
                    sellLot-=OrderLots();
                }
                else printf("close sell error: ticket=%i, lots=%g, symbol=%s, price=%g", OrderTicket(), OrderLots(), OrderSymbol(), ask());
            }
        }

        void closeBuyReverse() {
            for(int i=OrdersTotal()-1; i>=0; i--) {
                if(!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) break;
                if(OrderMagicNumber()!=MAGIC_NUMBER) continue;
                if(OrderType()!=OP_BUY) continue;
                bool success=OrderClose(OrderTicket(),OrderLots(),bid(),0,Yellow);
                if(success) {
                    buyCount--;
                    buyLot-=OrderLots();
                }
                else printf("close buy error: ticket=%i, lots=%g, symbol=%s, price=%g", OrderTicket(), OrderLots(), OrderSymbol(), bid());
            }
        }

        void closeSellReverse() {
            for(int i=OrdersTotal()-1; i>=0; i--) {
                if(!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) break;
                if(OrderMagicNumber()!=MAGIC_NUMBER) continue;
                if(OrderType()!=OP_SELL) continue;
                bool success=OrderClose(OrderTicket(),OrderLots(),ask(),0,Orange);
                if(success) {
                    sellCount--;
                    sellLot-=OrderLots();
                }
                else printf("close sell error: ticket=%i, lots=%g, symbol=%s, price=%g", OrderTicket(), OrderLots(), OrderSymbol(), ask());
            }
        }

        void closeBuy() {
            for(int i=0; i<OrdersTotal(); i++) {
                if(!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) break;
                if(OrderMagicNumber()!=MAGIC_NUMBER) continue;
                if(OrderType()!=OP_BUY) continue;
                bool success=OrderClose(OrderTicket(),OrderLots(),bid(),0,Yellow);
                if(success) {
                    i--;
                    buyCount--;
                    buyLot-=OrderLots();
                }
                else printf("close buy error: ticket=%i, lots=%g, symbol=%s, price=%g", OrderTicket(), OrderLots(), OrderSymbol(), bid());
            }
        }

        void closeSell() {
            for(int i=0; i<OrdersTotal(); i++) {
                if(!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) break;
                if(OrderMagicNumber()!=MAGIC_NUMBER) continue;
                if(OrderType()!=OP_SELL) continue;
                bool success=OrderClose(OrderTicket(),OrderLots(),ask(),0,Orange);
                if(success) {
                    i--;
                    sellCount--;
                    sellLot-=OrderLots();
                }
                else printf("close sell error: ticket=%i, lots=%g, symbol=%s, price=%g", OrderTicket(), OrderLots(), OrderSymbol(), ask());
            }
        }

        void closeAllReverse() {
            for(int i=OrdersTotal()-1; i>=0; i--) {
                if(!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) break;
                if(OrderMagicNumber()!=MAGIC_NUMBER) continue;
                bool success;
                if(OrderType()==OP_BUY) {
                    success=OrderClose(OrderTicket(),OrderLots(),bid(),0,Yellow);
                    if(success) {
                        buyCount--;
                        buyLot-=OrderLots();
                    }
                    else printf("close buy error: ticket=%i, lots=%g, symbol=%s, price=%g", OrderTicket(), OrderLots(), OrderSymbol(), bid());
                }
                if(OrderType()==OP_SELL) {
                    success=OrderClose(OrderTicket(),OrderLots(),ask(),0,Orange);
                    if(success) {
                        sellCount--;
                        sellLot-=OrderLots();
                    }
                    else printf("close sell error: ticket=%i, lots=%g, symbol=%s, price=%g", OrderTicket(), OrderLots(), OrderSymbol(), ask());
                }
            }
        }

        void closeAll() {
            for(int i=0; i<OrdersTotal(); i++) {
                if(!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) break;
                if(OrderMagicNumber()!=MAGIC_NUMBER) continue;
                bool success;
                if(OrderType()==OP_BUY) {
                    success=OrderClose(OrderTicket(),OrderLots(),bid(),0,Yellow);
                    if(success) {
                        i--;
                        buyCount--;
                        buyLot-=OrderLots();
                    }
                    else printf("close buy error: ticket=%i, lots=%g, symbol=%s, price=%g", OrderTicket(), OrderLots(), OrderSymbol(), bid());
                }
                if(OrderType()==OP_SELL) {
                    success=OrderClose(OrderTicket(),OrderLots(),ask(),0,Orange);
                    if(success) {
                        i--;
                        sellCount--;
                        sellLot-=OrderLots();
                    }
                    else printf("close sell error: ticket=%i, lots=%g, symbol=%s, price=%g", OrderTicket(), OrderLots(), OrderSymbol(), ask());
                }
            }
        }

        void reloadOrderCount() {
            buyCount=0;
            sellCount=0;
            for(int i=0; i<OrdersTotal(); i++) {
                if(!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) break;
                if(OrderMagicNumber()!=MAGIC_NUMBER) continue;
                if(OrderType()==OP_BUY) {
                    buyCount++;
                    continue;
                }
                if(OrderType()==OP_SELL) {
                    sellCount++;
                    continue;
                }
            }
        }

        bool selectFirstBuyOrder() {
            for(int i=0; i<OrdersTotal(); i++) {
                if(!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) break;
                if(OrderMagicNumber()!=MAGIC_NUMBER) continue;
                if(OrderType()==OP_BUY) return true;
            }
            return false;
        }

        bool selectFirstSellOrder() {
            for(int i=0; i<OrdersTotal(); i++) {
                if(!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) break;
                if(OrderMagicNumber()!=MAGIC_NUMBER) continue;
                if(OrderType()==OP_SELL) return true;
            }
            return false;
        }

        bool selectLastBuyOrder() {
            for(int i=OrdersTotal()-1; i>=0; i--) {
                if(!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) break;
                if(OrderMagicNumber()!=MAGIC_NUMBER) continue;
                if(OrderType()==OP_BUY) return true;
            }
            return false;
        }

        bool selectLastSellOrder() {
            for(int i=OrdersTotal()-1; i>=0; i--) {
                if(!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) break;
                if(OrderMagicNumber()!=MAGIC_NUMBER) continue;
                if(OrderType()==OP_SELL) return true;
            }
            return false;
        }

        // readable

        datetime previousBuyTime() {
            int i;
            for(i=OrdersTotal()-1; i>=0; i--) {
                if(!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) break;
                if(OrderMagicNumber()!=MAGIC_NUMBER) continue;
                if(OrderType()==OP_BUY) return OrderOpenTime();
            }
            for(i=OrdersHistoryTotal()-1; i>=0; i--) {
                if(!OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)) break;
                if(OrderMagicNumber()!=MAGIC_NUMBER) continue;
                if(OrderType()==OP_BUY) return OrderOpenTime();
            }
            return NULL;
        }

        datetime previousSellTime() {
            int i;
            for(i=OrdersTotal()-1; i>=0; i--) {
                if(!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) break;
                if(OrderMagicNumber()!=MAGIC_NUMBER) continue;
                if(OrderType()==OP_SELL) return OrderOpenTime();
            }
            for(i=OrdersHistoryTotal()-1; i>=0; i--) {
                if(!OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)) break;
                if(OrderMagicNumber()!=MAGIC_NUMBER) continue;
                if(OrderType()==OP_SELL) return OrderOpenTime();
            }
            return NULL;
        }

        double buyProfit() {
            double sum=0;
            for(int i=0; i<OrdersTotal(); i++) {
                if(!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) break;
                if(OrderMagicNumber()!=MAGIC_NUMBER) continue;
                if(OrderType()!=OP_BUY) continue;
                sum+=OrderProfit();
            }
            return sum;
        }

        double sellProfit() {
            double sum=0;
            for(int i=0; i<OrdersTotal(); i++) {
                if(!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) break;
                if(OrderMagicNumber()!=MAGIC_NUMBER) continue;
                if(OrderType()!=OP_SELL) continue;
                sum+=OrderProfit();
            }
            return sum;
        }
};