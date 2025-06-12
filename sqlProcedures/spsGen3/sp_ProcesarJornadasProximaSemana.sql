CREATE OR ALTER PROCEDURE sp_ProcesarJornadasProximaSemana
    @inXmlOperacion XML,
    @inFecha DATE,
    @outResultado INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        DECLARE @fechaInicioSemana DATE = DATEADD(DAY, 1, @inFecha); -- Viernes siguiente
        DECLARE @fechaFinSemana DATE = DATEADD(DAY, 6, @fechaInicioSemana); -- Jueves siguiente
        
        BEGIN TRANSACTION;
        
        -- Tabla variable para almacenar las jornadas a procesar
        DECLARE @jornadasProcesar TABLE (
            ValorTipoDocumento VARCHAR(50),
            IdTipoJornada INT
        );
        
        -- Extraer datos del XML
        INSERT INTO @jornadasProcesar (ValorTipoDocumento, IdTipoJornada)
        SELECT 
            t.f.value('@ValorTipoDocumento', 'VARCHAR(50)'),
            t.f.value('@IdTipoJornada', 'INT')
        FROM @inXmlOperacion.nodes('//JornadasProximaSemana/TipoJornadaProximaSemana') as t(f);
        
        -- Actualizar o insertar jornadas
        MERGE INTO dbo.JornadaEmpleado AS target
        USING (
            SELECT 
                E.id AS idEmpleado,
                JP.IdTipoJornada,
                @fechaInicioSemana AS FechaInicio,
                @fechaFinSemana AS FechaFin
            FROM @jornadasProcesar AS JP
            JOIN dbo.Empleado AS E ON JP.ValorTipoDocumento = E.ValorDocumentoIdentidad
            WHERE E.Activo = 1
        ) AS source
        ON target.idEmpleado = source.idEmpleado 
           AND target.FechaInicio = source.FechaInicio
        WHEN MATCHED THEN
            UPDATE SET 
                idTipoJornada = source.IdTipoJornada,
                FechaFin = source.FechaFin
        WHEN NOT MATCHED THEN
            INSERT (idEmpleado, idTipoJornada
                    , FechaInicio, FechaFin)
            VALUES (source.idEmpleado, source.IdTipoJornada
                    , source.FechaInicio, source.FechaFin);
        
        COMMIT TRANSACTION;
        SET @outResultado = 0;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        IF @outResultado = 0
            SET @outResultado = COALESCE(ERROR_NUMBER(), 50001);
        
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