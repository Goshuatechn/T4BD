let currentFinca = '';

async function consultarEstado() {
    const criterio = document.getElementById('criterio').value;
    const valor = document.getElementById('valorBusqueda').value;

    if(!valor) return alert('Ingrese un valor');

    try {
        const response = await fetch(`/api/consultar?criterio=${criterio}&valor=${valor}`);
        const data = await response.json();

        if (data.success) {
            mostrarResultados(data);
        } else {
            alert('Error: ' + data.error);
        }
    } catch (error) {
        console.error(error);
        alert('Error de conexión');
    }
}

function mostrarResultados(data) {
    document.getElementById('resultados').classList.remove('hidden');
    
    // 1. Mostrar Info Propiedad
    const prop = data.propiedad[0] || {};
    currentFinca = prop.numeroFinca || ''; // Guardar para el pago
    
    let htmlProp = `<h3>Propiedad: ${prop.numeroFinca || 'N/A'}</h3>`;
    if(prop.Nombre) htmlProp += `<p>Propietario: ${prop.Nombre}</p>`;
    document.getElementById('infoPropiedad').innerHTML = htmlProp;

    // 2. Tabla Pendientes
    const tbodyPend = document.querySelector('#tablaPendientes tbody');
    tbodyPend.innerHTML = '';
    
    // Ordenar pendientes por fecha (más antigua primero)
    // Asumimos que vienen ordenadas o las ordenamos aquí para cumplir rubrica
    data.pendientes.sort((a,b) => new Date(a.fechaVencimiento) - new Date(b.fechaVencimiento));

    data.pendientes.forEach((row, index) => {
        const tr = document.createElement('tr');
        // Solo mostrar botón de pago en la MÁS ANTIGUA (index 0)
        const btnPago = index === 0 
            ? `<button class="pay-btn" onclick="pagarFactura('${row.numeroFinca}')">Pagar ₡${row.totalAPagar}</button>` 
            : '<span style="color:gray">Debe pagar la anterior</span>';

        tr.innerHTML = `
            <td>${row.numeroFactura}</td>
            <td>${row.fechaVencimiento}</td>
            <td>₡${row.totalAPagar}</td>
            <td>${btnPago}</td>
        `;
        tbodyPend.appendChild(tr);
    });

    // 3. Tabla Pagadas
    const tbodyPag = document.querySelector('#tablaPagadas tbody');
    tbodyPag.innerHTML = '';
    data.pagadas.forEach(row => {
        tr = document.createElement('tr');
        tr.innerHTML = `
            <td>${row.numeroComprobante || 'N/A'}</td>
            <td>${row.fechaPago}</td>
            <td>₡${row.montoPagado}</td>
        `;
        tbodyPag.appendChild(tr);
    });
}

async function pagarFactura(numeroFinca) {
    if(!confirm('¿Desea procesar el pago de la factura más antigua?')) return;

    try {
        const response = await fetch('/api/pagar', {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({ numeroFinca: numeroFinca })
        });
        const data = await response.json();

        if(data.success) {
            alert('Pago realizado con éxito. Monto: ₡' + data.monto);
            consultarEstado(); // Recargar datos
        } else {
            alert('Error al pagar: ' + data.error);
        }
    } catch (error) {
        console.error(error);
        alert('Error procesando el pago');
    }
}

function openTab(tabName) {
    document.querySelectorAll('.tab-content').forEach(t => t.classList.remove('active'));
    document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
    
    document.getElementById(tabName).classList.add('active');
    event.currentTarget.classList.add('active');
}