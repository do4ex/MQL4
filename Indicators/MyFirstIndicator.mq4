//+------------------------------------------------------------------+
//|                                             MyFirstIndicator.mq4 |
//|                                                         jiumozhi |
//|                                               1025037674@163.com |
//+------------------------------------------------------------------+
#property copyright "jiumozhi"
#property link      "1025037674@163.com"
#property version   "1.00"
#property strict
#property indicator_separate_window
#property indicator_buffers 1
#property indicator_color1 DarkOrchid

#property indicator_level1 800.0
#property indicator_level2 200.0
#property indicator_levelcolor LimeGreen
#property indicator_levelwidth 2
#property indicator_levelstyle STYLE_SOLID
//--- input parameters
input int      barToProcess=100;
double ExtMapBuffer1[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping

	SetIndexStyle(0,DRAW_LINE);
	SetIndexBuffer(0,ExtMapBuffer1);

	MathSrand(TimeLocal());
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
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
//---

	int counted_bars= IndicatorCounted();

	if(counted_bars > 0){
		counted_bars --;
	}

	int limit = Bars - counted_bars;



    	for(int i=0; i< limit; i++){

    		ExtMapBuffer1[i] = MathRand() % 1001;
    	}


//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+

