//--- include
#include "Expert.mqh"                     //connect with CDonchianExpert
#include <Blues/StrategyInputClass/StrategyInputClass.mqh>

struct SExpertPool : SStrategyInput   //contains Symbol, Magic
{
  CExpertDonchian  *DonchianEA;        //hold CExpertDonchian object to manage the expert per symbol
};

struct SNewsWrapper{    CNews                *mNews;};

//--- struct to hold DonchianExpert's parameters
struct SDonchianEAParameter{           

   string                              SymbolStringList;
   string                              Suffix;
   string                              MagicStringList;
   ENUM_TIMEFRAMES                     Timeframe;

   int                                 DonchianPeriod;                 // 20 Donchian	Bands period
   ENUM_BLUES_STRATEGY_DIRECTION       TradeEntryStrategy;             // _Break_out_
   int                                 NoMoreTradeWithinXMins;         // 240 No new trade within X mins from last trade

   //--- TPSL parameters
   ENUM_OFX_TPSL_TYPE                  TPSLType;
   int                                 TPPoints;                       // 100
   int                                 SLPoints;                       // 100
   double                              RRratio ;                       // 2.5
	int				                     ATRPeriods;	                    // 14	ATR Periods
	double			                     ATRMultiplier;	                 // 3.0	ATR Multiplier

   //	general trading info
	double	                           OrderSize			            ; //=	0.01;					//	Order size
	string	                           TradeComment		            ; //	"Blueswift";	//	Trade comment
	int	                              MaxMainBuySignalTradeAllowed	; //3;				//	Max BUY trade from main Donchian signal
	int	                              MaxMainSellSignalTradeAllowed	; //	3;				//	Max SELL trade from main Donchian signal
   int                                 PadEntryValuePoint;

   bool                                IsNewsFilterEnabled       ;             // false - Enable News Filter?
   int                                 MinutesBeforeNews         ;             // 60  - minutes before news
   int                                 MinutesAfterNews          ;             // 60  - minutes after news
   ENUM_BLUES_NEWS_IMPACT              NewsImpactToFilter        ;              //= _HighImpact_;

   bool                                ShowSignalArrows       ;                                 // = false;       // Show Trade Signal on-chart?   
   
};

class CExpertDonchianCollection {

public:
   SExpertPool          mPool[];          // arrays to hold multiple DonchianExpert with different symbols and magicnumber
   
protected:
   string               mSymbolStringList;      // StringList of Symbol name from user input
   string               mSuffix;                // SymbolSuffix - provided by user
   string               mMagicStringList;       // StringList of Magicnumber from user input
   ENUM_TIMEFRAMES      mTimeframe;             // Strategy timeframe for the whole collection
   string               mEAChartSymbol;         // hold the ChartSymbo which EA drop on
   CStrategyInput       *mPoolInput;
   SDonchianEAParameter     mParams;
   
   // News Filter module
   CNews                *mNews;
   bool                    mIsNewsFilterEnabled;
   ENUM_BLUES_NEWS_IMPACT  mNewsImpactToFilter;
   int                     mMinutesBeforeNews;
   int                     mMinutesAfterNews;
   // MultiTimeframe enable
   bool                 mIsSystemComponent;
   SNewsWrapper         mNewsData;           //  Store an instance of CNews class which contain news data passed down from CExpertSystem class
         
   CTimer               *mTimer;
   bool                 mFirstTime;
   bool                 mDebug;

public:
   CExpertDonchianCollection(string symbolStrList, string symbolSuffix,string magicStrList, ENUM_TIMEFRAMES timeFrame
                            ,int donchianPeriod, ENUM_BLUES_STRATEGY_DIRECTION  tradeEntryStrategy, int noMoreTradeWithinXMins
                            ,ENUM_OFX_TPSL_TYPE tpslType, int tpPoints,int slPoints, double rrRatio ,int atrPeriods,double atrMultiplier
                            ,double orderSize, string tradeComment ,int maxMainBuySignalTradeAllowed	,int maxMainSellSignalTradeAllowed, int padEntryValuePoint
                            ,bool isNewsFilterEnabled ,int minutesBeforeNews,int minutesAfterNews,ENUM_BLUES_NEWS_IMPACT newsImpactToFilter 
                            ,bool showSignalArrows 
                             )
                              :mSymbolStringList(symbolStrList)
                              ,mSuffix(symbolSuffix)
                              ,mMagicStringList(magicStrList)
                              ,mTimeframe(timeFrame)
                                    {Init( donchianPeriod, tradeEntryStrategy, noMoreTradeWithinXMins
                                          ,tpslType, tpPoints, slPoints, rrRatio ,atrPeriods,atrMultiplier
                                          ,orderSize, tradeComment ,maxMainBuySignalTradeAllowed,maxMainSellSignalTradeAllowed, padEntryValuePoint
                                          ,isNewsFilterEnabled, minutesBeforeNews,minutesAfterNews, newsImpactToFilter 
                                          ,showSignalArrows  );};
   ~CExpertDonchianCollection(void){};

protected:
            void     Init(int donchianPeriod, ENUM_BLUES_STRATEGY_DIRECTION  tradeEntryStrategy, int noMoreTradeWithinXMins
                            ,ENUM_OFX_TPSL_TYPE tpslType, int tpPoints,int slPoints, double rrRatio ,int atrPeriods,double atrMultiplier
                            ,double orderSize, string tradeComment ,int maxMainBuySignalTradeAllowed	,int maxMainSellSignalTradeAllowed, int padEntryValuePoint
                            ,bool isNewsFilterEnabled ,int minutesBeforeNews,int minutesAfterNews,ENUM_BLUES_NEWS_IMPACT newsImpactToFilter 
                            ,bool showSignalArrows);
            //---initial setup
            void   Setup();
            void   SetExpert(string symbol, int magic, string comment, int i);
            
