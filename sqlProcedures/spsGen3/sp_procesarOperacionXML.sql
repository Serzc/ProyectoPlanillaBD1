CREATE OR ALTER PROCEDURE sp_procesarOperacionXML
    @inXmlOperacion XML,
    @outResultado INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
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
        DECLARE @fechaActual DATE, @esJueves BIT, @resultadoParcial INT = 0;
        
        WHILE @i <= @total AND @resultadoParcial = 0
        BEGIN
            SELECT @fechaActual = Fecha FROM @FechasOperacion WHERE Orden = @i;
            SET @esJueves = CASE WHEN DATEPART(WEEKDAY, @fechaActual) = 5 THEN 1 ELSE 0 END;
            
            -- Obtener el XML para esta fecha específica
            DECLARE @xmlFecha XML = @inXmlOperacion.query('/Operacion/FechaOperacion[@Fecha=sql:variable("@fechaActual")]');
            
            -- Procesar cada tipo de operación según lo que exista en el XML
            IF @xmlFecha.exist('//NuevosEmpleados') = 1
            BEGIN
                EXEC sp_ProcesarNuevosEmpleados @xmlFecha, @fechaActual, @outResultado = @resultadoParcial OUTPUT;
                IF @resultadoParcial <> 0
                    SET @outResultado = @resultadoParcial;
            END
            IF @xmlFecha.exist('//EliminarEmpleados') = 1
            BEGIN
                EXEC sp_ProcesarEliminarEmpleados @xmlFecha, @fechaActual, @outResultado = @resultadoParcial OUTPUT;
                IF @resultadoParcial <> 0
                    SET @outResultado = @resultadoParcial;
            END
            
            IF @resultadoParcial = 0 AND @xmlFecha.exist('//MarcasAsistencia') = 1
            BEGIN
                EXEC sp_ProcesarMarcasAsistencia @xmlFecha, @fechaActual, @outResultado = @resultadoParcial OUTPUT;
                IF @resultadoParcial <> 0
                    SET @outResultado = @resultadoParcial;
            END
            
            IF @resultadoParcial = 0 AND @xmlFecha.exist('//JornadasProximaSemana') = 1
            BEGIN
                EXEC sp_ProcesarJornadasProximaSemana @xmlFecha, @fechaActual, @outResultado = @resultadoParcial OUTPUT;
                IF @resultadoParcial <> 0
                    SET @outResultado = @resultadoParcial;
            END
            
            IF @resultadoParcial = 0 AND @xmlFecha.exist('//AsociacionEmpleadoDeducciones') = 1
            BEGIN
                EXEC sp_ProcesarAsociacionEmpleadoDeducciones @xmlFecha, @fechaActual, @outResultado = @resultadoParcial OUTPUT;
                IF @resultadoParcial <> 0
                    SET @outResultado = @resultadoParcial;
            END
            
            IF @resultadoParcial = 0 AND @xmlFecha.exist('//DesasociacionEmpleadoDeducciones') = 1
            BEGIN
                EXEC sp_ProcesarDesasociacionEmpleadoDeducciones @xmlFecha, @fechaActual, @outResultado = @resultadoParcial OUTPUT;
                IF @resultadoParcial <> 0
                    SET @outResultado = @resultadoParcial;
            END
            
            -- Procesar cierres semanales/mensuales si es jueves
            IF @resultadoParcial = 0 AND @esJueves = 1
            BEGIN
                IF @i <> 1 OR CAST(@fechaActual AS DATE) <> '2023-06-01'
                BEGIN 
                    EXEC sp_ProcesarCierreSemanal @fechaActual, @outResultado = @resultadoParcial OUTPUT;
                    IF @resultadoParcial <> 0
                        SET @outResultado = @resultadoParcial;
                        
                    -- Verificar si es el último jueves del mes para cierre mensual
                    IF @resultadoParcial = 0 AND dbo.GetUltimoJuevesDelMes(@fechaActual) = @fechaActual
                    BEGIN
                        EXEC sp_ProcesarCierreMensual @fechaActual, @outResultado = @resultadoParcial OUTPUT;
                        IF @resultadoParcial <> 0
                            SET @outResultado = @resultadoParcial;
                    END
                END
                IF @resultadoParcial = 0
                BEGIN
                    EXEC sp_CrearNuevaSemanaPlanilla @fechaActual, @outResultado = @resultadoParcial OUTPUT;
                    IF @resultadoParcial <> 0
                        SET @outResultado = @resultadoParcial;
                END
                --EXEC sp_RepararPlanilla @fechaActual, @outResultado = @resultadoParcial OUTPUT;
                --IF @resultadoParcial <> 0
                --    SET @outResultado = @resultadoParcial;
            END
            
            SET @i = @i + 1;
        END
        
        IF @outResultado IS NULL
            SET @outResultado = 0;
    END TRY
    BEGIN CATCH
        IF @outResultado = 0
            SET @outResultado = COALESCE(ERROR_NUMBER(), 50000);
        
        DECLARE @errorDesc VARCHAR(200) = CONCAT('En la fecha: ', @fechaActual, ' ', ERROR_MESSAGE());
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