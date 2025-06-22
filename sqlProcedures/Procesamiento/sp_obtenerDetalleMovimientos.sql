ALTER PROCEDURE dbo.sp_obtenerDetalleMovimientos
    @inIdPlanilla INT,
    @outResultado INT OUTPUT
AS
BEGIN
    BEGIN TRY
        SET @outResultado = 0;

        SELECT 
            TM.Nombre AS Nombre,
            MP.Monto AS Monto,
            MP.Fecha AS Fecha
        FROM dbo.MovimientoPlanilla MP
        INNER JOIN dbo.TipoMovimiento TM ON TM.id = MP.idTipoMovimiento
        WHERE MP.idPlanillaSemXEmpleado = @inIdPlanilla;
    END TRY
    BEGIN CATCH
        SET @outResultado = 50000 + ERROR_NUMBER();
    END CATCH
END