            void   SetExpertParameters(int donchianPeriod, ENUM_BLUES_STRATEGY_DIRECTION  tradeEntryStrategy, int noMoreTradeWithinXMins
                            ,ENUM_OFX_TPSL_TYPE tpslType, int tpPoints,int slPoints, double rrRatio ,int atrPeriods,double atrMultiplier
                            ,double orderSize, string tradeComment ,int maxMainBuySignalTradeAllowed	,int maxMainSellSignalTradeAllowed, int padEntryValuePoint
                            ,bool isNewsFilterEnabled ,int minutesBeforeNews,int minutesAfterNews,ENUM_BLUES_NEWS_IMPACT newsImpactToFilter 
                            ,bool showSignalArrows);

public:
            //void   OnTick(bool debug=false) { OnTick(false, debug);};
            void   OnTick(bool isSystemComponent = false, bool debug=false);
            void   OnDeinit();
	         void   SetupNewsFilter(bool isNewsFilterEnabled, int impactToFilter, int beforeNewsMinutes, int afterNewsMinutes);                     // passing various settings for CNews and CEvents
            void   SetNewsData(SNewsWrapper &news) {mNewsData = news;};
            void   SetEAChartSymbol(){mEAChartSymbol = Symbol();};
};


void   CExpertDonchianCollection::Init(int donchianPeriod, ENUM_BLUES_STRATEGY_DIRECTION  tradeEntryStrategy, int noMoreTradeWithinXMins
                            ,ENUM_OFX_TPSL_TYPE tpslType, int tpPoints,int slPoints, double rrRatio ,int atrPeriods,double atrMultiplier
                            ,double orderSize, string tradeComment ,int maxMainBuySignalTradeAllowed	,int maxMainSellSignalTradeAllowed, int padEntryValuePoint
                            ,bool isNewsFilterEnabled ,int minutesBeforeNews,int minutesAfterNews,ENUM_BLUES_NEWS_IMPACT newsImpactToFilter 
                            ,bool showSignalArrows){
      
      SetExpertParameters(donchianPeriod, tradeEntryStrategy, noMoreTradeWithinXMins
                           ,tpslType, tpPoints, slPoints, rrRatio ,atrPeriods,atrMultiplier
                           ,orderSize, tradeComment ,maxMainBuySignalTradeAllowed,maxMainSellSignalTradeAllowed, padEntryValuePoint
                           ,isNewsFilterEnabled, minutesBeforeNews,minutesAfterNews, newsImpactToFilter 
                           ,showSignalArrows);
      
      SetEAChartSymbol();
      mFirstTime = true;
      mDebug     = false;   
      #ifdef _DEBUG
      PrintFormat(__FUNCTION__+"Pool in %s",EnumToString(mTimeframe));
      #endif   
}

