#property copyright "Copyright 2021, BlueStone FX"
#property link      "https://www.mql5.com/en/users/expdal3/seller"
#property version   "1.00"
#property description	"an scalping EA base on 2 Donchian channels - Fast and Slow"
#property description	"with trailing TP and SL"
#property strict

//	This is where we pull in the framework
#include <Orchard/_Frameworks/Framework.mqh>

//	Input Section
//
extern	int				InpDonchianFastPeriods					=	10;	//	Fast periods	
extern	int				InpDonchianSlowPeriods					=	20;	//	Slow periods


enum ENUM_OFX_TPSL_TYPE
  {   Fixed_TPSL = 1,
      TPSL_base_on_ATR =2,
  };

string   __ChooseTakeProfitAndStopLoss__Type   = "_____________________________";

extern ENUM_OFX_TPSL_TYPE   InpTPSLType          =  TPSL_base_on_ATR; //Choose TakeProfit and StopLoss type
//
// For simple point based TPSL
extern int            InpTPPoints                = 100;
extern int            InpSLPoints                = 100;

//	For ATR based TPSL
extern	int				InpATRPeriods				=	14;	//	ATR Periods
extern	double			InpATRMultiplier			=	3.0;	//	ATR Multiplier

//	Order inputs
extern	double			InpLotSize				=	0.01;			//	Default order size
extern	string			InpComment				=	__FILE__;	//	Default trade comment
extern	int				InpMagicNumber			=	2222;	//	Magic Number

//	Declare the expert, use the child class name
//
#define	CExpert	CExpertBase
CExpert		*Expert;

//	Signals, use the child class names if applicable
//
CSignalPriceBreakout	*EntrySignal;

//	TPSL - use child class name (used for ATR TPSL, if simple TPSL then don't need this part)
//
CTPSLSimple	*TPSL;

//	Indicators - use the child class name here
//
CciDonchianChannel	*FastChannel;
CciDonchianChannel	*SlowChannel;
// And for the TPSL
CIndicatorATR	*IndicatorATR;

int OnInit() {

	//
	//	Instantiate the expert
	//
	Expert	=	new CExpert();

	//
	//	Assign the default values to the expert
	//
	Expert.SetVolume(InpLotSize);
	Expert.SetTradeComment(InpComment);
	Expert.SetMagic(InpMagicNumber);
	
	//
	//	Create the indicators
	//
	FastChannel	=	new CciDonchianChannel(Symbol(), (ENUM_TIMEFRAMES) Period(), InpDonchianFastPeriods);
	SlowChannel	=	new CciDonchianChannel(Symbol(), (ENUM_TIMEFRAMES) Period(), InpDonchianSlowPeriods);
	
	//
	//	Set up the signals
	//
	EntrySignal	=	new CSignalPriceBreakout();
	EntrySignal.AddIndicator(FastIndicator, 0);
	EntrySignal.AddIndicator(SlowIndicator, 0);
	
	//ExitSignal	=	Not needed, using the same signal as entry
	
	//
	//	Add the signals to the expert
	//
	Expert.AddEntrySignal(EntrySignal);
	Expert.AddExitSignal(EntrySignal);	//	Same signal
	//
	TPSL				=	new CTPSLSimple();
	IndicatorATR	=	new CIndicatorATR(InpATRPeriods);
	if(InpTPSLType == Fixed_TPSL){
	//
	//	Set up for Simple Fixed TPSL
	//
	Expert.SetTakeProfitValue(InpTPPoints);
	Expert.SetStopLossValue(InpSLPoints);
	   
	}else{
   //
	//	Set up the ATR TPSL
	//
	
	TPSL.AddIndicator(IndicatorATR               //CIndicatorBase *indicator object
	                  , 0);                      //bufferNum = 0
	TPSL.SetIndex(1);                            //Look at bar number 1
	TPSL.SetMultiplier(InpATRMultiplier);
	
	Expert.SetTakeProfitObj(TPSL);               //Add the TP object to Expert obj
	Expert.SetStopLossObj(TPSL);                 //Add the SL object to Expert obj
	}

	
	//
	// Finish expert initialisation and check result
	//
	int	result	=	Expert.OnInit();
	
   return(result);

}

void OnDeinit(const int reason) {

   EventKillTimer();
	
	delete	Expert;

	delete	EntrySignal;

	delete	TPSL;
	
	delete	FastIndicator;
	delete	SlowIndicator;
	delete	IndicatorATR;
	
	return;
	
}

void OnTick() {

	Expert.OnTick();
	return;
	
}

void OnTimer() {

	Expert.OnTimer();
	return;

}

double OnTester() {

	return(Expert.OnTester());

}

void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam) {

	Expert.OnChartEvent(id, lparam, dparam, sparam);
	return;
	
}


