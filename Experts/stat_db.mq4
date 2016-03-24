//+------------------------------------------------------------------+
//|                                                         stat.mq4 |
//|                                                   Grzegorz Zajac |
//|                                      http://www.grzesiekzajac.pl |
//+------------------------------------------------------------------+
#property copyright "Grzegorz Zajac"
#property link      "http://www.grzesiekzajac.pl"
#property version   "7.90"

#define MAGIC 1
#include <MQLMySQL.mqh>
//#include <mql4-mysql.mqh>

int handle;
int DB1;
int ile =0;
int added_to = 0;

string INI;

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
//| Function Sending Orders For Every Client                         |
//+------------------------------------------------------------------+
void SendMultipleOrder(int type){
   int    i,Cursor,Rows, res, vId;
   double  vSize;
   string Query = "SELECT id, stat_size FROM `user`";
   Cursor = MySqlCursorOpen(DB1, Query);
   //Print ("xxxxxxxxxxxxxxxxxxxxxxxxxxxx[MULTIPLE ORDER]xxxxxxxxxxxxxxxxxxxxxxxxxxxx");
   if (Cursor >= 0){
      Rows = MySqlCursorRows(Cursor);
      //FileWrite (handle, Rows, " row(s) selected.");
      for (i=0; i<Rows; i++){
         if (MySqlCursorFetchRow(Cursor)){
            vId = MySqlGetFieldAsInt(Cursor, 0); // id
            vSize = MySqlGetFieldAsDouble(Cursor, 1); // Size
            Print ("xxxxxxxxxxxxxxxxxxxxxxxxxxxx[MULTIPLE ORDER]xxxxxxxxxxxxxxxxxxxxxxxxxxxx id: ", vId, " rozmiar: ", vSize);
            if(type == 1)       res = OrderSend(Symbol(), OP_SELL, vSize,Bid,3,Bid+stopLoss*Point, Bid-stopLoss*takeProfitMultiplicator*Point, IntegerToString(vId), MAGIC,0,Red);
            else if (type == 2) res = OrderSend(Symbol(), OP_BUY, vSize,Ask,3,Ask-stopLoss*Point,Ask+stopLoss*takeProfitMultiplicator*Point,IntegerToString(vId), MAGIC,0,Blue);
         }      
      }
      MySqlCursorClose(Cursor); // NEVER FORGET TO CLOSE CURSOR !!!
    }
   else{
      FileWrite (handle,"Cursor opening failed. Error: ", MySqlErrorDescription);
   }
}

//+------------------------------------------------------------------+
//| Database Updating Function                                       |
//+------------------------------------------------------------------+
void CheckForUpdate(){
ile++;
Print("Wywolano mnie ", ile, " raz. Jest razem ", OrdersHistoryTotal(), " transakcji.");
   string Query;
   //---   
   //Print("                                                                                       Robie update "+TimeToString(TimeCurrent())+". Wszystkich transakcji: "+(string)OrdersHistoryTotal());
   for(int i=added_to;i<OrdersHistoryTotal();i++){
      if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==TRUE){
         if(OrderMagicNumber()!=MAGIC || OrderSymbol()!=Symbol()) continue; 
         //Print("                                                                                       Probuje dodac do bazy: "+(string)OrderTicket());
         Query = "INSERT INTO `transactions` (strategy, user, profit, ticket, type, open_price, close_price, open_time, close_time, symbol, size) VALUES ("+(string)MAGIC+", "+StringSubstr(OrderComment(),0,StringLen(OrderComment())-4)+", "+DoubleToString(OrderProfit() + OrderSwap() + OrderCommission())+", "+(string)OrderTicket()+", "+OrderType()+", "+(string)OrderOpenPrice()+", "+(string)OrderClosePrice()+", \'"+TimeToString(OrderOpenTime())+"\', \'"+TimeToString(OrderCloseTime())+"\', \'"+(string)OrderSymbol()+"\', "+(string)OrderLots()+");";
         Print("[SQL] >>> " + Query);
         Print("Iteracja petli nr ", i, ". Ticket nr ", OrderTicket());
         if (MySqlExecute(DB1, Query)){        
            Print("                                                                                       Transakcja" + (string)OrderTicket() + "dodana do bazy.");
         }
         else{
            Print("                                                                                       Blad dodawania transakcji: " + (string)OrderTicket() + "do bazy. Blad: " +MySqlErrorDescription);
         }   
      } 
          
   }
   added_to = OrdersHistoryTotal();
}

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
      SendMultipleOrder(1);     
      return;
   }
//--- buy conditions
   if(condition1 == 1 && condition2 == 1 && condition3 == 1){
      SendMultipleOrder(2);
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
   string Query;
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
   Print("====================================================================================================================");
   string Host = "127.0.0.1", User = "root", Password = "root" , Database="javadb"; // database credentials
   int Port=3306;   
   
   handle=FileOpen("stat_db.txt",FILE_CSV|FILE_READ|FILE_WRITE," "); 
   FileWrite(handle,"Start systemu: ", TimeToString(TimeCurrent())); 
   
   INI = "C:\\Users\\lenovo\\AppData\\Roaming\\MetaQuotes\\Terminal\\0FC27529066061916C718B44D2E4BAC3\\MQL4\\Experts\\MyConnection.ini";
   FileWrite(handle,"Plik inicjalizacyjny: ", INI);
   
   Host     = ReadIni(INI, "MYSQL", "Host");   
   Port     = StrToInteger(ReadIni(INI, "MYSQL", "Port"));   
   Database = ReadIni(INI, "MYSQL", "Database");
   User     = ReadIni(INI, "MYSQL", "User");
   Password = ReadIni(INI, "MYSQL", "Password");
   
   FileWrite (handle, "Host: ",Host, ", User: ", User, ", Database: ",Database);
   
   string Query;   
   
   // open database connection
   FileWrite (handle, "Laczenie z baza...");
   
   if(!IsOptimization()) DB1 = MySqlConnect(Host, User, Password, Database, Port, "", 0); 
   if (DB1 == -1) {
      FileWrite (handle, "Polaczenie nie udalo sie! Blad: "+MySqlErrorDescription); 
   } 
   else { 
      FileWrite (handle, "Polaczono! DBID#",DB1);
   }
   
   Query = "CREATE TABLE IF NOT EXISTS `transactions` (id int KEY NOT NULL AUTO_INCREMENT, strategy int, user int, profit float, ticket float, type int, open_price float, close_price float, open_time datetime, close_time datetime, symbol varchar(10), size float);";
   if (MySqlExecute(DB1, Query)){
      FileWrite (handle,"Tabela transactions zostala utworzona pomyslanie.");
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
void OnDeinit(const int reason)
  {
//---
      FileClose(handle);
      CheckForUpdate();
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick(){
//---
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
