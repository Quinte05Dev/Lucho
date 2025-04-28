//+------------------------------------------------------------------+
//|                                                  BFunded Ea.mq5 |
//|                             Copyright 2000-2024, TheTradingAPi   |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+


#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Indicators\Trend.mqh>
//#include <Jason.mqh>

//+------------------------------------------------------------------+
//| Input parameters                                                 |
//+------------------------------------------------------------------+
input bool EnableTrading = true;           // Activa o desactiva completamente la operativa del EA
input double RiskPercentage = 1.0;         // Porcentaje del saldo de la cuenta a arriesgar por operación (1% por defecto)
input int Slippage = 3;                    // Máximo deslizamiento permitido en puntos para abrir/cerrar operaciones
input int StopLoss = 50;                   // Distancia en puntos del Stop Loss desde el precio de entrada
input int TakeProfit = 50;                 // Distancia en puntos del Take Profit desde el precio de entrada
input int GMTOffset = 0;                   // Diferencia horaria en horas entre el servidor y GMT (puede ser negativa)



//#include "16_backtestingmodule.mqh"
//#include "DosVelas.mqh"


// Estructuras para Backtesting
// Definir la estructura al inicio del archivo
struct SMetricaMensual 
{
    double profit_mensual;
    double drawdown_mensual;
    bool mes_completado;
};

// Declarar las variables globales
SMetricaMensual g_metricas_mensuales[];  // Usar array dinámico
int g_mes_anterior = 0;
double g_balance_max_mes = 0;
double g_balance_inicial_mes = 0;

// Parámetros para el horario de operación (hora de Nueva York)
input string TimeSettings = "------- Configuración de Horario de Operación (Hora de Nueva York) -------"; // Separador visual en la interfaz
input string StartTime = "00:00";          // Hora de inicio de operación en formato HH:MM (hora de Nueva York)
input string EndTime = "23:59";            // Hora de fin de operación en formato HH:MM (hora de Nueva York)


// Parámetros para el patrón de velas
input string CandleSettings = "------- Configuración del Patrón de Velas -------"; // Separador visual
input double BodyToWickRatio = 1.5;        // Relación mínima entre cuerpo y mecha para considerar una vela válida
input ENUM_TIMEFRAMES CandleTimeframe = PERIOD_M1; // Periodo de tiempo para analizar las velas

//+------------------------------------------------------------------+
//| Global variables                                                 |
//+------------------------------------------------------------------+
datetime lastPrintTime = 0;                 // Controla el tiempo de la última impresión de información
ulong lastTicket = 0;                       // Guarda el número de ticket de la posición abierta actual
datetime lastCandleTime = 0;                // Almacena el tiempo de la última vela analizada
bool patternDetected = false;               // Indica si se detectó el patrón de velas
ENUM_POSITION_TYPE lastPatternDirection = POSITION_TYPE_BUY; // Dirección del último patrón detectado

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    EventSetTimer(1);                       // Configura un temporizador que se ejecuta cada segundo
    Print("EA inicializado - Operativa " + (EnableTrading ? "ACTIVADA" : "DESACTIVADA")); // Informa el estado inicial del EA
    Print("Horario de operación (NY): ", StartTime, " - ", EndTime); // Muestra el rango de operación configurado
    Print("Patrón de velas: Buscando 2 velas consecutivas en la misma dirección con relación cuerpo/mecha > ", DoubleToString(BodyToWickRatio, 1));
  
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   EventKillTimer();                       // Desactiva el temporizador al detener el EA
   Print("EA detenido - Razón: ", reason); // Registra la razón por la que se detuvo el EA
}


//+------------------------------------------------------------------+
//| Get GMT time using server time and GMTOffset                     |
//+------------------------------------------------------------------+
datetime GetGMTTime()
{
   datetime serverTime = TimeCurrent();    // Obtiene la hora actual del servidor
   datetime gmtTime = serverTime - GMTOffset * 3600; // Ajusta la hora al GMT según el offset en segundos
   return gmtTime;                         // Devuelve la hora GMT calculada
}

