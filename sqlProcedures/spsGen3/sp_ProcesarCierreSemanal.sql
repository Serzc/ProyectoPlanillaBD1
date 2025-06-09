CREATE OR ALTER PROCEDURE sp_ProcesarCierreSemanal
    @inFecha DATE,
    @outResultado INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        DECLARE @idSemanaPlanilla INT, @idMesPlanilla INT;
        DECLARE @fechaInicioSemana DATE, @fechaFinSemana DATE;
        DECLARE @fechaInicioMes DATE, @fechaFinMes DATE;
        DECLARE @semanasEnMes INT;
        
        -- Obtener semana de planilla actual
        SELECT TOP 1
            @idSemanaPlanilla = sp.id,
            @idMesPlanilla = sp.idMesPlanilla,
            @fechaInicioSemana = sp.FechaInicio,
            @fechaFinSemana = sp.FechaFin
        FROM SemanaPlanilla sp
        WHERE @inFecha BETWEEN sp.FechaInicio AND sp.FechaFin
        AND sp.Cerrado = 0
        ORDER BY sp.FechaInicio DESC;
        
        IF @idSemanaPlanilla IS NULL
        BEGIN
            SET @outResultado = 50015; -- Semana de planilla no encontrada
            THROW @outResultado, 'Semana de planilla no encontrada', 1;
        END
        
        -- Obtener información del mes
        SELECT 
            @fechaInicioMes = mp.FechaInicio,
            @fechaFinMes = mp.FechaFin
        FROM MesPlanilla mp
        WHERE mp.id = @idMesPlanilla;
        
        -- Calcular cuántas semanas hay en este mes (para deducciones fijas)
        SELECT @semanasEnMes = COUNT(*)
        FROM SemanaPlanilla
        WHERE idMesPlanilla = @idMesPlanilla;
        
        BEGIN TRANSACTION;
        
        -- Tabla variable para deducciones
        DECLARE @deduccionesProcesar TABLE (
            idPlanillaSemXEmpleado INT,
            idTipoDeduccion INT,
            Monto DECIMAL(25,4)
        );
        
        -- Procesar todos los empleados con planilla en esta semana
        -- Primero: Calcular todas las deducciones
        INSERT INTO @deduccionesProcesar (idPlanillaSemXEmpleado, idTipoDeduccion, Monto)
        SELECT 
            pse.id,
            ed.idTipoDeduccion,
            CASE 
                WHEN td.Porcentual = 1 THEN pse.SalarioBruto * ed.ValorPorcentual
                WHEN td.Porcentual = 0 THEN ed.ValorFijo / @semanasEnMes
                ELSE 0
            END AS Monto
        FROM PlanillaSemXEmpleado pse
        JOIN EmpleadoDeduccion ed ON pse.idEmpleado = ed.idEmpleado
        JOIN TipoDeduccion td ON ed.idTipoDeduccion = td.id
        WHERE pse.idSemanaPlanilla = @idSemanaPlanilla
          AND ed.FechaDesasociacion IS NULL
          AND (@inFecha >= ed.FechaAsociacion OR ed.FechaAsociacion IS NULL);
        
        -- Actualizar planillas semanales con total deducciones
        UPDATE pse
        SET 
            pse.TotalDeducciones = dp.TotalDeducciones,
            pse.SalarioNeto = pse.SalarioBruto - dp.TotalDeducciones
        FROM PlanillaSemXEmpleado pse
        JOIN (
            SELECT idPlanillaSemXEmpleado, SUM(Monto) AS TotalDeducciones
            FROM @deduccionesProcesar
            GROUP BY idPlanillaSemXEmpleado
        ) dp ON pse.id = dp.idPlanillaSemXEmpleado;
        
        -- Registrar movimientos de deducción
        INSERT INTO MovimientoPlanilla (idPlanillaSemXEmpleado, idTipoMovimiento, Fecha, Monto, Descripcion)
        SELECT 
            dp.idPlanillaSemXEmpleado,
            CASE 
                WHEN td.Obligatorio = 1 THEN 4 -- Débito Deducciones de Ley
                ELSE 5 -- Débito Deducción No Obligatoria
            END,
            @inFecha,
            dp.Monto,
            td.Nombre
        FROM @deduccionesProcesar dp
        JOIN TipoDeduccion td ON dp.idTipoDeduccion = td.id;
        
        -- Actualizar planillas mensuales
        UPDATE pme
        SET 
            pme.SalarioBruto = pme.SalarioBruto + pse.SalarioBruto,
            pme.TotalDeducciones = pme.TotalDeducciones + pse.TotalDeducciones,
            pme.SalarioNeto = pme.SalarioNeto + pse.SalarioNeto
        FROM PlanillaMexXEmpleado pme
        JOIN PlanillaSemXEmpleado pse ON pme.idEmpleado = pse.idEmpleado
        WHERE pse.idSemanaPlanilla = @idSemanaPlanilla
          AND pme.idMesPlanilla = @idMesPlanilla;
        
        -- Actualizar deducciones por mes
        MERGE INTO DeduccionesXEmpleadoxMes AS target
        USING (
            SELECT 
                pme.id AS idPlanillaMexXEmpleado,
                dp.idTipoDeduccion,
                dp.Monto
            FROM @deduccionesProcesar dp
            JOIN PlanillaSemXEmpleado pse ON dp.idPlanillaSemXEmpleado = pse.id
            JOIN PlanillaMexXEmpleado pme ON pse.idEmpleado = pme.idEmpleado AND pme.idMesPlanilla = @idMesPlanilla
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
        
        COMMIT TRANSACTION;
        SET @outResultado = 0;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        IF @outResultado = 0
            SET @outResultado = COALESCE(ERROR_NUMBER(), 50016);
        
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