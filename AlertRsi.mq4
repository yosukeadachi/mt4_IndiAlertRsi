//+------------------------------------------------------------------+
//|                                                          RSI.mq4 |
//|                   Copyright 2005-2014, MetaQuotes Software Corp. |
//|                                              http://www.mql4.com |
//+------------------------------------------------------------------+
#property copyright   "2005-2014, MetaQuotes Software Corp."
#property link        "http://www.mql4.com"
#property description "Relative Strength Index"
#property version   "1.02"
#property strict

#property indicator_separate_window
#property indicator_minimum    0
#property indicator_maximum    100
#property indicator_buffers    1
#property indicator_color1     DodgerBlue
#property indicator_level1     30.0
#property indicator_level2     70.0
#property indicator_levelcolor clrSilver
#property indicator_levelstyle STYLE_DOT
//--- input parameters
input int InpRSIPeriod=9; // RSI Period
input int InpLow=28;    // Alert Low
input int InpHigh=68;   // Alert High
//--- buffers
double ExtRSIBuffer[];
double ExtPosBuffer[];
double ExtNegBuffer[];

static double _value = 0;
static double _valuePrev = 0;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit(void)
  {
   string short_name;
//--- 2 additional buffers are used for counting.
   IndicatorBuffers(3);
   SetIndexBuffer(1,ExtPosBuffer);
   SetIndexBuffer(2,ExtNegBuffer);
//--- indicator line
   SetIndexStyle(0,DRAW_LINE);
   SetIndexBuffer(0,ExtRSIBuffer);
//--- name for DataWindow and indicator subwindow label
   short_name="RSI("+string(InpRSIPeriod)+")";
   IndicatorShortName(short_name);
   SetIndexLabel(0,short_name);
//--- check for input
   if(InpRSIPeriod<2)
     {
      Print("Incorrect value for input variable InpRSIPeriod = ",InpRSIPeriod);
      return(INIT_FAILED);
     }
//---
   SetIndexDrawBegin(0,InpRSIPeriod);

   _valuePrev = _value = iRSI(NULL,PERIOD_CURRENT,InpRSIPeriod,PRICE_CLOSE,0);;
//--- initialization done
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Relative Strength Index                                          |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   int    i,pos;
   double diff;
//---
   if(Bars<=InpRSIPeriod || InpRSIPeriod<2)
      return(0);
//--- counting from 0 to rates_total
   ArraySetAsSeries(ExtRSIBuffer,false);
   ArraySetAsSeries(ExtPosBuffer,false);
   ArraySetAsSeries(ExtNegBuffer,false);
   ArraySetAsSeries(close,false);
//--- preliminary calculations
   pos=prev_calculated-1;
   if(pos<=InpRSIPeriod)
     {
      //--- first RSIPeriod values of the indicator are not calculated
      ExtRSIBuffer[0]=0.0;
      ExtPosBuffer[0]=0.0;
      ExtNegBuffer[0]=0.0;
      double sump=0.0;
      double sumn=0.0;
      for(i=1; i<=InpRSIPeriod; i++)
        {
         ExtRSIBuffer[i]=0.0;
         ExtPosBuffer[i]=0.0;
         ExtNegBuffer[i]=0.0;
         diff=close[i]-close[i-1];
         if(diff>0)
            sump+=diff;
         else
            sumn-=diff;
        }
      //--- calculate first visible value
      ExtPosBuffer[InpRSIPeriod]=sump/InpRSIPeriod;
      ExtNegBuffer[InpRSIPeriod]=sumn/InpRSIPeriod;
      if(ExtNegBuffer[InpRSIPeriod]!=0.0)
         ExtRSIBuffer[InpRSIPeriod]=100.0-(100.0/(1.0+ExtPosBuffer[InpRSIPeriod]/ExtNegBuffer[InpRSIPeriod]));
      else
        {
         if(ExtPosBuffer[InpRSIPeriod]!=0.0)
            ExtRSIBuffer[InpRSIPeriod]=100.0;
         else
            ExtRSIBuffer[InpRSIPeriod]=50.0;
        }
      //--- prepare the position value for main calculation
      pos=InpRSIPeriod+1;
     }
//--- the main loop of calculations
   for(i=pos; i<rates_total && !IsStopped(); i++)
     {
      diff=close[i]-close[i-1];
      ExtPosBuffer[i]=(ExtPosBuffer[i-1]*(InpRSIPeriod-1)+(diff>0.0?diff:0.0))/InpRSIPeriod;
      ExtNegBuffer[i]=(ExtNegBuffer[i-1]*(InpRSIPeriod-1)+(diff<0.0?-diff:0.0))/InpRSIPeriod;
      if(ExtNegBuffer[i]!=0.0)
         ExtRSIBuffer[i]=100.0-100.0/(1+ExtPosBuffer[i]/ExtNegBuffer[i]);
      else
        {
         if(ExtPosBuffer[i]!=0.0)
            ExtRSIBuffer[i]=100.0;
         else
            ExtRSIBuffer[i]=50.0;
        }
     }
//---
    _value = iRSI(NULL,PERIOD_CURRENT,InpRSIPeriod,PRICE_CLOSE,0);
    if(((_value <= InpLow) && (_valuePrev > InpLow)) ||
       ((_value >= InpHigh) && (_valuePrev < InpHigh)))
    {
        Alert(Symbol(),",",PeriodToString(Period())," RSI:(",_valuePrev,") -> (",_value,")");
    }
    _valuePrev = _value;
   return(rates_total);
  }

string PeriodToString(int period){
   string value = "";
   
   if(period == 0){
      period = Period();
   }
   
   switch(period){
      case PERIOD_M1:  value = "M1";   break;
      case PERIOD_M5:  value = "M5";   break;
      case PERIOD_M15: value = "M15"; break;
      case PERIOD_M30: value = "M30"; break;
      case PERIOD_H1:  value = "H1"; break;
      case PERIOD_H4:  value = "H4"; break;
      case PERIOD_D1:  value = "D1";    break;
      case PERIOD_W1:  value = "W1";    break;
      case PERIOD_MN1: value = "MN1";   break;
      default: break;
   }
   return(value);
}
//+------------------------------------------------------------------+

