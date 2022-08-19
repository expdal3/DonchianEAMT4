/*

	Donchian v1
	Expert
	
	Copyright 2022, Orchard Forex
	https://www.orchardforex.com

*/

/** Disclaimer and Licence

 *	This file is free software: you can redistribute it and/or modify
 *	it under the terms of the GNU General Public License as published by
 *	the Free Software Foundation, either version 3 of the License, or
 *	(at your option) any later version.

 *	This program is distributed in the hope that it will be useful,
 *	but WITHOUT ANY WARRANTY; without even the implied warranty of
 *	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *	GNU General Public License for more details.
 
 *	You should have received a copy of the GNU General Public License
 *	along with this program.  If not, see <http://www.gnu.org/licenses/>.

 *	All trading involves risk. You should have received the risk warnings
 *	and terms of use in the README.MD file distributed with this software.
 *	See the README.MD file for more information and before using this software.

 **/

/*
 *	Strategy
 *
 *	Buy when:
 *		Candle crosses into Kumo cloud from below and closes above Leading Span A
 *	Sell when:
 *		Candle crosses into Kumo cloud from above and closes below Leading Span A
 *	Close when:
 *		Price touches Leading Span B
 *	Stop Loss:
 *		1:1 from the initial take profit or
 *		1:1 floating from the current take profit
 *
 *	This will use Take Profit and Stop Loss levels, not monitor the trade for a close
 *
 */
#include <Blues/StrategyInputClass/StrategyInputClass.mqh>
#include <Blues/TradeInfoClass/TradeInfoClass.mqh>
#include <Blues/UtilityFunction/UtilityFunctions.mqh>
#include <Blues/Signal/BufferSignal.mqh>
#include <Blues/NewsFilter/News.mqh>
#include "Framework.mqh"
#include "IndicatorDonchian.mqh"


struct SNewsFilterStatus{                     //struct to hold NewsFilter value passed down from CExpertCollection
    bool  IsNewsFilterEnabled;
    bool  IsDuringNews;
};

class CExpertDonchian : public CExpertBase {

private:
   MqlTradeRequest	mRequestBuy;
   MqlTradeRequest	mRequestSell;
protected:

	int		mHandle;
	int      mDonchianPeriod;
	double   mPriceDeviationPoint;           //price have to cross this point to enter trade
	int      mBandExtremumPeriod;            //Number of bar looks back to calculate BandExtremum
	CIndicatorChannelDonchian * mDonchianIndicator;
	int      mIsFirstTime;
	CTPSLCommon	   *mTPSL;
   CIndicatorATR	*IndicatorATR;       // And for the TPSL
   CTimer               *mTimer;
	int      mRetry;
	void		Loop();
	void		UpdateTPSL();              //double tp, double sl
	double   BandsExtremum(int bufferNumber, int index);
   double   BandsHigh(int lookBackBars);
   double   BandsLow(int lookBackBars);
   SCount   mMaxTrade;
   
   
   // Trade Pacing functionality
   //
	CEvent               *mRecentBuyTradeEvent;                //add CEvent to track existing trade event          
	CEvent               *mRecentSellTradeEvent;                //add CEvent to track existing trade event  	
	bool                 mIsInRecentTradeRange;            // check if within recent trade time restriction
	 
   bool  mIsShowTradeSignalOnChart;
   
   // TradeEntry Strategy
   ENUM_BLUES_STRATEGY_DIRECTION mTradeEntryStrategy;
   
   // News Filter module
   //CNews * mNews;
   SNewsFilterStatus mNews;
public:
   	// Signal Buffer tracking
   CBufferSignal  *mBufferBuy;   //hold buy signals and can be used to draw arrow
   CBufferSignal  *mBufferSell;  //hold sell signals and can be used to draw down arrow  
public:

	CExpertDonchian(	int donchianPeriod, string symbol, double orderSize, string tradeComment, long magic);
	~CExpertDonchian();
   void     SetTradingStrategy (ENUM_BLUES_STRATEGY_DIRECTION tradeEntryStrategy, int maxBuy, int maxSell){

               mTradeEntryStrategy = tradeEntryStrategy;
               
               mMaxTrade.Buy = (tradeEntryStrategy == _Both_) ?maxBuy*2:maxBuy;        //x2 if entry for both direction on Signal
               mMaxTrade.Sell = (tradeEntryStrategy == _Both_) ?maxSell*2:maxSell;
               };

