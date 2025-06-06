CREATE OR ALTER PROCEDURE sp_ProcesarNuevosEmpleados
    @inXmlData XML,
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @outResultCode = 0;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Tabla temporal para nuevos empleados
        DECLARE @NuevosEmpleados TABLE (
            Nombre VARCHAR(100),
            idTipoDocumento INT,
            ValorDocumentoIdentidad VARCHAR(50),
            idDepartamento INT,
            NombrePuesto VARCHAR(100),
            Username VARCHAR(50),
            Password VARCHAR(100)
        );
        
        -- Extraer datos del XML
        INSERT INTO @NuevosEmpleados (
            Nombre,
            idTipoDocumento,
            ValorDocumentoIdentidad,
            idDepartamento,
            NombrePuesto,
            Username,
            Password
        )
        SELECT
            emp.value('@Nombre', 'VARCHAR(100)'),
            emp.value('@IdTipoDocumento', 'INT'),
            emp.value('@ValorTipoDocumento', 'VARCHAR(50)'),
            emp.value('@IdDepartamento', 'INT'),
            emp.value('@Puesto', 'VARCHAR(100)'),
            emp.value('@Usuario', 'VARCHAR(50)'),
            emp.value('@Password', 'VARCHAR(100)')
        FROM @inXmlData.nodes('/Operacion/FechaOperacion/NuevosEmpleados/NuevoEmpleado') AS T(emp);
        
        -- Insertar empleados
        INSERT INTO Empleado (
            Nombre,
            idTipoDocumento,
            ValorDocumentoIdentidad,
            FechaNacimiento,
            FechaContratacion,
            idPuesto,
            idDepartamento,
            Activo
        )
        SELECT
            ne.Nombre,
            ne.idTipoDocumento,
            ne.ValorDocumentoIdentidad,
            NULL, -- FechaNacimiento opcional
            GETDATE(), -- FechaContratacion
            p.id,
            ne.idDepartamento,
            1 -- Activo
        FROM @NuevosEmpleados ne
        JOIN Puesto p ON p.Nombre = ne.NombrePuesto
        WHERE NOT EXISTS (
            SELECT 1 FROM Empleado 
            WHERE ValorDocumentoIdentidad = ne.ValorDocumentoIdentidad
        );
        
        -- Crear usuarios para nuevos empleados
        INSERT INTO Usuario (
            Username,
            Password,
            Tipo,
            idEmpleado
        )
        SELECT
            ne.Username,
            ne.Password,
            2, -- Tipo empleado
            e.id
        FROM @NuevosEmpleados ne
        JOIN Empleado e ON e.ValorDocumentoIdentidad = ne.ValorDocumentoIdentidad
        WHERE NOT EXISTS (
            SELECT 1 FROM Usuario 
            WHERE Username = ne.Username
        );
        
        COMMIT TRANSACTION;
        
        -- Retornar conteo de empleados insertados
        SELECT COUNT(*) AS EmpleadosInsertados
        FROM @NuevosEmpleados ne
        JOIN Empleado e ON e.ValorDocumentoIdentidad = ne.ValorDocumentoIdentidad;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        SET @outResultCode = 50010 + ERROR_NUMBER();
        -- Error 50010+: Error al procesar nuevos empleados
        THROW;
    END CATCH;
END;