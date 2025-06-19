CREATE OR ALTER PROCEDURE sp_ProcesarMarcasAsistencia
    @inXmlOperacion XML,
    @inFecha DATE,
    @outResultado INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Tabla variable para almacenar las marcas a procesar
        DECLARE @marcasProcesar TABLE (
            RowNum INT IDENTITY(1,1),
            ValorTipoDocumento VARCHAR(50),
            HoraEntrada DATETIME,
            HoraSalida DATETIME
        );
        
        -- Extraer datos del XML
        INSERT INTO @marcasProcesar (ValorTipoDocumento, HoraEntrada, HoraSalida)
        SELECT 
            t.f.value('@ValorTipoDocumento', 'VARCHAR(50)'),
            t.f.value('@HoraEntrada', 'DATETIME'),
            t.f.value('@HoraSalida', 'DATETIME')
        FROM @inXmlOperacion.nodes('//MarcasAsistencia/MarcaDeAsistencia') as t(f);
        
        -- Variables para procesamiento
        DECLARE @i INT = 1, @total INT = (SELECT COUNT(*) FROM @marcasProcesar);
        DECLARE @resultadoParcial INT = 0;
        
        WHILE @i <= @total AND @resultadoParcial = 0
        BEGIN
            DECLARE @valorDoc VARCHAR(50), @horaEntrada DATETIME, @horaSalida DATETIME;
            
            SELECT 
                @valorDoc = ValorTipoDocumento,
                @horaEntrada = HoraEntrada,
                @horaSalida = HoraSalida
            FROM @marcasProcesar
            WHERE RowNum = @i;
            
            BEGIN TRANSACTION;
            
            -- Obtener empleado y semana de planilla actual
            DECLARE @idEmpleado INT, @idSemanaPlanilla INT, @idPlanillaSemXEmpleado INT;
            
            SELECT @idEmpleado = id 
            FROM dbo.Empleado 
            WHERE ValorDocumentoIdentidad = @valorDoc AND Activo = 1;
            
            IF @idEmpleado IS NULL
            BEGIN
                SET @resultadoParcial = 50002; -- Empleado no encontrado
                THROW @resultadoParcial, 'Empleado no encontrado', 1;
                END
            ELSE
            BEGIN
                -- Obtener semana de planilla actual
                SELECT @idSemanaPlanilla = SP.id
                FROM dbo.SemanaPlanilla AS SP
                JOIN dbo.MesPlanilla AS MP ON SP.idMesPlanilla = MP.id
                WHERE @inFecha BETWEEN SP.FechaInicio AND SP.FechaFin
                AND MP.Cerrado = 0;
                
                IF @idSemanaPlanilla IS NULL
                BEGIN
                    SET @resultadoParcial = 50003; -- Semana de planilla no encontrada
                    THROW @resultadoParcial, 'Semana planilla no encontrada', 1;
                    END
                ELSE
                BEGIN
                    -- Obtener o crear planilla semanal del empleado
                    SELECT @idPlanillaSemXEmpleado = id
                    FROM dbo.PlanillaSemXEmpleado
                    WHERE idSemanaPlanilla = @idSemanaPlanilla 
                        AND idEmpleado = @idEmpleado;
                    
                    IF @idPlanillaSemXEmpleado IS NULL
                    BEGIN
                        INSERT INTO dbo.PlanillaSemXEmpleado (
                            idSemanaPlanilla
                            , idEmpleado
                            , SalarioBruto
                            , TotalDeducciones
                            , SalarioNeto
                            )
                        VALUES (
                            @idSemanaPlanilla
                            , @idEmpleado
                            , 0
                            , 0
                            , 0
                            );
                        
                        SET @idPlanillaSemXEmpleado = SCOPE_IDENTITY();
                    END
                    
                    -- Insertar asistencia
                    INSERT INTO dbo.Asistencia (
                        idEmpleado
                        , Fecha
                        , HoraEntrada
                        , HoraSalida
                        , Procesado
                        )
                    VALUES (
                        @idEmpleado
                        , @inFecha
                        , @horaEntrada
                        , @horaSalida
                        , 0
                        );
                    
                    DECLARE @idAsistencia INT = SCOPE_IDENTITY();
                    
                    -- Procesar horas trabajadas
                    EXEC sp_ProcesarHorasTrabajadas 
                        @idEmpleado, 
                        @idPlanillaSemXEmpleado, 
                        @idAsistencia, 
                        @horaEntrada, 
                        @horaSalida, 
                        @inFecha,
                        @outResultado = @resultadoParcial OUTPUT;
                END
            END
            
            IF @resultadoParcial = 0
                COMMIT TRANSACTION;
            ELSE
                ROLLBACK TRANSACTION;
            IF @resultadoParcial = 0
            BEGIN 
                DECLARE @idTipoEvento INT;                
                SELECT @idTipoEvento = id FROM dbo.TipoEvento WHERE Nombre = 'Ingreso de marcas de asistencia';

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
                            '"idEmpleado":"', CAST(@idEmpleado AS VARCHAR), '",',
                            '"SemanaPlanilla":"', @idSemanaPlanilla, '",',
                            '"SemPlanillaXEmpleado":"', @idPlanillaSemXEmpleado, '",',
                            '"HoraEntrada":"', FORMAT(@horaEntrada, 'HH:mm:ss'), '",',
                            '"HoraSalida":"', FORMAT(@horaSalida, 'HH:mm:ss'), '",',
                            '"Fecha":"', FORMAT(@inFecha, 'yyyy-MM-dd'), '"',
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
            SET @outResultado = COALESCE(ERROR_NUMBER(), 50004);
        
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