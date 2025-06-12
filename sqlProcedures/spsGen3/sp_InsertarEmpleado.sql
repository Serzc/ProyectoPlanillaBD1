CREATE OR ALTER PROCEDURE sp_InsertarEmpleado
    @inNombre VARCHAR(100),
    @inIdTipoDocumento INT,
    @inValorTipoDocumento VARCHAR(50),
    @inIdDepartamento INT,
    @inNombrePuesto VARCHAR(100),
    @inUsuario VARCHAR(50),
    @inPassword VARCHAR(100),
    @outResultado INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        DECLARE @idPuesto INT;
        
        -- Obtener el ID del puesto por nombre
        SELECT @idPuesto = id 
        FROM dbo.Puesto 
        WHERE Nombre = @inNombrePuesto;
        
        IF @idPuesto IS NULL
        BEGIN
            SET @outResultado = 50006; -- Puesto no encontrado
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
            NULL, -- FechaNacimiento no proporcionada en XML
            GETDATE(), -- Fecha de contratación actual
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
        
        COMMIT TRANSACTION;
        SET @outResultado = 0;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        IF @outResultado = 0
            SET @outResultado = COALESCE(ERROR_NUMBER(), 50007);
        
        DECLARE @errorDesc VARCHAR(200) = ERROR_MESSAGE();
        DECLARE @errorLine INT = ERROR_LINE();
        INSERT INTO dbo.DBError (
            idTipoError,
            Mensaje,
            Procedimiento,
            Linea
        )
        VALUES (
            @outResultado,
            ERROR_MESSAGE(),
            ERROR_PROCEDURE(),
            ERROR_LINE()
        );
    END CATCH
END;