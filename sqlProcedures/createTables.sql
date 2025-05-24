-- Tablas de catálogo
CREATE TABLE TipoDocumentoIdentidad (
    Id INT PRIMARY KEY,
    Nombre VARCHAR(50) NOT NULL
);

CREATE TABLE TipoJornada (
    Id INT PRIMARY KEY,
    Nombre VARCHAR(50) NOT NULL,
    HoraInicio TIME NOT NULL,
    HoraFin TIME NOT NULL
);

CREATE TABLE Puesto (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Nombre VARCHAR(100) NOT NULL,
    SalarioXHora DECIMAL(10,2) NOT NULL
);

CREATE TABLE Departamento (
    Id INT PRIMARY KEY,
    Nombre VARCHAR(100) NOT NULL
);

CREATE TABLE Feriado (
    Id INT PRIMARY KEY,
    Nombre VARCHAR(100) NOT NULL,
    Fecha DATE NOT NULL
);

CREATE TABLE TipoMovimiento (
    Id INT PRIMARY KEY,
    Nombre VARCHAR(100) NOT NULL
);

CREATE TABLE TipoDeduccion (
    Id INT PRIMARY KEY,
    Nombre VARCHAR(100) NOT NULL,
    Obligatorio BIT NOT NULL,
    Porcentual BIT NOT NULL,
    Valor DECIMAL(10,2) NOT NULL
);

CREATE TABLE TipoEvento (
    Id INT PRIMARY KEY,
    Nombre VARCHAR(100) NOT NULL
);

-- Tablas de operación
CREATE TABLE Usuario (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Username VARCHAR(50) NOT NULL UNIQUE,
    Password VARCHAR(100) NOT NULL,
    Tipo INT NOT NULL, -- 1=Administrador, 2=Empleado
    EmpleadoId INT NULL -- Solo para usuarios empleado
);

CREATE TABLE Empleado (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Nombre VARCHAR(100) NOT NULL,
    TipoDocumentoId INT NOT NULL,
    ValorDocumentoIdentidad VARCHAR(50) NOT NULL UNIQUE,
    FechaNacimiento DATE NULL,
    FechaContratacion DATE NOT NULL,
    PuestoId INT NOT NULL,
    DepartamentoId INT NOT NULL,
    SaldoVacaciones INT DEFAULT 0,
    Activo BIT NOT NULL DEFAULT 1,
    FOREIGN KEY (TipoDocumentoId) REFERENCES TipoDocumentoIdentidad(Id),
    FOREIGN KEY (PuestoId) REFERENCES Puesto(Id),
    FOREIGN KEY (DepartamentoId) REFERENCES Departamento(Id)
);

CREATE TABLE EmpleadoDeduccion (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    EmpleadoId INT NOT NULL,
    TipoDeduccionId INT NOT NULL,
    ValorPorcentual DECIMAL(5,2) NULL,
    ValorFijo DECIMAL(10,2) NULL,
    FechaAsociacion DATE NOT NULL DEFAULT GETDATE(),
    FechaDesasociacion DATE NULL,
    FOREIGN KEY (EmpleadoId) REFERENCES Empleado(Id),
    FOREIGN KEY (TipoDeduccionId) REFERENCES TipoDeduccion(Id)
);

CREATE TABLE JornadaEmpleado (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    EmpleadoId INT NOT NULL,
    TipoJornadaId INT NOT NULL,
    FechaInicio DATE NOT NULL,
    FechaFin DATE NOT NULL,
    FOREIGN KEY (EmpleadoId) REFERENCES Empleado(Id),
    FOREIGN KEY (TipoJornadaId) REFERENCES TipoJornada(Id)
);

CREATE TABLE MesPlanilla (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Anio INT NOT NULL,
    Mes INT NOT NULL,
    FechaInicio DATE NOT NULL,
    FechaFin DATE NOT NULL,
    Cerrado BIT NOT NULL DEFAULT 0
);

CREATE TABLE SemanaPlanilla (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    MesPlanillaId INT NOT NULL,
    Semana INT NOT NULL,
    FechaInicio DATE NOT NULL,
    FechaFin DATE NOT NULL,
    Cerrado BIT NOT NULL DEFAULT 0,
    FOREIGN KEY (MesPlanillaId) REFERENCES MesPlanilla(Id)
);

CREATE TABLE PlanillaSemXEmpleado (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    SemanaPlanillaId INT NOT NULL,
    EmpleadoId INT NOT NULL,
    SalarioBruto DECIMAL(12,2) NOT NULL DEFAULT 0,
    TotalDeducciones DECIMAL(12,2) NOT NULL DEFAULT 0,
    SalarioNeto DECIMAL(12,2) NOT NULL DEFAULT 0,
    FOREIGN KEY (SemanaPlanillaId) REFERENCES SemanaPlanilla(Id),
    FOREIGN KEY (EmpleadoId) REFERENCES Empleado(Id)
);

CREATE TABLE PlanillaMexXEmpleado (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    MesPlanillaId INT NOT NULL,
    EmpleadoId INT NOT NULL,
    SalarioBruto DECIMAL(12,2) NOT NULL DEFAULT 0,
    TotalDeducciones DECIMAL(12,2) NOT NULL DEFAULT 0,
    SalarioNeto DECIMAL(12,2) NOT NULL DEFAULT 0,
    FOREIGN KEY (MesPlanillaId) REFERENCES MesPlanilla(Id),
    FOREIGN KEY (EmpleadoId) REFERENCES Empleado(Id)
);

CREATE TABLE MovimientoPlanilla (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    PlanillaSemXEmpleadoId INT NOT NULL,
    TipoMovimientoId INT NOT NULL,
    Fecha DATE NOT NULL,
    CantidadHoras DECIMAL(5,2) NULL,
    Monto DECIMAL(12,2) NOT NULL,
    Descripcion VARCHAR(255) NULL,
    FOREIGN KEY (PlanillaSemXEmpleadoId) REFERENCES PlanillaSemXEmpleado(Id),
    FOREIGN KEY (TipoMovimientoId) REFERENCES TipoMovimiento(Id)
);

CREATE TABLE DeduccionesXEmpleadoxMes (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    PlanillaMexXEmpleadoId INT NOT NULL,
    TipoDeduccionId INT NOT NULL,
    Monto DECIMAL(12,2) NOT NULL,
    FOREIGN KEY (PlanillaMexXEmpleadoId) REFERENCES PlanillaMexXEmpleado(Id),
    FOREIGN KEY (TipoDeduccionId) REFERENCES TipoDeduccion(Id)
);

CREATE TABLE EventLog (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    FechaHora DATETIME NOT NULL DEFAULT GETDATE(),
    UsuarioId INT NULL,
    TipoEventoId INT NOT NULL,
    IP VARCHAR(50) NULL,
    DatosAntes NVARCHAR(MAX) NULL,
    DatosDespues NVARCHAR(MAX) NULL,
    Parametros NVARCHAR(MAX) NULL,
    FOREIGN KEY (UsuarioId) REFERENCES Usuario(Id),
    FOREIGN KEY (TipoEventoId) REFERENCES TipoEvento(Id)
);

CREATE TABLE Asistencia (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    EmpleadoId INT NOT NULL,
    Fecha DATE NOT NULL,
    HoraEntrada DATETIME NOT NULL,
    HoraSalida DATETIME NOT NULL,
    Procesado BIT NOT NULL DEFAULT 0,
    FOREIGN KEY (EmpleadoId) REFERENCES Empleado(Id)
);