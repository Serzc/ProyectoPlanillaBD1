ALTER PROCEDURE dbo.sp_obtenerDetalleDeduccionesMensuales
    @inIdPlanilla INT,
    @outResultado INT OUTPUT
AS
BEGIN
    BEGIN TRY
        SET @outResultado = 0;

        SELECT 
            TD.Nombre AS Nombre,
            TD.Valor AS Porcentaje,
            DX.Monto AS Monto
        FROM dbo.DeduccionesXEmpleadoxMes DX
        INNER JOIN dbo.TipoDeduccion TD ON DX.idTipoDeduccion = TD.id
        WHERE DX.idPlanillaMexXEmpleado = @inIdPlanilla;
    END TRY
    BEGIN CATCH
        SET @outResultado = 50000 + ERROR_NUMBER();
    END CATCH
END
