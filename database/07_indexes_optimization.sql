USE BoxScoutJunior;
GO
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO
CHECKPOINT;
DBCC DROPCLEANBUFFERS;
GO

CREATE NONCLUSTERED INDEX IX_bench_guardia_peso
ON dbo.boxeadores_bench (guardia, peso_kg)
INCLUDE (nombre, victorias);
GO

SELECT nombre, victorias
FROM dbo.boxeadores_bench
WHERE guardia = N'Zurdo' AND peso_kg BETWEEN 64.00 AND 65.00;
GO