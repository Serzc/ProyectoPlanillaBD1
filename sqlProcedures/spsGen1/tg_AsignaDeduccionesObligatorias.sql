CREATE OR ALTER TRIGGER tg_AsignaDeduccionesObligatorias
ON Empleado
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
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
        -- Error 50050: Error en trigger de asignación de deducciones
        THROW 50050, 'Error al asignar deducciones obligatorias al nuevo empleado.', 1;
    END CATCH;
END;