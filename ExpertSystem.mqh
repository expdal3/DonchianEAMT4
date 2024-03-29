//--- include
#include "ExpertCollection.mqh"                     //connect with CDonchianExpertCollection
#define  CExpertCollection CExpertDonchianCollection 
//+------------------------------------------------------------------+
//| struct to implement multiTimeframe strategy                      |
//+------------------------------------------------------------------+

struct STimeframeStrategy{
   
   ENUM_TIMEFRAMES      Timeframe;
   string               EntryStrategy;
   double               OrderSize;
   CExpertCollection*   Expert;      
  };

struct SStrategyTimeframePool{
   STimeframeStrategy	Timeframes[];
};


class CExpertDonchianSystem {

public:
   SStrategyTimeframePool   mStrategies;          // arrays to hold multiple DonchianExpert with different symbols and magicnumber
   
protected:   
   SDonchianEAParameter  mCommonParams; 
   //string                mSystemInputString;
   // News Filter module
   SNewsWrapper         mNewsData;           //  Store an instance of CNews class which contain news data passed down from CExpertSystem class
      
   CTimer               *mTimer;
   bool                 mFirstTime;
   bool                 mDebug;


public:
   CExpertDonchianSystem(string systemInput);
   ~CExpertDonchianSystem(void){};
   CStrategyInput       *mSystemInput;

            // Specify the common parameters accross different timeframe instance
            void   SetCommonParameters(string symbolStrList, string symbolSuffix,string magicStrList                                      //, ENUM_TIMEFRAMES timeFrame
                            ,int donchianPeriod                                                                                        //, ENUM_BLUES_STRATEGY_DIRECTION  tradeEntryStrategy
                            , int noMoreTradeWithinXMins
                            ,ENUM_OFX_TPSL_TYPE tpslType, int tpPoints,int slPoints, double rrRatio ,int atrPeriods,double atrMultiplier
                            ,string tradeComment ,int maxMainBuySignalTradeAllowed	,int maxMainSellSignalTradeAllowed, int padEntryValuePoint  //double orderSize
                            ,bool isNewsFilterEnabled ,int minutesBeforeNews,int minutesAfterNews,ENUM_BLUES_NEWS_IMPACT newsImpactToFilter 
                            ,bool showSignalArrows );
            
            void   SetCommonParameters(string symbolStrList, string symbolSuffix,string magicStrList, ENUM_TIMEFRAMES timeFrame
                            ,int donchianPeriod, ENUM_BLUES_STRATEGY_DIRECTION  tradeEntryStrategy, int noMoreTradeWithinXMins
                            ,ENUM_OFX_TPSL_TYPE tpslType, int tpPoints,int slPoints, double rrRatio ,int atrPeriods,double atrMultiplier
                            ,double orderSize, string tradeComment ,int maxMainBuySignalTradeAllowed	,int maxMainSellSignalTradeAllowed, int padEntryValuePoint  //
                            ,bool isNewsFilterEnabled ,int minutesBeforeNews,int minutesAfterNews,ENUM_BLUES_NEWS_IMPACT newsImpactToFilter 
                            ,bool showSignalArrows );
            void   SetupNewsFilter(bool isNewsFilterEnabled, int impactToFilter, int beforeNewsMinutes, int afterNewsMinutes);
protected:
            //---Setup the whole trading strategy system with one or more timeframe / settings
            void   Setup();
            
            //-- initiate a specific timeframe instance
            void   SetStrategy();                                                            //this use common parameters         
            void   SetStrategy(string symbolStrList, string symbolSuffix,string magicStrList, ENUM_TIMEFRAMES timeFrame       //this use specified parameters              
                            ,int donchianPeriod, ENUM_BLUES_STRATEGY_DIRECTION  tradeEntryStrategy, int noMoreTradeWithinXMins
                            ,ENUM_OFX_TPSL_TYPE tpslType, int tpPoints,int slPoints, double rrRatio ,int atrPeriods,double atrMultiplier
                            ,double orderSize, string tradeComment ,int maxMainBuySignalTradeAllowed	,int maxMainSellSignalTradeAllowed, int padEntryValuePoint
                            ,bool isNewsFilterEnabled ,int minutesBeforeNews,int minutesAfterNews,ENUM_BLUES_NEWS_IMPACT newsImpactToFilter 
                            ,bool showSignalArrows );
            //void  SetNewsToStrategy(CExpertCollection &expert);
public:
            void   OnTick(bool debug=false);
            void   OnDeinit();
};

