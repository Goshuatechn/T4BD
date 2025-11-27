USE T3BD
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- 1. CATÁLOGOS DEL SISTEMA 
-- =============================================

-- Tipo de Documento de Identidad
IF OBJECT_ID('dbo.TipoDocumentoIdentidad', 'U') IS NOT NULL 
    DROP TABLE dbo.TipoDocumentoIdentidad;
GO

CREATE TABLE dbo.TipoDocumentoIdentidad (
    idTipoDocumento INT NOT NULL
    , nombre VARCHAR(50) NOT NULL
    , CONSTRAINT PK_TipoDocumentoIdentidad 
        PRIMARY KEY CLUSTERED (idTipoDocumento)
);
GO

-- Tipo de Uso de Propiedad
IF OBJECT_ID('dbo.TipoUso', 'U') IS NOT NULL 
    DROP TABLE dbo.TipoUso;
GO

CREATE TABLE dbo.TipoUso (
    idTipoUso INT NOT NULL
    , nombre VARCHAR(50) NOT NULL
    , CONSTRAINT PK_TipoUso 
        PRIMARY KEY CLUSTERED (idTipoUso)
);
GO

-- Tipo de Zona de Propiedad
IF OBJECT_ID('dbo.TipoZona', 'U') IS NOT NULL 
    DROP TABLE dbo.TipoZona;
GO

CREATE TABLE dbo.TipoZona (
    idTipoZona INT NOT NULL
    , nombre VARCHAR(50) NOT NULL
    , CONSTRAINT PK_TipoZona 
        PRIMARY KEY CLUSTERED (idTipoZona)
);
GO

-- Tipo de Movimiento de Medidor
IF OBJECT_ID('dbo.TipoMovimiento', 'U') IS NOT NULL 
    DROP TABLE dbo.TipoMovimiento;
GO

CREATE TABLE dbo.TipoMovimiento (
    idTipoMovimiento INT NOT NULL
    , nombre VARCHAR(50) NOT NULL
    , CONSTRAINT PK_TipoMovimiento 
        PRIMARY KEY CLUSTERED (idTipoMovimiento)
);
GO

-- Tipo de Usuario
IF OBJECT_ID('dbo.TipoUsuario', 'U') IS NOT NULL 
    DROP TABLE dbo.TipoUsuario;
GO

CREATE TABLE dbo.TipoUsuario (
    idTipoUsuario INT NOT NULL
    , nombre VARCHAR(50) NOT NULL
    , CONSTRAINT PK_TipoUsuario 
        PRIMARY KEY CLUSTERED (idTipoUsuario)
);
GO

-- Tipo de Asociación
IF OBJECT_ID('dbo.TipoAsociacion', 'U') IS NOT NULL 
    DROP TABLE dbo.TipoAsociacion;
GO

CREATE TABLE dbo.TipoAsociacion (
    idTipoAsociacion INT NOT NULL
    , nombre VARCHAR(50) NOT NULL
    , CONSTRAINT PK_TipoAsociacion 
        PRIMARY KEY CLUSTERED (idTipoAsociacion)
);
GO

-- Medio de Pago
IF OBJECT_ID('dbo.MedioPago', 'U') IS NOT NULL 
    DROP TABLE dbo.MedioPago;
GO

CREATE TABLE dbo.MedioPago (
    idMedioPago INT NOT NULL
    , nombre VARCHAR(50) NOT NULL
    , CONSTRAINT PK_MedioPago 
        PRIMARY KEY CLUSTERED (idMedioPago)
);
GO

-- Estado de Factura
IF OBJECT_ID('dbo.EstadoFactura', 'U') IS NOT NULL 
    DROP TABLE dbo.EstadoFactura;
GO

CREATE TABLE dbo.EstadoFactura (
    idEstadoFactura INT NOT NULL
    , nombre VARCHAR(50) NOT NULL
    , CONSTRAINT PK_EstadoFactura 
        PRIMARY KEY CLUSTERED (idEstadoFactura)
);
GO

-- Estado de Orden
IF OBJECT_ID('dbo.EstadoOrden', 'U') IS NOT NULL 
    DROP TABLE dbo.EstadoOrden;
GO

CREATE TABLE dbo.EstadoOrden (
    idEstadoOrden INT NOT NULL
    , nombre VARCHAR(50) NOT NULL
    , CONSTRAINT PK_EstadoOrden 
        PRIMARY KEY CLUSTERED (idEstadoOrden)
);
GO

