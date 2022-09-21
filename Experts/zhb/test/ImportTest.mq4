#property copyright "zouhaibo"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <CommentService.mqh>
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+


input int magicNumber = 10001;


void OnStart()
{

	bool result = Math::eq(1,2);
	Print(result);


	bool res = OrderService::selectLastOrder("XAUUSD.s",10001);
	Print("selectLastOrder: "+ res);
	Print(" selectLastOrder  OrderTicket: "+OrderTicket());


	bool res2 = OrderService::selectFirstOrder("XAUUSD.s",10001);
	Print("selectFirstOrder: "+ res2);
	Print("selectFirstOrder OrderTicket: "+OrderTicket());
}

