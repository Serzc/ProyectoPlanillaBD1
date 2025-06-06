CREATE OR ALTER PROCEDURE sp_ObtenerDetalleDeducciones
    @inIdPlanillaSemXEmpleado INT,
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @outResultCode = 0;
    
    BEGIN TRY
        SELECT 
            td.Nombre AS Deduccion,
            CASE 
                WHEN ed.ValorPorcentual IS NOT NULL THEN 
                    CAST(ed.ValorPorcentual * 100 AS VARCHAR) + '%'
                ELSE 'Fijo'
            END AS Tipo,
            CASE 
                WHEN ed.ValorPorcentual IS NOT NULL THEN 
                    pse.SalarioBruto * ed.ValorPorcentual
                ELSE ed.ValorFijo / (
                    SELECT COUNT(*) 
                    FROM SemanaPlanilla 
                    WHERE idMesPlanilla = (
                        SELECT idMesPlanilla 
                        FROM SemanaPlanilla 
                        WHERE id = @inIdPlanillaSemXEmpleado
                    )
                )
            END AS Monto
        FROM PlanillaSemXEmpleado pse
        JOIN EmpleadoDeduccion ed ON pse.idEmpleado = ed.idEmpleado
        JOIN TipoDeduccion td ON ed.idTipoDeduccion = td.id
        WHERE pse.id = @inIdPlanillaSemXEmpleado
          AND (ed.FechaDesasociacion IS NULL OR ed.FechaDesasociacion > (
              SELECT FechaFin 
              FROM SemanaPlanilla 
              WHERE id = @inIdPlanillaSemXEmpleado
          ));
    END TRY
    BEGIN CATCH
        SET @outResultCode = 50070 + ERROR_NUMBER();
        -- Error 50070+: Error al obtener detalle de deducciones
        THROW;
    END CATCH;
END;