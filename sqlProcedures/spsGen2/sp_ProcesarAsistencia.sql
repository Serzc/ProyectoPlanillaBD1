CREATE OR ALTER PROCEDURE sp_ProcesarAsistencia
    @inValorTipoDocumento VARCHAR(50),
    @inHoraEntrada DATETIME,
    @inHoraSalida DATETIME,
    @outResultado INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @idEmpleado INT, @idTipoJornada INT, @horaInicioJornada TIME, @horaFinJornada TIME;
    DECLARE @fecha DATE = CAST(@inHoraEntrada AS DATE);
    DECLARE @esFeriado BIT = 0, @esDomingo BIT = 0;
    DECLARE @horasOrdinarias DECIMAL(5,2) = 0, @horasExtrasNormales DECIMAL(5,2) = 0, @horasExtrasDobles DECIMAL(5,2) = 0;
    DECLARE @salarioXHora DECIMAL(10,2), @idSemanaPlanilla INT, @idPlanillaSemXEmpleado INT;
    DECLARE @idAsistencia INT;

    BEGIN TRY
        -- Verificar si es domingo
        SET @esDomingo = CASE WHEN DATEPART(WEEKDAY, @fecha) = 1 THEN 1 ELSE 0 END;

        -- Verificar si es feriado
        IF EXISTS (SELECT 1 FROM Feriado WHERE Fecha = @fecha)
            SET @esFeriado = 1;

        -- Obtener empleado y jornada actual
        SELECT 
            @idEmpleado = e.id,
            @idTipoJornada = je.idTipoJornada,
            @horaInicioJornada = tj.HoraInicio,
            @horaFinJornada = tj.HoraFin,
            @salarioXHora = p.SalarioXHora
        FROM Empleado e
        JOIN JornadaEmpleado je ON je.idEmpleado = e.id
        JOIN TipoJornada tj ON tj.id = je.idTipoJornada
        JOIN Puesto p ON p.id = e.idPuesto
        WHERE e.ValorDocumentoIdentidad = @inValorTipoDocumento
        AND @fecha BETWEEN je.FechaInicio AND je.FechaFin
        AND e.Activo = 1;

        IF @idEmpleado IS NULL
        BEGIN
            SET @outResultado = 50001; -- Empleado no encontrado o sin jornada asignada
            RETURN;
        END

        -- Obtener semana de planilla actual
        SELECT TOP 1 
            @idSemanaPlanilla = sp.id,
            @idPlanillaSemXEmpleado = pse.id
        FROM SemanaPlanilla sp
        JOIN PlanillaSemXEmpleado pse ON pse.idSemanaPlanilla = sp.id
        WHERE @fecha BETWEEN sp.FechaInicio AND sp.FechaFin
        AND pse.idEmpleado = @idEmpleado
        ORDER BY sp.FechaInicio DESC;

        IF @idSemanaPlanilla IS NULL
        BEGIN
            SET @outResultado = 50002; -- No hay semana de planilla activa
            RETURN;
        END

        -- Buscar la asistencia existente (no procesada)
        SELECT TOP 1 @idAsistencia = id
        FROM Asistencia
        WHERE idEmpleado = @idEmpleado
          AND Fecha = @fecha
          AND HoraEntrada = @inHoraEntrada
          AND HoraSalida = @inHoraSalida
          AND Procesado = 0;

        IF @idAsistencia IS NULL
        BEGIN
            SET @outResultado = 50003; -- Asistencia no encontrada para procesar
            RETURN;
        END

        -- Calcular horas trabajadas
        DECLARE @horaEntrada TIME = CAST(@inHoraEntrada AS TIME);
        DECLARE @horaSalida TIME = CAST(@inHoraSalida AS TIME);

        -- Si la jornada cruza medianoche (nocturna)
        IF @horaInicioJornada > @horaFinJornada
        BEGIN
            IF @horaSalida >= @horaFinJornada
                SET @horasOrdinarias = DATEDIFF(MINUTE, @horaEntrada, @horaFinJornada) / 60.0;
            ELSE
                SET @horasOrdinarias = DATEDIFF(MINUTE, @horaEntrada, @horaSalida) / 60.0;

            IF @horaSalida > @horaFinJornada
                SET @horasExtrasNormales = DATEDIFF(MINUTE, @horaFinJornada, @horaSalida) / 60.0;
        END
        ELSE
        BEGIN
            IF @horaSalida >= @horaFinJornada
                SET @horasOrdinarias = DATEDIFF(MINUTE, @horaEntrada, @horaFinJornada) / 60.0;
            ELSE
                SET @horasOrdinarias = DATEDIFF(MINUTE, @horaEntrada, @horaSalida) / 60.0;

            IF @horaSalida > @horaFinJornada
                SET @horasExtrasNormales = DATEDIFF(MINUTE, @horaFinJornada, @horaSalida) / 60.0;
        END

        SET @horasOrdinarias = FLOOR(@horasOrdinarias);
        SET @horasExtrasNormales = FLOOR(@horasExtrasNormales);

        IF (@esDomingo = 1 OR @esFeriado = 1) AND @horasExtrasNormales > 0
        BEGIN
            SET @horasExtrasDobles = @horasExtrasNormales;
            SET @horasExtrasNormales = 0;
        END

        BEGIN TRANSACTION;

        -- Registrar horas ordinarias
        IF @horasOrdinarias > 0
        BEGIN
            DECLARE @idMovimientoOrdinario INT;
            INSERT INTO MovimientoPlanilla (
                idPlanillaSemXEmpleado, 
                idTipoMovimiento, 
                Fecha, 
                Monto, 
                Descripcion
            )
            VALUES (
                @idPlanillaSemXEmpleado, 
                1, -- Tipo: Crédito horas ordinarias
                @fecha, 
                @horasOrdinarias * @salarioXHora, 
                'Horas ordinarias trabajadas'
            );
            SET @idMovimientoOrdinario = SCOPE_IDENTITY();

            INSERT INTO MovimientoXHora (
                idMovimiento,
                idAsistencia,
                CantidadHoras
            )
            VALUES (
                @idMovimientoOrdinario,
                @idAsistencia,
                @horasOrdinarias
            );

            UPDATE PlanillaSemXEmpleado
            SET SalarioBruto = SalarioBruto + (@horasOrdinarias * @salarioXHora)
            WHERE id = @idPlanillaSemXEmpleado;
        END

        -- Registrar horas extras normales
        IF @horasExtrasNormales > 0
        BEGIN
            DECLARE @idMovimientoExtraNormal INT;
            INSERT INTO MovimientoPlanilla (
                idPlanillaSemXEmpleado, 
                idTipoMovimiento, 
                Fecha, 
                Monto, 
                Descripcion
            )
            VALUES (
                @idPlanillaSemXEmpleado, 
                2, -- Tipo: Crédito horas extras normales
                @fecha, 
                @horasExtrasNormales * @salarioXHora * 1.5, 
                'Horas extras normales trabajadas'
            );
            SET @idMovimientoExtraNormal = SCOPE_IDENTITY();

            INSERT INTO MovimientoXHora (
                idMovimiento,
                idAsistencia,
                CantidadHoras
            )
            VALUES (
                @idMovimientoExtraNormal,
                @idAsistencia,
                @horasExtrasNormales
            );

            UPDATE PlanillaSemXEmpleado
            SET SalarioBruto = SalarioBruto + (@horasExtrasNormales * @salarioXHora * 1.5)
            WHERE id = @idPlanillaSemXEmpleado;
        END

        -- Registrar horas extras dobles
        IF @horasExtrasDobles > 0
        BEGIN
            DECLARE @idMovimientoExtraDoble INT;
            INSERT INTO MovimientoPlanilla (
                idPlanillaSemXEmpleado, 
                idTipoMovimiento, 
                Fecha, 
                Monto, 
                Descripcion
            )
            VALUES (
                @idPlanillaSemXEmpleado, 
                3, -- Tipo: Crédito horas extras dobles
                @fecha, 
                @horasExtrasDobles * @salarioXHora * 2.0, 
                'Horas extras dobles trabajadas'
            );
            SET @idMovimientoExtraDoble = SCOPE_IDENTITY();

            INSERT INTO MovimientoXHora (
                idMovimiento,
                idAsistencia,
                CantidadHoras
            )
            VALUES (
                @idMovimientoExtraDoble,
                @idAsistencia,
                @horasExtrasDobles
            );

            UPDATE PlanillaSemXEmpleado
            SET SalarioBruto = SalarioBruto + (@horasExtrasDobles * @salarioXHora * 2.0)
            WHERE id = @idPlanillaSemXEmpleado;
        END

        -- Marcar asistencia como procesada
        UPDATE Asistencia
        SET Procesado = 1
        WHERE id = @idAsistencia;

        -- Registrar en bitácora
        INSERT INTO EventLog (
            idTipoEvento, 
            Parametros
        )
        VALUES (
            14, -- TipoEvento: Ingreso de marcas de asistencia
            JSON_MODIFY(JSON_MODIFY(JSON_MODIFY(JSON_MODIFY(
                '{}',
                '$.Empleado', @idEmpleado),
                '$.HoraEntrada', CONVERT(VARCHAR, @inHoraEntrada, 120)),
                '$.HoraSalida', CONVERT(VARCHAR, @inHoraSalida, 120)),
                '$.HorasCalculadas', JSON_MODIFY(JSON_MODIFY(JSON_MODIFY(
                    '{}',
                    '$.Ordinarias', @horasOrdinarias),
                    '$.ExtrasNormales', @horasExtrasNormales),
                    '$.ExtrasDobles', @horasExtrasDobles))
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
            14, -- TipoEvento: Ingreso de marcas de asistencia
            JSON_MODIFY('{}', '$.Error', ERROR_MESSAGE())
        );
    END CATCH;
END;