//+------------------------------------------------------------------+
//| Format time to string                                            |
//+------------------------------------------------------------------+
string FormatTimeToString(datetime time)
{
   MqlDateTime dt;                         // Estructura para descomponer la fecha y hora
   TimeToStruct(time, dt);                 // Convierte el tiempo en una estructura
   return StringFormat("%02d:%02d:%02d", dt.hour, dt.min, dt.sec); // Formatea como HH:MM:SS
}

//+------------------------------------------------------------------+
//| Get New York time properly considering DST                       |
//+------------------------------------------------------------------+
datetime GetNewYorkTimeRaw()
{
   datetime gmtTime = GetGMTTime();         // Obtiene la hora GMT ajustada
   MqlDateTime gmt_dt;                      // Estructura para la hora GMT
   TimeToStruct(gmtTime, gmt_dt);           // Descompone la hora GMT
   
   bool isDST = false;                      // Indicador de horario de verano (DST)
   if (gmt_dt.mon > 3 && gmt_dt.mon < 11) { // Si es entre abril y octubre, asume DST
      isDST = true;
   }
   else if (gmt_dt.mon == 3) {              // Regla para marzo (inicio DST: segundo domingo)
      int secondSunday = 8 + (7 - ((8 + gmt_dt.day_of_week) % 7)) % 7;
      if (gmt_dt.day > secondSunday || (gmt_dt.day == secondSunday && gmt_dt.hour >= 7)) {
         isDST = true;
      }
   }
   else if (gmt_dt.mon == 11) {             // Regla para noviembre (fin DST: primer domingo)
      int firstSunday = 1 + (7 - ((1 + gmt_dt.day_of_week) % 7)) % 7;
      if (gmt_dt.day < firstSunday || (gmt_dt.day == firstSunday && gmt_dt.hour < 6)) {
         isDST = true; 
      }
   }
   
   int nyOffset = isDST ? -4 : -5;          // Offset de Nueva York: -4 en DST, -5 en estándar
   datetime nyTime = gmtTime + nyOffset * 3600; // Calcula la hora de Nueva York
   return nyTime;                           // Devuelve la hora ajustada
}

//+------------------------------------------------------------------+
//| Get New York time as formatted string                           |
//+------------------------------------------------------------------+
string GetNewYorkTime()
{
   datetime nyTime = GetNewYorkTimeRaw();   // Obtiene la hora cruda de Nueva York
   MqlDateTime gmt_dt;                      // Estructura para GMT
   TimeToStruct(GetGMTTime(), gmt_dt);      // Descompone la hora GMT
   
   bool isDST = false;                      // Determina si es horario de verano
   if (gmt_dt.mon > 3 && gmt_dt.mon < 11) isDST = true;
   else if (gmt_dt.mon == 3) {
      int secondSunday = 8 + (7 - ((8 + gmt_dt.day_of_week) % 7)) % 7;
      if (gmt_dt.day > secondSunday || (gmt_dt.day == secondSunday && gmt_dt.hour >= 7)) isDST = true;
   }
   else if (gmt_dt.mon == 11) {
      int firstSunday = 1 + (7 - ((1 + gmt_dt.day_of_week) % 7)) % 7;
      if (gmt_dt.day < firstSunday || (gmt_dt.day == firstSunday && gmt_dt.hour < 6)) isDST = true;
   }
   
   MqlDateTime ny_dt;                       // Estructura para la hora de Nueva York
   TimeToStruct(nyTime, ny_dt);             // Descompone la hora de NY
   
   string dstIndicator = isDST ? "EDT" : "EST"; // Indicador EDT (verano) o EST (estándar)
   string time_str = StringFormat("%02d:%02d:%02d %s", ny_dt.hour, ny_dt.min, ny_dt.sec, dstIndicator); // Formatea la hora
   
   return time_str;                         // Devuelve la hora formateada con indicador
}

