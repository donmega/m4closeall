#include <WinUser32.mqh>
#import "user32.dll"
int GetAncestor(int hwnd, int flags);
#define MT4_WMCMD_EXPERTS  33020
#import

// Global Variables
bool AutoTradingEnabled = true; // Track desired AutoTrading state

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   // Schedule task to run every minute
   EventSetTimer(60); // Use 60 seconds timer to check every minute
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // Cleanup timer
   EventKillTimer();
}

//+------------------------------------------------------------------+
//| Timer event handler                                              |
//+------------------------------------------------------------------+
void OnTimer()
{
   datetime currentTime = TimeCurrent();

   // Check if it's Friday 22:00
   if (TimeDayOfWeek(currentTime) == 5 && TimeHour(currentTime) == 22 && TimeMinute(currentTime) == 0) 
   {
      // Close all open positions across all symbols
      CloseAllPositions(); 

      // Disable automatic trading (if it's not already disabled)
      SetAlgoTradingTo(false); 
      AutoTradingEnabled = false; // Update tracking variable
   }

   // If AutoTrading is not supposed to be enabled, but somehow gets turned on...
   if(!AutoTradingEnabled && IsTradeAllowed()) 
   {
      SetAlgoTradingTo(false); // ...ensure it's off.
   } 
}

//+------------------------------------------------------------------+
//| Closes all open positions across all symbols                     |
//+------------------------------------------------------------------+
void CloseAllPositions()
{
   for(int i = OrdersTotal()-1; i >= 0; i--)  // Reverse iteration: Close newest to oldest
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         // No symbol filter is applied, so it closes positions for any symbol
         OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 3, clrNONE);
      }
   }
}

//+------------------------------------------------------------------+
//| Toggles automatic trading on the MT4 terminal                    |
//+------------------------------------------------------------------+
void SetAlgoTradingTo(bool trueFalse) 
{
   bool currentStatus = IsTradeAllowed();
   if(currentStatus != trueFalse) 
   {
      int main = GetAncestor(WindowHandle(Symbol(), Period()), 2 /*GA_ROOT*/);
      PostMessageA(main, WM_COMMAND, MT4_WMCMD_EXPERTS, 0);
   }
}
