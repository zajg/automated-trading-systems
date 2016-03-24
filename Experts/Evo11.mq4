//---------------------------------------------------
// Author: Anakonda1231
// Copyright: Przemys?aw Tustanowski
//---------------------------------------------------
extern int SecureFactor = 190;
extern int BE_Range = 50;
extern int corner=0,
           x_dist=170,
           y_dist=300;
double up[],
       down[];
extern int Zeroes = 2;
extern int Distance = 2;

extern int Xfactor = 170;
extern int Yfactor = 0;
extern int TakeProfit       = 390;
extern int StopLoss        = 8000;
extern double  Risk_percent   = 5;
extern double minLots           = 0.01;
extern double maxLots           = 300;
extern bool Differ = true ; 
extern int DamageFactor = 1200;
extern int scopeStop = 70;
 int       magic = 12311, MagicAnakonda = 1231 ;
int     POS_n_BUY, POS_n_SELL, POS_n_BUYSTOP, POS_n_SELLSTOP, POS_n_total;
double   Lots, NewLots;
double OrderLevelB, OrderLevelS, OrderLevelD, OrderLevelE;
  
int start()
  {
double rsi0,rsi1,rsi2,bbu0,bbu1,bbl0,bbl1;
  color rsicol=Gray,
        bbcol=Gray;
  for(int i=Bars;i>=0;i--){
    rsi0=iRSI(Symbol(),0,7,5,i);
    rsi1=iRSI(Symbol(),0,7,5,i+1);
    rsi2=iRSI(Symbol(),0,7,5,i+2);
    bbu0=iBands(Symbol(),0,20,2,1,0,1,i);
    bbu1=iBands(Symbol(),0,20,2,1,0,1,i+1);
    bbl0=iBands(Symbol(),0,20,2,1,0,2,i);
    bbl1=iBands(Symbol(),0,20,2,1,0,2,i+1);
    if((Low[i+1]<bbl1||Low[i]<bbl0)&&(rsi1<20||rsi2<20)&&rsi0>rsi1){
      up[i]=Low[i]-5*Point;
    }
    if((High[i+1]>bbu1||High[i]>bbu0)&&(rsi1>80||rsi2>80)&&rsi0<rsi1){
      down[i]=High[i]+5*Point;
    }
    if(i==0){
      if(rsi0<20||rsi1<20||rsi2<20||rsi0>80||rsi1>80||rsi2>80) rsicol=Orange;
      if((rsi1<20||rsi2<20)&&rsi0>rsi1) rsicol=Green;
      if((rsi1>80||rsi2>80)&&rsi0<rsi1) rsicol=Red;
      if(High[i]>bbu0||High[i+1]>bbu1) bbcol=Red;
      if(Low[i]<bbl0||Low[i+1]<bbl1) bbcol=Green;
      ObjectCreate("rsi", OBJ_LABEL, 0, 0, 0);
      ObjectSetText("rsi","ANAK",32, "Mistral", rsicol);
      ObjectSet("rsi", OBJPROP_CORNER, 0);
      ObjectSet("rsi", OBJPROP_XDISTANCE, x_dist);
      ObjectSet("rsi", OBJPROP_YDISTANCE, y_dist);
      ObjectCreate("bb", OBJ_LABEL, 0, 0, 0);
      ObjectSetText("bb","ONDA",32, "Mistral", bbcol);
      ObjectSet("bb", OBJPROP_CORNER, 0);
      ObjectSet("bb", OBJPROP_XDISTANCE, x_dist+80);
      ObjectSet("bb", OBJPROP_YDISTANCE, y_dist);
      
      color c1 = Teal;
      color c2 = ForestGreen;
      color c3 = Maroon;
      color c11= Indigo;
      
         for(int c =0; c<=OrdersTotal();c++)      { 
      if(c>=1){c1=Aqua;}
      if(c>=2){c2=Lime;}
      if(c>=3){c3=Violet;}
      if(c>=4){c11=Gold;}
         } 
       ObjectCreate("1", OBJ_LABEL, 0, 0, 0);
       ObjectSetText("1","E",32, "Mistral",c1 );
      ObjectSet("1", OBJPROP_CORNER, 0);
      ObjectSet("1", OBJPROP_XDISTANCE, x_dist+170);
      ObjectSet("1", OBJPROP_YDISTANCE, y_dist);
             ObjectCreate("2", OBJ_LABEL, 0, 0, 0);
        ObjectSetText("2","V",32, "Mistral",c2);
      ObjectSet("2", OBJPROP_CORNER, 0);
      ObjectSet("2", OBJPROP_XDISTANCE, x_dist+190);
      ObjectSet("2", OBJPROP_YDISTANCE, y_dist);
      
       ObjectCreate("3", OBJ_LABEL, 0, 0, 0);
        ObjectSetText("3","O",32, "Mistral", c3);
      ObjectSet("3", OBJPROP_CORNER, 0);
      ObjectSet("3", OBJPROP_XDISTANCE, x_dist+210);
      ObjectSet("3", OBJPROP_YDISTANCE, y_dist);
      
       ObjectCreate("11", OBJ_LABEL, 0, 0, 0);
      ObjectSetText("11","11",32, "Mistral",c11 );
      ObjectSet("11", OBJPROP_CORNER, 0);
      ObjectSet("11", OBJPROP_XDISTANCE, x_dist+230);
      ObjectSet("11", OBJPROP_YDISTANCE, y_dist);    
    }
  }


double LevelB = Ask;
double LevelS = Ask;
 double LevelD = MathCeil(Bid / (Point* MathPow(10,Zeroes))) * Point* MathPow(10,Zeroes);
   if(LevelD - Distance*Point <= Ask) {LevelD = LevelD + MathPow(10,Zeroes)*Point;}

   
   double LevelE = LevelD - MathPow(10,Zeroes)*Point;
   if(LevelE + Distance*Point >= Bid) {LevelE = LevelE - MathPow(10,Zeroes)*Point; }
   
    count_position();  
    Call_MM();
   if( POS_n_BUYSTOP == 0 && rsicol==Green && bbcol==Green && POS_n_BUY==0) 
     { OrderSend(Symbol(),OP_BUYSTOP,Lots,Ask+scopeStop*Point,10,Ask-StopLoss*Point,Bid+TakeProfit*Point,"Anakonda",magic,0,Green); }
  int buy = 0;
   if( POS_n_BUYSTOP  == 0 &&  POS_n_BUY!=0) 
    { for(int y = 0 ; y <= OrdersTotal() ; y++)
      {OrderSelect(y, SELECT_BY_POS, MODE_TRADES);
      if(OrderType()==OP_BUY && OrderOpenPrice()<Bid){buy++;}
     if(Differ==true){ if(OrderType()==OP_BUY && OrderOpenPrice()-Bid>DamageFactor*Point){buy++;}}
          }
          if(buy==OrdersTotal())
     {OrderSend(Symbol(),OP_BUYSTOP,Lots,LevelD-Distance*Point,10,Ask-StopLoss*Point,Bid+TakeProfit*Point,"Anakonda",MagicAnakonda,0,Green);}}
   if(POS_n_SELLSTOP ==0 && rsicol==Red && bbcol==Red && POS_n_SELL==0 ) 
   { OrderSend(Symbol(),OP_SELLSTOP,Lots,Bid-scopeStop*Point,10,Bid+StopLoss*Point,Ask-TakeProfit*Point,"Anakonda",magic,0,Red); }
int sell=0;
  if(POS_n_SELLSTOP == 0 &&  POS_n_SELL!=0)
 { for(int z = 0 ; z <= OrdersTotal() ; z++)
    {   OrderSelect(z, SELECT_BY_POS, MODE_TRADES);     
   if(OrderType()==OP_SELL && OrderOpenPrice()>Bid){sell++;} 
   if(Differ==true){if(OrderType()==OP_SELL && Bid-OrderOpenPrice()>DamageFactor*Point){sell++;}} 
   
      }
      if(sell==OrdersTotal())
   { OrderSend(Symbol(),OP_SELLSTOP,Lots,LevelE+Distance*Point,10,Bid+StopLoss*Point,Ask-TakeProfit*Point,"Anakonda",MagicAnakonda,0,Red);}
   } 
      
  for(int q = 0 ; q <= OrdersTotal() ; q++)
  {
       OrderSelect(q, SELECT_BY_POS, MODE_TRADES);
       
      // delete the useless positions && move sl
      
        if(OrderType()==OP_BUYSTOP &&  POS_n_SELL >= Yfactor && OrderSymbol() == Symbol()&& (OrderMagicNumber()==magic || OrderMagicNumber()==MagicAnakonda))
         {if(OrderOpenPrice()-Xfactor*Point >Bid){ OrderDelete(OrderTicket());}
         if(rsicol==Red && bbcol==Red){OrderDelete(OrderTicket());}}
       if(OrderType()==OP_SELLSTOP && POS_n_BUY >= Yfactor && OrderSymbol() == Symbol()&& (OrderMagicNumber()==magic || OrderMagicNumber()==MagicAnakonda ))
         {if(OrderOpenPrice()+Xfactor*Point < Bid){ OrderDelete(OrderTicket());}
         if(rsicol==Green && bbcol==Green){OrderDelete(OrderTicket());}}
}
  for(int x = 0 ; x <= OrdersTotal() ; x++)
  {
       OrderSelect(x, SELECT_BY_POS, MODE_TRADES);
      if(OrderType()==OP_BUY && OrderSymbol() == Symbol() && (Bid-OrderOpenPrice()>= SecureFactor*Point && Bid-(30*Point)-OrderOpenPrice()<= SecureFactor*Point ))
      {OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice()+BE_Range*Point,OrderTakeProfit(),0,Green);}
 
      if(OrderType()==OP_SELL && OrderSymbol() == Symbol() && (OrderOpenPrice()-Bid<= SecureFactor*Point && OrderOpenPrice()+(30*Point)-Bid<= SecureFactor*Point))
      {OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice()-BE_Range*Point,OrderTakeProfit(),0,Red);}    
      } 
   return(0);
}
void Call_MM()
{
Lots=AccountFreeMargin()/100000*Risk_percent; 
Lots=MathMin(maxLots,MathMax(minLots,Lots));
   if(minLots<0.1) 
     Lots=NormalizeDouble(Lots,2);
   else
     {
     if(minLots<1) Lots=NormalizeDouble(Lots,1);
     else          Lots=NormalizeDouble(Lots,0);
     }
   }
void count_position()
{
    POS_n_BUY  = 0;
    POS_n_SELL = 0;
    
    POS_n_BUYSTOP = 0;
    POS_n_SELLSTOP = 0;
    
    for( int i = 0 ; i <= OrdersTotal() ; i++ ){
     OrderSelect( i,SELECT_BY_POS, MODE_TRADES ) ;
        if( OrderType() == OP_BUY  && OrderSymbol() == Symbol() && OrderMagicNumber()==magic){
            POS_n_BUY++;}
        else if( OrderType() == OP_SELL  && OrderSymbol() == Symbol() && OrderMagicNumber()==magic){
            POS_n_SELL++;}
        else if( OrderType() == OP_BUYSTOP  && OrderSymbol() == Symbol() && OrderMagicNumber()==magic){
            POS_n_BUYSTOP++;}
        else if( OrderType() == OP_SELLSTOP  && OrderSymbol() == Symbol() && OrderMagicNumber()==magic){
            POS_n_SELLSTOP++;}
        
    }
    } 
