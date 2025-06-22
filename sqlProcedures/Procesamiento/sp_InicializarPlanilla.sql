CREATE OR ALTER PROCEDURE sp_InicializarPlanilla
    @inFechaInicio DATE,  -- Fecha del primer jueves del sistema
    @outResultado INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- 1. Crear el primer mes de planilla
        DECLARE @primerJueves DATE = @inFechaInicio;
        DECLARE @ultimoJueves DATE = DATEADD(DAY, -1, DATEADD(MONTH, 1, @primerJueves));
        
        -- Ajustar para encontrar el último jueves del mes
        WHILE DATEPART(WEEKDAY, @ultimoJueves) <> 5  -- 5 = Jueves
        BEGIN
            SET @ultimoJueves = DATEADD(DAY, -1, @ultimoJueves);
        END
        
        INSERT INTO MesPlanilla (Anio, Mes, FechaInicio, FechaFin, Cerrado)
        VALUES (
            YEAR(@primerJueves),
            MONTH(@primerJueves),
            DATEADD(DAY, 1, @primerJueves),
            @ultimoJueves,
            0
        );
        
        DECLARE @idMesPlanilla INT = SCOPE_IDENTITY();
        
        -- 2. Crear las semanas para este mes
        DECLARE @fechaInicioSemana DATE = @primerJueves;
        DECLARE @fechaFinSemana DATE = DATEADD(DAY, 6, @fechaInicioSemana);
        DECLARE @semanaNum INT = 1;
        
        WHILE @fechaInicioSemana <= @ultimoJueves
        BEGIN
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
            
            SET @semanaNum = @semanaNum + 1;
            SET @fechaInicioSemana = DATEADD(DAY, 7, @fechaInicioSemana);
            SET @fechaFinSemana = DATEADD(DAY, 6, @fechaInicioSemana);
        END;
        
        COMMIT TRANSACTION;
        SET @outResultado = 0;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        IF @outResultado = 0
            SET @outResultado = COALESCE(ERROR_NUMBER(), 50008); -- Error en la base de datos
        
        DECLARE @errorDesc VARCHAR(200) = ERROR_MESSAGE();
        DECLARE @errorLine INT = ERROR_LINE();
        INSERT INTO DBError (
            idTipoError,
            Mensaje,
            Procedimiento,
            Linea
        )
        VALUES (
            @outResultado,
            ERROR_MESSAGE(),
            ERROR_PROCEDURE(),
            ERROR_LINE()
        );

    END CATCH
END;