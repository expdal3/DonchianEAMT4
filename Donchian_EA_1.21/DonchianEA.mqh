/*

	Ichimoku v1.mqh
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

#property strict

#include "../Framework.mqh"

#ifndef DONCHIAN_VERSION
   #define DONCHIAN_VERSION
   #define DONCHIAN_VERSION_1_21
#endif

#ifdef DONCHIAN_VERSION_1_21

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

//	inputs for this Donchian expert
extern   string   InpSymbols                 = "";        // List of Symbols
extern   string   InpSymbolSuffix            = "";             //Broker's symbol suffix
extern   int      InpDonchianPeriod          = 20;        //	Bands period
//extern   int      InpMaxTrades               = 30;       // Max number of trades allowed
extern   ENUM_BLUES_STRATEGY_DIRECTION      InpTradeEntryStrategy = _Break_out_;
extern   int      InpNoMoreTradeWithinXMins  = 240;        // No new trade within X mins from last trade

extern string   __ChooseTakeProfitAndStopLoss__Type   = "__TAKE-PROFIT AND STOP-LOSS SETTING___";

input ENUM_OFX_TPSL_TYPE   InpTPSLType          =  TPSL_base_on_ATR; //Choose TakeProfit and StopLoss type
//
// For simple point based TPSL
extern int            InpTPPoints                = 100;
extern int            InpSLPoints                = 100;
extern double         InpRRratio                 = 2.5;

//
//	For ATR based TPSL
//
extern	int				InpATRPeriods					=	14;	//	ATR Periods
extern	double			InpATRMultiplier				=	3.0;	//	ATR Multiplier

//	Now some general trading info
extern	double	InpOrderSize			            =	0.01;					//	Order size
extern	string	InpTradeComment		            =	"Donchian EA V1";	//	Trade comment
extern	string	InpMagic					            =	"222222";				//	Magic number
extern	int	   InpMaxMainBuySignalTradeAllowed	=	3;				//	Max BUY trade from main Donchian signal
extern	int	   InpMaxMainSellSignalTradeAllowed	=	3;				//	Max SELL trade from main Donchian signal

extern string   __ChooseNewsFilterSettings   = "__NEWS FILTER SETTINGS__";
extern   bool     InpIsNewsFilterEnabled       = false;             // Enable News Filter?
extern   int      InpMinutesBeforeNews         = 60   ;             // minutes before news
extern   int      InpMinutesAfterNews         = 60   ;              // minutes after news
extern   ENUM_BLUES_NEWS_IMPACT      InpNewsImpactToFilter        = _HighImpact_;

extern string   __ChooseSignalVisual   = "__SIGNAL INDICATOR ON-CHART SETTINGS__";

extern   bool     InpShowSignalArrows              = false;       // Show Trade Signal on-chart?

#define  GRIDTRADECLASS_VERSION_2_0                      //define the version of GridTradeFunction
#include <Blues/GridTradeFunction/include.mqh>
string   __Grid__Trading   = "_____________________________";
extern	bool		InpIsGridTradingAllowed					=	true;				//	Enable GridTrading?

extern   string            InpTradingAllowedTimeRange   =  "01:30-13:35,18:00-22:59";           //Trading-allowed time, Mon-Thu
extern   string            InpTradingAllowedTimeRangeFriday   =  "01:30-13:35,18:00-22:59";     //Trading-allowed time Friday
//		and lot sizes
extern   int		         InpLevelPoints			=	200;						//	Trade gap in points
//extern   int               InpMaxTrades          =  30;             //Max number of trades allowed

extern ENUM_BLUES_TRADE_MODES    InpTradeMode            = Buy_and_Sell;   // TradeMode  
extern double              InpMinProfit            = 100.00;           // GridTakeProfit ($))
extern double              InpMinProfitRescue      = 1.00;           // GridTakeProfit during recovery mode
extern int                 InpGridLevelRescue      = 3;           // GridLevel to start recovery mode
extern double              InpMaxLoss              = -200.00;           // GridStopLoss ($)

//	Now some general trading info
//extern   double	         InpOrderSize			   =	0.01;					//	Order size
extern   double            InpFactor               =  1.5;               //LotSize Multiplier
extern   int               InpLevelToStartAveraging =  3;               //LevelToStart Averaging
extern   ENUM_BLUES_GRID_TRAILORDERSIZE_OPT               InpTrailOrderSizeOption =  _multiply_factor_;               //Next OrderSize Calc approach

extern	string	         InpGridEATradeComment	=	"Donchian_Grids";	//	Trade comment
//extern	string		      InpGridEAMagics			=	"1234";				//	Magic number
extern	bool		         InpGridEADebug			   =	false;				//	EA Debug Mode

#define  GRIDRESCUECLASS_VERSION_2_0               // select the GridRescueClass's version'
#include <Blues/GridRescueFunction/include.mqh>

#include "../Expert.mqh"
CExpertDonchian*	      DonchianExpert;            // module to place signal order base on Donchian channel trade logic
CExpertGridCollection*	GridExpert;                // module to place subsequent grid order base on signal order - if Grid Trading is enabled
CGridCollection   *     BuyGridCollection;          // module to rescue drawdown for a Grid (include both signal order and child grid orders)    
CGridCollection   *     SellGridCollection;          // module to rescue drawdown for a Grid (include both signal order and child grid orders) 

int OnInit() {
   string inpSymbols = (InpSymbols=="")? Symbol(): InpSymbols;     //use Chart's symbol or ListOfSymbols
   int inpLevelToStartAveraging = InpLevelToStartAveraging-1;
	string inpGridMagicNumber = InpMagic+"00";
	
	DonchianExpert	=	new CExpertDonchian(	InpDonchianPeriod, inpSymbols, InpOrderSize, InpTradeComment, StringToInteger(InpMagic));
	DonchianExpert.SetTradingStrategy(InpTradeEntryStrategy, InpMaxMainBuySignalTradeAllowed,InpMaxMainSellSignalTradeAllowed);
	DonchianExpert.SetTPSLparameters(InpTPSLType,InpTPPoints,InpSLPoints,InpRRratio,InpATRMultiplier, InpATRPeriods);   //Set TPSL parameters
	DonchianExpert.SetTradePacingparameters(InpNoMoreTradeWithinXMins);   //Set TPSL parameters
	DonchianExpert.SetTradeSignalVisualparameters(InpShowSignalArrows);
	//---initial setup for sub-modules
   DonchianExpert.SetupTradeEntryStrategy();                            //enable choosing between BreakOut | Reversal entry
   DonchianExpert.SetupNewsFilter(InpIsNewsFilterEnabled, InpNewsImpactToFilter, InpMinutesBeforeNews, InpMinutesAfterNews); //enable NewsFilter setting
   
   //DonchianExpert.SetBandExtremumPeriod(5);      //if to only need to check for a shorter / longer period than the InpDonchianPeriod
   //---
   
	GridExpert = new CExpertGridCollection(inpSymbols, "", InpMagic
                             ,InpTradingAllowedTimeRange, InpTradingAllowedTimeRangeFriday, InpTrailOrderSizeOption, InpFactor,InpMinProfit, InpMinProfitRescue, InpGridLevelRescue
                             , InpMaxLoss, InpLevelPoints, inpLevelToStartAveraging, InpOrderSize, InpGridEATradeComment, InpTradeMode, true, InpGridEADebug);

	// instantiate and setup GridRescue Expert
	//
   // manage all BUY grids
   BuyGridCollection = new CGridCollection(inpSymbols,InpSymbolSuffix,inpGridMagicNumber,OP_BUY,InpLevelToStartRescue,InpRescueScheme, InpSubGridProfitToClose,InpIterationModeAndProfitToCloseStr,InpTradeComment, InpRescueAllowed
                                          ,InpPanicCloseOrderCount,InpPanicCloseMaxDrawdown,InpPanicCloseMaxLotSize,InpPanicCloseProfitToClose,InpPanicClosePosOfSecondOrder,InpStopPanicAfterNClose
                                          ,InpPanicCloseIsDriftProfitAfterEachIteration,InpPanicCloseDriftProfitStep,InpPanicCloseDriftLimit, InpPanicCloseBottomOrderIfBetter, InpPanicCloseAllowed
                                          ,InpCritCloseIfPanicOf,InpCritCloseTimeRange,InpCritCloseMaxOpenMinute,InpCritProfitToCloseTopOrder,InpCritForceCloseAtEndTime,InpCritForceCloseIgnoreMaxDuration,InpCritCloseAllowed
                                          ,true //isonechart
                                          );
   // manage all SELL grids
   SellGridCollection = new CGridCollection(inpSymbols,InpSymbolSuffix,inpGridMagicNumber,OP_SELL,InpLevelToStartRescue,InpRescueScheme, InpSubGridProfitToClose,InpIterationModeAndProfitToCloseStr,InpTradeComment, InpRescueAllowed
                                          ,InpPanicCloseOrderCount,InpPanicCloseMaxDrawdown,InpPanicCloseMaxLotSize,InpPanicCloseProfitToClose,InpPanicClosePosOfSecondOrder,InpStopPanicAfterNClose
                                          ,InpPanicCloseIsDriftProfitAfterEachIteration,InpPanicCloseDriftProfitStep,InpPanicCloseDriftLimit, InpPanicCloseBottomOrderIfBetter, InpPanicCloseAllowed
                                          ,InpCritCloseIfPanicOf,InpCritCloseTimeRange,InpCritCloseMaxOpenMinute,InpCritProfitToCloseTopOrder,InpCritForceCloseAtEndTime,InpCritForceCloseIgnoreMaxDuration,InpCritCloseAllowed
                                          ,true
                                          );
   BuyGridCollection.OnInit(DIRECTION_BUY,InpTradeComment, InpShowRescuePanel, InpRescuePanelFontSize);           //improve code readability
   SellGridCollection.OnInit(DIRECTION_SELL,InpTradeComment, InpShowRescuePanel, InpRescuePanelFontSize);
               
   return(DonchianExpert.InitResult());

}

void OnDeinit(const int reason) {

	delete	DonchianExpert;
	if(InpIsGridTradingAllowed == true) delete	GridExpert;
	        
}

void OnTick() {

	DonchianExpert.OnTick();
	if(InpIsGridTradingAllowed == true) GridExpert.OnTick();
	if(InpRescueAllowed == true)    {BuyGridCollection.OnTick(InpDebug);    SellGridCollection.OnTick(InpDebug); }
	
	if(IsNewSession(5) ){
      if (BuyGridCollection.CountValid()>0)  BuyGridCollection.ShowCollectionOrdersOnChart();
      if (SellGridCollection.CountValid()>0) SellGridCollection.ShowCollectionOrdersOnChart();
   }
	
	return;
	
}

#endif