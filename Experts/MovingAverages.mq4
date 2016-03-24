//+------------------------------------------------------------------+
//|                                               MovingAverages.mq4 |
//|                                                     Anakonda1231 |
//|                                            Przemys?aw Tustanowski|
//+------------------------------------------------------------------+
#property copyright "Anakonda1231"
#property version   "1.00"
extern string LotsMM = "-----Volume of lots Management-----";
extern double  Risk_percent   = 50;
extern double minLots = 0.01;
extern double maxLots = 300;
extern double MA_Short_period = 14;
extern double MA_Short_shift = 1;
extern double MA_Long_period = 30;
extern double MA_Long_shift = 5;

int     POS_n_BUY, POS_n_SELL, POS_n_BUYSTOP, POS_n_SELLSTOP;
double   Lots;

int start()
{
////                             ----core EA---
//MA
double MA_Short = iMA( Symbol(), 0, MA_Short_period, 0, 0, 0, MA_Short_shift );
double MA_Long = iMA( Symbol(), 0, MA_Long_period, 0, 0, 0, MA_Long_shift );
//						----trading evaluation---
count_position();
if(POS_n_BUY == 0 && MA_Short>MA_Long){
count_position();
	if(POS_n_SELL!=0){closAll();}
	openBuy();
}
else if(POS_n_SELL == 0 && MA_Short<MA_Long){
count_position();
	if(POS_n_BUY!=0){closAll();}
	openSell();
}
//return(0);
}

void count_position()
{
    POS_n_BUY  = 0;
    POS_n_SELL = 0;
    
    POS_n_BUYSTOP = 0;
    POS_n_SELLSTOP = 0;
    
    for( int i = 0 ; i <= OrdersTotal() ; i++ ){
     OrderSelect( i,SELECT_BY_POS, MODE_TRADES ) ;
        if( OrderType() == OP_BUY  && OrderSymbol() == Symbol()){
            POS_n_BUY++;}
        else if( OrderType() == OP_SELL  && OrderSymbol() == Symbol() ){
            POS_n_SELL++;}
        else if( OrderType() == OP_BUYSTOP  && OrderSymbol() == Symbol() ){
            POS_n_BUYSTOP++;}
        else if( OrderType() == OP_SELLSTOP  && OrderSymbol() == Symbol() ){
            POS_n_SELLSTOP++;}      
    }
}

void Call_MM(){
    Lots=AccountFreeMargin()/100000*Risk_percent; 
    Lots=MathMin(maxLots,MathMax(minLots,Lots));
    if(minLots<0.1)
    	Lots=NormalizeDouble(Lots,2);	
    else{
    	if(minLots<1) Lots=NormalizeDouble(Lots,1);
    	else          Lots=NormalizeDouble(Lots,0);
    }      
}

void closAll(){
	for( int i = 0 ; i <= OrdersTotal() ; i++ ){
	     OrderSelect(i,SELECT_BY_POS, MODE_TRADES);
      	if( OrderType() == OP_BUY && OrderSymbol() == Symbol()){
        	OrderClose( OrderTicket(), OrderLots(), Bid, 20, Black );	        
      	}
      	else if( OrderType() == OP_SELL && OrderSymbol() == Symbol()){
        	OrderClose( OrderTicket(), OrderLots(), Ask, 20, Black );       
      	}
}
}

void openBuy(){
   Call_MM();
	Print( Lots );
	OrderSend( Symbol(), OP_BUY, Lots, Ask, 20, 0, 0, NULL, 0, 0, Green);
}

void openSell(){
   Call_MM();
	Print( Lots );
	OrderSend( Symbol(), OP_SELL, Lots, Bid, 20, 0, 0, NULL, 0, 0, Red);
}