-- Tipo de Entidad
IF OBJECT_ID('dbo.TipoEntidad', 'U') IS NOT NULL 
    DROP TABLE dbo.TipoEntidad;
GO

CREATE TABLE dbo.TipoEntidad (
    idTipoEntidad INT NOT NULL
    , nombre VARCHAR(50) NOT NULL
    , CONSTRAINT PK_TipoEntidad 
        PRIMARY KEY CLUSTERED (idTipoEntidad)
);
GO

-- Periodo de Monto para Conceptos de Cobro
IF OBJECT_ID('dbo.PeriodoMontoCC', 'U') IS NOT NULL 
    DROP TABLE dbo.PeriodoMontoCC;
GO

CREATE TABLE dbo.PeriodoMontoCC (
    idPeriodo INT NOT NULL
    , nombre VARCHAR(50) NOT NULL
    , cantidadMeses INT NOT NULL
    , CONSTRAINT PK_PeriodoMontoCC 
        PRIMARY KEY CLUSTERED (idPeriodo)
);
GO

-- Tipo de Monto para Conceptos de Cobro
IF OBJECT_ID('dbo.TipoMontoCC', 'U') IS NOT NULL 
    DROP TABLE dbo.TipoMontoCC;
GO

CREATE TABLE dbo.TipoMontoCC (
    idTipoMonto INT NOT NULL
    , nombre VARCHAR(50) NOT NULL
    , CONSTRAINT PK_TipoMontoCC 
        PRIMARY KEY CLUSTERED (idTipoMonto)
);
GO

-- Conceptos de Cobro
IF OBJECT_ID('dbo.ConceptoCobro', 'U') IS NOT NULL 
    DROP TABLE dbo.ConceptoCobro;
GO

CREATE TABLE dbo.ConceptoCobro (
    idCC INT NOT NULL
    , nombre VARCHAR(100) NOT NULL
    , idTipoMontoCC INT NOT NULL
    , idPeriodoMontoCC INT NOT NULL
    , valorFijo MONEY NULL
    , valorPorcentaje DECIMAL(10,6) NULL
    , valorMinimo MONEY NULL
    , valorMinimoM3 DECIMAL(10,2) NULL
    , valorM3 MONEY NULL
    , valorFijoM3Adicional MONEY NULL
    , valorM2Minimo DECIMAL(10,2) NULL
    , valorTractosM2 DECIMAL(10,2) NULL
    , esRecurrente BIT NOT NULL DEFAULT 1
    , esInteresMoratorio BIT NOT NULL DEFAULT 0
    , esReconexion BIT NOT NULL DEFAULT 0
    , CONSTRAINT PK_ConceptoCobro 
        PRIMARY KEY CLUSTERED (idCC)
    , CONSTRAINT FK_CC_TipoMonto 
        FOREIGN KEY (idTipoMontoCC)
        REFERENCES dbo.TipoMontoCC(idTipoMonto)
    , CONSTRAINT FK_CC_Periodo 
        FOREIGN KEY (idPeriodoMontoCC)
        REFERENCES dbo.PeriodoMontoCC(idPeriodo)
);
GO

-- =============================================
-- 2. PARÁMETROS DEL SISTEMA
-- =============================================

IF OBJECT_ID('dbo.ParametrosSistema', 'U') IS NOT NULL 
    DROP TABLE dbo.ParametrosSistema;
GO

CREATE TABLE dbo.ParametrosSistema (
    nombreParametro VARCHAR(50) NOT NULL
    , valorNumerico INT NULL
    , valorTexto VARCHAR(100) NULL
    , descripcion VARCHAR(200) NULL
    , CONSTRAINT PK_ParametrosSistema 
        PRIMARY KEY CLUSTERED (nombreParametro)
);
GO

-- =============================================
-- 3. PROPIETARIOS
-- =============================================

IF OBJECT_ID('dbo.Propietario', 'U') IS NOT NULL 
    DROP TABLE dbo.Propietario;
GO

