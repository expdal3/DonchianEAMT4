/*

	Donchian BlueSwift.mqh
	Copyright 2022, BluesAlgo
	https://www.mql5.com

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

#property strict

#include "../Framework.mqh"

#ifndef DONCHIAN_VERSION
   #define DONCHIAN_VERSION
   #define DONCHIAN_VERSION_CURRENT
#endif

#ifdef DONCHIAN_VERSION_CURRENT

#ifdef __MQL4__
//#include "include_mql4/include.mqh"
#define extern extern
#endif


#ifdef __MQL5__
//#include "include_mql5/include.mqh"
#define extern input
#endif

//
//	Inputs
//

sinput string   __GeneralSetting__   = "__GENERAL EXPERT SETTINGS___";
//	inputs for this Donchian expert
extern   string   InpSymbols                      = "";        // Symbols to trade (separated by comma ,)
extern   string   InpSymbolSuffix                 = "";        // Broker's symbol suffix
extern   ENUM_BLUES_STRATEGY_DIRECTION      InpTradeEntryStrategy = _Break_out_; //Trade Entry strategy
extern   string   InpMultiTimeframeStrategyString = "";        // [*]Setup Expert on multiple timeframe
sinput   string   __GeneralSetting__Warning1      = "[*] example syntax: \'M15:BreakOut,M30:Reversal\'";
sinput   string   __GeneralSetting__Warning2      = "  pls test this in Tester/Demo account first as it";           
sinput   string   __GeneralSetting__Warning3      = "  this may lead to large number of trader order being opened";

extern   int      InpDonchianPeriod               = 20;        //	Bands period
extern   int      InpNoMoreTradeWithinXMins       = 240;        // No new trade within X mins from last trade

sinput   string   __SectionSep__1            = "======================================";
sinput string   __ChooseTakeProfitAndStopLoss__Type   = "__TAKE-PROFIT AND STOP-LOSS SETTING___";

input ENUM_OFX_TPSL_TYPE   InpTPSLType          =  Fixed_TPSL; //Choose TakeProfit and StopLoss type
//
// For simple point based TPSL
extern int            InpTPPoints                = 250;        //TakeProfit (Points)
extern int            InpSLPoints                = 2000;       //StopLoss (Points)
extern double         InpRRratio                 = 2.5;        //R:R Ratio

//
//	For ATR based TPSL
//
extern	int				InpATRPeriods					=	14;	//	ATR Periods
extern	double			InpATRMultiplier				=	3.0;	//	ATR Multiplier

//	Now some general trading info
extern	double	InpOrderSize			            =	0.01;		   //	Fixed starting order size
extern	string	InpTradeComment		            =	"Donchian";	//	Trade comment
extern	string	InpMagic					            =	"222222";				//	Magic number
extern	int	   InpMaxMainBuySignalTradeAllowed	=	3;				//	Max BUY trade from main Donchian signal
extern	int	   InpMaxMainSellSignalTradeAllowed	=	3;				//	Max SELL trade from main Donchian signal
extern	int	   InpPadEntryValuePoint	         =	0;				//	Points away from (-)/ closer to (+) signal entry

sinput string   __ChooseNewsFilterSettings   = "__NEWS FILTER SETTINGS__";
extern   bool     InpIsNewsFilterEnabled       = true;             // Enable News Filter?
extern   int      InpMinutesBeforeNews         = 60   ;             // minutes before news
extern   int      InpMinutesAfterNews         = 60   ;              // minutes after news
extern   ENUM_BLUES_NEWS_IMPACT      InpNewsImpactToFilter        = _HighImpact_;   //News Impact to filter

sinput string   __ChooseSignalVisual   = "__SIGNAL INDICATOR ON-CHART SETTINGS__";

extern   bool     InpShowSignalArrows              = false;       // Show Trade Signal on-chart?

#define  GRIDTRADECLASS_VERSION_2_0                      //define the version of GridTradeFunction
#include <Blues/GridTradeFunction/include.mqh>
string   __Grid__Trading   = "_____________________________";
extern	bool		InpIsGridTradingAllowed					=	true;				//	Enable GridTrading?

extern   string            InpTradingAllowedTimeRange   =  "04:30-12:35,18:00-22:59";           //Trading-allowed time, Mon-Thu
extern   string            InpTradingAllowedTimeRangeFriday   =  "04:30-12:30";     //Trading-allowed time Friday
//		and lot sizes
extern   int		         InpLevelPoints			    =	225;						//	Trade gap in points
extern   int               InpFirstRealGridLevel    =  3;         //First GridLevel to trade (Skip lower levels) [FirstLevel=0]
extern   int               InpLevelToStartAveraging =  3;               //LevelToStart Averaging [FirstLevel=0]
extern int                 InpGridLevelRescue       = 3;                 // GridLevel to start recovery mode [FirstLevel=0]
extern ENUM_BLUES_TRADE_MODES    InpTradeMode            = Buy_and_Sell;   // TradeMode  
extern double              InpMinProfit            = 5.00;           // Grid ($) TakeProfit 
extern double              InpMinProfitRescue      = 2;           // Grid ($) TakeProfit during recovery mode

extern double              InpMaxLoss              = -10000.00;           // Grid ($) StopLoss

//	Now some general trading info
//extern   double	         InpOrderSize			   =	0.01;					//	Order size
extern   double            InpFactor               =  2;               //LotSize Multiplier

extern   ENUM_BLUES_GRID_TRAILORDERSIZE_OPT               InpTrailOrderSizeOption =  _multiply_factor_;               //Next OrderSize Calc approach

extern	string	         InpGridEATradeComment	=	"Donchian_Grids";	//	Trade comment
//extern	string		      InpGridEAMagics			=	"1234";				//	Magic number
extern	bool		         InpGridEADebug			   =	false;				//	EA Debug Mode

#define  GRIDRESCUECLASS_VERSION_2_0               // select the GridRescueClass's version'
#include <Blues/GridRescueFunction/include.mqh>

#include "../ExpertCollection.mqh"
#include "../ExpertSystem.mqh"
#define CExpertSystem     CExpertDonchianSystem 
#define CExpertCollection CExpertDonchianCollection
#define CGridRescueCollection CGridCollection

CExpertSystem*          DonchianSystem;            // module to control a 'System' of DonchianExperts
CExpertCollection*	   DonchianExpert;            // module to place signal order base on Donchian channel trade logic

CExpertGridCollection*	GridExpert;                // module to place subsequent grid order base on signal order - if Grid Trading is enabled
CGridRescueCollection   *     BuyGridRescueCollection;          // module to rescue drawdown for a Grid (include both signal order and child grid orders)    
CGridRescueCollection   *     SellGridRescueCollection;          // module to rescue drawdown for a Grid (include both signal order and child grid orders) 

CStrategyInput*         Strategies;    

//+------------------------------------------------------------------+
//| struct to implement multiTimeframe strategy                      |
//+------------------------------------------------------------------+


int OnInit() {
   Print("EA version: ",MVersion);
   string inpSymbols = (InpSymbols=="")? Symbol(): InpSymbols;     //use Chart's symbol or ListOfSymbols
   int inpLevelToStartAveraging = InpLevelToStartAveraging-1;
	string inpGridMagicNumber = InpMagic+"00";
	string inpTradeComment = InpTradeComment;
	
	//ENUM_TIMEFRAMES inpTimeframe = (InpMultiTimeframeStrategyString == "")? Period(): PERIOD_D1; 

   if(InpMultiTimeframeStrategyString!=""){
	//--- setup multi timeframe
	// Initialize system      
   DonchianSystem = new CExpertSystem(InpMultiTimeframeStrategyString);
	DonchianSystem.SetCommonParameters(inpSymbols,InpSymbolSuffix,InpMagic                                                  //, PERIOD_M15
	                                       ,InpDonchianPeriod                                                            //, InpTradeEntryStrategy
	                                       ,InpNoMoreTradeWithinXMins
	                                       ,InpTPSLType,InpTPPoints,InpSLPoints,InpRRratio,InpATRMultiplier, InpATRPeriods              //Set TPSL parameters
	                                       ,InpTradeComment,InpMaxMainBuySignalTradeAllowed,InpMaxMainSellSignalTradeAllowed, InpPadEntryValuePoint       //InpOrderSize
	                                       ,InpIsNewsFilterEnabled, InpMinutesBeforeNews, InpMinutesAfterNews, InpNewsImpactToFilter
	                                       ,InpShowSignalArrows);
   } else {
   //--- setup the current chart timeframe
   
   #ifdef __MQL5__
      ENUM_TIMEFRAMES _period = Period();
   #endif 
   
   #ifdef __MQL4__
      ENUM_TIMEFRAMES _period = (ENUM_TIMEFRAMES) Period();
   #endif 
	DonchianExpert	=	new CExpertCollection(inpSymbols,InpSymbolSuffix,InpMagic, _period
	                                       ,InpDonchianPeriod, InpTradeEntryStrategy, InpNoMoreTradeWithinXMins
	                                       ,InpTPSLType,InpTPPoints,InpSLPoints,InpRRratio,InpATRMultiplier, InpATRPeriods              //Set TPSL parameters
	                                       ,InpOrderSize, InpTradeComment,InpMaxMainBuySignalTradeAllowed,InpMaxMainSellSignalTradeAllowed, InpPadEntryValuePoint
	                                       ,InpIsNewsFilterEnabled, InpMinutesBeforeNews, InpMinutesAfterNews, InpNewsImpactToFilter
	                                       ,InpShowSignalArrows
	                                       );
	

   }
   // instantiate and setup GridTrading Expert
	GridExpert = new CExpertGridCollection(inpSymbols, InpSymbolSuffix, InpMagic
                                            ,InpTradingAllowedTimeRange, InpTradingAllowedTimeRangeFriday, InpTrailOrderSizeOption, InpFactor,InpMinProfit, InpMinProfitRescue, InpGridLevelRescue
                                            , InpMaxLoss, InpLevelPoints, inpLevelToStartAveraging, InpFirstRealGridLevel, InpOrderSize, InpGridEATradeComment, InpTradeMode, true, InpGridEADebug);

	// instantiate and setup GridRescue Expert
	//
   // manage all BUY grids
   BuyGridRescueCollection = new CGridRescueCollection(inpSymbols,InpSymbolSuffix,inpGridMagicNumber,OP_BUY,InpLevelToStartRescue,InpRescueScheme, InpSubGridProfitToClose,InpIterationModeAndProfitToCloseStr,InpTradeComment, InpRescueAllowed
                                          ,InpPanicCloseOrderCount,InpPanicCloseMaxDrawdown,InpPanicCloseMaxLotSize,InpPanicCloseProfitToClose,InpPanicClosePosOfSecondOrder,InpStopPanicAfterNClose
                                          ,InpPanicCloseIsDriftProfitAfterEachIteration,InpPanicCloseDriftProfitStep,InpPanicCloseDriftLimit, InpPanicCloseBottomOrderIfBetter, InpPanicCloseAllowed
                                          ,InpCritCloseIfPanicOf,InpCritCloseTimeRange,InpCritCloseMaxOpenMinute,InpCritProfitToCloseTopOrder,InpCritForceCloseAtEndTime,InpCritForceCloseIgnoreMaxDuration,InpCritCloseAllowed
                                          ,true //isonechart
                                          );
   // manage all SELL grids
   SellGridRescueCollection = new CGridRescueCollection(inpSymbols,InpSymbolSuffix,inpGridMagicNumber,OP_SELL,InpLevelToStartRescue,InpRescueScheme, InpSubGridProfitToClose,InpIterationModeAndProfitToCloseStr,InpTradeComment, InpRescueAllowed
                                          ,InpPanicCloseOrderCount,InpPanicCloseMaxDrawdown,InpPanicCloseMaxLotSize,InpPanicCloseProfitToClose,InpPanicClosePosOfSecondOrder,InpStopPanicAfterNClose
                                          ,InpPanicCloseIsDriftProfitAfterEachIteration,InpPanicCloseDriftProfitStep,InpPanicCloseDriftLimit, InpPanicCloseBottomOrderIfBetter, InpPanicCloseAllowed
                                          ,InpCritCloseIfPanicOf,InpCritCloseTimeRange,InpCritCloseMaxOpenMinute,InpCritProfitToCloseTopOrder,InpCritForceCloseAtEndTime,InpCritForceCloseIgnoreMaxDuration,InpCritCloseAllowed
                                          ,true
                                          );
   BuyGridRescueCollection.OnInit(DIRECTION_BUY,InpTradeComment, InpShowRescuePanel, InpRescuePanelFontSize);           //improve code readability
   SellGridRescueCollection.OnInit(DIRECTION_SELL,InpTradeComment, InpShowRescuePanel, InpRescuePanelFontSize);

               
   return(INIT_SUCCEEDED);

}

void OnDeinit(const int reason) {
   if(InpMultiTimeframeStrategyString!="") {DonchianSystem.OnDeinit();delete	DonchianSystem;}
   else{ DonchianExpert.OnDeinit(); delete	DonchianExpert;}  
   
	if(InpIsGridTradingAllowed == true) delete	GridExpert;
	if(InpRescueAllowed == true)    {delete BuyGridRescueCollection; delete   SellGridRescueCollection; }	        
}

void OnTick() {

	if(InpMultiTimeframeStrategyString!="") DonchianSystem.OnTick(); 
	else DonchianExpert.OnTick(); 
	
	if(InpIsGridTradingAllowed == true) GridExpert.OnTick();
	if(InpRescueAllowed == true)    {
	   BuyGridRescueCollection.OnTick(InpDebug);    
	   SellGridRescueCollection.OnTick(InpDebug); 
	}
	
	if(IsNewSession(5) ){
      if (BuyGridRescueCollection.CountValid()>0)  BuyGridRescueCollection.ShowCollectionOrdersOnChart();
      if (SellGridRescueCollection.CountValid()>0) SellGridRescueCollection.ShowCollectionOrdersOnChart();
   }
	
	return;
	
}

#endif