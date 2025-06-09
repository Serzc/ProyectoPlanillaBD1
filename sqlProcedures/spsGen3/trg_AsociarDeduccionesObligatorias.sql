CREATE OR ALTER TRIGGER trg_AsociarDeduccionesObligatorias
ON Empleado
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Insertar deducciones obligatorias para cada nuevo empleado
        INSERT INTO EmpleadoDeduccion (
            idEmpleado,
            idTipoDeduccion,
            ValorPorcentual,
            ValorFijo,
            FechaAsociacion
        )
        SELECT 
            i.id,
            td.id,
            CASE WHEN td.Porcentual = 1 THEN td.Valor ELSE NULL END,
            CASE WHEN td.Porcentual = 0 THEN td.Valor ELSE NULL END,
            GETDATE()
        FROM inserted i
        CROSS JOIN TipoDeduccion td
        WHERE td.Obligatorio = 1;
    END TRY
    BEGIN CATCH
        -- Registrar error pero no detener la operación

        INSERT INTO DBError (
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