#property copyright "zouhaibo"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//| ea 模板                     |
//+------------------------------------------------------------------+

int OnInit() {

	return 0;

}

void OnTick() {

	Print("3 ");
	ExpertRemove();
	Print("4 ");

}


void OnDeinit(const int reason)
{
//--- destroy timer
   EventKillTimer();

   Print("OnDeinit method execute");

}

void OnTimer(){


}


