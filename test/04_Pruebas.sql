USE BoxScoutJunior;
GO

-- Vista
SELECT TOP (5) * FROM dbo.v_ranking_boxeadores WHERE categoria = N'Medio' ORDER BY puesto_categoria, nombre;

-- Función
SELECT * FROM dbo.fn_rivales_candidatos(1, 3.0) ORDER BY diferencia_kg, nombre;

-- Antes
SELECT boxeador_id, nombre, victorias, derrotas FROM dbo.boxeadores WHERE boxeador_id IN (1, 3);

-- Registrar un combate: Hugo (1) gana a Marcos (3)
EXEC dbo.usp_registrar_combate @fecha = '2026-10-10', @rojo = 1, @azul = 3, @ganador = 1, @metodo = N'Puntos', @asaltos = 3;

-- Después: Hugo tiene una victoria más y Marcos una derrota más
SELECT boxeador_id, nombre, victorias, derrotas FROM dbo.boxeadores WHERE boxeador_id IN (1, 3);

-- Borrar el combate de prueba: el trigger revierte los récords
DELETE FROM dbo.combates WHERE fecha = '2026-10-10' AND boxeador_rojo_id = 1 AND boxeador_azul_id = 3;
SELECT boxeador_id, nombre, victorias, derrotas FROM dbo.boxeadores WHERE boxeador_id IN (1, 3);

EXEC dbo.usp_registrar_combate @fecha = '2026-10-11', @rojo = 5, @azul = 5, @ganador = 5, @metodo = N'KO', @asaltos = 1;