void   CExpertDonchianCollection::SetExpertParameters(int donchianPeriod, ENUM_BLUES_STRATEGY_DIRECTION  tradeEntryStrategy, int noMoreTradeWithinXMins
                            ,ENUM_OFX_TPSL_TYPE tpslType, int tpPoints,int slPoints, double rrRatio ,int atrPeriods,double atrMultiplier
                            ,double orderSize, string tradeComment ,int maxMainBuySignalTradeAllowed	,int maxMainSellSignalTradeAllowed, int padEntryValuePoint
                            ,bool isNewsFilterEnabled ,int minutesBeforeNews,int minutesAfterNews,ENUM_BLUES_NEWS_IMPACT newsImpactToFilter 
                            ,bool showSignalArrows){

   mParams.DonchianPeriod = donchianPeriod;                     
   mParams.TradeEntryStrategy = tradeEntryStrategy;             
   mParams.NoMoreTradeWithinXMins = noMoreTradeWithinXMins;         

   //--- TPSL parameters
   mParams.TPSLType = tpslType;
   mParams.TPPoints = tpPoints;                       
   mParams.SLPoints = slPoints;                       
   mParams.RRratio  = rrRatio;                       
   mParams.ATRPeriods = atrPeriods;	                    
	mParams.ATRMultiplier = atrMultiplier;	                 

   //	general trading info
	mParams.OrderSize =		orderSize; 
	mParams.TradeComment =		 tradeComment; 
	mParams.MaxMainBuySignalTradeAllowed =	maxMainBuySignalTradeAllowed; 
	mParams.MaxMainSellSignalTradeAllowed	= maxMainSellSignalTradeAllowed; 
   mParams.PadEntryValuePoint = padEntryValuePoint;

   mParams.IsNewsFilterEnabled =   isNewsFilterEnabled;             
   mParams.MinutesBeforeNews  =     minutesBeforeNews;             
   mParams.MinutesAfterNews  =     minutesAfterNews;             
   mParams.NewsImpactToFilter  =   newsImpactToFilter;              

   mParams.ShowSignalArrows  =    showSignalArrows;

}
//---

void  CExpertDonchianCollection::OnTick( bool isSystemComponent, bool debug=false){
   mIsSystemComponent = isSystemComponent;
   
   if(mFirstTime == true){
      Setup();
      mFirstTime = false;
     }
   
   int  count = ArraySize(mPool);
   //if (count == 0) return;             // exit if pool empty
   // -- Update news
   //

   if (!isSystemComponent)
	   mNews.Update();          // update the news module every 4 hours (re-load weekly news from website + pick out the currentDay News)
	else
	   mNewsData.mNews.Update();
	bool isNewsFilterEnabled =  (!isSystemComponent) ? mNews.IsNewsFilterEnabled(): mNewsData.mNews.IsNewsFilterEnabled();

   if(mTimer.IsNewSession(5,MINUTE)){
   for(int i=count - 1;i>=0;i--){
	// validate symbol name every 5 min

         bool is_custom = false;
         if(!SymbolExist(mPool[i].Symbol, is_custom)) PrintFormat("WARNING: %s does not exist!! please add this in terminal's MarketWatch OR double check for typo",mPool[i].Symbol);
      }
   }
   
   //-- execute CExpert OnTick()
	for(int i=count - 1;i>=0;i--){
	   
	   bool isDuringNews = (!isSystemComponent)? mNews.IsDuringNews(mPool[i].Symbol, mNews.ImpactToFilter(), mNews.mEventsOfCurrentDay)
	                                           :mNewsData.mNews.IsDuringNews(mPool[i].Symbol, mNewsData.mNews.ImpactToFilter(), mNewsData.mNews.mEventsOfCurrentDay);
	   // update the news value into each Expert
   	#ifdef _DEBUG 
   	//if(isNewsFilterEnabled && isDuringNews ){
      //
   	//   PrintFormat(__FUNCTION__+"CurrentNewsInEffect: %s, News: %s, Pair: %s, Impact: %s, PreTime: %s, EndTime: %s ", mPool[i].Symbol
   	//                     , mNews.mNewsInEffect.Title
   	//                     , mNews.mNewsInEffect.Currency
   	//                     , mNews.mNewsInEffect.Impact
   	//                     , TimeToString(mNews.mNewsInEffect.DateTime - mNews.BeforeNewsMinutes()*60, TIME_DATE|TIME_MINUTES)
   	//                     , TimeToString(mNews.mNewsInEffect.DateTime + mNews.AfterNewsMinutes()*60, TIME_DATE|TIME_MINUTES)
   	//                     );
   	//   
   	//}
   	#endif

      
      mPool[i].DonchianEA.SetNewsFilterValue	(isNewsFilterEnabled, isDuringNews );           //pass down the newsFiler curretn value to CExpert layer
      mPool[i].DonchianEA.OnTick();
   }
}

//---

