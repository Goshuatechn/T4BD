-- =============================================
-- SP_RegistrarLecturaAgua 
-- =============================================

USE T3BD
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID('dbo.SP_RegistrarLecturaAgua', 'P') IS NOT NULL
    DROP PROCEDURE dbo.SP_RegistrarLecturaAgua;
GO

CREATE PROCEDURE dbo.SP_RegistrarLecturaAgua
    @inNumeroMedidor VARCHAR(50)
    , @inTipoMovimiento INT
    , @inValor DECIMAL(12,2)
    , @inFechaLectura DATE
    , @outNuevoSaldo DECIMAL(12,2) OUTPUT
    , @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        
        SET @outResultCode = 0;
        SET @outNuevoSaldo = 0;

        
        -- Validar que medidor exista
        IF NOT EXISTS (
            SELECT 1 
            FROM dbo.Medidor M
            WHERE (M.numeroMedidor = @inNumeroMedidor)
                AND (M.activo = 1)
        )
        BEGIN
            SET @outResultCode = 50001;  -- Medidor no existe o inactivo
            RETURN;
        END;

        -- Validar tipo de movimiento
        IF NOT EXISTS (
            SELECT 1 
            FROM dbo.TipoMovimiento TM
            WHERE (TM.idTipoMovimiento = @inTipoMovimiento)
        )
        BEGIN
            SET @outResultCode = 50002;  -- Tipo movimiento invalido
            RETURN;
        END;

        -- Validar que valor sea positivo (NO cero)
        IF (@inValor <= 0)
        BEGIN
            SET @outResultCode = 50003;  -- Valor debe ser mayor a cero
            RETURN;
        END;
        
        DECLARE @fechaUltimaLectura DATE;

        SELECT @fechaUltimaLectura = M.fechaUltimaLectura
        FROM dbo.Medidor M
        WHERE (M.numeroMedidor = @inNumeroMedidor);

        IF (@fechaUltimaLectura IS NOT NULL)
            AND (@inFechaLectura < @fechaUltimaLectura)
        BEGIN
            SET @outResultCode = 50007;  -- Fecha anterior a ultima lectura
            RETURN;
        END;


        -- PREPROCESO: Obtener saldo actual y calcular nuevo saldo
        
        DECLARE @saldoActual DECIMAL(12,2);
        DECLARE @numeroFinca VARCHAR(30);
        DECLARE @valorMovimiento DECIMAL(12,2);

        SELECT 
            @saldoActual = M.saldoAcumulado
            , @numeroFinca = M.numeroFinca
        FROM dbo.Medidor M
        WHERE (M.numeroMedidor = @inNumeroMedidor);

        -- Calcular según tipo de movimiento
        IF (@inTipoMovimiento = 1)
        BEGIN
            -- Tipo 1: Lectura normal
            SET @valorMovimiento = @inValor - @saldoActual;
            SET @outNuevoSaldo = @inValor;
        END
        ELSE IF (@inTipoMovimiento = 2)
        BEGIN
            -- Tipo 2: Ajuste Crédito (resta del saldo)
            SET @valorMovimiento = -@inValor;
            SET @outNuevoSaldo = @saldoActual - @inValor;
        END
        ELSE IF (@inTipoMovimiento = 3)
        BEGIN
            -- Tipo 3: Ajuste Débito (suma al saldo)
            SET @valorMovimiento = @inValor;
            SET @outNuevoSaldo = @saldoActual + @inValor;
        END
        ELSE
        BEGIN
            SET @outResultCode = 50004;  -- Tipo no reconocido
            RETURN;
        END;

        -- Validar que nuevo saldo no sea negativo
        IF (@outNuevoSaldo < 0)
        BEGIN
            SET @outResultCode = 50005;  -- Saldo negativo resultante
            RETURN;
        END;

        -- TRANSACCION: Insertar movimiento y actualizar saldos

        
        BEGIN TRANSACTION tRegistrarLectura

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
                @inNumeroMedidor
                , @inTipoMovimiento
                , @inFechaLectura
                , @valorMovimiento
                , @saldoActual
                , @outNuevoSaldo
            );

            -- Actualizar saldo del medidor
            UPDATE dbo.Medidor
            SET saldoAcumulado = @outNuevoSaldo
                , fechaUltimaLectura = @inFechaLectura
            WHERE (numeroMedidor = @inNumeroMedidor);

            -- Actualizar m3Acumulados en Propiedad
            UPDATE dbo.Propiedad
            SET m3Acumulados = @outNuevoSaldo
            WHERE (numeroFinca = @numeroFinca);

        COMMIT TRANSACTION tRegistrarLectura;

    END TRY
    BEGIN CATCH
        
        IF (@@TRANCOUNT > 0)
        BEGIN
            ROLLBACK TRANSACTION tRegistrarLectura;
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

        SET @outResultCode = 50006;  -- Error general BD

    END CATCH;

    SET NOCOUNT OFF;
END;
GO