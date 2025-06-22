ALTER PROCEDURE dbo.sp_obtenerDetalleDeducciones
    @inIdPlanilla INT,
    @outResultado INT OUTPUT
AS
BEGIN
    BEGIN TRY
        SET @outResultado = 0;

        SELECT 
            TD.Nombre AS Nombre,
            TD.Valor AS Porcentaje,
            MP.Monto AS Monto
        FROM dbo.MovimientoPlanilla MP
        INNER JOIN dbo.TipoMovimiento TM ON TM.id = MP.idTipoMovimiento
        INNER JOIN dbo.TipoDeduccion TD ON TD.Nombre = TM.Nombre
        WHERE MP.idPlanillaSemXEmpleado = @inIdPlanilla
          AND TM.Nombre LIKE 'Debito%';
    END TRY
    BEGIN CATCH
        SET @outResultado = 50000 + ERROR_NUMBER();
    END CATCH
END
