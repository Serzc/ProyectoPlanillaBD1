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
            SET @outResultado = 50008; -- Error en la base de datos
            THROW @outResultado, 'La fecha proporcionada no es un jueves', 1;
        END
        
        DECLARE @fechaInicioSemana DATE = DATEADD(DAY, 1, @inFechaJueves); -- Viernes
        DECLARE @fechaFinSemana DATE = DATEADD(DAY, 6, @fechaInicioSemana); -- Siguiente jueves
        
        -- Determinar el mes de planilla correcto (basado en el mes natural del jueves de cierre)
        DECLARE @mesNatural INT = MONTH(@inFechaJueves);
        DECLARE @anioNatural INT = YEAR(@inFechaJueves);
        DECLARE @idMesPlanilla INT;
        DECLARE @esNuevoMes BIT = 0;
        
        -- Buscar mes existente para este periodo
        SELECT @idMesPlanilla = id
        FROM dbo.MesPlanilla
        WHERE Mes = @mesNatural 
          AND Anio = @anioNatural
          AND FechaFin > DATEADD(DAY, 1,@inFechaJueves);
          --AND Cerrado = 0;
        
        -- Si no existe mes, crear uno nuevo
        IF @idMesPlanilla IS NULL
        BEGIN
            -- Calcular el primer jueves del mes natural
            DECLARE @primerDiaMes DATE = DATEFROMPARTS(@anioNatural, @mesNatural, 1);
            DECLARE @primerJueves DATE = DATEADD(DAY, (5 - DATEPART(WEEKDAY, @primerDiaMes) + 7) % 7, @primerDiaMes);
            
            -- Calcular el último jueves del mes natural
            DECLARE @ultimoJueves DATE = dbo.GetUltimoJuevesDelMes(@primerDiaMes);
            
            -- Insertar nuevo mes con el rango completo desde el primer viernes hasta el último jueves
            INSERT INTO dbo.MesPlanilla (
                Anio
                , Mes
                , FechaInicio
                , FechaFin
                , Cerrado
                )
            VALUES (
                DATEPART(YEAR, dbo.GetUltimoJuevesDelMes(@fechaFinSemana)),
                DATEPART(MONTH, dbo.GetUltimoJuevesDelMes(@fechaFinSemana)),
                @fechaInicioSemana,
                dbo.GetUltimoJuevesDelMes(@fechaFinSemana),
                0
            );
            
            SET @idMesPlanilla = SCOPE_IDENTITY();
            SET @esNuevoMes = 1;
        END
        
        -- Verificar que la semana no exista ya
        IF EXISTS (
            SELECT 1 FROM dbo.SemanaPlanilla 
            WHERE FechaInicio = @fechaInicioSemana 
              AND FechaFin = @fechaFinSemana
        )
        BEGIN
            SET @outResultado = 50008; -- Error en la base de datos
            THROW @outResultado, 'La semana ya existe', 1;
        END
        
        -- Crear nueva semana
        DECLARE @semanaNum INT;
        
        IF @esNuevoMes = 1
            SET @semanaNum = 1;
        ELSE
            SELECT @semanaNum = COUNT(*) + 1
            FROM dbo.SemanaPlanilla
            WHERE idMesPlanilla = @idMesPlanilla;
        
        -- Insertar la nueva semana
        INSERT INTO dbo.SemanaPlanilla (
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
        INSERT INTO dbo.PlanillaSemXEmpleado (
            idSemanaPlanilla
            , idEmpleado
            , SalarioBruto
            , TotalDeducciones
            , SalarioNeto
            )
        SELECT 
            @idSemanaPlanilla,
            id,
            0,
            0,
            0
        FROM dbo.Empleado
        WHERE Activo = 1;
        
        -- Si es nuevo mes, crear también registros mensuales
        IF @esNuevoMes = 1
        BEGIN
            INSERT INTO dbo.PlanillaMexXEmpleado (
                idMesPlanilla
                , idEmpleado
                , SalarioBruto
                , TotalDeducciones
                , SalarioNeto
                )
            SELECT 
                @idMesPlanilla,
                id,
                0,
                0,
                0
            FROM dbo.Empleado
            WHERE Activo = 1;
            
            -- Crear registros de deducciones por mes para cada empleado
            INSERT INTO dbo.DeduccionesXEmpleadoxMes (
                idPlanillaMexXEmpleado
                , idTipoDeduccion
                , Monto
                )
            SELECT 
                PME.id,
                ED.idTipoDeduccion,
                0
            FROM dbo.PlanillaMexXEmpleado AS PME
            JOIN dbo.EmpleadoDeduccion AS ED ON PME.idEmpleado = ED.idEmpleado
            WHERE PME.idMesPlanilla = @idMesPlanilla
              AND ED.FechaDesasociacion IS NULL;
        END
        
        SET @outResultado = 0;
    END TRY
    BEGIN CATCH
        IF @outResultado = 0
            SET @outResultado = COALESCE(ERROR_NUMBER(), 50008); -- Error en la base de datos); -- error no reconocido
        
        DECLARE @errorDesc VARCHAR(200) = CONCAT('En la fecha: ', @inFechaJueves, ' - ', ERROR_MESSAGE());
        DECLARE @errorLine INT = ERROR_LINE();
        
        INSERT INTO dbo.DBError (
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