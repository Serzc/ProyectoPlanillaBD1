ALTER PROCEDURE dbo.sp_obtenerPlanillasMensuales
    @inIdEmpleado INT,
    @inCantidad INT,
    @outResultado INT OUTPUT
AS
BEGIN
    BEGIN TRY
        SET @outResultado = 0;

        SELECT TOP (@inCantidad)
            PME.id AS Id,
            MP.FechaInicio AS FechaInicio,
            MP.FechaFin AS FechaFin,
            PME.SalarioBruto AS SalarioBruto,
            PME.TotalDeducciones AS TotalDeducciones,
            PME.SalarioNeto AS SalarioNeto
        FROM dbo.PlanillaMexXEmpleado PME
        INNER JOIN dbo.MesPlanilla MP ON PME.idMesPlanilla = MP.id
        WHERE PME.idEmpleado = @inIdEmpleado
        ORDER BY MP.FechaInicio DESC;
    END TRY
    BEGIN CATCH
        SET @outResultado = 50000 + ERROR_NUMBER();
    END CATCH
END
