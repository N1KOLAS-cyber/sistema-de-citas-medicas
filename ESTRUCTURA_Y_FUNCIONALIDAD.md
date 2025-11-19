    # 📋 ESTRUCTURA Y FUNCIONALIDAD COMPLETA DE LA APLICACIÓN

    ## 🏗️ ARQUITECTURA GENERAL

    ### Estructura de Directorios

    ```
    lib/
    ├── main.dart                          # Punto de entrada principal
    ├── firebase_options.dart              # Configuración de Firebase
    │
    ├── bloc/                              # Gestión de estado con BLoC
    │   ├── dashboard_bloc.dart           # BLoC para Dashboard médico
    │   ├── dashboard_event.dart          # Eventos del Dashboard
    │   └── dashboard_state.dart          # Estados del Dashboard
    │
    ├── models/                            # Modelos de datos
    │   ├── user_model.dart               # Modelo de usuario (Paciente/Médico)
    │   ├── appointment_model.dart        # Modelo de citas médicas
    │   ├── doctor_availability_model.dart # Modelo de disponibilidad
    │   └── specialty_model.dart          # Modelo de especialidades
    │
    ├── services/                          # Servicios y lógica de negocio
    │   ├── firestore_service.dart       # Servicio de Firestore
    │   ├── admin_service.dart            # Servicio de administración
    │   ├── advice_service.dart           # Servicio de consejos médicos
    │   ├── bulk_availability_service.dart # Servicio de horarios masivos
    │   └── migration_service.dart        # Servicio de migración
    │
    ├── tabs/                              # Páginas principales de la app
    │   ├── simple_login_page.dart        # Página de login principal
    │   ├── login_page.dart               # Página de login alternativa
    │   ├── register_page.dart            # Página de registro
    │   ├── forgot_password_page.dart     # Recuperación de contraseña
    │   ├── home_page.dart                # Página principal (Home)
    │   ├── dashboard_page.dart           # Dashboard médico (SOLO MÉDICOS)
    │   ├── appointments_page.dart        # Página de citas
    │   ├── doctor_appointments_page.dart  # Gestión de citas para médicos
    │   ├── create_appointment_page.dart  # Crear nueva cita
    │   ├── doctors_page.dart             # Lista de doctores
    │   ├── doctor_availability_page.dart  # Gestión de horarios médicos
    │   ├── profile_page.dart             # Perfil de usuario
    │   ├── edit_profile_page.dart        # Editar perfil
    │   ├── messages_page.dart            # Mensajería
    │   ├── admin_tools_page.dart         # Herramientas de administración
    │   └── privacy_terms_page.dart       # Términos y privacidad
    │
    ├── widgets/                           # Widgets reutilizables
    │   └── app_drawer.dart               # Sidebar global de la app
    │
    ├── constants/                         # Constantes de la aplicación
    │   └── app_constants.dart            # Constantes globales
    │
    └── utils/                             # Utilidades
        ├── date_utils.dart               # Utilidades de fechas
        └── integration_helper.dart       # Helper de integración
    ```

    ---

    ## 🔐 SISTEMA DE AUTENTICACIÓN

    ### Flujo de Autenticación

    1. **Login (`simple_login_page.dart`)**
    - Campos: Email y Contraseña
    - **NO incluye selector de rol** (el rol se determina automáticamente)
    - Accesos rápidos: Admin, Usuario, Invitado
    - Navegación a registro y recuperación de contraseña

    2. **Registro (`register_page.dart`)**
    - Campos: Nombre, Email, Teléfono, Contraseña
    - Checkbox "Soy doctor" para definir rol
    - Si es doctor: Especialidad y Número de licencia
    - El rol se guarda automáticamente: "Médico" o "Paciente"

    3. **Recuperación de Contraseña (`forgot_password_page.dart`)**
    - Envío de email de recuperación

    ### Determinación de Rol

    - **Automática en Login:**
    - Si email contiene "admin" → Rol: "Médico"
    - Si email contiene "test" → Rol: "Paciente"
    - Si email contiene "anonimo" → Rol: "Paciente"
    - Por defecto → Rol: "Paciente"
    - Si el usuario existe en Firestore → Usa el rol guardado

    - **En Registro:**
    - Si marca "Soy doctor" → Rol: "Médico"
    - Si no marca → Rol: "Paciente"

    ---

    ## 👤 SISTEMA DE ROLES

    ### Roles Disponibles

    1. **Paciente**
    - Puede agendar citas
    - Ver sus citas
    - Buscar doctores
    - Ver perfil y editarlo

    2. **Médico**
    - Acceso al **Dashboard** (exclusivo)
    - Gestionar citas pendientes
    - Configurar horarios de disponibilidad
    - Ver todas sus citas
    - Ver perfil y editarlo

    3. **Administrador** (email contiene "admin")
    - Todas las funciones de médico
    - Acceso a herramientas administrativas
    - Creación de horarios masivos

    ---

    ## 📱 PÁGINAS PRINCIPALES

    ### 1. Home Page (`home_page.dart`)

    **Funcionalidad:**
    - Página principal después del login
    - Muestra contenido según el rol del usuario
    - Navegación con tabs inferiores
    - **Sidebar (Drawer) global** con navegación

    **Contenido por Rol:**

    **Para Pacientes:**
    - Saludo personalizado
    - Consejo del día
    - Estadísticas de citas (Total, Pendientes)
    - Acciones rápidas:
    - Agregar Cita
    - Buscar Doctores
    - Mis Citas

