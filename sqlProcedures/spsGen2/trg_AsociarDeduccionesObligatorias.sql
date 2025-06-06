CREATE OR ALTER TRIGGER trg_AsociarDeduccionesObligatorias
ON Empleado
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        INSERT INTO EmpleadoDeduccion (
            idEmpleado,
            idTipoDeduccion,
            ValorPorcentual
        )
        SELECT 
            i.id,
            td.id,
            td.Valor
        FROM inserted i
        CROSS JOIN TipoDeduccion td
        WHERE td.Obligatorio = 1 AND td.Porcentual = 1;
    END TRY
    BEGIN CATCH
        -- Registrar error en bitácora
        INSERT INTO EventLog (
            idTipoEvento,
            Parametros
        )
        VALUES (
            17, -- TipoEvento: Error en trigger
            JSON_MODIFY('{}', '$.Error', ERROR_MESSAGE())
        );
    END CATCH;
END;