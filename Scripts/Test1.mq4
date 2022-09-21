//+------------------------------------------------------------------+
//|                                                        Test1.mq4 |
//|                                                         jiumozhi |
//|                                               1025037674@163.com |
//+------------------------------------------------------------------+
#property copyright "jiumozhi"
#property link      "1025037674@163.com"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
//---
   
   testIndicatorCounted();
   
  }
//+------------------------------------------------------------------+


void testIndicatorCounted() {

	int a = IndicatorCounted();
	
	Alert(a);
}