//+------------------------------------------------------------------+
//| Check if trading is allowed based on time filter                 |
//+------------------------------------------------------------------+
bool IsTimeToTrade()
{
   datetime nyTimeNow = GetNewYorkTimeRaw(); // Obtiene la hora actual de Nueva York
   MqlDateTime ny_dt;                        // Estructura para la hora de NY
   TimeToStruct(nyTimeNow, ny_dt);           // Descompone la hora actual
   
   // Convierte la hora actual y los límites a valores enteros para comparación
   int currentTime = ny_dt.hour * 100 + ny_dt.min; // Hora actual en formato HHMM
   int startTime = (int)StringToInteger(StringSubstr(StartTime,0,2)) * 100 + (int)StringToInteger(StringSubstr(StartTime,3,2)); // Inicio en HHMM
   int endTime = (int)StringToInteger(StringSubstr(EndTime,0,2)) * 100 + (int)StringToInteger(StringSubstr(EndTime,3,2));     // Fin en HHMM
   
   if(startTime <= endTime) {                // Si el horario está en el mismo día
      return (currentTime >= startTime && currentTime < endTime); // Verifica si está dentro del rango
   } else {                                  // Si el horario cruza la medianoche
      return (currentTime >= startTime || currentTime < endTime); // Verifica ambos segmentos
   }
}


//+------------------------------------------------------------------+
//| Check if candle has more body than wick                          |
//+------------------------------------------------------------------+
bool HasMoreBodyThanWick(MqlRates &candle)
{
   double bodySize = MathAbs(candle.close - candle.open);  // Tamaño del cuerpo
   double upperWick = candle.high - MathMax(candle.open, candle.close);  // Mecha superior
   double lowerWick = MathMin(candle.open, candle.close) - candle.low;   // Mecha inferior
   double totalWickSize = upperWick + lowerWick;  // Tamaño total de las mechas
   
   // Evitar división por cero
   if(totalWickSize < 0.000001) {
      return true;  // Si casi no hay mechas, consideramos que tiene más cuerpo
   }
   
   // Verifica si la relación cuerpo/mecha es mayor que el ratio definido
   return (bodySize / totalWickSize) >= BodyToWickRatio;
}

//+------------------------------------------------------------------+
//| Get candle direction (bullish or bearish)                        |
//+------------------------------------------------------------------+
ENUM_POSITION_TYPE GetCandleDirection(MqlRates &candle)
{
   return (candle.close > candle.open) ? POSITION_TYPE_BUY : POSITION_TYPE_SELL;
}

//+------------------------------------------------------------------+
//| Check for two consecutive candles in the same direction with     |
//| more body than wick                                              |
//+------------------------------------------------------------------+
bool CheckCandlePattern()
{
   MqlRates candles[3];  // Obtener las últimas 3 velas
   if(CopyRates(_Symbol, CandleTimeframe, 0, 3, candles) != 3) {
      Print("Error al obtener datos de velas: ", GetLastError());
      return false;
   }
   
   // Las velas están ordenadas de la más antigua a la más reciente
   MqlRates candle1 = candles[1];  // Penúltima vela (completada)
   MqlRates candle2 = candles[0];  // Última vela completada
   
   // Verificar si ambas velas tienen más cuerpo que mecha
   bool candle1Valid = HasMoreBodyThanWick(candle1);
   bool candle2Valid = HasMoreBodyThanWick(candle2);
   
   if(!candle1Valid || !candle2Valid) {
      return false;  // Al menos una de las velas no cumple el criterio de cuerpo/mecha
   }
   
   // Obtener la dirección de cada vela
   ENUM_POSITION_TYPE direction1 = GetCandleDirection(candle1);
   ENUM_POSITION_TYPE direction2 = GetCandleDirection(candle2);
   
   // Verificar si las dos velas están en la misma dirección
   if(direction1 == direction2) {
      lastPatternDirection = direction1;  // Guardamos la dirección del patrón
      return true;
   }
   
   return false;
}


