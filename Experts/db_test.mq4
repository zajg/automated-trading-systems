//+------------------------------------------------------------------+
//|                                                    MySQL-002.mq4 |
//|                                   Copyright 2014, Eugene Lugovoy |
//|                                        http://www.fxcodexlab.com |
//| Table creation (DEMO)                                            |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, Eugene Lugovoy."
#property link      " "
#property version   " "

#include <MQLMySQL.mqh>

int handle;
int db;
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnInit(){
handle=FileOpen("db222.txt",FILE_TXT|FILE_READ|FILE_WRITE," ");
//db = MySqlConnect("localhost", "root", "root", "javadb", 3306, "", 0);
}

void OnTick()
{
   
   FileSeek(handle,0,SEEK_END);
   FileWrite(handle,"xq222xStart systemu: ", TimeToString(TimeCurrent())); 
   db = MySqlConnect("localhost", "root", "root", "javadb", 3306, "", 0);
   //FileWrite (handle, "Laczenie z baza...");   
   //DB1 = MySqlConnect(Host, User, Password, Database, Port, "", 0);
   //FileWrite (handle, "tu mnie nie ma...");
}
//+------------------------------------------------------------------+
void OnDeinit(){
FileClose(handle);
}