CREATE TABLE dbo.Propietario (
    valorDocumentoIdentidad VARCHAR(30) NOT NULL
    , idTipoDocumento INT NOT NULL
    , nombre VARCHAR(100) NOT NULL
    , email VARCHAR(100) NULL
    , telefono1 VARCHAR(20) NOT NULL
    , telefono2 VARCHAR(20) NOT NULL
    , fechaRegistro DATETIME NOT NULL DEFAULT GETDATE()
    , activo BIT NOT NULL DEFAULT 1
    , CONSTRAINT PK_Propietario 
        PRIMARY KEY CLUSTERED (valorDocumentoIdentidad)
    , CONSTRAINT FK_Propietario_TipoDoc 
        FOREIGN KEY (idTipoDocumento)
        REFERENCES dbo.TipoDocumentoIdentidad(idTipoDocumento)
);
GO

-- =============================================
-- 4. PROPIEDADES
-- =============================================

IF OBJECT_ID('dbo.Propiedad', 'U') IS NOT NULL 
    DROP TABLE dbo.Propiedad;
GO

CREATE TABLE dbo.Propiedad (
    numeroFinca VARCHAR(30) NOT NULL
    , idTipoUso INT NOT NULL
    , idTipoZona INT NOT NULL
    , valorFiscal MONEY NOT NULL DEFAULT 0
    , metrosCuadrados DECIMAL(10,2) NOT NULL DEFAULT 0
    , numeroMedidor VARCHAR(50) NULL
    , fechaRegistro DATE NOT NULL
    , diaFacturacion AS (
        CASE 
            WHEN DAY(fechaRegistro) = 31 THEN 30
            ELSE DAY(fechaRegistro)
        END
    ) PERSISTED
    , m3Acumulados DECIMAL(12,2) NOT NULL DEFAULT 0
    , m3AcumuladosUltimaFactura DECIMAL(12,2) NOT NULL DEFAULT 0
    , activo BIT NOT NULL DEFAULT 1
    , CONSTRAINT PK_Propiedad 
        PRIMARY KEY CLUSTERED (numeroFinca)
    , CONSTRAINT FK_Propiedad_TipoUso 
        FOREIGN KEY (idTipoUso) 
        REFERENCES dbo.TipoUso(idTipoUso)
    , CONSTRAINT FK_Propiedad_TipoZona 
        FOREIGN KEY (idTipoZona) 
        REFERENCES dbo.TipoZona(idTipoZona)
);
GO

IF OBJECT_ID('dbo.PropiedadPropietario', 'U') IS NOT NULL 
    DROP TABLE dbo.PropiedadPropietario;
GO

CREATE TABLE dbo.PropiedadPropietario (
    idRelacion INT IDENTITY(1,1) NOT NULL
    , numeroFinca VARCHAR(30) NOT NULL
    , valorDocumentoIdentidad VARCHAR(30) NOT NULL
    , esActual BIT NOT NULL DEFAULT 1
    , fechaInicio DATE NOT NULL DEFAULT GETDATE()
    , fechaFin DATE NULL
    , CONSTRAINT PK_PropiedadPropietario 
        PRIMARY KEY CLUSTERED (idRelacion)
    , CONSTRAINT FK_PropProp_Finca 
        FOREIGN KEY (numeroFinca) 
        REFERENCES dbo.Propiedad(numeroFinca)
    , CONSTRAINT FK_PropProp_Propietario 
        FOREIGN KEY (valorDocumentoIdentidad) 
        REFERENCES dbo.Propietario(valorDocumentoIdentidad)
);
GO

-- =============================================
-- 5. MEDIDORES
-- =============================================

IF OBJECT_ID('dbo.Medidor', 'U') IS NOT NULL 
    DROP TABLE dbo.Medidor;
GO

CREATE TABLE dbo.Medidor (
    numeroMedidor VARCHAR(50) NOT NULL
    , numeroFinca VARCHAR(30) NOT NULL
    , saldoAcumulado DECIMAL(12,2) NOT NULL DEFAULT 0
    , fechaUltimaLectura DATETIME NULL
    , activo BIT NOT NULL DEFAULT 1
    , CONSTRAINT PK_Medidor 
        PRIMARY KEY CLUSTERED (numeroMedidor)
    , CONSTRAINT FK_Medidor_Propiedad 
        FOREIGN KEY (numeroFinca) 
        REFERENCES dbo.Propiedad(numeroFinca)
);
GO

IF OBJECT_ID('dbo.MovimientoMedidor', 'U') IS NOT NULL 
    DROP TABLE dbo.MovimientoMedidor;
GO

