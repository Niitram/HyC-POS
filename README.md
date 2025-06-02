# Sistema POS

Sistema de Punto de Venta desarrollado con Tauri + React + Rust para pequeños y medianos negocios.

## 📋 Descripción

Sistema completo de punto de venta que permite:

- Gestión de productos y categorías
- Procesamiento de ventas en tiempo real
- Reportes y cierre de caja
- Configuración personalizable del negocio

## 🚀 Tecnologías

- **Frontend**: React + JavaScript + Tailwind CSS
- **Backend**: Rust + Tauri v2
- **Base de Datos**: PostgreSQL
- **Herramientas**: ESLint, Prettier, Git

## 🛠️ Configuración del Entorno de Desarrollo

### Prerrequisitos

1. **Node.js** (LTS) - [Descargar](https://nodejs.org/)
2. **Rust** - [Instalar con rustup](https://rustup.rs/)
3. **Visual Studio** con herramientas de C++ (para Windows)
4. **PostgreSQL** - [Descargar](https://www.postgresql.org/download/)

### Instalación

1. Clonar el repositorio:

```bash
git clone https://github.com/TU_USUARIO/sistema-pos.git
cd sistema-pos
```

2. Instalar dependencias:

```bash
npm install
```

3. Configurar la base de datos:

```sql
-- Crear usuario para la aplicación
CREATE USER usuario_pos_dev WITH PASSWORD 'tu_contraseña_segura';

-- Crear base de datos
CREATE DATABASE db_pos_dev OWNER = usuario_pos_dev;

-- Otorgar privilegios
GRANT ALL PRIVILEGES ON DATABASE db_pos_dev TO usuario_pos_dev;
```

4. Ejecutar en modo desarrollo:

```bash
npm run tauri dev
```

## 📁 Estructura del Proyecto

```
sistema-pos/
├── src-tauri/          # Backend Rust + Configuración Tauri
│   ├── src/
│   │   ├── main.rs     # Punto de entrada
│   │   ├── commands/   # Comandos Tauri (futuro)
│   │   ├── models/     # Modelos de datos (futuro)
│   │   └── db.rs       # Conexión BD (futuro)
│   └── tauri.conf.json # Configuración principal
├── src/                # Frontend React
│   ├── components/     # Componentes reutilizables
│   ├── pages/          # Vistas principales
│   ├── services/       # Comunicación con backend
│   └── utils/          # Funciones auxiliares
└── public/             # Archivos estáticos
```

## 🏗️ Estado del Proyecto

**Fase Actual**: Configuración inicial completada

- ✅ Entorno de desarrollo configurado
- ✅ Estructura base del proyecto
- ✅ Configuración de Tauri v2
- ⏳ Próximo: Diseño de base de datos

## 📝 Roadmap MVP

### Módulos Principales

1. **Gestión de Productos** - Categorías, productos, variantes y precios
2. **Punto de Venta (POS)** - Interfaz de ventas, carrito, cobro
3. **Reportes** - Ventas del día, cierre de caja
4. **Configuración** - Datos del negocio, impresora

### Funcionalidades Futuras

- Gestión de empleados
- Control de stock
- Promociones y descuentos
- Reportes avanzados
- Sistema de fidelización

## 🔒 Seguridad y Licenciamiento

- Código de verificación mensual implementado
- Notificaciones de vencimiento 5 días antes
- Validación de entradas en backend
- Almacenamiento seguro de credenciales

## 👤 Desarrollador

**Marto** - Desarrollador Principal

- Experiencia: Full Stack Web Development
- Tecnologías: JavaScript, React, Node.js, Rust (aprendiendo)

## 📄 Licencia

Proyecto privado - Todos los derechos reservados

---

**Versión**: 0.1.0 - Configuración Inicial
**Última actualización**: $(date)
