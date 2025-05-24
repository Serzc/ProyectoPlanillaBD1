USE [proyectoBD1]
GO
/****** Object:  StoredProcedure [dbo].[sp_ObtenerEmpleadosActivos]    Script Date: 5/23/2025 7:39:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_ObtenerEmpleadosActivos]
    @outResultado INT OUTPUT
AS
BEGIN
    BEGIN TRY
        SET @outResultado = 0; -- Éxito
        
        SELECT 
            e.Id,
            e.Nombre,
            e.ValorDocumentoIdentidad,
            e.Activo,
            p.Id AS PuestoId,
            p.Nombre AS PuestoNombre,
            p.SalarioXHora
        FROM 
            Empleado e
        INNER JOIN 
            Puesto p ON e.PuestoId = p.Id
        WHERE 
            e.Activo = 1
        ORDER BY 
            e.Nombre;
            
    END TRY
    BEGIN CATCH
        SET @outResultado = 50000 + ERROR_NUMBER();
    END CATCH
END