EXECUTE AS USER = N'entrenador_rayo';
EXEC dbo.usp_rag_asistente_boxeo @pregunta_usuario = N'prueba', @peso_min = 60.0, @peso_max = 70.0;
REVERT;