   void     SetTradePacingparameters(int durationMinutes, int timeLimitMinutes=1440){
                     mRecentBuyTradeEvent = new CEvent(Trade_Open, durationMinutes, timeLimitMinutes);   
                     mRecentSellTradeEvent = new CEvent(Trade_Open, durationMinutes, timeLimitMinutes); 
                     };
   void     SetTradeSignalVisualparameters(bool isShowTradeSignalOnChart){
                  mIsShowTradeSignalOnChart = isShowTradeSignalOnChart;
            };                     
	
	void     Setup();
	void     SetupTradeEntryStrategy(string chartSymbol="");             //enable switching between breakout & reversal
	//void     SetupNewsFilter(bool isNewsFilterEnabled, int impactToFilter, int beforeNewsMinutes, int afterNewsMinutes);                     // passing various settings for CNews and CEvents
   void     SetNewsFilterValue(bool isNewsFilterEnabled, bool isDuringNews){
                     mNews.IsNewsFilterEnabled = isNewsFilterEnabled;
                     mNews.IsDuringNews = isDuringNews;
                     };
   //void     SetBandExtremumPeriod(int bars){mBandExtremumPeriod = bars;};

};


CExpertDonchian::CExpertDonchian(	int donchianPeriod, string symbol, double orderSize, string tradeComment, long magic)
						:	CExpertBase(symbol, orderSize, tradeComment, magic) {
   
   mDonchianPeriod = donchianPeriod;
   mBandExtremumPeriod = donchianPeriod;            //<-- look back 5 bars to determine extremum
   mRetry = 2;
	
	//#ifdef __MQL5__
	//	mHandle			=	iIchimoku(mSymbol, mTimeframe, 9, 26, 52);
	//	if (mHandle==INVALID_HANDLE) {
	//		mInitResult		=	INIT_FAILED;
	//		return;
	//	}
	//#endif
	MqlTradeRequest	mRequestBuy = {};	//	Just initialising
	MqlTradeRequest	mRequestSell = {};	//	Just initialising
	mIsFirstTime = true;
	mInitResult		=	INIT_SUCCEEDED;
	
}

CExpertDonchian::~CExpertDonchian() {

	//#ifdef __MQL5__
	//	IndicatorRelease(mHandle);
	//#endif 
	delete mTimer;
	delete mDonchianIndicator;
}

