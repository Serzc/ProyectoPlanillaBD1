ALTER PROCEDURE dbo.sp_obtenerTiposDocumentoIdentidad
    @outResultado INT OUTPUT
AS
BEGIN
    BEGIN TRY
        SET @outResultado = 0;

        SELECT 
            TDI.id AS Id,
            TDI.Nombre AS Nombre
        FROM dbo.TipoDocumentoIdentidad TDI;
    END TRY
    BEGIN CATCH
        SET @outResultado = 50000 + ERROR_NUMBER();
    END CATCH
END
