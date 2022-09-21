

void OrderSendTest1() {


	string symbol = "EURUSD.s";

	string COMMENT = "OrderSendTest1";

	double price = 1.0188;

	int magicNumber = 1231234;

	double lots = 0.01;

	Print("OrderSendTest1");

	OrderSend(symbol,OP_SELLLIMIT,lots,price,0,0,0,COMMENT,magicNumber,0,clrRed);

}


void OrderSelectTest() {


	string newSymbol = "EURUSD.s";

	for(int temp = 0; temp < OrdersTotal(); temp++){
        if(OrderSelect(temp,SELECT_BY_POS)){
            if(OrderSymbol() == newSymbol ){
                // 选中最后下单的该交易对

                PrintFormat("current order ticket : %i , orderType: %i ,orderProfit: %g,", OrderTicket(),OrderType(),OrderProfit());

            }
        }
    }


}