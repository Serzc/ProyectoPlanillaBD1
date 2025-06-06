CREATE OR ALTER PROCEDURE sp_ProcesarAsistencias
    @inFechaOperacion DATE,
    @inXmlData XML,
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @outResultCode = 0;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Verificar si es feriado o domingo
        DECLARE @esFeriado BIT = CASE WHEN EXISTS (
            SELECT 1 FROM Feriado 
            WHERE Fecha = @inFechaOperacion
        ) THEN 1 ELSE 0 END;
        
        DECLARE @esDomingo BIT = CASE WHEN DATEPART(WEEKDAY, @inFechaOperacion) = 1 
                                  THEN 1 ELSE 0 END;
        
        -- Tabla temporal para asistencias
        DECLARE @Asistencias TABLE (
            idEmpleado INT,
            HoraEntrada DATETIME,
            HoraSalida DATETIME,
            idTipoJornada INT,
            HoraInicioJornada TIME,
            HoraFinJornada TIME,
            idPuesto INT,
            SalarioXHora DECIMAL(10,2)
        );
        
        -- Obtener datos de asistencias con jornadas y puestos
        INSERT INTO @Asistencias (
            idEmpleado,
            HoraEntrada,
            HoraSalida,
            idTipoJornada,
            HoraInicioJornada,
            HoraFinJornada,
            idPuesto,
            SalarioXHora
        )
        SELECT
            e.id,
            marca.value('@HoraEntrada', 'DATETIME'),
            marca.value('@HoraSalida', 'DATETIME'),
            je.idTipoJornada,
            tj.HoraInicio,
            tj.HoraFin,
            e.idPuesto,
            p.SalarioXHora
        FROM @inXmlData.nodes('/Operacion/FechaOperacion/MarcasAsistencia/MarcaAsistencia') AS T(marca)
        JOIN Empleado e ON e.ValorDocumentoIdentidad = marca.value('@ValorTipoDocumento', 'VARCHAR(50)')
        JOIN JornadaEmpleado je ON je.idEmpleado = e.id 
                               AND @inFechaOperacion BETWEEN je.FechaInicio AND je.FechaFin
        JOIN TipoJornada tj ON je.idTipoJornada = tj.id
        JOIN Puesto p ON e.idPuesto = p.id
        WHERE e.Activo = 1;
        
        -- Procesar cada asistencia (sin cursor)
        INSERT INTO MovimientoPlanilla (
            idPlanillaSemXEmpleado,
            idTipoMovimiento,
            Fecha,
            CantidadHoras,
            Monto
        )
        SELECT
            pse.id,
            CASE 
                WHEN a.HoraSalida > DATEADD(HOUR, 8, a.HoraEntrada) AND 
                     (@esFeriado = 1 OR @esDomingo = 1) THEN 3 -- Horas extra dobles
                WHEN a.HoraSalida > DATEADD(HOUR, 8, a.HoraEntrada) THEN 2 -- Horas extra normales
                ELSE 1 -- Horas ordinarias
            END,
            @inFechaOperacion,
            DATEDIFF(HOUR, a.HoraEntrada, 
                CASE 
                    WHEN a.HoraSalida > DATEADD(HOUR, 8, a.HoraEntrada) THEN DATEADD(HOUR, 8, a.HoraEntrada)
                    ELSE a.HoraSalida
                END),
            CASE 
                WHEN a.HoraSalida > DATEADD(HOUR, 8, a.HoraEntrada) AND 
                     (@esFeriado = 1 OR @esDomingo = 1) THEN 
                    DATEDIFF(HOUR, DATEADD(HOUR, 8, a.HoraEntrada), a.HoraSalida) * a.SalarioXHora * 2.0
                WHEN a.HoraSalida > DATEADD(HOUR, 8, a.HoraEntrada) THEN 
                    DATEDIFF(HOUR, DATEADD(HOUR, 8, a.HoraEntrada), a.HoraSalida) * a.SalarioXHora * 1.5
                ELSE 
                    DATEDIFF(HOUR, a.HoraEntrada, a.HoraSalida) * a.SalarioXHora
            END
        FROM @Asistencias a
        JOIN PlanillaSemXEmpleado pse ON pse.idEmpleado = a.idEmpleado
        JOIN SemanaPlanilla sp ON pse.idSemanaPlanilla = sp.id
        WHERE @inFechaOperacion BETWEEN sp.FechaInicio AND sp.FechaFin;
        
        COMMIT TRANSACTION;
        
        -- Retornar conteo de asistencias procesadas
        SELECT COUNT(*) AS AsistenciasProcesadas
        FROM @Asistencias;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        SET @outResultCode = 50020 + ERROR_NUMBER();
        -- Error 50020+: Error al procesar asistencias
        THROW;
    END CATCH;
END;