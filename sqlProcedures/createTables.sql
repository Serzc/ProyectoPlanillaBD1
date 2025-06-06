-- Tablas de catálogo
CREATE TABLE TipoDocumentoIdentidad (
    id INT PRIMARY KEY,
    Nombre VARCHAR(50) NOT NULL
);

CREATE TABLE TipoJornada (
    id INT PRIMARY KEY,
    Nombre VARCHAR(50) NOT NULL,
    HoraInicio TIME NOT NULL,
    HoraFin TIME NOT NULL
);

CREATE TABLE Puesto (
    id INT IDENTITY(1,1) PRIMARY KEY,
    Nombre VARCHAR(100) NOT NULL,
    SalarioXHora DECIMAL(10,2) NOT NULL
);

CREATE TABLE Departamento (
    id INT PRIMARY KEY,
    Nombre VARCHAR(100) NOT NULL
);

CREATE TABLE Feriado (
    id INT PRIMARY KEY,
    Nombre VARCHAR(100) NOT NULL,
    Fecha DATE NOT NULL
);

CREATE TABLE TipoMovimiento (
    id INT PRIMARY KEY,
    Nombre VARCHAR(100) NOT NULL
);

CREATE TABLE TipoDeduccion (
    id INT PRIMARY KEY,
    Nombre VARCHAR(100) NOT NULL,
    Obligatorio BIT NOT NULL,
    Porcentual BIT NOT NULL,
    Valor DECIMAL(10,2) NOT NULL
);

CREATE TABLE TipoEvento (
    id INT PRIMARY KEY,
    Nombre VARCHAR(100) NOT NULL
);

-- Tablas de operación
CREATE TABLE Usuario (
    id INT IDENTITY(1,1) PRIMARY KEY,
    Username VARCHAR(50) NOT NULL UNIQUE,
    Password VARCHAR(100) NOT NULL,
    Tipo INT NOT NULL, -- 1=Administrador, 2=Empleado
    idEmpleado INT NULL -- Solo para usuarios empleado
);

CREATE TABLE Empleado (
    id INT IDENTITY(1,1) PRIMARY KEY,
    Nombre VARCHAR(100) NOT NULL,
    idTipoDocumento INT NOT NULL,
    ValorDocumentoIdentidad VARCHAR(50) NOT NULL UNIQUE,
    FechaNacimiento DATE NULL,
    FechaContratacion DATE NOT NULL,
    idPuesto INT NOT NULL,
    idDepartamento INT NOT NULL,
    SaldoVacaciones INT DEFAULT 0,
    Activo BIT NOT NULL DEFAULT 1,
    FOREIGN KEY (idTipoDocumento) REFERENCES TipoDocumentoIdentidad(id),
    FOREIGN KEY (idPuesto) REFERENCES Puesto(id),
    FOREIGN KEY (idDepartamento) REFERENCES Departamento(id)
);

CREATE TABLE EmpleadoDeduccion (
    id INT IDENTITY(1,1) PRIMARY KEY,
    idEmpleado INT NOT NULL,
    idTipoDeduccion INT NOT NULL,
    ValorPorcentual DECIMAL(5,2) NULL,
    ValorFijo DECIMAL(10,2) NULL,
    FechaAsociacion DATE NOT NULL DEFAULT GETDATE(),
    FechaDesasociacion DATE NULL,
    FOREIGN KEY (idEmpleado) REFERENCES Empleado(id),
    FOREIGN KEY (idTipoDeduccion) REFERENCES TipoDeduccion(id)
);

CREATE TABLE JornadaEmpleado (
    id INT IDENTITY(1,1) PRIMARY KEY,
    idEmpleado INT NOT NULL,
    idTipoJornada INT NOT NULL,
    FechaInicio DATE NOT NULL,
    FechaFin DATE NOT NULL,
    FOREIGN KEY (idEmpleado) REFERENCES Empleado(id),
    FOREIGN KEY (idTipoJornada) REFERENCES TipoJornada(id)
);

CREATE TABLE MesPlanilla (
    id INT IDENTITY(1,1) PRIMARY KEY,
    Anio INT NOT NULL,
    Mes INT NOT NULL,
    FechaInicio DATE NOT NULL,
    FechaFin DATE NOT NULL,
    Cerrado BIT NOT NULL DEFAULT 0
);

