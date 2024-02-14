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
//| Closes all open positions across all symbols and sends a        |
//| notification upon completion or error.                           |
//+------------------------------------------------------------------+
void CloseAllPositions()
{
   int closedPositions = 0;
   int totalPositions = OrdersTotal();
   string message = "";

   for(int i = totalPositions-1; i >= 0; i--)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 3, clrNONE))
         {
            closedPositions++;
         }
         else
         {
            // If there was an error closing an order, capture the error
            message += "Error closing position: " + IntegerToString(GetLastError()) + "; ";
         }
      }
   }

   if(closedPositions == totalPositions)
   {
      // All positions closed successfully
      SendNotification("All positions closed successfully at " + TimeToString(TimeCurrent(), TIME_DATE | TIME_MINUTES));
   }
   else if(closedPositions < totalPositions && closedPositions > 0)
   {
      // Some positions were not closed successfully
      SendNotification(IntegerToString(closedPositions) + " of " + IntegerToString(totalPositions) + " positions closed. Errors: " + message);
   }
   else if(totalPositions > 0)
   {
      // No positions were closed, but there were positions to close
      SendNotification("Failed to close positions. Errors: " + message);
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
