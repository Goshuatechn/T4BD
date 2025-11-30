-- =============================================
-- SP_CalcularInteresesMoratorios 
-- =============================================

USE T3BD
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID('dbo.SP_CalcularInteresesMoratorios', 'P') IS NOT NULL
    DROP PROCEDURE dbo.SP_CalcularInteresesMoratorios;
GO

CREATE PROCEDURE dbo.SP_CalcularInteresesMoratorios
    @inIdFactura INT
    , @inFechaActual DATE
    , @outMontoInteres MONEY OUTPUT
    , @outDiasVencidos INT OUTPUT
    , @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        
        SET @outResultCode = 0;
        SET @outMontoInteres = 0;
        SET @outDiasVencidos = 0;

        -- =============================================
        -- VALIDACIONES
        -- =============================================
        
        -- Validar que factura exista
        IF NOT EXISTS (
            SELECT 1 
            FROM dbo.Factura F
            WHERE (F.idFactura = @inIdFactura)
        )
        BEGIN
            SET @outResultCode = 50101;  -- Factura no existe
            RETURN;
        END;

        -- =============================================
        -- OBTENER DATOS DE FACTURA
        -- =============================================
        
        DECLARE @fechaVencimiento DATE;
        DECLARE @totalOriginal MONEY;
        DECLARE @porcentajeMensual DECIMAL(10,6);

        SELECT 
            @fechaVencimiento = F.fechaVencimiento
            , @totalOriginal = F.totalOriginal
        FROM dbo.Factura F
        WHERE (F.idFactura = @inIdFactura);

        -- Obtener porcentaje mensual del CC InteresesMoratorios (idCC=7)
        SELECT @porcentajeMensual = CC.valorPorcentaje
        FROM dbo.ConceptoCobro CC
        WHERE (CC.idCC = 7)
            AND (CC.esInteresMoratorio = 1);

        -- Si no est� vencida, retornar 0
        IF (@inFechaActual <= @fechaVencimiento)
        BEGIN
            SET @outMontoInteres = 0;
            SET @outDiasVencidos = 0;
            RETURN;
        END;

        -- =============================================
        -- CALCULAR INTERESES 
        -- =============================================
        
        -- Calcular d�as vencidos
        SET @outDiasVencidos = DATEDIFF(DAY, @fechaVencimiento, @inFechaActual);

        -- Porcentaje en BD: 0.040000 (4% mensual)
        
        DECLARE @porcentajeDiario DECIMAL(10,6);
        SET @porcentajeDiario = @porcentajeMensual / 30.0;

        SET @outMontoInteres = ROUND(@totalOriginal * 0.04 * @outDiasVencidos / 30, 2);

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

        SET @outResultCode = 50106;  -- Error general

    END CATCH;

    SET NOCOUNT OFF;
END;
GO