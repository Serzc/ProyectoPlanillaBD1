CREATE OR ALTER PROCEDURE sp_ProcesarNuevosEmpleados
    @inXmlOperacion XML,
    @inFecha DATE,
    @outResultado INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Tabla variable para almacenar los nuevos empleados
        DECLARE @nuevosEmpleados TABLE (
            RowNum INT IDENTITY(1,1),
            Nombre VARCHAR(100),
            IdTipoDocumento INT,
            ValorTipoDocumento VARCHAR(50),
            IdDepartamento INT,
            NombrePuesto VARCHAR(100),
            Usuario VARCHAR(50),
            Password VARCHAR(100)
        );
        
        -- Extraer datos del XML
        INSERT INTO @nuevosEmpleados (Nombre, IdTipoDocumento, ValorTipoDocumento, IdDepartamento, NombrePuesto, Usuario, Password)
        SELECT 
            t.f.value('@Nombre', 'VARCHAR(100)'),
            t.f.value('@IdTipoDocumento', 'INT'),
            t.f.value('@ValorTipoDocumento', 'VARCHAR(50)'),
            t.f.value('@IdDepartamento', 'INT'),
            t.f.value('@NombrePuesto', 'VARCHAR(100)'),
            t.f.value('@Usuario', 'VARCHAR(50)'),
            t.f.value('@Password', 'VARCHAR(100)')
        FROM @inXmlOperacion.nodes('//NuevosEmpleados/NuevoEmpleado') as t(f);
        
        -- Variables para procesamiento
        DECLARE @i INT = 1, @total INT = (SELECT COUNT(*) FROM @nuevosEmpleados);
        DECLARE @resultadoParcial INT = 0;
        
        -- Procesar cada empleado con enfoque basado en conjuntos
        WHILE @i <= @total AND @resultadoParcial = 0
        BEGIN
            DECLARE @nombre VARCHAR(100), @idTipoDoc INT, @valorDoc VARCHAR(50), @idDepto INT;
            DECLARE @nombrePuesto VARCHAR(100), @usuario VARCHAR(50), @password VARCHAR(100);
            
            SELECT 
                @nombre = Nombre,
                @idTipoDoc = IdTipoDocumento,
                @valorDoc = ValorTipoDocumento,
                @idDepto = IdDepartamento,
                @nombrePuesto = NombrePuesto,
                @usuario = Usuario,
                @password = Password
            FROM @nuevosEmpleados
            WHERE RowNum = @i;
            
            DECLARE @usuarioSistemaId INT;
            SELECT TOP 1 @usuarioSistemaId = id FROM dbo.Usuario WHERE Tipo = 3; -- Usuario del sistema

            EXEC sp_InsertarEmpleado 
                @nombre, 
                @idTipoDoc, 
                @valorDoc, 
                @idDepto, 
                @nombrePuesto, 
                @usuario, 
                @password,
                @inFecha,
                NULL, -- no hay fecha de nacimiento en xml
                @usuarioSistemaId, 
                @outResultado = @resultadoParcial OUTPUT;
                
            SET @i = @i + 1;
        END
        
        SET @outResultado = @resultadoParcial;
    END TRY
    BEGIN CATCH
        IF @outResultado = 0
            SET @outResultado = COALESCE(ERROR_NUMBER(), 50008); -- Error en la base de datos
        
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