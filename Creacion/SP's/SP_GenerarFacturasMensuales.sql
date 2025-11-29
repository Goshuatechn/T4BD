-- =============================================
-- SP_GenerarFacturasMensuales
-- =============================================

USE T3BD
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID('dbo.SP_GenerarFacturasMensuales', 'P') IS NOT NULL
    DROP PROCEDURE dbo.SP_GenerarFacturasMensuales;
GO

CREATE PROCEDURE dbo.SP_GenerarFacturasMensuales
    @inFechaOperacion DATE
    , @outCantidadFacturas INT OUTPUT
    , @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        
        SET @outResultCode = 0;
        SET @outCantidadFacturas = 0;

        -- =============================================
        -- CAPA 1: IDENTIFICAR PROPIEDADES A FACTURAR
        -- VALIDACIONES DE ENTRADA
        -- =============================================
        
        -- Validar que fecha no sea futura
        IF (@inFechaOperacion > GETDATE())
        BEGIN
            SET @outResultCode = 50601;
            SET @outCantidadFacturas = 0;
            PRINT 'ERROR: Fecha de operación no puede ser futura';
            RETURN;
        END;

        -- Validar que fecha no sea muy antigua (más de 2 años)
        IF (@inFechaOperacion < DATEADD(YEAR, -2, GETDATE()))
        BEGIN
            SET @outResultCode = 50602;
            SET @outCantidadFacturas = 0;
            PRINT 'ERROR: Fecha de operación muy antigua';
            RETURN;
        END;

        -- =============================================
        -- INICIAR TRANSACCIÓN
        -- Aunque sea CAPA 1, iniciamos aquí para estructura
        -- =============================================
        
        BEGIN TRANSACTION tGenerarFacturas;

        -- =============================================
        -- TABLAS TEMPORALES
        -- =============================================
        
        -- Tabla 1: Propiedades a facturar
        DECLARE @tablaPropiedadesFacturar TABLE (
            numeroFinca VARCHAR(30)
            , diaFacturacion INT
            , valorFiscal MONEY
            , metrosCuadrados DECIMAL(10,2)
            , m3Acumulados DECIMAL(12,2)
            , m3AcumuladosUltimaFactura DECIMAL(12,2)
            , numeroMedidor VARCHAR(50)
        );

        -- Tabla 2: Detalles de factura (para capas siguientes)
        DECLARE @tablaDetallesFactura TABLE (
            numeroFinca VARCHAR(30)
            , idCC INT
            , monto MONEY
            , descripcion VARCHAR(100)
        );

        -- Obtener día del mes de la fecha de operación
        DECLARE @diaOperacion INT;
        SET @diaOperacion = DAY(@inFechaOperacion);

        PRINT CONCAT('Día de operación: ', @diaOperacion);
        PRINT '';

        -- =============================================
        -- LÓGICA: PROPIEDADES QUE CORRESPONDE FACTURAR HOY
        -- =============================================
        
        -- Regla 1: Día de facturación coincide con día de operación
        -- Regla 2: Si es día 31 y el mes tiene menos días → facturar el último día
        -- Regla 3: Solo propiedades activas
        
        INSERT INTO @tablaPropiedadesFacturar (
            numeroFinca
            , diaFacturacion
            , valorFiscal
            , metrosCuadrados
            , m3Acumulados
            , m3AcumuladosUltimaFactura
            , numeroMedidor
        )
        SELECT 
            P.numeroFinca
            , P.diaFacturacion
            , P.valorFiscal
            , P.metrosCuadrados
            , ISNULL(P.m3Acumulados, 0)
            , ISNULL(P.m3AcumuladosUltimaFactura, 0)
            , P.numeroMedidor
        FROM dbo.Propiedad P
        WHERE (P.activo = 1)
            AND (
                -- CASO 1: Día exacto
                (P.diaFacturacion = @diaOperacion)
                
                OR
                
                -- CASO 2: Día 31 en meses cortos
                (
                    P.diaFacturacion = 31
                    AND @diaOperacion = DAY(EOMONTH(@inFechaOperacion))
                    AND DAY(EOMONTH(@inFechaOperacion)) < 31
                )
            );

        -- =============================================
        -- FILTRAR: NO FACTURAR SI YA TIENE FACTURA DEL MES
        -- =============================================
        
        DELETE FROM @tablaPropiedadesFacturar
        WHERE numeroFinca IN (
            SELECT F.numeroFinca
            FROM dbo.Factura F
            WHERE (F.periodo = DATEFROMPARTS(YEAR(@inFechaOperacion), MONTH(@inFechaOperacion), 1))
        );

        -- =============================================
        -- VALIDAR SI HAY PROPIEDADES
        -- =============================================
        
        DECLARE @cantidadPropiedades INT;
        SELECT @cantidadPropiedades = COUNT(*) FROM @tablaPropiedadesFacturar;

        IF (@cantidadPropiedades = 0)
        BEGIN
            
            SET @outCantidadFacturas = 0;
            
            PRINT '>> No hay propiedades para facturar en esta fecha';
            PRINT '';
            
            ROLLBACK TRANSACTION tGenerarFacturas;
            
            RETURN;
            
        END;


		-- =============================================
		-- CAPA 2 CORREGIDA: CÁLCULO DE CONSUMO DE AGUA
		-- =============================================

		PRINT '===================================================';
		PRINT 'CAPA 2: Calculando consumo de agua';
		PRINT '===================================================';
		PRINT '';

		-- OBTENER TARIFAS DE AGUA (idCC = 1)
		DECLARE @valorM3 MONEY;
		DECLARE @valorMinimo MONEY;

		SELECT 
			@valorM3 = ISNULL(CC.valorM3, 0),
			@valorMinimo = ISNULL(CC.valorMinimo, 0)
		FROM dbo.ConceptoCobro CC
		WHERE (CC.idCC = 1);

		-- Manejo elegante de tarifas faltantes
		IF (@valorM3 = 0 OR @valorMinimo = 0)
		BEGIN
			SET @valorM3 = 150.00;  -- ₡150 por m3 por defecto
			SET @valorMinimo = 1000.00;  -- ₡1000 mínimo por defecto
			PRINT '⚠️  ADVERTENCIA: Usando tarifas por defecto para agua';
		END;

		PRINT CONCAT('>> Tarifas agua: ₡', @valorM3, '/m³, Mínimo: ₡', @valorMinimo);
		PRINT '';

		-- INSERTAR DETALLES DE AGUA
		INSERT INTO @tablaDetallesFactura (
			numeroFinca, idCC, monto, descripcion
		)
		SELECT 
			TPF.numeroFinca,
			1,  -- idCC Agua
			ROUND(
				CASE 
					WHEN (ISNULL(TPF.m3Acumulados, 0) - ISNULL(TPF.m3AcumuladosUltimaFactura, 0)) <= 0 THEN @valorMinimo
					WHEN (ISNULL(TPF.m3Acumulados, 0) - ISNULL(TPF.m3AcumuladosUltimaFactura, 0)) * @valorM3 > @valorMinimo
					THEN (ISNULL(TPF.m3Acumulados, 0) - ISNULL(TPF.m3AcumuladosUltimaFactura, 0)) * @valorM3
					ELSE @valorMinimo
				END, 2
			) AS monto,
			CONCAT('Consumo de agua - ', 
				   CAST(GREATEST(ISNULL(TPF.m3Acumulados, 0) - ISNULL(TPF.m3AcumuladosUltimaFactura, 0), 0) AS VARCHAR(20)), 
				   ' m³') AS descripcion
		FROM @tablaPropiedadesFacturar TPF
		WHERE EXISTS (
			SELECT 1
			FROM dbo.PropiedadConceptoCobro PCC
			WHERE PCC.numeroFinca = TPF.numeroFinca
				AND PCC.idCC = 1
				AND PCC.activo = 1
		);

		-- RESULTADOS CAPA 2
		DECLARE @totalDetallesAgua INT;
		SELECT @totalDetallesAgua = COUNT(*) FROM @tablaDetallesFactura WHERE idCC = 1;

		PRINT CONCAT('>> Detalles agua generados: ', @totalDetallesAgua);
		SELECT numeroFinca, monto, descripcion 
		FROM @tablaDetallesFactura WHERE idCC = 1;

		PRINT '===================================================';
		PRINT 'CAPA 2 COMPLETADA';
		PRINT '===================================================';
		PRINT '';

 



 -- =============================================
