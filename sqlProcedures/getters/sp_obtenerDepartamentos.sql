ALTER PROCEDURE dbo.sp_obtenerDepartamentos
    @outResultado INT OUTPUT
AS
BEGIN
    BEGIN TRY
        SET @outResultado = 0;

        SELECT 
            D.id AS Id,
            D.Nombre AS Nombre
        FROM dbo.Departamento D;
    END TRY
    BEGIN CATCH
        SET @outResultado = 50000 + ERROR_NUMBER();
    END CATCH
END
