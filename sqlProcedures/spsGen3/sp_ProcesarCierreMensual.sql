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
            @idMesPlanilla = MP.id,
            @fechaInicioMes = MP.FechaInicio,
            @fechaFinMes = MP.FechaFin
        FROM dbo.MesPlanilla MP
        WHERE @inFecha BETWEEN MP.FechaInicio AND MP.FechaFin
        AND MP.Cerrado = 0;
        
        IF @idMesPlanilla IS NULL
        BEGIN
            SET @outResultado = 50017; -- Mes de planilla no encontrado
            THROW @outResultado, 'Mes de planilla no encontrado', 1;
        END
        
        -- Marcar mes como cerrado
        UPDATE dbo.MesPlanilla
        SET Cerrado = 1
        WHERE id = @idMesPlanilla;
        
        
        SET @outResultado = 0;
    END TRY
    BEGIN CATCH
        IF @outResultado = 0
            SET @outResultado = COALESCE(ERROR_NUMBER(), 50018);
        
        DECLARE @errorDesc VARCHAR(200) = CONCAT('En la fecha: ',@inFecha,' ',ERROR_MESSAGE());
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
            ERROR_LINE()
        );
        
    END CATCH
END;