CREATE TABLE SemanaPlanilla (
    id INT IDENTITY(1,1) PRIMARY KEY,
    idMesPlanilla INT NOT NULL,
    Semana INT NOT NULL,
    FechaInicio DATE NOT NULL,
    FechaFin DATE NOT NULL,
    Cerrado BIT NOT NULL DEFAULT 0,
    FOREIGN KEY (idMesPlanilla) REFERENCES MesPlanilla(id)
);

CREATE TABLE PlanillaSemXEmpleado (
    id INT IDENTITY(1,1) PRIMARY KEY,
    idSemanaPlanilla INT NOT NULL,
    idEmpleado INT NOT NULL,
    SalarioBruto DECIMAL(12,2) NOT NULL DEFAULT 0,
    TotalDeducciones DECIMAL(12,2) NOT NULL DEFAULT 0,
    SalarioNeto DECIMAL(12,2) NOT NULL DEFAULT 0,
    FOREIGN KEY (idSemanaPlanilla) REFERENCES SemanaPlanilla(id),
    FOREIGN KEY (idEmpleado) REFERENCES Empleado(id)
);

CREATE TABLE PlanillaMexXEmpleado (
    id INT IDENTITY(1,1) PRIMARY KEY,
    idMesPlanilla INT NOT NULL,
    idEmpleado INT NOT NULL,
    SalarioBruto DECIMAL(12,2) NOT NULL DEFAULT 0,
    TotalDeducciones DECIMAL(12,2) NOT NULL DEFAULT 0,
    SalarioNeto DECIMAL(12,2) NOT NULL DEFAULT 0,
    FOREIGN KEY (idMesPlanilla) REFERENCES MesPlanilla(id),
    FOREIGN KEY (idEmpleado) REFERENCES Empleado(id)
);

CREATE TABLE MovimientoPlanilla (
    id INT IDENTITY(1,1) PRIMARY KEY,
    idPlanillaSemXEmpleado INT NOT NULL,
    idTipoMovimiento INT NOT NULL,
    Fecha DATE NOT NULL,
    Monto DECIMAL(12,2) NOT NULL,
    Descripcion VARCHAR(255) NULL,
    FOREIGN KEY (idPlanillaSemXEmpleado) REFERENCES PlanillaSemXEmpleado(id),
    FOREIGN KEY (idTipoMovimiento) REFERENCES TipoMovimiento(id)
);

CREATE TABLE DeduccionesXEmpleadoxMes (
    id INT IDENTITY(1,1) PRIMARY KEY,
    idPlanillaMexXEmpleado INT NOT NULL,
    idTipoDeduccion INT NOT NULL,
    Monto DECIMAL(12,2) NOT NULL,
    FOREIGN KEY (idPlanillaMexXEmpleado) REFERENCES PlanillaMexXEmpleado(id),
    FOREIGN KEY (idTipoDeduccion) REFERENCES TipoDeduccion(id)
);

CREATE TABLE EventLog (
    id INT IDENTITY(1,1) PRIMARY KEY,
    FechaHora DATETIME NOT NULL DEFAULT GETDATE(),
    idUsuario INT NULL,
    idTipoEvento INT NOT NULL,
    IP VARCHAR(50) NULL,
    DatosAntes NVARCHAR(MAX) NULL,
    DatosDespues NVARCHAR(MAX) NULL,
    Parametros NVARCHAR(MAX) NULL,
    FOREIGN KEY (idUsuario) REFERENCES Usuario(id),
    FOREIGN KEY (idTipoEvento) REFERENCES TipoEvento(id)
);

CREATE TABLE Asistencia (
    id INT IDENTITY(1,1) PRIMARY KEY,
    idEmpleado INT NOT NULL,
    Fecha DATE NOT NULL,
    HoraEntrada DATETIME NOT NULL,
    HoraSalida DATETIME NOT NULL,
    Procesado BIT NOT NULL DEFAULT 0,
    FOREIGN KEY (idEmpleado) REFERENCES Empleado(id)
);

CREATE TABLE MovimientoXHora (
    id INT IDENTITY(1,1) PRIMARY KEY,
    idMovimiento INT NOT NULL,
    idAsistencia INT NOT NULL,
    CantidadHoras DECIMAL(5,2) NULL,
    FOREIGN KEY (idMovimiento) REFERENCES MovimientoPlanilla(id),
    FOREIGN KEY (idAsistencia) REFERENCES Asistencia(id)

);

CREATE TABLE TipoError (
    id INT PRIMARY KEY,
    Descripcion VARCHAR(100) NOT NULL
);