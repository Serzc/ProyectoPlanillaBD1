CREATE OR ALTER PROCEDURE sp_CierreSemanalPlanilla
    @inFechaCierre DATE,
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @outResultCode = 0;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        DECLARE @idSemanaPlanilla INT;
        DECLARE @idMesPlanilla INT;
        DECLARE @semanasEnMes INT;
        
        -- Obtener semana de planilla a cerrar
        SELECT 
            @idSemanaPlanilla = id, 
            @idMesPlanilla = idMesPlanilla
        FROM SemanaPlanilla
        WHERE @inFechaCierre BETWEEN FechaInicio AND FechaFin
          AND Cerrado = 0;
        
        -- Calcular semanas en el mes (para deducciones fijas)
        SELECT @semanasEnMes = COUNT(*)
        FROM SemanaPlanilla
        WHERE idMesPlanilla = @idMesPlanilla;
        
        -- Actualizar planillas semanales con deducciones
        UPDATE pse
        SET 
            SalarioBruto = (
                SELECT SUM(Monto)
                FROM MovimientoPlanilla mp
                WHERE mp.idPlanillaSemXEmpleado = pse.id
                  AND mp.idTipoMovimiento IN (1, 2, 3) -- Créditos
            ),
            TotalDeducciones = (
                SELECT SUM(
                    CASE 
                        WHEN ed.ValorPorcentual IS NOT NULL THEN 
                            (SELECT SUM(Monto) 
                             FROM MovimientoPlanilla 
                             WHERE idPlanillaSemXEmpleado = pse.id 
                               AND idTipoMovimiento IN (1, 2, 3)) * ed.ValorPorcentual
                        ELSE ed.ValorFijo / @semanasEnMes
                    END
                )
                FROM EmpleadoDeduccion ed
                WHERE ed.idEmpleado = pse.idEmpleado
                  AND (ed.FechaDesasociacion IS NULL OR ed.FechaDesasociacion > @inFechaCierre)
            ),
            SalarioNeto = (
                SELECT SUM(Monto)
                FROM MovimientoPlanilla mp
                WHERE mp.idPlanillaSemXEmpleado = pse.id
                  AND mp.idTipoMovimiento IN (1, 2, 3) -- Créditos
            ) - (
                SELECT SUM(
                    CASE 
                        WHEN ed.ValorPorcentual IS NOT NULL THEN 
                            (SELECT SUM(Monto) 
                             FROM MovimientoPlanilla 
                             WHERE idPlanillaSemXEmpleado = pse.id 
                               AND idTipoMovimiento IN (1, 2, 3)) * ed.ValorPorcentual
                        ELSE ed.ValorFijo / @semanasEnMes
                    END
                )
                FROM EmpleadoDeduccion ed
                WHERE ed.idEmpleado = pse.idEmpleado
                  AND (ed.FechaDesasociacion IS NULL OR ed.FechaDesasociacion > @inFechaCierre)
            )
        FROM PlanillaSemXEmpleado pse
        WHERE pse.idSemanaPlanilla = @idSemanaPlanilla;
        
        -- Actualizar planilla mensual
        UPDATE pme
        SET 
            SalarioBruto = pme.SalarioBruto + pse.SalarioBruto,
            TotalDeducciones = pme.TotalDeducciones + pse.TotalDeducciones,
            SalarioNeto = pme.SalarioNeto + pse.SalarioNeto
        FROM PlanillaMexXEmpleado pme
        JOIN PlanillaSemXEmpleado pse ON pme.idEmpleado = pse.idEmpleado
        WHERE pse.idSemanaPlanilla = @idSemanaPlanilla
          AND pme.idMesPlanilla = @idMesPlanilla;
        
        -- Actualizar deducciones por tipo en el mes
        MERGE INTO DeduccionesXEmpleadoxMes AS target
        USING (
            SELECT 
                pme.id AS idPlanillaMexXEmpleado,
                ed.idTipoDeduccion,
                SUM(
                    CASE 
                        WHEN ed.ValorPorcentual IS NOT NULL THEN 
                            pse.SalarioBruto * ed.ValorPorcentual
                        ELSE ed.ValorFijo / @semanasEnMes
                    END
                ) AS Monto
            FROM PlanillaSemXEmpleado pse
            JOIN PlanillaMexXEmpleado pme ON pse.idEmpleado = pme.idEmpleado 
                                         AND pme.idMesPlanilla = @idMesPlanilla
            JOIN EmpleadoDeduccion ed ON pse.idEmpleado = ed.idEmpleado
            WHERE pse.idSemanaPlanilla = @idSemanaPlanilla
              AND (ed.FechaDesasociacion IS NULL OR ed.FechaDesasociacion > @inFechaCierre)
            GROUP BY pme.id, ed.idTipoDeduccion
        ) AS source
        ON target.idPlanillaMexXEmpleado = source.idPlanillaMexXEmpleado
           AND target.idTipoDeduccion = source.idTipoDeduccion
        WHEN MATCHED THEN
            UPDATE SET Monto = target.Monto + source.Monto
        WHEN NOT MATCHED THEN
            INSERT (idPlanillaMexXEmpleado, idTipoDeduccion, Monto)
            VALUES (source.idPlanillaMexXEmpleado, source.idTipoDeduccion, source.Monto);
        
        -- Marcar semana como cerrada
        UPDATE SemanaPlanilla 
        SET Cerrado = 1 
        WHERE id = @idSemanaPlanilla;
        
        COMMIT TRANSACTION;
        
        -- Retornar resumen del cierre
        SELECT 
            COUNT(*) AS EmpleadosProcesados,
            SUM(SalarioBruto) AS TotalSalarioBruto,
            SUM(TotalDeducciones) AS TotalDeducciones,
            SUM(SalarioNeto) AS TotalSalarioNeto
        FROM PlanillaSemXEmpleado
        WHERE idSemanaPlanilla = @idSemanaPlanilla;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        SET @outResultCode = 50030 + ERROR_NUMBER();
        -- Error 50030+: Error en cierre semanal
        THROW;
    END CATCH;
END;