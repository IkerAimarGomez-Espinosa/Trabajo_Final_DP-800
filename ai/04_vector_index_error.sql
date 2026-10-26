USE BoxScoutJunior;
GO

CREATE VECTOR INDEX ix_informes_reporte_vector
ON dbo.informes_scouting (reporte_vector)
WITH (METRIC = 'cosine', TYPE = 'DiskANN');
GO

DECLARE @qv VECTOR(768) = AI_GENERATE_EMBEDDINGS(N'boxeador técnico, escurridizo y con mucha movilidad' USE MODEL local_embeddings);

SELECT TOP (5) WITH APPROXIMATE
       s.informe_id, s.boxeador_id, LEFT(s.reporte_texto, 70) AS extracto, r.distance
FROM VECTOR_SEARCH(
        TABLE      = dbo.informes_scouting AS s,
        COLUMN     = reporte_vector,
        SIMILAR_TO = @qv,
        METRIC     = 'cosine'
     ) AS r
ORDER BY r.distance;
GO