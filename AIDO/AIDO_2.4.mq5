#property copyright "Copyright 2023, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"

// --- En esta versión imprime cuando hay un rompimiento de la sesion anterior ---

// --- INPUTS (CONFIGURACIÓN DEL USUARIO) ---

input group "01. SESION";

// Configuración de Nueva York
input bool input_operativa_newyork = true; // Permitir Operativa en NY
input string input_ny_hora = "08:00";      // Inicio horario NY (hora:minutos)
input string hasta_ny_hora = "12:00";      // Fin horario NY (hora:minutos)
input color input_color_rect_main = clrRed; // Color del rectángulo principal NY

// Configuración de Londres
input bool input_operativa_londres = true; // Permitir Operativa en Londres
input string input_londres_hora = "00:10";  // Inicio horario Londres (hora:minutos)
input string hasta_londres_hora = "10:10";  // Fin horario Londres (hora:minutos)
input color input_color_rect_main_londres = clrGreen; // Color del rectángulo principal Londres

// Configuración de Tokio (Asia)
input bool input_operativa_asia = true;   // Permitir Operativa en Asia
input string input_asia_hora = "21:00";    // Inicio horario Asia (hora:minutos)
input string hasta_asia_hora = "01:00";    // Fin horario Asia (hora:minutos)
input color input_color_rect_main_asia = clrPurple; // Color del rectángulo principal Asia

input group "02. OPERATIVA";

// Subperíodo de Nueva York
input string input_ny_sub_hora = "09:00";  // Inicio subperíodo NY (hora:minutos)
input string hasta_ny_sub_hora = "11:00";  // Fin subperíodo NY (hora:minutos)
input color input_color_rect_sub = clrBlue; // Color del rectángulo del subperíodo NY

// Subperíodo de Londres
input string input_londres_sub_hora = "01:00";  // Inicio subperíodo Londres (hora:minutos)
input string hasta_londres_sub_hora = "03:00";  // Fin subperíodo Londres (hora:minutos)
input color input_color_rect_sub_londres = clrLightGreen; // Color del rectángulo del subperíodo Londres

// Subperíodo de Tokio (Asia)
input string input_asia_sub_hora = "22:00";  // Inicio subperíodo Asia (hora:minutos)
input string hasta_asia_sub_hora = "00:00";  // Fin subperíodo Asia (hora:minutos)
input color input_color_rect_sub_asia = clrLightBlue; // Color del rectángulo del subperíodo Asia

input group "03. CONFIGURACION";

input int ajuste_horario = 7; // Ajuste horario (diferencia entre servidor y NY, en horas)
input bool debug_hora = true; // Debug Hora NY

input string CandleSettings = "------- Configuración del Patrón de Velas -------"; // Separador visual
input ENUM_TIMEFRAMES CandleTimeframe = PERIOD_M5; // Periodo de tiempo para analizar las velas



datetime lastCandleTime = 0;                // Almacena el tiempo de la última vela analizada
bool patternDetected = false;               // Indica si se detectó el patrón de velas
input bool EnableTrading = true;           // Activa o desactiva completamente la operativa del EA
ENUM_POSITION_TYPE lastPatternDirection = POSITION_TYPE_BUY; // Dirección del último patrón detectado
ulong lastTicket = 0;                       // Guarda el número de ticket de la posición abierta actual



// --- VARIABLES INTERNAS/GLOBALES ---

// Variables de ajuste horario y tiempo del servidor
int ajuste_tiempo; // Ajuste horario calculado (en segundos)
datetime hora_servidor; // Hora actual del servidor
datetime hora_actual_servidor; // Hora ajustada a NY
datetime hora_inicio_newY; // Hora de inicio de la sesión de NY (servidor)
datetime hora_fin_newY; // Hora de fin de la sesión de NY (servidor)

// Variables para descomposición de horas (usadas por SepararHoraMinuto)
int input_ny_desde_hora; // Inicio horario NY (hora)
int input_ny_desde_minuto; // Inicio horario NY (minuto)
int input_ny_hasta_hora; // Fin horario NY (hora)
int input_ny_hasta_minuto; // Fin horario NY (minuto)
int input_ny_sub_desde_hora; // Inicio subperíodo NY (hora)
int input_ny_sub_desde_minuto; // Inicio subperíodo NY (minuto)
int input_ny_sub_hasta_hora; // Fin subperíodo NY (hora)
int input_ny_sub_hasta_minuto; // Fin subperíodo NY (minuto)

int input_londres_desde_hora; // Inicio horario Londres (hora)
int input_londres_desde_minuto; // Inicio horario Londres (minuto)
int input_londres_hasta_hora; // Fin horario Londres (hora)
int input_londres_hasta_minuto; // Fin horario Londres (minuto)
int input_londres_sub_desde_hora; // Inicio subperíodo Londres (hora)
int input_londres_sub_desde_minuto; // Inicio subperíodo Londres (minuto)
int input_londres_sub_hasta_hora; // Fin subperíodo Londres (hora)
int input_londres_sub_hasta_minuto; // Fin subperíodo Londres (minuto)

int input_asia_desde_hora; // Inicio horario Asia (hora)
int input_asia_desde_minuto; // Inicio horario Asia (minuto)
int input_asia_hasta_hora; // Fin horario Asia (hora)
int input_asia_hasta_minuto; // Fin horario Asia (minuto)
int input_asia_sub_desde_hora; // Inicio subperíodo Asia (hora)
int input_asia_sub_desde_minuto; // Inicio subperíodo Asia (minuto)
int input_asia_sub_hasta_hora; // Fin subperíodo Asia (hora)
int input_asia_sub_hasta_minuto; // Fin subperíodo Asia (minuto)

int hora_nya; // Variable para almacenar la hora (NY)
int minuto_nya; // Variable para almacenar los minutos (NY)

// Variables para la gestión de velas M1
datetime currentCandleTime = 0; // Tiempo de la vela M1 actual
datetime firstTimeOfCandle = 0; // Inicio de la vela M1
datetime lastTimeOfCandle = 0;  // Fin de la vela M1
double maxValueOfCandle = -DBL_MAX; // Valor máximo de la vela M1
double minValueOfCandle = DBL_MAX;  // Valor mínimo de la vela M1

// Variables para la sesión principal de Nueva York
datetime sessionStartTimeNY = 0;    // Tiempo de inicio de la sesión principal NY
datetime sessionEndTimeNY = 0;      // Tiempo de fin de la sesión principal NY
double sessionMaxValueNY = -DBL_MAX; // Valor máximo de la sesión principal NY
double sessionMinValueNY = DBL_MAX;  // Valor mínimo de la sesión principal NY
string rectNameNY = "";              // Nombre del rectángulo principal NY
bool sessionActiveNY = false;        // Indica si la sesión principal NY está activa
bool rectDrawnNY = false;            // Indica si el rectángulo principal NY ya fue creado
string labelMaxMainNameNY = "";      // Nombre de la etiqueta del máximo (rectángulo principal NY)
string labelMinMainNameNY = "";      // Nombre de la etiqueta del mínimo (rectángulo principal NY)

// Variables para el subperíodo de Nueva York
datetime subSessionStartTimeNY = 0;    // Tiempo de inicio del subperíodo NY
datetime subSessionEndTimeNY = 0;      // Tiempo de fin del subperíodo NY
double subSessionMaxValueNY = -DBL_MAX; // Valor máximo del subperíodo NY
double subSessionMinValueNY = DBL_MAX;  // Valor mínimo del subperíodo NY
string subRectNameNY = "";              // Nombre del rectángulo del subperíodo NY
bool subSessionActiveNY = false;        // Indica si el subperíodo NY está activo
bool subRectDrawnNY = false;            // Indica si el rectángulo del subperíodo NY ya fue creado

// Variables para la sesión principal de Londres
datetime sessionStartTimeLondon = 0;    // Tiempo de inicio de la sesión principal Londres
datetime sessionEndTimeLondon = 0;      // Tiempo de fin de la sesión principal Londres
double sessionMaxValueLondon = -DBL_MAX; // Valor máximo de la sesión principal Londres
double sessionMinValueLondon = DBL_MAX;  // Valor mínimo de la sesión principal Londres
string rectNameLondon = "";              // Nombre del rectángulo principal Londres
bool sessionActiveLondon = false;        // Indica si la sesión principal Londres está activa
bool rectDrawnLondon = false;            // Indica si el rectángulo principal Londres ya fue creado
string labelMaxMainNameLondon = "";      // Nombre de la etiqueta del máximo (rectángulo principal Londres)
string labelMinMainNameLondon = "";      // Nombre de la etiqueta del mínimo (rectángulo principal Londres)

// Variables para el subperíodo de Londres
datetime subSessionStartTimeLondon = 0;    // Tiempo de inicio del subperíodo Londres
datetime subSessionEndTimeLondon = 0;      // Tiempo de fin del subperíodo Londres
double subSessionMaxValueLondon = -DBL_MAX; // Valor máximo del subperíodo Londres
double subSessionMinValueLondon = DBL_MAX;  // Valor mínimo del subperíodo Londres
string subRectNameLondon = "";              // Nombre del rectángulo del subperíodo Londres
bool subSessionActiveLondon = false;        // Indica si el subperíodo Londres está activo
bool subRectDrawnLondon = false;            // Indica si el rectángulo del subperíodo Londres ya fue creado

// Variables para la sesión principal de Tokio (Asia)
datetime sessionStartTimeAsia = 0;    // Tiempo de inicio de la sesión principal Asia
datetime sessionEndTimeAsia = 0;      // Tiempo de fin de la sesión principal Asia
double sessionMaxValueAsia = -DBL_MAX; // Valor máximo de la sesión principal Asia
double sessionMinValueAsia = DBL_MAX;  // Valor mínimo de la sesión principal Asia
string rectNameAsia = "";              // Nombre del rectángulo principal Asia
bool sessionActiveAsia = false;        // Indica si la sesión principal Asia está activa
bool rectDrawnAsia = false;            // Indica si el rectángulo principal Asia ya fue creado
string labelMaxMainNameAsia = "";      // Nombre de la etiqueta del máximo (rectángulo principal Asia)
string labelMinMainNameAsia = "";      // Nombre de la etiqueta del mínimo (rectángulo principal Asia)

// Variables para el subperíodo de Tokio (Asia)
datetime subSessionStartTimeAsia = 0;    // Tiempo de inicio del subperíodo Asia
datetime subSessionEndTimeAsia = 0;      // Tiempo de fin del subperíodo Asia
double subSessionMaxValueAsia = -DBL_MAX; // Valor máximo del subperíodo Asia
double subSessionMinValueAsia = DBL_MAX;  // Valor mínimo del subperíodo Asia
string subRectNameAsia = "";              // Nombre del rectángulo del subperíodo Asia
bool subSessionActiveAsia = false;        // Indica si el subperíodo Asia está activo
bool subRectDrawnAsia = false;            // Indica si el rectángulo del subperíodo Asia ya fue creado

// Variables para la gestión de sesiones (estado de inicio/fin)
bool sesion_asia_iniciada = true;
bool sesion_asia_finalizada = false;
bool sesion_ny_iniciada = true;
bool sesion_ny_finalizada = false;
bool sesion_londres_iniciada = true;
bool sesion_londres_finalizada = false;
bool isTrueNY = false;

// Variables para la operativa global (indicadores de sesiones activas)
bool global_operar_asia;
bool global_operar_londres;
bool global_operar_ny;

