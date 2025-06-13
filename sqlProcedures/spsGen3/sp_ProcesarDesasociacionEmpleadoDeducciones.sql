CREATE OR ALTER PROCEDURE sp_ProcesarDesasociacionEmpleadoDeducciones
    @inXmlOperacion XML,
    @inFecha DATE,
    @outResultado INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Tabla variable para almacenar las desasociaciones a procesar
        DECLARE @desasociacionesProcesar TABLE (
            RowNum INT IDENTITY(1,1),
            IdTipoDeduccion INT,
            ValorTipoDocumento VARCHAR(50)
        );
        
        -- Extraer datos del XML
        INSERT INTO @desasociacionesProcesar (IdTipoDeduccion, ValorTipoDocumento)
        SELECT 
            t.f.value('@IdTipoDeduccion', 'INT'),
            t.f.value('@ValorTipoDocumento', 'VARCHAR(50)')
        FROM @inXmlOperacion.nodes('//DesasociacionEmpleadoDeducciones/DesasociacionEmpleadoConDeduccion') as t(f);
        
        -- Variables para procesamiento
        DECLARE @i INT = 1, @total INT = (SELECT COUNT(*) FROM @desasociacionesProcesar);
        DECLARE @resultadoParcial INT = 0;
        
        WHILE @i <= @total AND @resultadoParcial = 0
        BEGIN
            DECLARE @idTipoDeduccion INT, @valorDoc VARCHAR(50);
            
            SELECT 
                @idTipoDeduccion = IdTipoDeduccion,
                @valorDoc = ValorTipoDocumento
            FROM @desasociacionesProcesar
            WHERE RowNum = @i;
            
            BEGIN TRANSACTION;
            
            -- Obtener empleado
            DECLARE @idEmpleado INT;
            
            SELECT @idEmpleado = id 
            FROM dbo.Empleado 
            WHERE ValorDocumentoIdentidad = @valorDoc AND Activo = 1;
            
            IF @idEmpleado IS NULL
            BEGIN
                SET @resultadoParcial = 50011; -- Empleado no encontrado
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
                    SET @resultadoParcial = 50012; -- No se puede desasociar deducción obligatoria
                    THROW @resultadoParcial, 'No se puede desasociar deducción obligatoria', 1;
                    END
                ELSE
                BEGIN
                    -- Verificar si existe una asociación activa
                    IF NOT EXISTS (
                        SELECT 1 
                        FROM dbo.EmpleadoDeduccion 
                        WHERE idEmpleado = @idEmpleado 
                          AND idTipoDeduccion = @idTipoDeduccion
                          AND FechaDesasociacion IS NULL
                    )
                    BEGIN
                        SET @resultadoParcial = 50013; -- Asociación no encontrada
                        THROW @resultadoParcial, 'Asociacion no encontrada', 1;
                        END
                    ELSE
                    BEGIN
                        -- Desasociar (marcar con fecha de desasociación)
                        UPDATE dbo.EmpleadoDeduccion
                        SET FechaDesasociacion = @inFecha
                        WHERE idEmpleado = @idEmpleado
                          AND idTipoDeduccion = @idTipoDeduccion
                          AND FechaDesasociacion IS NULL;
                    END
                END
            END
            
            IF @resultadoParcial = 0
                COMMIT TRANSACTION;
            ELSE
                ROLLBACK TRANSACTION;
            IF @resultadoParcial = 0
            BEGIN
                DECLARE @idTipoEvento INT;
                SELECT @idTipoEvento = id FROM dbo.TipoEvento WHERE Nombre = 'Desasociar deducción';

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
                            '"FechaDeasociacion":"', FORMAT(@inFecha, 'yyyy-MM-dd'), '"',
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
            SET @outResultado = COALESCE(ERROR_NUMBER(), 50014);
        
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