**Para Médicos:**
- Saludo personalizado con especialidad
- Consejo del día
- Estadísticas profesionales
- Acciones rápidas:
  - Gestionar Citas
  - Gestionar Horarios
  - Ver Mis Citas
  - **❌ NO incluye widget del Dashboard** (solo accesible desde sidebar)

    **Navegación:**
    - Tabs inferiores: Inicio, Citas, Doctores, Perfil
    - Sidebar (Drawer) con todas las opciones

    ---

### 2. Dashboard Page (`dashboard_page.dart`) ⭐ **EXCLUSIVO PARA MÉDICOS**

**Acceso:**
- **✅ SOLO desde el Sidebar (Drawer)** - Botón de menú hamburguesa
- **❌ NO aparece como widget en Home Page**
- **❌ NO aparece en acciones rápidas**
- Solo visible para usuarios con rol "Médico"
- Botón de menú en AppBar para abrir el sidebar

    **Funcionalidad:**
    - Dashboard profesional con gráficos en tiempo real
    - Usa **BlocBuilder** para actualización automática
    - Datos obtenidos desde Firebase Cloud Firestore

    **Componentes:**

    1. **Header del Médico**
    - Nombre y especialidad
    - Icono médico

    2. **KPIs Principales (3 tarjetas)**
    - Total de Citas
    - Citas Pendientes
    - Total de Pacientes

    3. **Gráfico de Líneas**
    - Tendencias de citas por mes
    - "Citas Creadas vs Citas Completadas"
    - Área sombreada con gradiente

    4. **Gráfico de Dona (Pie Chart)**
    - Distribución de citas por estado
    - Porcentajes: Pendientes, Confirmadas, Completadas, Canceladas
    - Leyenda con colores

    5. **Gráfico de Barras**
    - Citas por día de la semana
    - Barras verticales con gradientes

    6. **Resumen Detallado**
    - Total de Citas
    - Citas Pendientes
    - Citas Confirmadas
    - Citas Completadas
    - Citas Canceladas
    - Total de Pacientes
    - Información de actualización en tiempo real

    **Tecnologías:**
    - `flutter_bloc` para gestión de estado
    - `fl_chart` para gráficos profesionales
    - `BlocBuilder` para actualización en tiempo real
    - Firebase Cloud Firestore como fuente de datos

    ---

    ### 3. Appointments Page (`appointments_page.dart`)

    **Funcionalidad:**
    - Lista de citas del usuario
    - Filtros por estado
    - Cancelación de citas
    - Diferente vista para médicos y pacientes

    **Para Pacientes:**
    - Muestra sus citas programadas
    - Botón para crear nueva cita
    - Filtros: Todas, Pendientes, Confirmadas, Completadas

    **Para Médicos:**
    - Redirige a `DoctorAppointmentsPage`
    - Gestión de citas pendientes
    - Aprobación/rechazo de citas

    ---

    ### 4. Doctor Appointments Page (`doctor_appointments_page.dart`)

    **Funcionalidad:**
    - Gestión de citas para médicos
    - Aprobación/rechazo de citas pendientes
    - Vista de citas confirmadas
    - Filtros por estado y fecha

    ---

    ### 5. Create Appointment Page (`create_appointment_page.dart`)

    **Funcionalidad:**
    - Crear nueva cita médica
    - Selección de doctor
    - Selección de fecha y hora
    - Campos: Síntomas, Notas
    - Edición de citas existentes

    ---

    ### 6. Doctors Page (`doctors_page.dart`)

    **Funcionalidad:**
    - Lista de doctores disponibles
    - Búsqueda por nombre o especialidad
    - Filtros por especialidad
    - Vista de perfil del doctor
    - Agendar cita con doctor seleccionado

    ---

    ### 7. Doctor Availability Page (`doctor_availability_page.dart`)

    **Funcionalidad:**
    - Configuración de horarios disponibles
    - Selección de fecha y horas
    - Creación masiva de horarios
    - Vista de disponibilidad

    ---

    ### 8. Profile Page (`profile_page.dart`)

    **Funcionalidad:**
    - Información personal del usuario
    - **Selector de rol** (Paciente/Médico)
    - Estadísticas profesionales (para médicos)
    - Edición de perfil
    - Cambio de contraseña
    - Cerrar sesión

    ---

    ### 9. Edit Profile Page (`edit_profile_page.dart`)

    **Funcionalidad:**
    - Edición de información personal
    - **Selector de rol** (Paciente/Médico)
    - Campos según rol:
    - Paciente: Historial médico, edad, lugar de nacimiento
    - Médico: Especialidad, número de licencia

    ---

