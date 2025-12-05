-- =============================================
-- CARGA DE DATOS DESDE simulacionActu.xml
-- =============================================

USE T3BD
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO

DECLARE @outResultCode INT;

BEGIN TRY

    SET @outResultCode = 0;

    PRINT '===================================================';
    PRINT 'INICIANDO CARGA DE DATOS DESDE XML';
    PRINT '===================================================';
    PRINT '';

    -- =============================================
    -- 1. LEER ARCHIVO XML
    -- =============================================
    
    DECLARE @xmlData XML;

    SELECT @xmlData = TRY_CAST(BulkColumn AS XML)
    FROM OPENROWSET(
        BULK N'C:\Users\alons\OneDrive\Escritorio\TEC\VI Semestre\BD\ProyectoFinal\Datos\simulacionActu (1).xml',
        SINGLE_BLOB
    ) AS XmlFile;

    IF (@xmlData IS NULL)
    BEGIN
        SET @outResultCode = 50001;
        PRINT 'ERROR: No se pudo leer el archivo XML';
        PRINT 'Verificar ruta y permisos';
        RETURN;
    END;

    PRINT ' Archivo XML le�do correctamente';
    PRINT '';

    -- =============================================
    -- 2. CARGAR PROPIETARIOS (30)
    -- =============================================
    
    PRINT 'Cargando Propietarios...';

    DECLARE @contadorPropietarios INT = 0;

    INSERT INTO dbo.Propietario (
        valorDocumentoIdentidad
        , idTipoDocumento
        , nombre
        , email
        , telefono1
        , telefono2
        , fechaRegistro
        , activo
    )
    SELECT 
        T.N.value('@valorDocumento', 'VARCHAR(30)')
        , 1
        , T.N.value('@nombre', 'VARCHAR(100)')
        , T.N.value('@email', 'VARCHAR(100)')
        , T.N.value('@telefono', 'VARCHAR(20)')
        , T.N.value('@telefono', 'VARCHAR(20)')
        , GETDATE()
        , 1
    FROM @xmlData.nodes('/Operaciones/FechaOperacion[@fecha="2025-06-01"]/Personas/Persona') AS T(N)
    WHERE NOT EXISTS (
        SELECT 1 
        FROM dbo.Propietario P
        WHERE (P.valorDocumentoIdentidad = T.N.value('@valorDocumento', 'VARCHAR(30)'))
    );

    SET @contadorPropietarios = @@ROWCOUNT;
    PRINT CONCAT('R ', @contadorPropietarios, ' Propietarios insertados');

    -- =============================================
    -- 3. CARGAR PROPIEDADES (15)
    -- =============================================
    
    PRINT 'Cargando Propiedades...';

    DECLARE @contadorPropiedades INT = 0;

    INSERT INTO dbo.Propiedad (
        numeroFinca
        , idTipoUso
        , idTipoZona
        , valorFiscal
        , metrosCuadrados
        , numeroMedidor
        , fechaRegistro
        , activo
    )
    SELECT 
        T.N.value('@numeroFinca', 'VARCHAR(30)')
        , T.N.value('@tipoUsoId', 'INT')
        , T.N.value('@tipoZonaId', 'INT')
        , T.N.value('@valorFiscal', 'MONEY')
        , T.N.value('@metrosCuadrados', 'DECIMAL(10,2)')
        , T.N.value('@numeroMedidor', 'VARCHAR(50)')
        , T.N.value('@fechaRegistro', 'DATE')
        , 1
    FROM @xmlData.nodes('/Operaciones/FechaOperacion[@fecha="2025-06-01"]/Propiedades/Propiedad') AS T(N)
    WHERE NOT EXISTS (
        SELECT 1 
        FROM dbo.Propiedad P
        WHERE (P.numeroFinca = T.N.value('@numeroFinca', 'VARCHAR(30)'))
    );

    SET @contadorPropiedades = @@ROWCOUNT;
    PRINT CONCAT('R ', @contadorPropiedades, ' Propiedades insertadas');
    PRINT 'R Trigger asign� CCs autom�ticamente';

    -- =============================================
    -- 4. CARGAR MEDIDORES (15)
    -- =============================================
    
    PRINT 'Cargando Medidores...';

    DECLARE @contadorMedidores INT = 0;

    INSERT INTO dbo.Medidor (
        numeroMedidor
        , numeroFinca
        , saldoAcumulado
        , activo
    )
    SELECT 
        T.N.value('@numeroMedidor', 'VARCHAR(50)')
        , T.N.value('@numeroFinca', 'VARCHAR(30)')
        , 0
        , 1
    FROM @xmlData.nodes('/Operaciones/FechaOperacion[@fecha="2025-06-01"]/Propiedades/Propiedad') AS T(N)
    WHERE NOT EXISTS (
        SELECT 1 
        FROM dbo.Medidor M
        WHERE (M.numeroMedidor = T.N.value('@numeroMedidor', 'VARCHAR(50)'))
    );

    SET @contadorMedidores = @@ROWCOUNT;
    PRINT CONCAT('R ', @contadorMedidores, ' Medidores insertados');

    -- =============================================
    -- 5. CARGAR PROPIEDAD-PROPIETARIO (30)
    -- =============================================
    
    PRINT 'Cargando asociaciones Propiedad-Propietario...';

    DECLARE @contadorAsociaciones INT = 0;

    INSERT INTO dbo.PropiedadPropietario (
        numeroFinca
        , valorDocumentoIdentidad
        , esActual
        , fechaInicio
    )
    SELECT 
        T.N.value('@numeroFinca', 'VARCHAR(30)')
        , T.N.value('@valorDocumento', 'VARCHAR(30)')
        , 1
        , '2025-06-01'
    FROM @xmlData.nodes('/Operaciones/FechaOperacion[@fecha="2025-06-01"]/PropiedadPersona/Movimiento') AS T(N)
    WHERE (T.N.value('@tipoAsociacionId', 'INT') = 1)
        AND NOT EXISTS (
            SELECT 1 
            FROM dbo.PropiedadPropietario PP
            WHERE (PP.numeroFinca = T.N.value('@numeroFinca', 'VARCHAR(30)'))
                AND (PP.valorDocumentoIdentidad = T.N.value('@valorDocumento', 'VARCHAR(30)'))
        );

    SET @contadorAsociaciones = @@ROWCOUNT;
    PRINT CONCAT('R ', @contadorAsociaciones, ' asociaciones insertadas');

    -- =============================================
    -- 6. CARGAR CCs ADICIONALES (Patente Comercial)
    -- =============================================
    
    PRINT 'Cargando Conceptos de Cobro adicionales...';

    DECLARE @contadorCCAdicionales INT = 0;

    INSERT INTO dbo.PropiedadConceptoCobro (
        numeroFinca
        , idCC
        , activo
        , fechaAsignacion
    )
    SELECT 
        T.N.value('@numeroFinca', 'VARCHAR(30)')
        , T.N.value('@idCC', 'INT')
        , 1
        , GETDATE()
    FROM @xmlData.nodes('/Operaciones/FechaOperacion[@fecha="2025-06-01"]/CCPropiedad/Movimiento') AS T(N)
    WHERE (T.N.value('@tipoAsociacionId', 'INT') = 1)
        AND NOT EXISTS (
            SELECT 1 
            FROM dbo.PropiedadConceptoCobro PCC
            WHERE (PCC.numeroFinca = T.N.value('@numeroFinca', 'VARCHAR(30)'))
                AND (PCC.idCC = T.N.value('@idCC', 'INT'))
        );

    SET @contadorCCAdicionales = @@ROWCOUNT;
    PRINT CONCAT('R ', @contadorCCAdicionales, ' CCs adicionales asignados');
    PRINT '';


END TRY
BEGIN CATCH
    
    INSERT INTO dbo.DBErrors (
        userName
        , errorNumber
        , errorState
        , errorSeverity
        , errorLine
        , errorProcedure
        , errorMessage
        , errorDateTime
    )
    VALUES (
        SUSER_SNAME()
        , ERROR_NUMBER()
        , ERROR_STATE()
        , ERROR_SEVERITY()
        , ERROR_LINE()
        , ERROR_PROCEDURE()
        , ERROR_MESSAGE()
        , GETDATE()
    );

    SET @outResultCode = 50005;
    PRINT 'ERROR: ' + ERROR_MESSAGE();

END CATCH;

SET NOCOUNT OFF;
GO