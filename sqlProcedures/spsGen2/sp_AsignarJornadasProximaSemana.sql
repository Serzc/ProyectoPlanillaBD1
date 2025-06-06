CREATE OR ALTER PROCEDURE sp_AsignarJornadasProximaSemana
    @inFechaOperacion DATE,
    @inValorTipoDocumento VARCHAR(50),
    @inIdTipoJornada INT,
    @outResultado INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @idEmpleado INT, @fechaInicioSemana DATE, @fechaFinSemana DATE;
    
    BEGIN TRY
        -- Verificar que la fecha de operación sea jueves
        IF DATEPART(WEEKDAY, @inFechaOperacion) <> 5 -- 5 = Jueves
        BEGIN
            SET @outResultado = 50005; -- Solo se pueden asignar jornadas los jueves
            RETURN;
        END
        
        -- Calcular fechas de la próxima semana (viernes a jueves)
        SET @fechaInicioSemana = DATEADD(DAY, 1, @inFechaOperacion); -- Viernes
        SET @fechaFinSemana = DATEADD(DAY, 6, @fechaInicioSemana); -- Siguiente jueves
        
        -- Obtener empleado
        SELECT @idEmpleado = id
        FROM Empleado
        WHERE ValorDocumentoIdentidad = @inValorTipoDocumento
        AND Activo = 1;
        
        IF @idEmpleado IS NULL
        BEGIN
            SET @outResultado = 50001; -- Empleado no encontrado
            RETURN;
        END
        
        BEGIN TRANSACTION;
        
        -- Desactivar jornada actual si existe para ese período
        UPDATE JornadaEmpleado
        SET FechaFin = DATEADD(DAY, -1, @fechaInicioSemana)
        WHERE idEmpleado = @idEmpleado
        AND FechaFin >= @fechaInicioSemana;
        
        -- Asignar nueva jornada
        INSERT INTO JornadaEmpleado (
            idEmpleado,
            idTipoJornada,
            FechaInicio,
            FechaFin
        )
        VALUES (
            @idEmpleado,
            @inIdTipoJornada,
            @fechaInicioSemana,
            @fechaFinSemana
        );
        
        -- Registrar en bitácora
        INSERT INTO EventLog (
            idTipoEvento,
            Parametros
        )
        VALUES (
            15, -- TipoEvento: Ingreso nuevas jornadas
            JSON_MODIFY(JSON_MODIFY(JSON_MODIFY(
                '{}',
                '$.Empleado', @idEmpleado),
                '$.TipoJornada', @inIdTipoJornada),
                '$.Semana', CONVERT(VARCHAR, @fechaInicioSemana, 120) + ' a ' + CONVERT(VARCHAR, @fechaFinSemana, 120))
        )
        ;
        
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
            15, -- TipoEvento: Ingreso nuevas jornadas
            JSON_MODIFY('{}', '$.Error', ERROR_MESSAGE())
        );
    END CATCH;
END;