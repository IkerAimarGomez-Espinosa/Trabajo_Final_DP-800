USE BoxScoutJunior;
GO

SELECT 'compatibilidad_170' AS prueba,
       CASE WHEN (SELECT compatibility_level FROM sys.databases WHERE name = DB_NAME()) = 170 THEN 'OK' ELSE 'FALLO' END AS resultado
UNION ALL SELECT 'cinco_tablas',
       CASE WHEN (SELECT COUNT(*) FROM sys.tables WHERE name IN (N'clubes', N'boxeadores', N'combates', N'fichas_medicas', N'informes_scouting')) = 5 THEN 'OK' ELSE 'FALLO' END
UNION ALL SELECT 'boxeadores_48',
       CASE WHEN (SELECT COUNT(*) FROM dbo.boxeadores) = 48 THEN 'OK' ELSE 'FALLO' END
UNION ALL SELECT 'combates_126',
       CASE WHEN (SELECT COUNT(*) FROM dbo.combates) = 126 THEN 'OK' ELSE 'FALLO' END
UNION ALL SELECT 'informes_63',
       CASE WHEN (SELECT COUNT(*) FROM dbo.informes_scouting) = 63 THEN 'OK' ELSE 'FALLO' END
UNION ALL SELECT 'records_coherentes',
       CASE WHEN (SELECT SUM(victorias) FROM dbo.boxeadores) = (SELECT SUM(derrotas) FROM dbo.boxeadores) THEN 'OK' ELSE 'FALLO' END
UNION ALL SELECT 'vectores_completos',
       CASE WHEN (SELECT COUNT(*) FROM dbo.informes_scouting WHERE reporte_vector IS NULL) = 0 THEN 'OK' ELSE 'FALLO' END
UNION ALL SELECT 'dimension_768',
       CASE WHEN (SELECT MIN(VECTORPROPERTY(reporte_vector, 'Dimensions')) FROM dbo.informes_scouting) = 768 THEN 'OK' ELSE 'FALLO' END
UNION ALL SELECT 'rls_activa',
       CASE WHEN EXISTS (SELECT 1 FROM sys.security_policies WHERE name = N'pol_boxeadores_por_club' AND is_enabled = 1) THEN 'OK' ELSE 'FALLO' END
UNION ALL SELECT 'enmascarado_activo',
       CASE WHEN EXISTS (SELECT 1 FROM sys.masked_columns WHERE object_id = OBJECT_ID(N'dbo.fichas_medicas')) THEN 'OK' ELSE 'FALLO' END
UNION ALL SELECT 'indice_compuesto_bench',
       CASE WHEN EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_bench_guardia_peso' AND object_id = OBJECT_ID(N'dbo.boxeadores_bench')) THEN 'OK' ELSE 'FALLO' END;
GO

-- Prueba de la conexión con el modelo de IA
BEGIN TRY
    DECLARE @v VECTOR(768) = AI_GENERATE_EMBEDDINGS(N'prueba' USE MODEL local_embeddings);
    SELECT 'modelo_ia_responde' AS prueba, 'OK' AS resultado;
END TRY
BEGIN CATCH
    SELECT 'modelo_ia_responde' AS prueba, 'FALLO' AS resultado, ERROR_MESSAGE() AS detalle;
END CATCH;
GO