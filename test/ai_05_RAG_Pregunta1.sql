USE [BoxScoutJunior]
GO
EXEC dbo.usp_rag_asistente_boxeo
     @pregunta_usuario = N'¿Qué boxeador me recomiendas para preparar una pelea contra un rival que busca el intercambio de golpes constantes?',
     @peso_min = 70.0,
     @peso_max = 75.0;