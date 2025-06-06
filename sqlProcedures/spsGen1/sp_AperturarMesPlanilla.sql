CREATE OR ALTER PROCEDURE sp_AperturarMesPlanilla
    @inFechaInicio DATE,
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @outResultCode = 0;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        DECLARE @anio INT = YEAR(@inFechaInicio);
        DECLARE @mes INT = MONTH(@inFechaInicio);
        DECLARE @fechaFin DATE;
        DECLARE @idMesPlanilla INT;
        
        -- Calcular fecha fin (último jueves del mes)
        -- Obtener el último día del mes
        DECLARE @ultimoDiaMes DATE = EOMONTH(@inFechaInicio);
        -- Calcular el último jueves del mes
        SET @fechaFin = DATEADD(DAY, -((DATEPART(WEEKDAY, @ultimoDiaMes) + @@DATEFIRST - 5 + 7) % 7), @ultimoDiaMes);
        
        -- Insertar mes de planilla
        INSERT INTO MesPlanilla (
            Anio, 
            Mes, 
            FechaInicio, 
            FechaFin, 
            Cerrado
        )
        VALUES (
            @anio, 
            @mes, 
            @inFechaInicio, 
            @fechaFin, 
            0
        );
        
        SET @idMesPlanilla = SCOPE_IDENTITY();
        
        -- Crear registros de planilla mensual para cada empleado activo
        INSERT INTO PlanillaMexXEmpleado (
            idMesPlanilla, 
            idEmpleado, 
            SalarioBruto, 
            TotalDeducciones, 
            SalarioNeto
        )
        SELECT 
            @idMesPlanilla, 
            id, 
            0, 
            0, 
            0
        FROM Empleado
        WHERE Activo = 1;
        
        COMMIT TRANSACTION;
        
        -- Retornar datos del mes creado
        SELECT 
            id AS idMesPlanilla,
            Anio,
            Mes,
            FechaInicio,
            FechaFin
        FROM MesPlanilla
        WHERE id = @idMesPlanilla;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        SET @outResultCode = 50040 + ERROR_NUMBER();
        -- Error 50040+: Error al aperturar mes
        THROW;
    END CATCH;
END;