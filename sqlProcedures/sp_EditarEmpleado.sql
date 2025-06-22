CREATE OR ALTER PROCEDURE sp_EditarEmpleado
    @inId INT,
    @inNombre VARCHAR(100),
    @inIdTipoDocumento INT,
    @inValorDocumentoIdentidad VARCHAR(50),
    @inFechaNacimiento DATE,
    @inIdPuesto INT,
    @inIdDepartamento INT,
    @outResultado INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Validar si ya existe otro empleado con el mismo ValorDocumentoIdentidad
        IF EXISTS (
            SELECT 1 FROM dbo.Empleado 
            WHERE ValorDocumentoIdentidad = @inValorDocumentoIdentidad
              AND id <> @inId
        )
        BEGIN
            SET @outResultado = 50004; -- Documento ya existe
            THROW 50004, 'Empleado con ValorDocumentoIdentidad ya existe en edición', 1;
        END

        -- Validar si ya existe otro empleado con el mismo nombre
        IF EXISTS (
            SELECT 1 FROM dbo.Empleado 
            WHERE Nombre = @inNombre
              AND id <> @inId
        )
        BEGIN
            SET @outResultado = 50005; -- Nombre ya existe
            THROW 50005, 'Empleado con mismo nombre ya existe en edición', 1;
        END

        UPDATE dbo.Empleado
        SET 
            Nombre = @inNombre,
            idTipoDocumento = @inIdTipoDocumento,
            ValorDocumentoIdentidad = @inValorDocumentoIdentidad,
            FechaNacimiento = @inFechaNacimiento,
            idPuesto = @inIdPuesto,
            idDepartamento = @inIdDepartamento
        WHERE id = @inId;

        -- Insertar en EventLog
        DECLARE @idTipoEvento INT;
        SELECT @idTipoEvento = id FROM dbo.TipoEvento WHERE Nombre = 'Editar empleado';

        INSERT INTO dbo.EventLog (
            FechaHora,
            idUsuario,
            idTipoEvento,
            Parametros
        )
        VALUES (
            GETDATE(),
            (SELECT TOP 1 id FROM dbo.Usuario WHERE Tipo = 3),
            @idTipoEvento,
            JSON_QUERY(CONCAT(
                '{',
                    '"idEmpleado":"', COALESCE(CAST(@inId AS VARCHAR), 'null'), '",',
                    '"Nombre":"', @inNombre, '",',
                    '"ValorDocumentoIdentidad":"', @inValorDocumentoIdentidad, '",',
                    '"FechaNacimiento":"', FORMAT(@inFechaNacimiento, 'yyyy-MM-dd'), '",',
                    '"idPuesto":"', COALESCE(CAST(@inIdPuesto AS VARCHAR), 'null'), '",',
                    '"idDepartamento":"', COALESCE(CAST(@inIdDepartamento AS VARCHAR), 'null'), '"',
                '}'
            ))
        );

        SET @outResultado = 0;
    END TRY
    BEGIN CATCH
        IF @outResultado IS NULL OR @outResultado = 0
            SET @outResultado = COALESCE(ERROR_NUMBER(), 50008);

        DECLARE @errorDesc VARCHAR(200) = CONCAT('En la fecha: ', GETDATE(), ' ', ERROR_MESSAGE());
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