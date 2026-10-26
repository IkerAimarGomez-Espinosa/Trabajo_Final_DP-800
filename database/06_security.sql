USE BoxScoutJunior;
GO

-- 1. Roles y usuarios de prueba (sin login: se usan con EXECUTE AS)
CREATE ROLE FederacionAdmin;
CREATE ROLE ClubLectura;

CREATE USER admin_fed         WITHOUT LOGIN;
CREATE USER entrenador_rayo   WITHOUT LOGIN;
CREATE USER entrenador_acero  WITHOUT LOGIN;

ALTER ROLE FederacionAdmin ADD MEMBER admin_fed;
ALTER ROLE ClubLectura     ADD MEMBER entrenador_rayo;
ALTER ROLE ClubLectura     ADD MEMBER entrenador_acero;
GO

-- 2. Permisos con mínimo privilegio
GRANT CONTROL ON SCHEMA::dbo TO FederacionAdmin;
GRANT UNMASK TO FederacionAdmin;

GRANT SELECT ON dbo.clubes               TO ClubLectura;
GRANT SELECT ON dbo.boxeadores           TO ClubLectura;
GRANT SELECT ON dbo.combates             TO ClubLectura;
GRANT SELECT ON dbo.fichas_medicas       TO ClubLectura;
GRANT SELECT ON dbo.v_ranking_boxeadores TO ClubLectura;

DENY SELECT ON dbo.informes_scouting TO ClubLectura;
DENY INSERT, UPDATE, DELETE ON SCHEMA::dbo TO ClubLectura;
GO

-- 3. Row-Level Security: cada usuario de club solo ve los boxeadores de su club
CREATE TABLE dbo.usuarios_club (
    usuario SYSNAME NOT NULL CONSTRAINT PK_usuarios_club PRIMARY KEY,
    club_id INT NOT NULL CONSTRAINT FK_usuarios_club_clubes REFERENCES dbo.clubes(club_id)
);

INSERT INTO dbo.usuarios_club (usuario, club_id) VALUES
(N'entrenador_rayo', 1),
(N'entrenador_acero', 2);
GO

CREATE SCHEMA seguridad AUTHORIZATION dbo;
GO

CREATE FUNCTION seguridad.fn_filtro_club (@club_id INT)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
(
    SELECT 1 AS permitido
    WHERE IS_MEMBER(N'db_owner') = 1
       OR IS_MEMBER(N'FederacionAdmin') = 1
       OR EXISTS (SELECT 1 FROM dbo.usuarios_club AS u
                  WHERE u.usuario = USER_NAME() AND u.club_id = @club_id)
);
GO

CREATE SECURITY POLICY seguridad.pol_boxeadores_por_club
ADD FILTER PREDICATE seguridad.fn_filtro_club(club_id) ON dbo.boxeadores
WITH (STATE = ON);
GO