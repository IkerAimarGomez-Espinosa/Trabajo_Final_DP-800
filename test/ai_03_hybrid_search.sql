EXEC dbo.usp_buscar_sparring_hibrido
     @texto_busqueda = N'escurridizo, técnico y con movilidad de piernas',
     @peso_min = 63.0, @peso_max = 67.0, @guardia = N'Zurdo', @top = 3;

EXEC dbo.usp_buscar_sparring_hibrido
     @texto_busqueda = N'alguien que se mueve mucho y no se deja pegar',
     @peso_min = 50.0, @peso_max = 100.0, @guardia = NULL, @top = 5;

SELECT COUNT(*) AS coincidencias_por_palabra FROM dbo.informes_scouting
WHERE reporte_texto LIKE N'%se mueve%' OR reporte_texto LIKE N'%no se deja pegar%';
