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
        DECLARE @salarioXHora DECIMAL(25,5);
        DECLARE @esFeriado BIT, @esDomingo BIT;
        
        -- 1. Obtener jornada actual del empleado
        SELECT 
            @idTipoJornada = JE.idTipoJornada,
            @horaInicioJornada = TJ.HoraInicio,
            @horaFinJornada = TJ.HoraFin
        FROM dbo.JornadaEmpleado AS JE
        JOIN dbo.TipoJornada AS TJ ON JE.idTipoJornada = TJ.id
        WHERE JE.idEmpleado = @inIdEmpleado
          AND @inHoraEntrada BETWEEN JE.FechaInicio AND JE.FechaFin;
        
        -- 2. Obtener salario por hora
        SELECT @salarioXHora = P.SalarioXHora
        FROM dbo.Empleado AS E
        JOIN dbo.Puesto AS P ON E.idPuesto = P.id
        WHERE E.id = @inIdEmpleado;
        
        -- 3. Verificar si es feriado o domingo
        SET @esFeriado = CASE WHEN EXISTS (SELECT 1 FROM dbo.Feriado WHERE Fecha = @inFecha) THEN 1 ELSE 0 END;
        SET @esDomingo = CASE WHEN DATEPART(WEEKDAY, @inFecha) = 1 THEN 1 ELSE 0 END;
        
        -- 4. Calcular horas trabajadas
        DECLARE @horaEntradaTime DECIMAL(25,5) = DATEPART(HOUR, @inHoraEntrada) + DATEPART(MINUTE, @inHoraEntrada)/60.0;
        DECLARE @horaSalidaTime DECIMAL(25,5) = DATEPART(HOUR, @inHoraSalida)+ DATEPART(MINUTE, @inHoraSalida)/60.0;
        DECLARE @horaFinJornadaTime DECIMAL(25,5) = DATEPART(HOUR, @horaFinJornada) + DATEPART(MINUTE, @horaFinJornada)/60.0;
		DECLARE @horaInicioJornadaTime DECIMAL(25,5) = DATEPART(HOUR, @horaInicioJornada) + DATEPART(MINUTE, @horaInicioJornada)/60.0;

        -- Ajustar para jornadas nocturnas que cruzan medianoche
        IF @horaFinJornadaTime < @horaInicioJornadaTime
            SET @horaFinJornadaTime = @horaFinJornadaTime+24;

        -- Si la salida es antes que la entrada (jornada nocturna), ajustar sumando 24 horas
        IF @horaSalidaTime < @horaEntradaTime
            SET @horaSalidaTime = @horaSalidaTime+24;

        -- 4.1. Calcular horas ordinarias (máximo 8 horas)
        DECLARE @horasOrdinarias DECIMAL(5,2) = 0;
        DECLARE @horasExtrasNormales DECIMAL(5,2) = 0;
        DECLARE @horasExtrasDobles DECIMAL(5,2) = 0;

        -- Horas trabajadas totales (redondear hacia abajo a horas completas)
        DECLARE @horasTrabajadas DECIMAL(5,2) = FLOOR((DATEDIFF(MINUTE,@inHoraEntrada, @inHoraSalida)/60.0));
		

        -- Horas ordinarias son las trabajadas dentro del horario de jornada (hasta 8 horas)
        SET @horasOrdinarias = CASE 
            WHEN @horasTrabajadas <= 8 THEN @horasTrabajadas --trabajó menos de 8 horas
            WHEN @horasTrabajadas > 8 AND @horaSalidaTime <= @horaFinJornadaTime THEN 8 --llegó temprano
            ELSE FLOOR(@horaFinJornadaTime-@horaEntradaTime) --llegó tarde
        END;

        -- Asegurar que no exceda las horas trabajadas
        IF @horasOrdinarias > @horasTrabajadas
            SET @horasOrdinarias = @horasTrabajadas;

        -- 4.2. Calcular horas extras (si las hay)
        DECLARE @horasExtras DECIMAL(5,2) = @horasTrabajadas - @horasOrdinarias;

        IF @horasTrabajadas > 0
        BEGIN
            
            DECLARE @fechaDiaSiguiente DATE = DATEADD(DAY, 1, @inHoraEntrada);
            
            -- Separar horas extras normales y dobles
            IF @esFeriado = 1 OR @esDomingo = 1 OR 
               (@horaSalidaTime > 24 AND (DATEPART(WEEKDAY, @fechaDiaSiguiente) = 1 
                OR EXISTS (SELECT 1 FROM dbo.Feriado WHERE Fecha = @fechaDiaSiguiente)))
            BEGIN
                -- Todas las horas son dobles si es feriado/domingo
                SET @horasExtrasDobles = @horasTrabajadas;
                SET @horasOrdinarias = 0;
            END
            ELSE
            BEGIN
                -- Horas extras normales son las que exceden la jornada pero no son en feriado/domingo
                SET @horasExtrasNormales = @horasExtras;
                
                -- Si la jornada cruza medianoche y el día siguiente es feriado/domingo, parte puede ser doble
                IF @horaSalidaTime > 24 
                    AND (DATEPART(WEEKDAY, @fechaDiaSiguiente) = 1 
                        OR EXISTS (SELECT 1 FROM dbo.Feriado WHERE Fecha = @fechaDiaSiguiente))
                BEGIN
                    -- Calcular horas en el nuevo día (feriado/domingo)
                    DECLARE @horasNuevoDia DECIMAL(25,5) = @horaSalidaTime - 24;
                    
                    SET @horasExtrasDobles = @horasNuevoDia;
                    SET @horasExtrasNormales = @horasExtras - @horasExtrasDobles;
                END
            END
        END

        -- Asegurar que las horas ordinarias no excedan el máximo de 8 horas
        IF @horasOrdinarias > 8
            SET @horasOrdinarias = 8;

        -- Asegurar que solo contamos horas completas
        SET @horasOrdinarias = FLOOR(@horasOrdinarias);
        SET @horasExtrasNormales = FLOOR(@horasExtrasNormales);
        SET @horasExtrasDobles = FLOOR(@horasExtrasDobles);
        
        -- 5. Insertar movimientos en la planilla
        BEGIN TRANSACTION;
        
        -- Movimiento por horas ordinarias
        IF @horasOrdinarias > 0
        BEGIN
            INSERT INTO dbo.MovimientoPlanilla (
                idPlanillaSemXEmpleado
                , idTipoMovimiento
                , Fecha
                , Monto
                , Descripcion
                )
            VALUES (
                @inIdPlanillaSemXEmpleado,
                1, -- Crédito Horas ordinarias
                @inFecha,
                @horasOrdinarias * @salarioXHora,
                CONCAT('Horas ordinarias: ', @horasOrdinarias)
            );
            
            -- Relacionar con la asistencia
            INSERT INTO dbo.MovimientoXHora (
                idMovimiento
                , idAsistencia
                , CantidadHoras
                )
            VALUES (
                SCOPE_IDENTITY()
                , @inIdAsistencia
                , @horasOrdinarias
                );
        END
        
        -- Movimiento por horas extras normales
        IF @horasExtrasNormales > 0
        BEGIN
            INSERT INTO dbo.MovimientoPlanilla (
                idPlanillaSemXEmpleado
                , idTipoMovimiento
                , Fecha
                , Monto
                , Descripcion
                )
            VALUES (
                @inIdPlanillaSemXEmpleado,
                2, -- Crédito Horas Extra Normales
                @inFecha,
                @horasExtrasNormales * @salarioXHora * 1.5,
                CONCAT('Horas extras normales: ', @horasExtrasNormales)
            );
            
            INSERT INTO dbo.MovimientoXHora (
                idMovimiento
                , idAsistencia
                , CantidadHoras)
            VALUES (
                SCOPE_IDENTITY()
                , @inIdAsistencia
                , @horasExtrasNormales
                );
        END
        
        -- Movimiento por horas extras dobles (domingo o feriado)
        IF @horasExtrasDobles > 0
        BEGIN
            INSERT INTO dbo.MovimientoPlanilla (
                idPlanillaSemXEmpleado
                , idTipoMovimiento
                , Fecha
                , Monto
                , Descripcion)
            VALUES (
                @inIdPlanillaSemXEmpleado,
                3, -- Crédito Horas Extra Dobles
                @inFecha,
                @horasExtrasDobles * @salarioXHora * 2.0,
                CONCAT('Horas extras dobles: ', @horasExtrasDobles)
            );
            
            INSERT INTO dbo.MovimientoXHora (
                idMovimiento
                , idAsistencia
                , CantidadHoras
                )
            VALUES (
                SCOPE_IDENTITY()
                , @inIdAsistencia
                , @horasExtrasDobles
                );
        END
        
        -- Actualizar salario bruto en la planilla semanal
        UPDATE dbo.PlanillaSemXEmpleado
        SET SalarioBruto = SalarioBruto + 
            (COALESCE(@horasOrdinarias, 0) * @salarioXHora +
            (COALESCE(@horasExtrasNormales, 0) * @salarioXHora * 1.5) +
            (COALESCE(@horasExtrasDobles, 0) * @salarioXHora * 2.0))
        WHERE id = @inIdPlanillaSemXEmpleado;
        
        -- Marcar asistencia como procesada
        UPDATE dbo.Asistencia
        SET Procesado = 1
        WHERE id = @inIdAsistencia;
        
        IF @horasOrdinarias >= 12 OR @horasExtrasNormales >= 12 OR @horasExtrasDobles >= 12 --revisar casos sospechosos
        BEGIN
            DECLARE @mensaje VARCHAR(500) = CONCAT('Atención: El empleado ', @inIdEmpleado, '. Fecha: ', @inFecha,'\n',
                'Horas ordinarias: ', @horasOrdinarias, ', Horas extras normales: ', @horasExtrasNormales, ', Horas extras dobles: ', @horasExtrasDobles
                , '\n. Hora Entrada: ', @inHoraEntrada, ', Hora Salida: ', @inHoraSalida
                , '\n. TipoJornada: ',  @idTipoJornada, ', Hora Inicio: ', @horaInicioJornada, ', Hora Fin: ', @horaFinJornada);
            INSERT INTO dbo.DBError (
                idTipoError,
                Mensaje,
                Procedimiento,
                Linea
            )
            VALUES (
                50008, -- Error en la base de datos
                @mensaje,
                'sp_ProcesarHorasTrabajadas',
                0
            );
        END

        COMMIT TRANSACTION;
        SET @outResultado = 0;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        IF @outResultado = 0
            SET @outResultado = COALESCE(ERROR_NUMBER(), 50008); -- Error en la base de datos
        
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