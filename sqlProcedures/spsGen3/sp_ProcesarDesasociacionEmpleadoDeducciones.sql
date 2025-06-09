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
            FROM Empleado 
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
                FROM TipoDeduccion
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
                        FROM EmpleadoDeduccion 
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
                        UPDATE EmpleadoDeduccion
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