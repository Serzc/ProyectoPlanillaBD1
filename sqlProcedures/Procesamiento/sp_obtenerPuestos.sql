ALTER PROCEDURE dbo.sp_obtenerPuestos
    @outResultado INT OUTPUT
AS
BEGIN
    BEGIN TRY
        SET @outResultado = 0;

        SELECT 
            P.id AS Id,
            P.Nombre AS Nombre,
            P.SalarioXHora AS SalarioXHora
        FROM dbo.Puesto P;
    END TRY
    BEGIN CATCH
        SET @outResultado = 50000 + ERROR_NUMBER();
    END CATCH
END
