USE BoxScoutJunior;
GO

CREATE TABLE dbo.clubes (
    club_id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_clubes PRIMARY KEY,
    nombre  NVARCHAR(100) NOT NULL CONSTRAINT UQ_clubes_nombre UNIQUE,
    ciudad  NVARCHAR(100) NOT NULL
);

CREATE TABLE dbo.boxeadores (
    boxeador_id      INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_boxeadores PRIMARY KEY,
    club_id          INT NOT NULL CONSTRAINT FK_boxeadores_clubes REFERENCES dbo.clubes(club_id),
    licencia         VARCHAR(13) NOT NULL CONSTRAINT UQ_boxeadores_licencia UNIQUE,
    nombre           NVARCHAR(100) NOT NULL,
    fecha_nacimiento DATE NOT NULL,
    peso_kg          DECIMAL(5,2) NOT NULL,
    guardia          NVARCHAR(20) NOT NULL,
    victorias        INT NOT NULL CONSTRAINT DF_boxeadores_victorias DEFAULT 0,
    derrotas         INT NOT NULL CONSTRAINT DF_boxeadores_derrotas DEFAULT 0,
    CONSTRAINT CK_boxeadores_peso     CHECK (peso_kg BETWEEN 40 AND 140),
    CONSTRAINT CK_boxeadores_guardia  CHECK (guardia IN (N'Diestro', N'Zurdo')),
    CONSTRAINT CK_boxeadores_record   CHECK (victorias >= 0 AND derrotas >= 0),
    CONSTRAINT CK_boxeadores_licencia CHECK (REGEXP_LIKE(licencia, '^FRB-[0-9]{4}-[0-9]{4}$'))
);

CREATE TABLE dbo.combates (
    combate_id       INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_combates PRIMARY KEY,
    fecha            DATE NOT NULL,
    boxeador_rojo_id INT NOT NULL,
    boxeador_azul_id INT NOT NULL,
    ganador_id       INT NULL,
    metodo           NVARCHAR(20) NOT NULL,
    asaltos          INT NOT NULL,
    CONSTRAINT FK_combates_rojo    FOREIGN KEY (boxeador_rojo_id) REFERENCES dbo.boxeadores(boxeador_id),
    CONSTRAINT FK_combates_azul    FOREIGN KEY (boxeador_azul_id) REFERENCES dbo.boxeadores(boxeador_id),
    CONSTRAINT FK_combates_ganador FOREIGN KEY (ganador_id)       REFERENCES dbo.boxeadores(boxeador_id),
    CONSTRAINT CK_combates_distintos CHECK (boxeador_rojo_id <> boxeador_azul_id),
    CONSTRAINT CK_combates_ganador   CHECK (ganador_id IS NULL OR ganador_id IN (boxeador_rojo_id, boxeador_azul_id)),
    CONSTRAINT CK_combates_metodo    CHECK (metodo IN (N'KO', N'TKO', N'Puntos', N'Descalificacion', N'Empate')),
    CONSTRAINT CK_combates_asaltos   CHECK (asaltos BETWEEN 1 AND 12)
);

CREATE TABLE dbo.fichas_medicas (
    ficha_id            INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_fichas_medicas PRIMARY KEY,
    boxeador_id         INT NOT NULL,
    dni                 NVARCHAR(9)   MASKED WITH (FUNCTION = 'partial(0,"XXXXX",4)')   NOT NULL,
    telefono_emergencia NVARCHAR(20)  MASKED WITH (FUNCTION = 'partial(0,"XXX-XXX-",3)') NOT NULL,
    lesiones            NVARCHAR(500) MASKED WITH (FUNCTION = 'default()')               NOT NULL,
    apto                BIT NOT NULL,
    fecha_revision      DATE NOT NULL,
    CONSTRAINT UQ_fichas_boxeador   UNIQUE (boxeador_id),
    CONSTRAINT FK_fichas_boxeadores FOREIGN KEY (boxeador_id) REFERENCES dbo.boxeadores(boxeador_id),
    CONSTRAINT CK_fichas_dni        CHECK (REGEXP_LIKE(dni, '^[0-9]{8}[A-Z]$'))
);

CREATE TABLE dbo.informes_scouting (
    informe_id     INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_informes_scouting PRIMARY KEY,
    boxeador_id    INT NOT NULL CONSTRAINT FK_informes_boxeadores REFERENCES dbo.boxeadores(boxeador_id),
    fecha_informe  DATE NOT NULL,
    entrenador     NVARCHAR(100) NOT NULL,
    reporte_texto  NVARCHAR(MAX) NOT NULL,
    reporte_vector VECTOR(768) NULL   -- nomic-embed-text devuelve 768 dimensiones
);
GO

-- Índices sobre claves foráneas
CREATE INDEX IX_boxeadores_club   ON dbo.boxeadores (club_id);
CREATE INDEX IX_combates_rojo     ON dbo.combates (boxeador_rojo_id);
CREATE INDEX IX_combates_azul     ON dbo.combates (boxeador_azul_id);
CREATE INDEX IX_combates_ganador  ON dbo.combates (ganador_id);
CREATE INDEX IX_informes_boxeador ON dbo.informes_scouting (boxeador_id);
GO

SELECT name AS tabla FROM sys.tables ORDER BY name;
GO