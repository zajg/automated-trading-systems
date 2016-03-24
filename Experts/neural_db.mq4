//+------------------------------------------------------------------+
//|                                                    neural_db.mq4 |
//|                                                   Grzegorz Zajac |
//|                                      http://www.grzesiekzajac.pl |
//+------------------------------------------------------------------+
#property copyright "Grzegorz Zajac"
#property link      "http://www.grzesiekzajac.pl"
#property version   "9.20"
#property strict

#define MAGIC 2
#include <MQLMySQL.mqh>

int handle;
int DB1;
int ile =0;
int added_to = 0;

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
//| Function Sending Orders For Every Client                         |
//+------------------------------------------------------------------+
void SendMultipleOrder(int type){
   int    i,Cursor,Rows, res, vId;
   double  vSize;
   string Query = "SELECT id, neural_size FROM `user`";
   Cursor = MySqlCursorOpen(DB1, Query);
   if (Cursor >= 0){
      Rows = MySqlCursorRows(Cursor);
      for (i=0; i<Rows; i++){
         if (MySqlCursorFetchRow(Cursor)){
            vId = MySqlGetFieldAsInt(Cursor, 0);
            vSize = MySqlGetFieldAsDouble(Cursor, 1);
            if (type == 1)       res = OrderSend(Symbol(), OP_SELL, vSize,Bid,3,Bid+stopLoss*Point, Bid-takeProfit*Point, IntegerToString(vId), MAGIC,0,Red);
            else if (type == 2)  res = OrderSend(Symbol(), OP_BUY, vSize,Ask,3,Ask-stopLoss*Point,Ask+takeProfit*Point,IntegerToString(vId), MAGIC,0,Blue);
         }      
      }
      MySqlCursorClose(Cursor);
    }
   else{
      Print("Nie udalo sie otworzyc kursora: ", MySqlErrorDescription);
   }
}
//+------------------------------------------------------------------+
//| Database Updating Function                                       |
//+------------------------------------------------------------------+
void CheckForUpdate(){
   ile++;
   //Print("Wywolano mnie ", ile, " raz. Jest razem ", OrdersHistoryTotal(), " transakcji.");
   string Query;
   for(int i=added_to;i<OrdersHistoryTotal();i++){
      if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==TRUE){
         if(OrderMagicNumber()!=MAGIC || OrderSymbol()!=Symbol()) continue; 
         Query = "INSERT INTO `transactions` (strategy, user, profit, ticket, type, open_price, close_price, open_time, close_time, symbol, size) VALUES ("+(string)MAGIC+", "+StringSubstr(OrderComment(),0,StringLen(OrderComment())-4)+", "+DoubleToString(OrderProfit() + OrderSwap() + OrderCommission())+", "+(string)OrderTicket()+", "+OrderType()+", "+(string)OrderOpenPrice()+", "+(string)OrderClosePrice()+", \'"+TimeToString(OrderOpenTime())+"\', \'"+TimeToString(OrderCloseTime())+"\', \'"+(string)OrderSymbol()+"\', "+(string)OrderLots()+");";
         Print("[SQL] >>> " + Query);
         if (MySqlExecute(DB1, Query)){        
            Print("Transakcja" + (string)OrderTicket() + "dodana do bazy.");
         }
         else{
            Print("Blad dodawania transakcji: " + (string)OrderTicket() + "do bazy. Blad: " +MySqlErrorDescription);
         }   
      } 
          
   }
   added_to = OrdersHistoryTotal();
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
      SendMultipleOrder(1);
      return;
   }
//--- buy conditions
   if(condition1 < 0 && condition2 == 1){
      SendMultipleOrder(2);
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
   Print("====================================================================================================================");
   string Host = "127.0.0.1", User = "root", Password = "root" , Database="javadb";
   int Port=3306;
   handle=FileOpen("neural_db.txt",FILE_CSV|FILE_READ|FILE_WRITE," "); 
   FileWrite(handle,"Start systemu: ", TimeToString(TimeCurrent()));    
   string INI = "C:\\Users\\lenovo\\AppData\\Roaming\\MetaQuotes\\Terminal\\0FC27529066061916C718B44D2E4BAC3\\MQL4\\Experts\\MyConnection.ini";
   FileWrite(handle,"Plik inicjalizacyjny: ", INI);   
   Host     = ReadIni(INI, "MYSQL", "Host");   
   Port     = StrToInteger(ReadIni(INI, "MYSQL", "Port"));   
   Database = ReadIni(INI, "MYSQL", "Database");
   User     = ReadIni(INI, "MYSQL", "User");
   Password = ReadIni(INI, "MYSQL", "Password");   
   FileWrite (handle, "Host: ",Host, ", User: ", User, ", Database: ",Database);   
   string Query;  
   FileWrite (handle, "Laczenie z baza...");   
   if(!IsOptimization()) DB1 = MySqlConnect(Host, User, Password, Database, Port, "", 0); 
   if (DB1 == -1) {
      Print ("Blad polaczenia z baza danych: "+MySqlErrorDescription); 
   } 
   else { 
      Print ("Polaczono! DB#",DB1);
   }  
   Query = "CREATE TABLE IF NOT EXISTS `transactions` (id int KEY NOT NULL AUTO_INCREMENT, strategy int, user int, profit float, ticket float, type int, open_price float, close_price float, open_time datetime, close_time datetime, symbol varchar(10), size float);";
   if (MySqlExecute(DB1, Query)){
      Print ("Tabela transactions zostala utworzona pomyslanie.");
      Query = "ALTER TABLE transactions ADD CONSTRAINT uq_transactions UNIQUE(strategy, ticket, symbol, type);";
      if (MySqlExecute(DB1, Query)){
         Print ("Tabela transactions zostala zmodyfikowana pomyslanie.");
      }
      else{
         Print ("Nie zmodyfikowano tabeli transactions. Blad: ", MySqlErrorDescription);
      }
   }
   else{
      Print ("Nie utworzono tabeli transactions. Blad: ", MySqlErrorDescription);
   } 
      return(INIT_SUCCEEDED);
   }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason){
   FileClose(handle);
   CheckForUpdate();
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick(){
//--- go trading only for first tiks of new bar   
   CheckForUpdate();
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
