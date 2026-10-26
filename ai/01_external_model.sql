USE BoxScoutJunior;
GO

-- Permite que SQL Server llame a endpoints REST (nivel de instancia)
EXEC sp_configure 'external rest endpoint enabled', 1;
RECONFIGURE WITH OVERRIDE;
GO

-- Registra el modelo de embeddings. Si necesitas recrearlo: DROP EXTERNAL MODEL local_embeddings;
CREATE EXTERNAL MODEL local_embeddings
WITH (
    LOCATION   = 'https://localhost:443/api/embed',
    API_FORMAT = 'Ollama',
    MODEL_TYPE = EMBEDDINGS,
    MODEL      = 'nomic-embed-text'
);
GO

-- Permisos para el rol de administración (mínimo privilegio: los clubes no pueden usar la IA)
GRANT EXECUTE ON EXTERNAL MODEL::local_embeddings TO FederacionAdmin;
GRANT EXECUTE ANY EXTERNAL ENDPOINT TO FederacionAdmin;
GO

-- Prueba: debe devolver 768
DECLARE @v VECTOR(768) = AI_GENERATE_EMBEDDINGS(N'boxeador técnico y escurridizo' USE MODEL local_embeddings);
SELECT VECTORPROPERTY(@v, 'Dimensions') AS dimensiones;
GO