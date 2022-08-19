/*
 *	CciChannelBase.mqh
 *	Copyright 2013-2020, Orchard Forex
 * https://orchardforex.com
 *
 */



#include	"Framework.mqh"

enum ENUM_INDICATOR_CHANNEL
  {
   HIGH_CHANNEL=0,
   LOW_CHANNEL=1,
   MID_CHANNEL=2
  };

class CIndicatorChannelBase: public CIndicatorBase {

private:

public:                                                  //protected vars and function can be used by child class inherit from this class
	
	datetime				   mFirstBarTime;
	int						mPrevCalculated;

	double					mChannelMid[];	
	double					mChannelHigh[];
	double					mChannelLow[];

	virtual void			Update();
	virtual void			UpdateValues(int bars, int limit);


public:

	CIndicatorChannelBase(); //default initialization
	CIndicatorChannelBase(string symbol, ENUM_TIMEFRAMES timeframe); //pointer initialization
	~CIndicatorChannelBase(){};
	
	virtual int				Init();

	virtual double			Mid(int index);
	virtual double			High(int index);
	virtual double			Low(int index);
	
};
//+------------------------------------------------------------------+
//| Constructor & destructor                                         |
//+------------------------------------------------------------------+
CIndicatorChannelBase::CIndicatorChannelBase():CIndicatorBase(){Init();}

CIndicatorChannelBase::CIndicatorChannelBase(string symbol, ENUM_TIMEFRAMES timeframe)
                  :CIndicatorBase(symbol, timeframe)
                  {Init();}

int		CIndicatorChannelBase::Init() {
	
	if (InitResult()!=INIT_SUCCEEDED)	return(InitResult());
	
	mFirstBarTime		=	0;
	mPrevCalculated	=	0;
	
	ArraySetAsSeries(mChannelMid, true);
	ArraySetAsSeries(mChannelHigh, true);
	ArraySetAsSeries(mChannelLow, true);
	
	return (InitResult());
}

double	CIndicatorChannelBase::Mid(int index) {

	Update();

	if (index>=ArraySize(mChannelMid))	return(0);
	return(mChannelMid[index]);
	
}

double	CIndicatorChannelBase::High(int index) {

	Update();

	if (index>=ArraySize(mChannelHigh))	return(0);
	return(mChannelHigh[index]);
	
}

double	CIndicatorChannelBase::Low(int index) {

	Update();

	if (index>=ArraySize(mChannelLow))	return(0);
	return(mChannelLow[index]);
	
}


//
//	This is the function definition for an indicator
//

void		CIndicatorChannelBase::Update() {

	//	Some basic information required
	int		bars				=	iBars(mSymbol, mTimeframe);			//	How many bars are available to calculate
	datetime	firstBarTime	=	iTime(mSymbol, mTimeframe, bars-1);	//	Find the time of the first available bar
	
	//	How many bars must be calculated
   int		limit				=	bars-mPrevCalculated;					//	How many bars have we NOT calculated
   if (mPrevCalculated>0)		limit++;										//	This forces recalculation of the current bar (0)
	if (firstBarTime!=mFirstBarTime) {
		limit						=	bars;											//	First time change means recalculate everything
		mFirstBarTime			=	firstBarTime;								//	Just a reset
	}

	if (limit<=0)							return;								//	Should not happen but better to be safe
		
	if (bars!=ArraySize(mChannelHigh)) {									//	Make sure array size matches number of bars
		ArrayResize(mChannelMid, bars);
		ArrayResize(mChannelHigh, bars);
		ArrayResize(mChannelLow, bars);
	}
	
	UpdateValues(bars, limit);
	
}

void		CIndicatorChannelBase::UpdateValues(int bars,int limit) {

	mPrevCalculated		=	bars;																		//	Reset our position in the array
	
	return;

}


class CIndicatorChannelDonchian: public CIndicatorChannelBase 
   {
private:
   //---declaring private class's variable and function

   int               mDonchianPeriods;
protected:
   virtual  void  UpdateValues(int bars, int limit);

public:
                     CIndicatorChannelDonchian(){Init(20);};   //original constructor with no param
                     CIndicatorChannelDonchian(string symbol, ENUM_TIMEFRAMES timeframe, int donchianPeriods)    //---new constructur CciDonchianChannel() with 3 params - which then pass default value to Init function
					 		 : CIndicatorChannelBase(symbol, timeframe) 
							  {Init(donchianPeriods);}; //this can be used with pointer using `new` operator

                    ~CIndicatorChannelDonchian(){};   //deconstructor
   void              Init(int donchianPeriods);
   
	virtual double GetData(const int buffer_num,const int index);
};

void CIndicatorChannelDonchian::Init(int donchianPeriods)
  {
   mDonchianPeriods = donchianPeriods;
   Update();                     //CIndicatorChannelBase Update function, which run on each new bar - which will call UpdateValues from CDonchian

  }

//+------------------------------------------------------------------+
//| Calculating the value of the indicator                           |
//+------------------------------------------------------------------+
void CIndicatorChannelDonchian::UpdateValues(int bars, int limit)
  {

   int lim = 0;
   int count = (bars >= mDonchianPeriods) ? mDonchianPeriods : bars; 
   for(int i=0; i<=count-1; i++)     // int i=limit - 1; i>=0; i-- start the the first bar of the chart (far Left) then got toward the right
                                       // int i=0; i<=count-1; i++ start the the current bar (right most of the chart) then got toward the left (past bar)
     {
      lim = (bars - i)>= mDonchianPeriods ? mDonchianPeriods : (bars-i);  //To handle  bars before the length of the channel
      mChannelHigh[i]   = iHigh(mSymbol,mTimeframe,iHighest(mSymbol,mTimeframe,MODE_HIGH,lim, i));
      mChannelLow[i] = iLow(mSymbol,mTimeframe,iLowest(mSymbol,mTimeframe,MODE_LOW,lim,i));
      mChannelMid[i] = (mChannelHigh[i]+mChannelLow[i])/2;
     }
   mPrevCalculated = bars; // Reset our position in the array

  }

double	CIndicatorChannelDonchian::GetData(const int buffer_num,const int index) {
	double value =0;

	switch (buffer_num)
	{
	case 0:					//buffer 0 = High
		value = mChannelHigh[index];
		break;
	case 1:
		value = mChannelLow[index];
      break;
	case 2:
		value = mChannelMid[index];
		break;
	default:
		break;
	}
	return(value); 
}