USE BoxScoutJunior;
GO

-- 1. Clubes
INSERT INTO dbo.clubes (nombre, ciudad) VALUES
(N'Rayo del Norte',   N'Madrid'),
(N'Guantes de Acero', N'Barcelona'),
(N'Puño de Hierro',   N'Valencia'),
(N'Ring Sevilla',     N'Sevilla');

-- 2. Boxeadores 1-4: los del guion original
INSERT INTO dbo.boxeadores (club_id, licencia, nombre, fecha_nacimiento, peso_kg, guardia) VALUES
(1, 'FRB-2026-0001', N'Hugo "La Bestia" Marín',    '2002-03-14', 72.5, N'Diestro'),
(1, 'FRB-2026-0002', N'Leo "Tornado" Silva',       '2004-07-02', 65.0, N'Zurdo'),
(2, 'FRB-2026-0003', N'Marcos "El Muro" Pineda',   '2001-11-23', 71.0, N'Diestro'),
(2, 'FRB-2026-0004', N'Dani "Viper" López',        '2005-01-30', 64.5, N'Zurdo');

-- 3. Boxeadores 5-48: generados (peso creciente de 54 a 84,1 kg; zurdos cuando el número es múltiplo de 3)
INSERT INTO dbo.boxeadores (club_id, licencia, nombre, fecha_nacimiento, peso_kg, guardia)
SELECT 1 + (value % 4),
       CONCAT('FRB-2026-', RIGHT(CONCAT('0000', value), 4)),
       CONCAT(
         CHOOSE(value % 11 + 1, N'Álvaro', N'Bruno', N'Cristian', N'Diego', N'Enzo', N'Fran', N'Gonzalo', N'Iván', N'Jon', N'Kevin', N'Lucas'),
         N' ',
         CHOOSE(value % 12 + 1, N'Ortega', N'Navarro', N'Ibáñez', N'Campos', N'Romero', N'Vidal', N'Herrera', N'Prieto', N'Cano', N'Soler', N'Giménez', N'Lara')),
       DATEADD(DAY, (value * 97) % 2000, CAST('2004-01-01' AS DATE)),
       CAST(54 + (value - 5) * 0.7 AS DECIMAL(5,2)),
       IIF(value % 3 = 0, N'Zurdo', N'Diestro')
FROM GENERATE_SERIES(5, 48)
ORDER BY value;

-- 4. Fichas médicas (una por boxeador; no apto cuando el id es múltiplo de 11)
INSERT INTO dbo.fichas_medicas (boxeador_id, dni, telefono_emergencia, lesiones, apto, fecha_revision)
SELECT b.boxeador_id,
       CONCAT(10000000 + b.boxeador_id * 7919, CHAR(65 + b.boxeador_id % 23)),
       CONCAT(N'+34 6', 10000000 + (b.boxeador_id * 1234567) % 90000000),
       CASE b.boxeador_id % 5
            WHEN 0 THEN N'Esguince leve de muñeca derecha (2026-05)'
            WHEN 2 THEN N'Fractura de nudillo ya curada (2025-11)'
            ELSE N'Sin lesiones registradas'
       END,
       IIF(b.boxeador_id % 11 = 0, 0, 1),
       DATEADD(DAY, -(b.boxeador_id % 60), CAST('2026-09-30' AS DATE))
FROM dbo.boxeadores AS b
ORDER BY b.boxeador_id;

-- 5. Combates entre los cuatro boxeadores originales
INSERT INTO dbo.combates (fecha, boxeador_rojo_id, boxeador_azul_id, ganador_id, metodo, asaltos) VALUES
('2026-05-10', 1, 3, 3, N'Puntos', 3),
('2026-06-14', 1, 3, 1, N'TKO',    2),
('2026-07-19', 3, 1, 3, N'Puntos', 3),
('2026-05-24', 2, 4, 2, N'KO',     1),
('2026-06-28', 4, 2, 2, N'Puntos', 3),
('2026-08-09', 2, 4, 4, N'TKO',    3);

-- 6. 120 combates generados entre boxeadores de peso parecido (ids 8 a 48)
WITH n AS (
    SELECT value AS n FROM GENERATE_SERIES(1, 120)
),
par AS (
    SELECT n, 8 + (n * 7) % 41 AS rojo, 1 + n % 3 AS d FROM n
),
cb AS (
    SELECT n, rojo, IIF(rojo + d <= 48, rojo + d, rojo - d) AS azul FROM par
)
INSERT INTO dbo.combates (fecha, boxeador_rojo_id, boxeador_azul_id, ganador_id, metodo, asaltos)
SELECT DATEADD(DAY, -n * 3, CAST('2026-09-30' AS DATE)),
       rojo,
       azul,
       CASE WHEN n % 17 = 0 THEN NULL WHEN (n * 13) % 10 < 5 THEN rojo ELSE azul END,
       CASE WHEN n % 17 = 0 THEN N'Empate' WHEN n % 6 = 0 THEN N'KO' WHEN n % 6 = 1 THEN N'TKO' ELSE N'Puntos' END,
       CASE WHEN n % 17 = 0 THEN 3 WHEN n % 6 IN (0, 1) THEN 1 + n % 3 ELSE 3 END
FROM cb;

