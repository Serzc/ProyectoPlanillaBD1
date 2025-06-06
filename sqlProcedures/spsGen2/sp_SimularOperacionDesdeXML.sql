CREATE OR ALTER PROCEDURE sp_SimularOperacionDesdeXML
    @inXmlOperacion XML,
    @outResultado INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @resultadoParcial INT = 0;
    
    BEGIN TRY
    --DIVIDIR LAS FECHAS================================================================
        -- Declarar tabla variable para fechas de operación
        DECLARE @FechasOperacion TABLE (
            Fecha DATE,
            Orden INT IDENTITY(1,1)
        );
        
        -- Insertar fechas únicas en orden
        INSERT INTO @FechasOperacion (Fecha)
        SELECT DISTINCT
            t.f.value('@Fecha', 'DATE')
        FROM @inXmlOperacion.nodes('/Operacion/FechaOperacion') as t(f);
        
        -- Procesar cada fecha en orden
        DECLARE @i INT = 1, @total INT = (SELECT COUNT(*) FROM @FechasOperacion);
       -- FECHAS PROCESADAS UNA POR UNA======================================================== 
        WHILE @i <= @total AND @resultadoParcial = 0
        BEGIN
            DECLARE @fechaOperacion DATE;
            SELECT @fechaOperacion = Fecha FROM @FechasOperacion WHERE Orden = @i;
            
            -- Obtener el XML para esta fecha específica
            DECLARE @xmlFecha XML = @inXmlOperacion.query('/Operacion/FechaOperacion[@Fecha=sql:variable("@fechaOperacion")]');
            
--START INSERTAR NUEVOS EMPLEADOS========================================================
            BEGIN TRANSACTION;
            -- Tabla variable para nuevos empleados
            DECLARE @NuevosEmpleados TABLE (
                Nombre VARCHAR(100),
                IdTipoDocumento INT,
                ValorDocumento VARCHAR(50),
                IdDepartamento INT,
                NombrePuesto VARCHAR(100),
                IdUsuario INT,
                IdPuesto INT NULL
            );
            
            -- Insertar datos de nuevos empleados
            INSERT INTO @NuevosEmpleados (Nombre, IdTipoDocumento, ValorDocumento, IdDepartamento, NombrePuesto, IdUsuario)
            SELECT
                t.f.value('@Nombre', 'VARCHAR(100)'),
                t.f.value('@IdTipoDocumento', 'INT'),
                t.f.value('@ValorTipoDocumento', 'VARCHAR(50)'),
                t.f.value('@IdDepartamento', 'INT'),
                t.f.value('@NombrePuesto', 'VARCHAR(100)'),
                t.f.value('@IdUsuario', 'INT')
            FROM @xmlFecha.nodes('/FechaOperacion/NuevosEmpleados/NuevoEmpleado') as t(f);
            
            -- Actualizar con IDs de puesto
            UPDATE ne
            SET IdPuesto = p.id
            FROM @NuevosEmpleados ne
            JOIN Puesto p ON p.Nombre = ne.NombrePuesto;
            
            -- Verificar puestos no encontrados
            IF EXISTS (SELECT 1 FROM @NuevosEmpleados WHERE IdPuesto IS NULL)
            BEGIN
                SET @resultadoParcial = 50006; -- Puesto no encontrado
                -- Registrar error en bitácora
                INSERT INTO EventLog (idTipoEvento, Parametros)
                SELECT 
                    5, -- Insertar empleado
                    JSON_MODIFY(JSON_MODIFY('{}', '$.Error', 'Puesto no encontrado'), '$.NombrePuesto', NombrePuesto)
                FROM @NuevosEmpleados
                WHERE IdPuesto IS NULL;
            END
            
            -- Insertar empleados válidos
            IF @resultadoParcial = 0 AND EXISTS (SELECT 1 FROM @NuevosEmpleados WHERE IdPuesto IS NOT NULL)
            BEGIN
                INSERT INTO Empleado (Nombre, idTipoDocumento, ValorDocumentoIdentidad, FechaContratacion, idPuesto, idDepartamento)
                SELECT 
                    Nombre,
                    IdTipoDocumento,
                    ValorDocumento,
                    @fechaOperacion,
                    IdPuesto,
                    IdDepartamento
                FROM @NuevosEmpleados
                WHERE IdPuesto IS NOT NULL;
                
                -- Registrar en bitácora
                INSERT INTO EventLog (idTipoEvento, Parametros)
                SELECT 
                    5, -- Insertar empleado
                    JSON_MODIFY(JSON_MODIFY(JSON_MODIFY(JSON_MODIFY(JSON_MODIFY(
                        '{}',
                        '$.Nombre', Nombre),
                        '$.TipoDocumento', IdTipoDocumento),
                        '$.ValorDocumento', ValorDocumento),
                        '$.Puesto', IdPuesto),
                        '$.Departamento', IdDepartamento)
                FROM @NuevosEmpleados
                WHERE IdPuesto IS NOT NULL;
            END -- END INSERTAR NUEVOS EMPLEADOS========================================================
            COMMIT
