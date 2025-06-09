CREATE OR ALTER PROCEDURE sp_CrearNuevaSemanaPlanilla
    @inFechaJueves DATE,
    @outResultado INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Verificar que la fecha sea jueves
        IF DATEPART(WEEKDAY, @inFechaJueves) <> 5
        BEGIN
            SET @outResultado = 50022;
            THROW 50022, 'La fecha proporcionada no es un jueves', 1;
        END
        
        DECLARE @fechaInicioSemana DATE = DATEADD(DAY, 1, @inFechaJueves); -- Viernes
        DECLARE @fechaFinSemana DATE = DATEADD(DAY, 6, @fechaInicioSemana); -- Siguiente jueves
        
        -- Determinar si necesitamos un nuevo mes
        DECLARE @idMesPlanilla INT;
        DECLARE @esNuevoMes BIT = 0;
        
        -- Buscar mes existente que contenga el viernes de inicio
        SELECT @idMesPlanilla = id
        FROM MesPlanilla
        WHERE @fechaInicioSemana BETWEEN FechaInicio AND FechaFin;
        
        -- Si no existe mes, crear uno nuevo
        IF @idMesPlanilla IS NULL
        BEGIN
            -- Calcular el primer jueves del mes que contiene el viernes de inicio
            DECLARE @primerJueves DATE = 
                DATEADD(DAY, -((DATEPART(DAY, @fechaInicioSemana) + DATEPART(WEEKDAY, @fechaInicioSemana) + 5) % 7), @fechaInicioSemana);
            
            -- Asegurarnos que es jueves (5)
            WHILE DATEPART(WEEKDAY, @primerJueves) <> 5
                SET @primerJueves = DATEADD(DAY, 1, @primerJueves);
            
            -- Calcular el último jueves del mes
            DECLARE @ultimoJueves DATE = DATEADD(DAY, -1, DATEADD(MONTH, 1, @primerJueves));
            WHILE DATEPART(WEEKDAY, @ultimoJueves) <> 5
                SET @ultimoJueves = DATEADD(DAY, -1, @ultimoJueves);
            
            -- Insertar nuevo mes
            INSERT INTO MesPlanilla (Anio, Mes, FechaInicio, FechaFin, Cerrado)
            VALUES (
                YEAR(@primerJueves),
                MONTH(@primerJueves),
                @primerJueves,
                @ultimoJueves,
                0
            );
            
            SET @idMesPlanilla = SCOPE_IDENTITY();
            SET @esNuevoMes = 1;
        END
        
        -- Verificar nuevamente que tenemos un idMesPlanilla válido
        IF @idMesPlanilla IS NULL
        BEGIN
            SET @outResultado = 50024;
            THROW 50024, 'No se pudo determinar o crear el mes de planilla', 1;
        END
        
        -- Crear nueva semana
        DECLARE @semanaNum INT;
        
        IF @esNuevoMes = 1
            SET @semanaNum = 1;
        ELSE
            SELECT @semanaNum = COUNT(*) + 1
            FROM SemanaPlanilla
            WHERE idMesPlanilla = @idMesPlanilla;
        
        -- Insertar la nueva semana
        INSERT INTO SemanaPlanilla (
            idMesPlanilla,
            Semana,
            FechaInicio,
            FechaFin,
            Cerrado
        )
        VALUES (
            @idMesPlanilla,
            @semanaNum,
            @fechaInicioSemana,
            @fechaFinSemana,
            0
        );
        
        DECLARE @idSemanaPlanilla INT = SCOPE_IDENTITY();
        
        -- Crear registros de planilla para todos los empleados activos
        INSERT INTO PlanillaSemXEmpleado (idSemanaPlanilla, idEmpleado, SalarioBruto, TotalDeducciones, SalarioNeto)
        SELECT 
            @idSemanaPlanilla,
            id,
            0,
            0,
            0
        FROM Empleado
        WHERE Activo = 1;
        
        -- Si es nuevo mes, crear también registros mensuales
        IF @esNuevoMes = 1
        BEGIN
            INSERT INTO PlanillaMexXEmpleado (idMesPlanilla, idEmpleado, SalarioBruto, TotalDeducciones, SalarioNeto)
            SELECT 
                @idMesPlanilla,
                id,
                0,
                0,
                0
            FROM Empleado
            WHERE Activo = 1;
            
            -- Crear registros de deducciones por mes para cada empleado
            INSERT INTO DeduccionesXEmpleadoxMes (idPlanillaMexXEmpleado, idTipoDeduccion, Monto)
            SELECT 
                pme.id,
                ed.idTipoDeduccion,
                0
            FROM PlanillaMexXEmpleado pme
            JOIN EmpleadoDeduccion ed ON pme.idEmpleado = ed.idEmpleado
            WHERE pme.idMesPlanilla = @idMesPlanilla
              AND ed.FechaDesasociacion IS NULL;
        END
        
        SET @outResultado = 0;
    END TRY
    BEGIN CATCH
        IF @outResultado = 0
            SET @outResultado = COALESCE(ERROR_NUMBER(), 50023);
        
        DECLARE @errorDesc VARCHAR(200) = CONCAT('En la fecha: ', @inFechaJueves, ' - ', ERROR_MESSAGE());
        DECLARE @errorLine INT = ERROR_LINE();
        
        INSERT INTO DBError (
            idTipoError,
            Mensaje,
            Procedimiento,
            Linea
        )
        VALUES (
            @outResultado,
            @errorDesc,
            ERROR_PROCEDURE(),
            @errorLine
        );
    END CATCH
END;