CREATE TABLE dbo.MovimientoMedidor (
    idMovimiento INT IDENTITY(1,1) NOT NULL
    , numeroMedidor VARCHAR(50) NOT NULL
    , idTipoMovimiento INT NOT NULL
    , fechaMovimiento DATETIME NOT NULL DEFAULT GETDATE()
    , valorMovimiento DECIMAL(12,2) NOT NULL
    , saldoAnterior DECIMAL(12,2) NOT NULL
    , saldoDespues DECIMAL(12,2) NOT NULL
    , CONSTRAINT PK_MovimientoMedidor 
        PRIMARY KEY CLUSTERED (idMovimiento)
    , CONSTRAINT FK_Movimiento_Medidor 
        FOREIGN KEY (numeroMedidor) 
        REFERENCES dbo.Medidor(numeroMedidor)
    , CONSTRAINT FK_Movimiento_Tipo 
        FOREIGN KEY (idTipoMovimiento)
        REFERENCES dbo.TipoMovimiento(idTipoMovimiento)
);
GO

-- =============================================
-- 6. PROPIEDAD - CONCEPTO COBRO
-- =============================================

IF OBJECT_ID('dbo.PropiedadConceptoCobro', 'U') IS NOT NULL 
    DROP TABLE dbo.PropiedadConceptoCobro;
GO

CREATE TABLE dbo.PropiedadConceptoCobro (
    idRelacion INT IDENTITY(1,1) NOT NULL
    , numeroFinca VARCHAR(30) NOT NULL
    , idCC INT NOT NULL
    , activo BIT NOT NULL DEFAULT 1
    , fechaAsignacion DATETIME NOT NULL DEFAULT GETDATE()
    , CONSTRAINT PK_PropiedadCC 
        PRIMARY KEY CLUSTERED (idRelacion)
    , CONSTRAINT FK_PropCC_Propiedad 
        FOREIGN KEY (numeroFinca)
        REFERENCES dbo.Propiedad(numeroFinca)
    , CONSTRAINT FK_PropCC_Concepto 
        FOREIGN KEY (idCC)
        REFERENCES dbo.ConceptoCobro(idCC)
    , CONSTRAINT UQ_PropCC 
        UNIQUE (numeroFinca, idCC)
);
GO

-- =============================================
-- 7. FACTURACIÓN
-- =============================================

IF OBJECT_ID('dbo.Factura', 'U') IS NOT NULL 
    DROP TABLE dbo.Factura;
GO

CREATE TABLE dbo.Factura (
    idFactura INT IDENTITY(1,1) NOT NULL
    , numeroFactura VARCHAR(50) NOT NULL
    , numeroFinca VARCHAR(30) NOT NULL
    , idEstadoFactura INT NOT NULL DEFAULT 0
    , fechaEmision DATE NOT NULL DEFAULT GETDATE()
    , fechaVencimiento DATE NOT NULL
    , periodo DATE NOT NULL
    , totalOriginal MONEY NOT NULL DEFAULT 0
    , totalAPagar MONEY NOT NULL DEFAULT 0
    , CONSTRAINT PK_Factura 
        PRIMARY KEY CLUSTERED (idFactura)
    , CONSTRAINT UQ_NumeroFactura 
        UNIQUE (numeroFactura)
    , CONSTRAINT FK_Factura_Propiedad 
        FOREIGN KEY (numeroFinca) 
        REFERENCES dbo.Propiedad(numeroFinca)
    , CONSTRAINT FK_Factura_Estado 
        FOREIGN KEY (idEstadoFactura) 
        REFERENCES dbo.EstadoFactura(idEstadoFactura)
);
GO

IF OBJECT_ID('dbo.FacturaDetalle', 'U') IS NOT NULL 
    DROP TABLE dbo.FacturaDetalle;
GO

CREATE TABLE dbo.FacturaDetalle (
    idDetalle INT IDENTITY(1,1) NOT NULL
    , idFactura INT NOT NULL
    , idCC INT NOT NULL
    , cantidad DECIMAL(10,2) NOT NULL DEFAULT 1
    , monto MONEY NOT NULL
    , descripcion VARCHAR(200) NULL
    , CONSTRAINT PK_FacturaDetalle 
        PRIMARY KEY CLUSTERED (idDetalle)
    , CONSTRAINT FK_Detalle_Factura 
        FOREIGN KEY (idFactura) 
        REFERENCES dbo.Factura(idFactura)
    , CONSTRAINT FK_Detalle_Concepto 
        FOREIGN KEY (idCC) 
        REFERENCES dbo.ConceptoCobro(idCC)
);
GO

