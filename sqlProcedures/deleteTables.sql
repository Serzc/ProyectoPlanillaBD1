-- Script para limpiar todos los datos (ejecutar solo si es necesario)
BEGIN TRY
    BEGIN TRANSACTION;
    
    DELETE FROM EmpleadoDeduccion;
    DELETE FROM JornadaEmpleado; 
    DELETE FROM DeduccionesXEmpleadoxMes;
    DELETE FROM MovimientoPlanilla;
    DELETE FROM PlanillaSemXEmpleado;
    DELETE FROM PlanillaMexXEmpleado;
    DELETE FROM SemanaPlanilla;
    DELETE FROM MesPlanilla;
    DELETE FROM Asistencia;
    DELETE FROM MovimientoXHora;
    DELETE FROM DBError;
    DELETE FROM TipoError;
    DELETE FROM EventLog;
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

    DBCC CHECKIDENT ('Usuario', RESEED, 0);
    DBCC CHECKIDENT ('Empleado', RESEED, 0);
    DBCC CHECKIDENT ('EmpleadoDeduccion', RESEED, 0);
    DBCC CHECKIDENT ('JornadaEmpleado', RESEED, 0);
    DBCC CHECKIDENT ('MesPlanilla', RESEED, 0);
    DBCC CHECKIDENT ('SemanaPlanilla', RESEED, 0);
    DBCC CHECKIDENT ('PlanillaSemXEmpleado', RESEED, 0);
    DBCC CHECKIDENT ('PlanillaMexXEmpleado', RESEED, 0);
    DBCC CHECKIDENT ('MovimientoPlanilla', RESEED, 0);
    DBCC CHECKIDENT ('DeduccionesXEmpleadoxMes', RESEED, 0);
    DBCC CHECKIDENT ('EventLog', RESEED, 0);
    DBCC CHECKIDENT ('Asistencia', RESEED, 0);
    DBCC CHECKIDENT ('MovimientoXHora', RESEED, 0);
    COMMIT TRANSACTION;
    PRINT 'Todos los datos fueron eliminados exitosamente.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    
    PRINT 'Error al eliminar datos:';
    PRINT ERROR_MESSAGE();
END CATCH;