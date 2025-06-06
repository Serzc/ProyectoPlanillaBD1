CREATE OR ALTER PROCEDURE sp_CargarCatalogosDesdeXML
    @inXmlCatalogos XML,
    @outResultado INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Tipos de Documento de Identidad
        INSERT INTO TipoDocumentoIdentidad (id, Nombre)
        SELECT
            t.f.value('@Id', 'INT'),
            t.f.value('@Nombre', 'VARCHAR(50)')
        FROM @inXmlCatalogos.nodes('/Catalogo/TiposdeDocumentodeldentidad/TipoDocuidentidad') as t(f);
        
        -- Tipos de Jornada
        INSERT INTO TipoJornada (id, Nombre, HoraInicio, HoraFin)
        SELECT
            t.f.value('@id', 'INT'),
            t.f.value('@Nombre', 'VARCHAR(50)'),
            CAST(t.f.value('@Horalnicio', 'VARCHAR(8)') AS TIME),
            CAST(t.f.value('@HoraFin', 'VARCHAR(8)') AS TIME)
        FROM @inXmlCatalogos.nodes('/Catalogo/TiposDeJornada/TipoDeJornada') as t(f);
        
        -- Puestos
        INSERT INTO Puesto (Nombre, SalarioXHora)
        SELECT
            t.f.value('@Nombre', 'VARCHAR(100)'),
            t.f.value('@SalarioXHora', 'DECIMAL(10,2)')
        FROM @inXmlCatalogos.nodes('/Catalogo/Puestos/Puesto') as t(f);
        
        -- Departamentos
        INSERT INTO Departamento (id, Nombre)
        SELECT
            t.f.value('@Id', 'INT'),
            t.f.value('@Nombre', 'VARCHAR(100)')
        FROM @inXmlCatalogos.nodes('/Catalogo/Departamentos/Departamento') as t(f);
        
        -- Feriados
        INSERT INTO Feriado (id, Nombre, Fecha)
        SELECT
            t.f.value('@Id', 'INT'),
            t.f.value('@Nombre', 'VARCHAR(100)'),
            CAST(t.f.value('@Fecha', 'CHAR(8)') AS DATE)
        FROM @inXmlCatalogos.nodes('/Catalogo/Feriados/Feriado') as t(f);
        
        -- Tipos de Movimiento
        INSERT INTO TipoMovimiento (id, Nombre)
        SELECT
            t.f.value('@Id', 'INT'),
            t.f.value('@Nombre', 'VARCHAR(100)')
        FROM @inXmlCatalogos.nodes('/Catalogo/TiposDeMovimiento/TipoDeMovimiento') as t(f);
        
        -- Tipos de Deducción
        INSERT INTO TipoDeduccion (id, Nombre, Obligatorio, Porcentual, Valor)
        SELECT
            t.f.value('@Id', 'INT'),
            t.f.value('@Nombre', 'VARCHAR(100)'),
            CASE WHEN t.f.value('@Obligatorio', 'VARCHAR(2)') = 'Si' THEN 1 ELSE 0 END,
            CASE WHEN t.f.value('@Porcentual', 'VARCHAR(2)') = 'Si' THEN 1 ELSE 0 END,
            t.f.value('@Valor', 'DECIMAL(10,2)')
        FROM @inXmlCatalogos.nodes('/Catalogo/TiposDeDeduccion/TipoDeDeduccion') as t(f);
        
        -- Usuarios Administrador
        INSERT INTO Usuario (Username, Password, Tipo)
        SELECT
            t.f.value('@username', 'VARCHAR(50)'),
            t.f.value('@pwd', 'VARCHAR(100)'),
            1 -- Administrador
        FROM @inXmlCatalogos.nodes('/Catalogo/UsuariosAdministrador/Usuario') as t(f);
        
        -- Tipos de Evento
        INSERT INTO TipoEvento (id, Nombre)
        SELECT
            t.f.value('@Id', 'INT'),
            t.f.value('@Nombre', 'VARCHAR(100)')
        FROM @inXmlCatalogos.nodes('/Catalogo/TiposdeEvento/TipoEvento') as t(f);
        
        COMMIT;
        SET @outResultado = 0; -- Éxito
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
            18, -- TipoEvento: Carga de catálogos
            JSON_MODIFY('{}', '$.Error', ERROR_MESSAGE())
        );
    END CATCH;
END;