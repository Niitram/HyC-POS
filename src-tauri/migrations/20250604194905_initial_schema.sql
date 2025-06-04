-- Add migration script here
-- src-tauri/migrations/YYYYMMDDHHMMSS_initial_schema.up.sql

-- Tabla para la configuración general del negocio
-- Estos datos se mostrarán en tickets, UI, etc.
CREATE TABLE configuracion_negocio (
    id_configuracion SERIAL PRIMARY KEY,
    nombre_negocio VARCHAR(255) NOT NULL,
    direccion TEXT,
    telefono VARCHAR(50),
    simbolo_moneda VARCHAR(5) NOT NULL DEFAULT '$', -- Ejemplo: $, €, etc.
    impresora_tickets_predeterminada VARCHAR(255), -- Nombre de la impresora en el sistema
    mensaje_pie_ticket TEXT, -- Mensaje opcional al final del ticket
    -- TODO MVP_Extendido: añadir campos como 'email_negocio', 'cuit_o_identificador_fiscal', 'logo_url'
    -- TODO MVP_Extendido: considerar una tabla 'preferencias_ui' (tema_oscuro, idioma_por_defecto)
    fecha_creacion TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Tabla para usuarios/empleados y su PIN de acceso
-- En el MVP, se usa para identificar quién abre/cierra caja y quién realiza una venta.
CREATE TABLE usuarios_pin (
    id_usuario_pin SERIAL PRIMARY KEY,
    nombre_empleado VARCHAR(100) NOT NULL, -- Nombre para mostrar, ej. "Marto", "Cajero Mañana"
    pin_hash VARCHAR(255) NOT NULL, -- Hash del PIN (NUNCA el PIN en texto plano)
    rol VARCHAR(50) NOT NULL CHECK (rol IN ('ADMINISTRADOR', 'CAJERO')), -- Roles básicos para MVP
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    -- TODO MVP_Extendido: añadir 'email' para recuperación de PIN/contraseña
    -- TODO MVP_Extendido: añadir 'contrasena_hash' para un login con usuario/contraseña completo
    -- TODO MVP_Extendido: tabla 'roles' y 'permisos' para un control de acceso más granular
    fecha_creacion TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de Categorías de Productos
-- Permite organizar los productos en el POS.
CREATE TABLE categorias (
    id_categoria SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    descripcion TEXT, -- Descripción opcional de la categoría
    orden_visualizacion INTEGER DEFAULT 0, -- Para controlar el orden en que aparecen en la UI
    activa BOOLEAN NOT NULL DEFAULT TRUE, -- Si la categoría está activa y se muestra
    -- TODO MVP_Extendido: añadir 'id_categoria_padre INTEGER REFERENCES categorias(id_categoria)' para subcategorías
    -- TODO MVP_Extendido: añadir 'color_etiqueta VARCHAR(7)' para personalización visual
    fecha_creacion TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de Productos
-- Define los ítems que se venden.
CREATE TABLE productos (
    id_producto SERIAL PRIMARY KEY,
    id_categoria INTEGER NOT NULL REFERENCES categorias(id_categoria),
    nombre VARCHAR(255) NOT NULL,
    descripcion TEXT, -- Descripción detallada del producto
    visible_en_pos BOOLEAN NOT NULL DEFAULT TRUE, -- Si el producto como tal es visible en el POS
    activo BOOLEAN NOT NULL DEFAULT TRUE, -- Si el producto está activo en el sistema
    -- TODO MVP_Extendido: añadir 'imagen_url VARCHAR(500)'
    -- TODO MVP_Extendido: añadir 'sku VARCHAR(100) UNIQUE' (Stock Keeping Unit)
    -- TODO MVP_Extendido: añadir 'maneja_stock BOOLEAN DEFAULT FALSE'
    -- TODO MVP_Extendido: añadir 'stock_actual INTEGER DEFAULT 0' (si maneja_stock es TRUE y no usa variantes con stock individual)
    -- TODO MVP_Extendido: añadir 'precio_costo DECIMAL(10, 2)' para calcular rentabilidad
    -- TODO MVP_Extendido: considerar tabla 'producto_impuestos' para asociar impuestos específicos
    fecha_creacion TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (id_categoria, nombre) -- Un producto con el mismo nombre no debería repetirse en la misma categoría
);

-- Tabla de Variantes de Producto
-- Cada producto tiene al menos una variante (ej. "Unidad", "Chico", "Grande").
-- Si un producto no tiene variantes "nombradas", se crea una por defecto (ej. con nombre "Única" o el mismo nombre del producto).
CREATE TABLE variantes_producto (
    id_variante_producto SERIAL PRIMARY KEY,
    id_producto INTEGER NOT NULL REFERENCES productos(id_producto) ON DELETE CASCADE, -- Si se borra el producto, se borran sus variantes
    nombre_variante VARCHAR(100) NOT NULL, -- Ej: "Porción", "Chico", "Grande", "Roja", "Azul"
    precio_venta DECIMAL(10, 2) NOT NULL CHECK (precio_venta >= 0),
    visible_en_pos BOOLEAN NOT NULL DEFAULT TRUE, -- Si esta variante específica es visible en el POS
    activa BOOLEAN NOT NULL DEFAULT TRUE,
    -- TODO MVP_Extendido: añadir 'sku_variante VARCHAR(100) UNIQUE'
    -- TODO MVP_Extendido: añadir 'stock_actual_variante INTEGER DEFAULT 0' (si el stock se maneja por variante)
    -- TODO MVP_Extendido: añadir 'orden_visualizacion_variante INTEGER DEFAULT 0'
    -- TODO MVP_Extendido: añadir 'imagen_url_variante VARCHAR(500)'
    fecha_creacion TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (id_producto, nombre_variante) -- Una variante con el mismo nombre no debería repetirse para el mismo producto
);

-- Tabla de Sesiones de Caja (reemplaza "CierresCaja" para reflejar un ciclo completo)
-- Registra la apertura y cierre de caja por un usuario.
CREATE TABLE sesiones_caja (
    id_sesion_caja SERIAL PRIMARY KEY,
    id_usuario_apertura INTEGER NOT NULL REFERENCES usuarios_pin(id_usuario_pin),
    fecha_apertura TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    monto_inicial_efectivo DECIMAL(10, 2) NOT NULL CHECK (monto_inicial_efectivo >= 0),

    id_usuario_cierre INTEGER REFERENCES usuarios_pin(id_usuario_pin), -- Se llena al cerrar
    fecha_cierre TIMESTAMPTZ, -- Se llena al cerrar
    monto_final_efectivo_contado DECIMAL(10, 2), -- El monto que el usuario contó físicamente
    efectivo_esperado_sistema DECIMAL(10, 2), -- Calculado: inicial + ventas efectivo - retiros + ingresos
    diferencia_efectivo DECIMAL(10, 2), -- Calculado: contado - esperado
    notas_cierre TEXT, -- Notas del usuario al cerrar la caja
    estado_sesion VARCHAR(20) NOT NULL DEFAULT 'ABIERTA' CHECK (estado_sesion IN ('ABIERTA', 'CERRADA', 'AUDITADA')),
    -- TODO MVP_Extendido: añadir 'total_ventas_tarjeta_sistema', 'total_ventas_qr_sistema', 'total_otros_pagos_sistema'
    -- TODO MVP_Extendido: añadir 'total_retiros_efectivo', 'total_ingresos_adicionales_efectivo' (si se implementan esas funcionalidades)
    -- Para esto, se necesitaría una tabla 'movimientos_caja_efectivo' que registre retiros/ingresos
    fecha_creacion TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de Ventas
-- Registra cada transacción completada.
CREATE TABLE ventas (
    id_venta SERIAL PRIMARY KEY,
    id_sesion_caja INTEGER NOT NULL REFERENCES sesiones_caja(id_sesion_caja), -- A qué sesión de caja pertenece
    id_usuario_vendedor INTEGER NOT NULL REFERENCES usuarios_pin(id_usuario_pin), -- Quién realizó la venta
    fecha_venta TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    total_venta DECIMAL(10, 2) NOT NULL CHECK (total_venta >= 0),
    metodo_pago_principal VARCHAR(50) NOT NULL CHECK (metodo_pago_principal IN ('EFECTIVO', 'TARJETA', 'QR', 'OTRO')), -- Simplificado para MVP
    monto_recibido_efectivo DECIMAL(10, 2) CHECK (monto_recibido_efectivo >= 0), -- Si es efectivo, cuánto dio el cliente
    vuelto_entregado DECIMAL(10, 2) CHECK (vuelto_entregado >= 0), -- Si es efectivo, cuánto vuelto se dio
    referencia_pago_otros VARCHAR(255), -- Para guardar ID de transacción de tarjeta/QR, etc.
    estado_venta VARCHAR(50) NOT NULL DEFAULT 'COMPLETADA' CHECK (estado_venta IN ('COMPLETADA', 'CANCELADA', 'PENDIENTE')), -- Para MVP, todas serán 'COMPLETADA'
    -- TODO MVP_Extendido: añadir 'id_cliente INTEGER REFERENCES clientes(id_cliente)' (necesitaría tabla 'clientes')
    -- TODO MVP_Extendido: añadir 'descuento_total_aplicado DECIMAL(10,2) DEFAULT 0'
    -- TODO MVP_Extendido: añadir 'impuestos_total_aplicado DECIMAL(10,2) DEFAULT 0'
    -- TODO MVP_Extendido: añadir 'notas_venta TEXT'
    -- TODO MVP_Extendido: considerar 'id_mesa INTEGER REFERENCES mesas(id_mesa)' o 'tipo_servicio (MOSTRADOR, MESA, DELIVERY)'
    fecha_creacion TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de Items de Venta (detalle de cada venta)
-- Qué productos y variantes se vendieron en cada venta.
CREATE TABLE items_venta (
    id_item_venta SERIAL PRIMARY KEY,
    id_venta INTEGER NOT NULL REFERENCES ventas(id_venta) ON DELETE CASCADE, -- Si se borra la venta, se borran sus ítems
    id_variante_producto INTEGER NOT NULL REFERENCES variantes_producto(id_variante_producto), -- Qué variante específica se vendió
    cantidad INTEGER NOT NULL CHECK (cantidad > 0),
    -- Se guarda el precio unitario y nombres al momento de la venta para histórico, por si el precio/nombre del producto/variante cambia después
    precio_unitario_venta DECIMAL(10, 2) NOT NULL CHECK (precio_unitario_venta >= 0),
    nombre_producto_venta VARCHAR(255) NOT NULL, -- Denormalizado para histórico
    nombre_variante_venta VARCHAR(100) NOT NULL, -- Denormalizado para histórico
    subtotal_item DECIMAL(10, 2) NOT NULL, -- Calculado: cantidad * precio_unitario_venta
    -- TODO MVP_Extendido: añadir 'descuento_item_aplicado DECIMAL(10,2) DEFAULT 0'
    -- TODO MVP_Extendido: añadir 'id_promocion_aplicada INTEGER REFERENCES promociones(id_promocion)'
    -- TODO MVP_Extendido: añadir 'notas_item TEXT'
    fecha_creacion TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Tabla para Licenciamiento (MVP General Points)
CREATE TABLE licencia_aplicacion (
    id_licencia SERIAL PRIMARY KEY,
    codigo_activacion_hash VARCHAR(255) NOT NULL UNIQUE, -- El hash del código ingresado
    fecha_activacion TIMESTAMPTZ NOT NULL,
    fecha_vencimiento TIMESTAMPTZ NOT NULL,
    notificado_proximo_vencimiento BOOLEAN NOT NULL DEFAULT FALSE,
    -- TODO MVP_Extendido: 'datos_adicionales_encriptados TEXT' para info extra de licencia
    -- TODO MVP_Extendido: 'ultimo_chequeo_validez_online TIMESTAMPTZ' si se valida contra servidor
    fecha_creacion TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de Promociones (MVP incluye "Creación de promociones y combos")
CREATE TABLE promociones (
    id_promocion SERIAL PRIMARY KEY,
    nombre_promocion VARCHAR(255) NOT NULL,
    descripcion_promocion TEXT,
    -- Para MVP, nos enfocaremos en 'COMBO_PRECIO_FIJO'. Otros tipos son MVP Extendido.
    tipo_promocion VARCHAR(50) NOT NULL CHECK (tipo_promocion IN ('COMBO_PRECIO_FIJO', 'DESCUENTO_PORCENTAJE_PRODUCTO', 'DESCUENTO_MONTO_FIJO_PRODUCTO', 'NXM_PRODUCTO')),
    
    -- Para tipo_promocion = 'COMBO_PRECIO_FIJO'
    precio_fijo_combo DECIMAL(10, 2) CHECK (precio_fijo_combo >= 0), -- Solo aplica si es COMBO_PRECIO_FIJO

    -- Para tipo_promocion = 'DESCUENTO_PORCENTAJE_PRODUCTO' (MVP_Extendido)
    -- valor_descuento_porcentaje DECIMAL(5, 2) CHECK (valor_descuento_porcentaje > 0 AND valor_descuento_porcentaje <= 100),

    -- Para tipo_promocion = 'DESCUENTO_MONTO_FIJO_PRODUCTO' (MVP_Extendido)
    -- valor_descuento_monto_fijo DECIMAL(10, 2) CHECK (valor_descuento_monto_fijo > 0),
    
    -- Para tipo_promocion = 'NXM_PRODUCTO' (NxM, ej: 2x1, 3x2) (MVP_Extendido)
    -- cantidad_n_paga INTEGER CHECK (cantidad_n_paga > 0), -- El cliente PAGA N items
    -- cantidad_m_lleva INTEGER CHECK (cantidad_m_lleva > cantidad_n_paga), -- El cliente LLEVA M items (M > N)

    fecha_inicio_validez TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_fin_validez TIMESTAMPTZ, -- NULL si no tiene fecha de fin
    activa BOOLEAN NOT NULL DEFAULT TRUE,
    -- TODO MVP_Extendido: 'codigo_promocion VARCHAR(50) UNIQUE' para aplicar promos con código
    -- TODO MVP_Extendido: 'aplicable_automaticamente BOOLEAN DEFAULT TRUE' (si se aplica sin código)
    -- TODO MVP_Extendido: tabla 'promocion_condiciones' para reglas más complejas (ej. aplica solo a categoría X, solo los lunes, etc.)
    -- TODO MVP_Extendido: Llenar los campos comentados para otros tipos de promoción
    fecha_creacion TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de Items de Combo (para promociones de tipo 'COMBO_PRECIO_FIJO')
-- Define qué variantes de producto y en qué cantidad componen un combo.
CREATE TABLE promocion_items_combo (
    id_promocion_item_combo SERIAL PRIMARY KEY,
    id_promocion INTEGER NOT NULL REFERENCES promociones(id_promocion) ON DELETE CASCADE,
    id_variante_producto INTEGER NOT NULL REFERENCES variantes_producto(id_variante_producto) ON DELETE RESTRICT, -- ON DELETE RESTRICT para evitar borrar una variante si está en un combo activo
    cantidad INTEGER NOT NULL CHECK (cantidad > 0),
    -- TODO MVP_Extendido: 'es_opcional BOOLEAN DEFAULT FALSE' si algunos items del combo son a elección
    -- TODO MVP_Extendido: 'grupo_opcional VARCHAR(50)' para agrupar items opcionales (ej. "elige 1 de estas 3 bebidas")
    fecha_creacion TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (id_promocion, id_variante_producto) -- No repetir la misma variante en el mismo combo (se actualiza cantidad si es necesario)
);

-- (Opcional MVP, pero útil) Tabla para registrar qué promociones se aplicaron a qué ventas/items
CREATE TABLE ventas_promociones_aplicadas (
    id_venta_promocion_aplicada SERIAL PRIMARY KEY,
    id_venta INTEGER NOT NULL REFERENCES ventas(id_venta) ON DELETE CASCADE,
    id_promocion INTEGER NOT NULL REFERENCES promociones(id_promocion) ON DELETE RESTRICT,
    -- id_item_venta puede ser NULL si la promo es a nivel de toda la venta, no de un item específico.
    id_item_venta INTEGER NULL REFERENCES items_venta(id_item_venta) ON DELETE CASCADE,
    monto_descuento_generado DECIMAL(10,2) NOT NULL DEFAULT 0, -- Cuánto ahorro representó esta promo en esta venta/item
    descripcion_aplicacion TEXT, -- Ej: "Combo X aplicado", "Descuento 10% en Producto Y"
    -- TODO MVP_Extendido: Detalles más específicos de cómo se aplicó
    fecha_creacion TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);


-- Funciones para actualizar 'fecha_actualizacion' automáticamente (opcional, pero buena práctica)
CREATE OR REPLACE FUNCTION actualizar_fecha_modificacion()
RETURNS TRIGGER AS $$
BEGIN
    NEW.fecha_actualizacion = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar el trigger a todas las tablas que tengan 'fecha_actualizacion'
-- Esto es un poco repetitivo, pero asegura que se actualice.
-- Si usaras un ORM más avanzado, a veces él se encarga de esto.
CREATE TRIGGER trg_configuracion_negocio_actualizacion BEFORE UPDATE ON configuracion_negocio FOR EACH ROW EXECUTE FUNCTION actualizar_fecha_modificacion();
CREATE TRIGGER trg_usuarios_pin_actualizacion BEFORE UPDATE ON usuarios_pin FOR EACH ROW EXECUTE FUNCTION actualizar_fecha_modificacion();
CREATE TRIGGER trg_categorias_actualizacion BEFORE UPDATE ON categorias FOR EACH ROW EXECUTE FUNCTION actualizar_fecha_modificacion();
CREATE TRIGGER trg_productos_actualizacion BEFORE UPDATE ON productos FOR EACH ROW EXECUTE FUNCTION actualizar_fecha_modificacion();
CREATE TRIGGER trg_variantes_producto_actualizacion BEFORE UPDATE ON variantes_producto FOR EACH ROW EXECUTE FUNCTION actualizar_fecha_modificacion();
CREATE TRIGGER trg_sesiones_caja_actualizacion BEFORE UPDATE ON sesiones_caja FOR EACH ROW EXECUTE FUNCTION actualizar_fecha_modificacion();
CREATE TRIGGER trg_ventas_actualizacion BEFORE UPDATE ON ventas FOR EACH ROW EXECUTE FUNCTION actualizar_fecha_modificacion();
CREATE TRIGGER trg_items_venta_actualizacion BEFORE UPDATE ON items_venta FOR EACH ROW EXECUTE FUNCTION actualizar_fecha_modificacion();
CREATE TRIGGER trg_licencia_aplicacion_actualizacion BEFORE UPDATE ON licencia_aplicacion FOR EACH ROW EXECUTE FUNCTION actualizar_fecha_modificacion();
CREATE TRIGGER trg_promociones_actualizacion BEFORE UPDATE ON promociones FOR EACH ROW EXECUTE FUNCTION actualizar_fecha_modificacion();
CREATE TRIGGER trg_promocion_items_combo_actualizacion BEFORE UPDATE ON promocion_items_combo FOR EACH ROW EXECUTE FUNCTION actualizar_fecha_modificacion();
CREATE TRIGGER trg_ventas_promociones_aplicadas_actualizacion BEFORE UPDATE ON ventas_promociones_aplicadas FOR EACH ROW EXECUTE FUNCTION actualizar_fecha_modificacion();


-- Poblar datos iniciales mínimos (ej. una configuración por defecto, un usuario admin)
-- Esto es opcional, pero puede ser útil para el primer arranque.
-- IMPORTANTE: Las contraseñas/PINs deben ser HASHEADOS antes de insertarlos aquí.
-- Por ahora, dejo un placeholder para el PIN hash. Deberás generar uno real con Argon2/bcrypt.
INSERT INTO configuracion_negocio (nombre_negocio, simbolo_moneda) VALUES ('Mi Negocio POS', '$');

-- Ejemplo de PIN '1234' hasheado con Argon2 (ESTE HASH ES SOLO UN EJEMPLO, GENERA EL TUYO):
-- Para generar un hash, podrías usar una herramienta online para una prueba rápida, o un script simple en Rust.
-- Ejemplo Rust (añade `argon2` y `rand_core` con feature `std` a [dev-dependencies]):
/*
fn main() {
    let password = b"1234";
    let salt = rand_core::OsRng.gen::<[u8; 16]>(); // O usa un salt fijo para pruebas iniciales si es más simple
    let config = argon2::Config::default();
    let hash = argon2::hash_encoded(password, &salt, &config).unwrap();
    println!("{}", hash);
}
*/
-- Suponiendo que el hash de '1234' es '$argon2id$v=19$m=19456,t=2,p=1$abcdefghijklmnop$qwertzuiopasdfghjklyxcvbnm'
INSERT INTO usuarios_pin (nombre_empleado, pin_hash, rol) VALUES ('Administrador Principal', '$argon2id$v=19$m=19456,t=2,p=1$SALTPARAPINADMIN$HASHVALIDODELPINADMIN1234', 'ADMINISTRADOR');
INSERT INTO usuarios_pin (nombre_empleado, pin_hash, rol) VALUES ('Cajero Demo', '$argon2id$v=19$m=19456,t=2,p=1$SALTPARAPINCAJERO$HASHVALIDODELPINCAJERO5678', 'CAJERO');

-- Puedes añadir una categoría por defecto si quieres
INSERT INTO categorias (nombre, descripcion, activa) VALUES ('General', 'Categoría por defecto para productos sin asignar', TRUE);