## 🎨 SIDEBAR GLOBAL (App Drawer)

### Ubicación: `lib/widgets/app_drawer.dart`

**Funcionalidad:**
- **Sidebar accesible desde TODAS las páginas principales de la app**
- **REPLICA todas las funcionalidades del HomePage** + Dashboard
- Navegación según rol del usuario
- Información del usuario en el header
- Obtiene el usuario automáticamente desde Firestore si no se proporciona

**Páginas con Sidebar:**
- ✅ Home Page
- ✅ Dashboard Page (médicos)
- ✅ Appointments Page
- ✅ Doctors Page
- ✅ Profile Page
- ✅ Todas las páginas principales

**Opciones del Sidebar (REPLICANDO HomePage):**

**Sección: Acciones Rápidas**

**Para Todos:**
- 🏠 Inicio

**Para MÉDICOS (replicando HomePage):**
- 📊 **Dashboard** ⭐ (EXCLUSIVO - Solo en sidebar, no en HomePage)
- 📅 **Gestionar Citas** - Revisa y aprueba citas pendientes
- ⏰ **Gestionar Horarios** - Configura tu disponibilidad de consultas
- 📆 **Ver Mis Citas** - Gestiona tus citas programadas

**Para PACIENTES (replicando HomePage):**
- ➕ **Agregar Cita** - Reserva una consulta con un especialista
- 🔍 **Buscar Doctores** - Encuentra especialistas cerca de ti
- 📆 **Mis Citas** - Revisa tus citas programadas

**Para ADMINISTRADORES (replicando HomePage):**
- ⚙️ **Herramientas Admin** - Crear horarios masivos y más utilidades

**Navegación Adicional:**
- 👨‍⚕️ Doctores - Lista de especialistas
- 👤 Mi Perfil
- 🚪 Cerrar Sesión

