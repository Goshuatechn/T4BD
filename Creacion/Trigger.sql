USE T3BD
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID('dbo.TR_Propiedad_AsignarCCs', 'TR') IS NOT NULL
    DROP TRIGGER dbo.TR_Propiedad_AsignarCCs;
GO

CREATE TRIGGER dbo.TR_Propiedad_AsignarCCs
ON dbo.Propiedad
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        
        -- =============================================
        -- REGLA 1: SIEMPRE asignar Impuesto Propiedad
        -- idCC = 3
        -- =============================================
        INSERT INTO dbo.PropiedadConceptoCobro (
            numeroFinca
            , idCC
            , activo
            , fechaAsignacion
        )
        SELECT 
            I.numeroFinca
            , 3
            , 1
            , GETDATE()
        FROM INSERTED I
        WHERE NOT EXISTS (
            SELECT 1 
            FROM dbo.PropiedadConceptoCobro PCC
            WHERE (PCC.numeroFinca = I.numeroFinca)
                AND (PCC.idCC = 3)
        );

        -- =============================================
        -- REGLA 2: Consumo Agua SI uso residencial,
        --          comercial o industrial
        -- idCC = 1
        -- idTipoUso: 1=habitación, 2=comercial, 3=industrial
        -- =============================================
        INSERT INTO dbo.PropiedadConceptoCobro (
            numeroFinca
            , idCC
            , activo
            , fechaAsignacion
        )
        SELECT 
            I.numeroFinca
            , 1
            , 1
            , GETDATE()
        FROM INSERTED I
        WHERE (I.idTipoUso IN (1, 2, 3))
            AND NOT EXISTS (
                SELECT 1 
                FROM dbo.PropiedadConceptoCobro PCC
                WHERE (PCC.numeroFinca = I.numeroFinca)
                    AND (PCC.idCC = 1)
            );

        -- =============================================
        -- idCC = 4
        -- =============================================
        INSERT INTO dbo.PropiedadConceptoCobro (
            numeroFinca
            , idCC
            , activo
            , fechaAsignacion
        )
        SELECT 
            I.numeroFinca
            , 4
            , 1
            , GETDATE()
        FROM INSERTED I
        WHERE (I.idTipoZona != 2)
            AND NOT EXISTS (
                SELECT 1 
                FROM dbo.PropiedadConceptoCobro PCC
                WHERE (PCC.numeroFinca = I.numeroFinca)
                    AND (PCC.idCC = 4)
            );

        -- =============================================
        -- REGLA 4: Mantenimiento Parques SI zona
        --          residencial o comercial
        -- idCC = 5
        -- idTipoZona: 1=residencial, 5=comercial
        -- =============================================
        INSERT INTO dbo.PropiedadConceptoCobro (
            numeroFinca
            , idCC
            , activo
            , fechaAsignacion
        )
        SELECT 
            I.numeroFinca
            , 5
            , 1
            , GETDATE()
        FROM INSERTED I
        WHERE (I.idTipoZona IN (1, 5))
            AND NOT EXISTS (
                SELECT 1 
                FROM dbo.PropiedadConceptoCobro PCC
                WHERE (PCC.numeroFinca = I.numeroFinca)
                    AND (PCC.idCC = 5)
            );

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

        THROW;

    END CATCH;

    SET NOCOUNT OFF;
END;
GO

GO