string operationStatus = "Identificando Operación"; // Estado inicial
string operationLabelName = "OperationStatusLabel"; // Nombre del label para el estado

// Variable para la gestión de días
datetime currentSessionDay = 0; // Día actual de la sesión (para detectar cambio de día)

// Variables para rastrear el día de inicio de cada sesión
datetime sessionStartDayNY = 0;    // Día de inicio de la sesión de Nueva York
datetime sessionStartDayLondon = 0; // Día de inicio de la sesión de Londres
datetime sessionStartDayAsia = 0;   // Día de inicio de la sesión de Tokio (Asia)

// Variables para rastrear los valores máximos y mínimos de los recuadros principales anteriores
double lastMaxValueNY = -DBL_MAX;  // Máximo del último recuadro principal de Nueva York
double lastMinValueNY = DBL_MAX;   // Mínimo del último recuadro principal de Nueva York
datetime lastEndTimeNY = 0;        // Tiempo de fin del último recuadro principal de Nueva York
bool nyMaxBroken = false;          // Indica si el máximo de NY ya fue roto
bool nyMinBroken = false;          // Indica si el mínimo de NY ya fue roto
bool breakoutNY = false;      // Indica si ha ocurrido un rompimiento en la sesión de Nueva York
bool breakoutLondon = false;  // Indica si ha ocurrido un rompimiento en la sesión de Londres
bool breakoutAsia = false;    // Indica si ha ocurrido un rompimiento en la sesión de Asia

double lastMaxValueLondon = -DBL_MAX;  // Máximo del último recuadro principal de Londres
double lastMinValueLondon = DBL_MAX;   // Mínimo del último recuadro principal de Londres
datetime lastEndTimeLondon = 0;        // Tiempo de fin del último recuadro principal de Londres
bool londonMaxBroken = false;          // Indica si el máximo de Londres ya fue roto
bool londonMinBroken = false;          // Indica si el mínimo de Londres ya fue roto

double lastMaxValueAsia = -DBL_MAX;  // Máximo del último recuadro principal de Tokio (Asia)
double lastMinValueAsia = DBL_MAX;   // Mínimo del último recuadro principal de Tokio (Asia)
datetime lastEndTimeAsia = 0;        // Tiempo de fin del último recuadro principal de Tokio (Asia)
bool asiaMaxBroken = false;          // Indica si el máximo de Tokio ya fue roto
bool asiaMinBroken = false;          // Indica si el mínimo de Tokio ya fue roto

bool labelDrawnNY = false;          // Indica si la etiqueta de tendencia contraria ya fue dibujada para NY
bool labelDrawnLondon = false;      // Indica si la etiqueta de tendencia contraria ya fue dibujada para Londres
bool labelDrawnAsia = false;        // Indica si la etiqueta de tendencia contraria ya fue dibujada para Asia

// Contador para nombres únicos de etiquetas
int breakLabelCounter = 0;

// Variables para detectar tendencia contraria después de un rompimiento
bool contraryTrendNY = false;       // Indica si hay tendencia contraria en NY
bool contraryTrendLondon = false;   // Indica si hay tendencia contraria en Londres
bool contraryTrendAsia = false;     // Indica si hay tendencia contraria en Asia

double breakPriceNY = 0;            // Precio en el momento del rompimiento NY
datetime breakTimeNY = 0;           // Tiempo del rompimiento NY
double breakPriceLondon = 0;        // Precio en el momento del rompimiento Londres
datetime breakTimeLondon = 0;       // Tiempo del rompimiento Londres
double breakPriceAsia = 0;          // Precio en el momento del rompimiento Asia
datetime breakTimeAsia = 0;         // Tiempo del rompimiento Asia

input double reversalThreshold = 20; // Umbral de reversión en pips






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


// --- FUNCIONES AUXILIARES ---

int GetNewYorkTime()
{
    // Obtener la hora actual del servidor
    datetime serverTime = TimeCurrent();
    // Obtener la hora GMT
    datetime gmtTime = TimeGMT();
    
    
    // Calcular el desplazamiento de Nueva York respecto a GMT
    int nyOffset = -5 * 3600; // Ajuste base para NY (-5 horas en segundos)
    
    // Determinar si NY está en horario de verano (DST)
    MqlDateTime serverDate;
    TimeToStruct(serverTime, serverDate);
    bool isDST = IsNewYorkDST(serverDate.mon, serverDate.day, serverDate.day_of_week);
    if (isDST)
    {
        nyOffset = -4 * 3600; // Ajuste para horario de verano (-4 horas en segundos)
    }
    
    // CORECCIÓN: Incorporar el ajuste horario del usuario
    // ajuste_horario debería estar en horas, convertir a segundos
    int userGMTOffset = ajuste_horario * 3600;
    
    // Calcular el ajuste necesario para convertir la hora del servidor a hora de NY
    // Ahora consideramos: NY_offset - Server_offset - User_GMT_offset
    int adjustment = nyOffset - userGMTOffset;
    
    return adjustment;
}

// int GetNewYorkTime()
// {
//     // Obtener la hora actual del servidor
//     datetime serverTime = TimeCurrent();
//     // Obtener la hora GMT
//     datetime gmtTime = TimeGMT();
//     // Calcular el desplazamiento del servidor respecto a GMT (en segundos)
//     int serverOffset = (int)(serverTime - gmtTime);
//     // Calcular el desplazamiento de Nueva York respecto a GMT (NY está a -5 horas de GMT, o -4 durante horario de verano)
//     int nyOffset = -5 * 3600; // Ajuste base para NY (-5 horas en segundos)
//     // Determinar si NY está en horario de verano (DST)
//     MqlDateTime serverDate;
//     TimeToStruct(serverTime, serverDate);
//     bool isDST = IsNewYorkDST(serverDate.mon, serverDate.day, serverDate.day_of_week);
//     if (isDST)
//     {
//         nyOffset = -4 * 3600; // Ajuste para horario de verano (-4 horas en segundos)
//     }
//     // Calcular el ajuste necesario para convertir la hora del servidor a hora de NY
//     int adjustment = nyOffset - serverOffset;
//     return adjustment;
// }

// bool IsNewYorkDST(int month, int day, int dayOfWeek)
// {
//     // Horario de verano en Nueva York (generalmente del segundo domingo de marzo al primer domingo de noviembre)
//     if (month < 3 || month > 11) return false; // Antes de marzo o después de noviembre: no DST
//     if (month > 3 && month < 11) return true;  // Entre abril y octubre: DST activo

//     // Calcular el segundo domingo de marzo
//     int secondSundayMarch = 14 - (dayOfWeek + 6) % 7; // Segundo domingo de marzo
//     // Calcular el primer domingo de noviembre
//     int firstSundayNovember = 7 - (dayOfWeek + 6) % 7; // Primer domingo de noviembre

//     if (month == 3)
//     {
//         if (day < secondSundayMarch) return false;
//         if (day > secondSundayMarch) return true;
//         return (dayOfWeek == 0 && day == secondSundayMarch); // Inicia el DST el segundo domingo
//     }

//     if (month == 11)
//     {
//         if (day < firstSundayNovember) return true;
//         if (day > firstSundayNovember) return false;
//         return (dayOfWeek != 0 || day != firstSundayNovember); // Termina el DST el primer domingo
//     }

//     return false;
// }

bool IsNewYorkDST(int month, int day, int dayOfWeek)
{
    // Horario de verano en Nueva York: segundo domingo de marzo al primer domingo de noviembre
    if (month < 3 || month > 11) return false; // Fuera del rango posible
    if (month > 3 && month < 11) return true;  // Definitivamente en DST
    
    if (month == 3) // Marzo
    {
        // Encontrar el segundo domingo de marzo
        // Primer domingo: día 1-7 dependiendo del día de la semana del día 1
        // Si el día 1 es domingo (dayOfWeek=0), el primer domingo es el día 1
        // Si el día 1 es lunes (dayOfWeek=1), el primer domingo es el día 7
        // Fórmula: primer domingo = 8 - dayOfWeek (donde dayOfWeek del día 1)
        
        // Para el día actual, necesitamos encontrar qué domingo es
        int daysFromFirstSunday = (day - 1 + (7 - dayOfWeek)) % 7;
        int firstSunday = day - daysFromFirstSunday;
        int secondSunday = firstSunday + 7;
        
        // Si estamos en o después del segundo domingo
        return day >= secondSunday;
    }
    
    if (month == 11) // Noviembre
    {
        // Encontrar el primer domingo de noviembre
        int daysFromSunday = (day - 1 + (7 - dayOfWeek)) % 7;
        int firstSunday = day - daysFromSunday;
        
        // DST termina el primer domingo, así que antes de esa fecha aún hay DST
        return day < firstSunday;
    }
    
    return false;
}

void SepararHoraMinuto(string hora, int &hora_out, int &minuto_out)
{
    string partes[];
    int partes_count = StringSplit(hora, ':', partes);
    if (partes_count != 2)
    {
        Print("Error: Formato de hora inválido (", hora, "). Se esperaba 'hora:minuto'. Usando valor por defecto.");
        hora_out = 0;
        minuto_out = 0;
        return;
    }

    hora_out = (int)StringToInteger(partes[0]);
    minuto_out = (int)StringToInteger(partes[1]);

    if (hora_out < 0 || hora_out > 23 || minuto_out < 0 || minuto_out > 59)
    {
        Print("Error: Hora o minuto fuera de rango (", hora, "). Usando valor por defecto.");
        hora_out = 0;
        minuto_out = 0;
    }
}

void CalculateSessionMaxMin(datetime startTime, datetime endTime, double &maxValue, double &minValue)
{
    int startBar = iBarShift(Symbol(), PERIOD_M1, startTime, true);
    int endBar = iBarShift(Symbol(), PERIOD_M1, endTime, true);

    if (startBar == -1 || endBar == -1)
    {
        Print("Error: No se encontraron barras para el rango de tiempo especificado.");
        return;
    }

    if (startBar < endBar)
    {
        int temp = startBar;
        startBar = endBar;
        endBar = temp;
    }

    for (int i = endBar; i <= startBar; i++)
    {
        double high = iHigh(Symbol(), PERIOD_M1, i);
        double low = iLow(Symbol(), PERIOD_M1, i);

        if (high > maxValue) maxValue = high;
        if (low < minValue) minValue = low;
    }
}

void UpdatePriceLabels(string labelName, string text, datetime time, double price, color labelColor)
{
    if (ObjectFind(0, labelName) < 0)
    {
        ObjectCreate(0, labelName, OBJ_TEXT, 0, time, price);
        ObjectSetInteger(0, labelName, OBJPROP_COLOR, labelColor);
        ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 8);
        ObjectSetString(0, labelName, OBJPROP_FONT, "Arial");
        ObjectSetInteger(0, labelName, OBJPROP_ANCHOR, ANCHOR_LEFT);
    }

    ObjectSetString(0, labelName, OBJPROP_TEXT, text);
    ObjectSetDouble(0, labelName, OBJPROP_PRICE, price);
    ObjectSetInteger(0, labelName, OBJPROP_TIME, time);
}