-- =============================================
-- 8. PAGOS
-- =============================================

IF OBJECT_ID('dbo.Pago', 'U') IS NOT NULL 
    DROP TABLE dbo.Pago;
GO

CREATE TABLE dbo.Pago (
    idPago INT IDENTITY(1,1) NOT NULL
    , numeroFinca VARCHAR(30) NOT NULL
    , idFactura INT NULL
    , idMedioPago INT NOT NULL
    , numeroComprobante VARCHAR(50) NOT NULL
    , numeroReferencia VARCHAR(100) NULL
    , fechaPago DATETIME NOT NULL DEFAULT GETDATE()
    , montoPagado MONEY NOT NULL
    , CONSTRAINT PK_Pago 
        PRIMARY KEY CLUSTERED (idPago)
    , CONSTRAINT UQ_NumeroComprobante 
        UNIQUE (numeroComprobante)
    , CONSTRAINT FK_Pago_Propiedad 
        FOREIGN KEY (numeroFinca)
        REFERENCES dbo.Propiedad(numeroFinca)
    , CONSTRAINT FK_Pago_Factura 
        FOREIGN KEY (idFactura) 
        REFERENCES dbo.Factura(idFactura)
    , CONSTRAINT FK_Pago_Medio 
        FOREIGN KEY (idMedioPago) 
        REFERENCES dbo.MedioPago(idMedioPago)
);
GO

-- =============================================
-- 9. CORTES Y RECONEXIONES
-- =============================================

IF OBJECT_ID('dbo.OrdenCorte', 'U') IS NOT NULL 
    DROP TABLE dbo.OrdenCorte;
GO

CREATE TABLE dbo.OrdenCorte (
    idOrdenCorte INT IDENTITY(1,1) NOT NULL
    , numeroFinca VARCHAR(30) NOT NULL
    , idFacturaOrigen INT NOT NULL
    , idEstadoOrden INT NOT NULL DEFAULT 0
    , fechaCreacion DATETIME NOT NULL DEFAULT GETDATE()
    , fechaEjecucion DATETIME NULL
    , CONSTRAINT PK_OrdenCorte 
        PRIMARY KEY CLUSTERED (idOrdenCorte)
    , CONSTRAINT FK_OrdenCorte_Propiedad 
        FOREIGN KEY (numeroFinca)
        REFERENCES dbo.Propiedad(numeroFinca)
    , CONSTRAINT FK_OrdenCorte_Factura 
        FOREIGN KEY (idFacturaOrigen) 
        REFERENCES dbo.Factura(idFactura)
    , CONSTRAINT FK_OrdenCorte_Estado 
        FOREIGN KEY (idEstadoOrden) 
        REFERENCES dbo.EstadoOrden(idEstadoOrden)
);
GO

IF OBJECT_ID('dbo.Reconexion', 'U') IS NOT NULL 
    DROP TABLE dbo.Reconexion;
GO

CREATE TABLE dbo.Reconexion (
    idReconexion INT IDENTITY(1,1) NOT NULL
    , idOrdenCorte INT NOT NULL
    , idPago INT NOT NULL
    , fechaSolicitud DATETIME NOT NULL DEFAULT GETDATE()
    , fechaEjecucion DATETIME NULL
    , CONSTRAINT PK_Reconexion 
        PRIMARY KEY CLUSTERED (idReconexion)
    , CONSTRAINT FK_Reconexion_Orden 
        FOREIGN KEY (idOrdenCorte) 
        REFERENCES dbo.OrdenCorte(idOrdenCorte)
    , CONSTRAINT FK_Reconexion_Pago 
        FOREIGN KEY (idPago) 
        REFERENCES dbo.Pago(idPago)
);
GO

-- =============================================
-- 10. USUARIOS 
-- =============================================

IF OBJECT_ID('dbo.Usuario', 'U') IS NOT NULL 
    DROP TABLE dbo.Usuario;
GO

