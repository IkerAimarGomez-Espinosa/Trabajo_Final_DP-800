USE [BoxScoutJunior]
GO

EXEC dbo.usp_rag_asistente_boxeo @pregunta_usuario = N'¿Quién es el mejor contragolpeador?', @peso_min = 95.0, @peso_max = 100.0;