void OnTimer()
{
   datetime currentTime = TimeCurrent();     // Obtiene el tiempo actual del servidor
   
   if(currentTime - lastPrintTime >= 5)      // Imprime información cada 5 segundos
   {
      string server_time = FormatTimeToString(currentTime); // Hora del servidor formateada
      datetime gmtTime = GetGMTTime();        // Obtiene la hora GMT
      string gmt_time = FormatTimeToString(gmtTime); // Hora GMT formateada
      string ny_time = GetNewYorkTime();      // Hora de Nueva York formateada
      
      bool canTrade = EnableTrading && IsTimeToTrade(); // Verifica si se puede operar
      string tradingStatus = canTrade ? "PERMITIDO" : "NO PERMITIDO"; // Estado de trading
      
      Print("Hora del servidor: ", server_time, " | Hora GMT: ", gmt_time, " | Hora de Nueva York: ", ny_time, " | Trading: ", tradingStatus);
      
      lastPrintTime = currentTime;            // Actualiza el tiempo de la última impresión
   }
   
   // Verificar si hay una nueva vela completa
   datetime lastBarTime = iTime(_Symbol, CandleTimeframe, 0);
   if(lastBarTime != lastCandleTime) {
      lastCandleTime = lastBarTime;           // Actualizar el tiempo de la última vela analizada
      
      // Verificar el patrón de velas cuando se forma una nueva vela
      patternDetected = CheckCandlePattern();
      
      if(patternDetected) {
         string direction = (lastPatternDirection == POSITION_TYPE_BUY) ? "ALCISTA" : "BAJISTA";
         Print("¡Patrón de velas detectado! Dirección: ", direction);
         
         // Si podemos operar y no hay posición abierta, abrir una nueva operación
         if(EnableTrading && IsTimeToTrade() && lastTicket == 0) {
            OpenTradeBasedOnPattern();
         }
      }
   }
   
   // El bloque que cerraba la operación después de 30 segundos ha sido eliminado
}



// void OnTimer()
// {
//    datetime currentTime = TimeCurrent();     // Obtiene el tiempo actual del servidor
   
//    if(currentTime - lastPrintTime >= 5)      // Imprime información cada 5 segundos
//    {
//       string server_time = FormatTimeToString(currentTime); // Hora del servidor formateada
//       datetime gmtTime = GetGMTTime();        // Obtiene la hora GMT
//       string gmt_time = FormatTimeToString(gmtTime); // Hora GMT formateada
//       string ny_time = GetNewYorkTime();      // Hora de Nueva York formateada
      
//       bool canTrade = EnableTrading && IsTimeToTrade(); // Verifica si se puede operar
//       string tradingStatus = canTrade ? "PERMITIDO" : "NO PERMITIDO"; // Estado de trading
      
//       Print("Hora del servidor: ", server_time, " | Hora GMT: ", gmt_time, " | Hora de Nueva York: ", ny_time, " | Trading: ", tradingStatus);
      
//       lastPrintTime = currentTime;            // Actualiza el tiempo de la última impresión
//    }
   
//    // Verificar si hay una nueva vela completa
//    datetime lastBarTime = iTime(_Symbol, CandleTimeframe, 0);
//    if(lastBarTime != lastCandleTime) {
//       lastCandleTime = lastBarTime;           // Actualizar el tiempo de la última vela analizada
      
//       // Verificar el patrón de velas cuando se forma una nueva vela
//       patternDetected = CheckCandlePattern();
      
//       if(patternDetected) {
//          string direction = (lastPatternDirection == POSITION_TYPE_BUY) ? "ALCISTA" : "BAJISTA";
//          Print("¡Patrón de velas detectado! Dirección: ", direction);
         
//          // Si podemos operar y no hay posición abierta, abrir una nueva operación
//          if(EnableTrading && IsTimeToTrade() && lastTicket == 0) {
//             OpenTradeBasedOnPattern();
//          }
//       }
//    }
   
// }

//+------------------------------------------------------------------+
//| Calculate lot size based on risk percentage                      |
//+------------------------------------------------------------------+
double CalculateLotSize(double riskPercentage, int stopLoss)
{
   double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE); // Obtiene el saldo actual de la cuenta
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE); // Valor monetario de un tick
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);   // Tamaño del tick del símbolo
   double pointValue = tickValue * (Point() / tickSize); // Calcula el valor por punto ajustado
   
   double riskAmount = accountBalance * (riskPercentage / 100.0); // Cantidad en dinero a arriesgar
   double lotSize = riskAmount / (stopLoss * pointValue); // Calcula el tamaño del lote según el riesgo y SL
   
   double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP); // Paso mínimo de volumen del broker
   lotSize = MathFloor(lotSize / lotStep) * lotStep; // Ajusta al paso mínimo permitido
   
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN); // Volumen mínimo permitido
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX); // Volumen máximo permitido
   lotSize = MathMax(minLot, MathMin(maxLot, lotSize)); // Limita el lote entre min y max
   
   return lotSize;                             // Devuelve el tamaño del lote calculado
}