bool ComprobarSesionOperativa()
{
    // Separar y validar las horas de inicio y fin
    SepararHoraMinuto(input_ny_hora, input_ny_desde_hora, input_ny_desde_minuto);
    SepararHoraMinuto(hasta_ny_hora, input_ny_hasta_hora, input_ny_hasta_minuto);
    SepararHoraMinuto(input_ny_sub_hora, input_ny_sub_desde_hora, input_ny_sub_desde_minuto);
    SepararHoraMinuto(hasta_ny_sub_hora, input_ny_sub_hasta_hora, input_ny_sub_hasta_minuto);
    SepararHoraMinuto(input_londres_hora, input_londres_desde_hora, input_londres_desde_minuto);
    SepararHoraMinuto(hasta_londres_hora, input_londres_hasta_hora, input_londres_hasta_minuto);
    SepararHoraMinuto(input_londres_sub_hora, input_londres_sub_desde_hora, input_londres_sub_desde_minuto);
    SepararHoraMinuto(hasta_londres_sub_hora, input_londres_sub_hasta_hora, input_londres_sub_hasta_minuto);
    SepararHoraMinuto(input_asia_hora, input_asia_desde_hora, input_asia_desde_minuto);
    SepararHoraMinuto(hasta_asia_hora, input_asia_hasta_hora, input_asia_hasta_minuto);
    SepararHoraMinuto(input_asia_sub_hora, input_asia_sub_desde_hora, input_asia_sub_desde_minuto);
    SepararHoraMinuto(hasta_asia_sub_hora, input_asia_sub_hasta_hora, input_asia_sub_hasta_minuto);

    MqlDateTime fecha_hora_ny;
    TimeToStruct(hora_actual_servidor, fecha_hora_ny);

    int hora_ny = fecha_hora_ny.hour;
    int minuto_ny = fecha_hora_ny.min;
    int segundo_ny = fecha_hora_ny.sec;
    int dia_semana_ny = fecha_hora_ny.day_of_week;

    // Calcular el tiempo actual en segundos desde el inicio del día (para comparar con cruce de días)
    int currentSecondsNY = (hora_ny * 3600) + (minuto_ny * 60) + segundo_ny;
    int asiaStartSeconds = (input_asia_desde_hora * 3600) + (input_asia_desde_minuto * 60);
    int asiaEndSeconds = (input_asia_hasta_hora * 3600) + (input_asia_hasta_minuto * 60);

    // Sesión de Tokio (Asia) - Manejar cruce de días
    bool sesion_asia = false;
    if (dia_semana_ny >= 0 && dia_semana_ny <= 6)
    {
        if (input_asia_hasta_hora < input_asia_desde_hora || (input_asia_hasta_hora == input_asia_desde_hora && input_asia_hasta_minuto < input_asia_desde_minuto))
        {
            // Cruce de días: la sesión termina el día siguiente
            if (currentSecondsNY >= asiaStartSeconds || currentSecondsNY <= asiaEndSeconds)
            {
                sesion_asia = true;
            }
        }
        else
        {
            // Sin cruce de días
            sesion_asia = (currentSecondsNY >= asiaStartSeconds && currentSecondsNY <= asiaEndSeconds);
        }
    }

    // Sesión de Londres
    bool sesion_londres = (dia_semana_ny >= 0 && dia_semana_ny <= 6) &&
                          ((hora_ny > input_londres_desde_hora ||
                            (hora_ny == input_londres_desde_hora && minuto_ny >= input_londres_desde_minuto)) &&
                           (hora_ny < input_londres_hasta_hora ||
                            (hora_ny == input_londres_hasta_hora && minuto_ny < input_londres_hasta_minuto)));

    // Sesión de Nueva York
    bool sesion_ny = (dia_semana_ny >= 0 && dia_semana_ny <= 6) &&
                     ((hora_ny > input_ny_desde_hora ||
                       (hora_ny == input_ny_desde_hora && minuto_ny >= input_ny_desde_minuto)) &&
                      (hora_ny < input_ny_hasta_hora ||
                       (hora_ny == input_ny_hasta_hora && minuto_ny < input_ny_hasta_minuto)));

    datetime hora_servidor_ajustada = hora_servidor - 3600;

    if (debug_hora)
    {
        string hora_formateada = StringFormat("%02d:%02d:%02d", hora_ny, minuto_ny, segundo_ny);
        Print("Sesión de Nueva York activa. Hora NY: ", hora_formateada, " Día de la semana: ", dia_semana_ny, 
              " | Hora Servidor: ", TimeToString(hora_servidor_ajustada, TIME_DATE | TIME_MINUTES | TIME_SECONDS));
    }

    if (!sesion_asia_iniciada && sesion_asia)
    {
        if (input_operativa_asia)
        {
            Print("----------| Sesion de Asia Iniciada |----------");
        }
        sesion_asia_iniciada = true;
        sesion_asia_finalizada = false;
    }

    if (!sesion_asia_finalizada && !sesion_asia)
    {
        if (input_operativa_asia)
        {
            Print("----------| Sesion de Asia Finalizada |----------");
        }
        sesion_asia_finalizada = true;
        sesion_asia_iniciada = false;
    }

    if (!sesion_londres_iniciada && sesion_londres)
    {
        if (input_operativa_londres)
        {
            Print("----------| Sesion de Londres Iniciada |----------");
        }
        sesion_londres_finalizada = false;
        sesion_londres_iniciada = true;
    }

    if (!sesion_londres_finalizada && !sesion_londres)
    {
        if (input_operativa_londres)
        {
            Print("----------| Sesion de Londres Finalizada |----------");
        }
        sesion_londres_finalizada = true;
        sesion_londres_iniciada = false;
    }

    if (!sesion_ny_iniciada && sesion_ny)
    {
        if (input_operativa_newyork)
        {
            isTrueNY = true;
            hora_inicio_newY = hora_servidor;
            Print("----------| Sesion de Nueva York Iniciada |---------- Hora NY: ", 
                  TimeToString(hora_actual_servidor, TIME_DATE | TIME_MINUTES | TIME_SECONDS), 
                  " | Hora Servidor: ", 
                  TimeToString(hora_servidor_ajustada, TIME_DATE | TIME_MINUTES | TIME_SECONDS));
        }
        sesion_ny_finalizada = false;
        sesion_ny_iniciada = true;
    }

    if (!sesion_ny_finalizada && !sesion_ny)
    {
        if (input_operativa_newyork)
        {
            isTrueNY = false;
            Print("----------| Sesion de NY Finalizada |---------- Hora NY: ", 
                  TimeToString(hora_actual_servidor, TIME_DATE | TIME_MINUTES | TIME_SECONDS), 
                  " | Hora Servidor: ", 
                  TimeToString(hora_servidor_ajustada, TIME_DATE | TIME_MINUTES | TIME_SECONDS));
            hora_fin_newY = hora_servidor;
        }
        sesion_ny_finalizada = true;
        sesion_ny_iniciada = false;
    }
    return sesion_ny;
}



// bool DetectContraryTrend(double breakPrice, double currentPrice, bool maxBroken, double thresholdPips)
// {
//     double pipValue = SymbolInfoDouble(Symbol(), SYMBOL_POINT) * 10; // Valor de 1 pip
//     double priceDiff = (currentPrice - breakPrice) / pipValue; // Diferencia en pips

//     if (maxBroken)
//     {
//         // Rompimiento del máximo: verificar si el precio cae (tendencia bajista)
//         if (currentPrice < breakPrice && MathAbs(priceDiff) >= thresholdPips)
//         {
//             return true; // Tendencia contraria detectada (bajada tras romper máximo)
//         }
//     }
//     else
//     {
//         // Rompimiento del mínimo: verificar si el precio sube (tendencia alcista)
//         if (currentPrice > breakPrice && MathAbs(priceDiff) >= thresholdPips)
//         {
//             return true; // Tendencia contraria detectada (subida tras romper mínimo)
//         }
//     }
//     return false;
// }

// Reemplazar la función DetectContraryTrend
bool DetectContraryTrend(double breakPrice, double currentPrice, bool maxBroken, double thresholdPips)
{
    // No se usa thresholdPips en la nueva lógica, mantenido por compatibilidad
    int currentShift = 0; // Vela actual
    return DetectContraryCandlePattern(maxBroken, currentShift);
}


// Función para verificar si una vela tiene cuerpo mayor que las mechas
bool IsBodyLargerThanWicks(int shift)
{
    double open = iOpen(Symbol(), PERIOD_M1, shift);
    double close = iClose(Symbol(), PERIOD_M1, shift);
    double high = iHigh(Symbol(), PERIOD_M1, shift);
    double low = iLow(Symbol(), PERIOD_M1, shift);
    
    double body = MathAbs(close - open); // Tamaño del cuerpo
    double upperWick = high - MathMax(open, close); // Mecha superior
    double lowerWick = MathMin(open, close) - low; // Mecha inferior
    
    // Verificar si el cuerpo es mayor que ambas mechas
    return body > upperWick && body > lowerWick;
}

// Función para detectar tendencia contraria basada en dos velas consecutivas
bool DetectContraryCandlePattern(bool maxBroken, int shift)
{
    // Verificar las últimas dos velas (shift y shift+1)
    if (shift + 1 >= iBars(Symbol(), PERIOD_M1)) return false; // Asegurar que hay suficientes velas
    
    bool candle1Valid = IsBodyLargerThanWicks(shift);
    bool candle2Valid = IsBodyLargerThanWicks(shift + 1);
    
    if (!candle1Valid || !candle2Valid) return false;
    
    // Determinar la dirección de las velas
    double close1 = iClose(Symbol(), PERIOD_M1, shift);
    double open1 = iOpen(Symbol(), PERIOD_M1, shift);
    double close2 = iClose(Symbol(), PERIOD_M1, shift + 1);
    double open2 = iOpen(Symbol(), PERIOD_M1, shift + 1);
    
    bool isBearish1 = close1 < open1;
    bool isBullish1 = close1 > open1;
    bool isBearish2 = close2 < open2;
    bool isBullish2 = close2 > open2;
    
    // Si el rompimiento fue del máximo, buscamos dos velas bajistas
    if (maxBroken)
    {
        return isBearish1 && isBearish2;
    }
    // Si el rompimiento fue del mínimo, buscamos dos velas alcistas
    else
    {
        return isBullish1 && isBullish2;
    }
}