-- CAPAS 3-6 CORREGIDAS: Optimización set-based completa
-- REEMPLAZAR DESDE CAPA 3 HASTA FINAL
-- =============================================

        -- =============================================
        -- CAPA 3: IMPUESTO PROPIEDAD (idCC = 3)
        -- CORRECCIÓN: Para TODAS las propiedades sin filtro
        -- =============================================
        
        PRINT '===================================================';
        PRINT 'CAPA 3: Calculando impuesto de propiedad';
        PRINT '===================================================';
        PRINT '';

        -- Obtener tarifa de impuesto (anual)
        DECLARE @porcentajeImpuesto DECIMAL(10,6);

        SELECT @porcentajeImpuesto = ISNULL(CC.valorPorcentaje, 0)
        FROM dbo.ConceptoCobro CC
        WHERE (CC.idCC = 3);

        -- Default: 1% anual si no encuentra tarifa
        IF (@porcentajeImpuesto = 0)
        BEGIN
            SET @porcentajeImpuesto = 0.01;
            PRINT '⚠️  ADVERTENCIA: Usando tarifa por defecto de impuesto (1% anual)';
        END;

        PRINT CONCAT('>> Tarifa impuesto: ', (@porcentajeImpuesto * 100), '% anual');
        PRINT '';

        -- CORRECCIÓN 1: Insertar para TODAS las propiedades (sin WHERE EXISTS)
        INSERT INTO @tablaDetallesFactura (
            numeroFinca, idCC, monto, descripcion
        )
        SELECT 
            TPF.numeroFinca,
            3,  -- idCC Impuesto
            ROUND((TPF.valorFiscal * @porcentajeImpuesto) / 12, 2),
            CONCAT('Impuesto propiedad - ', FORMAT(@porcentajeImpuesto * 100, 'N2'), '% anual')
        FROM @tablaPropiedadesFacturar TPF;  -- ✅ SIN FILTRO - TODAS las propiedades

        DECLARE @totalDetallesImpuesto INT;
        SELECT @totalDetallesImpuesto = COUNT(*) FROM @tablaDetallesFactura WHERE idCC = 3;

        PRINT CONCAT('>> Detalles impuesto generados: ', @totalDetallesImpuesto);
        PRINT '';

        -- =============================================
        -- CAPA 4: BASURA + PARQUES
        -- =============================================
        
        PRINT '===================================================';
        PRINT 'CAPA 4: Calculando basura y parques';
        PRINT '===================================================';
        PRINT '';

        -- Obtener tarifas
        DECLARE @valorFijoBasura MONEY;
        DECLARE @valorFijoParques MONEY;

        SELECT @valorFijoBasura = ISNULL(CC.valorFijo, 0)
        FROM dbo.ConceptoCobro CC
        WHERE (CC.idCC = 4);

        SELECT @valorFijoParques = ISNULL(CC.valorFijo, 0)
        FROM dbo.ConceptoCobro CC
        WHERE (CC.idCC = 5);

        -- Defaults
        IF (@valorFijoBasura = 0)
        BEGIN
            SET @valorFijoBasura = 300.00;
            PRINT '⚠️  ADVERTENCIA: Usando tarifa por defecto de basura (₡300)';
        END;

        IF (@valorFijoParques = 0)
        BEGIN
            SET @valorFijoParques = 2000.00;
            PRINT '⚠️  ADVERTENCIA: Usando tarifa por defecto de parques (₡2000)';
        END;

        PRINT CONCAT('>> Tarifa basura: ₡', @valorFijoBasura);
        PRINT CONCAT('>> Tarifa parques: ₡', @valorFijoParques);
        PRINT '';

        -- BASURA: Solo si zona ≠ Agrícola (idTipoZona ≠ 2) Y servicio activo
        INSERT INTO @tablaDetallesFactura (
            numeroFinca, idCC, monto, descripcion
        )
        SELECT 
            TPF.numeroFinca,
            4,  -- idCC Basura
            @valorFijoBasura,
            'Recolección de basura'
        FROM @tablaPropiedadesFacturar TPF
            INNER JOIN dbo.Propiedad P ON P.numeroFinca = TPF.numeroFinca
        WHERE (P.idTipoZona != 2)  -- No agrícola
            AND EXISTS (
                SELECT 1
                FROM dbo.PropiedadConceptoCobro PCC
                WHERE PCC.numeroFinca = TPF.numeroFinca
                    AND PCC.idCC = 4
                    AND PCC.activo = 1
            );

        -- PARQUES: Solo si zona Residencial(1) o Comercial(5) Y servicio activo
        INSERT INTO @tablaDetallesFactura (
            numeroFinca, idCC, monto, descripcion
        )
        SELECT 
            TPF.numeroFinca,
            5,  -- idCC Parques
            @valorFijoParques,
            'Mantenimiento de parques'
        FROM @tablaPropiedadesFacturar TPF
            INNER JOIN dbo.Propiedad P ON P.numeroFinca = TPF.numeroFinca
        WHERE (P.idTipoZona IN (1, 5))  -- Residencial o Comercial
            AND EXISTS (
                SELECT 1
                FROM dbo.PropiedadConceptoCobro PCC
                WHERE PCC.numeroFinca = TPF.numeroFinca
                    AND PCC.idCC = 5
                    AND PCC.activo = 1
            );

        DECLARE @totalDetallesBasura INT, @totalDetallesParques INT;
        SELECT @totalDetallesBasura = COUNT(*) FROM @tablaDetallesFactura WHERE idCC = 4;
        SELECT @totalDetallesParques = COUNT(*) FROM @tablaDetallesFactura WHERE idCC = 5;

        PRINT CONCAT('>> Detalles basura generados: ', @totalDetallesBasura);
        PRINT CONCAT('>> Detalles parques generados: ', @totalDetallesParques);
        PRINT '';

        -- =============================================
        -- CAPA 5: GENERACIÓN DE FACTURAS (OPTIMIZADA)
        -- CORRECCIÓN 2: Eliminar cursor, usar set-based
        -- =============================================
        
        PRINT '===================================================';
        PRINT 'CAPA 5: Generando facturas';
        PRINT '===================================================';
        PRINT '';

        -- Variables para generación
        DECLARE @periodo DATE;
        DECLARE @fechaEmision DATE;
        DECLARE @fechaVencimiento DATE;

        SET @periodo = DATEFROMPARTS(YEAR(@inFechaOperacion), MONTH(@inFechaOperacion), 1);
        SET @fechaEmision = @inFechaOperacion;
        SET @fechaVencimiento = DATEADD(DAY, 15, @inFechaOperacion);

        -- CORRECCIÓN 2: Insertar todas las facturas de una vez (set-based)
        INSERT INTO dbo.Factura (
            numeroFinca,
            numeroFactura,
            periodo,
            fechaEmision,
            fechaVencimiento,
            totalOriginal,
            totalAPagar,
            idEstadoFactura
        )
        SELECT 
            TPF.numeroFinca,
            CONCAT('FACT-', FORMAT(@inFechaOperacion, 'yyyyMM'), '-', TPF.numeroFinca) AS numeroFactura,
            @periodo,
            @fechaEmision,
            @fechaVencimiento,
            Totales.total AS totalOriginal,
            Totales.total AS totalAPagar,
            0  
        FROM @tablaPropiedadesFacturar TPF
        CROSS APPLY (
            SELECT ISNULL(SUM(monto), 0) AS total
            FROM @tablaDetallesFactura TDF
            WHERE TDF.numeroFinca = TPF.numeroFinca
        ) Totales;

        DECLARE @totalFacturasGeneradas INT = @@ROWCOUNT;

        PRINT CONCAT('>> Facturas insertadas: ', @totalFacturasGeneradas);
        PRINT '';

        -- CORRECCIÓN 3: Insertar todos los detalles de una vez (con descripcion)
        INSERT INTO dbo.FacturaDetalle (
			idFactura,
			idCC, 
			monto,
			descripcion  
		)
		SELECT 
			F.idFactura,
			TDF.idCC,
			TDF.monto,
			TDF.descripcion  
			INNER JOIN @tablaDetallesFactura TDF ON F.numeroFinca = TDF.numeroFinca
		WHERE (F.periodo = @periodo);

        DECLARE @totalDetallesGenerados INT = @@ROWCOUNT;

        PRINT CONCAT('>> Detalles insertados: ', @totalDetallesGenerados);
        PRINT '';

        -- Mostrar resumen de facturas generadas
        SELECT 
            F.numeroFactura,
            F.numeroFinca,
            F.totalOriginal,
            F.fechaVencimiento
        FROM dbo.Factura F
        WHERE (F.periodo = @periodo)
        ORDER BY F.numeroFinca;

        PRINT '';

        -- =============================================
        -- CAPA 6: ACTUALIZACIÓN + COMMIT
        -- =============================================
        
        PRINT '===================================================';
        PRINT 'CAPA 6: Actualizando y finalizando transacción';
        PRINT '===================================================';
        PRINT '';

        -- Actualizar m3AcumuladosUltimaFactura para propiedades facturadas
        UPDATE P
        SET P.m3AcumuladosUltimaFactura = P.m3Acumulados
        FROM dbo.Propiedad P
        WHERE P.numeroFinca IN (
            SELECT F.numeroFinca
            FROM dbo.Factura F
            WHERE F.periodo = @periodo
        );

        DECLARE @propiedadesActualizadas INT = @@ROWCOUNT;

        PRINT CONCAT('>> m3AcumuladosUltimaFactura actualizado: ', @propiedadesActualizadas, ' propiedades');
        PRINT '';

        SET @outCantidadFacturas = @totalFacturasGeneradas;

        IF (@@TRANCOUNT > 0)
        BEGIN
            COMMIT TRANSACTION tGenerarFacturas;
            PRINT '✅ Transacción COMMIT exitoso';
        END;


    END TRY
    BEGIN CATCH
        
        -- Rollback si hay error
        IF (@@TRANCOUNT > 0)
        BEGIN
            ROLLBACK TRANSACTION tGenerarFacturas;
        END;

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

        SET @outResultCode = 50606;
        SET @outCantidadFacturas = 0;
        
        PRINT CONCAT('ERROR: ', ERROR_MESSAGE());

    END CATCH;

    SET NOCOUNT OFF;
END;
GO