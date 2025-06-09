CREATE OR ALTER PROCEDURE sp_ProcesarCierreMensual
    @inFecha DATE,
    @outResultado INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        DECLARE @idMesPlanilla INT;
        DECLARE @fechaInicioMes DATE, @fechaFinMes DATE;
        
        -- Obtener mes de planilla actual
        SELECT 
            @idMesPlanilla = mp.id,
            @fechaInicioMes = mp.FechaInicio,
            @fechaFinMes = mp.FechaFin
        FROM MesPlanilla mp
        WHERE @inFecha BETWEEN mp.FechaInicio AND mp.FechaFin
        AND mp.Cerrado = 0;
        
        IF @idMesPlanilla IS NULL
        BEGIN
            SET @outResultado = 50017; -- Mes de planilla no encontrado
            THROW @outResultado, 'Mes de planilla no encontrado', 1;
        END
        
        -- Marcar mes como cerrado
        UPDATE MesPlanilla
        SET Cerrado = 1
        WHERE id = @idMesPlanilla;
        
        -- No hay más procesamiento aquí según los requerimientos
        -- Los datos ya están acumulados en las tablas correspondientes
        
        SET @outResultado = 0;
    END TRY
    BEGIN CATCH
        IF @outResultado = 0
            SET @outResultado = COALESCE(ERROR_NUMBER(), 50018);
        
        DECLARE @errorDesc VARCHAR(200) = CONCAT('En la fecha: ',@inFecha,' ',ERROR_MESSAGE());
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
            ERROR_LINE()
        );
        
    END CATCH
END;