void   CExpertDonchianCollection::Setup(){
   //creat timer
   mTimer = new CTimer();
   
   // take in poolInput strings and process it into the mPool
   mPoolInput = new CStrategyInput(mSymbolStringList, mSuffix, mMagicStringList);
   mPoolInput.GetSymbolMagicStruct(mPool);
   
   int   count = ArraySize(mPool);
   if (count == 0) return;             // exit if pool empty
   
   //--- loop thru mPool and instanstiate new CDonchianExpert object for each symbol
   for(int i=count - 1;i>=0;i--){
      SetExpert(mPool[i].Symbol, mPool[i].Magic, mParams.TradeComment, i);

   }
   // load news once if not a component of a bigger system
   if(!mIsSystemComponent)
         SetupNewsFilter(mParams.IsNewsFilterEnabled, mParams.NewsImpactToFilter, mParams.MinutesBeforeNews, mParams.MinutesAfterNews ); //enable NewsFilter setting

   //SetupNewsFilter(mParams.IsNewsFilterEnabled, mParams.NewsImpactToFilter, mParams.MinutesBeforeNews, mParams.MinutesAfterNews); //enable NewsFilter setting

}


void   CExpertDonchianCollection::SetExpert(string symbol, int magic, string comment, int i){
    
   mPool[i].DonchianEA	=	new CExpertDonchian(	mParams.DonchianPeriod, symbol, mParams.OrderSize, comment, magic);
   //--SetTimeframe value for CExpertDoncian
   mPool[i].DonchianEA.SetTimeframe(mTimeframe);            //<-- pass mTimeframe value to CExpertDonchian which will then in-turn pass to Donchian Indicator
   
	mPool[i].DonchianEA.SetTradingStrategy(mParams.TradeEntryStrategy, mParams.MaxMainBuySignalTradeAllowed,mParams.MaxMainSellSignalTradeAllowed, mParams.PadEntryValuePoint);
	mPool[i].DonchianEA.SetTPSLparameters(mParams.TPSLType,mParams.TPPoints,mParams.SLPoints,mParams.RRratio,mParams.ATRMultiplier, mParams.ATRPeriods);   //Set TPSL parameters
	mPool[i].DonchianEA.SetTradePacingparameters(mParams.NoMoreTradeWithinXMins);   //Set TPSL parameters
	mPool[i].DonchianEA.SetTradeSignalVisualparameters(mParams.ShowSignalArrows);
	//---initial setup for sub-modules
   mPool[i].DonchianEA.SetupTradeEntryStrategy(symbol);                                   //enable choosing between BreakOut | Reversal entry
   mPool[i].DonchianEA.mBufferBuy.SetChartIDofEA(GetChartID(mEAChartSymbol) );           // pass down the ChartID of EA to BufferBuy/Sell to draw arrow
   mPool[i].DonchianEA.mBufferSell.SetChartIDofEA(GetChartID(mEAChartSymbol));
}
      

	
void   CExpertDonchianCollection::OnDeinit(){
   int   count = ArraySize(mPool);
   if (count == 0) return;             // exit if pool empty
   //--- loop thru mPool and delete all CExpert instance
   for(int i=count - 1;i>=0;i--){
      delete mPool[i].DonchianEA;
   }
}


void CExpertDonchianCollection::SetupNewsFilter(bool isNewsFilterEnabled, int impactToFilter, int beforeNewsMinutes, int afterNewsMinutes){
      //Set up News Filter once when first loaded
      mNews = new CNews("calendar.csv","HistoryNewsEvents_2020.csv");
      
      if(IS_DEBUG_MODE || IsTesting() ) {
         mNews.LoadHistoryNewsFromFile(mNews.HistoryNewsFileName());      //load history newsEvent    **warning this may take sometimes to load in tester - best to only load one year of past news
         //mNews.FilterG8CurrenciesNews();                                  // filter only those news of G8 currency

      }
      else {
      Print ("downloading News from FF Calendar");
      mNews.LoadNewsFromDownloadResponse();
      
      // go thru and print out all the news to check
      //
      int countevent = ArraySize(mNews.mEvents);
      if(countevent > 0){
      for(int i=countevent-1;i>=0;i--){
         PrintFormat(__FUNCTION__+"i:%d, News: %s, Pair: %s, Impact: %s, PreTime: %s, EndTime: %s ", i
      	                     , mNews.mEvents[i].Title
      	                     , mNews.mEvents[i].Currency
      	                     , mNews.mEvents[i].Impact
      	                     , TimeToString(mNews.mEvents[i].DateTime - mNews.BeforeNewsMinutes()*60, TIME_DATE|TIME_MINUTES)
      	                     , TimeToString(mNews.mEvents[i].DateTime + mNews.AfterNewsMinutes()*60, TIME_DATE|TIME_MINUTES)
      	                     );
              }
           }
      }

      mNews.SetNewsFilterParameters(isNewsFilterEnabled, impactToFilter, beforeNewsMinutes, afterNewsMinutes);
}
//---