CExpertDonchianSystem::CExpertDonchianSystem(string systemInput){
      mSystemInput = new CStrategyInput();
      mSystemInput.SetSystemInputString(systemInput); //parse in the system's input strins
}

void   CExpertDonchianSystem::SetCommonParameters(string symbolStrList, string symbolSuffix,string magicStrList
                            ,int donchianPeriod, int noMoreTradeWithinXMins
                            ,ENUM_OFX_TPSL_TYPE tpslType, int tpPoints,int slPoints, double rrRatio ,int atrPeriods,double atrMultiplier
                            ,string tradeComment ,int maxMainBuySignalTradeAllowed	,int maxMainSellSignalTradeAllowed, int padEntryValuePoint        //double orderSize,
                            ,bool isNewsFilterEnabled ,int minutesBeforeNews,int minutesAfterNews,ENUM_BLUES_NEWS_IMPACT newsImpactToFilter 
                            ,bool showSignalArrows){

   #ifdef __MQL5__
      ENUM_TIMEFRAMES _period = Period();
   #endif 
   
   #ifdef __MQL4__
      ENUM_TIMEFRAMES _period = (ENUM_TIMEFRAMES) Period();
   #endif 
   
   SetCommonParameters(symbolStrList, symbolSuffix, magicStrList, _period, donchianPeriod,_Break_out_, noMoreTradeWithinXMins
                                          ,tpslType, tpPoints, slPoints, rrRatio ,atrPeriods,atrMultiplier
                                          ,SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MIN), tradeComment ,maxMainBuySignalTradeAllowed,maxMainSellSignalTradeAllowed, padEntryValuePoint         //orderSize
                                          ,isNewsFilterEnabled, minutesBeforeNews,minutesAfterNews, newsImpactToFilter 
                                          ,showSignalArrows);

   mFirstTime = true;

}

void   CExpertDonchianSystem::SetCommonParameters(string symbolStrList, string symbolSuffix,string magicStrList, ENUM_TIMEFRAMES timeFrame
                            ,int donchianPeriod, ENUM_BLUES_STRATEGY_DIRECTION  tradeEntryStrategy, int noMoreTradeWithinXMins
                            ,ENUM_OFX_TPSL_TYPE tpslType, int tpPoints,int slPoints, double rrRatio ,int atrPeriods,double atrMultiplier
                            ,double orderSize, string tradeComment ,int maxMainBuySignalTradeAllowed	,int maxMainSellSignalTradeAllowed, int padEntryValuePoint
                            ,bool isNewsFilterEnabled ,int minutesBeforeNews,int minutesAfterNews,ENUM_BLUES_NEWS_IMPACT newsImpactToFilter 
                            ,bool showSignalArrows){

   
   mCommonParams.SymbolStringList = symbolStrList;
   mCommonParams.Suffix =  symbolSuffix;
   mCommonParams.MagicStringList = magicStrList;
   mCommonParams.Timeframe = timeFrame;
   
   mCommonParams.DonchianPeriod = donchianPeriod;                     
   mCommonParams.TradeEntryStrategy = tradeEntryStrategy;             
   mCommonParams.NoMoreTradeWithinXMins = noMoreTradeWithinXMins;         

   //--- TPSL parameters
   mCommonParams.TPSLType = tpslType;
   mCommonParams.TPPoints = tpPoints;                       
   mCommonParams.SLPoints = slPoints;                       
   mCommonParams.RRratio  = rrRatio;                       
   mCommonParams.ATRPeriods = atrPeriods;	                    
	mCommonParams.ATRMultiplier = atrMultiplier;	                 

   //	general trading info
	mCommonParams.OrderSize =		orderSize; 
	mCommonParams.TradeComment =		 tradeComment; 
	mCommonParams.MaxMainBuySignalTradeAllowed =	maxMainBuySignalTradeAllowed; 
	mCommonParams.MaxMainSellSignalTradeAllowed	= maxMainSellSignalTradeAllowed; 
   mCommonParams.PadEntryValuePoint = padEntryValuePoint;

   mCommonParams.IsNewsFilterEnabled =   isNewsFilterEnabled;             
   mCommonParams.MinutesBeforeNews  =     minutesBeforeNews;             
   mCommonParams.MinutesAfterNews  =     minutesAfterNews;             
   mCommonParams.NewsImpactToFilter  =   newsImpactToFilter;              

   mCommonParams.ShowSignalArrows  =    showSignalArrows;

   // load news on init
   SetupNewsFilter(isNewsFilterEnabled, newsImpactToFilter, minutesBeforeNews, minutesAfterNews); //enable NewsFilter setting
}
//---

