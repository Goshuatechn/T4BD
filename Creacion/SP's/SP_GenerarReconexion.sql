-- =============================================
-- SP_GenerarReconexion
-- =============================================

USE T3BD
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID('dbo.SP_GenerarReconexion', 'P') IS NOT NULL
    DROP PROCEDURE dbo.SP_GenerarReconexion;
GO

CREATE PROCEDURE dbo.SP_GenerarReconexion
    @inNumeroFinca VARCHAR(30)
    , @inIdPago INT
    , @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        
        SET @outResultCode = 0;

        -- =============================================
        -- VALIDACIONES
        -- =============================================
        
        -- Validar que propiedad exista
        IF NOT EXISTS (
            SELECT 1 
            FROM dbo.Propiedad P
            WHERE (P.numeroFinca = @inNumeroFinca)
                AND (P.activo = 1)
        )
        BEGIN
            SET @outResultCode = 50401;
            RETURN;
        END;

        -- Validar que pago exista
        IF NOT EXISTS (
            SELECT 1 
            FROM dbo.Pago P
            WHERE (P.idPago = @inIdPago)
        )
        BEGIN
            SET @outResultCode = 50402;
            RETURN;
        END;

        -- =============================================
        -- VERIFICAR SI TIENE ORDEN DE CORTE ACTIVA
        -- =============================================
        
        DECLARE @idOrdenCorte INT;

        SELECT @idOrdenCorte = OC.idOrdenCorte
        FROM dbo.OrdenCorte OC
        WHERE (OC.numeroFinca = @inNumeroFinca)
            AND (OC.idEstadoOrden = 0);

        -- Si no tiene orden de corte activa, no proceder
        IF (@idOrdenCorte IS NULL)
        BEGIN
            SET @outResultCode = 50403;
            RETURN;
        END;

        -- =============================================
        -- VERIFICAR QUE NO TENGA FACTURAS PENDIENTES
        -- =============================================
        
        DECLARE @cantidadPendientes INT;

        SELECT @cantidadPendientes = COUNT(*)
        FROM dbo.Factura F
        WHERE (F.numeroFinca = @inNumeroFinca)
            AND (F.idEstadoFactura = 0);

        IF (@cantidadPendientes > 0)
        BEGIN
            SET @outResultCode = 50404;
            RETURN;
        END;

        -- =============================================
        -- TRANSACCION: Crear reconexion y cerrar orden
        -- =============================================
        
        BEGIN TRANSACTION tGenerarReconexion;

            INSERT INTO dbo.Reconexion (
                idOrdenCorte
                , idPago
                , fechaSolicitud
            )
            VALUES (
                @idOrdenCorte
                , @inIdPago
                , GETDATE()
            );

            UPDATE dbo.OrdenCorte
            SET idEstadoOrden = 1
                , fechaEjecucion = GETDATE()
            WHERE (idOrdenCorte = @idOrdenCorte);

        COMMIT TRANSACTION tGenerarReconexion;

    END TRY
    BEGIN CATCH
        
        IF (@@TRANCOUNT > 0)
        BEGIN
            ROLLBACK TRANSACTION tGenerarReconexion;
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

        SET @outResultCode = 50406;

    END CATCH;

    SET NOCOUNT OFF;
END;
GO