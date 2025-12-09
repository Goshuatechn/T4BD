-- =============================================
-- CARGA DE CATÁLOGOS DESDE catalogosV3.xml
-- =============================================

-- =====
-- COMENTARIO PRUEBA
-- =====


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
    PRINT 'INICIANDO CARGA DE CAT�LOGOS DESDE XML';
    PRINT '===================================================';
    PRINT '';

    -- =============================================
    -- 1. LEER ARCHIVO XML
    -- =============================================
    
    DECLARE @xmlData XML;

    SELECT @xmlData = TRY_CAST(BulkColumn AS XML)
    FROM OPENROWSET(
        BULK N'C:\Users\alons\OneDrive\Escritorio\TEC\VI Semestre\BD\ProyectoFinal\Datos\catalogosV3 (1).xml',
		
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
    -- 2. ACTUALIZAR PAR�METROS DEL SISTEMA
    -- =============================================
    
    PRINT 'Actualizando Par�metros del Sistema...';

    UPDATE dbo.ParametrosSistema 
    SET valorNumerico = @xmlData.value('(/Catalogos/ParametrosSistema/DiasVencimientoFactura)[1]', 'INT')
    WHERE (nombreParametro = 'DiasVencimientoFactura');

    UPDATE dbo.ParametrosSistema 
    SET valorNumerico = @xmlData.value('(/Catalogos/ParametrosSistema/DiasGraciaCorta)[1]', 'INT')
    WHERE (nombreParametro = 'DiasGraciaCorteAgua');

    PRINT 'Par�metros actualizados';

    -- =============================================
    -- 3. TIPO MOVIMIENTO
    -- =============================================
    
    PRINT 'Cargando TipoMovimiento...';

    INSERT INTO dbo.TipoMovimiento (
        idTipoMovimiento
        , nombre
    )
    SELECT 
        T.N.value('@id', 'INT')
        , T.N.value('@nombre', 'VARCHAR(50)')
    FROM @xmlData.nodes('/Catalogos/TipoMovimientoLecturaMedidor/TipoMov') AS T(N)
    WHERE NOT EXISTS (
        SELECT 1 
        FROM dbo.TipoMovimiento TM
        WHERE (TM.idTipoMovimiento = T.N.value('@id', 'INT'))
    );

    PRINT CONCAT('R ', @@ROWCOUNT, ' registros insertados');

    -- =============================================
    -- 4. TIPO USO PROPIEDAD
    -- =============================================
    
    PRINT 'Cargando TipoUso...';

    INSERT INTO dbo.TipoUso (
        idTipoUso
        , nombre
    )
    SELECT 
        T.N.value('@id', 'INT')
        , T.N.value('@nombre', 'VARCHAR(50)')
    FROM @xmlData.nodes('/Catalogos/TipoUsoPropiedad/TipoUso') AS T(N)
    WHERE NOT EXISTS (
        SELECT 1 
        FROM dbo.TipoUso TU
        WHERE (TU.idTipoUso = T.N.value('@id', 'INT'))
    );

    PRINT CONCAT('R ', @@ROWCOUNT, ' registros insertados');

    -- =============================================
    -- 5. TIPO ZONA PROPIEDAD
    -- =============================================
    
    PRINT 'Cargando TipoZona...';

    INSERT INTO dbo.TipoZona (
        idTipoZona
        , nombre
    )
    SELECT 
        T.N.value('@id', 'INT')
        , T.N.value('@nombre', 'VARCHAR(50)')
    FROM @xmlData.nodes('/Catalogos/TipoZonaPropiedad/TipoZona') AS T(N)
    WHERE NOT EXISTS (
        SELECT 1 
        FROM dbo.TipoZona TZ
        WHERE (TZ.idTipoZona = T.N.value('@id', 'INT'))
    );

    PRINT CONCAT('R ', @@ROWCOUNT, ' registros insertados');

    -- =============================================
    -- 6. TIPO ASOCIACION
    -- =============================================
    
    PRINT 'Cargando TipoAsociacion...';

    INSERT INTO dbo.TipoAsociacion (
        idTipoAsociacion
        , nombre
    )
    SELECT 
        T.N.value('@id', 'INT')
        , T.N.value('@nombre', 'VARCHAR(50)')
    FROM @xmlData.nodes('/Catalogos/TipoAsociacion/TipoAso') AS T(N)
    WHERE NOT EXISTS (
        SELECT 1 
        FROM dbo.TipoAsociacion TA
        WHERE (TA.idTipoAsociacion = T.N.value('@id', 'INT'))
    );

    PRINT CONCAT('R ', @@ROWCOUNT, ' registros insertados');

    -- =============================================
    -- 7. MEDIO PAGO
    -- =============================================
    
    PRINT 'Cargando MedioPago...';

    INSERT INTO dbo.MedioPago (
        idMedioPago
        , nombre
    )
    SELECT 
        T.N.value('@id', 'INT')
        , T.N.value('@nombre', 'VARCHAR(50)')
    FROM @xmlData.nodes('/Catalogos/TipoMedioPago/MedioPago') AS T(N)
    WHERE NOT EXISTS (
        SELECT 1 
        FROM dbo.MedioPago MP
        WHERE (MP.idMedioPago = T.N.value('@id', 'INT'))
    );

    PRINT CONCAT('R ', @@ROWCOUNT, ' registros insertados');

    -- =============================================
    -- 8. PERIODO MONTO CC
    -- =============================================
    
    PRINT 'Cargando PeriodoMontoCC...';

    INSERT INTO dbo.PeriodoMontoCC (
        idPeriodo
        , nombre
        , cantidadMeses
    )
    SELECT 
        T.N.value('@id', 'INT')
        , T.N.value('@nombre', 'VARCHAR(50)')
        , T.N.value('@qMeses', 'INT')
    FROM @xmlData.nodes('/Catalogos/PeriodoMontoCC/PeriodoMonto') AS T(N)
    WHERE NOT EXISTS (
        SELECT 1 
        FROM dbo.PeriodoMontoCC PM
        WHERE (PM.idPeriodo = T.N.value('@id', 'INT'))
    );

    PRINT CONCAT('R ', @@ROWCOUNT, ' registros insertados');

    -- =============================================
    -- 9. TIPO MONTO CC
    -- =============================================
    
    PRINT 'Cargando TipoMontoCC...';

    INSERT INTO dbo.TipoMontoCC (
        idTipoMonto
        , nombre
    )
    SELECT 
        T.N.value('@id', 'INT')
        , T.N.value('@nombre', 'VARCHAR(50)')
    FROM @xmlData.nodes('/Catalogos/TipoMontoCC/TipoMonto') AS T(N)
    WHERE NOT EXISTS (
        SELECT 1 
        FROM dbo.TipoMontoCC TM
        WHERE (TM.idTipoMonto = T.N.value('@id', 'INT'))
    );

    PRINT CONCAT('R ', @@ROWCOUNT, ' registros insertados');

    -- =============================================
    -- 10. CONCEPTOS DE COBRO
    -- =============================================
    

    INSERT INTO dbo.ConceptoCobro (
        idCC
        , nombre
        , idTipoMontoCC
        , idPeriodoMontoCC
        , valorFijo
        , valorPorcentaje
        , valorMinimo
        , valorMinimoM3
        , valorM3
        , valorFijoM3Adicional
        , valorM2Minimo
        , valorTractosM2
        , esRecurrente
        , esInteresMoratorio
        , esReconexion
    )
    SELECT 
        T.N.value('@id', 'INT')
        , T.N.value('@nombre', 'VARCHAR(100)')
        , T.N.value('@TipoMontoCC', 'INT')
        , T.N.value('@PeriodoMontoCC', 'INT')
        , NULLIF(T.N.value('@ValorFijo', 'MONEY'), '')
        , NULLIF(T.N.value('@ValorPorcentual', 'DECIMAL(10,6)'), '')
        , NULLIF(T.N.value('@ValorMinimo', 'MONEY'), '')
        , NULLIF(T.N.value('@ValorMinimoM3', 'DECIMAL(10,2)'), '')
        , NULLIF(T.N.value('@ValorM3', 'MONEY'), '')
        , NULLIF(T.N.value('@ValorFijoM3Adicional', 'MONEY'), '')
        , NULLIF(T.N.value('@ValorM2Minimo', 'DECIMAL(10,2)'), '')
        , NULLIF(T.N.value('@ValorTramosM2', 'DECIMAL(10,2)'), '')
        , CASE 
            WHEN T.N.value('@nombre', 'VARCHAR(100)') IN ('ReconexionAgua', 'InteresesMoratorios') THEN 0
            ELSE 1
          END
        , CASE 
            WHEN T.N.value('@nombre', 'VARCHAR(100)') = 'InteresesMoratorios' THEN 1
            ELSE 0
          END
        , CASE 
            WHEN T.N.value('@nombre', 'VARCHAR(100)') = 'ReconexionAgua' THEN 1
            ELSE 0
          END
    FROM @xmlData.nodes('/Catalogos/CCs/CC') AS T(N)
    WHERE NOT EXISTS (
        SELECT 1 
        FROM dbo.ConceptoCobro CC
        WHERE (CC.idCC = T.N.value('@id', 'INT'))
    );

    PRINT CONCAT('R ', @@ROWCOUNT, ' registros insertados');
    PRINT '';

    -- =============================================
    -- RESUMEN FINAL
    -- =============================================

    PRINT '===================================================';
    PRINT 'CAT�LOGOS CARGADOS EXITOSAMENTE DESDE XML';
    PRINT '===================================================';

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