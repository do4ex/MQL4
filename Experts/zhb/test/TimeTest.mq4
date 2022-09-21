//	int  TimeMinute(
//       datetime      date            // date and time
//       );


//datetime  StringToTime(
//   string  value      // date string
//   );

void minuteTest() {


	OrderSelect(0,SELECT_BY_POS,MODE_HISTORY);

	Print("OrderTicket: "+ OrderTicket());

	int bar = iBarShift("EURUSD.s",PERIOD_D1,OrderOpenTime());
	Print("bar: "+ bar);


	Print("MarketInfo-high： "+ MarketInfo(MODE_HIGH));

	double highPrice = iHigh("EURUSD.s",-bar);

	Print("highPrice: "+ highPrice);

}