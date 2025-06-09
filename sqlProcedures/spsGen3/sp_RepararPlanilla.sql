CREATE OR ALTER PROCEDURE sp_RepararPlanilla
    @inFechaReparacion DATE,
    @outResultado INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- 1. Cerrar todos los meses pasados no cerrados
        UPDATE MesPlanilla
        SET Cerrado = 1
        WHERE FechaFin < @inFechaReparacion
        AND Cerrado = 0;
        
        -- 2. Encontrar o crear mes actual
        DECLARE @idMesPlanilla INT;
        
        SELECT @idMesPlanilla = id
        FROM MesPlanilla
        WHERE @inFechaReparacion BETWEEN FechaInicio AND FechaFin;
        
        IF @idMesPlanilla IS NULL
        BEGIN
            -- Calcular primer jueves del mes actual
            DECLARE @primerJueves DATE = DATEADD(DAY, -((DAY(@inFechaReparacion) + DATEPART(WEEKDAY, @inFechaReparacion) + 5) % 7), @inFechaReparacion);
            WHILE DATEPART(WEEKDAY, @primerJueves) <> 5
                SET @primerJueves = DATEADD(DAY, 1, @primerJueves);
            
            -- Calcular último jueves del mes
            DECLARE @ultimoJueves DATE = DATEADD(DAY, -1, DATEADD(MONTH, 1, @primerJueves));
            WHILE DATEPART(WEEKDAY, @ultimoJueves) <> 5
                SET @ultimoJueves = DATEADD(DAY, -1, @ultimoJueves);
            
            INSERT INTO MesPlanilla (Anio, Mes, FechaInicio, FechaFin, Cerrado)
            VALUES (
                YEAR(@primerJueves),
                MONTH(@primerJueves),
                @primerJueves,
                @ultimoJueves,
                0
            );
            
            SET @idMesPlanilla = SCOPE_IDENTITY();
        END
        
        -- 3. Crear semanas faltantes en el mes actual
        DECLARE @fechaActual DATE = (
            SELECT ISNULL(MAX(FechaFin), DATEADD(DAY, -6, @inFechaReparacion)) 
            FROM SemanaPlanilla 
            WHERE idMesPlanilla = @idMesPlanilla
        );
        
        WHILE @fechaActual < @inFechaReparacion
        BEGIN
            SET @fechaActual = DATEADD(DAY, 7, @fechaActual);
            
            IF NOT EXISTS (
                SELECT 1 
                FROM SemanaPlanilla 
                WHERE idMesPlanilla = @idMesPlanilla 
                AND @fechaActual BETWEEN FechaInicio AND FechaFin
            )
            BEGIN
                DECLARE @semanaNum INT = (
                    SELECT COUNT(*) + 1 
                    FROM SemanaPlanilla 
                    WHERE idMesPlanilla = @idMesPlanilla
                );
                
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
                    @fechaActual,
                    DATEADD(DAY, 6, @fechaActual),
                    0
                );
                
                -- Crear registros para empleados
                INSERT INTO PlanillaSemXEmpleado (idSemanaPlanilla, idEmpleado, SalarioBruto, TotalDeducciones, SalarioNeto)
                SELECT 
                    SCOPE_IDENTITY(),
                    id,
                    0,
                    0,
                    0
                FROM Empleado
                WHERE Activo = 1;
            END
        END
        
        COMMIT TRANSACTION;
        SET @outResultado = 0;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        SET @outResultado = COALESCE(ERROR_NUMBER(), 50027);
        
        INSERT INTO DBError (
            idTipoError,
            Mensaje,
            Procedimiento,
            Linea
        )
        VALUES (
            @outResultado,
            ERROR_MESSAGE(),
            'sp_RepararPlanilla',
            ERROR_LINE()
        );
    END CATCH
END;