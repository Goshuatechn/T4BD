USE T3BD
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET NOCOUNT ON
GO

BEGIN TRY

    PRINT '===================================================';
    PRINT 'INICIANDO CARGA DE CAT�LOGOS';
    PRINT '===================================================';
    PRINT '';

    -- =============================================
    -- TIPO DOCUMENTO IDENTIDAD
    -- =============================================
    
    INSERT INTO dbo.TipoDocumentoIdentidad (
        idTipoDocumento
        , nombre
    )
    VALUES (
        1
        , 'C�dula Nacional'
    );


    -- =============================================
    -- TIPO USO PROPIEDAD
    -- =============================================
    
    INSERT INTO dbo.TipoUso (
        idTipoUso
        , nombre
    )
    VALUES 
        (1, 'Habitaci�n')
        , (2, 'Comercial')
        , (3, 'Industrial')
        , (4, 'Lote Bald�o')
        , (5, 'Agr�cola');


    -- =============================================
    -- TIPO ZONA PROPIEDAD
    -- =============================================
    
    INSERT INTO dbo.TipoZona (
        idTipoZona
        , nombre
    )
    VALUES 
        (1, 'Residencial')
        , (2, 'Agr�cola')
        , (3, 'Bosque')
        , (4, 'Industrial')
        , (5, 'Comercial');

    -- =============================================
    -- TIPO MOVIMIENTO MEDIDOR
    -- =============================================
    
    INSERT INTO dbo.TipoMovimiento (
        idTipoMovimiento
        , nombre
    )
    VALUES 
        (1, 'Lectura')
        , (2, 'Ajuste Cr�dito')
        , (3, 'Ajuste D�bito');


    -- =============================================
    -- TIPO USUARIO
    -- =============================================
    
    INSERT INTO dbo.TipoUsuario (
        idTipoUsuario
        , nombre
    )
    VALUES 
        (0, 'Administrador')
        , (1, 'Propietario');

    -- =============================================
    -- TIPO ASOCIACION
    -- =============================================
    
    INSERT INTO dbo.TipoAsociacion (
        idTipoAsociacion
        , nombre
    )
    VALUES 
        (1, 'Asociar')
        , (2, 'Desasociar');


    -- =============================================
    -- MEDIO PAGO
    -- =============================================
    
    INSERT INTO dbo.MedioPago (
        idMedioPago
        , nombre
    )
    VALUES 
        (1, 'Efectivo')
        , (2, 'Tarjeta');


    -- =============================================
    -- ESTADO FACTURA
    -- =============================================
    
    INSERT INTO dbo.EstadoFactura (
        idEstadoFactura
        , nombre
    )
    VALUES 
        (0, 'Pendiente')
        , (1, 'Pagado');


    -- =============================================
    -- ESTADO ORDEN
    -- =============================================
    
    INSERT INTO dbo.EstadoOrden (
        idEstadoOrden
        , nombre
    )
    VALUES 
        (0, 'Pendiente')
        , (1, 'Ejecutado');


    -- =============================================
    -- TIPO ENTIDAD
    -- =============================================
    
    INSERT INTO dbo.TipoEntidad (
        idTipoEntidad
        , nombre
    )
    VALUES 
        (1, 'Propiedad')
        , (2, 'Propietario')
        , (3, 'Usuario')
        , (4, 'PropiedadPropietario')
        , (5, 'PropiedadUsuario')
        , (6, 'PropietarioJuridico')
        , (7, 'ConceptoCobro');


    -- =============================================
    -- PERIODO MONTO CC
    -- =============================================
    
    INSERT INTO dbo.PeriodoMontoCC (
        idPeriodo
        , nombre
        , cantidadMeses
    )
    VALUES 
        (1, 'Mensual', 1)
        , (2, 'Trimestral', 3)
        , (3, 'Semestral', 6)
        , (4, 'Anual', 12)
        , (5, '�nico', 1)
        , (6, 'Diario', 1);


    -- =============================================
    -- TIPO MONTO CC
    -- =============================================
    
    INSERT INTO dbo.TipoMontoCC (
        idTipoMonto
        , nombre
    )
    VALUES 
        (1, 'Monto Fijo')
        , (2, 'Monto Variable')
        , (3, 'Porcentaje');


    -- =============================================
    -- CONCEPTOS DE COBRO 
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
    VALUES 
        -- CC 1: Consumo Agua
        (
            1
            , 'ConsumoAgua'
            , 2
            , 1
            , NULL
            , NULL
            , 5000.00
            , 30.00
            , NULL
            , 1000.00
            , NULL
            , NULL
            , 1
            , 0
            , 0
        )
        -- CC 2: Patente Comercial
        , (
            2
            , 'PatenteComercial'
            , 1
            , 3
            , 150000.00
            , NULL
            , NULL
            , NULL
            , NULL
            , NULL
            , NULL
            , NULL
            , 1
            , 0
            , 0
        )
        -- CC 3: Impuesto Propiedad
        , (
            3
            , 'ImpuestoPropiedad'
            , 3
            , 4
            , NULL
            , 0.010000
            , NULL
            , NULL
            , NULL
            , NULL
            , NULL
            , NULL
            , 1
            , 0
            , 0
        )
        -- CC 4: Recolecci�n Basura
        , (
            4
            , 'RecoleccionBasura'
            , 1
            , 1
            , 300.00
            , NULL
            , 150.00
            , NULL
            , NULL
            , NULL
            , 400.00
            , 75.00
            , 1
            , 0
            , 0
        )
        -- CC 5: Mantenimiento Parques
        , (
            5
            , 'MantenimientoParques'
            , 1
            , 1
            , 2000.00
            , NULL
            , NULL
            , NULL
            , NULL
            , NULL
            , NULL
            , NULL
            , 1
            , 0
            , 0
        )
        -- CC 6: Reconexi�n Agua
        , (
            6
            , 'ReconexionAgua'
            , 1
            , 5
            , 30000.00
            , NULL
            , NULL
            , NULL
            , NULL
            , NULL
            , NULL
            , NULL
            , 0
            , 0
            , 1
        )
        -- CC 7: Intereses Moratorios
        , (
            7
            , 'InteresesMoratorios'
            , 3
            , 6
            , NULL
            , 0.040000
            , NULL
            , NULL
            , NULL
            , NULL
            , NULL
            , NULL
            , 0
            , 1
            , 0
        );

    PRINT 'CAT�LOGOS CARGADOS EXITOSAMENTE';

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

    PRINT 'ERROR: ' + ERROR_MESSAGE();

END CATCH;

SET NOCOUNT OFF;
GO