void   CExpertDonchianSystem::SetStrategy(){
   int count = ArraySize(mStrategies.Timeframes);
   if(count <8) ArrayResize(mStrategies.Timeframes,8);         //avoid out-of-range array error;
   ENUM_TIMEFRAMES blankTimeframe;
   string tfSuffix="";
   for(int i=0;i<count;i++){
      if(mStrategies.Timeframes[i].EntryStrategy == NULL) continue;
      
      tfSuffix = "_"+EnumToTimeframeString(mStrategies.Timeframes[i].Timeframe);
      
      // instantiate CExpertCollection instance
      if (mStrategies.Timeframes[i].Expert ==NULL) 
            mStrategies.Timeframes[i].Expert 
               = new CExpertCollection(mCommonParams.SymbolStringList, mCommonParams.Suffix, mCommonParams.MagicStringList, mStrategies.Timeframes[i].Timeframe, mCommonParams.DonchianPeriod, StringToTradeEntryStrategyEnum( mStrategies.Timeframes[i].EntryStrategy)
                                    , mCommonParams.NoMoreTradeWithinXMins
                                    ,mCommonParams.TPSLType, mCommonParams.TPPoints, mCommonParams.SLPoints, mCommonParams.RRratio ,mCommonParams.ATRPeriods,mCommonParams.ATRMultiplier
                                    ,mStrategies.Timeframes[i].OrderSize, mCommonParams.TradeComment+tfSuffix , mCommonParams.MaxMainBuySignalTradeAllowed, mCommonParams.MaxMainSellSignalTradeAllowed     //mCommonParams.OrderSize
      										,mCommonParams.PadEntryValuePoint
                                    ,mCommonParams.IsNewsFilterEnabled, mCommonParams.MinutesBeforeNews, mCommonParams.MinutesAfterNews, mCommonParams.NewsImpactToFilter 
                                    ,mCommonParams.ShowSignalArrows
                                 );
    }
}

//---

