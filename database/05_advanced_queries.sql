USE BoxScoutJunior;
GO

-- 1) CTE + window functions: mejor racha de victorias consecutivas (islas y huecos)
WITH resultados AS (
    SELECT b.boxeador_id, c.fecha, c.combate_id,
           CASE WHEN c.ganador_id = b.boxeador_id THEN 1 ELSE 0 END AS gano
    FROM dbo.boxeadores AS b
    JOIN dbo.combates AS c ON b.boxeador_id IN (c.boxeador_rojo_id, c.boxeador_azul_id)
),
numerados AS (
    SELECT boxeador_id, gano,
           ROW_NUMBER() OVER (PARTITION BY boxeador_id ORDER BY fecha, combate_id)       AS rn_total,
           ROW_NUMBER() OVER (PARTITION BY boxeador_id, gano ORDER BY fecha, combate_id) AS rn_resultado
    FROM resultados
),
rachas AS (
    SELECT boxeador_id, COUNT(*) AS longitud
    FROM numerados
    WHERE gano = 1
    GROUP BY boxeador_id, (rn_total - rn_resultado)
)
SELECT TOP (10) b.nombre, MAX(r.longitud) AS mejor_racha
FROM rachas AS r
JOIN dbo.boxeadores AS b ON b.boxeador_id = r.boxeador_id
GROUP BY b.nombre
ORDER BY mejor_racha DESC, b.nombre;
GO

-- 2) Subconsulta correlacionada + JSON: estadísticas de combate por boxeador
SELECT b.boxeador_id, b.nombre,
(
    SELECT COUNT(*) AS combates,
           SUM(es_ko) AS victorias_por_ko,
           AVG(asaltos_dec) AS media_asaltos
    FROM (
        SELECT CAST(c.asaltos AS DECIMAL(4,2)) AS asaltos_dec,
               CASE WHEN c.ganador_id = b.boxeador_id AND c.metodo IN (N'KO', N'TKO') THEN 1 ELSE 0 END AS es_ko
        FROM dbo.combates AS c
        WHERE b.boxeador_id IN (c.boxeador_rojo_id, c.boxeador_azul_id)
    ) AS sub
    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
) AS estadisticas_json
FROM dbo.boxeadores AS b
WHERE b.boxeador_id <= 4;
GO

-- 3) Fuzzy string matching: encontrar un boxeador aunque el nombre esté mal escrito
SELECT TOP (5) nombre, EDIT_DISTANCE(nombre, N'Hugo La Bestia Marin') AS distancia_edicion
FROM dbo.boxeadores
ORDER BY distancia_edicion, nombre;
GO

-- 4) Expresiones regulares: validación de licencias y búsqueda por palabras clave
SELECT boxeador_id, licencia FROM dbo.boxeadores
WHERE NOT REGEXP_LIKE(licencia, '^FRB-[0-9]{4}-[0-9]{4}$');

SELECT COUNT(*) AS informes_con_distancia_o_cuerdas
FROM dbo.informes_scouting
WHERE REGEXP_LIKE(reporte_texto, 'distancia|cuerdas', 'i');
GO

-- 5) Una licencia mal formada debe ser rechazada por el CHECK (error 547)
BEGIN TRY
    INSERT INTO dbo.boxeadores (club_id, licencia, nombre, fecha_nacimiento, peso_kg, guardia)
    VALUES (1, 'LICENCIA-MALA', N'Prueba', '2005-01-01', 70, N'Diestro');
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS numero_error, ERROR_MESSAGE() AS mensaje;
END CATCH;
GO