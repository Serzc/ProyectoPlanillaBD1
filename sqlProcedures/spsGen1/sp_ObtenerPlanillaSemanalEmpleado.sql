CREATE OR ALTER PROCEDURE sp_ObtenerPlanillaSemanalEmpleado
    @inIdEmpleado INT,
    @inCantidadSemanas INT = 15,
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @outResultCode = 0;
    
    BEGIN TRY
        SELECT TOP (@inCantidadSemanas)
            sp.id AS idSemanaPlanilla,
            sp.FechaInicio,
            sp.FechaFin,
            pse.SalarioBruto,
            pse.TotalDeducciones,
            pse.SalarioNeto,
            (
                SELECT SUM(mp.CantidadHoras)
                FROM MovimientoPlanilla mp
                WHERE mp.idPlanillaSemXEmpleado = pse.id
                  AND mp.idTipoMovimiento = 1 -- Horas ordinarias
            ) AS HorasOrdinarias,
            (
                SELECT SUM(mp.CantidadHoras)
                FROM MovimientoPlanilla mp
                WHERE mp.idPlanillaSemXEmpleado = pse.id
                  AND mp.idTipoMovimiento = 2 -- Horas extra normales
            ) AS HorasExtrasNormales,
            (
                SELECT SUM(mp.CantidadHoras)
                FROM MovimientoPlanilla mp
                WHERE mp.idPlanillaSemXEmpleado = pse.id
                  AND mp.idTipoMovimiento = 3 -- Horas extra dobles
            ) AS HorasExtrasDobles
        FROM PlanillaSemXEmpleado pse
        JOIN SemanaPlanilla sp ON pse.idSemanaPlanilla = sp.id
        WHERE pse.idEmpleado = @inIdEmpleado
        ORDER BY sp.FechaInicio DESC;
    END TRY
    BEGIN CATCH
        SET @outResultCode = 50060 + ERROR_NUMBER();
        -- Error 50060+: Error al obtener planilla semanal
        THROW;
    END CATCH;
END;