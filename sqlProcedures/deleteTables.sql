-- Script para limpiar todos los datos (ejecutar solo si es necesario)
CREATE OR ALTER PROCEDURE sp_borrarTablas
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        DELETE FROM dbo.EmpleadoDeduccion;
        DELETE FROM dbo.JornadaEmpleado; 
        DELETE FROM dbo.DeduccionesXEmpleadoxMes;
        DELETE FROM dbo.MovimientoXHora;
        DELETE FROM dbo.Asistencia;
        DELETE FROM dbo.MovimientoPlanilla;
        DELETE FROM dbo.PlanillaSemXEmpleado;
        DELETE FROM dbo.PlanillaMexXEmpleado;  
        DELETE FROM dbo.SemanaPlanilla;
        DELETE FROM dbo.MesPlanilla;
        DELETE FROM dbo.DBError;
        DELETE FROM dbo.TipoError;
        DELETE FROM dbo.EventLog;
        DELETE FROM dbo.Empleado;
        DELETE FROM dbo.Usuario;
        DELETE FROM dbo.TipoEvento;
        DELETE FROM dbo.TipoDeduccion;
        DELETE FROM dbo.TipoMovimiento;
        DELETE FROM dbo.Feriado;
        DELETE FROM dbo.Departamento;
        DELETE FROM dbo.Puesto;
        DELETE FROM dbo.TipoJornada;
        DELETE FROM dbo.TipoDocumentoIdentidad;

        DBCC CHECKIDENT ('Puesto', RESEED, 0);
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
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

    END CATCH
END;