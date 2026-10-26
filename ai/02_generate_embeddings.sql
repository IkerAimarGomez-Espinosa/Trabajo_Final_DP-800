USE BoxScoutJunior;
GO

UPDATE dbo.informes_scouting
SET reporte_vector = AI_GENERATE_EMBEDDINGS(reporte_texto USE MODEL local_embeddings)
WHERE reporte_vector IS NULL;
GO

SELECT COUNT(*) AS informes,
       SUM(CASE WHEN reporte_vector IS NULL THEN 1 ELSE 0 END) AS sin_vector
FROM dbo.informes_scouting;

SELECT TOP (3) informe_id, boxeador_id,
       VECTORPROPERTY(reporte_vector, 'Dimensions') AS dimensiones,
       reporte_vector
FROM dbo.informes_scouting
ORDER BY informe_id;
GO

UPDATE dbo.informes_scouting SET reporte_texto = reporte_texto + N' (revisado)' WHERE informe_id = 1;
SELECT informe_id, CASE WHEN reporte_vector IS NULL THEN 'invalidado' ELSE 'vigente' END AS estado
FROM dbo.informes_scouting WHERE informe_id = 1;

-- Deshacer la edición y regenerar el vector
UPDATE dbo.informes_scouting SET reporte_texto = REPLACE(reporte_texto, N' (revisado)', N'') WHERE informe_id = 1;
UPDATE dbo.informes_scouting
SET reporte_vector = AI_GENERATE_EMBEDDINGS(reporte_texto USE MODEL local_embeddings)
WHERE reporte_vector IS NULL;