void   CExpertDonchianSystem::SetStrategy(string symbolStrList, string symbolSuffix,string magicStrList, ENUM_TIMEFRAMES timeFrame                
                                  ,int donchianPeriod, ENUM_BLUES_STRATEGY_DIRECTION  tradeEntryStrategy, int noMoreTradeWithinXMins
                                  ,ENUM_OFX_TPSL_TYPE tpslType, int tpPoints,int slPoints, double rrRatio ,int atrPeriods,double atrMultiplier
                                  ,double orderSize, string tradeComment ,int maxMainBuySignalTradeAllowed	,int maxMainSellSignalTradeAllowed, int padEntryValuePoint
                                  ,bool isNewsFilterEnabled ,int minutesBeforeNews,int minutesAfterNews,ENUM_BLUES_NEWS_IMPACT newsImpactToFilter 
                                  ,bool showSignalArrows){

   int count = ArraySize(mStrategies.Timeframes);
   if(count <8) ArrayResize(mStrategies.Timeframes,8);         //avoid out-of-range array error;
   int tf = EnumToTimeframeInt (timeFrame);
   #define strategyExpert mStrategies.Timeframes[tf].Expert
   if (strategyExpert ==NULL) 
         strategyExpert 
               = new CExpertCollection(symbolStrList, symbolSuffix, magicStrList, timeFrame, donchianPeriod, tradeEntryStrategy, noMoreTradeWithinXMins
                                          ,tpslType, tpPoints, slPoints, rrRatio ,atrPeriods,atrMultiplier
                                          ,orderSize, tradeComment ,maxMainBuySignalTradeAllowed,maxMainSellSignalTradeAllowed, padEntryValuePoint
                                          ,isNewsFilterEnabled, minutesBeforeNews,minutesAfterNews, newsImpactToFilter 
                                          ,showSignalArrows
                                       );
   
   #undef  strategyExpert
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+


void  CExpertDonchianSystem::OnTick(bool debug=false){
   
   if(mFirstTime == true){
      Setup();
      mFirstTime = false;
     }
   
   int  count = ArraySize(mStrategies.Timeframes);
   //if (count == 0) return;             // exit if pool empty
   // -- Update news
   //

	mNewsData.mNews.Update();          // update the news module every 4 hours (re-load weekly news from website + pick out the currentDay News)
	bool isNewsFilterEnabled =  mNewsData.mNews.IsNewsFilterEnabled();

   string selectedTimeframe;
   //-- execute CExpertCollection OnTick()
	for(int i=count - 1;i>=0;i--){
	   selectedTimeframe = EnumToTimeframeString(mStrategies.Timeframes[i].Timeframe);
      if(StringFind(mSystemInput.SystemInputString(), selectedTimeframe ) <0 ) continue; //if not the specified timeframe in the SystemInputString
      if(mStrategies.Timeframes[i].Expert==NULL)   continue;
      
      mStrategies.Timeframes[i].Expert.SetNewsData(mNewsData);      //pass the updated NewsData down to the ExpertCollection
      mStrategies.Timeframes[i].Expert.OnTick(true,false);
      
   }

}

//---

void   CExpertDonchianSystem::Setup(){
   //creat timer
   mTimer = new CTimer();
   
   // take in poolInput strings and process it into the mStrategies
   mSystemInput.SetTimeframeStringInputsToStruct(mStrategies);          //mStrategies is an array
   
   int   count = ArraySize(mStrategies.Timeframes);
   if (count == 0) return;             // exit if mStrategies empty
   string selectedTimeframe;
   //--- loop thru mStrategies and instanstiate new CDonchianExpert object for each symbol
   for(int i=count - 1;i>=0;i--){
      selectedTimeframe = EnumToTimeframeString(mStrategies.Timeframes[i].Timeframe);
      if(StringFind(mSystemInput.SystemInputString(), selectedTimeframe ) <0 ) continue; //if not the specified timeframe in the SystemInputString
      SetStrategy(); //mStrategies.Timeframes[i].Timeframe
   }

}
      

	
void   CExpertDonchianSystem::OnDeinit(){
   int   count = ArraySize(mStrategies.Timeframes);
   if (count == 0) return;             // exit if pool empty
   //--- loop thru mPool and delete all CExpert instance
   for(int i=count - 1;i>=0;i--){
      if (mStrategies.Timeframes[i].Expert==NULL) continue;
      delete mStrategies.Timeframes[i].Expert;
   }
}


void CExpertDonchianSystem::SetupNewsFilter(bool isNewsFilterEnabled, int impactToFilter, int beforeNewsMinutes, int afterNewsMinutes){            //This is called on Initialize of this class
      
      #define News mNewsData.mNews
      //Set up News Filter once when first loaded
      News = new CNews("calendar.csv","HistoryNewsEvents_2020.csv");
      
      if(IS_DEBUG_MODE || IsTesting() ) {
         News.LoadHistoryNewsFromFile(News.HistoryNewsFileName());      //load history newsEvent    **warning this may take sometimes to load in tester - best to only load one year of past news
         //mNews.FilterG8CurrenciesNews();                                  // filter only those news of G8 currency

      }
      else {
      Print ("downloading News from FF Calendar");
      News.LoadNewsFromDownloadResponse();
      
      // go thru and print out all the news to check
      //
      int countevent = ArraySize(News.mEvents);
      if(countevent > 0){
      for(int i=countevent-1;i>=0;i--){
         PrintFormat(__FUNCTION__+"i:%d, News: %s, Pair: %s, Impact: %s, PreTime: %s, EndTime: %s ", i
      	                     , News.mEvents[i].Title
      	                     , News.mEvents[i].Currency
      	                     , News.mEvents[i].Impact
      	                     , TimeToString(News.mEvents[i].DateTime - News.BeforeNewsMinutes()*60, TIME_DATE|TIME_MINUTES)
      	                     , TimeToString(News.mEvents[i].DateTime + News.AfterNewsMinutes()*60, TIME_DATE|TIME_MINUTES)
      	                     );
              }
           }
      }

      News.SetNewsFilterParameters(isNewsFilterEnabled, impactToFilter, beforeNewsMinutes, afterNewsMinutes);
      #undef News
}
//---
