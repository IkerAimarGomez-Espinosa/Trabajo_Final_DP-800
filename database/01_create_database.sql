USE master;
GO
IF DB_ID(N'BoxScoutJunior') IS NOT NULL
BEGIN
ALTER DATABASE BoxScoutJunior SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
DROP DATABASE BoxScoutJunior;
END;
GO
CREATE DATABASE BoxScoutJunior;
GO
ALTER DATABASE BoxScoutJunior SET COMPATIBILITY_LEVEL = 170;
GO
USE BoxScoutJunior;
GO

-- Necesario para CREATE VECTOR INDEX / VECTOR_SEARCH y, según versión, el
fuzzy matching
ALTER DATABASE SCOPED CONFIGURATION SET PREVIEW_FEATURES = ON;
GO
SELECT name, compatibility_level FROM sys.databases WHERE name =
N'BoxScoutJunior';
SELECT name, value FROM sys.database_scoped_configurations WHERE name =
N'PREVIEW_FEATURES';
GO