void		CExpertDonchian::Loop() {


   // load the indicator object
   //
   //PrintFormat(__FUNCTION__+" mIsFirstTime: %s", (string) mIsFirstTime);
   if(mIsFirstTime == true)         // run first time setup
     {
      Setup();
      mTimer = new CTimer();           
      mIsFirstTime = false;
     }
	if (!mTimer.IsNewSession(5, MINUTE))  return;	// No need to check price at each tick because     if (!mTimer.IsNewSession(10))  if (!mTimer.IsNewSession(5,MINUTE)) 
									//	There is a tp and sl to take care of that  
   
   
   if(mTimer.IsNewBar(mSymbol,mTimeframe)) {
      mDonchianIndicator.Update();     //load the current chart's bars and get latest Donchian's values
   	mBufferBuy.UpdateBuffer(mBufferBuy.mSignals);
   	mBufferSell.UpdateBuffer(mBufferSell.mSignals);
   	

   }
	//	Load indicator values MQL4 & MQL5 (same process)
   
	double	highChannel1	=	mDonchianIndicator.GetData(HIGH_CHANNEL,2);
	double	highChannel2	=	mDonchianIndicator.GetData(HIGH_CHANNEL,3);
   double   highChannel =  BandsHigh(5);
   
	double	lowChannel1	=	mDonchianIndicator.GetData(LOW_CHANNEL,2);
	double	lowChannel2	=	mDonchianIndicator.GetData(LOW_CHANNEL,3);	
   double   lowChannel =   BandsLow(5);
   //#ifdef _DEBUG
   //   PrintFormat(__FUNCTION__"highChannel1: %.4f, highChannel2: %.4f, lowChannel1: %.4f,lowChannel2: %.4f", highChannel1, highChannel2, lowChannel1, lowChannel2);
   //#endif
	
	//	Closing prices
	double	close1	=	iClose(mSymbol, mTimeframe, 1);
	double	close2	=	iClose(mSymbol, mTimeframe, 2);

   // GetSignal
   //
   
   ENUM_OFX_SIGNAL_DIRECTION	entrySignal;
	
	if (close2<highChannel && close1>=highChannel) entrySignal = OFX_SIGNAL_BUY; 
   if (close2>lowChannel && close1<=lowChannel)  entrySignal = OFX_SIGNAL_SELL;
	
	Recount();
	if (mCount.All>0) {
	   //GetMarketPrices(ORDER_TYPE_BUY, mRequest);
		if (mTimer.IsNewSession(5,MINUTE)) UpdateTPSL();
	//	Recount();
	}
	
	//if (mCount>0) return;	// Test again in case of close above

   //Trade-Pacing
   //
   bool isInRecentBuyTradeRange = mRecentBuyTradeEvent.IsInRange();
   bool isInRecentSellTradeRange = mRecentSellTradeEvent.IsInRange();

   bool tradeResult;
	
	if (entrySignal == OFX_SIGNAL_BUY && mCount.Buy< mMaxTrade.Buy 
	   && !isInRecentBuyTradeRange                                    // if not within a recent BuyTrade
	   && ( 
	         (mNews.IsNewsFilterEnabled && !mNews.IsDuringNews) 
	         || !mNews.IsNewsFilterEnabled 
	       )     // not during a high impact news or if newsFilter disabled
	   ){
   	   #ifdef _DEBUG
         PrintFormat(__FUNCTION__"highChannel1: %.5f, highChannel2: %.5f", highChannel1, highChannel2);
         PrintFormat(__FUNCTION__"close1: %.5f, close2: %.5f --> close2<highChannel2: %s close1>=highChannel1: %s", close1, close2, (string) (close2<highChannel2), (string) (close1>=highChannel1) );
          #endif
          
         #define Buy RBuy             //place BUY trade with retry
         #define Sell RSell           //place SELL trade with retry
   	   mBufferBuy.SetSignalPriceAndTime(mRequestBuy.price,TimeCurrent(),0); //record the signal to bufferBuy
         //   Checking Trade entry strategy
         if(mTradeEntryStrategy == _Break_out_ || mTradeEntryStrategy == _Both_){
	          GetMarketPrices(ORDER_TYPE_BUY, mRequestBuy);                        //gather trade levels & tpsl
             tradeResult = Trade.Buy(mOrderSize, mSymbol, mRequestBuy.price, mRequestBuy.sl, mRequestBuy.tp, mTradeComment,2);
	          }
         if(mTradeEntryStrategy == _Reversal_  || mTradeEntryStrategy == _Both_ ){
	          GetMarketPrices(ORDER_TYPE_SELL, mRequestBuy);                        //gather trade levels & tpsl
             tradeResult = Trade.Sell(mOrderSize, mSymbol, mRequestBuy.price, mRequestBuy.sl, mRequestBuy.tp, mTradeComment,2); 
            }
        
         #undef Buy
         #undef Sell 

		//while(retry++ <=2 && !tradeResult)
      //{
         //PrintFormat("OrderSend error %d",GetLastError());
         //PrintFormat("price: %.5f, sl: %.5f, tp: %.5f",mLastTick.ask, mRequest.sl, mRequest.tp);
      //   if(Trade.Buy(mOrderSize, mSymbol, mRequest.price, 0, 0, mTradeComment)) break;
      //}
      if(tradeResult)  mRecentBuyTradeEvent.AddTimeRange(TimeCurrentToStruct());            //record the current time and add it to tracking
	   #undef Buy
	} else
	if (entrySignal == OFX_SIGNAL_SELL && mCount.Sell< mMaxTrade.Sell
		 && !isInRecentSellTradeRange                                    // if not within a recent SellTrade
	    && ( 
	         (mNews.IsNewsFilterEnabled && !mNews.IsDuringNews) 
	         || !mNews.IsNewsFilterEnabled 
	       )     // not during a high impact news or if newsFilter disabled
	   ) {
   	   #ifdef _DEBUG
         PrintFormat(__FUNCTION__"lowChannel1: %.5f,lowChannel2: %.5f", lowChannel1, lowChannel2);
         PrintFormat(__FUNCTION__"close1: %.5f, close2: %.5f --> close2>lowChannel2: %s close1<=lowChannel1: %s", close1, close2, (string) (close2>lowChannel2), (string) (close1<=lowChannel1) );
         #endif

         #define Sell RSell         //place SELL trade with retry
         #define Buy RBuy           //place BUY trade with retry
   		GetMarketPrices(ORDER_TYPE_SELL, mRequestSell);
   	   mBufferSell.SetSignalPriceAndTime(mRequestSell.price,TimeCurrent(),0);
         
         //   Checking Trade entry strategy
         if(mTradeEntryStrategy == _Break_out_ || mTradeEntryStrategy == _Both_){
	          GetMarketPrices(ORDER_TYPE_SELL, mRequestSell);                        //gather trade levels & tpsl
             tradeResult = Trade.Sell(mOrderSize, mSymbol, mRequestSell.price, mRequestSell.sl, mRequestSell.tp, mTradeComment,2);
         }
         if(mTradeEntryStrategy == _Reversal_  || mTradeEntryStrategy == _Both_ ){
	          GetMarketPrices(ORDER_TYPE_BUY, mRequestSell);                        //gather trade levels & tpsl
             tradeResult = Trade.Buy(mOrderSize, mSymbol, mRequestSell.price, mRequestSell.sl, mRequestSell.tp, mTradeComment,2);         
         }
         #undef Buy
         #undef Sell 

      if(tradeResult) mRecentSellTradeEvent.AddTimeRange(TimeCurrentToStruct());            //record the current time and add it to tracking
	   #undef  Sell
	}

   mRecentBuyTradeEvent.OnTick();      mRecentSellTradeEvent.OnTick();  //update RecentTrade events tracker   
	
	return;	
	
}