**Características:**
- **Replica completa** de todas las acciones del HomePage
- Header con información del usuario (nombre, email, avatar)
- Iconos diferenciados por sección con colores
- Subtítulos descriptivos iguales al HomePage
- Navegación fluida entre páginas
- Confirmación para cerrar sesión
- Carga automática del usuario desde Firestore
- **Dashboard solo disponible en sidebar** (no en HomePage)

    ---

    ## 🔄 GESTIÓN DE ESTADO

    ### BLoC Pattern

    **Dashboard BLoC:**
    - `DashboardBloc`: Gestiona el estado del dashboard
    - `LoadDashboardData`: Carga inicial de datos
    - `RefreshDashboardData`: Actualización de datos
    - Estados: `Loading`, `Loaded`, `Error`

    **Datos Calculados:**
    - Total de citas
    - Citas por estado (pending, confirmed, completed, cancelled)
    - Citas por mes
    - Total de pacientes únicos

    ---

    ## 🗄️ BASE DE DATOS (Firebase Cloud Firestore)

    ### Colecciones

    1. **`usuarios`**
    - Datos de usuarios (pacientes y médicos)
    - Campos: id, email, name, phone, role, isDoctor, specialty, etc.

    2. **`citas`**
    - Citas médicas
    - Campos: id, patientId, doctorId, appointmentDate, status, type, etc.

    3. **`disponibilidad_medicos`**
    - Horarios disponibles de médicos
    - Campos: doctorId, date, timeSlot, isAvailable, etc.

    4. **`consejos_medicos`** (opcional)
    - Consejos médicos aleatorios

    ---

    ## 🎯 FLUJOS PRINCIPALES

    ### Flujo de Paciente

    1. Login → Home Page
    2. Ver citas / Agendar cita / Buscar doctores
    3. Acceso desde Sidebar a todas las opciones
    4. **NO tiene acceso al Dashboard**

    ### Flujo de Médico

    1. Login → Home Page
    2. Gestionar citas / Configurar horarios
    3. **Acceso al Dashboard desde Sidebar** ⭐
    4. Ver estadísticas en tiempo real
    5. Gestión completa de citas

    ### Flujo de Administrador

    1. Login → Home Page
    2. Todas las funciones de médico
    3. Acceso a herramientas administrativas
    4. Creación de horarios masivos

    ---

    ## 📊 DASHBOARD MÉDICO - DETALLES TÉCNICOS

    ### Indicadores (KPIs)

    1. **Total de Citas Creadas**
    - Cuenta todas las citas del médico
    - Fuente: Colección `citas` filtrada por `doctorId`

    2. **Citas Próximas/Pendientes**
    - Citas con estado "pending" o "confirmed" que sean futuras
    - Filtrado por fecha

    3. **Total de Pacientes Registrados**
    - Cuenta pacientes únicos que han tenido citas con el médico
    - Usa Set para evitar duplicados

    ### Actualización en Tiempo Real

    - **BlocBuilder**: Reconstruye UI cuando cambia el estado
    - **StreamBuilder**: (Alternativa) Escucha cambios en Firestore
    - **Refresh manual**: Botón de refresh y pull-to-refresh

    ### Gráficos

    - **Gráfico de Líneas**: Tendencias mensuales
    - **Gráfico de Dona**: Distribución por estado
    - **Gráfico de Barras**: Citas por día de la semana

    ---

    ## 🔧 CONFIGURACIÓN Y DEPENDENCIAS

    ### Dependencias Principales

    ```yaml
    dependencies:
    flutter_bloc: ^8.1.6      # Gestión de estado
    equatable: ^2.0.5         # Comparación de estados
    fl_chart: ^0.68.0         # Gráficos profesionales
    firebase_core: ^2.32.0    # Firebase Core
    firebase_auth: ^4.20.0    # Autenticación
    cloud_firestore: ^4.17.5  # Base de datos
    provider: ^6.1.2          # State management adicional
    ```

    ---

    ## ✅ CARACTERÍSTICAS IMPLEMENTADAS

    - ✅ Sistema de autenticación completo
    - ✅ Sistema de roles (Paciente/Médico)
    - ✅ Dashboard exclusivo para médicos
    - ✅ Sidebar global en toda la app
    - ✅ Gestión de citas médicas
    - ✅ Gestión de horarios médicos
    - ✅ Perfiles de usuario editables
    - ✅ Selector de rol en perfil (NO en login)
    - ✅ Gráficos profesionales en dashboard
    - ✅ Actualización en tiempo real con BlocBuilder
    - ✅ Integración completa con Firebase

    ---

    ## 🚀 PRÓXIMAS MEJORAS SUGERIDAS

    - Notificaciones push
    - Chat en tiempo real
    - Historial médico completo
    - Reportes PDF
    - Exportación de datos
    - Calendario integrado
    - Recordatorios de citas

    ---

## 📝 NOTAS IMPORTANTES

1. **Dashboard solo para médicos**: El dashboard NO aparece como widget en Home Page, **SOLO accesible desde el Sidebar**
2. **Sidebar replica HomePage**: El sidebar tiene **TODAS las funcionalidades del HomePage** más el Dashboard**
3. **Funcionalidad duplicada**: Tanto el HomePage como el Sidebar tienen las mismas acciones rápidas, permitiendo acceso desde ambos lugares
4. **Rol no se selecciona en login**: Se determina automáticamente o se usa el guardado en Firestore
5. **Sidebar global**: Disponible en todas las páginas principales
6. **Actualización en tiempo real**: El dashboard se actualiza automáticamente usando BlocBuilder
7. **3 indicadores principales**: Total citas, Citas pendientes, Total pacientes

    ---

    **Última actualización**: Noviembre 2025
    **Versión**: 1.0.0

