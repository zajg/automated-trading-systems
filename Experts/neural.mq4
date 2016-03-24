//+------------------------------------------------------------------+
//|                                      GZC_algo_WIG20_Balanced.mq4 |
//|                                                   Grzegorz Zajac |
//|                                      http://www.grzesiekzajac.pl |
//+------------------------------------------------------------------+
#property copyright "Grzegorz Zajac"
#property link      "http://www.grzesiekzajac.pl"
#property version   "8.70"
#property strict

#define MAGIC 12345

input int      stopLoss         =  20;
input int      takeProfit       =  60;
input int      rsiMovingPeriod  =  14;
input int      rsiRange         =  14;
input int      rsiUpperThresh   =  80;
input int      rsiLowerThresh   =  20;
input int      nnPeriod         =  7;
input int      input_parameter1 =  7;
input int      input_parameter2 =  7;
input int      input_parameter3 =  7;
input int      input_parameter4 =  7;
input double   Lots             =  0.1;

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
//|  Expert neural network perceptron function                       |
//+------------------------------------------------------------------+
double Perceptron(double x1, double x2, double x3, double x4) 
  {
   int w1 = input_parameter1;
   int w2 = input_parameter2;
   int w3 = input_parameter3;
   int w4 = input_parameter4;
   return (w1 * x1 + w2 * x2 + w3 * x3 + w4 * x4);
  }
//+------------------------------------------------------------------+
//| Check for open order conditions                                  |
//+------------------------------------------------------------------+
void CheckForOpen(){
//-- set neural network imput signals
   double   nn_input1 = iAC(NULL, 0, 0);
   double   nn_input2 = iAC(NULL, 0, nnPeriod);
   double   nn_input3 = iAC(NULL, 0, 2*nnPeriod);
   double   nn_input4 = iAC(NULL, 0, 3*nnPeriod);
//-- get signals from indicators
   double   condition1  =  Perceptron(nn_input1, nn_input2, nn_input3, nn_input4);
   int      condition2  =  CheckRSI();
   int      res;
//--- sell conditions
   if(condition1 > 0 && condition2 == -1){
      res = OrderSend(Symbol(),OP_SELL,Lots,Bid,3,Bid+stopLoss*Point, Bid-stopLoss*5*Point,"komentarz",MAGIC,0,Red);
      //res = OrderSend(Symbol(),OP_SELL,Lots,Bid,3,0, 0,"komentarz",MAGIC,0,Red);
      return;
   }
//--- buy conditions
   if(condition1 < 0 && condition2 == 1){
      res = OrderSend(Symbol(),OP_BUY,Lots,Ask,3,Ask-stopLoss*Point,Ask+stopLoss*5*Point,"komentarz",MAGIC,0,Blue);
      //res = OrderSend(Symbol(),OP_BUY,Lots,Ask,3,0,0,"komentarz",MAGIC,0,Blue);
      return;
   }
//---
}
//+------------------------------------------------------------------+
//| Check for close order conditions                                 |
//+------------------------------------------------------------------+
void CheckForClose(){
//-- set neural network imput signals
   double   nn_input1 = iAC(NULL, 0, 0);
   double   nn_input2 = iAC(NULL, 0, nnPeriod);
   double   nn_input3 = iAC(NULL, 0, 2*nnPeriod);
   double   nn_input4 = iAC(NULL, 0, 3*nnPeriod);
//-- get signals from indicators
   double   condition1  =  Perceptron(nn_input1, nn_input2, nn_input3, nn_input4);
   int      condition2  =  CheckRSI();
//---
   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) continue;
      if(OrderMagicNumber()!=MAGIC || OrderSymbol()!=Symbol()) continue;
      //--- check order type 
      if(OrderType()==OP_BUY)
        {
         if(condition1 > 0 && condition2 == -1)
           {
            if(!OrderClose(OrderTicket(),OrderLots(),Bid,3,White))
               Print("OrderClose error ",GetLastError());
           }
         continue;
        }
      if(OrderType()==OP_SELL)
        {
         if(condition1 < 0 && condition2 == 1)
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
//---
   
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