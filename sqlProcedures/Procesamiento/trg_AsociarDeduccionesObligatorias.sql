CREATE OR ALTER TRIGGER trg_AsociarDeduccionesObligatorias
ON Empleado
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Insertar deducciones obligatorias para cada nuevo empleado
        INSERT INTO dbo.EmpleadoDeduccion (
            idEmpleado,
            idTipoDeduccion,
            ValorPorcentual,
            ValorFijo,
            FechaAsociacion
        )
        SELECT 
            I.id,
            TD.id,
            CASE WHEN TD.Porcentual = 1 THEN TD.Valor ELSE NULL END,
            CASE WHEN TD.Porcentual = 0 THEN TD.Valor ELSE NULL END,
            I.FechaContratacion
        FROM inserted i
        CROSS JOIN TipoDeduccion AS TD
        WHERE TD.Obligatorio = 1;
    END TRY
    BEGIN CATCH
        INSERT INTO dbo.DBError (
            idTipoError,
            Mensaje,
            Procedimiento,
            Linea
        )
        VALUES (
            50014,
            ERROR_MESSAGE(),
            ERROR_PROCEDURE(),
            ERROR_LINE()
        );
    END CATCH
END;