-- =============================================
-- SP_GenerarOrdenesCorte 
-- =============================================

USE T3BD
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID('dbo.SP_GenerarOrdenesCorte', 'P') IS NOT NULL
    DROP PROCEDURE dbo.SP_GenerarOrdenesCorte;
GO

CREATE PROCEDURE dbo.SP_GenerarOrdenesCorte
    @inFechaOperacion DATE
    , @outCantidadCortes INT OUTPUT
    , @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        
        SET @outResultCode = 0;
        SET @outCantidadCortes = 0;

        -- =============================================
        -- IDENTIFICAR PROPIEDADES CON 2+ FACTURAS PENDIENTES
        -- Que tengan servicio de agua (idCC=1)
        -- =============================================
        
        DECLARE @tablaPropiedadesCorte TABLE (
            numeroFinca VARCHAR(30)
            , cantidadFacturasPendientes INT
            , idFacturaMasVieja INT
        );

        INSERT INTO @tablaPropiedadesCorte (
            numeroFinca
            , cantidadFacturasPendientes
            , idFacturaMasVieja
        )
        SELECT 
            F.numeroFinca
            , COUNT(*) AS CantidadPendientes
            , MIN(F.idFactura) AS FacturaMasVieja
        FROM dbo.Factura F
        WHERE (F.idEstadoFactura = 0)
            AND EXISTS (
                SELECT 1
                FROM dbo.PropiedadConceptoCobro PCC
                WHERE (PCC.numeroFinca = F.numeroFinca)
                    AND (PCC.idCC = 1)
                    AND (PCC.activo = 1)
            )
            AND NOT EXISTS (
                SELECT 1
                FROM dbo.OrdenCorte OC
                WHERE (OC.numeroFinca = F.numeroFinca)
                    AND (OC.idEstadoOrden = 0)
            )
        GROUP BY F.numeroFinca
        HAVING COUNT(*) >= 2;

        -- Si no hay propiedades para corte, salir
        IF NOT EXISTS (SELECT 1 FROM @tablaPropiedadesCorte)
        BEGIN
            SET @outCantidadCortes = 0;
            RETURN;
        END;

        -- =============================================
        -- OBTENER MONTO RECONEXION
        -- =============================================
        
        DECLARE @montoReconexion MONEY;

        SELECT @montoReconexion = CC.valorFijo
        FROM dbo.ConceptoCobro CC
        WHERE (CC.idCC = 6)
            AND (CC.esReconexion = 1);

        -- Si no encuentra monto, usar valor por defecto
        IF (@montoReconexion IS NULL)
            SET @montoReconexion = 30000.00;

        
        BEGIN TRANSACTION tGenerarCortes;

            -- 1. INSERTAR ORDENES DE CORTE
            INSERT INTO dbo.OrdenCorte (
                numeroFinca
                , idFacturaOrigen
                , fechaCreacion
                , idEstadoOrden
            )
            SELECT 
                numeroFinca
                , idFacturaMasVieja
                , @inFechaOperacion
                , 0
            FROM @tablaPropiedadesCorte;

            -- 2. CONTAR ORDENES CREADAS (CRITICO)
            SET @outCantidadCortes = @@ROWCOUNT;

            -- 3. AGREGAR CARGO DE RECONEXION A FACTURAS
            INSERT INTO dbo.FacturaDetalle (
                idFactura
                , idCC
                , monto
                , descripcion
            )
            SELECT 
                idFacturaMasVieja
                , 6  -- ReconexionAgua
                , @montoReconexion
                , 'Cargo por reconexi�n de servicio'
            FROM @tablaPropiedadesCorte;

            -- 4. ACTUALIZAR TOTALES DE FACTURAS
            UPDATE F 
            SET totalAPagar = totalAPagar + @montoReconexion
            FROM dbo.Factura F
            INNER JOIN @tablaPropiedadesCorte TPC ON F.idFactura = TPC.idFacturaMasVieja;

        COMMIT TRANSACTION tGenerarCortes;

        PRINT CONCAT('SP_GenerarOrdenesCorte: ', @outCantidadCortes, ' �rdenes creadas');  -- Para debugging QUITAR LUEGO

    END TRY
    BEGIN CATCH
        
        IF (@@TRANCOUNT > 0)
        BEGIN
            ROLLBACK TRANSACTION tGenerarCortes;
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

        SET @outResultCode = 50301;
        SET @outCantidadCortes = 0;  -- Asegurar que sea 0 en error

    END CATCH;

    SET NOCOUNT OFF;
END;
GO