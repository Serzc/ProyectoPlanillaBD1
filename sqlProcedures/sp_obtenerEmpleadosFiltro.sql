USE [proyectoBD1]
GO
/****** Object:  StoredProcedure [dbo].[sp_obtenerEmpleadosFiltro]    Script Date: 5/25/2025 5:59:40 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER   PROCEDURE [dbo].[sp_obtenerEmpleadosFiltro]
    @inFiltro VARCHAR(64) = NULL,
    @outResultado INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SELECT 
            E.id,
            E.ValorDocumentoIdentidad,
            E.Nombre,
            P.Nombre AS Puesto,
            P.SalarioXHora,
            E.FechaContratacion,
            E.SaldoVacaciones,
            E.Activo,
            E.idDepartamento,
            D.Nombre AS Departamento
        FROM dbo.Empleado E
        JOIN dbo.Puesto P ON E.idPuesto = P.id
        JOIN dbo.Departamento D ON E.idDepartamento = D.id
        WHERE E.Activo = 1
          AND (
              @inFiltro IS NULL
              OR @inFiltro = ''
              OR (
                  @inFiltro LIKE '%[^0-9]%' AND E.Nombre LIKE '%' + @inFiltro + '%'
              )
              OR (
                  @inFiltro NOT LIKE '%[^0-9]%' AND E.ValorDocumentoIdentidad LIKE '%' + @inFiltro + '%'
              )
          )
        ORDER BY E.Nombre ASC
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER;
        ;

        RETURN 0;
    END TRY
    BEGIN CATCH
        SET @outResultado = ERROR_NUMBER();

        RETURN @outResultado;
    END CATCH;
END;