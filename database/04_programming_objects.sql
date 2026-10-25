USE BoxScoutJunior;
GO

-- VISTA: ranking por categoría de peso (window function RANK)
CREATE OR ALTER VIEW dbo.v_ranking_boxeadores AS
SELECT b.boxeador_id,
       b.nombre,
       c.nombre AS club,
       cat.categoria,
       b.guardia,
       b.peso_kg,
       b.victorias,
       b.derrotas,
       CAST(b.victorias * 100.0 / NULLIF(b.victorias + b.derrotas, 0) AS DECIMAL(5,2)) AS porcentaje_victorias,
       RANK() OVER (PARTITION BY cat.categoria ORDER BY b.victorias DESC, b.derrotas ASC) AS puesto_categoria
FROM dbo.boxeadores AS b
JOIN dbo.clubes AS c ON c.club_id = b.club_id
CROSS APPLY (VALUES (CASE WHEN b.peso_kg < 60 THEN N'Ligero'
                          WHEN b.peso_kg < 72 THEN N'Medio'
                          ELSE N'Pesado' END)) AS cat(categoria);
GO

-- FUNCIÓN: rivales candidatos (otro club, peso parecido y apto médicamente)
CREATE OR ALTER FUNCTION dbo.fn_rivales_candidatos (@boxeador_id INT, @margen_kg DECIMAL(5,2))
RETURNS TABLE
AS
RETURN
(
    SELECT r.boxeador_id, r.nombre, r.club_id, r.guardia, r.peso_kg,
           ABS(r.peso_kg - o.peso_kg) AS diferencia_kg
    FROM dbo.boxeadores AS o
    JOIN dbo.boxeadores AS r
         ON r.boxeador_id <> o.boxeador_id
        AND r.club_id <> o.club_id
        AND ABS(r.peso_kg - o.peso_kg) <= @margen_kg
    JOIN dbo.fichas_medicas AS f ON f.boxeador_id = r.boxeador_id AND f.apto = 1
    WHERE o.boxeador_id = @boxeador_id
);
GO

-- PROCEDIMIENTO: registrar un combate con transacción y control de errores
CREATE OR ALTER PROCEDURE dbo.usp_registrar_combate
    @fecha   DATE,
    @rojo    INT,
    @azul    INT,
    @ganador INT = NULL,
    @metodo  NVARCHAR(20),
    @asaltos INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        INSERT INTO dbo.combates (fecha, boxeador_rojo_id, boxeador_azul_id, ganador_id, metodo, asaltos)
        VALUES (@fecha, @rojo, @azul, @ganador, @metodo, @asaltos);
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- TRIGGER 1: mantiene victorias y derrotas al insertar o borrar combates
CREATE OR ALTER TRIGGER dbo.trg_combates_actualizar_record
ON dbo.combates
AFTER INSERT, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE b
    SET victorias = (SELECT COUNT(*) FROM dbo.combates c WHERE c.ganador_id = b.boxeador_id),
        derrotas  = (SELECT COUNT(*) FROM dbo.combates c
                     WHERE c.ganador_id IS NOT NULL
                       AND c.ganador_id <> b.boxeador_id
                       AND b.boxeador_id IN (c.boxeador_rojo_id, c.boxeador_azul_id))
    FROM dbo.boxeadores AS b
    WHERE b.boxeador_id IN (SELECT boxeador_rojo_id FROM inserted
                            UNION SELECT boxeador_azul_id FROM inserted
                            UNION SELECT boxeador_rojo_id FROM deleted
                            UNION SELECT boxeador_azul_id FROM deleted);
END;
GO

-- TRIGGER 2: si se edita el texto de un informe, su vector deja de ser válido y se borra
CREATE OR ALTER TRIGGER dbo.trg_informes_invalidar_vector
ON dbo.informes_scouting
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF UPDATE(reporte_texto)
        UPDATE i
        SET reporte_vector = NULL
        FROM dbo.informes_scouting AS i
        JOIN inserted AS ins ON ins.informe_id = i.informe_id;
END;
GO