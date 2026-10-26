EXECUTE AS USER = N'entrenador_rayo';
SELECT USER_NAME() AS usuario_actual;
SELECT COUNT(*) AS boxeadores_visibles, MIN(club_id) AS club_min, MAX(club_id) AS club_max FROM dbo.boxeadores;
SELECT COUNT(*) AS boxeadores_del_club_2 FROM dbo.boxeadores WHERE club_id = 2;
REVERT;

EXECUTE AS USER = N'entrenador_acero';
SELECT COUNT(*) AS boxeadores_visibles, MIN(club_id) AS club_min, MAX(club_id) AS club_max FROM dbo.boxeadores;
REVERT;

EXECUTE AS USER = N'entrenador_rayo';
SELECT * FROM dbo.informes_scouting;
REVERT;

EXECUTE AS USER = N'entrenador_rayo';
DELETE FROM dbo.boxeadores WHERE boxeador_id = 1;
UPDATE dbo.boxeadores SET peso_kg = 50 WHERE boxeador_id = 1;
REVERT;

EXECUTE AS USER = N'entrenador_rayo';
SELECT TOP (3) boxeador_id, dni, telefono_emergencia, lesiones, apto FROM dbo.fichas_medicas ORDER BY boxeador_id;
REVERT;

EXECUTE AS USER = N'admin_fed';
SELECT COUNT(*) AS boxeadores_visibles FROM dbo.boxeadores;
SELECT COUNT(*) AS informes_visibles FROM dbo.informes_scouting;
SELECT TOP (3) boxeador_id, dni, telefono_emergencia, lesiones, apto FROM dbo.fichas_medicas ORDER BY boxeador_id;
REVERT;