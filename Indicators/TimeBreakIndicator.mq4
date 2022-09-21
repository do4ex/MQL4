//+------------------------------------------------------------------+
//|                                                          MA5.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

// #property indicator_separate_window
#property indicator_chart_window

#property  indicator_buffers 4
input int entrancePeriod = 20;
input int exitPeriod = 10;
double highEntranceBuffer[];
double lowExitBuffer[];
double lowEntranceBuffer[];
double highExitBuffer[];

int OnInit()
{
   IndicatorDigits(Digits);
   IndicatorShortName("TimeBreak("+string(entrancePeriod)+","+string(exitPeriod)+")");
   
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,1,RoyalBlue);
   SetIndexBuffer(0,highEntranceBuffer);
   SetIndexLabel(0,"HighEntrance("+string(entrancePeriod)+")");
   
   SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,1,Red);
   SetIndexBuffer(1,lowExitBuffer);
   SetIndexLabel(1,"LowExit("+string(exitPeriod)+")");
   
   SetIndexStyle(2,DRAW_LINE,STYLE_SOLID,1,RoyalBlue);
   SetIndexBuffer(2,lowEntranceBuffer);
   SetIndexLabel(2,"LowEntrance("+string(entrancePeriod)+")");
   
   SetIndexStyle(3,DRAW_LINE,STYLE_SOLID,1,Red);
   SetIndexBuffer(3,highExitBuffer);
   SetIndexLabel(3,"HighExit("+string(exitPeriod)+")");
   
   return(INIT_SUCCEEDED);
}

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]) 
{
   if(rates_total==prev_calculated) return(rates_total); // skip
   ArraySetAsSeries(highEntranceBuffer,false);
   ArraySetAsSeries(lowExitBuffer,false);
   ArraySetAsSeries(lowEntranceBuffer,false);
   ArraySetAsSeries(highExitBuffer,false);

   int minPeriod=entrancePeriod<exitPeriod ? entrancePeriod : exitPeriod;
   int i=prev_calculated==0 ? minPeriod-1 : prev_calculated-1;
   for(;i<rates_total;i++) {
      if(i>=entrancePeriod) {
         int highest=iHighest(NULL,0,MODE_HIGH,entrancePeriod,rates_total-i);
         highEntranceBuffer[i]=iHigh(NULL,0,highest);
         int lowest=iLowest(NULL,0,MODE_LOW,entrancePeriod,rates_total-i);
         lowEntranceBuffer[i]=iLow(NULL,0,lowest);
      }
      if(i>=exitPeriod) {
         int lowest=iLowest(NULL,0,MODE_LOW,exitPeriod,rates_total-i);
         lowExitBuffer[i]=iLow(NULL,0,lowest);
         int highest=iHighest(NULL,0,MODE_HIGH,exitPeriod,rates_total-i);
         highExitBuffer[i]=iHigh(NULL,0,highest);
      }
   }
   return(rates_total);
}