//+------------------------------------------------------------------+
//| Open trade based on detected candle pattern                      |
//+------------------------------------------------------------------+
void OpenTradeBasedOnPattern()
{
   CTrade trade;                               // Crea un objeto de la clase CTrade para operar
   double lotSize = CalculateLotSize(RiskPercentage, StopLoss); // Calcula el tamaño del lote
   
   if(lastPatternDirection == POSITION_TYPE_BUY) {
      // Abrir posición de compra (patrón alcista)
      double price = SymbolInfoDouble(_Symbol, SYMBOL_ASK); // Precio actual de compra (ASK)
      double sl = price - StopLoss * _Point;  // Nivel de Stop Loss
      double tp = price + TakeProfit * _Point; // Nivel de Take Profit
      
      if(trade.Buy(lotSize, _Symbol, price, sl, tp, "Velas Pattern Trader")) {
         lastTicket = trade.ResultOrder();
         Print("Posición COMPRA abierta por patrón. Ticket: ", lastTicket, " Lote: ", lotSize, " Hora NY: ", GetNewYorkTime());
      }
      else {
         Print("Error al abrir posición de compra: ", GetLastError());
      }
   }
   else {
      // Abrir posición de venta (patrón bajista)
      double price = SymbolInfoDouble(_Symbol, SYMBOL_BID); // Precio actual de venta (BID)
      double sl = price + StopLoss * _Point;  // Nivel de Stop Loss
      double tp = price - TakeProfit * _Point; // Nivel de Take Profit
      
      if(trade.Sell(lotSize, _Symbol, price, sl, tp, "Velas Pattern Trader")) {
         lastTicket = trade.ResultOrder();
         Print("Posición VENTA abierta por patrón. Ticket: ", lastTicket, " Lote: ", lotSize, " Hora NY: ", GetNewYorkTime());
      }
      else {
         Print("Error al abrir posición de venta: ", GetLastError());
      }
   }
   
   // Restablecer la detección del patrón para evitar operaciones duplicadas
   patternDetected = false;
}

//+------------------------------------------------------------------+
//| Close trade function                                             |
//+------------------------------------------------------------------+
void CloseTrade()
{
   CTrade trade;                               // Crea un objeto de la clase CTrade para cerrar
   if(trade.PositionClose(lastTicket, Slippage)) // Intenta cerrar la posición usando el ticket
   {
      Print("Posición cerrada. Ticket: ", lastTicket, " Hora NY: ", GetNewYorkTime()); // Registra el cierre exitoso
      lastTicket = 0;                          // Reinicia el ticket a 0
   }
   else
   {
      Print("Error al cerrar posición: ", GetLastError()); // Muestra el error si falla
   }
}



//+------------------------------------------------------------------+
//| Expert Trade function                                             |
//+------------------------------------------------------------------+

void OnTrade() {
  // Si había una posición abierta pero ya no está, actualizar lastTicket
  if(lastTicket > 0) {
     if(!PositionSelectByTicket(lastTicket)) {
        Print("Posición cerrada naturalmente (SL/TP). Ticket: ", lastTicket);
        lastTicket = 0;  // Reiniciar el ticket cuando la posición se cierra
     }
  }
  
  // Metricas Backtesting (código existente)
}

// void OnTrade() {


//             //Metricas Backtesting 
//             // Actualizar métricas
//             //DibujarMetricasMensuales();

// }


//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+

void OnTick() {



}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
// void OnDeinit(const int reason)
//   {
 

//     if (!MQLInfoInteger(MQL_TESTER))
//     {   

//     ObjectsDeleteAll(0, "MetricasMensuales");
//     for(int i = 0; i < 12; i++)
//     {
//         ObjectDelete(0, "Mes_" + IntegerToString(i));
//     }
//     ObjectDelete(0, "MesActual");
//     ObjectDelete(0, "TituloMetricas");
    
//      }

//   }
// //+------------------------------------------------------------------+


// double OnTester()
// {

// }





