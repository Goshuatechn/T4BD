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
    PRINT 'INICIANDO CARGA DE LECTURAS Y PAGOS DESDE XML';
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
    -- 2. CARGAR LECTURAS DE MEDIDORES
    -- Procesar todas las fechas del XML
    -- =============================================
    
    PRINT 'Procesando Lecturas de Medidores...';

    DECLARE @tablaLecturas TABLE (
        numeroMedidor VARCHAR(50)
        , idTipoMovimiento INT
        , fechaMovimiento DATETIME
        , valorMovimiento DECIMAL(12,2)
    );

    INSERT INTO @tablaLecturas (
        numeroMedidor
        , idTipoMovimiento
        , fechaMovimiento
        , valorMovimiento
    )
    SELECT 
        T.N.value('@numeroMedidor', 'VARCHAR(50)')
        , T.N.value('@tipoMovimientoId', 'INT')
        , T.N.value('../../@fecha', 'DATE')
        , T.N.value('@valor', 'DECIMAL(12,2)')
    FROM @xmlData.nodes('//FechaOperacion/LecturasMedidor/Lectura') AS T(N);

    DECLARE @totalLecturas INT;
    SELECT @totalLecturas = COUNT(*) FROM @tablaLecturas;

    PRINT CONCAT('R ', @totalLecturas, ' lecturas extra�das del XML');

    -- =============================================
    -- 3. PROCESAR LECTURAS MEDIDOR POR MEDIDOR
    -- =============================================
    
    PRINT 'Insertando movimientos de medidores...';

    DECLARE @contadorMovimientos INT = 0;
    DECLARE @numeroMedidor VARCHAR(50);
    DECLARE @idTipoMovimiento INT;
    DECLARE @fechaMovimiento DATETIME;
    DECLARE @valorMovimiento DECIMAL(12,2);
    DECLARE @saldoActual DECIMAL(12,2);
    DECLARE @nuevoSaldo DECIMAL(12,2);

    DECLARE @curLecturas TABLE (
        id INT IDENTITY(1,1)
        , numeroMedidor VARCHAR(50)
        , idTipoMovimiento INT
        , fechaMovimiento DATETIME
        , valorMovimiento DECIMAL(12,2)
    );

    INSERT INTO @curLecturas
    SELECT 
        numeroMedidor
        , idTipoMovimiento
        , fechaMovimiento
        , valorMovimiento
    FROM @tablaLecturas
    ORDER BY numeroMedidor, fechaMovimiento;

    DECLARE @i INT = 1;
    DECLARE @maxId INT;
    SELECT @maxId = MAX(id) FROM @curLecturas;

    WHILE (@i <= @maxId)
    BEGIN
        
        SELECT 
            @numeroMedidor = numeroMedidor
            , @idTipoMovimiento = idTipoMovimiento
            , @fechaMovimiento = fechaMovimiento
            , @valorMovimiento = valorMovimiento
        FROM @curLecturas
        WHERE (id = @i);

        -- Obtener saldo actual del medidor
        SELECT @saldoActual = saldoAcumulado
        FROM dbo.Medidor
        WHERE (numeroMedidor = @numeroMedidor);

        IF (@idTipoMovimiento = 1)
        BEGIN
            -- Tipo 1: Lectura normal
            -- El nuevo saldo es el valor de la lectura
            SET @nuevoSaldo = @valorMovimiento;
            SET @valorMovimiento = @valorMovimiento - @saldoActual;
        END
        ELSE IF (@idTipoMovimiento = 2)
        BEGIN

            SET @nuevoSaldo = @saldoActual - @valorMovimiento;
            SET @valorMovimiento = -@valorMovimiento;
        END
        ELSE IF (@idTipoMovimiento = 3)
        BEGIN

            SET @nuevoSaldo = @saldoActual + @valorMovimiento;
        END;

        -- Insertar movimiento
        INSERT INTO dbo.MovimientoMedidor (
            numeroMedidor
            , idTipoMovimiento
            , fechaMovimiento
            , valorMovimiento
            , saldoAnterior
            , saldoDespues
        )
        VALUES (
            @numeroMedidor
            , @idTipoMovimiento
            , @fechaMovimiento
            , @valorMovimiento
            , @saldoActual
            , @nuevoSaldo
        );

        -- Actualizar saldo del medidor
        UPDATE dbo.Medidor
        SET saldoAcumulado = @nuevoSaldo
            , fechaUltimaLectura = @fechaMovimiento
        WHERE (numeroMedidor = @numeroMedidor);

        -- Actualizar m3Acumulados en Propiedad
        UPDATE P
        SET P.m3Acumulados = @nuevoSaldo
        FROM dbo.Propiedad P
            INNER JOIN dbo.Medidor M ON (M.numeroFinca = P.numeroFinca)
        WHERE (M.numeroMedidor = @numeroMedidor);

        SET @contadorMovimientos = @contadorMovimientos + 1;
        SET @i = @i + 1;

    END;

    PRINT CONCAT('R ', @contadorMovimientos, ' movimientos insertados');

    -- =============================================
    -- 4. CARGAR PAGOS
    -- =============================================
    
    PRINT 'Procesando Pagos...';

    DECLARE @tablaPagos TABLE (
        numeroFinca VARCHAR(30)
        , tipoMedioPagoId INT
        , numeroReferencia VARCHAR(100)
        , fechaPago DATETIME
    );

    -- Extraer todos los pagos del XML
    INSERT INTO @tablaPagos (
        numeroFinca
        , tipoMedioPagoId
        , numeroReferencia
        , fechaPago
    )
    SELECT 
        T.N.value('@numeroFinca', 'VARCHAR(30)')
        , T.N.value('@tipoMedioPagoId', 'INT')
        , T.N.value('@numeroReferencia', 'VARCHAR(100)')
        , T.N.value('../../@fecha', 'DATE')
    FROM @xmlData.nodes('//FechaOperacion/Pagos/Pago') AS T(N);

    DECLARE @totalPagos INT;
    SELECT @totalPagos = COUNT(*) FROM @tablaPagos;

    PRINT CONCAT('R ', @totalPagos, ' pagos extra�dos del XML');

    -- Insertar pagos
    DECLARE @contadorPagos INT = 0;
    DECLARE @numeroFinca VARCHAR(30);
    DECLARE @tipoMedioPagoId INT;
    DECLARE @numeroReferencia VARCHAR(100);
    DECLARE @fechaPago DATETIME;
    DECLARE @numeroComprobante VARCHAR(50);

    DECLARE @curPagos TABLE (
        id INT IDENTITY(1,1)
        , numeroFinca VARCHAR(30)
        , tipoMedioPagoId INT
        , numeroReferencia VARCHAR(100)
        , fechaPago DATETIME
    );

    INSERT INTO @curPagos
    SELECT 
        numeroFinca
        , tipoMedioPagoId
        , numeroReferencia
        , fechaPago
    FROM @tablaPagos
    ORDER BY fechaPago;

    SET @i = 1;
    SELECT @maxId = MAX(id) FROM @curPagos;

    WHILE (@i <= @maxId)
    BEGIN
        
        SELECT 
            @numeroFinca = numeroFinca
            , @tipoMedioPagoId = tipoMedioPagoId
            , @numeroReferencia = numeroReferencia
            , @fechaPago = fechaPago
        FROM @curPagos
        WHERE (id = @i);

        -- Generar n�mero de comprobante
        SET @numeroComprobante = CONCAT('COMP-', FORMAT(@fechaPago, 'yyyyMMdd'), '-', @numeroFinca);

        -- Insertar pago
        INSERT INTO dbo.Pago (
            numeroFinca
            , idFactura
            , idMedioPago
            , numeroComprobante
            , numeroReferencia
            , fechaPago
            , montoPagado
        )
        VALUES (
            @numeroFinca
            , NULL
            , @tipoMedioPagoId
            , @numeroComprobante
            , @numeroReferencia
            , @fechaPago
            , 0
        );

        SET @contadorPagos = @contadorPagos + 1;
        SET @i = @i + 1;

    END;

    PRINT CONCAT('R ', @contadorPagos, ' pagos insertados');
    PRINT '';

    -- =============================================
    -- RESUMEN FINAL
    -- =============================================

    PRINT '===================================================';
    PRINT 'CARGA DE LECTURAS Y PAGOS COMPLETADA';
    PRINT '===================================================';
    PRINT '';
    PRINT 'RESUMEN:';
    PRINT CONCAT('  - ', @contadorMovimientos, ' Movimientos de medidores');
    PRINT CONCAT('  - ', @contadorPagos, ' Pagos hist�ricos');
    PRINT '';
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