CREATE TABLE dbo.Usuario (
    idUsuario INT IDENTITY(1,1) NOT NULL
    , valorDocumentoIdentidad VARCHAR(30) NOT NULL
    , idTipoUsuario INT NOT NULL
    , username VARCHAR(50) NOT NULL
    , passwordHash VARCHAR(255) NOT NULL
    , activo BIT NOT NULL DEFAULT 1
    , fechaCreacion DATETIME NOT NULL DEFAULT GETDATE()
    , CONSTRAINT PK_Usuario 
        PRIMARY KEY CLUSTERED (idUsuario)
    , CONSTRAINT UQ_Username 
        UNIQUE (username)
    , CONSTRAINT FK_Usuario_Propietario 
        FOREIGN KEY (valorDocumentoIdentidad)
        REFERENCES dbo.Propietario(valorDocumentoIdentidad)
    , CONSTRAINT FK_Usuario_Tipo 
        FOREIGN KEY (idTipoUsuario)
        REFERENCES dbo.TipoUsuario(idTipoUsuario)
);
GO

IF OBJECT_ID('dbo.UsuarioPropiedad', 'U') IS NOT NULL 
    DROP TABLE dbo.UsuarioPropiedad;
GO

CREATE TABLE dbo.UsuarioPropiedad (
    idRelacion INT IDENTITY(1,1) NOT NULL
    , idUsuario INT NOT NULL
    , numeroFinca VARCHAR(30) NOT NULL
    , activo BIT NOT NULL DEFAULT 1
    , fechaAsignacion DATETIME NOT NULL DEFAULT GETDATE()
    , CONSTRAINT PK_UsuarioPropiedad 
        PRIMARY KEY CLUSTERED (idRelacion)
    , CONSTRAINT FK_UsrProp_Usuario 
        FOREIGN KEY (idUsuario)
        REFERENCES dbo.Usuario(idUsuario)
    , CONSTRAINT FK_UsrProp_Propiedad 
        FOREIGN KEY (numeroFinca)
        REFERENCES dbo.Propiedad(numeroFinca)
    , CONSTRAINT UQ_UsrProp 
        UNIQUE (idUsuario, numeroFinca)
);
GO

IF OBJECT_ID('dbo.BitacoraCambios', 'U') IS NOT NULL 
    DROP TABLE dbo.BitacoraCambios;
GO

CREATE TABLE dbo.BitacoraCambios (
    idBitacora INT IDENTITY(1,1) NOT NULL
    , idTipoEntidad INT NOT NULL
    , entidadId VARCHAR(50) NOT NULL
    , jsonAntes VARCHAR(MAX) NULL
    , jsonDespues VARCHAR(MAX) NULL
    , insertedAt DATETIME NOT NULL DEFAULT GETDATE()
    , insertedBy INT NOT NULL
    , insertedIn VARCHAR(50) NULL
    , CONSTRAINT PK_BitacoraCambios 
        PRIMARY KEY CLUSTERED (idBitacora)
    , CONSTRAINT FK_Bitacora_TipoEntidad 
        FOREIGN KEY (idTipoEntidad)
        REFERENCES dbo.TipoEntidad(idTipoEntidad)
    , CONSTRAINT FK_Bitacora_Usuario 
        FOREIGN KEY (insertedBy)
        REFERENCES dbo.Usuario(idUsuario)
);
GO

-- =============================================
-- 11. TABLA DE ERRORES
-- =============================================

IF OBJECT_ID('dbo.DBErrors', 'U') IS NOT NULL 
    DROP TABLE dbo.DBErrors;
GO

CREATE TABLE dbo.DBErrors (
    idError INT IDENTITY(1,1) NOT NULL
    , userName VARCHAR(100) NULL
    , errorNumber INT NULL
    , errorState INT NULL
    , errorSeverity INT NULL
    , errorLine INT NULL
    , errorProcedure VARCHAR(MAX) NULL
    , errorMessage VARCHAR(MAX) NULL
    , errorDateTime DATETIME NOT NULL DEFAULT GETDATE()
    , CONSTRAINT PK_DBErrors 
        PRIMARY KEY CLUSTERED (idError)
);
GO

-- =============================================
-- 12. PARÁMETROS INICIALES
-- =============================================

INSERT INTO dbo.ParametrosSistema (
    nombreParametro, valorNumerico, valorTexto, descripcion
)
VALUES 
    ('DiasVencimientoFactura', 8, NULL, 'D�as para vencimiento')
    , ('DiasGraciaCorteAgua', 10, NULL, 'D�as de gracia antes de corte')
    , ('PorcentajeInteresMoratorio', 2, NULL, 'Porcentaje inter�s');
GO

PRINT 'BASE DE DATOS CREADA EXITOSAMENTE';
GO