// Función para actualizar el label del estado de operación
void UpdateOperationStatusLabel(string status, datetime time, double price)
{
    operationStatus = status;
    
    if (ObjectFind(0, operationLabelName) < 0)
    {
        ObjectCreate(0, operationLabelName, OBJ_LABEL, 0, 0, 0);
        ObjectSetInteger(0, operationLabelName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
        ObjectSetInteger(0, operationLabelName, OBJPROP_XDISTANCE, 10);
        ObjectSetInteger(0, operationLabelName, OBJPROP_YDISTANCE, 10);
        ObjectSetInteger(0, operationLabelName, OBJPROP_COLOR, clrWhite);
        ObjectSetInteger(0, operationLabelName, OBJPROP_FONTSIZE, 10);
        ObjectSetString(0, operationLabelName, OBJPROP_FONT, "Arial");
    }
    
    ObjectSetString(0, operationLabelName, OBJPROP_TEXT, "Estado Operación: " + status);
    ChartRedraw();
}


// --- EVENTOS DEL EA ---

int OnInit()
{
    // Inicialización existente
    Print("EA inicializado correctamente.");
    hora_servidor = TimeCurrent();
    datetime serverTime = TimeCurrent();
    datetime gmtTime = TimeGMT();
    int chartOffset = (int)(serverTime - gmtTime) / 3600;
    Print("Desplazamiento horario del servidor respecto a GMT: ", chartOffset, " horas");
    ajuste_tiempo = GetNewYorkTime();
    Print("Ajuste tiempo calculado: ", ajuste_tiempo, " segundos (", ajuste_tiempo / 3600.0, " horas)");
    EventSetTimer(1);
    
    // Inicializar el label de estado
    UpdateOperationStatusLabel("Identificando Operación", hora_servidor, SymbolInfoDouble(Symbol(), SYMBOL_BID));
    
    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{

    // Eliminación del label de estado al detener el EA
    ObjectDelete(0, operationLabelName);

    // Fijar el rectángulo principal de Nueva York si la sesión está activa al detener el EA
    if (sessionActiveNY && ObjectFind(0, rectNameNY) >= 0)
    {
        ObjectSetInteger(0, rectNameNY, OBJPROP_TIME, 1, sessionEndTimeNY - ajuste_tiempo);
        ObjectSetDouble(0, rectNameNY, OBJPROP_PRICE, 0, sessionMaxValueNY);
        ObjectSetDouble(0, rectNameNY, OBJPROP_PRICE, 1, sessionMinValueNY);
        ChartRedraw();
    }

    // Fijar el rectángulo del subperíodo de Nueva York si está activo
    if (subSessionActiveNY && ObjectFind(0, subRectNameNY) >= 0)
    {
        ObjectSetInteger(0, subRectNameNY, OBJPROP_TIME, 1, subSessionEndTimeNY - ajuste_tiempo);
        ObjectSetDouble(0, subRectNameNY, OBJPROP_PRICE, 0, subSessionMaxValueNY);
        ObjectSetDouble(0, subRectNameNY, OBJPROP_PRICE, 1, subSessionMinValueNY);
        ChartRedraw();
    }

    // Fijar el rectángulo principal de Londres si la sesión está activa al detener el EA
    if (sessionActiveLondon && ObjectFind(0, rectNameLondon) >= 0)
    {
        ObjectSetInteger(0, rectNameLondon, OBJPROP_TIME, 1, sessionEndTimeLondon - ajuste_tiempo);
        ObjectSetDouble(0, rectNameLondon, OBJPROP_PRICE, 0, sessionMaxValueLondon);
        ObjectSetDouble(0, rectNameLondon, OBJPROP_PRICE, 1, sessionMinValueLondon);
        ChartRedraw();
    }

    // Fijar el rectángulo del subperíodo de Londres si está activo
    if (subSessionActiveLondon && ObjectFind(0, subRectNameLondon) >= 0)
    {
        ObjectSetInteger(0, subRectNameLondon, OBJPROP_TIME, 1, subSessionEndTimeLondon - ajuste_tiempo);
        ObjectSetDouble(0, subRectNameLondon, OBJPROP_PRICE, 0, subSessionMaxValueLondon);
        ObjectSetDouble(0, subRectNameLondon, OBJPROP_PRICE, 1, subSessionMinValueLondon);
        ChartRedraw();
    }

    // Fijar el rectángulo principal de Tokio (Asia) si la sesión está activa al detener el EA
    if (sessionActiveAsia && ObjectFind(0, rectNameAsia) >= 0)
    {
        ObjectSetInteger(0, rectNameAsia, OBJPROP_TIME, 1, sessionEndTimeAsia - ajuste_tiempo);
        ObjectSetDouble(0, rectNameAsia, OBJPROP_PRICE, 0, sessionMaxValueAsia);
        ObjectSetDouble(0, rectNameAsia, OBJPROP_PRICE, 1, sessionMinValueAsia);
        ChartRedraw();
    }

    // Fijar el rectángulo del subperíodo de Tokio (Asia) si está activo
    if (subSessionActiveAsia && ObjectFind(0, subRectNameAsia) >= 0)
    {
        ObjectSetInteger(0, subRectNameAsia, OBJPROP_TIME, 1, subSessionEndTimeAsia - ajuste_tiempo);
        ObjectSetDouble(0, subRectNameAsia, OBJPROP_PRICE, 0, subSessionMaxValueAsia);
        ObjectSetDouble(0, subRectNameAsia, OBJPROP_PRICE, 1, subSessionMinValueAsia);
        ChartRedraw();
    }

    // No eliminamos las etiquetas de los rectángulos principales para que persistan

    Print("EA detenido. Razón: ", reason);
}

datetime tickTimeNY = hora_actual_servidor;
datetime tickTimeServer = TimeCurrent();

void OnTick()
{
    // Obtener la hora del tick actual (en horario del servidor)
    //datetime tickTimeServer = TimeCurrent();
    // Calcular la hora ajustada a NY
     //datetime tickTimeNY = tickTimeServer + ajuste_tiempo;



    // Obtener el día actual en horario de Nueva York (inicio del día)
    datetime currentDay = tickTimeNY - (tickTimeNY % 86400);

    // Verificar si hemos cambiado de día
    if (currentDay != currentSessionDay)
    {
        // Actualizar el día actual
        currentSessionDay = currentDay;
    }

    // --- Definir tiempos de inicio y fin para todas las sesiones (en horario de NY) ---

    // Nueva York (principal y subperíodo)
    if (!sessionActiveNY)
    {
        MqlDateTime timeStruct;
        TimeToStruct(tickTimeNY, timeStruct);
        int secondsSinceDayStart = (timeStruct.hour * 3600) + (timeStruct.min * 60) + timeStruct.sec;
        int nyStartSeconds = (input_ny_desde_hora * 3600) + (input_ny_desde_minuto * 60);

        // Si la hora actual es mayor o igual a la hora de inicio de NY, la sesión comienza hoy
        if (secondsSinceDayStart >= nyStartSeconds)
        {
            sessionStartDayNY = currentDay;
        }
        else
        {
            // Si no, la sesión comenzó el día anterior
            sessionStartDayNY = currentDay - 86400;
        }

        sessionStartTimeNY = sessionStartDayNY + (input_ny_desde_hora * 3600) + (input_ny_desde_minuto * 60);
        sessionEndTimeNY = sessionStartDayNY + (input_ny_hasta_hora * 3600) + (input_ny_hasta_minuto * 60);
        subSessionStartTimeNY = sessionStartDayNY + (input_ny_sub_desde_hora * 3600) + (input_ny_sub_desde_minuto * 60);
        subSessionEndTimeNY = sessionStartDayNY + (input_ny_sub_hasta_hora * 3600) + (input_ny_sub_hasta_minuto * 60);
    }

    // Londres (principal y subperíodo)
    if (!sessionActiveLondon)
    {
        MqlDateTime timeStruct;
        TimeToStruct(tickTimeNY, timeStruct);
        int secondsSinceDayStart = (timeStruct.hour * 3600) + (timeStruct.min * 60) + timeStruct.sec;
        int londonStartSeconds = (input_londres_desde_hora * 3600) + (input_londres_desde_minuto * 60);

        if (secondsSinceDayStart >= londonStartSeconds)
        {
            sessionStartDayLondon = currentDay;
        }
        else
        {
            sessionStartDayLondon = currentDay - 86400;
        }

        sessionStartTimeLondon = sessionStartDayLondon + (input_londres_desde_hora * 3600) + (input_londres_desde_minuto * 60);
        sessionEndTimeLondon = sessionStartDayLondon + (input_londres_hasta_hora * 3600) + (input_londres_hasta_minuto * 60);
        subSessionStartTimeLondon = sessionStartDayLondon + (input_londres_sub_desde_hora * 3600) + (input_londres_sub_desde_minuto * 60);
        subSessionEndTimeLondon = sessionStartDayLondon + (input_londres_sub_hasta_hora * 3600) + (input_londres_sub_hasta_minuto * 60);
    }

    // Tokio (Asia) (principal y subperíodo)
    if (!sessionActiveAsia)
    {
        MqlDateTime timeStruct;
        TimeToStruct(tickTimeNY, timeStruct);
        int secondsSinceDayStart = (timeStruct.hour * 3600) + (timeStruct.min * 60) + timeStruct.sec;
        int asiaStartSeconds = (input_asia_desde_hora * 3600) + (input_asia_desde_minuto * 60);
        int asiaEndSeconds = (input_asia_hasta_hora * 3600) + (input_asia_hasta_minuto * 60);

        if (input_asia_hasta_hora < input_asia_desde_hora || (input_asia_hasta_hora == input_asia_desde_hora && input_asia_hasta_minuto < input_asia_desde_minuto))
        {
            // Tokio cruza días
            if (secondsSinceDayStart >= asiaStartSeconds)
            {
                sessionStartDayAsia = currentDay;
            }
            else
            {
                sessionStartDayAsia = currentDay - 86400;
            }
        }
        else
        {
            if (secondsSinceDayStart >= asiaStartSeconds)
            {
                sessionStartDayAsia = currentDay;
            }
            else
            {
                sessionStartDayAsia = currentDay - 86400;
            }
        }

        sessionStartTimeAsia = sessionStartDayAsia + (input_asia_desde_hora * 3600) + (input_asia_desde_minuto * 60);
        if (input_asia_hasta_hora < input_asia_desde_hora || (input_asia_hasta_hora == input_asia_desde_hora && input_asia_hasta_minuto < input_asia_desde_minuto))
        {
            sessionEndTimeAsia = sessionStartDayAsia + 86400 + (input_asia_hasta_hora * 3600) + (input_asia_hasta_minuto * 60);
        }
        else
        {
            sessionEndTimeAsia = sessionStartDayAsia + (input_asia_hasta_hora * 3600) + (input_asia_hasta_minuto * 60);
        }

        subSessionStartTimeAsia = sessionStartDayAsia + (input_asia_sub_desde_hora * 3600) + (input_asia_sub_desde_minuto * 60);
        if (input_asia_sub_hasta_hora < input_asia_sub_desde_hora || (input_asia_sub_hasta_hora == input_asia_sub_desde_hora && input_asia_sub_hasta_minuto < input_asia_sub_desde_minuto))
        {
            subSessionEndTimeAsia = sessionStartDayAsia + 86400 + (input_asia_sub_hasta_hora * 3600) + (input_asia_sub_hasta_minuto * 60);
        }
        else
        {
            subSessionEndTimeAsia = sessionStartDayAsia + (input_asia_sub_hasta_hora * 3600) + (input_asia_sub_hasta_minuto * 60);
        }
    }

    // Convertir los tiempos de inicio y fin al horario del servidor para el dibujo
    // Nueva York
    datetime sessionStartTimeServerNY = sessionStartTimeNY - ajuste_tiempo;
    datetime sessionEndTimeServerNY = sessionEndTimeNY - ajuste_tiempo;
    datetime subSessionStartTimeServerNY = subSessionStartTimeNY - ajuste_tiempo;
    datetime subSessionEndTimeServerNY = subSessionEndTimeNY - ajuste_tiempo;

    // Londres
    datetime sessionStartTimeServerLondon = sessionStartTimeLondon - ajuste_tiempo;
    datetime sessionEndTimeServerLondon = sessionEndTimeLondon - ajuste_tiempo;
    datetime subSessionStartTimeServerLondon = subSessionStartTimeLondon - ajuste_tiempo;
    datetime subSessionEndTimeServerLondon = subSessionEndTimeLondon - ajuste_tiempo;

    // Tokio (Asia)
    datetime sessionStartTimeServerAsia = sessionStartTimeAsia - ajuste_tiempo;
    datetime sessionEndTimeServerAsia = sessionEndTimeAsia - ajuste_tiempo;
    datetime subSessionStartTimeServerAsia = subSessionStartTimeAsia - ajuste_tiempo;
    datetime subSessionEndTimeServerAsia = subSessionEndTimeAsia - ajuste_tiempo;

    // Verificar si estamos dentro de las sesiones (usando hora NY)
    MqlDateTime timeStruct;
    TimeToStruct(tickTimeNY, timeStruct);
    int hora_ny = timeStruct.hour;
    int minuto_ny = timeStruct.min;
    int dia_semana_ny = timeStruct.day_of_week;

    // Nueva York
    bool sesion_ny = (dia_semana_ny >= 0 && dia_semana_ny <= 6) &&
                    (tickTimeNY >= sessionStartTimeNY && tickTimeNY <= sessionEndTimeNY);
    bool sub_sesion_ny = (dia_semana_ny >= 0 && dia_semana_ny <= 6) &&
                         (tickTimeNY >= subSessionStartTimeNY && tickTimeNY <= subSessionEndTimeNY);
    bool sesion_ny_server = (tickTimeServer >= sessionStartTimeServerNY && tickTimeServer <= sessionEndTimeServerNY);
    bool sub_sesion_ny_server = (tickTimeServer >= subSessionStartTimeServerNY && tickTimeServer <= subSessionEndTimeServerNY);

    // Londres
    bool sesion_londres = (dia_semana_ny >= 0 && dia_semana_ny <= 6) &&
                          (tickTimeNY >= sessionStartTimeLondon && tickTimeNY <= sessionEndTimeLondon);
    bool sub_sesion_londres = (dia_semana_ny >= 0 && dia_semana_ny <= 6) &&
                              (tickTimeNY >= subSessionStartTimeLondon && tickTimeNY <= subSessionEndTimeLondon);
    bool sesion_londres_server = (tickTimeServer >= sessionStartTimeServerLondon && tickTimeServer <= sessionEndTimeServerLondon);
    bool sub_sesion_londres_server = (tickTimeServer >= subSessionStartTimeServerLondon && tickTimeServer <= subSessionEndTimeServerLondon);

    // Tokio (Asia)
    bool sesion_asia = (dia_semana_ny >= 0 && dia_semana_ny <= 6) &&
                       (tickTimeNY >= sessionStartTimeAsia && tickTimeNY <= sessionEndTimeAsia);
    bool sub_sesion_asia = (dia_semana_ny >= 0 && dia_semana_ny <= 6) &&
                           (tickTimeNY >= subSessionStartTimeAsia && tickTimeNY <= subSessionEndTimeAsia);
    bool sesion_asia_server = (tickTimeServer >= sessionStartTimeServerAsia && tickTimeServer <= sessionEndTimeServerAsia);
    bool sub_sesion_asia_server = (tickTimeServer >= subSessionStartTimeServerAsia && tickTimeServer <= subSessionEndTimeServerAsia);

    // Obtener el precio actual
    double valor = SymbolInfoDouble(Symbol(), SYMBOL_BID);

    // --- Dibujar el rectángulo principal (sesión de Nueva York) ---
    if (input_operativa_newyork && sesion_ny_server)
    {
        sessionActiveNY = true;

        // Calcular máximo y mínimo desde el inicio de la sesión hasta el momento actual
        if (!rectDrawnNY)
        {
            CalculateSessionMaxMin(sessionStartTimeServerNY, tickTimeServer, sessionMaxValueNY, sessionMinValueNY);
        }

        // Actualizar máximo y mínimo de la sesión con el precio actual
        if (valor > sessionMaxValueNY) sessionMaxValueNY = valor;
        if (valor < sessionMinValueNY) sessionMinValueNY = valor;

        // Crear el rectángulo principal al inicio de la sesión (solo una vez por día)
        if (!rectDrawnNY)
        {
            rectNameNY = "SessionRectNY_" + TimeToString(sessionStartTimeNY, TIME_DATE | TIME_MINUTES);
            labelMaxMainNameNY = "LabelMaxMainNY_" + TimeToString(sessionStartTimeNY, TIME_DATE | TIME_MINUTES);
            labelMinMainNameNY = "LabelMinMainNY_" + TimeToString(sessionStartTimeNY, TIME_DATE | TIME_MINUTES);

            if (sessionMaxValueNY != -DBL_MAX && sessionMinValueNY != DBL_MAX)
            {
                if (ObjectCreate(0, rectNameNY, OBJ_RECTANGLE, 0, sessionStartTimeServerNY, sessionMaxValueNY, tickTimeServer, sessionMinValueNY))
                {
                    ObjectSetInteger(0, rectNameNY, OBJPROP_COLOR, input_color_rect_main);
                    ObjectSetInteger(0, rectNameNY, OBJPROP_WIDTH, 2);
                    ObjectSetInteger(0, rectNameNY, OBJPROP_STYLE, STYLE_SOLID);
                    ObjectSetInteger(0, rectNameNY, OBJPROP_BACK, true);
                    rectDrawnNY = true;
                }
            }
        }

        // Actualizar el rectángulo principal y etiquetas en cada vela M1
        static datetime lastCandleTimeMainNY = 0;
        datetime candleTimeMainNY = iTime(Symbol(), PERIOD_M1, 0);
        if (candleTimeMainNY != lastCandleTimeMainNY)
        {
            if (ObjectFind(0, rectNameNY) >= 0) // Verificar que el rectángulo existe
            {
                if (sessionMaxValueNY != -DBL_MAX && sessionMinValueNY != DBL_MAX)
                {
                    ObjectSetDouble(0, rectNameNY, OBJPROP_PRICE, 0, sessionMaxValueNY); // Máximo
                    ObjectSetDouble(0, rectNameNY, OBJPROP_PRICE, 1, sessionMinValueNY); // Mínimo
                    ObjectSetInteger(0, rectNameNY, OBJPROP_TIME, 1, tickTimeServer); // Fin del rectángulo
                    ChartRedraw();

                    // Actualizar etiquetas del rectángulo principal
                    UpdatePriceLabels(labelMaxMainNameNY, "Max NY: " + DoubleToString(sessionMaxValueNY, _Digits), sessionEndTimeServerNY, sessionMaxValueNY, clrWhite);
                    UpdatePriceLabels(labelMinMainNameNY, "Min NY: " + DoubleToString(sessionMinValueNY, _Digits), sessionEndTimeServerNY, sessionMinValueNY, clrWhite);
                }
            }
            lastCandleTimeMainNY = candleTimeMainNY;
        }
    }
    else if (sessionActiveNY && tickTimeServer > sessionEndTimeServerNY)
    {
    // La sesión principal ha terminado, fijar el rectángulo
    sessionActiveNY = false;
    rectDrawnNY = false;
    if (ObjectFind(0, rectNameNY) >= 0)
    {
        ObjectSetInteger(0, rectNameNY, OBJPROP_TIME, 1, sessionEndTimeServerNY);
        ObjectSetDouble(0, rectNameNY, OBJPROP_PRICE, 0, sessionMaxValueNY);
        ObjectSetDouble(0, rectNameNY, OBJPROP_PRICE, 1, sessionMinValueNY);
        ChartRedraw();
    }
    // Actualizar valores de la última sesión
    lastMaxValueNY = sessionMaxValueNY;
    lastMinValueNY = sessionMinValueNY;
    lastEndTimeNY = sessionEndTimeServerNY;
    nyMaxBroken = false;
    nyMinBroken = false;
    breakoutNY = false;
    contraryTrendNY = false;  // Reiniciar tendencia contraria
    labelDrawnNY = false;     // Reiniciar bandera de dibujo
    breakPriceNY = 0;         // Reiniciar precio de rompimiento
    breakTimeNY = 0;          // Reiniciar tiempo de rompimiento
    Print("Sesión NY finalizada. lastMaxValueNY=", lastMaxValueNY, ", lastMinValueNY=", lastMinValueNY, ", lastEndTimeNY=", TimeToString(lastEndTimeNY));
    sessionMaxValueNY = -DBL_MAX;
    sessionMinValueNY = DBL_MAX;
    }

    // --- Dibujar el rectángulo del subperíodo (Nueva York) ---
    if (input_operativa_newyork && sub_sesion_ny_server)
    {
        subSessionActiveNY = true;

        // Calcular máximo y mínimo del subperíodo
        if (!subRectDrawnNY)
        {
            CalculateSessionMaxMin(subSessionStartTimeServerNY, tickTimeServer, subSessionMaxValueNY, subSessionMinValueNY);
        }

        // Actualizar máximo y mínimo del subperíodo con el precio actual
        if (valor > subSessionMaxValueNY) subSessionMaxValueNY = valor;
        if (valor < subSessionMinValueNY) subSessionMinValueNY = valor;

        // Crear el rectángulo del subperíodo (solo una vez por día)
        if (!subRectDrawnNY)
        {
            subRectNameNY = "SubSessionRectNY_" + TimeToString(subSessionStartTimeNY, TIME_DATE | TIME_MINUTES);

            if (subSessionMaxValueNY != -DBL_MAX && subSessionMinValueNY != DBL_MAX)
            {
                if (ObjectCreate(0, subRectNameNY, OBJ_RECTANGLE, 0, subSessionStartTimeServerNY, subSessionMaxValueNY, tickTimeServer, subSessionMinValueNY))
                {
                    ObjectSetInteger(0, subRectNameNY, OBJPROP_COLOR, input_color_rect_sub);
                    ObjectSetInteger(0, subRectNameNY, OBJPROP_WIDTH, 2);
                    ObjectSetInteger(0, subRectNameNY, OBJPROP_STYLE, STYLE_SOLID);
                    ObjectSetInteger(0, subRectNameNY, OBJPROP_BACK, true);
                    subRectDrawnNY = true;
                }
            }
        }

        // Actualizar el rectángulo del subperíodo en cada vela M1 (sin etiquetas)
        static datetime lastCandleTimeSubNY = 0;
        datetime candleTimeSubNY = iTime(Symbol(), PERIOD_M1, 0);
        if (candleTimeSubNY != lastCandleTimeSubNY)
        {
            if (ObjectFind(0, subRectNameNY) >= 0)
            {
                if (subSessionMaxValueNY != -DBL_MAX && subSessionMinValueNY != DBL_MAX)
                {
                    ObjectSetDouble(0, subRectNameNY, OBJPROP_PRICE, 0, subSessionMaxValueNY); // Máximo
                    ObjectSetDouble(0, subRectNameNY, OBJPROP_PRICE, 1, subSessionMinValueNY); // Mínimo
                    ObjectSetInteger(0, subRectNameNY, OBJPROP_TIME, 1, tickTimeServer); // Fin del rectángulo
                    ChartRedraw();
                }
            }
            lastCandleTimeSubNY = candleTimeSubNY;
        }
    }
    else if (subSessionActiveNY && tickTimeServer > subSessionEndTimeServerNY)
    {
        // El subperíodo ha terminado, fijar el rectángulo
        subSessionActiveNY = false;
        subRectDrawnNY = false;
        if (ObjectFind(0, subRectNameNY) >= 0)
        {
            ObjectSetInteger(0, subRectNameNY, OBJPROP_TIME, 1, subSessionEndTimeServerNY);
            ObjectSetDouble(0, subRectNameNY, OBJPROP_PRICE, 0, subSessionMaxValueNY);
            ObjectSetDouble(0, subRectNameNY, OBJPROP_PRICE, 1, subSessionMinValueNY);
            ChartRedraw();
        }
        subSessionMaxValueNY = -DBL_MAX;
        subSessionMinValueNY = DBL_MAX;
    }

    // --- Dibujar el rectángulo principal (sesión de Londres) ---
    if (input_operativa_londres && sesion_londres_server)
    {
        sessionActiveLondon = true;

        // Calcular máximo y mínimo desde el inicio de la sesión hasta el momento actual
        if (!rectDrawnLondon)
        {
            CalculateSessionMaxMin(sessionStartTimeServerLondon, tickTimeServer, sessionMaxValueLondon, sessionMinValueLondon);
        }

        // Actualizar máximo y mínimo de la sesión con el precio actual
        if (valor > sessionMaxValueLondon) sessionMaxValueLondon = valor;
        if (valor < sessionMinValueLondon) sessionMinValueLondon = valor;

        // Crear el rectángulo principal al inicio de la sesión (solo una vez por día)
        if (!rectDrawnLondon)
        {
            rectNameLondon = "SessionRectLondon_" + TimeToString(sessionStartTimeLondon, TIME_DATE | TIME_MINUTES);
            labelMaxMainNameLondon = "LabelMaxMainLondon_" + TimeToString(sessionStartTimeLondon, TIME_DATE | TIME_MINUTES);
            labelMinMainNameLondon = "LabelMinMainLondon_" + TimeToString(sessionStartTimeLondon, TIME_DATE | TIME_MINUTES);

            if (sessionMaxValueLondon != -DBL_MAX && sessionMinValueLondon != DBL_MAX)
            {
                if (ObjectCreate(0, rectNameLondon, OBJ_RECTANGLE, 0, sessionStartTimeServerLondon, sessionMaxValueLondon, tickTimeServer, sessionMinValueLondon))
                {
                    ObjectSetInteger(0, rectNameLondon, OBJPROP_COLOR, input_color_rect_main_londres);
                    ObjectSetInteger(0, rectNameLondon, OBJPROP_WIDTH, 2);
                    ObjectSetInteger(0, rectNameLondon, OBJPROP_STYLE, STYLE_SOLID);
                    ObjectSetInteger(0, rectNameLondon, OBJPROP_BACK, true);
                    rectDrawnLondon = true;
                }
            }
        }

        // Actualizar el rectángulo principal y etiquetas en cada vela M1
        static datetime lastCandleTimeMainLondon = 0;
        datetime candleTimeMainLondon = iTime(Symbol(), PERIOD_M1, 0);
        if (candleTimeMainLondon != lastCandleTimeMainLondon)
        {
            if (ObjectFind(0, rectNameLondon) >= 0) // Verificar que el rectángulo existe
            {
                if (sessionMaxValueLondon != -DBL_MAX && sessionMinValueLondon != DBL_MAX)
                {
                    ObjectSetDouble(0, rectNameLondon, OBJPROP_PRICE, 0, sessionMaxValueLondon); // Máximo
                    ObjectSetDouble(0, rectNameLondon, OBJPROP_PRICE, 1, sessionMinValueLondon); // Mínimo
                    ObjectSetInteger(0, rectNameLondon, OBJPROP_TIME, 1, tickTimeServer); // Fin del rectángulo
                    ChartRedraw();

                    // Actualizar etiquetas del rectángulo principal
                    UpdatePriceLabels(labelMaxMainNameLondon, "Max London: " + DoubleToString(sessionMaxValueLondon, _Digits), sessionEndTimeServerLondon, sessionMaxValueLondon, clrWhite);
                    UpdatePriceLabels(labelMinMainNameLondon, "Min London: " + DoubleToString(sessionMinValueLondon, _Digits), sessionEndTimeServerLondon, sessionMinValueLondon, clrWhite);
                }
            }
            lastCandleTimeMainLondon = candleTimeMainLondon;
        }
    }

    else if (sessionActiveLondon && tickTimeServer > sessionEndTimeServerLondon)
{
    // La sesión principal ha terminado, fijar el rectángulo
    sessionActiveLondon = false;
    rectDrawnLondon = false;
    if (ObjectFind(0, rectNameLondon) >= 0)
    {
        ObjectSetInteger(0, rectNameLondon, OBJPROP_TIME, 1, sessionEndTimeServerLondon);
        ObjectSetDouble(0, rectNameLondon, OBJPROP_PRICE, 0, sessionMaxValueLondon);
        ObjectSetDouble(0, rectNameLondon, OBJPROP_PRICE, 1, sessionMinValueLondon);
        ChartRedraw();
    }
    // Actualizar valores de la última sesión
    lastMaxValueLondon = sessionMaxValueLondon;
    lastMinValueLondon = sessionMinValueLondon;
    lastEndTimeLondon = sessionEndTimeServerLondon;
    londonMaxBroken = false;
    londonMinBroken = false;
    breakoutLondon = false;
    contraryTrendLondon = false;  // Reiniciar tendencia contraria
    labelDrawnLondon = false;     // Reiniciar bandera de dibujo
    breakPriceLondon = 0;         // Reiniciar precio de rompimiento
    breakTimeLondon = 0;          // Reiniciar tiempo de rompimiento
    Print("Sesión London finalizada. lastMaxValueLondon=", lastMaxValueLondon, ", lastMinValueLondon=", lastMinValueLondon, ", lastEndTimeLondon=", TimeToString(lastEndTimeLondon));
    sessionMaxValueLondon = -DBL_MAX;
    sessionMinValueLondon = DBL_MAX;
}

    // --- Dibujar el rectángulo del subperíodo (Londres) ---
    if (input_operativa_londres && sub_sesion_londres_server)
    {
        subSessionActiveLondon = true;

        // Calcular máximo y mínimo del subperíodo
        if (!subRectDrawnLondon)
        {
            CalculateSessionMaxMin(subSessionStartTimeServerLondon, tickTimeServer, subSessionMaxValueLondon, subSessionMinValueLondon);
        }

        // Actualizar máximo y mínimo del subperíodo con el precio actual
        if (valor > subSessionMaxValueLondon) subSessionMaxValueLondon = valor;
        if (valor < subSessionMinValueLondon) subSessionMinValueLondon = valor;

        // Crear el rectángulo del subperíodo (solo una vez por día)
        if (!subRectDrawnLondon)
        {
            subRectNameLondon = "SubSessionRectLondon_" + TimeToString(subSessionStartTimeLondon, TIME_DATE | TIME_MINUTES);

            if (subSessionMaxValueLondon != -DBL_MAX && subSessionMinValueLondon != DBL_MAX)
            {
                if (ObjectCreate(0, subRectNameLondon, OBJ_RECTANGLE, 0, subSessionStartTimeServerLondon, subSessionMaxValueLondon, tickTimeServer, subSessionMinValueLondon))
                {
                    ObjectSetInteger(0, subRectNameLondon, OBJPROP_COLOR, input_color_rect_sub_londres);
                    ObjectSetInteger(0, subRectNameLondon, OBJPROP_WIDTH, 2);
                    ObjectSetInteger(0, subRectNameLondon, OBJPROP_STYLE, STYLE_SOLID);
                    ObjectSetInteger(0, subRectNameLondon, OBJPROP_BACK, true);
                    subRectDrawnLondon = true;
                }
            }
        }

        // Actualizar el rectángulo del subperíodo en cada vela M1 (sin etiquetas)
        static datetime lastCandleTimeSubLondon = 0;
        datetime candleTimeSubLondon = iTime(Symbol(), PERIOD_M1, 0);
        if (candleTimeSubLondon != lastCandleTimeSubLondon)
        {
            if (ObjectFind(0, subRectNameLondon) >= 0)
            {
                if (subSessionMaxValueLondon != -DBL_MAX && subSessionMinValueLondon != DBL_MAX)
                {
                    ObjectSetDouble(0, subRectNameLondon, OBJPROP_PRICE, 0, subSessionMaxValueLondon); // Máximo
                    ObjectSetDouble(0, subRectNameLondon, OBJPROP_PRICE, 1, subSessionMinValueLondon); // Mínimo
                    ObjectSetInteger(0, subRectNameLondon, OBJPROP_TIME, 1, tickTimeServer); // Fin del rectángulo
                    ChartRedraw();
                }
            }
            lastCandleTimeSubLondon = candleTimeSubLondon;
        }
    }
    else if (subSessionActiveLondon && tickTimeServer > subSessionEndTimeServerLondon)
    {
        // El subperíodo ha terminado, fijar el rectángulo
        subSessionActiveLondon = false;
        subRectDrawnLondon = false;
        if (ObjectFind(0, subRectNameLondon) >= 0)
        {
            ObjectSetInteger(0, subRectNameLondon, OBJPROP_TIME, 1, subSessionEndTimeServerLondon);
            ObjectSetDouble(0, subRectNameLondon, OBJPROP_PRICE, 0, subSessionMaxValueLondon);
            ObjectSetDouble(0, subRectNameLondon, OBJPROP_PRICE, 1, subSessionMinValueLondon);
            ChartRedraw();
        }
        subSessionMaxValueLondon = -DBL_MAX;
        subSessionMinValueLondon = DBL_MAX;
    }

    // --- Dibujar el rectángulo principal (sesión de Tokio/Asia) ---
    if (input_operativa_asia && sesion_asia_server)
    {
        sessionActiveAsia = true;

        // Calcular máximo y mínimo desde el inicio de la sesión hasta el momento actual
        if (!rectDrawnAsia)
        {
            CalculateSessionMaxMin(sessionStartTimeServerAsia, tickTimeServer, sessionMaxValueAsia, sessionMinValueAsia);
        }

        // Actualizar máximo y mínimo de la sesión con el precio actual
        if (valor > sessionMaxValueAsia) sessionMaxValueAsia = valor;
        if (valor < sessionMinValueAsia) sessionMinValueAsia = valor;

        // Crear el rectángulo principal al inicio de la sesión (solo una vez por día)
        if (!rectDrawnAsia)
        {
            rectNameAsia = "SessionRectAsia_" + TimeToString(sessionStartTimeAsia, TIME_DATE | TIME_MINUTES);
            labelMaxMainNameAsia = "LabelMaxMainAsia_" + TimeToString(sessionStartTimeAsia, TIME_DATE | TIME_MINUTES);
            labelMinMainNameAsia = "LabelMinMainAsia_" + TimeToString(sessionStartTimeAsia, TIME_DATE | TIME_MINUTES);

            if (sessionMaxValueAsia != -DBL_MAX && sessionMinValueAsia != DBL_MAX)
            {
                if (ObjectCreate(0, rectNameAsia, OBJ_RECTANGLE, 0, sessionStartTimeServerAsia, sessionMaxValueAsia, tickTimeServer, sessionMinValueAsia))
                {
                    ObjectSetInteger(0, rectNameAsia, OBJPROP_COLOR, input_color_rect_main_asia);
                    ObjectSetInteger(0, rectNameAsia, OBJPROP_WIDTH, 2);
                    ObjectSetInteger(0, rectNameAsia, OBJPROP_STYLE, STYLE_SOLID);
                    ObjectSetInteger(0, rectNameAsia, OBJPROP_BACK, true);
                    rectDrawnAsia = true;
                }
            }
        }

        // Actualizar el rectángulo principal y etiquetas en cada vela M1
        static datetime lastCandleTimeMainAsia = 0;
        datetime candleTimeMainAsia = iTime(Symbol(), PERIOD_M1, 0);
        if (candleTimeMainAsia != lastCandleTimeMainAsia)
        {
            if (ObjectFind(0, rectNameAsia) >= 0) // Verificar que el rectángulo existe
            {
                if (sessionMaxValueAsia != -DBL_MAX && sessionMinValueAsia != DBL_MAX)
                {
                    ObjectSetDouble(0, rectNameAsia, OBJPROP_PRICE, 0, sessionMaxValueAsia); // Máximo
                    ObjectSetDouble(0, rectNameAsia, OBJPROP_PRICE, 1, sessionMinValueAsia); // Mínimo
                    ObjectSetInteger(0, rectNameAsia, OBJPROP_TIME, 1, tickTimeServer); // Fin del rectángulo
                    ChartRedraw();

                    // Actualizar etiquetas del rectángulo principal
                    UpdatePriceLabels(labelMaxMainNameAsia, "Max Asia: " + DoubleToString(sessionMaxValueAsia, _Digits), sessionEndTimeServerAsia, sessionMaxValueAsia, clrWhite);
                    UpdatePriceLabels(labelMinMainNameAsia, "Min Asia: " + DoubleToString(sessionMinValueAsia, _Digits), sessionEndTimeServerAsia, sessionMinValueAsia, clrWhite);
                }
            }
            lastCandleTimeMainAsia = candleTimeMainAsia;
        }
    }
    
    else if (sessionActiveAsia && tickTimeServer > sessionEndTimeServerAsia)
{
    // La sesión principal ha terminado, fijar el rectángulo
    sessionActiveAsia = false;
    rectDrawnAsia = false;
    if (ObjectFind(0, rectNameAsia) >= 0)
    {
        ObjectSetInteger(0, rectNameAsia, OBJPROP_TIME, 1, sessionEndTimeServerAsia);
        ObjectSetDouble(0, rectNameAsia, OBJPROP_PRICE, 0, sessionMaxValueAsia);
        ObjectSetDouble(0, rectNameAsia, OBJPROP_PRICE, 1, sessionMinValueAsia);
        ChartRedraw();
    }
    // Actualizar valores de la última sesión
    lastMaxValueAsia = sessionMaxValueAsia;
    lastMinValueAsia = sessionMinValueAsia;
    lastEndTimeAsia = sessionEndTimeServerAsia;
    asiaMaxBroken = false;
    asiaMinBroken = false;
    breakoutAsia = false;
    contraryTrendAsia = false;  // Reiniciar tendencia contraria
    labelDrawnAsia = false;     // Reiniciar bandera de dibujo
    breakPriceAsia = 0;         // Reiniciar precio de rompimiento
    breakTimeAsia = 0;          // Reiniciar tiempo de rompimiento
    Print("Sesión Asia finalizada. lastMaxValueAsia=", lastMaxValueAsia, ", lastMinValueAsia=", lastMinValueAsia, ", lastEndTimeAsia=", TimeToString(lastEndTimeAsia));
    sessionMaxValueAsia = -DBL_MAX;
    sessionMinValueAsia = DBL_MAX;
}

    // --- Dibujar el rectángulo del subperíodo (Tokio/Asia) ---
    if (input_operativa_asia && sub_sesion_asia_server)
    {
        subSessionActiveAsia = true;

        // Calcular máximo y mínimo del subperíodo
        if (!subRectDrawnAsia)
        {
            CalculateSessionMaxMin(subSessionStartTimeServerAsia, tickTimeServer, subSessionMaxValueAsia, subSessionMinValueAsia);
        }

        // Actualizar máximo y mínimo del subperíodo con el precio actual
        if (valor > subSessionMaxValueAsia) subSessionMaxValueAsia = valor;
        if (valor < subSessionMinValueAsia) subSessionMinValueAsia = valor;

        // Crear el rectángulo del subperíodo (solo una vez por día)
        if (!subRectDrawnAsia)
        {
            subRectNameAsia = "SubSessionRectAsia_" + TimeToString(subSessionStartTimeAsia, TIME_DATE | TIME_MINUTES);

            if (subSessionMaxValueAsia != -DBL_MAX && subSessionMinValueAsia != DBL_MAX)
            {
                if (ObjectCreate(0, subRectNameAsia, OBJ_RECTANGLE, 0, subSessionStartTimeServerAsia, subSessionMaxValueAsia, tickTimeServer, subSessionMinValueAsia))
                {
                    ObjectSetInteger(0, subRectNameAsia, OBJPROP_COLOR, input_color_rect_sub_asia);
                    ObjectSetInteger(0, subRectNameAsia, OBJPROP_WIDTH, 2);
                    ObjectSetInteger(0, subRectNameAsia, OBJPROP_STYLE, STYLE_SOLID);
                    ObjectSetInteger(0, subRectNameAsia, OBJPROP_BACK, true);
                    subRectDrawnAsia = true;
                }
            }
        }

        // Actualizar el rectángulo del subperíodo en cada vela M1 (sin etiquetas)
        static datetime lastCandleTimeSubAsia = 0;
        datetime candleTimeSubAsia = iTime(Symbol(), PERIOD_M1, 0);
        if (candleTimeSubAsia != lastCandleTimeSubAsia)
        {
            if (ObjectFind(0, subRectNameAsia) >= 0)
            {
                if (subSessionMaxValueAsia != -DBL_MAX && subSessionMinValueAsia != DBL_MAX)
                {
                    ObjectSetDouble(0, subRectNameAsia, OBJPROP_PRICE, 0, subSessionMaxValueAsia); // Máximo
                    ObjectSetDouble(0, subRectNameAsia, OBJPROP_PRICE, 1, subSessionMinValueAsia); // Mínimo
                    ObjectSetInteger(0, subRectNameAsia, OBJPROP_TIME, 1, tickTimeServer); // Fin del rectángulo
                    ChartRedraw();
                }
            }
            lastCandleTimeSubAsia = candleTimeSubAsia;
        }
    }
    else if (subSessionActiveAsia && tickTimeServer > subSessionEndTimeServerAsia)
    {
        // El subperíodo ha terminado, fijar el rectángulo
        subSessionActiveAsia = false;
        subRectDrawnAsia = false;
        if (ObjectFind(0, subRectNameAsia) >= 0)
        {
            ObjectSetInteger(0, subRectNameAsia, OBJPROP_TIME, 1, subSessionEndTimeServerAsia);
            ObjectSetDouble(0, subRectNameAsia, OBJPROP_PRICE, 0, subSessionMaxValueAsia);
            ObjectSetDouble(0, subRectNameAsia, OBJPROP_PRICE, 1, subSessionMinValueAsia);
            ChartRedraw();
        }
        subSessionMaxValueAsia = -DBL_MAX;
        subSessionMinValueAsia = DBL_MAX;
    }
    // --- Verificar rupturas de máximos y mínimos de recuadros principales anteriores ---

    // Actualizar los valores del último recuadro principal cuando termina una sesión
if (sessionActiveNY && tickTimeServer > sessionEndTimeServerNY)
{
    lastMaxValueNY = sessionMaxValueNY;
    lastMinValueNY = sessionMinValueNY;
    lastEndTimeNY = sessionEndTimeServerNY;
    nyMaxBroken = false;    // Reiniciar la bandera de ruptura
    nyMinBroken = false;
    breakoutNY = false;     // Reiniciar la variable de rompimiento
}

if (sessionActiveLondon && tickTimeServer > sessionEndTimeServerLondon)
{
    lastMaxValueLondon = sessionMaxValueLondon;
    lastMinValueLondon = sessionMinValueLondon;
    lastEndTimeLondon = sessionEndTimeServerLondon;
    londonMaxBroken = false; // Reiniciar la bandera de ruptura
    londonMinBroken = false;
    breakoutLondon = false;  // Reiniciar la variable de rompimiento
}

if (sessionActiveAsia && tickTimeServer > sessionEndTimeServerAsia)
{
    lastMaxValueAsia = sessionMaxValueAsia;
    lastMinValueAsia = sessionMinValueAsia;
    lastEndTimeAsia = sessionEndTimeServerAsia;
    asiaMaxBroken = false;   // Reiniciar la bandera de ruptura
    asiaMinBroken = false;
    breakoutAsia = false;    // Reiniciar la variable de rompimiento
}

 // Verificar rupturas después de que los recuadros hayan terminado
double currentPrice = SymbolInfoDouble(Symbol(), SYMBOL_BID);

// Nueva York: Verificar ruptura del máximo o mínimo del último recuadro
if (lastEndTimeNY > 0 && tickTimeServer > lastEndTimeNY)
    {
        // Ruptura del máximo
        if (!nyMaxBroken && currentPrice > lastMaxValueNY)
        {
            string labelName = "BreakLabelNY_Max_" + IntegerToString(breakLabelCounter++);
            if (ObjectCreate(0, labelName, OBJ_TEXT, 0, tickTimeServer, currentPrice))
            {
                ObjectSetString(0, labelName, OBJPROP_TEXT, "ROMPE");
                ObjectSetInteger(0, labelName, OBJPROP_COLOR, clrRed);
                ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 10);
                ObjectSetString(0, labelName, OBJPROP_FONT, "Arial");
                ObjectSetInteger(0, labelName, OBJPROP_ANCHOR, ANCHOR_CENTER);
                ChartRedraw();
            }
            nyMaxBroken = true;
            breakoutNY = true;
            breakPriceNY = currentPrice;
            breakTimeNY = tickTimeServer;
            labelDrawnNY = false;
            UpdateOperationStatusLabel("Identificando Operación", tickTimeServer, currentPrice);
            Print("Rompimiento NY (Máximo): Precio=", currentPrice, ", Máximo Anterior=", lastMaxValueNY, ", breakoutNY=", breakoutNY);
        }
        // Ruptura del mínimo
        if (!nyMinBroken && currentPrice < lastMinValueNY)
        {
            string labelName = "BreakLabelNY_Min_" + IntegerToString(breakLabelCounter++);
            if (ObjectCreate(0, labelName, OBJ_TEXT, 0, tickTimeServer, currentPrice))
            {
                ObjectSetString(0, labelName, OBJPROP_TEXT, "ROMPE");
                ObjectSetInteger(0, labelName, OBJPROP_COLOR, clrRed);
                ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 10);
                ObjectSetString(0, labelName, OBJPROP_FONT, "Arial");
                ObjectSetInteger(0, labelName, OBJPROP_ANCHOR, ANCHOR_CENTER);
                ChartRedraw();
            }
            nyMinBroken = true;
            breakoutNY = true;
            breakPriceNY = currentPrice;
            breakTimeNY = tickTimeServer;
            labelDrawnNY = false;
            UpdateOperationStatusLabel("Identificando Operación", tickTimeServer, currentPrice);
            Print("Rompimiento NY (Mínimo): Precio=", currentPrice, ", Mínimo Anterior=", lastMinValueNY, ", breakoutNY=", breakoutNY);
        }
        



        // Verificar tendencia contraria después del rompimiento
        if (breakoutNY && breakTimeNY > 0 && !labelDrawnNY)
        {
            contraryTrendNY = DetectContraryTrend(breakPriceNY, currentPrice, nyMaxBroken, reversalThreshold);
            if (contraryTrendNY)
            {
                // string labelName = "ContraryTrendNY_" + IntegerToString(breakLabelCounter++);
                // if (ObjectCreate(0, labelName, OBJ_TEXT, 0, tickTimeServer, currentPrice))
                // {
                //     ObjectSetString(0, labelName, OBJPROP_TEXT, "TENDENCIA CONTRARIA");
                //     ObjectSetInteger(0, labelName, OBJPROP_COLOR, clrYellow);
                //     ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 10);
                //     ObjectSetString(0, labelName, OBJPROP_FONT, "Arial");
                //     ObjectSetInteger(0, labelName, OBJPROP_ANCHOR, ANCHOR_CENTER);
                //     ChartRedraw();
                // }
                labelDrawnNY = true;
                string newStatus = nyMaxBroken ? "Venta" : "Compra";
                UpdateOperationStatusLabel(newStatus, tickTimeServer, currentPrice);
                Print("Tendencia Contraria NY Detectada: Precio=", currentPrice, ", Precio Rompimiento=", breakPriceNY, ", contraryTrendNY=", contraryTrendNY, ", Estado=", newStatus);
            }
        }




        
    }
    
    // Londres: Verificar ruptura y tendencia contraria
    if (lastEndTimeLondon > 0 && tickTimeServer > lastEndTimeLondon)
    {
        // Ruptura del máximo
        if (!londonMaxBroken && currentPrice > lastMaxValueLondon)
        {
            string labelName = "BreakLabelLondon_Max_" + IntegerToString(breakLabelCounter++);
            if (ObjectCreate(0, labelName, OBJ_TEXT, 0, tickTimeServer, currentPrice))
            {
                ObjectSetString(0, labelName, OBJPROP_TEXT, "ROMPE");
                ObjectSetInteger(0, labelName, OBJPROP_COLOR, clrRed);
                ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 10);
                ObjectSetString(0, labelName, OBJPROP_FONT, "Arial");
                ObjectSetInteger(0, labelName, OBJPROP_ANCHOR, ANCHOR_CENTER);
                ChartRedraw();
            }
            londonMaxBroken = true;
            breakoutLondon = true;
            breakPriceLondon = currentPrice;
            breakTimeLondon = tickTimeServer;
            labelDrawnLondon = false;
            UpdateOperationStatusLabel("Identificando Operación", tickTimeServer, currentPrice);
            Print("Rompimiento London (Máximo): Precio=", currentPrice, ", Máximo Anterior=", lastMaxValueLondon, ", breakoutLondon=", breakoutLondon);
        }
        // Ruptura del mínimo
        if (!londonMinBroken && currentPrice < lastMinValueLondon)
        {
            string labelName = "BreakLabelLondon_Min_" + IntegerToString(breakLabelCounter++);
            if (ObjectCreate(0, labelName, OBJ_TEXT, 0, tickTimeServer, currentPrice))
            {
                ObjectSetString(0, labelName, OBJPROP_TEXT, "ROMPE");
                ObjectSetInteger(0, labelName, OBJPROP_COLOR, clrRed);
                ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 10);
                ObjectSetString(0, labelName, OBJPROP_FONT, "Arial");
                ObjectSetInteger(0, labelName, OBJPROP_ANCHOR, ANCHOR_CENTER);
                ChartRedraw();
            }
            londonMinBroken = true;
            breakoutLondon = true;
            breakPriceLondon = currentPrice;
            breakTimeLondon = tickTimeServer;
            labelDrawnLondon = false;
            UpdateOperationStatusLabel("Identificando Operación", tickTimeServer, currentPrice);
            Print("Rompimiento London (Mínimo): Precio=", currentPrice, ", Mínimo Anterior=", lastMinValueLondon, ", breakoutLondon=", breakoutLondon);
        }
        
        // Verificar tendencia contraria después del rompimiento
        if (breakoutLondon && breakTimeLondon > 0 && !labelDrawnLondon)
        {
            contraryTrendLondon = DetectContraryTrend(breakPriceLondon, currentPrice, londonMaxBroken, reversalThreshold);
            if (contraryTrendLondon)
            {
                // string labelName = "ContraryTrendLondon_" + IntegerToString(breakLabelCounter++);
                // if (ObjectCreate(0, labelName, OBJ_TEXT, 0, tickTimeServer, currentPrice))
                // {
                //     ObjectSetString(0, labelName, OBJPROP_TEXT, "TENDENCIA CONTRARIA");
                //     ObjectSetInteger(0, labelName, OBJPROP_COLOR, clrYellow);
                //     ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 10);
                //     ObjectSetString(0, labelName, OBJPROP_FONT, "Arial");
                //     ObjectSetInteger(0, labelName, OBJPROP_ANCHOR, ANCHOR_CENTER);
                //     ChartRedraw();
                // }
                labelDrawnLondon = true;
                string newStatus = londonMaxBroken ? "Venta" : "Compra";
                UpdateOperationStatusLabel(newStatus, tickTimeServer, currentPrice);
                Print("Tendencia Contraria London Detectada: Precio=", currentPrice, ", Precio Rompimiento=", breakPriceLondon, ", contraryTrendLondon=", contraryTrendLondon, ", Estado=", newStatus);
            }
        }
    }
    
    // Asia: Verificar ruptura y tendencia contraria
    if (lastEndTimeAsia > 0 && tickTimeServer > lastEndTimeAsia)
    {
        // Ruptura del máximo
        if (!asiaMaxBroken && currentPrice > lastMaxValueAsia)
        {
            string labelName = "BreakLabelAsia_Max_" + IntegerToString(breakLabelCounter++);
            if (ObjectCreate(0, labelName, OBJ_TEXT, 0, tickTimeServer, currentPrice))
            {
                ObjectSetString(0, labelName, OBJPROP_TEXT, "ROMPE");
                ObjectSetInteger(0, labelName, OBJPROP_COLOR, clrRed);
                ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 10);
                ObjectSetString(0, labelName, OBJPROP_FONT, "Arial");
                ObjectSetInteger(0, labelName, OBJPROP_ANCHOR, ANCHOR_CENTER);
                ChartRedraw();
            }
            asiaMaxBroken = true;
            breakoutAsia = true;
            breakPriceAsia = currentPrice;
            breakTimeAsia = tickTimeServer;
            labelDrawnAsia = false;
            UpdateOperationStatusLabel("Identificando Operación", tickTimeServer, currentPrice);
            Print("Rompimiento Asia (Máximo): Precio=", currentPrice, ", Máximo Anterior=", lastMaxValueAsia, ", breakoutAsia=", breakoutAsia);
        }
        // Ruptura del mínimo
        if (!asiaMinBroken && currentPrice < lastMinValueAsia)
        {
            string labelName = "BreakLabelAsia_Min_" + IntegerToString(breakLabelCounter++);
            if (ObjectCreate(0, labelName, OBJ_TEXT, 0, tickTimeServer, currentPrice))
            {
                ObjectSetString(0, labelName, OBJPROP_TEXT, "ROMPE");
                ObjectSetInteger(0, labelName, OBJPROP_COLOR, clrRed);
                ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 10);
                ObjectSetString(0, labelName, OBJPROP_FONT, "Arial");
                ObjectSetInteger(0, labelName, OBJPROP_ANCHOR, ANCHOR_CENTER);
                ChartRedraw();
            }
            asiaMinBroken = true;
            breakoutAsia = true;
            breakPriceAsia = currentPrice;
            breakTimeAsia = tickTimeServer;
            labelDrawnAsia = false;
            UpdateOperationStatusLabel("Identificando Operación", tickTimeServer, currentPrice);
            Print("Rompimiento Asia (Mínimo): Precio=", currentPrice, ", Mínimo Anterior=", lastMinValueAsia, ", breakoutAsia=", breakoutAsia);
        }

        if (asiaMaxBroken && breakoutAsia)
        {
            // Verificar si hay una nueva vela completa
            datetime lastBarTime = iTime(_Symbol, CandleTimeframe, 0);
            if(lastBarTime != lastCandleTime) {
                lastCandleTime = lastBarTime;           // Actualizar el tiempo de la última vela analizada
                
                // Verificar el patrón de velas cuando se forma una nueva vela
                patternDetected = CheckCandlePattern();
                
                if(patternDetected) {
                    string direction = (lastPatternDirection == POSITION_TYPE_BUY) ? "ALCISTA" : "BAJISTA";
                    Print("¡Patrón de velas detectado después de ruptura Asia! Dirección: ", direction);
                    
                    // Si rompió por el máximo, buscamos VENTAS (patrón bajista)
                    // Si rompió por el mínimo, buscamos COMPRAS (patrón alcista)
                    bool correctDirection = (asiaMaxBroken && lastPatternDirection == POSITION_TYPE_SELL) ||
                                        (asiaMinBroken && lastPatternDirection == POSITION_TYPE_BUY);
                    
                    if(correctDirection) {
                        // Si podemos operar y no hay posición abierta, abrir una nueva operación
                        if(EnableTrading && IsTimeToTrade() && lastTicket == 0) {
                            OpenTradeBasedOnPattern();
                            
                            // Actualizar estado después de abrir operación
                            string newStatus = asiaMaxBroken ? "Venta Ejecutada" : "Compra Ejecutada";
                            UpdateOperationStatusLabel(newStatus, tickTimeServer, currentPrice);
                        }
                    }
                    else {
                        Print("Patrón detectado pero dirección incorrecta. Esperando patrón ", 
                            asiaMaxBroken ? "BAJISTA" : "ALCISTA");
                    }
                }
            }
        }
        
        // // Verificar tendencia contraria después del rompimiento
        // if (breakoutAsia && breakTimeAsia > 0 && !labelDrawnAsia)
        // {
        //     contraryTrendAsia = DetectContraryTrend(breakPriceAsia, currentPrice, asiaMaxBroken, reversalThreshold);
        //     if (contraryTrendAsia)
        //     {
        //         // string labelName = "ContraryTrendAsia_" + IntegerToString(breakLabelCounter++);
        //         // if (ObjectCreate(0, labelName, OBJ_TEXT, 0, tickTimeServer, currentPrice))
        //         // {
        //         //     ObjectSetString(0, labelName, OBJPROP_TEXT, "TENDENCIA CONTRARIA");
        //         //     ObjectSetInteger(0, labelName, OBJPROP_COLOR, clrYellow);
        //         //     ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 10);
        //         //     ObjectSetString(0, labelName, OBJPROP_FONT, "Arial");
        //         //     ObjectSetInteger(0, labelName, OBJPROP_ANCHOR, ANCHOR_CENTER);
        //         //     ChartRedraw();
        //         // }
        //         labelDrawnAsia = true;
        //         string newStatus = asiaMaxBroken ? "Venta" : "Compra";
        //         UpdateOperationStatusLabel(newStatus, tickTimeServer, currentPrice);
        //         Print("Tendencia Contraria Asia Detectada: Precio=", currentPrice, ", Precio Rompimiento=", breakPriceAsia, ", contraryTrendAsia=", contraryTrendAsia, ", Estado=", newStatus);
        //     }
        // }
    }

}

void OnTimer()
{
    hora_servidor = TimeCurrent();
    hora_actual_servidor = hora_servidor + ajuste_tiempo;
    tickTimeNY = hora_actual_servidor;
    tickTimeServer = TimeCurrent();
    ComprobarSesionOperativa();
    if (debug_hora)
    {
        Print("Estado Tendencias Contrarias: NY=", contraryTrendNY, ", London=", contraryTrendLondon, ", Asia=", contraryTrendAsia, ", Estado Operación=", operationStatus);
    }
    //Print("Hora Servidor: ", hora_servidor ,"  -  Hora NY: ", hora_actual_servidor);
}