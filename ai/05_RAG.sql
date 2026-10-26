USE BoxScoutJunior;
GO

CREATE OR ALTER PROCEDURE dbo.usp_rag_asistente_boxeo
    @pregunta_usuario NVARCHAR(MAX),
    @peso_min         DECIMAL(5,2),
    @peso_max         DECIMAL(5,2),
    @top              INT = 3,
    @modelo_llm       NVARCHAR(100) = N'llama3.2'
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Embedding de la pregunta
    DECLARE @qv VECTOR(768) = AI_GENERATE_EMBEDDINGS(@pregunta_usuario USE MODEL local_embeddings);

    -- 2. Recuperación: informes más parecidos (un informe por boxeador, solo aptos y en el rango de peso)
    DECLARE @recuperados TABLE (
        orden INT NOT NULL, boxeador_id INT, nombre NVARCHAR(100), peso_kg DECIMAL(5,2),
        guardia NVARCHAR(20), informe_id INT, reporte_texto NVARCHAR(MAX), distancia FLOAT
    );

    WITH candidatos AS (
        SELECT b.boxeador_id, b.nombre, b.peso_kg, b.guardia, i.informe_id, i.reporte_texto,
               VECTOR_DISTANCE('cosine', i.reporte_vector, @qv) AS distancia
        FROM dbo.boxeadores AS b
        JOIN dbo.informes_scouting AS i ON i.boxeador_id = b.boxeador_id
        JOIN dbo.fichas_medicas AS f ON f.boxeador_id = b.boxeador_id AND f.apto = 1
        WHERE b.peso_kg BETWEEN @peso_min AND @peso_max
          AND i.reporte_vector IS NOT NULL
    ),
    mejor AS (
        SELECT *, ROW_NUMBER() OVER (PARTITION BY boxeador_id ORDER BY distancia) AS rn
        FROM candidatos
    )
    INSERT INTO @recuperados (orden, boxeador_id, nombre, peso_kg, guardia, informe_id, reporte_texto, distancia)
    SELECT TOP (@top) ROW_NUMBER() OVER (ORDER BY distancia), boxeador_id, nombre, peso_kg, guardia, informe_id, reporte_texto, distancia
    FROM mejor
    WHERE rn = 1
    ORDER BY distancia ASC;

    -- 3. Construcción del contexto (STRING_AGG garantiza el orden, a diferencia de concatenar en un SELECT TOP)
    DECLARE @contexto NVARCHAR(MAX) = (
        SELECT STRING_AGG(
                 CONCAT(N'[Documento ', orden, N'] Boxeador: ', nombre, N' | Peso: ', peso_kg,
                        N' kg | Guardia: ', guardia, N' | Informe: ', reporte_texto),
                 CHAR(10)) WITHIN GROUP (ORDER BY orden)
        FROM @recuperados
    );

    IF @contexto IS NULL
    BEGIN
        SELECT @pregunta_usuario AS pregunta,
               N'No hay boxeadores aptos con informe en ese rango de peso.' AS respuesta_final;
        RETURN;
    END;

    -- 4. Prompt aumentado
    DECLARE @sistema NVARCHAR(MAX) = N'Eres analista de boxeo de la Federación Regional. Responde en español y usa SOLO la información de los documentos. Si no basta para responder, dilo. Cita siempre el nombre del boxeador que recomiendas y explica el motivo.';
    DECLARE @usuario NVARCHAR(MAX) = CONCAT(N'DOCUMENTOS:', CHAR(10), @contexto, CHAR(10), CHAR(10), N'PREGUNTA: ', @pregunta_usuario);

    DECLARE @payload NVARCHAR(MAX) = CONCAT(
        N'{"model":"', @modelo_llm, N'","stream":false,"options":{"temperature":0.2},"messages":[',
        N'{"role":"system","content":"', STRING_ESCAPE(@sistema, 'json'), N'"},',
        N'{"role":"user","content":"',   STRING_ESCAPE(@usuario, 'json'), N'"}]}');

    -- 5. Generación: llamada al LLM local (Caddy -> Ollama)
    DECLARE @http_respuesta NVARCHAR(MAX), @codigo INT;
    EXEC @codigo = sp_invoke_external_rest_endpoint
         @url      = N'https://localhost:443/api/chat',
         @method   = 'POST',
         @headers  = N'{"Content-Type":"application/json"}',
         @payload  = @payload,
         @timeout  = 200,
         @response = @http_respuesta OUTPUT;

    -- 6. Salida en cuatro resultados: pregunta, documentos, contexto enviado y respuesta final
    SELECT @pregunta_usuario AS pregunta;

    SELECT orden, boxeador_id, nombre, peso_kg, guardia, informe_id, distancia, reporte_texto
    FROM @recuperados ORDER BY orden;

    SELECT @sistema AS instrucciones_del_sistema, @usuario AS contexto_y_pregunta_enviados_al_llm;

    SELECT @codigo AS codigo_retorno,
           JSON_VALUE(@http_respuesta, '$.result.message.content') AS respuesta_final,
           CASE WHEN @codigo <> 0 THEN @http_respuesta END AS detalle_error;
END;
GO

GRANT EXECUTE ON dbo.usp_rag_asistente_boxeo TO FederacionAdmin;
GO