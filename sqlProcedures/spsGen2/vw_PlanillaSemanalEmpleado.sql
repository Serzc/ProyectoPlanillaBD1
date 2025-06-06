CREATE OR ALTER VIEW vw_PlanillaSemanalEmpleado
AS
SELECT
    e.id AS idEmpleado,
    e.Nombre AS NombreEmpleado,
    sp.FechaInicio AS FechaInicioSemana,
    sp.FechaFin AS FechaFinSemana,
    pse.SalarioBruto,
    pse.TotalDeducciones,
    pse.SalarioNeto,
    ISNULL((SELECT SUM(CantidadHoras) FROM MovimientoPlanilla mp WHERE mp.idPlanillaSemXEmpleado = pse.id AND mp.idTipoMovimiento = 1), 0) AS HorasOrdinarias,
    ISNULL((SELECT SUM(CantidadHoras) FROM MovimientoPlanilla mp WHERE mp.idPlanillaSemXEmpleado = pse.id AND mp.idTipoMovimiento = 2), 0) AS HorasExtrasNormales,
    ISNULL((SELECT SUM(CantidadHoras) FROM MovimientoPlanilla mp WHERE mp.idPlanillaSemXEmpleado = pse.id AND mp.idTipoMovimiento = 3), 0) AS HorasExtrasDobles
FROM Empleado e
JOIN PlanillaSemXEmpleado pse ON pse.idEmpleado = e.id
JOIN SemanaPlanilla sp ON sp.id = pse.idSemanaPlanilla
WHERE e.Activo = 1;