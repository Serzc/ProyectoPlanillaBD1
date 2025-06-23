CREATE OR ALTER PROCEDURE sp_obtenerEmpleadoPorId
    @inId INT,
    @outResultado INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SELECT 
            E.id,
            E.ValorDocumentoIdentidad,
            E.Nombre,
            E.idPuesto,
            P.Nombre AS Puesto,
            P.SalarioXHora,
            E.FechaNacimiento,
            E.FechaContratacion,
            E.SaldoVacaciones,
            E.Activo,
            E.idDepartamento,
            D.Nombre AS Departamento
        FROM dbo.Empleado E
        JOIN dbo.Puesto P ON E.idPuesto = P.id
        JOIN dbo.Departamento D ON E.idDepartamento = D.id
        WHERE E.id = @inId;

        SET @outResultado = 0;
        RETURN 0;
    END TRY
    BEGIN CATCH
        SET @outResultado = ERROR_NUMBER();
        RETURN @outResultado;
    END CATCH;
END