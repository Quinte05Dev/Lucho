//+------------------------------------------------------------------+
//|                                                  BFunded Ea.mq5 |
//|                             Copyright 2000-2024, TheTradingAPi   |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

//Primer Cambio
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Indicators\Trend.mqh>
#include <Jason.mqh>




#include "16_backtestingmodule.mqh"


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


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{


    return(INIT_SUCCEEDED);
}


//+------------------------------------------------------------------+
//| Expert Trade function                                             |
//+------------------------------------------------------------------+
void OnTrade() {


            //Metricas Backtesting 
            // Actualizar métricas
            DibujarMetricasMensuales();

}


//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+

void OnTick() {



}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
 

    if (!MQLInfoInteger(MQL_TESTER))
    {   

    ObjectsDeleteAll(0, "MetricasMensuales");
    for(int i = 0; i < 12; i++)
    {
        ObjectDelete(0, "Mes_" + IntegerToString(i));
    }
    ObjectDelete(0, "MesActual");
    ObjectDelete(0, "TituloMetricas");
    
     }

  }
//+------------------------------------------------------------------+


double OnTester()
{

}





