CREATE OR ALTER PROCEDURE sp_EliminarEmpleado
    @inId INT,
    @inFecha DATE,
    @outResultado INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DECLARE @idEmpleado INT = @inId;
        DECLARE @resultadoParcial INT = 0;

        -- Desactivar empleado
        UPDATE dbo.Empleado
        SET Activo = 0
        WHERE id = @idEmpleado AND Activo = 1;

        IF @@ROWCOUNT = 0
        BEGIN
            SET @outResultado = 50008; -- No se encontró el empleado o ya estaba inactivo
            RETURN;
        END

        -- Registrar en EventLog
        DECLARE @idTipoEvento INT;
        SELECT @idTipoEvento = id FROM dbo.TipoEvento WHERE Nombre = 'Eliminar empleado';

        INSERT INTO dbo.EventLog (
            FechaHora,
            idUsuario,
            idTipoEvento,
            Parametros
        )
        VALUES (
            @inFecha,
            (SELECT TOP 1 id FROM dbo.Usuario WHERE Tipo = 3),
            @idTipoEvento,
            JSON_QUERY(CONCAT(
                '{',
                    '"idEmpleado":"', COALESCE(CAST(@idEmpleado AS VARCHAR), 'null'), '",',
                    '"Fecha":"', FORMAT(@inFecha, 'yyyy-MM-dd'), '"',
                '}'
            ))
        );

        SET @outResultado = 0;
    END TRY
    BEGIN CATCH
        IF @outResultado = 0 OR @outResultado IS NULL
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
END