-- 7. Récord de victorias y derrotas calculado a partir de los combates
--    (el trigger de la sección 4 lo mantendrá al día en los combates nuevos)
UPDATE b
SET victorias = (SELECT COUNT(*) FROM dbo.combates c WHERE c.ganador_id = b.boxeador_id),
    derrotas  = (SELECT COUNT(*) FROM dbo.combates c
                 WHERE c.ganador_id IS NOT NULL
                   AND c.ganador_id <> b.boxeador_id
                   AND b.boxeador_id IN (c.boxeador_rojo_id, c.boxeador_azul_id))
FROM dbo.boxeadores AS b;
GO

-- 8. Informes de scouting
DECLARE @estilos TABLE (idx INT PRIMARY KEY, texto NVARCHAR(400) NOT NULL);
INSERT INTO @estilos (idx, texto) VALUES
(0, N'Estilo fajador muy agresivo. Busca siempre el intercambio en la corta distancia y presiona sin descanso hacia las cuerdas. Pega fuerte al cuerpo.'),
(1, N'Boxeador técnico y escurridizo. Usa muy bien la mano adelantada para mantener la distancia. Gran movilidad de piernas, siempre fuera de la línea de fuego.'),
(2, N'Estilo conservador y contragolpeador. Guardia cerrada, difícil de penetrar. Espera el error del rival para conectar directos y ganchos de contra.'),
(3, N'Púgil explosivo con poca resistencia aérobica. Muy peligroso en los primeros asaltos con series rápidas de combinaciones. Baja el ritmo a partir del tercer asalto.'),
(4, N'Boxeador de largo alcance con un jab constante que controla el centro del ring. Prefiere pelear a media y larga distancia y rara vez entra al cuerpo a cuerpo.'),
(5, N'Presionador de ritmo alto y excelente fondo físico. Mantiene un volumen de golpes constante durante todo el combate y asfixia al rival contra las cuerdas.');

DECLARE @debilidades TABLE (idx INT PRIMARY KEY, texto NVARCHAR(300) NOT NULL);
INSERT INTO @debilidades (idx, texto) VALUES
(0, N'Debilidad: tras lanzar la combinación baja la mano derecha y deja el mentón expuesto.'),
(1, N'Debilidad: le falta pegada y pierde asaltos cuando el rival le corta el ring.'),
(2, N'Debilidad: es previsible y regala asaltos por falta de iniciativa si el rival no ataca.');

-- 8a. Informes originales del guion (boxeadores 1-4)
INSERT INTO dbo.informes_scouting (boxeador_id, fecha_informe, entrenador, reporte_texto) VALUES
(1, '2026-09-15', N'Carlos T.', N'Estilo fajador muy agresivo. Busca siempre el intercambio en la corta distancia. Excelente gancho al hígado, pero descuida la guardia al atacar.'),
(2, '2026-09-20', N'Carlos T.', N'Boxeador técnico y escurridizo. Utiliza muy bien su mano adelantada para mantener la distancia. Gran movilidad de piernas, ideal para esquivar.'),
(3, '2026-09-10', N'Elena R.',  N'Estilo conservador y contragolpeador. Guardia de hierro, muy difícil de penetrar. Espera el fallo del rival para conectar directos pesados.'),
(4, '2026-09-22', N'Elena R.',  N'Púgil explosivo pero con poca resistencia aérobica. Muy peligroso en los primeros dos asaltos. Tiende a bajar las manos cuando se cansa.');

-- 8b. Un informe por cada boxeador generado (5-48)
INSERT INTO dbo.informes_scouting (boxeador_id, fecha_informe, entrenador, reporte_texto)
SELECT b.boxeador_id,
       DATEADD(DAY, -((b.boxeador_id * 2) % 40), CAST('2026-09-30' AS DATE)),
       CHOOSE(b.boxeador_id % 4 + 1, N'Carlos T.', N'Elena R.', N'Marta S.', N'Pablo V.'),
       CONCAT(e.texto, N' ', d.texto)
FROM dbo.boxeadores AS b
JOIN @estilos      AS e ON e.idx = b.boxeador_id % 6
JOIN @debilidades  AS d ON d.idx = (b.boxeador_id / 6) % 3
WHERE b.boxeador_id >= 5
ORDER BY b.boxeador_id;

-- 8c. Segundo informe de seguimiento para los boxeadores generados con id múltiplo de 3
INSERT INTO dbo.informes_scouting (boxeador_id, fecha_informe, entrenador, reporte_texto)
SELECT b.boxeador_id,
       DATEADD(DAY, -(b.boxeador_id % 10), CAST('2026-09-30' AS DATE)),
       CHOOSE((b.boxeador_id + 1) % 4 + 1, N'Carlos T.', N'Elena R.', N'Marta S.', N'Pablo V.'),
       CONCAT(N'Seguimiento: ', e.texto, N' ', d.texto)
FROM dbo.boxeadores AS b
JOIN @estilos      AS e ON e.idx = b.boxeador_id % 6
JOIN @debilidades  AS d ON d.idx = (b.boxeador_id / 6 + 1) % 3
WHERE b.boxeador_id >= 5 AND b.boxeador_id % 3 = 0
ORDER BY b.boxeador_id;
GO