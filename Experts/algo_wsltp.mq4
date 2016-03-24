//+------------------------------------------------------------------+
//|                                      GZC_algo_WIG20_Balanced.mq4 |
//|                                                   Grzegorz Zajac |
//|                                      http://www.grzesiekzajac.pl |
//+------------------------------------------------------------------+
#property copyright "Grzegorz Zajac"
#property link      "http://www.grzesiekzajac.pl"
#property version   "4.70"
#property strict

#define MAGIC 12345

input int      stopLoss         =  20;
input int      takeProfit       =  60;
input int      maMovingPeriod   =  12;
input int      maMovingShift    =  6;
input int      rsiMovingPeriod  =  14;
input int      rsiUpperThresh   =  80;
input int      rsiLowerThresh   =  20;
input int      wprUpperThresh   =  80;
input int      wprLowerThresh   =  20;
input double   Lots   =  0.1;
input string   FileName="myfilename2.csv";
//+------------------------------------------------------------------+
//| Check Moving Averages Signal                                     |
//+------------------------------------------------------------------+
int CheckMA(){
//--- get Moving Average 
   double ma=iMA(NULL,0, maMovingPeriod,maMovingShift,MODE_SMA,PRICE_CLOSE,0);
//--- sell condition
   if(Open[1]>ma && Close[1]<ma)
      return -1;
//--- buy condition
   if(Open[1]<ma && Close[1]>ma)
      return 1;
   return 0;
  }
//+------------------------------------------------------------------+
//| Check Relative Strength Index Signal                             |
//+------------------------------------------------------------------+
int CheckRSI(){
//--- get Relative Strength Index
   double rsi=iRSI( NULL, 0, rsiMovingPeriod, PRICE_CLOSE, 0);
//--- sell condition
   if(rsi < rsiLowerThresh)
      return -1;
//--- buy condition
   if(rsi > rsiUpperThresh)
      return 1;
   return 0;
//---
  }
//+------------------------------------------------------------------+
//| Check SAR Signal                                                 |
//+------------------------------------------------------------------+
int CheckSAR(){
//--- get SAR
   double sar=iSAR(NULL,0,0.02,0.2,1);
//--- sell condition
   if(sar > Close[1])
      return -1;
//--- buy condition
   return 1;
//---
  }
  /*
//+------------------------------------------------------------------+
//| Check ARTR                                              |
//+------------------------------------------------------------------+
int CheckATR(){
//--- get Relative Strength Index
   double atr=iATR(NULL,0,12,0);
   double max_atr = 0;
   double tmp = 0;

//--to find max rsi between current bar and NUMBER_OF_BARS bar

   for ( int i = 0; i < atrRange; i ++ )
   {
      atr = iRSI( Symbol(), Period(), perRSI, PRICE_CLOSE, i );
      if ( tmp > max_atr ) { max_atr = tmp; }
   }
//--- sell condition
   if(atr < rsiLowerThresh)
      return -1;
//--- buy condition
   if(atr > rsiUpperThresh)
      return 1;
   return 0;
//---
  }
  */
//+------------------------------------------------------------------+
//| Check for open order conditions                                  |
//+------------------------------------------------------------------+
void CheckForOpen(){
   int   condition1  =  CheckMA();
   int   condition2  =  CheckRSI();
   int   condition3  =  CheckSAR();
   int   res;
//--- sell conditions
   if(condition1 == -1 && condition2 == -1 && condition3 == -1){
      res = OrderSend(Symbol(),OP_SELL,Lots,Bid,3,Bid+stopLoss*Point, Bid-takeProfit*Point,"komentarz",MAGIC,0,Red);
      return;
   }
//--- buy conditions
   if(condition1 == 1 && condition2 == 1 && condition3 == 1){
      res = OrderSend(Symbol(),OP_BUY,Lots,Ask,3,Ask-stopLoss*Point,Ask+takeProfit*Point,"komentarz",MAGIC,0,Blue);
      return;
   }
//---
}
//+------------------------------------------------------------------+
//| Check for close order conditions                                 |
//+------------------------------------------------------------------+
void CheckForClose(){
   int   condition1  =  CheckMA();
   int   condition2  =  CheckRSI();
   int   condition3  =  CheckSAR();
//---
   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) continue;
      if(OrderMagicNumber()!=MAGIC || OrderSymbol()!=Symbol()) continue;
      //--- check order type 
      if(OrderType()==OP_BUY)
        {
         if(condition1 == -1 && condition2 == -1 && condition3 == -1)
           {
            if(!OrderClose(OrderTicket(),OrderLots(),Bid,3,White))
               Print("OrderClose error ",GetLastError());
           }
         continue;
        }
      if(OrderType()==OP_SELL)
        {
         if(condition1 == 1 && condition2 == 1 && condition3 == 1)
           {
            if(!OrderClose(OrderTicket(),OrderLots(),Ask,3,White))
               Print("OrderClose error ",GetLastError());
           }
         continue;
        }
     }
//---
  }
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//Create csv file
   int handle=FileOpen(FileName,FILE_CSV|FILE_READ|FILE_WRITE,",");
//Separator info for MS Excel
   FileWrite(handle,"sep=,");
//Name collumns
   FileWrite(handle,"Typ zlecenia","Zysk/Strata","Numer zlecenia","Cena otwarcia","Cena zamkniecia","Data otwarcia","Data zamkniecia","Instrument","Rozmiar");
//Close file
   FileClose(handle);
//Print success message to log file
   Print("CSV file created successfully");  
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick(){
//---
//--- go trading only for first tiks of new bar   
   if(Volume[0]>1) 
      return; 
   if(IsTradeAllowed()==false){
      Print("Trade is not allowed!");
      return;
   }  
   if(Bars<100){
      Print("Not enough bars!");
      return;
   }       
   CheckForOpen();
   CheckForClose();
}
//+------------------------------------------------------------------+
