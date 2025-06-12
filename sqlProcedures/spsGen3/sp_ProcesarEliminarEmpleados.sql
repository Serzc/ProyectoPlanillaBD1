CREATE OR ALTER PROCEDURE sp_ProcesarEliminarEmpleados
    @inXmlOperacion XML,
    @inFecha DATE,
    @outResultado INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Tabla variable para almacenar los empleados por eliminar
        DECLARE @EmpleadosEliminar TABLE (
            RowNum INT IDENTITY(1,1),
            ValorTipoDocumento VARCHAR(50)
        );
        
        -- Extraer datos del XML
        INSERT INTO @EmpleadosEliminar (ValorTipoDocumento)
        SELECT 
            t.f.value('@ValorTipoDocumento', 'VARCHAR(50)')
        FROM @inXmlOperacion.nodes('//EliminarEmpleados/EliminarEmpleado') as t(f);
        
        -- Variables para procesamiento
        DECLARE @i INT = 1, @total INT = (SELECT COUNT(*) FROM @EmpleadosEliminar);
        DECLARE @resultadoParcial INT = 0;
        
        -- Procesar cada empleado
        WHILE @i <= @total AND @resultadoParcial = 0
        BEGIN
            UPDATE dbo.Empleado
            SET Activo = 0
            WHERE ValorDocumentoIdentidad = (
                SELECT ValorTipoDocumento 
                FROM @EmpleadosEliminar 
                WHERE RowNum = @i
            );
            SET @i = @i + 1;
        END
        
        SET @outResultado = @resultadoParcial;
    END TRY
    BEGIN CATCH
        IF @outResultado = 0
            SET @outResultado = COALESCE(ERROR_NUMBER(), 50005);
        
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