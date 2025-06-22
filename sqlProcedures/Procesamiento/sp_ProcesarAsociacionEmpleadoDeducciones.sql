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
            Monto DECIMAL(25,5)
        );
        
        -- Extraer datos del XML
        INSERT INTO @asociacionesProcesar (IdTipoDeduccion, ValorTipoDocumento, Monto)
        SELECT 
            t.f.value('@IdTipoDeduccion', 'INT'),
            t.f.value('@ValorTipoDocumento', 'VARCHAR(50)'),
            t.f.value('@Monto', 'DECIMAL(25,5)')
        FROM @inXmlOperacion.nodes('//AsociacionEmpleadoDeducciones/AsociacionEmpleadoConDeduccion') as t(f);
        
        -- Variables para procesamiento
        DECLARE @i INT = 1, @total INT = (SELECT COUNT(*) FROM @asociacionesProcesar);
        DECLARE @resultadoParcial INT = 0;
        
        WHILE @i <= @total AND @resultadoParcial = 0
        BEGIN
            DECLARE @idTipoDeduccion INT, @valorDoc VARCHAR(50), @monto DECIMAL(25,5);
            
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
            FROM dbo.Empleado 
            WHERE ValorDocumentoIdentidad = @valorDoc AND Activo = 1;
            
            IF @idEmpleado IS NULL
            BEGIN
                SET @resultadoParcial = 50008; -- Error en la base de datos
                THROW @resultadoParcial, 'Empleado no encontrado', 1;
            END
            ELSE
            BEGIN
                -- Verificar que la deducción no sea obligatoria
                DECLARE @esObligatoria BIT;
                
                SELECT @esObligatoria = Obligatorio
                FROM dbo.TipoDeduccion
                WHERE id = @idTipoDeduccion;
                
                IF @esObligatoria = 1
                BEGIN
                    SET @resultadoParcial = 50008; -- Error en la base de datos
                    THROW @resultadoParcial, 'Intento de asociar deducción obligatoria manualmente', 1;
                    
                END
                ELSE
                BEGIN
                    -- Verificar si ya existe una asociación activa
                    IF EXISTS (
                        SELECT 1 
                        FROM dbo.EmpleadoDeduccion 
                        WHERE idEmpleado = @idEmpleado 
                          AND idTipoDeduccion = @idTipoDeduccion
                          AND FechaDesasociacion IS NULL
                    )
                    BEGIN
                        -- Actualizar asociación existente
                        UPDATE dbo.EmpleadoDeduccion
                        SET 
                            ValorFijo = CASE 
                                WHEN (SELECT Porcentual 
                                        FROM dbo.TipoDeduccion 
                                        WHERE id = @idTipoDeduccion) = 0 
                                THEN @monto 
                                ELSE NULL 
                            END,
                            ValorPorcentual = CASE 
                                WHEN (SELECT Porcentual 
                                        FROM dbo.TipoDeduccion 
                                        WHERE id = @idTipoDeduccion) = 1 
                                THEN (SELECT Valor 
                                        FROM dbo.TipoDeduccion 
                                        WHERE id = @idTipoDeduccion) 
                                ELSE NULL 
                            END
                        WHERE idEmpleado = @idEmpleado 
                          AND idTipoDeduccion = @idTipoDeduccion
                          AND FechaDesasociacion IS NULL;
                    END
                    ELSE
                    BEGIN
                        -- Insertar nueva asociación
                        INSERT INTO dbo.EmpleadoDeduccion (
                            idEmpleado,
                            idTipoDeduccion,
                            ValorPorcentual,
                            ValorFijo,
                            FechaAsociacion
                        )
                        SELECT 
                            @idEmpleado,
                            @idTipoDeduccion,
                            CASE WHEN TD.Porcentual = 1 THEN (SELECT Valor 
                                                    FROM dbo.TipoDeduccion 
                                                    WHERE id = @idTipoDeduccion)  
                                                    ELSE NULL END,
                            CASE WHEN TD.Porcentual = 0 THEN @monto ELSE NULL END,
                            @inFecha
                        FROM dbo.TipoDeduccion TD
                        WHERE TD.id = @idTipoDeduccion;
                    END
                    IF (
                        (SELECT Porcentual FROM dbo.TipoDeduccion WHERE id = @idTipoDeduccion) = 1
                        AND
                        (SELECT ValorPorcentual FROM dbo.EmpleadoDeduccion 
                            WHERE idEmpleado = @idEmpleado 
                              AND idTipoDeduccion = @idTipoDeduccion 
                              AND FechaDesasociacion IS NULL) = 0
                    )
                    BEGIN
                        SET @resultadoParcial = 50008; -- Error en la base de datos 
                        DECLARE @errMsg NVARCHAR(200);
                        SET @errMsg = 'Asociado Empleado con porcentaje 0: ' + CAST(@idEmpleado AS NVARCHAR) + ' con tipo deducción ' + CAST(@idTipoDeduccion AS NVARCHAR);
                        THROW @resultadoParcial, @errMsg, 1;
                    
                    END
                END
            END
            
            IF @resultadoParcial = 0
                COMMIT TRANSACTION;
            ELSE
                ROLLBACK TRANSACTION;

            -- Registrar en EventLog si el procedimiento fue exitoso para esta deducción
            IF @resultadoParcial = 0
            BEGIN
                DECLARE @idTipoEvento INT;
                SELECT @idTipoEvento = id FROM dbo.TipoEvento WHERE Nombre = 'Asociar Deducción';

                INSERT INTO dbo.EventLog (
                    FechaHora,
                    idUsuario,
                    idTipoEvento,
                    Parametros
                )
                VALUES (
                    @inFecha,
                    (SELECT id FROM dbo.Usuario WHERE Tipo = 3),
                    @idTipoEvento,
                    JSON_QUERY(CONCAT(
                        '{',
                            '"idEmpleado":"', COALESCE(CAST(@idEmpleado AS VARCHAR), 'null'), '",',
                            '"idDeduccion":"', COALESCE(CAST(@idTipoDeduccion AS VARCHAR), 'null'), '",',
                            '"ValorFijo":"', 
                                (SELECT TOP 1 
                                    CASE WHEN ValorFijo IS NULL THEN 'null' ELSE CAST(ValorFijo AS VARCHAR) END 
                                FROM dbo.EmpleadoDeduccion 
                                WHERE idEmpleado = @idEmpleado 
                                AND idTipoDeduccion = @idTipoDeduccion 
                                AND FechaDesasociacion IS NULL
                                ORDER BY FechaAsociacion DESC), '",',
                            '"ValorPorcentual":"', 
                                (SELECT TOP 1 
                                    CASE WHEN ValorPorcentual IS NULL THEN 'null' ELSE CAST(ValorPorcentual AS VARCHAR) END 
                                FROM dbo.EmpleadoDeduccion 
                                WHERE idEmpleado = @idEmpleado 
                                AND idTipoDeduccion = @idTipoDeduccion 
                                AND FechaDesasociacion IS NULL
                                ORDER BY FechaAsociacion DESC), '",',
                            '"FechaAsociacion":"', FORMAT(@inFecha, 'yyyy-MM-dd'), '"',
                        '}'
                    ))
                );
            END

            SET @i = @i + 1;
        END
        
        SET @outResultado = @resultadoParcial;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
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