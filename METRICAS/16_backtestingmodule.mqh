//+------------------------------------------------------------------+
//| Función para dibujar métricas mensuales                          |
//+------------------------------------------------------------------+
void DibujarMetricasMensuales()
{
    MqlDateTime tiempo;
    TimeToStruct(TimeCurrent(), tiempo);
    
    // Si cambia el mes, guardar métricas del mes anterior
    if(g_mes_anterior != tiempo.mon && g_mes_anterior != 0)
    {
        double balance_actual = AccountInfoDouble(ACCOUNT_BALANCE);
        g_metricas_mensuales[g_mes_anterior-1].profit_mensual = 
            ((balance_actual - g_balance_inicial_mes) / g_balance_inicial_mes) * 100;
        g_metricas_mensuales[g_mes_anterior-1].drawdown_mensual = 
            ((g_balance_max_mes - balance_actual) / g_balance_max_mes) * 100;
        g_metricas_mensuales[g_mes_anterior-1].mes_completado = true;
    }
    
    // Inicializar valores para el nuevo mes
    if(g_mes_anterior != tiempo.mon)
    {
        g_balance_inicial_mes = AccountInfoDouble(ACCOUNT_BALANCE);
        g_balance_max_mes = g_balance_inicial_mes;
        g_mes_anterior = tiempo.mon;
    }
    
    // Actualizar balance máximo del mes actual
    double balance_actual = AccountInfoDouble(ACCOUNT_BALANCE);
    if(balance_actual > g_balance_max_mes)
        g_balance_max_mes = balance_actual;
        
    // Calcular métricas del mes actual
    double profit_actual = ((balance_actual - g_balance_inicial_mes) / g_balance_inicial_mes) * 100;
    double drawdown_actual = ((g_balance_max_mes - balance_actual) / g_balance_max_mes) * 100;
    
    // Crear el cuadro de métricas
    string table_name = "MetricasMensuales";
    
    if(ObjectFind(0, table_name) < 0) // Si el objeto no existe, créalo
    {
        ObjectCreate(0, table_name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
        ObjectSetInteger(0, table_name, OBJPROP_XDISTANCE, 280);
        ObjectSetInteger(0, table_name, OBJPROP_YDISTANCE, 20);
        ObjectSetInteger(0, table_name, OBJPROP_XSIZE, 250);
        ObjectSetInteger(0, table_name, OBJPROP_YSIZE, 300);
        ObjectSetInteger(0, table_name, OBJPROP_BGCOLOR, clrBlack);
        ObjectSetInteger(0, table_name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
        ObjectSetInteger(0, table_name, OBJPROP_COLOR, clrWhite);
        ObjectSetInteger(0, table_name, OBJPROP_STYLE, STYLE_SOLID);
        ObjectSetInteger(0, table_name, OBJPROP_WIDTH, 2);
        ObjectSetInteger(0, table_name, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
        ObjectSetInteger(0, table_name, OBJPROP_BACK, false);
    }
    
    string nombres_meses[] = {"Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", 
                             "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"};
    
    // Título
    CrearLabelD("TituloMetricas", "Historial de Métricas", 250, 35);
    
    // Mostrar métricas de meses completados
    int pos_y = 55;
    for(int i = 0; i < 12; i++)
    {
        if(g_metricas_mensuales[i].mes_completado)
        {
            string nombre_label = "Mes_" + IntegerToString(i);
            string texto = nombres_meses[i] + ": " + 
                          DoubleToString(g_metricas_mensuales[i].profit_mensual, 2) + "% | DD: " +
                          DoubleToString(g_metricas_mensuales[i].drawdown_mensual, 2) + "%";
            
            CrearLabelD(nombre_label, texto, 250, pos_y);
            color color_texto = g_metricas_mensuales[i].profit_mensual >= 0 ? clrLime : clrRed;
            ObjectSetInteger(0, nombre_label, OBJPROP_COLOR, color_texto);
            
            pos_y += 20;
        }
    }
    
    // Mostrar mes actual
    string texto_actual = nombres_meses[tiempo.mon-1] + " (Actual): " + 
                         DoubleToString(profit_actual, 2) + "% | DD: " +
                         DoubleToString(drawdown_actual, 2) + "%";
    
    CrearLabelD("MesActual", texto_actual, 250, pos_y);
    color color_actual = profit_actual >= 0 ? clrLime : clrRed;
    ObjectSetInteger(0, "MesActual", OBJPROP_COLOR, color_actual);
}