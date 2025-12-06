from flask import Flask, render_template, request, jsonify
import pyodbc
import json

app = Flask(__name__)

# ==============================================================================
# CONFIGURACIÓN DE LA BASE DE DATOS
# ==============================================================================
DB_CONFIG = {
    'server': 'GOSHUA\\SQLEXPRESS',   # Tu servidor
    'database': 'T3BD',               # Tu base de datos
    'driver': '{ODBC Driver 17 for SQL Server}',
    'trusted_connection': 'yes'       # Autenticación de Windows
}

def get_db_connection():
    """Crea y retorna una conexión a SQL Server usando PyODBC"""
    conn_str = f"DRIVER={DB_CONFIG['driver']};SERVER={DB_CONFIG['server']};DATABASE={DB_CONFIG['database']};Trusted_Connection={DB_CONFIG['trusted_connection']};"
    return pyodbc.connect(conn_str)

# ==============================================================================
# RUTAS DE LA APLICACIÓN
# ==============================================================================

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/api/consultar', methods=['GET'])
def consultar():
    criterio = request.args.get('criterio')
    valor = request.args.get('valor')
    
    if not valor:
        return jsonify({'success': False, 'error': 'Debe ingresar un valor de búsqueda'})
    
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        num_finca = valor if criterio == 'finca' else None
        doc_persona = valor if criterio == 'persona' else None
        
        # Ejecutar SP. El 0 final es el placeholder para @outResultCode
        cursor.execute("{CALL SP_ConsultarEstadoCuenta (?, ?, ?)}", (num_finca, doc_persona, 0))
        
        # 1. Información de Propiedad
        propiedad = []
        if cursor.description:
            cols = [column[0] for column in cursor.description]
            propiedad = [dict(zip(cols, row)) for row in cursor.fetchall()]
        
        # 2. Información de Propietarios
        propietarios = []
        if cursor.nextset() and cursor.description:
            cols = [column[0] for column in cursor.description]
            propietarios = [dict(zip(cols, row)) for row in cursor.fetchall()]
        
        # 3. Conceptos de Cobro (Saltamos)
        if cursor.nextset(): cursor.fetchall()
        
        # 4. Facturas Pendientes (Capturar)
        facturas_pendientes = []
        if cursor.nextset() and cursor.description:
            cols = [column[0] for column in cursor.description]
            facturas_pendientes = [dict(zip(cols, row)) for row in cursor.fetchall()]
            
        # 5. Detalles Facturas (Saltamos)
        if cursor.nextset(): cursor.fetchall()
        
        # 6. Facturas Pagadas (Capturar)
        facturas_pagadas = []
        if cursor.nextset() and cursor.description:
            cols = [column[0] for column in cursor.description]
            facturas_pagadas = [dict(zip(cols, row)) for row in cursor.fetchall()]
            
        # 7. Cortes y 8. Resumen (Saltamos el resto)
        while cursor.nextset(): pass

        # Agregar nombre del propietario si existe
        if propiedad and propietarios:
            propiedad[0]['Nombre'] = propietarios[0].get('nombrePropietario', 'Sin Propietario')

        return jsonify({
            'success': True,
            'propiedad': propiedad,
            'pendientes': facturas_pendientes,
            'pagadas': facturas_pagadas
        })

    except Exception as e:
        return jsonify({'success': False, 'error': f'Error Interno: {str(e)}'})
    finally:
        cursor.close()
        conn.close()

@app.route('/api/pagar', methods=['POST'])
def pagar():
    data = request.json
    numero_finca = data.get('numeroFinca')
    medio_pago = 1  # 1 = Efectivo/Web
    
    if not numero_finca:
        return jsonify({'success': False, 'error': 'Finca requerida'})
    
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        # ---------------------------------------------------------
        # PASO 1: REGISTRAR EL PAGO
        # ---------------------------------------------------------
        # NOTA: Usamos DECLARE @fechaHoy para evitar errores de sintaxis con GETDATE()
        sql_pago = """
        DECLARE @outIdPago INT;
        DECLARE @outIdFactura INT;
        DECLARE @outMonto MONEY;
        DECLARE @outResult INT;
        DECLARE @fechaHoy DATE = GETDATE();
        
        EXEC SP_RegistrarPagoFactura 
            @inNumeroFinca = ?, 
            @inTipoMedioPago = ?, 
            @inNumeroReferencia = 'WEB-APP', 
            @inFechaPago = @fechaHoy, 
            @outIdPago = @outIdPago OUTPUT, 
            @outIdFactura = @outIdFactura OUTPUT, 
            @outMontoTotal = @outMonto OUTPUT, 
            @outResultCode = @outResult OUTPUT;
            
        SELECT @outResult AS ResultCode, @outMonto AS MontoPagado, @outIdPago AS IdPago;
        """
        cursor.execute(sql_pago, (numero_finca, medio_pago))
        row = cursor.fetchone()
        
        if not row:
            raise Exception("El SP de pago no retornó valores.")
            
        result_code = row.ResultCode
        monto_pagado = row.MontoPagado
        id_pago = row.IdPago
        
        if result_code != 0:
            conn.rollback()
            return jsonify({'success': False, 'error': f'El pago falló. Código error: {result_code}'})
        
        conn.commit()

        # ---------------------------------------------------------
        # PASO 2: INTENTAR RECONEXIÓN
        # ---------------------------------------------------------
        msg_reconexion = ""
        try:
            sql_recon = """
            DECLARE @outRes INT;
            EXEC SP_GenerarReconexion 
                @inNumeroFinca = ?, 
                @inIdPago = ?, 
                @outResultCode = @outRes OUTPUT;
            SELECT @outRes AS ResultCode;
            """
            cursor.execute(sql_recon, (numero_finca, id_pago))
            row_rec = cursor.fetchone()
            res_rec = row_rec.ResultCode if row_rec else -1
            
            conn.commit()
            
            if res_rec == 0:
                msg_reconexion = "¡Servicio Reconectado!"
            elif res_rec in [50403, 50404]:
                msg_reconexion = "Pago procesado (No requería reconexión)."
            else:
                msg_reconexion = f"Pago ok, pero error reconexión: {res_rec}"
                
        except Exception as e:
            msg_reconexion = f"Pago ok, error sistema reconexión: {str(e)}"

        return jsonify({
            'success': True,
            'monto': float(monto_pagado),
            'mensaje': f"Pago exitoso de ₡{monto_pagado:,.2f}. {msg_reconexion}"
        })

    except Exception as e:
        conn.rollback()
        return jsonify({'success': False, 'error': str(e)})
    finally:
        conn.close()

if __name__ == '__main__':
    app.run(debug=True)