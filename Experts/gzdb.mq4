#property copyright "Grzegorz Zajac"
#property link      "..."
#property version   "0.3.4"
#property strict

#include <MQLMySQL.mqh>

int handle;
int DB1;

string INI;
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
int OnInit()
{
   string Host, User, Password, Database, Socket; // database credentials
   int Port,ClientFlag;
   
   
   handle=FileOpen("db0.txt",FILE_CSV|FILE_READ|FILE_WRITE," "); 
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
   FileWrite (handle, "Laczenie...");
   
   DB1 = MySqlConnect(Host, User, Password, Database, Port, 0, 0);
   
   if (DB1 == -1) {
      FileWrite (handle, "Connection failed! Error: "+MySqlErrorDescription); 
   } 
   else { 
      FileWrite (handle, "Polaczono! DBID#",DB1);
   }
   
    //Query = "CREATE TABLE IF NOT EXISTS `transactions` (id int, code varchar(50), start_date datetime);";
   Query = "CREATE TABLE IF NOT EXISTS `transactions` (id int KEY NOT NULL AUTO_INCREMENT UNIQUE, strategy int, user int, profit float, ticket float, open_price float, close_price float, open_time datetime, close_time datetime, symbol varchar(20), size float)";
   if (MySqlExecute(DB1, Query)){
      FileWrite (handle,"Tabela transactions zostala utworzona pomyslanie.");
   }
   else{
      FileWrite (handle,"Nie utworzono tabeli transactions. Blad: ", MySqlErrorDescription);
   }
   
   int    i,Cursor,Rows;
   
   int      vId;
   string   user_name;
   datetime vStartTime;
   
   Query = "SELECT id, user_name FROM `user`";
   Cursor = MySqlCursorOpen(DB1, Query);
   if (Cursor >= 0){
      Rows = MySqlCursorRows(Cursor);
      FileWrite (handle, Rows, " row(s) selected.");
      for (i=0; i<Rows; i++)
         if (MySqlCursorFetchRow(Cursor)){
            vId = MySqlGetFieldAsInt(Cursor, 0); // id
            user_name = MySqlGetFieldAsString(Cursor, 1); // code
            //vStartTime = MySqlGetFieldAsDatetime(Cursor, 2); // start_time
            //FileWrite (handle,"ROW[",i,"]: id = ", vId, ", code = ", vCode, ", start_time = ", TimeToStr(vStartTime, TIME_DATE|TIME_SECONDS));
            FileWrite (handle, "User ID: ", vId, ", Username: ", user_name);
         }
      MySqlCursorClose(Cursor); // NEVER FORGET TO CLOSE CURSOR !!!
    }
   else{
      FileWrite (handle,"Cursor opening failed. Error: ", MySqlErrorDescription);
   }
   
   //Query = "INSERT INTO `user` (id, active, email, last_login_time,password, register_datetime, user_name, flat_id) VALUES (\'2\', \'0\', \'gg1@gg.pl\', NULL, \'mm\', \'2015-12-11 22:58:08\', \'mm\', NULL );";
   //if (MySqlExecute(DB1, Query)){
   //   FileWrite (handle,"Succeeded! 3 rows has been inserted by one query.");
   //}
   //else{
   //   FileWrite (handle,"Error of multiple statements: ", MySqlErrorDescription);
   //}
   
   FileClose(handle); 
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
void OnTick(){
  FileWrite (handle,"tick");
  return;
}