-- Script para limpiar todos los datos (ejecutar solo si es necesario)
BEGIN TRY
    BEGIN TRANSACTION;
    
    DELETE FROM EmpleadoDeduccion;
    DELETE FROM Empleado;
    DELETE FROM Usuario;
    DELETE FROM TipoEvento;
    DELETE FROM TipoDeduccion;
    DELETE FROM TipoMovimiento;
    DELETE FROM Feriado;
    DELETE FROM Departamento;
    DELETE FROM Puesto;
    DELETE FROM TipoJornada;
    DELETE FROM TipoDocumentoIdentidad;
    
    COMMIT TRANSACTION;
    PRINT 'Todos los datos fueron eliminados exitosamente.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    
    PRINT 'Error al eliminar datos:';
    PRINT ERROR_MESSAGE();
END CATCH;