CREATE OR ALTER PROCEDURE sp_ProcesarHorasTrabajadas
    @inIdEmpleado INT,
    @inIdPlanillaSemXEmpleado INT,
    @inIdAsistencia INT,
    @inHoraEntrada DATETIME,
    @inHoraSalida DATETIME,
    @inFecha DATE,
    @outResultado INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Obtener información del empleado y su jornada
        DECLARE @idTipoJornada INT, @horaInicioJornada TIME, @horaFinJornada TIME;
        DECLARE @salarioXHora DECIMAL(10,2);
        DECLARE @esFeriado BIT, @esDomingo BIT;
        
        -- 1. Obtener jornada actual del empleado
        SELECT 
            @idTipoJornada = je.idTipoJornada,
            @horaInicioJornada = tj.HoraInicio,
            @horaFinJornada = tj.HoraFin
        FROM JornadaEmpleado je
        JOIN TipoJornada tj ON je.idTipoJornada = tj.id
        WHERE je.idEmpleado = @inIdEmpleado
          AND @inFecha BETWEEN je.FechaInicio AND je.FechaFin;
        
        -- 2. Obtener salario por hora
        SELECT @salarioXHora = p.SalarioXHora
        FROM Empleado e
        JOIN Puesto p ON e.idPuesto = p.id
        WHERE e.id = @inIdEmpleado;
        
        -- 3. Verificar si es feriado o domingo
        SET @esFeriado = CASE WHEN EXISTS (SELECT 1 FROM Feriado WHERE Fecha = @inFecha) THEN 1 ELSE 0 END;
        SET @esDomingo = CASE WHEN DATEPART(WEEKDAY, @inFecha) = 1 THEN 1 ELSE 0 END;
        
        -- 4. Calcular horas trabajadas
        DECLARE @horaEntradaTime TIME = CAST(@inHoraEntrada AS TIME);
        DECLARE @horaSalidaTime TIME = CAST(@inHoraSalida AS TIME);
        
        -- Ajustar para jornadas nocturnas que cruzan medianoche
        IF @horaSalidaTime < @horaEntradaTime
            SET @horaSalidaTime = DATEADD(HOUR, 24, @horaSalidaTime);
        
        -- Calcular horas ordinarias (dentro del horario de jornada)
        DECLARE @horasOrdinarias DECIMAL(5,2) = 0;
        DECLARE @horasExtrasNormales DECIMAL(5,2) = 0;
        DECLARE @horasExtrasDobles DECIMAL(5,2) = 0;
        
        -- Lógica compleja para calcular los diferentes tipos de horas
        -- (Implementación detallada depende de las reglas de negocio exactas)
        
        -- 5. Insertar movimientos en la planilla
        BEGIN TRANSACTION;
        
        -- Movimiento por horas ordinarias
        IF @horasOrdinarias > 0
        BEGIN
            INSERT INTO MovimientoPlanilla (idPlanillaSemXEmpleado, idTipoMovimiento, Fecha, Monto, Descripcion)
            VALUES (
                @inIdPlanillaSemXEmpleado,
                1, -- Crédito Horas ordinarias
                @inFecha,
                @horasOrdinarias * @salarioXHora,
                CONCAT('Horas ordinarias: ', @horasOrdinarias)
            );
            
            -- Relacionar con la asistencia
            INSERT INTO MovimientoXHora (idMovimiento, idAsistencia, CantidadHoras)
            VALUES (SCOPE_IDENTITY(), @inIdAsistencia, @horasOrdinarias);
        END
        
        -- Movimiento por horas extras normales
        IF @horasExtrasNormales > 0 AND @esFeriado = 0 AND @esDomingo = 0
        BEGIN
            INSERT INTO MovimientoPlanilla (idPlanillaSemXEmpleado, idTipoMovimiento, Fecha, Monto, Descripcion)
            VALUES (
                @inIdPlanillaSemXEmpleado,
                2, -- Crédito Horas Extra Normales
                @inFecha,
                @horasExtrasNormales * @salarioXHora * 1.5,
                CONCAT('Horas extras normales: ', @horasExtrasNormales)
            );
            
            INSERT INTO MovimientoXHora (idMovimiento, idAsistencia, CantidadHoras)
            VALUES (SCOPE_IDENTITY(), @inIdAsistencia, @horasExtrasNormales);
        END
        
        -- Movimiento por horas extras dobles (domingo o feriado)
        IF @horasExtrasDobles > 0 AND (@esFeriado = 1 OR @esDomingo = 1)
        BEGIN
            INSERT INTO MovimientoPlanilla (idPlanillaSemXEmpleado, idTipoMovimiento, Fecha, Monto, Descripcion)
            VALUES (
                @inIdPlanillaSemXEmpleado,
                3, -- Crédito Horas Extra Dobles
                @inFecha,
                @horasExtrasDobles * @salarioXHora * 2.0,
                CONCAT('Horas extras dobles: ', @horasExtrasDobles)
            );
            
            INSERT INTO MovimientoXHora (idMovimiento, idAsistencia, CantidadHoras)
            VALUES (SCOPE_IDENTITY(), @inIdAsistencia, @horasExtrasDobles);
        END
        
        -- Actualizar salario bruto en la planilla semanal
        UPDATE PlanillaSemXEmpleado
        SET SalarioBruto = SalarioBruto + 
            (COALESCE(@horasOrdinarias, 0) * @salarioXHora +
            (COALESCE(@horasExtrasNormales, 0) * @salarioXHora * 1.5) +
            (COALESCE(@horasExtrasDobles, 0) * @salarioXHora * 2.0))
        WHERE id = @inIdPlanillaSemXEmpleado;
        
        -- Marcar asistencia como procesada
        UPDATE Asistencia
        SET Procesado = 1
        WHERE id = @inIdAsistencia;
        
        COMMIT TRANSACTION;
        SET @outResultado = 0;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        IF @outResultado = 0
            SET @outResultado = COALESCE(ERROR_NUMBER(), 50021);
        
        DECLARE @errorDesc VARCHAR(200) = CONCAT('En la fecha: ',@inFecha,' ',ERROR_MESSAGE());
        INSERT INTO DBError (
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