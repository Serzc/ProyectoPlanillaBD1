CREATE OR ALTER PROCEDURE sp_ProcesarAsociacionEmpleadoDeducciones
    @inXmlOperacion XML,
    @inFecha DATE,
    @outResultado INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Tabla variable para almacenar las asociaciones a procesar
        DECLARE @asociacionesProcesar TABLE (
            RowNum INT IDENTITY(1,1),
            IdTipoDeduccion INT,
            ValorTipoDocumento VARCHAR(50),
            Monto DECIMAL(10,2)
        );
        
        -- Extraer datos del XML
        INSERT INTO @asociacionesProcesar (IdTipoDeduccion, ValorTipoDocumento, Monto)
        SELECT 
            t.f.value('@IdTipoDeduccion', 'INT'),
            t.f.value('@ValorTipoDocumento', 'VARCHAR(50)'),
            t.f.value('@Monto', 'DECIMAL(10,2)')
        FROM @inXmlOperacion.nodes('//AsociacionEmpleadoDeducciones/AsociacionEmpleadoConDeduccion') as t(f);
        
        -- Variables para procesamiento
        DECLARE @i INT = 1, @total INT = (SELECT COUNT(*) FROM @asociacionesProcesar);
        DECLARE @resultadoParcial INT = 0;
        
        WHILE @i <= @total AND @resultadoParcial = 0
        BEGIN
            DECLARE @idTipoDeduccion INT, @valorDoc VARCHAR(50), @monto DECIMAL(10,2);
            
            SELECT 
                @idTipoDeduccion = IdTipoDeduccion,
                @valorDoc = ValorTipoDocumento,
                @monto = Monto
            FROM @asociacionesProcesar
            WHERE RowNum = @i;
            
            BEGIN TRANSACTION;
            
            -- Obtener empleado
            DECLARE @idEmpleado INT;
            
            SELECT @idEmpleado = id 
            FROM Empleado 
            WHERE ValorDocumentoIdentidad = @valorDoc AND Activo = 1;
            
            IF @idEmpleado IS NULL
            BEGIN
                SET @resultadoParcial = 50008; -- Empleado no encontrado
                THROW @resultadoParcial, 'Empleado no encontrado', 1;
            END
            ELSE
            BEGIN
                -- Verificar que la deducción no sea obligatoria
                DECLARE @esObligatoria BIT;
                
                SELECT @esObligatoria = Obligatorio
                FROM TipoDeduccion
                WHERE id = @idTipoDeduccion;
                
                IF @esObligatoria = 1
                BEGIN
                    SET @resultadoParcial = 50009; -- No se puede asociar deducción obligatoria manualmente
                    INSERT INTO TipoError (id, Descripcion)
                    VALUES (@resultadoParcial, 'Intento de asociar deducción obligatoria manualmente');
                END
                ELSE
                BEGIN
                    -- Verificar si ya existe una asociación activa
                    IF EXISTS (
                        SELECT 1 
                        FROM EmpleadoDeduccion 
                        WHERE idEmpleado = @idEmpleado 
                          AND idTipoDeduccion = @idTipoDeduccion
                          AND FechaDesasociacion IS NULL
                    )
                    BEGIN
                        -- Actualizar asociación existente
                        UPDATE EmpleadoDeduccion
                        SET 
                            ValorFijo = CASE 
                                WHEN (SELECT Porcentual FROM TipoDeduccion WHERE id = @idTipoDeduccion) = 0 
                                THEN @monto 
                                ELSE NULL 
                            END,
                            ValorPorcentual = CASE 
                                WHEN (SELECT Porcentual FROM TipoDeduccion WHERE id = @idTipoDeduccion) = 1 
                                THEN @monto 
                                ELSE NULL 
                            END
                        WHERE idEmpleado = @idEmpleado 
                          AND idTipoDeduccion = @idTipoDeduccion
                          AND FechaDesasociacion IS NULL;
                    END
                    ELSE
                    BEGIN
                        -- Insertar nueva asociación
                        INSERT INTO EmpleadoDeduccion (
                            idEmpleado,
                            idTipoDeduccion,
                            ValorPorcentual,
                            ValorFijo,
                            FechaAsociacion
                        )
                        SELECT 
                            @idEmpleado,
                            @idTipoDeduccion,
                            CASE WHEN td.Porcentual = 1 THEN @monto ELSE NULL END,
                            CASE WHEN td.Porcentual = 0 THEN @monto ELSE NULL END,
                            @inFecha
                        FROM TipoDeduccion td
                        WHERE td.id = @idTipoDeduccion;
                    END
                END
            END
            
            IF @resultadoParcial = 0
                COMMIT TRANSACTION;
            ELSE
                ROLLBACK TRANSACTION;
                
            SET @i = @i + 1;
        END
        
        SET @outResultado = @resultadoParcial;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        IF @outResultado = 0
            SET @outResultado = COALESCE(ERROR_NUMBER(), 50010);
        
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