--START JORNADAS PROXIMA SEMANA========================================================
            -- Procesar jornadas para próxima semana (solo si es jueves)
            BEGIN TRANSACTION
            IF DATEPART(WEEKDAY, @fechaOperacion) = 5 AND @resultadoParcial = 0 -- Jueves
            BEGIN
                -- Tabla variable para jornadas
                DECLARE @JornadasProximaSemana TABLE (
                    ValorTipoDocumento VARCHAR(50),
                    IdTipoJornada INT,
                    IdEmpleado INT NULL
                );
                
                -- Insertar datos de jornadas
                INSERT INTO @JornadasProximaSemana (ValorTipoDocumento, IdTipoJornada)
                SELECT
                    t.f.value('@ValorTipoDocumento', 'VARCHAR(50)'),
                    t.f.value('@IdTipoJornada', 'INT')
                FROM @xmlFecha.nodes('/FechaOperacion/JornadasProximaSemana/TipoJornadaProximaSemana') as t(f);
                
                -- Actualizar con IDs de empleado
                UPDATE j
                SET IdEmpleado = e.id
                FROM @JornadasProximaSemana j
                JOIN Empleado e ON e.ValorDocumentoIdentidad = j.ValorTipoDocumento
                WHERE e.Activo = 1;
                
                -- Insertar jornadas válidas
                INSERT INTO JornadaEmpleado (idEmpleado, idTipoJornada, FechaInicio, FechaFin)
                SELECT 
                    IdEmpleado,
                    IdTipoJornada,
                    DATEADD(DAY, 1, @fechaOperacion), -- Viernes
                    DATEADD(DAY, 7, @fechaOperacion)  -- Siguiente jueves
                FROM @JornadasProximaSemana
                WHERE IdEmpleado IS NOT NULL;
                
                -- Registrar en bitácora
                INSERT INTO EventLog (idTipoEvento, Parametros)
                SELECT 
                    15, -- Ingreso nuevas jornadas
                    JSON_MODIFY(JSON_MODIFY(JSON_MODIFY('{}',
                        '$.Empleado', IdEmpleado),
                        '$.TipoJornada', IdTipoJornada),
                        '$.Semana', CONVERT(VARCHAR, DATEADD(DAY, 1, @fechaOperacion), 120) + ' a ' + 
                                   CONVERT(VARCHAR, DATEADD(DAY, 7, @fechaOperacion), 120))
                FROM @JornadasProximaSemana
                WHERE IdEmpleado IS NOT NULL;
                COMMIT;
            END -- END JORNADAS PROXIMA SEMANA========================================================
            
            -- Procesar marcas de asistencia
            IF @resultadoParcial = 0

    --START MARCAS DE ASISTENCIA========================================================
            BEGIN
                BEGIN TRANSACTION;
                -- Tabla variable para asistencias
                DECLARE @MarcasAsistencia TABLE (
                    ValorTipoDocumento VARCHAR(50),
                    HoraEntrada DATETIME,
                    HoraSalida DATETIME,
                    IdEmpleado INT NULL
                );
                
                -- Insertar datos de asistencias
                INSERT INTO @MarcasAsistencia (ValorTipoDocumento, HoraEntrada, HoraSalida)
                SELECT
                    t.f.value('@ValorTipoDocumento', 'VARCHAR(50)'),
                    t.f.value('@HoraEntrada', 'DATETIME'),
                    t.f.value('@HoraSalida', 'DATETIME')
                FROM @xmlFecha.nodes('/FechaOperacion/MarcasAsistencia/MarcaDeAsistencia') as t(f);
                
                -- Actualizar con IDs de empleado
                UPDATE ma
                SET IdEmpleado = e.id
                FROM @MarcasAsistencia ma
                JOIN Empleado e ON e.ValorDocumentoIdentidad = ma.ValorTipoDocumento
                WHERE e.Activo = 1;
                
                -- Insertar asistencias válidas (solo una vez, como no procesadas)
                INSERT INTO Asistencia (idEmpleado, Fecha, HoraEntrada, HoraSalida, Procesado)
                SELECT 
                    IdEmpleado,
                    CAST(HoraEntrada AS DATE),
                    HoraEntrada,
                    HoraSalida,
                    0 -- No procesado aún
                FROM @MarcasAsistencia
                WHERE IdEmpleado IS NOT NULL;

                -- Procesar cada asistencia
                DECLARE @ValorTipoDocumento VARCHAR(50), @HoraEntrada DATETIME, @HoraSalida DATETIME;

                SELECT TOP 1 
                    @ValorTipoDocumento = ValorTipoDocumento,
                    @HoraEntrada = HoraEntrada,
                    @HoraSalida = HoraSalida
                FROM @MarcasAsistencia
                WHERE IdEmpleado IS NOT NULL;

                WHILE @@ROWCOUNT > 0 AND @resultadoParcial = 0
                BEGIN
                    EXEC sp_ProcesarAsistencia
                        @inValorTipoDocumento = @ValorTipoDocumento,
                        @inHoraEntrada = @HoraEntrada,
                        @inHoraSalida = @HoraSalida,
                        @outResultado = @resultadoParcial OUTPUT;

                    IF @resultadoParcial = 0
                    BEGIN
                        DELETE FROM @MarcasAsistencia 
                        WHERE ValorTipoDocumento = @ValorTipoDocumento 
                        AND HoraEntrada = @HoraEntrada 
                        AND HoraSalida = @HoraSalida;

                        SELECT TOP 1 
                            @ValorTipoDocumento = ValorTipoDocumento,
                            @HoraEntrada = HoraEntrada,
                            @HoraSalida = HoraSalida
                        FROM @MarcasAsistencia
                        WHERE IdEmpleado IS NOT NULL;
                    END
                END
                COMMIT
            END --END MARCAS DE ASISTENCIA========================================================
            
            -- Procesar asociaciones de deducciones
            IF @resultadoParcial = 0
            --START ASOCIACIONES DE DEDUCCIONES========================================================
            BEGIN
                -- Tabla variable para asociaciones
                DECLARE @Asociaciones TABLE (
                    IdTipoDeduccion INT,
                    ValorTipoDocumento VARCHAR(50),
                    Monto DECIMAL(10,2),
                    IdEmpleado INT NULL,
                    EsObligatoria BIT NULL
                );
                
                -- Insertar datos de asociaciones
                INSERT INTO @Asociaciones (IdTipoDeduccion, ValorTipoDocumento, Monto)
                SELECT
                    t.f.value('@IdTipoDeduccion', 'INT'),
                    t.f.value('@ValorTipoDocumento', 'VARCHAR(50)'),
                    t.f.value('@Monto', 'DECIMAL(10,2)')
                FROM @xmlFecha.nodes('/FechaOperacion/AsociacionEmpleadoDeducciones/AsociacionEmpleadoConDeduccion') as t(f);
                
                -- Actualizar con IDs de empleado y verificar si es obligatoria
                UPDATE a
                SET 
                    IdEmpleado = e.id,
                    EsObligatoria = CASE WHEN td.Obligatorio = 1 THEN 1 ELSE 0 END
                FROM @Asociaciones a
                LEFT JOIN Empleado e ON e.ValorDocumentoIdentidad = a.ValorTipoDocumento AND e.Activo = 1
                LEFT JOIN TipoDeduccion td ON td.id = a.IdTipoDeduccion;
                
                -- Verificar errores
                IF EXISTS (SELECT 1 FROM @Asociaciones WHERE IdEmpleado IS NULL)
                BEGIN
                    SET @resultadoParcial = 50001; -- Empleado no encontrado
                    -- Registrar error en bitácora
                    INSERT INTO EventLog (idTipoEvento, Parametros)
                    SELECT 
                        7, -- Asociar deducción
                        JSON_MODIFY(JSON_MODIFY('{}',
                            '$.Error', 'Empleado no encontrado'),
                            '$.ValorDocumento', ValorTipoDocumento)
                    FROM @Asociaciones
                    WHERE IdEmpleado IS NULL;
                END
                
                -- Verificar deducciones obligatorias
                IF @resultadoParcial = 0 AND EXISTS (SELECT 1 FROM @Asociaciones WHERE EsObligatoria = 1)
                BEGIN
                    SET @resultadoParcial = 50007; -- No se puede asociar deducción obligatoria manualmente
                    -- Registrar error en bitácora
                    INSERT INTO EventLog (idTipoEvento, Parametros)
                    SELECT 
                        7, -- Asociar deducción
                        JSON_MODIFY(JSON_MODIFY('{}',
                            '$.Error', 'Deducción obligatoria'),
                            '$.TipoDeduccion', IdTipoDeduccion)
                    FROM @Asociaciones
                    WHERE EsObligatoria = 1;
                END
                
                -- Procesar asociaciones válidas
                IF @resultadoParcial = 0 AND EXISTS (SELECT 1 FROM @Asociaciones WHERE IdEmpleado IS NOT NULL AND EsObligatoria = 0)
                BEGIN
                    BEGIN TRANSACTION;
                    
                    -- Desasociar primero si ya existe
                    UPDATE ed
                    SET FechaDesasociacion = @fechaOperacion
                    FROM EmpleadoDeduccion ed
                    JOIN @Asociaciones a ON a.IdEmpleado = ed.idEmpleado AND a.IdTipoDeduccion = ed.idTipoDeduccion
                    WHERE ed.FechaDesasociacion IS NULL;
                    
                    -- Asociar nuevas deducciones
                    INSERT INTO EmpleadoDeduccion (
                        idEmpleado,
                        idTipoDeduccion,
                        ValorPorcentual,
                        ValorFijo,
                        FechaAsociacion
                    )
                    SELECT
                        a.IdEmpleado,
                        a.IdTipoDeduccion,
                        CASE WHEN td.Porcentual = 1 THEN td.Valor ELSE NULL END,
                        CASE WHEN td.Porcentual = 0 THEN a.Monto ELSE NULL END,
                        @fechaOperacion
                    FROM @Asociaciones a
                    JOIN TipoDeduccion td ON td.id = a.IdTipoDeduccion
                    WHERE a.IdEmpleado IS NOT NULL 
                    AND a.EsObligatoria = 0;
                    
                    -- Registrar en bitácora
                    INSERT INTO EventLog (
                        idTipoEvento,
                        Parametros
                    )
                    SELECT 
                        7, -- Asociar deducción
                        JSON_MODIFY(JSON_MODIFY(JSON_MODIFY('{}',
                            '$.Empleado', IdEmpleado),
                            '$.TipoDeduccion', IdTipoDeduccion),
                            '$.Monto', Monto)
                    FROM @Asociaciones
                    WHERE IdEmpleado IS NOT NULL 
                    AND EsObligatoria = 0;
                    
                    COMMIT;
                END
            END --END ASOCIACIONES DE DEDUCCIONES========================================================
            
            -- Procesar desasociaciones de deducciones
            IF @resultadoParcial = 0
            --START DESASOCIACIONES DE DEDUCCIONES========================================================
            BEGIN 
                -- Tabla variable para desasociaciones
                DECLARE @Desasociaciones TABLE (
                    IdTipoDeduccion INT,
                    ValorTipoDocumento VARCHAR(50),
                    IdEmpleado INT NULL,
                    EsObligatoria BIT NULL
                );
                
                -- Insertar datos de desasociaciones
                INSERT INTO @Desasociaciones (IdTipoDeduccion, ValorTipoDocumento)
                SELECT
                    t.f.value('@IdTipoDeduccion', 'INT'),
                    t.f.value('@ValorTipoDocumento', 'VARCHAR(50)')
                FROM @xmlFecha.nodes('/FechaOperacion/DesasociacionEmpleadoDeducciones/DesasociacionEmpleadoConDeduccion') as t(f);
                
                -- Actualizar con IDs de empleado y verificar si es obligatoria
                UPDATE d
                SET 
                    IdEmpleado = e.id,
                    EsObligatoria = CASE WHEN td.Obligatorio = 1 THEN 1 ELSE 0 END
                FROM @Desasociaciones d
                LEFT JOIN Empleado e ON e.ValorDocumentoIdentidad = d.ValorTipoDocumento AND e.Activo = 1
                LEFT JOIN TipoDeduccion td ON td.id = d.IdTipoDeduccion;
                
                -- Verificar errores
                IF EXISTS (SELECT 1 FROM @Desasociaciones WHERE IdEmpleado IS NULL)
                BEGIN
                    SET @resultadoParcial = 50001; -- Empleado no encontrado
                    -- Registrar error en bitácora
                    INSERT INTO EventLog (idTipoEvento, Parametros)
                    SELECT 
                        te.id, -- Desasociar deducción
                        JSON_MODIFY(JSON_MODIFY('{}',
                            '$.Error', 'Empleado no encontrado'),
                            '$.ValorDocumento', ValorTipoDocumento)
                    FROM @Desasociaciones
                    JOIN TipoEvento te ON te.Nombre = "DesaAsociar deduccion" -- Desasociar deducción
                    WHERE IdEmpleado IS NULL;
                END
                
                -- Verificar deducciones obligatorias
                IF @resultadoParcial = 0 AND EXISTS (SELECT 1 FROM @Desasociaciones WHERE EsObligatoria = 1)
                BEGIN
                    SET @resultadoParcial = 50008; -- No se puede desasociar deducción obligatoria
                    -- Registrar error en bitácora
                    INSERT INTO EventLog (idTipoEvento, Parametros)
                    SELECT 
                        8, -- Desasociar deducción
                        JSON_MODIFY(JSON_MODIFY('{}',
                            '$.Error', 'Deducción obligatoria'),
                            '$.TipoDeduccion', IdTipoDeduccion)
                    FROM @Desasociaciones
                    WHERE EsObligatoria = 1;
                END
                
                -- Procesar desasociaciones válidas
                IF @resultadoParcial = 0 AND EXISTS (SELECT 1 FROM @Desasociaciones WHERE IdEmpleado IS NOT NULL AND EsObligatoria = 0)
                BEGIN
                    BEGIN TRANSACTION;
                    
                    -- Desasociar deducciones
                    UPDATE ed
                    SET FechaDesasociacion = @fechaOperacion
                    FROM EmpleadoDeduccion ed
                    JOIN @Desasociaciones d ON d.IdEmpleado = ed.idEmpleado AND d.IdTipoDeduccion = ed.idTipoDeduccion
                    WHERE ed.FechaDesasociacion IS NULL;
                    
                    -- Registrar en bitácora
                    INSERT INTO EventLog (
                        idTipoEvento,
                        Parametros
                    )
                    SELECT 
                        8, -- Desasociar deducción
                        JSON_MODIFY(JSON_MODIFY('{}',
                            '$.Empleado', IdEmpleado),
                            '$.TipoDeduccion', IdTipoDeduccion)
                    FROM @Desasociaciones
                    WHERE IdEmpleado IS NOT NULL 
                    AND EsObligatoria = 0;
                    
                    COMMIT;
                END
            END --END DESASOCIACIONES DE DEDUCCIONES========================================================
            
            -- Si es jueves, hacer cierre semanal de planilla
            IF DATEPART(WEEKDAY, @fechaOperacion) = 5 AND @resultadoParcial = 0 -- Jueves
            BEGIN
                EXEC sp_CierreSemanalPlanilla
                    @inFechaCierre = @fechaOperacion,
                    @outResultado = @resultadoParcial OUTPUT;
            END
            
            SET @i = @i + 1;
        END
        
        -- Si hubo error en alguna operación, retornar ese código
        IF @resultadoParcial <> 0
            SET @outResultado = @resultadoParcial;
        ELSE
            SET @outResultado = 0; -- Éxito completo
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK;
            
        SET @outResultado = 50000 + ERROR_NUMBER();
        INSERT INTO EventLog (
            idTipoEvento,
            Parametros
        )
        VALUES (
            16, -- TipoEvento: Simulación de operación
            JSON_MODIFY('{}', '$.Error', ERROR_MESSAGE())
        );
    END CATCH;
END;