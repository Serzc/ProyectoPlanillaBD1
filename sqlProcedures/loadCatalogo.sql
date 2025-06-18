CREATE OR ALTER PROCEDURE sp_CargarCatalogoDesdeXML
    @inXmlData XML,
    @outResultado INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        DECLARE @fechaInicio DATE = '2023-06-01';
        DECLARE @xmlData XML = @inXmlData;

        -- 1. Cargar Tipos de Documento de Identidad
        INSERT INTO TipoDocumentoIdentidad (id, Nombre)
        SELECT 
            doc.value('@Id', 'INT'),
            doc.value('@Nombre', 'VARCHAR(50)')
        FROM @xmlData.nodes('/Catalogo/TiposdeDocumentodeIdentidad/TipoDocuIdentidad') AS T(doc)
        WHERE NOT EXISTS (SELECT 1 FROM TipoDocumentoIdentidad WHERE id = doc.value('@Id', 'INT'));

        -- 2. Cargar Tipos de Jornada
        INSERT INTO TipoJornada (id, Nombre, HoraInicio, HoraFin)
        SELECT 
            jornada.value('@Id', 'INT'),
            jornada.value('@Nombre', 'VARCHAR(50)'),
            CAST(jornada.value('@HoraInicio', 'VARCHAR(8)') AS TIME),
            CAST(jornada.value('@HoraFin', 'VARCHAR(8)') AS TIME)
        FROM @xmlData.nodes('/Catalogo/TiposDeJornada/TipoDeJornada') AS T(jornada)
        WHERE NOT EXISTS (SELECT 1 FROM TipoJornada WHERE id = jornada.value('@Id', 'INT'));

        -- 3. Cargar Puestos
        INSERT INTO Puesto (Nombre, SalarioXHora)
        SELECT 
            puesto.value('@Nombre', 'VARCHAR(100)'),
            puesto.value('@SalarioXHora', 'DECIMAL(25,4)')
        FROM @xmlData.nodes('/Catalogo/Puestos/Puesto') AS T(puesto)
        WHERE NOT EXISTS (SELECT 1 FROM Puesto WHERE Nombre = puesto.value('@Nombre', 'VARCHAR(100)'));

        -- 4. Cargar Departamentos
        INSERT INTO Departamento (id, Nombre)
        SELECT 
            depto.value('@Id', 'INT'),
            depto.value('@Nombre', 'VARCHAR(100)')
        FROM @xmlData.nodes('/Catalogo/Departamentos/Departamento') AS T(depto)
        WHERE NOT EXISTS (SELECT 1 FROM Departamento WHERE id = depto.value('@Id', 'INT'));

        -- 5. Cargar Feriados
        INSERT INTO Feriado (id, Nombre, Fecha)
        SELECT 
            feriado.value('@Id', 'INT'),
            feriado.value('@Nombre', 'VARCHAR(100)'),
            CASE 
                WHEN ISDATE(feriado.value('@Fecha', 'VARCHAR(8)')) = 1 
                THEN CAST(feriado.value('@Fecha', 'VARCHAR(8)') AS DATE)
                ELSE NULL
            END
        FROM @xmlData.nodes('/Catalogo/Feriados/Feriado') AS T(feriado)
        WHERE NOT EXISTS (SELECT 1 FROM Feriado WHERE id = feriado.value('@Id', 'INT'));

        -- 6. Cargar Tipos de Movimiento
        INSERT INTO TipoMovimiento (id, Nombre)
        SELECT 
            mov.value('@Id', 'INT'),
            mov.value('@Nombre', 'VARCHAR(100)')
        FROM @xmlData.nodes('/Catalogo/TiposDeMovimiento/TipoDeMovimiento') AS T(mov)
        WHERE NOT EXISTS (SELECT 1 FROM TipoMovimiento WHERE id = mov.value('@Id', 'INT'));

        -- 7. Cargar Tipos de Deducción
        INSERT INTO TipoDeduccion (id, Nombre, Obligatorio, Porcentual, Valor)
        SELECT 
            ded.value('@Id', 'INT'),
            ded.value('@Nombre', 'VARCHAR(100)'),
            CASE WHEN ded.value('@Obligatorio', 'VARCHAR(2)') = 'Si' THEN 1 ELSE 0 END,
            CASE WHEN ded.value('@Porcentual', 'VARCHAR(2)') = 'Si' THEN 1 ELSE 0 END,
            ded.value('@Valor', 'DECIMAL(25,4)')
        FROM @xmlData.nodes('/Catalogo/TiposDeDeduccion/TipoDeDeduccion') AS T(ded)
        WHERE NOT EXISTS (SELECT 1 FROM TipoDeduccion WHERE id = ded.value('@Id', 'INT'));

        -- 8. Cargar Tipos de Evento
        INSERT INTO TipoEvento (id, Nombre)
        SELECT 
            evento.value('@Id', 'INT'),
            evento.value('@Nombre', 'VARCHAR(100)')
        FROM @xmlData.nodes('/Catalogo/TiposdeEvento/TipoEvento') AS T(evento)
        WHERE NOT EXISTS (SELECT 1 FROM TipoEvento WHERE id = evento.value('@Id', 'INT'));

        -- 9. Cargar Tipos de Error
        INSERT INTO TipoError (id, Descripcion)
        SELECT 
            error.value('@Codigo', 'INT'),
            error.value('@Descripcion', 'VARCHAR(255)')
        FROM @xmlData.nodes('/Catalogo/Errores/Error') AS T(error)
        WHERE NOT EXISTS (SELECT 1 FROM TipoError WHERE id = error.value('@Codigo', 'INT'));

        -- 10. Cargar Usuarios
        SET IDENTITY_INSERT Usuario ON;
        INSERT INTO Usuario (id, Username, Password, Tipo, idEmpleado)
        SELECT 
            usuario.value('@Id', 'INT'),
            usuario.value('@Username', 'VARCHAR(50)'),
            usuario.value('@Password', 'VARCHAR(100)'),
            usuario.value('@Tipo', 'INT'),
            NULL
        FROM @xmlData.nodes('/Catalogo/Usuarios/Usuario') AS T(usuario)
        WHERE NOT EXISTS (SELECT 1 FROM Usuario WHERE Username = usuario.value('@Username', 'VARCHAR(50)'));
        SET IDENTITY_INSERT Usuario OFF;

        -- 11. Cargar Empleados
        DECLARE @EmpleadosTemp TABLE (
            idUsuario INT,
            Nombre VARCHAR(100),
            idTipoDocumento INT,
            ValorDocumentoIdentidad VARCHAR(50),
            FechaNacimiento DATE,
            FechaContratacion DATE,
            idDepartamento INT,
            NombrePuesto VARCHAR(100),
            Activo BIT
        );

        INSERT INTO @EmpleadosTemp
        SELECT 
            emp.value('@IdUsuario', 'INT'),
            emp.value('@Nombre', 'VARCHAR(100)'),
            emp.value('@IdTipoDocumento', 'INT'),
            emp.value('@ValorDocumento', 'VARCHAR(50)'),
            CASE 
                WHEN ISDATE(emp.value('@FechaNacimiento', 'VARCHAR(10)')) = 1 
                THEN CAST(emp.value('@FechaNacimiento', 'VARCHAR(10)') AS DATE)
                ELSE NULL
            END,
            @fechaInicio,
            emp.value('@IdDepartamento', 'INT'),
            emp.value('@NombrePuesto', 'VARCHAR(100)'),
            CASE WHEN emp.value('@Activo', 'VARCHAR(1)') = '1' THEN 1 ELSE 0 END
        FROM @xmlData.nodes('/Catalogo/Empleados/Empleado') AS T(emp);

        INSERT INTO Empleado (
            Nombre
            , idTipoDocumento
            , ValorDocumentoIdentidad
            , FechaNacimiento
            , FechaContratacion
            , idPuesto
            , idDepartamento
            , Activo
        )
        SELECT 
            t.Nombre,
            t.idTipoDocumento,
            t.ValorDocumentoIdentidad,
            t.FechaNacimiento,
            t.FechaContratacion,
            p.id,
            t.idDepartamento,
            t.Activo
        FROM @EmpleadosTemp t
        INNER JOIN Puesto p ON p.Nombre = t.NombrePuesto
        WHERE NOT EXISTS (
            SELECT 1 FROM Empleado 
            WHERE ValorDocumentoIdentidad = t.ValorDocumentoIdentidad
        );

        -- Actualizar usuarios con los IDs de empleado
        UPDATE u
        SET u.idEmpleado = e.id
        FROM Usuario u
        INNER JOIN @EmpleadosTemp t ON u.id = t.idUsuario
        INNER JOIN Empleado e ON e.ValorDocumentoIdentidad = t.ValorDocumentoIdentidad
        WHERE u.idEmpleado IS NULL;

        COMMIT TRANSACTION;
        SET @outResultado = 0;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @outResultado = ERROR_NUMBER();
        
    END CATCH
END;