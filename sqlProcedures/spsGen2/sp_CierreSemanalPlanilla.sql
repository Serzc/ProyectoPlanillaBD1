CREATE OR ALTER PROCEDURE sp_CierreSemanalPlanilla
    @inFechaCierre DATE,
    @outResultado INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @idSemanaPlanilla INT, @idMesPlanilla INT, @semanasEnMes INT;
    DECLARE @fechaInicioSemana DATE, @fechaFinSemana DATE;
    DECLARE @fechaInicioMes DATE, @fechaFinMes DATE;
    DECLARE @esUltimaSemanaMes BIT = 0;
    
    BEGIN TRY
        -- Verificar que la fecha de cierre sea jueves
        IF DATEPART(WEEKDAY, @inFechaCierre) <> 5 -- 5 = Jueves
        BEGIN
            SET @outResultado = 50003; -- La fecha de cierre no es jueves
            RETURN;
        END
        
        -- Obtener semana de planilla a cerrar
        SELECT 
            @idSemanaPlanilla = id,
            @fechaInicioSemana = FechaInicio,
            @fechaFinSemana = FechaFin,
            @idMesPlanilla = idMesPlanilla
        FROM SemanaPlanilla
        WHERE @inFechaCierre BETWEEN FechaInicio AND FechaFin
        AND Cerrado = 0;
        
        IF @idSemanaPlanilla IS NULL
        BEGIN
            SET @outResultado = 50004; -- No hay semana de planilla para cerrar
            RETURN;
        END
        
        -- Obtener mes de planilla
        SELECT 
            @fechaInicioMes = FechaInicio,
            @fechaFinMes = FechaFin
        FROM MesPlanilla
        WHERE id = @idMesPlanilla;
        
        -- Verificar si es la última semana del mes
        IF @fechaFinSemana = @fechaFinMes
            SET @esUltimaSemanaMes = 1;
            
        -- Calcular cuántas semanas tiene el mes (4 o 5)
        SELECT @semanasEnMes = COUNT(*)
        FROM SemanaPlanilla
        WHERE idMesPlanilla = @idMesPlanilla;
        
        BEGIN TRANSACTION;
        
        -- Declarar tabla variable para empleados a procesar
        DECLARE @EmpleadosProcesar TABLE (
            idPlanillaSemXEmpleado INT,
            idEmpleado INT,
            SalarioBruto DECIMAL(12,2),
            idPlanillaMexXEmpleado INT NULL
        );
        
        -- Insertar empleados a procesar
        INSERT INTO @EmpleadosProcesar (idPlanillaSemXEmpleado, idEmpleado, SalarioBruto, idPlanillaMexXEmpleado)
        SELECT 
            pse.id,
            pse.idEmpleado,
            pse.SalarioBruto,
            pme.id
        FROM PlanillaSemXEmpleado pse
        LEFT JOIN PlanillaMexXEmpleado pme ON pme.idEmpleado = pse.idEmpleado AND pme.idMesPlanilla = @idMesPlanilla
        WHERE pse.idSemanaPlanilla = @idSemanaPlanilla;
        
        -- Procesar deducciones porcentuales
        INSERT INTO MovimientoPlanilla (
            idPlanillaSemXEmpleado,
            idTipoMovimiento,
            Fecha,
            Monto,
            Descripcion
        )
        SELECT 
            ep.idPlanillaSemXEmpleado,
            4, -- Tipo: Débito deducciones de ley
            @inFechaCierre,
            ep.SalarioBruto * ed.ValorPorcentual,
            td.Nombre + ' (Deducción porcentual)'
        FROM @EmpleadosProcesar ep
        JOIN EmpleadoDeduccion ed ON ed.idEmpleado = ep.idEmpleado
        JOIN TipoDeduccion td ON td.id = ed.idTipoDeduccion
        WHERE ed.FechaDesasociacion IS NULL
        AND td.Porcentual = 1;
        
        -- Procesar deducciones fijas (dividir entre número de semanas en el mes)
        INSERT INTO MovimientoPlanilla (
            idPlanillaSemXEmpleado,
            idTipoMovimiento,
            Fecha,
            Monto,
            Descripcion
        )
        SELECT 
            ep.idPlanillaSemXEmpleado,
            5, -- Tipo: Débito deducción no obligatoria
            @inFechaCierre,
            ed.ValorFijo / @semanasEnMes,
            td.Nombre + ' (Deducción fija)'
        FROM @EmpleadosProcesar ep
        JOIN EmpleadoDeduccion ed ON ed.idEmpleado = ep.idEmpleado
        JOIN TipoDeduccion td ON td.id = ed.idTipoDeduccion
        WHERE ed.FechaDesasociacion IS NULL
        AND td.Porcentual = 0
        AND ed.ValorFijo > 0;
        
        -- Actualizar planillas semanales con total deducciones y salario neto
        UPDATE pse
        SET 
            pse.TotalDeducciones = ded.TotalDeducciones,
            pse.SalarioNeto = pse.SalarioBruto - ded.TotalDeducciones
        FROM PlanillaSemXEmpleado pse
        JOIN (
            SELECT 
                ep.idPlanillaSemXEmpleado,
                SUM(CASE WHEN td.Porcentual = 1 THEN ep.SalarioBruto * ed.ValorPorcentual
                         ELSE ed.ValorFijo / @semanasEnMes END) AS TotalDeducciones
            FROM @EmpleadosProcesar ep
            JOIN EmpleadoDeduccion ed ON ed.idEmpleado = ep.idEmpleado
            JOIN TipoDeduccion td ON td.id = ed.idTipoDeduccion
            WHERE ed.FechaDesasociacion IS NULL
            GROUP BY ep.idPlanillaSemXEmpleado
        ) ded ON ded.idPlanillaSemXEmpleado = pse.id;
        
        -- Actualizar planillas mensuales (acumular salario bruto y deducciones)
        UPDATE pme
        SET 
            pme.SalarioBruto = pme.SalarioBruto + ep.SalarioBruto,
            pme.TotalDeducciones = pme.TotalDeducciones + ded.TotalDeducciones,
            pme.SalarioNeto = pme.SalarioBruto + ep.SalarioBruto - (pme.TotalDeducciones + ded.TotalDeducciones)
        FROM PlanillaMexXEmpleado pme
        JOIN @EmpleadosProcesar ep ON ep.idPlanillaMexXEmpleado = pme.id
        JOIN (
            SELECT 
                ep.idPlanillaSemXEmpleado,
                SUM(CASE WHEN td.Porcentual = 1 THEN ep.SalarioBruto * ed.ValorPorcentual
                         ELSE ed.ValorFijo / @semanasEnMes END) AS TotalDeducciones
            FROM @EmpleadosProcesar ep
            JOIN EmpleadoDeduccion ed ON ed.idEmpleado = ep.idEmpleado
            JOIN TipoDeduccion td ON td.id = ed.idTipoDeduccion
            WHERE ed.FechaDesasociacion IS NULL
            GROUP BY ep.idPlanillaSemXEmpleado
        ) ded ON ded.idPlanillaSemXEmpleado = ep.idPlanillaSemXEmpleado;
        
        -- Registrar deducciones por tipo en el mes
        MERGE INTO DeduccionesXEmpleadoxMes AS target
        USING (
            SELECT 
                ep.idPlanillaMexXEmpleado,
                ed.idTipoDeduccion,
                SUM(CASE WHEN td.Porcentual = 1 THEN ep.SalarioBruto * ed.ValorPorcentual
                          ELSE ed.ValorFijo / @semanasEnMes END) AS Monto
            FROM @EmpleadosProcesar ep
            JOIN EmpleadoDeduccion ed ON ed.idEmpleado = ep.idEmpleado
            JOIN TipoDeduccion td ON td.id = ed.idTipoDeduccion
            WHERE ed.FechaDesasociacion IS NULL
            AND ep.idPlanillaMexXEmpleado IS NOT NULL
            GROUP BY ep.idPlanillaMexXEmpleado, ed.idTipoDeduccion
        ) AS source
        ON target.idPlanillaMexXEmpleado = source.idPlanillaMexXEmpleado 
        AND target.idTipoDeduccion = source.idTipoDeduccion
        WHEN MATCHED THEN
            UPDATE SET target.Monto = target.Monto + source.Monto
        WHEN NOT MATCHED THEN
            INSERT (idPlanillaMexXEmpleado, idTipoDeduccion, Monto)
            VALUES (source.idPlanillaMexXEmpleado, source.idTipoDeduccion, source.Monto);
        
        -- Marcar semana como cerrada
        UPDATE SemanaPlanilla
        SET Cerrado = 1
        WHERE id = @idSemanaPlanilla;
        
        -- Si es última semana del mes, marcar mes como cerrado
        IF @esUltimaSemanaMes = 1
        BEGIN
            UPDATE MesPlanilla
            SET Cerrado = 1
            WHERE id = @idMesPlanilla;
        END
        
        -- Registrar en bitácora
        INSERT INTO EventLog (
            idTipoEvento,
            Parametros
        )
        VALUES (
            13, -- TipoEvento: Cierre semanal de planilla
            JSON_MODIFY(JSON_MODIFY(
                '{}',
                '$.FechaCierre', CONVERT(VARCHAR, @inFechaCierre, 120)),
                '$.SemanaPlanilla', @idSemanaPlanilla)
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
            13, -- TipoEvento: Cierre semanal de planilla
            JSON_MODIFY('{}', '$.Error', ERROR_MESSAGE())
        );
    END CATCH;
END;