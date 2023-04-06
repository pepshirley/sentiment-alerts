//+------------------------------------------------------------------+
//|                                                   Sentiment Alerts.mq4 |
//|                                          Copyright 2021, Perpetual Vincent |
//|                                               http://mql5.com|
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Perpetual Vincent"
#property link      "http://mql5.com"
#property version   "1.00"
#property  strict

input string    chat_id = "1380098782";//Chat ID
input string    token  = "5007154718:AAHWEu2vCue-1hPS1iZqbWasSg5fywVvjB0";//Bot token
input string    InpOtherSymbols = "Wall Street=US30.cash,US 500=US500.cash,FTSE 100=UK100.cash,France 40=FRA40.cash,Oil - US Crude=USOIL.cash,Germany 40=""";//Special symbols

string        cookie       = NULL,headers;
char          post[];

int           resu;
string        baseurl      = "https://api.telegram.org";

string DATA[];
string OtherSymbols[];
string AllSymbols[];
string Currencies[] = {"USD","AUD","CAD","CHF","EUR","GBP","JPY","NZD"};

string symbols[] = {"AUD","CAD","CHF","EUR","GBP","JPY","NZD","USD"};
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(StringLen(InpOtherSymbols) > 0)
      StringSplit(InpOtherSymbols,StringGetCharacter(",",0),OtherSymbols);


   for(int j=0; j<SymbolsTotal(true); j++)
     {
      string sym = SymbolName(j,true);

      if(!IsMajorPair(sym))
         continue;

      if(StringFind(sym,"USD") < 0)
         continue;

      if(!IsFound(sym,AllSymbols))
         AddToArray(AllSymbols,sym);
     }





   EventSetTimer(300);
   OnTimer();
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   EventKillTimer();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(IsNewBar())
      SendUpdates();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer()
  {
//  SendUpdates();




  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double SendUpdates()
  {

//Print("New bar formed.");

   int timeout = 2000;

   string url = "https://www.dailyfx.com/sentiment-report";

   char results[];

   resu = WebRequest("GET",url,cookie,NULL,timeout,post,0,results,headers);

   Print("Webrequest returned ",resu);

   GetData(results);

   string data = "";

   data = "SENTIMENT REPORT @ "+TimeToString(TimeCurrent())+"\n";

   for(int i=0; i<ArraySize(AllSymbols); i++)
     {
      string name = AllSymbols[i];

      string symdata[];

      ArrayFree(symdata);

      GetSymbolData(name,symdata);

      /*  for(int j=0; j<ArraySize(symdata); j++)
       {
        Print(symdata[j]);
       }*/

      if(ArraySize(symdata) > 0)
        {
         StringReplace(symdata[1]," ","");
         StringReplace(symdata[2]," ","");
         StringReplace(symdata[3]," ","");
         StringReplace(symdata[4]," ","");
         StringReplace(symdata[5]," ","");
         StringReplace(symdata[6]," ","");

         double longs  = StringToDouble(symdata[1]);
         double shorts = StringToDouble(symdata[2]);
         double pLong  = StringToDouble(symdata[3]);
         double pShort = StringToDouble(symdata[5]);
         double pLongW = StringToDouble(symdata[4]);
         double pShortW = StringToDouble(symdata[6]);
         double ratio   = longs/shorts;

         if(pLong > 5)
           {
            SendToTelegram(name+"=> "+"Buyers up +"+pLong+"% in 24h!. Ratio = "+(string)ratio);
           }

         if(pShort > 5)
           {
            SendToTelegram(name+"=> "+"Sellers up +"+pShort+"% in 24h!. Ratio = "+(string)ratio);
           }

         if(pLongW > 5)
           {
            SendToTelegram(name+"=> "+"Buyers up +"+pLongW+"% in 1w!. Ratio = "+(string)ratio);
           }

         if(pShortW > 5)
           {
            SendToTelegram(name+"=> "+"Sellers up +"+pShortW+"% in 1w!. Ratio = "+(string)ratio);
           }


         data += name+" => "+" Longs="+longs+", Shorts="+shorts+", %Change In Longs="+pLong+", %Change In Shorts="+pShort+", %Change In Weekly Longs="+pLongW+", %Change In Weekly Shorts="+pShortW+"\n";



        }

     }

   Comment(data);

   return 0;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string GetSymbol(string text)
  {

   StringReplace(text,"/","");

   for(int i=0; i<ArraySize(AllSymbols); i++)
     {
      string name = AllSymbols[i];

      if(StringFind(text,name)>=0)
         return name;

      if(StringFind(text,GetSymbolKey(name))>=0)
         return name;
     }

   if(StringFind(text,"Gold")>=0)
      return "XAUUSD";

   if(StringFind(text,"Silver")>=0)
      return "XAGUSD";



   return "";
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string GetSymbolKey(string value)
  {

   for(int j=0; j<ArraySize(OtherSymbols); j++)
     {
      string parts[];

      StringSplit(OtherSymbols[j],StringGetCharacter("=",0),parts);

      if(ArraySize(parts) > 0)
        {
         if(parts[1] == value)
            return parts[0];
        }
     }

   return "";
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string GetLong(string text)
  {

   return StringSubstr(text,StringFind(text,"%")-5,5);

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetData(char &text[])
  {

   int locs[];

   string blocks[];

   string preblocks[];

   string changelocs[];

   string textstring = CharArrayToString(text);

   for(int i=ArraySize(text)-100; i>=0; i--)
     {
      if(CharToString(text[i])=="T" && CharToString(text[i+1])=="h" && CharToString(text[i+2])=="e" && CharToString(text[i+3])==" " && CharToString(text[i+4])=="n"
         && CharToString(text[i+5])=="u" && CharToString(text[i+6])=="m" && CharToString(text[i+7])=="b" && CharToString(text[i+8])=="e" && CharToString(text[i+9])=="r"
         && CharToString(text[i+10])==" " && CharToString(text[i+11])=="o" && CharToString(text[i+12])=="f" && CharToString(text[i+13])==" " && CharToString(text[i+14])=="t"
         && CharToString(text[i+15])=="r" && CharToString(text[i+16])=="a" && CharToString(text[i+17])=="d" && CharToString(text[i+18])=="e" && CharToString(text[i+19])=="r"
         && CharToString(text[i+20])=="s" && CharToString(text[i+21])==" " && CharToString(text[i+22])=="n" && CharToString(text[i+23])=="e" && CharToString(text[i+24])=="t"
         && CharToString(text[i+25])=="-" && CharToString(text[i+26])=="l" && CharToString(text[i+27])=="o" && CharToString(text[i+28])=="n" && CharToString(text[i+29])=="g")
        {
         AddToArray(locs,i);
        }
     }

   for(int j=0; j<ArraySize(locs); j++)
     {
      AddToArray(blocks,StringSubstr(textstring,locs[j],350));
     }
   string data="";
   for(int l=0; l<ArraySize(locs); l++)
     {
      string sect = StringSubstr(textstring,locs[l]-200,200);
      string post = StringSubstr(textstring,locs[l],200);
      StringReplace(sect,"/","");
      data += GetSymbol(sect)+",";//AddToArray(preblocks,sect);
      data += GetLong(sect)+",";

      char b2c[];

      StringToCharArray(post,b2c);

      for(int s=0; s<ArraySize(b2c); s++)
        {
         if(CharToString(b2c[s])=="%")
            data += StringSubstr(post,s-5,12)+",";//AddToArray(changelocs,StringSubstr(post,s-5,5));
        }

      data += "\n";
     }



   /* int handle = FileOpen("CURRENT SENTIMENT.txt",FILE_WRITE);

    FileWriteString(handle,data);

    FileClose(handle);*/


   StringSplit(data,StringGetCharacter("\n",0),DATA);

   if(ArraySize(DATA)==0)
      return 0;

// Print(DATA[7]);


   return 0;
  }



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void AddToArray(int &array[], int value)
  {

   ArrayResize(array, ArraySize(array)+1);
   array[ArraySize(array)-1] = value;

  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void AddToArray(string &array[], string value)
  {

   ArrayResize(array, ArraySize(array)+1);
   array[ArraySize(array)-1] = value;

  }



//+------------------------------------------------------------------+
void GetSymbolData(string sym, string &array[])
  {
   ArrayFree(array);

   for(int i=0; i<ArraySize(DATA); i++)
     {
      //Print("Data ",i+1," = ",DATA[i]);
      if(StringFind(DATA[i],sym) >= 0 || StringFind(DATA[i],GetSymbolKey(sym)) >= 0)
        {

         if(StringFind(DATA[i],sym) >= 0)
            AddToArray(array,sym);

         else
            AddToArray(array,GetSymbolKey(sym));

         string parts[];

         StringSplit(DATA[i],StringGetCharacter(",",0),parts);

         if(ArraySize(parts)==0)
            continue;

         AddToArray(array,parts[1]);
         AddToArray(array,(string)(100-(double)parts[1]));

         for(int j=0; j<ArraySize(parts); j++)
           {
            if(StringFind(parts[j],"lower") >= 0)
              {
               StringTrimLeft(StringTrimRight(parts[j]));
               StringReplace(parts[j],"lower","");
               StringReplace(parts[j],"%","");
               parts[j] = "-"+parts[j];
               AddToArray(array,parts[j]);
              }

            else
               if(StringFind(parts[j],"highe") >= 0)
                 {
                  StringTrimLeft(StringTrimRight(parts[j]));
                  StringReplace(parts[j],"highe","");
                  StringReplace(parts[j],"%","");
                  AddToArray(array,parts[j]);
                 }
           }
        }
     }


  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsCurrencyPair(string sym)
  {

   int currcnt = 0;

   for(int i=0; i<ArraySize(Currencies); i++)
     {
      if(StringFind(sym,Currencies[i]) >= 0)
         currcnt++;
     }

   if(currcnt >= 2)
      return true;

   return false;
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsNewBar()
  {
   static datetime  currentTime   = 0;
   bool             result        = (currentTime!=Time[0]); //Result is true only if new bar has been formed
   if(result)
      currentTime   = Time[0]; // while returning true result, also re-assign currentTime to Time [0]


   return result; //return a true result meaning new bar has been formed


  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsMajorPair(string symbol)
  {

   int cnt = 0;

   for(int i=0; i<ArraySize(symbols); i++)
     {
      if(StringFind(symbol,symbols[i]) >= 0)
         cnt++;
     }

   if(cnt >= 2)
      return true;

   return false;
  }
//+------------------------------------------------------------------+
bool IsFound(string value, string &array[])
  {

   for(int i=0; i<ArraySize(array); i++)
     {
      if(value == array[i])
         return(true);
     }

   return(false);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int SendToTelegram(string message)
  {


   int timeout = 2000;
   uchar result[];



   string url = baseurl+"/bot"+token+"/sendMessage?chat_id="+chat_id+"&text="+message;

   resu = WebRequest("GET",url,cookie,NULL,timeout,post,0,result,headers);



   return(resu);
  }
//+------------------------------------------------------------------+
