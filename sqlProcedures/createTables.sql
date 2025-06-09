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
    SalarioXHora DECIMAL(25,4) NOT NULL
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
    Valor DECIMAL(25,4) NOT NULL
);

CREATE TABLE TipoEvento (
    id INT PRIMARY KEY,
    Nombre VARCHAR(100) NOT NULL
);
--<TipoEvento Id="1" Nombre="Login"/>
--<TipoEvento Id="2" Nombre="Logout"/>
--<TipoEvento Id="3" Nombre="Listar empleados"/>
--<TipoEvento Id="4" Nombre="Listar empleados con filtro"/>
--<TipoEvento Id="5" Nombre="Insertar empleado"/>
--<TipoEvento Id="6" Nombre="Eliminar empleado"/>
--<TipoEvento Id="7" Nombre="Editar empleado"/>
--<TipoEvento Id="8" Nombre="Asociar deducción"/>
--<TipoEvento Id="9" Nombre="Desasociar deducción"/>
--<TipoEvento Id="10" Nombre="Consultar una planilla semanal"/>
--<TipoEvento Id="11" Nombre="Consultar una planilla mensual"/>
--<TipoEvento Id="12" Nombre="Impersonar empleado"/>
--<TipoEvento Id="13" Nombre="Regresar a interfaz de administrador"/>
--<TipoEvento Id="14" Nombre="Ingreso de marcas de asistencia"/>
--<TipoEvento Id="15" Nombre="Ingreso nuevas jornadas"/>
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
    ValorPorcentual DECIMAL(25,4) NULL,
    ValorFijo DECIMAL(25,4) NULL,
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
    SalarioBruto DECIMAL(25,4) NOT NULL DEFAULT 0,
    TotalDeducciones DECIMAL(25,4) NOT NULL DEFAULT 0,
    SalarioNeto DECIMAL(25,4) NOT NULL DEFAULT 0,
    FOREIGN KEY (idSemanaPlanilla) REFERENCES SemanaPlanilla(id),
    FOREIGN KEY (idEmpleado) REFERENCES Empleado(id)
);

CREATE TABLE PlanillaMexXEmpleado (
    id INT IDENTITY(1,1) PRIMARY KEY,
    idMesPlanilla INT NOT NULL,
    idEmpleado INT NOT NULL,
    SalarioBruto DECIMAL(25,4) NOT NULL DEFAULT 0,
    TotalDeducciones DECIMAL(25,4) NOT NULL DEFAULT 0,
    SalarioNeto DECIMAL(25,4) NOT NULL DEFAULT 0,
    FOREIGN KEY (idMesPlanilla) REFERENCES MesPlanilla(id),
    FOREIGN KEY (idEmpleado) REFERENCES Empleado(id)
);

CREATE TABLE MovimientoPlanilla (
    id INT IDENTITY(1,1) PRIMARY KEY,
    idPlanillaSemXEmpleado INT NOT NULL,
    idTipoMovimiento INT NOT NULL,
    Fecha DATE NOT NULL,
    Monto DECIMAL(25,4) NOT NULL,
    Descripcion VARCHAR(255) NULL,
    FOREIGN KEY (idPlanillaSemXEmpleado) REFERENCES PlanillaSemXEmpleado(id),
    FOREIGN KEY (idTipoMovimiento) REFERENCES TipoMovimiento(id)
);

CREATE TABLE DeduccionesXEmpleadoxMes (
    id INT IDENTITY(1,1) PRIMARY KEY,
    idPlanillaMexXEmpleado INT NOT NULL,
    idTipoDeduccion INT NOT NULL,
    Monto DECIMAL(25,4) NOT NULL,
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
    CantidadHoras DECIMAL(25,4) NULL,
    FOREIGN KEY (idMovimiento) REFERENCES MovimientoPlanilla(id),
    FOREIGN KEY (idAsistencia) REFERENCES Asistencia(id)

);

CREATE TABLE TipoError (
    id INT PRIMARY KEY,
    Descripcion VARCHAR(100) NOT NULL
);
CREATE TABLE DBError (
    id INT IDENTITY(1,1) PRIMARY KEY,
    FechaHora DATETIME NOT NULL DEFAULT GETDATE(),
    idTipoError INT NOT NULL,
    Mensaje NVARCHAR(MAX) NOT NULL,
    Procedimiento NVARCHAR(100) NULL,
    Linea INT NULL
);