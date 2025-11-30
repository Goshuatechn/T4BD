-- =============================================
-- SP_RegistrarPagoFactura
-- =============================================

USE T3BD
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID('dbo.SP_RegistrarPagoFactura', 'P') IS NOT NULL
    DROP PROCEDURE dbo.SP_RegistrarPagoFactura;
GO

CREATE PROCEDURE dbo.SP_RegistrarPagoFactura
    @inNumeroFinca VARCHAR(30)
    , @inTipoMedioPago INT
    , @inNumeroReferencia VARCHAR(100)
    , @inFechaPago DATE
    , @outIdPago INT OUTPUT
    , @outIdFactura INT OUTPUT
    , @outMontoTotal MONEY OUTPUT
    , @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        
        SET @outResultCode = 0;
        SET @outIdPago = 0;
        SET @outIdFactura = 0;
        SET @outMontoTotal = 0;

        
        -- Validar que propiedad exista
        IF NOT EXISTS (
            SELECT 1 
            FROM dbo.Propiedad P
            WHERE (P.numeroFinca = @inNumeroFinca)
                AND (P.activo = 1)
        )
        BEGIN
            SET @outResultCode = 50201;  -- Propiedad no existe
            RETURN;
        END;

        -- Validar medio de pago
        IF NOT EXISTS (
            SELECT 1 
            FROM dbo.MedioPago MP
            WHERE (MP.idMedioPago = @inTipoMedioPago)
        )
        BEGIN
            SET @outResultCode = 50202;  -- Medio de pago inv�lido
            RETURN;
        END;

        -- Validar que tenga facturas pendientes
        IF NOT EXISTS (
            SELECT 1 
            FROM dbo.Factura F
            WHERE (F.numeroFinca = @inNumeroFinca)
                AND (F.idEstadoFactura = 0)
        )
        BEGIN
            SET @outResultCode = 50203;  -- No hay facturas pendientes
            RETURN;
        END;
        
        DECLARE @fechaVencimiento DATE;
        DECLARE @totalOriginal MONEY;
        DECLARE @totalAPagar MONEY;

        SELECT TOP 1
            @outIdFactura = F.idFactura
            , @fechaVencimiento = F.fechaVencimiento
            , @totalOriginal = F.totalOriginal
            , @totalAPagar = F.totalAPagar
        FROM dbo.Factura F
        WHERE (F.numeroFinca = @inNumeroFinca)
            AND (F.idEstadoFactura = 0)
        ORDER BY F.fechaEmision ASC;

        DECLARE @montoInteres MONEY;
        DECLARE @diasVencidos INT;
        DECLARE @resultado INT;

        SET @montoInteres = 0;

        IF (@inFechaPago > @fechaVencimiento)
        BEGIN
            
            -- Llamar SP auxiliar para calcular intereses
            EXEC dbo.SP_CalcularInteresesMoratorios
                @inIdFactura = @outIdFactura
                , @inFechaActual = @inFechaPago
                , @outMontoInteres = @montoInteres OUTPUT
                , @outDiasVencidos = @diasVencidos OUTPUT
                , @outResultCode = @resultado OUTPUT;

            IF (@resultado != 0)
            BEGIN
                SET @outResultCode = @resultado;
                RETURN;
            END;

        END;

        BEGIN TRANSACTION tRegistrarPago

            -- Si hay intereses, agregar detalle a la factura
            IF (@montoInteres > 0)
            BEGIN
                
                -- Insertar detalle de inter�s moratorio
                INSERT INTO dbo.FacturaDetalle (
                    idFactura
                    , idCC
                    , monto
                )
                VALUES (
                    @outIdFactura
                    , 7  -- InteresesMoratorios
                    , @montoInteres
                );

                -- Actualizar totalAPagar de la factura
                UPDATE dbo.Factura
                SET totalAPagar = totalAPagar + @montoInteres
                WHERE (idFactura = @outIdFactura);

                -- Actualizar variable local
                SET @totalAPagar = @totalAPagar + @montoInteres;

            END;

            -- Establecer monto total del pago (siempre es el total completo)
            SET @outMontoTotal = @totalAPagar;

            DECLARE @numeroComprobante VARCHAR(50);
            SET @numeroComprobante = CONCAT(
                'COMP-'
                , FORMAT(@inFechaPago, 'yyyyMMdd')
                , '-'
                , @inNumeroFinca
                , '-'
                , @outIdFactura
            );

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
                @inNumeroFinca
                , @outIdFactura
                , @inTipoMedioPago
                , @numeroComprobante
                , @inNumeroReferencia
                , @inFechaPago
                , @outMontoTotal
            );

            -- Obtener ID del pago insertado
            SET @outIdPago = SCOPE_IDENTITY();

            UPDATE dbo.Factura
            SET idEstadoFactura = 1  -- Pagado
            WHERE (idFactura = @outIdFactura);

        COMMIT TRANSACTION tRegistrarPago;

    END TRY
    BEGIN CATCH
        
        IF (@@TRANCOUNT > 0)
        BEGIN
            ROLLBACK TRANSACTION tRegistrarPago;
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

        SET @outResultCode = 50206;  -- Error general

    END CATCH;

    SET NOCOUNT OFF;
END;
GO