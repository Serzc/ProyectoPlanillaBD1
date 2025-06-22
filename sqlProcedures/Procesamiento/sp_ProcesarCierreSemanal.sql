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
        
        

        -- Obtener semana de planilla actual========================================
        SELECT TOP 1
            @idSemanaPlanilla = SP.id,
            @idMesPlanilla = SP.idMesPlanilla,
            @fechaInicioSemana = SP.FechaInicio,
            @fechaFinSemana = SP.FechaFin
        FROM dbo.SemanaPlanilla AS SP
        WHERE @inFecha BETWEEN SP.FechaInicio AND SP.FechaFin
        AND SP.Cerrado = 0
        ORDER BY SP.FechaInicio DESC;
        
        IF @idSemanaPlanilla IS NULL
        BEGIN
            SET @outResultado = 50008; -- Error en la base de datos
            THROW @outResultado, 'Semana de planilla no encontrada', 1;
        END
        
        -- Obtener información del mes
        SELECT 
            @fechaInicioMes = MP.FechaInicio,
            @fechaFinMes = MP.FechaFin
        FROM dbo.MesPlanilla AS MP
        WHERE MP.id = @idMesPlanilla;
        
        -- Calcular cuántas semanas hay en este mes (para deducciones fijas)
        SELECT @semanasEnMes = COUNT(*)
        FROM dbo.SemanaPlanilla
        WHERE idMesPlanilla = @idMesPlanilla;
        -- PROCESAR DEDUCCIONES ==================================================
        BEGIN TRANSACTION;
        
        -- Tabla variable para deducciones
        DECLARE @deduccionesProcesar TABLE (
            idPlanillaSemXEmpleado INT,
            idTipoDeduccion INT,
            Monto DECIMAL(25,4)
        );
        
        -- Procesar todos los empleados con planilla en esta semana
        -- Primero: Calcular todas las deducciones
        INSERT INTO @deduccionesProcesar (
            idPlanillaSemXEmpleado
            , idTipoDeduccion
            , Monto
            )
        SELECT 
            PSE.id,
            ED.idTipoDeduccion,
            CASE 
                WHEN TD.Porcentual = 1 THEN PSE.SalarioBruto * TD.Valor
                WHEN TD.Porcentual = 0 THEN GREATEST(ED.ValorFijo / @semanasEnMes,0)
                ELSE 0
            END AS Monto
        FROM dbo.EmpleadoDeduccion AS ED 
        FULL JOIN dbo.PlanillaSemXEmpleado AS PSE ON PSE.idEmpleado = ED.idEmpleado        
        JOIN dbo.TipoDeduccion AS TD ON ED.idTipoDeduccion = TD.id
        WHERE PSE.idSemanaPlanilla = @idSemanaPlanilla
          AND ED.FechaDesasociacion IS NULL
          AND (@inFecha >= ED.FechaAsociacion OR ED.FechaAsociacion IS NULL);
        
        -- Asegúrese de que la tabla deduccionesProcesarBackup exista con las columnas correctas antes de ejecutar este procedimiento.
        INSERT INTO dbo.deduccionesProcesarBackup (
            idPlanillaSemXEmpleado,
            idTipoDeduccion,
            Monto,
            Fecha
        )
        SELECT
            DP.idPlanillaSemXEmpleado,
            DP.idTipoDeduccion,
            DP.Monto,
            @inFecha
        FROM @deduccionesProcesar AS DP;
        -- Actualizar planillas semanales con total deducciones
        UPDATE PSE
        SET 
            PSE.TotalDeducciones = DP.TotalDeducciones,
            PSE.SalarioNeto = PSE.SalarioBruto - DP.TotalDeducciones
        FROM dbo.PlanillaSemXEmpleado AS PSE
        JOIN (
            SELECT idPlanillaSemXEmpleado, SUM(Monto) AS TotalDeducciones
            FROM @deduccionesProcesar
            GROUP BY idPlanillaSemXEmpleado
        ) DP ON PSE.id = DP.idPlanillaSemXEmpleado;
        
        -- Registrar movimientos de deducción
        INSERT INTO dbo.MovimientoPlanilla (
            idPlanillaSemXEmpleado
            , idTipoMovimiento
            , Fecha
            , Monto
            , Descripcion
            )
        SELECT 
            DP.idPlanillaSemXEmpleado,
            CASE 
                WHEN TD.Obligatorio = 1 THEN 4 -- Débito Deducciones de Ley
                ELSE 5 -- Débito Deducción No Obligatoria
            END,
            @inFecha,
            DP.Monto,
            TD.Nombre
        FROM @deduccionesProcesar DP
        JOIN dbo.TipoDeduccion TD ON DP.idTipoDeduccion = TD.id;
        
        -- Actualizar planillas mensuales
        UPDATE PME
        SET 
            PME.SalarioBruto = PME.SalarioBruto + PSE.SalarioBruto,
            PME.TotalDeducciones = PME.TotalDeducciones + PSE.TotalDeducciones,
            PME.SalarioNeto = PME.SalarioNeto + PSE.SalarioNeto
        FROM dbo.PlanillaMexXEmpleado AS PME
        JOIN dbo.PlanillaSemXEmpleado AS PSE ON PME.idEmpleado = PSE.idEmpleado
        WHERE PSE.idSemanaPlanilla = @idSemanaPlanilla
          AND PME.idMesPlanilla = @idMesPlanilla;
        
        -- Actualizar deducciones por mes
        MERGE INTO dbo.DeduccionesXEmpleadoxMes AS target
        USING (
            SELECT 
                PME.id AS idPlanillaMexXEmpleado,
                DP.idTipoDeduccion,
                DP.Monto
            FROM @deduccionesProcesar AS DP
            JOIN PlanillaSemXEmpleado AS PSE ON DP.idPlanillaSemXEmpleado = PSE.id
            JOIN PlanillaMexXEmpleado AS PME ON PSE.idEmpleado = PME.idEmpleado 
                                                AND PME.idMesPlanilla = @idMesPlanilla
        ) AS source
        ON target.idPlanillaMexXEmpleado = source.idPlanillaMexXEmpleado
           AND target.idTipoDeduccion = source.idTipoDeduccion
        WHEN MATCHED THEN
            UPDATE SET target.Monto = target.Monto + source.Monto
        WHEN NOT MATCHED THEN
            INSERT (
                idPlanillaMexXEmpleado
                , idTipoDeduccion
                , Monto)
            VALUES (source.idPlanillaMexXEmpleado
            , source.idTipoDeduccion
            , source.Monto);
        
        -- Marcar semana como cerrada
        UPDATE dbo.SemanaPlanilla
        SET Cerrado = 1
        WHERE id = @idSemanaPlanilla;
        
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