void		CExpertDonchian::UpdateTPSL( ) {
   double tp, sl;
   
   if(mTPSLparams.Type == Fixed_TPSL){
      sl = mTPSLparams.StopLossValue;
      tp = mTPSLparams.TakeProfitValue;
      
   } else {
	sl = (mStopLossObj==NULL) ? mTPSLparams.StopLossValue : mStopLossObj.GetStopLoss();
   tp = (mTakeProfitObj==NULL) ? mTPSLparams.TakeProfitValue : mTakeProfitObj.GetTakeProfit();
   }
   


	for (int i=PositionInfo.Total()-1; i>=0; i--) {
		
		if (!PositionInfo.SelectByIndex(i)) continue;
		if (PositionInfo.Symbol()!=mSymbol || PositionInfo.Magic()!=mMagic || PositionInfo.Comment()!=mTradeComment ) continue;
      
      

      
      /*
      //Close trade where price hit sl or profit (this is for hidden sl or tk)
		//
		sl	=	(PositionInfo.PriceOpen()*2.0)-tp;

       
		//	Handle conditions where the tp/sl has moved past current price
		if (PositionInfo.PositionType()==POSITION_TYPE_BUY) {
			if (mLastTick.bid>=tp || mLastTick.bid<=sl) {
				Trade.PositionClose(PositionInfo.Ticket());
				continue;
			} 
		} else
		if (PositionInfo.PositionType()==POSITION_TYPE_SELL) {
			if (mLastTick.ask<=tp || mLastTick.ask>=sl) {
				Trade.PositionClose(PositionInfo.Ticket());
				continue;
			} 
		}
		*/
		//int      posTicket = PositionInfo.Ticket();
		//string  posTypeName = OrderTypeName(PositionInfo.PositionType());
		int   posType = PositionInfo.PositionType();
		double posTP = PositionInfo.TakeProfit();
		double posSL = PositionInfo.StopLoss();
		int    posSymbolDigit = SymbolInfoInteger(PositionInfo.Symbol(),SYMBOL_DIGITS );
		double newTP =  (posType==ORDER_TYPE_BUY ) ? NormalizeDouble(PositionInfo.PriceOpen()+tp, posSymbolDigit): NormalizeDouble(PositionInfo.PriceOpen()-tp,posSymbolDigit);
		double newSL =  (posType==ORDER_TYPE_BUY ) ? NormalizeDouble(PositionInfo.PriceOpen()-sl,posSymbolDigit): NormalizeDouble(PositionInfo.PriceOpen()+sl,posSymbolDigit);
		
		if (posType==ORDER_TYPE_BUY ){
		  if ((posTP!=newTP || posSL!=newSL)
		      && newTP !=0 && newSL != 0
		      ) Trade.PositionModify(PositionInfo.Ticket(), newSL, newTP);
		}
		if (posType==ORDER_TYPE_SELL ){
		  if ((posTP!=newTP || posSL!=newSL)
		      && newTP !=0 && newSL != 0
		      ) Trade.PositionModify(PositionInfo.Ticket(), newSL, newTP);
		
		}
		
	}

}
//+------------------------------------------------------------------+
//|   Setup functions                                                |
//+------------------------------------------------------------------+


