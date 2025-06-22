ALTER PROCEDURE dbo.sp_obtenerPlanillasSemanales
    @inIdEmpleado INT,
    @inCantidad INT,
    @outResultado INT OUTPUT
AS
BEGIN
    BEGIN TRY
        SET @outResultado = 0;

        SELECT TOP (@inCantidad)
            P.id AS Id,
            SP.FechaInicio AS FechaInicio,
            SP.FechaFin AS FechaFin,
            P.SalarioBruto AS SalarioBruto,
            P.TotalDeducciones AS TotalDeducciones,
            P.SalarioNeto AS SalarioNeto,
            SUM(CASE WHEN TM.Nombre = 'Credito Horas ordinarias' THEN ISNULL(MP.Monto, 0) ELSE 0 END) AS HorasOrdinarias,
            SUM(CASE WHEN TM.Nombre = 'Credito Horas Extra Normales' THEN ISNULL(MP.Monto, 0) ELSE 0 END) AS HorasExtrasNormales,
            SUM(CASE WHEN TM.Nombre = 'Credito Horas Extra Dobles' THEN ISNULL(MP.Monto, 0) ELSE 0 END) AS HorasExtrasDobles
        FROM dbo.PlanillaSemXEmpleado P
        INNER JOIN dbo.SemanaPlanilla SP ON P.idSemanaPlanilla = SP.id
        LEFT JOIN dbo.MovimientoPlanilla MP ON MP.idPlanillaSemXEmpleado = P.id
            AND MP.idTipoMovimiento IN (
                SELECT id FROM dbo.TipoMovimiento WHERE Nombre LIKE 'Credito%'
            )
        LEFT JOIN dbo.TipoMovimiento TM ON TM.id = MP.idTipoMovimiento
        WHERE P.idEmpleado = @inIdEmpleado
        GROUP BY P.id, SP.FechaInicio, SP.FechaFin, P.SalarioBruto, P.TotalDeducciones, P.SalarioNeto
        ORDER BY SP.FechaInicio DESC;
    END TRY
    BEGIN CATCH
        SET @outResultado = 50000 + ERROR_NUMBER();
    END CATCH
END
