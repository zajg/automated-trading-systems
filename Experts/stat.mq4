//+------------------------------------------------------------------+
//|                                                         stat.mq4 |
//|                                                   Grzegorz Zajac |
//|                                      http://www.grzesiekzajac.pl |
//+------------------------------------------------------------------+
#property copyright "Grzegorz Zajac"
#property link      "http://www.grzesiekzajac.pl"
#property version   "6.10"

#define MAGIC 11111

input int      stopLoss                =  40;
input double   takeProfitMultiplicator =  3;
input int      maMovingPeriod          =  12;
input int      maMovingShift           =  6;
input int      rsiMovingPeriod         =  12;
input int      rsiUpperThresh          =  70;
input int      rsiLowerThresh          =  30;
input int      rsiRange                =  7;
input double   sarStep                 =  0.02;
input double   sarMax                  =  0.2;
input double   Lots                    =  0.1;
input string   FileName                =  "history.csv";

//+------------------------------------------------------------------+
//| Check Moving Average Signal                                     |
//+------------------------------------------------------------------+
int CheckMA(){
//--- get Moving Average 
   double ma=iMA(NULL,0, maMovingPeriod,maMovingShift,MODE_SMA,PRICE_CLOSE,0);
   double ma_long=iMA(NULL,0, maMovingPeriod,maMovingShift,MODE_SMA,PRICE_CLOSE,0);
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
//-- find max and min RSI in given period
double max_rsi = 0;
double min_rsi = 100;
for ( int i = 0; i < rsiRange; i++ )
{
   double tmp = iRSI( NULL, 0, rsiMovingPeriod, PRICE_CLOSE, i);
   if ( tmp > max_rsi ) { max_rsi = tmp; }
   if ( tmp < min_rsi ) { min_rsi = tmp; }
}
//--- buy condition
   if(min_rsi < rsiLowerThresh)
      return 1;
//--- sell condition
   if(max_rsi > rsiUpperThresh)
      return -1;
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
      res = OrderSend(Symbol(),OP_SELL,Lots,Bid,3,Bid+stopLoss*Point, Bid-stopLoss*takeProfitMultiplicator*Point,"komentarz",MAGIC,0,Red);
      return;
   }
//--- buy conditions
   if(condition1 == 1 && condition2 == 1 && condition3 == 1){
      res = OrderSend(Symbol(),OP_BUY,Lots,Ask,3,Ask-stopLoss*Point,Ask+stopLoss*takeProfitMultiplicator*Point,"komentarz",MAGIC,0,Blue);
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