void CExpertDonchian::Setup(){

      mDonchianIndicator = new CIndicatorChannelDonchian(mSymbol, mTimeframe, mDonchianPeriod);
      //setup TPSL
      
      mTPSL				=	new CTPSLCommon();
      mTPSLparams.IndicatorATR = new CIndicatorATR(mTPSLparams.ATRMultiply);
   	//
   	//	No Need to Set up for Simple Fixed TPSL as this has been handled in CExpertBase::SetTPSLParameters
   	//
   	//	Set up the ATR TPSL
   	//
   	
   	mTPSL.AddIndicator(mTPSLparams.IndicatorATR               //CIndicatorBase *indicator object
   	                  , 0);                      //bufferNum = 0
   	mTPSL.SetIndex(1);                            //Look at bar number 1
   	mTPSL.SetMultiplier(mTPSLparams.ATRMultiply);
   	
   	SetTakeProfitObj(mTPSL);               //Add the TP object to Expert obj
	   SetStopLossObj(mTPSL);                 //Add the SL object to Expert obj
      

}


void CExpertDonchian::SetupTradeEntryStrategy(string chartSymbol=""){
      
      //set up Trade Entry Strategy
      mBufferBuy = new CBufferSignal("DonchianBufferBuy_"+chartSymbol,clrDarkTurquoise,UP_ARROW);
      mBufferSell = new CBufferSignal("DonchianBufferSell_"+chartSymbol,clrDeepPink,DOWN_ARROW);
      mBufferBuy.Setup(mIsShowTradeSignalOnChart);
      mBufferSell.Setup(mIsShowTradeSignalOnChart);
      
      mBufferBuy.GetChartIDFromChartSymbol(chartSymbol);      //find chartID if not yet
      mBufferSell.GetChartIDFromChartSymbol(chartSymbol);

}


//---


double CExpertDonchian::BandsHigh(int lookBackBars) {
   double arr[];
   ArrayResize(arr, lookBackBars);
   for(int i=0;i<=lookBackBars-1;i++)
     {
      arr[i] = BandsExtremum( HIGH_CHANNEL, i  ); 
     }
   return ( arr[ArrayMinimum(arr)] ); //mBandExtremumPeriod - 1
}

double CExpertDonchian::BandsLow(int lookBackBars) {
   
   double arr[];
   ArrayResize(arr, lookBackBars);
   for(int i=0;i<=lookBackBars-1;i++)
     {
      arr[i] = BandsExtremum( LOW_CHANNEL, i  ); 
     }
   return ( arr[ArrayMaximum(arr)] );
}


double CExpertDonchian::BandsExtremum( int bufferNumber, int index ) {

   //	Beware in case there are simply not enough bars to generate a result
   //	That would be very unusual unless you set an extremely long
   //	period so I haven't bothered to deal with it here

   double buf[];

//#ifdef __MQL5__
//   CopyBuffer( mHandle, bufferNumber, 1, mSqueezePeriod, buf );
//#endif

//#ifdef __MQL4__
   ArrayResize( buf, mBandExtremumPeriod );
   ArraySetAsSeries(buf,true);
   for(int i=0;i<=mBandExtremumPeriod-1;i++)
     {
      buf[i]	=	mDonchianIndicator.GetData(bufferNumber,i);
      //PrintFormat(__FUNCTION__+"buf[%d]: %.5f", i, buf[i]);
     }
   	
//   for ( int i = 1; i <= mSqueezePeriod; i++ )
//   {
//      buf[i - 1] = iBands( mSymbol, ( int )mTimeframe, mBandsPeriod, mBandsDeviation, 0,
//                           mBandsAppliedPrice, bufferNumber, i );
//   }
//#endif

   //ArraySort( buf ); <-- no need to sort, should use Min and Max
   
   return ( buf[index] );
}