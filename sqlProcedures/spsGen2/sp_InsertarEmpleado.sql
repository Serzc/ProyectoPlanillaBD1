CREATE OR ALTER PROCEDURE sp_InsertarEmpleado
    @inNombre VARCHAR(100),
    @inIdTipoDocumento INT,
    @inValorDocumentoIdentidad VARCHAR(50),
    @inFechaNacimiento DATE = NULL,
    @inIdPuesto INT,
    @inIdDepartamento INT,
    @inUsername VARCHAR(50) = NULL,
    @inPassword VARCHAR(100) = NULL,
    @inPostedByUsername VARCHAR(50) = NULL,
    @outResultado INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @idEmpleado INT;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Insertar empleado
        INSERT INTO Empleado (
            Nombre, 
            idTipoDocumento, 
            ValorDocumentoIdentidad, 
            FechaNacimiento, 
            FechaContratacion, 
            idPuesto, 
            idDepartamento
        )
        VALUES (
            @inNombre, 
            @inIdTipoDocumento, 
            @inValorDocumentoIdentidad, 
            @inFechaNacimiento, 
            GETDATE(), 
            @inIdPuesto, 
            @inIdDepartamento
        );
        
        SET @idEmpleado = SCOPE_IDENTITY();
        
        -- Crear usuario si se proporcionan credenciales
        IF @inUsername IS NOT NULL AND @inPassword IS NOT NULL
        BEGIN
            INSERT INTO Usuario (
                Username, 
                Password, 
                Tipo, 
                idEmpleado
            )
            VALUES (
                @inUsername, 
                @inPassword, 
                2, -- Tipo empleado
                @idEmpleado
            );
        END
        
        -- Asociar deducciones obligatorias
        --INSERT INTO EmpleadoDeduccion (
        --    idEmpleado, 
        --    idTipoDeduccion, 
        --    ValorPorcentual
        --)
        --SELECT 
        --    @idEmpleado, 
        --    id, 
        --    Valor
        --FROM TipoDeduccion
        --WHERE Obligatorio = 1 AND Porcentual = 1;
        
        --Ya no sirve, se cubre con el trigger trg_AsociarDeduccionesObligatorias
        
        DECLARE @idEventoInsertEmpleado INT =
            (SELECT id FROM TipoEvento WHERE Nombre = 'Insertar empleado');
        
        DECLARE @idPostByUser INT = NULL;
        IF @inPostedByUsername IS NOT NULL
        BEGIN
            SET @idPostByUser = 
                (SELECT id FROM Usuario WHERE Username = @inPostedByUsername);
        END

        DECLARE @params_JSON NVARCHAR(MAX) = 
            JSON_MODIFY(JSON_MODIFY(JSON_MODIFY(JSON_MODIFY(JSON_MODIFY(
                '{}',
                '$.Nombre', @inNombre),
                '$.TipoDocumento', @inIdTipoDocumento),
                '$.ValorDocumento', @inValorDocumentoIdentidad),
                '$.Puesto', @inIdPuesto),
                '$.Departamento', @inIdDepartamento);
        -- Registrar en bitácora
        INSERT INTO EventLog (
            idTipoEvento
            , idUsuario
            , IP
            , Parametros
        )
        VALUES (
            @idEventoInsertEmpleado
            , @idPostByUser
            , NULL -- IP no se maneja en este contexto
            , @params_JSON
            );
        
        COMMIT;
        SET @outResultado = 0; -- Éxito
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK;
            
        SET @outResultado = 50000 + ERROR_NUMBER();
        INSERT INTO EventLog (
            idTipoEvento, 
            Parametros
        )
        VALUES (
            5, -- TipoEvento: Insertar empleado
            JSON_MODIFY('{}', '$.Error', ERROR_MESSAGE())
        );
    END CATCH;
END;