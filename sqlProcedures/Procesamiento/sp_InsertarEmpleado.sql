CREATE OR ALTER PROCEDURE sp_InsertarEmpleado
    @inNombre VARCHAR(100),
    @inIdTipoDocumento INT,
    @inValorTipoDocumento VARCHAR(50),
    @inIdDepartamento INT,
    @inNombrePuesto VARCHAR(100),
    @inUsuario VARCHAR(50),
    @inPassword VARCHAR(100),
    @inFecha DATE,
    @inFechaNacimiento DATE = NULL,
    @inIdUsuarioOp INT,
    @outResultado INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF @inFecha IS NULL
        SET @inFecha = GETDATE();

    BEGIN TRY
        -- Validar si ya existe un empleado con el mismo ValorDocumentoIdentidad
        IF EXISTS (SELECT 1 FROM dbo.Empleado WHERE ValorDocumentoIdentidad = @inValorTipoDocumento)
        BEGIN
            SET @outResultado = 50004; -- Empleado con ValorDocumentoIdentidad ya existe
            THROW @outResultado, 'Empleado con ValorDocumentoIdentidad ya existe en inserción', 1;
        END

        -- Validar si ya existe un empleado con el mismo nombre
        IF EXISTS (SELECT 1 FROM dbo.Empleado WHERE Nombre = @inNombre)
        BEGIN
            SET @outResultado = 50005; -- Empleado con mismo nombre ya existe
            THROW @outResultado, 'Empleado con mismo nombre ya existe en inserción', 1;
        END

        -- Validar si ya existe un usuario con el mismo nombre de usuario
        IF EXISTS (SELECT 1 FROM dbo.Usuario WHERE Username = @inUsuario)
        BEGIN
            SET @outResultado = 50005; -- Usuario con mismo nombre ya existe
            THROW @outResultado, 'Usuario con mismo nombre ya existe en inserción', 1;
        END

        DECLARE @idPuesto INT;

        SELECT @idPuesto = id 
        FROM dbo.Puesto 
        WHERE Nombre = @inNombrePuesto;

        IF @idPuesto IS NULL
        BEGIN
            SET @outResultado = 50008; -- Error en la base de datos
            THROW @outResultado, 'Puesto no encontrado', 1;
        END

        BEGIN TRANSACTION;

        -- Insertar empleado
        INSERT INTO dbo.Empleado (
            Nombre, 
            idTipoDocumento, 
            ValorDocumentoIdentidad, 
            FechaNacimiento, 
            FechaContratacion, 
            idPuesto, 
            idDepartamento,
            Activo
        )
        VALUES (
            @inNombre,
            @inIdTipoDocumento,
            @inValorTipoDocumento,
            @inFechaNacimiento, 
            @inFecha, 
            @idPuesto,
            @inIdDepartamento,
            1 -- Activo
        );

        DECLARE @idEmpleado INT = SCOPE_IDENTITY();

        -- Crear usuario asociado
        INSERT INTO dbo.Usuario (
            Username,
            Password,
            Tipo,
            idEmpleado
        )
        VALUES (
            @inUsuario,
            @inPassword,
            2, -- Tipo empleado
            @idEmpleado
        );

        DECLARE @idTipoEvento INT;
        SELECT @idTipoEvento = id FROM dbo.TipoEvento WHERE Nombre = 'Insertar empleado';
        
        IF @inIdUsuarioOp IS NULL
            SET @inIdUsuarioOp = (SELECT TOP 1 id FROM dbo.Usuario WHERE Tipo = 3); -- Usuario sistema
        INSERT INTO dbo.EventLog (
            FechaHora,
            idUsuario,
            idTipoEvento,
            Parametros
        )
        VALUES (
            @inFecha,
            @inIdUsuarioOp,
            @idTipoEvento,
            JSON_QUERY(CONCAT(
                '{',
                    '"idEmpleado":"', COALESCE(CAST(@idEmpleado AS VARCHAR), 'null'), '",',
                    '"Nombre":"', @inNombre, '",',
                    '"ValorTipoDocumento":"', @inValorTipoDocumento, '",',
                    '"Usuario":"', @inUsuario, '",',
                    '"Contraseña":"', @inPassword, '",',
                    '"idPuesto":"', COALESCE(CAST(@idPuesto AS VARCHAR), 'null'), '",',
                    '"Fecha":"', FORMAT(@inFecha, 'yyyy-MM-dd'), '"',
                '}'
            ))
        );

        COMMIT TRANSACTION;
        SET @outResultado = 0;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        IF @outResultado = 0
            SET @outResultado = COALESCE(ERROR_NUMBER(), 50008);

        DECLARE @errorDesc VARCHAR(200) = CONCAT('En la fecha: ',@inFecha,' ',ERROR_MESSAGE());
        INSERT INTO dbo.DBError (
            idTipoError,
            Mensaje,
            Procedimiento,
            Linea
        )
        VALUES (
            @outResultado,
            @errorDesc,
            ERROR_PROCEDURE(),
            ERROR_LINE()
        );
    END CATCH
END;