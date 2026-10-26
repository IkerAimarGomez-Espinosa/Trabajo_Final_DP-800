USE BoxScoutJunior;
GO

CREATE OR ALTER PROCEDURE dbo.usp_buscar_sparring_hibrido
    @texto_busqueda NVARCHAR(MAX),
    @peso_min       DECIMAL(5,2),
    @peso_max       DECIMAL(5,2),
    @guardia        NVARCHAR(20) = NULL,
    @top            INT = 3
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @qv VECTOR(768) = AI_GENERATE_EMBEDDINGS(@texto_busqueda USE MODEL local_embeddings);

    WITH candidatos AS (
        SELECT b.boxeador_id, b.nombre, b.peso_kg, b.guardia, i.informe_id, i.reporte_texto,
               VECTOR_DISTANCE('cosine', i.reporte_vector, @qv) AS distancia
        FROM dbo.boxeadores AS b
        JOIN dbo.informes_scouting AS i ON i.boxeador_id = b.boxeador_id
        JOIN dbo.fichas_medicas AS f ON f.boxeador_id = b.boxeador_id AND f.apto = 1
        WHERE b.peso_kg BETWEEN @peso_min AND @peso_max
          AND (@guardia IS NULL OR b.guardia = @guardia)
          AND i.reporte_vector IS NOT NULL
    ),
    mejor AS (
        SELECT *, ROW_NUMBER() OVER (PARTITION BY boxeador_id ORDER BY distancia) AS rn
        FROM candidatos
    )
    SELECT TOP (@top) boxeador_id, nombre, peso_kg, guardia, reporte_texto, distancia
    FROM mejor
    WHERE rn = 1
    ORDER BY distancia ASC;
END;
GO