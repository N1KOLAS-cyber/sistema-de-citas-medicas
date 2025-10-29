# 📚 Documentación Completa - Sistema NERV

## 🎯 Sistema de Citas Médicas NERV

> Aplicación móvil multiplataforma para la gestión eficiente de citas médicas entre pacientes y profesionales de la salud.

![NERV Logo](assets/images/logo.jpeg)

---

## 🚀 ¡NUEVO! Integración Completa de Colecciones

**Las 3 colecciones de Firestore están 100% integradas y funcionando:**
- ✅ `usuarios` - Gestión completa de usuarios
- ✅ `citas` - Sistema de citas médicas
- ✅ `disponibilidad_medicos` - Horarios de doctores

---

## 📋 Tabla de Contenidos

- [Instalación Rápida](#-instalación-rápida)
- [Descripción General](#descripción-general)
- [Características](#características)
- [Tecnologías](#tecnologías)
- [Estructura del Proyecto](#estructura-del-proyecto)
- [Configuración](#configuración)
- [Colecciones de Firestore](#-colecciones-de-firestore)
- [Nuevas Funcionalidades](#-nuevas-funcionalidades-implementadas)
- [Guía de Pruebas](#-guía-de-pruebas-rápidas)
- [Troubleshooting](#-solución-de-problemas)
- [Comandos Útiles](#-comandos-útiles)

---

## 🎯 Instalación Rápida

**¿Quieres el sistema funcionando en 10 minutos?**

### Paso 1: Configurar Firestore (CRÍTICO)
1. Ve a [Firebase Console](https://console.firebase.google.com)
2. Tu proyecto → Firestore Database → Rules
3. Copia las reglas de la sección [Reglas de Firestore](#-reglas-de-firestore)
4. Publicar

### Paso 2: Ejecutar
```bash
flutter run
```

### Paso 3: Probar
- Sigue la [Guía de Pruebas](#-guía-de-pruebas-rápidas)

---

## Descripción General

**NERV** es un sistema integral de gestión de citas médicas desarrollado como proyecto académico del cuarto cuatrimestre. La aplicación permite a pacientes agendar citas con doctores especializados, gestionar su historial médico y facilitar la comunicación entre profesionales de la salud y pacientes.

Desarrollado con Flutter para garantizar compatibilidad multiplataforma (Android, iOS, Web, Desktop) y Firebase como backend para autenticación en tiempo real y almacenamiento de datos en la nube.

### Objetivos del Proyecto

- ✅ Implementar arquitectura limpia y escalable
- ✅ Integrar servicios de Firebase (Authentication, Firestore)
- ✅ Diseñar interfaces de usuario centradas en la experiencia del usuario
- ✅ Desarrollar aplicación multiplataforma con una única base de código
- ✅ Aplicar principios de desarrollo móvil moderno
- ✅ **Sistema completo de gestión de citas médicas en tiempo real**

---

## Características

### Módulo de Pacientes

| Funcionalidad | Descripción | Estado |
|--------------|-------------|--------|
| Registro de Usuario | Crear cuenta con validación de datos | Implementado |
| Autenticación | Login con email/password y login anónimo | Implementado |
| Búsqueda de Doctores | Filtrar por especialidad y búsqueda por nombre | Implementado |
| Visualización de Citas | Ver historial y citas programadas | Implementado |
| Gestión de Perfil | Actualizar información personal | Implementado |
| Agendamiento de Citas | Reservar citas con doctores | Implementado |

### Módulo de Doctores

| Funcionalidad | Descripción | Estado |
|--------------|-------------|--------|
| Registro Profesional | Registro con especialidad y licencia médica | Implementado |
| Panel de Control | Dashboard con estadísticas y métricas | Implementado |
| Gestión de Citas | Ver y administrar citas programadas | Implementado |
| Perfil Profesional | Información médica y credenciales | Implementado |
| Gestión de Horarios | Crear y administrar disponibilidad | Implementado |

### Módulo de Administración

| Funcionalidad | Descripción | Estado |
|--------------|-------------|--------|
| Acceso Rápido | Login directo con credenciales predefinidas | Implementado |
| Gestión de Usuarios | Administrar pacientes y doctores | Implementado |
| Herramientas Admin | Crear horarios masivos y utilidades | Implementado |

---

## Tecnologías

### Stack Tecnológico

```yaml
Frontend Framework: Flutter 3.9.2+
Lenguaje: Dart
Backend as a Service: Firebase
  - Firebase Authentication
  - Cloud Firestore
Gestión de Estado: Provider 6.1.2
Diseño UI/UX: Material Design 3
```

### Dependencias Principales

| Paquete | Versión | Propósito |
|---------|---------|-----------|
| `firebase_core` | ^2.32.0 | Configuración de Firebase |
| `firebase_auth` | ^4.20.0 | Autenticación de usuarios |
| `cloud_firestore` | ^4.17.5 | Base de datos en tiempo real |
| `provider` | ^6.1.2 | Gestión de estado |
| `intl` | ^0.19.0 | Internacionalización y formato de fechas |
| `http` | ^1.2.2 | Peticiones HTTP |

---

## Estructura del Proyecto

```
sistema_citas_medicas/
│
├── android/                    # Configuración Android
├── ios/                        # Configuración iOS
├── web/                        # Configuración Web
├── windows/                    # Configuración Windows
├── linux/                      # Configuración Linux
├── macos/                      # Configuración macOS
│
├── assets/                     # Recursos estáticos
│   └── images/
│       └── logo.jpeg          # Logo de la aplicación
│
├── lib/                        # Código fuente principal
│   ├── constants/             # Constantes de la aplicación
│   │   └── app_constants.dart
│   │
│   ├── models/                # Modelos de datos
│   │   ├── user_model.dart
│   │   ├── appointment_model.dart
│   │   ├── doctor_availability_model.dart
│   │   └── specialty_model.dart
│   │
│   ├── services/              # Servicios y lógica de negocio
│   │   ├── admin_service.dart
│   │   ├── firestore_service.dart
│   │   ├── bulk_availability_service.dart
│   │   └── migration_service.dart
│   │
│   ├── tabs/                  # Pantallas de la aplicación
│   │   ├── simple_login_page.dart
│   │   ├── login_page.dart
│   │   ├── register_page.dart
│   │   ├── forgot_password_page.dart
│   │   ├── dashboard_page.dart
│   │   ├── appointments_page.dart
│   │   ├── doctors_page.dart
│   │   ├── profile_page.dart
│   │   ├── edit_profile_page.dart
│   │   ├── doctor_availability_page.dart
│   │   ├── create_appointment_page.dart
│   │   ├── messages_page.dart
│   │   ├── privacy_terms_page.dart
│   │   └── admin_tools_page.dart
│   │
│   ├── utils/                 # Utilidades
│   │   ├── date_utils.dart
│   │   └── integration_helper.dart
│   │
│   ├── firebase_options.dart  # Configuración Firebase
│   └── main.dart             # Punto de entrada
│
├── pubspec.yaml               # Dependencias del proyecto
├── README.md                  # Este archivo
└── firebase.json              # Configuración de Firebase
```

---

## Configuración

### Configuración de Firebase

#### 1. Crear Proyecto en Firebase

1. Acceder a [Firebase Console](https://console.firebase.google.com/)
2. Crear nuevo proyecto llamado "sistema-citas-medicas"
3. Habilitar Google Analytics (opcional)

#### 2. Habilitar Servicios

**Authentication:**
1. Ir a Authentication > Sign-in method
2. Habilitar "Email/Password"
3. Habilitar "Anonymous" (opcional)

**Firestore Database:**
1. Ir a Firestore Database
2. Crear base de datos en modo "production"
3. Configurar reglas de seguridad (ver sección siguiente)

#### 3. Configurar Flutter con Firebase

El proyecto ya incluye `firebase_options.dart` con las configuraciones necesarias para:
- Android
- iOS
- Web
- Windows
- macOS

**Proyecto Firebase:** `doctor-appoitment-4b`

---

## 🔥 Colecciones de Firestore

### 1. Colección de Usuarios (`usuarios`)

Esta colección almacena la información personal de cada usuario (pacientes y doctores).

#### Estructura del Documento

```dart
{
  "id": "userId_abc123",                    // UID de Firebase Auth
  "email": "usuario@ejemplo.com",           // Email del usuario
  "name": "Juan Pérez",                     // Nombre completo
  "phone": "+34 123 456 789",              // Teléfono
  "profileImage": "https://...",            // URL de imagen de perfil (opcional)
  "createdAt": 1697875200000,              // Timestamp de creación
  "updatedAt": 1697875200000,              // Timestamp de última actualización
  "isDoctor": false,                        // Si es doctor o paciente
  "age": 25,                               // Edad del usuario
  "birthplace": "Ciudad de México",        // Lugar de nacimiento
  
  // Campos específicos para pacientes:
  "medicalHistory": "Alergia a penicilina...", // Historial médico/enfermedades
  
  // Campos específicos para doctores:
  "specialty": "Cardiología",               // Especialidad médica
  "licenseNumber": "MED-12345",            // Número de licencia
  "rating": 4.5,                           // Calificación promedio
  "totalAppointments": 150                  // Total de citas atendidas
}
```

### 2. Colección de Citas (`citas`)

Esta colección guarda todas las citas programadas en la aplicación.

#### Estructura del Documento

```dart
{
  "id": "appointment_xyz789",              // ID único de la cita
  "patientId": "userId_abc123",           // ID del paciente
  "doctorId": "doctorId_def456",          // ID del médico
  "patientName": "Juan Pérez",            // Nombre del paciente
  "doctorName": "Dr. María García",       // Nombre del doctor
  "specialty": "Cardiología",             // Especialidad
  "appointmentDate": 1697875200000,       // Fecha y hora de la cita (timestamp)
  "timeSlot": "09:00 - 10:00",           // Franja horaria
  "status": "pending",                     // Estado: pending, confirmed, completed, cancelled
  "type": "consultation",                  // Tipo: consultation, followUp, emergency, routine
  "notes": "Primera consulta...",         // Notas adicionales (opcional)
  "symptoms": "Dolor de pecho...",        // Síntomas reportados (opcional)
  "diagnosis": "...",                      // Diagnóstico (opcional)
  "prescription": "...",                   // Receta médica (opcional)
  "cost": 50.00,                          // Costo de la consulta (opcional)
  "createdAt": 1697875200000,             // Timestamp de creación
  "updatedAt": 1697875200000              // Timestamp de última actualización
}
```

### 3. Colección de Disponibilidad de Médicos (`disponibilidad_medicos`)

Esta colección es vital para la lógica de validación de la agenda. Almacena los horarios disponibles de cada médico.

#### Estructura del Documento

```dart
{
  "id": "availability_123",                // ID único del horario
  "doctorId": "doctorId_def456",          // ID del médico
  "doctorName": "Dr. María García",       // Nombre del doctor
  "date": 1697875200000,                  // Fecha del horario (timestamp)
  "timeSlot": "09:00 - 10:00",           // Franja horaria formateada
  "startTime": 1697875200000,             // Hora de inicio (timestamp)
  "endTime": 1697878800000,               // Hora de fin (timestamp)
  "isAvailable": true,                     // Si el horario está disponible
  "appointmentId": null,                   // ID de la cita si está ocupado (opcional)
  "createdAt": 1697875200000,             // Timestamp de creación
  "updatedAt": 1697875200000              // Timestamp de última actualización
}
```

---

## 🔐 Reglas de Firestore

**IMPORTANTE**: Configura estas reglas en Firebase Console para proteger tus datos:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Colección de usuarios
    match /usuarios/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Colección de citas
    match /citas/{appointmentId} {
      allow read: if request.auth != null && 
        (resource.data.patientId == request.auth.uid || 
         resource.data.doctorId == request.auth.uid);
      
      allow create: if request.auth != null && 
        request.resource.data.patientId == request.auth.uid;
      
      allow update: if request.auth != null && 
        (resource.data.patientId == request.auth.uid || 
         resource.data.doctorId == request.auth.uid);
      
      allow delete: if request.auth != null && 
        resource.data.patientId == request.auth.uid;
    }
    
    // Colección de disponibilidad de médicos
    match /disponibilidad_medicos/{availabilityId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        request.resource.data.doctorId == request.auth.uid;
    }
  }
}
```

### Cómo Aplicar las Reglas:

1. Abre [Firebase Console](https://console.firebase.google.com)
2. Selecciona tu proyecto
3. Ve a **Firestore Database** > **Rules**
4. Copia y pega las reglas de arriba
5. Haz clic en **Publicar**

---

## ✨ Nuevas Funcionalidades Implementadas

### 1️⃣ Widget de Consejos Médicos 🌮🐸

**Ubicación:** Dashboard (Inicio)  
**Color:** Verde agua/teal

Al hacer clic, se abre un diálogo con consejos divertidos:

**Consejos incluidos:**
- 🌮 "Si comiste tacos de la esquina y te cayeron mal" → Médico General
- 🐸 "Si te besó el sapo y ahora tienes calentura" → Médico General
- ❤️ "Si sientes que tu corazón late diferente" → Cardiólogo
- 👶 "Si tu bebé tiene fiebre o malestar" → Pediatra
- 👁️ "Si ves borroso o te duelen los ojos" → Oftalmólogo
- 🦴 "Si te duelen los huesos o articulaciones" → Ortopedista

### 2️⃣ Chat Widget Flotante 💬

**Ubicación:** Botón flotante en "Mis Citas"  
**Funcionalidad:** Widget flotante sin funcionalidad real (solo visual)

- 🖤 Fondo semi-transparente (overlay)
- 📱 Tamaño fijo: 400x600px máximo
- 🎨 Bordes redondeados y sombra elegante
- ❌ Botón X para cerrar

### 3️⃣ Formulario de Perfil Completo 📝

**Campos Nuevos Agregados:**
- ✅ **Edad** (campo numérico)
- ✅ **Lugar de Nacimiento** (texto)

**Campos Existentes:**
- Nombre, Teléfono, Edad, Lugar de Nacimiento
- Historial Médico (solo pacientes)
- Especialidad (solo doctores)
- Número de Licencia (solo doctores)

### 4️⃣ Pantalla de Privacidad y Términos 📜

**Ubicación:** Perfil → "Privacidad y Términos"

**Contenido:**
1. **Introducción** - Aceptación de términos
2. **Recopilación de Datos** - Qué datos se recopilan
3. **Uso Privado** - Cómo se usan los datos
4. **Fundamento Legal** - Leyes mexicanas aplicables:
   - LFPDPPP (Ley Federal de Protección de Datos)
   - Artículo 6° - Principios
   - Artículo 8° - Consentimiento
   - Artículo 16° - Derechos ARCO
   - Ley General de Salud - Artículo 100 Bis
   - NOM-024-SSA3-2012
5. **Derechos ARCO** - Derechos del usuario
6. **Medidas de Seguridad** - Protección implementada
7. **Datos Sensibles** - Manejo de información médica
8. **Conservación** - Tiempo de almacenamiento
9. **Contacto** - Información de contacto

### 5️⃣ Filtros Simplificados en Citas 📅

**Antes:** Todas, Pendientes, Confirmadas, Completadas, Canceladas (5 opciones)  
**Ahora:** 
- **Todas** - Todas las citas
- **Próximas** - Solo citas futuras (pendientes/confirmadas) ⭐ Por defecto
- **Canceladas** - Solo canceladas

### 6️⃣ Botón "Agendar Cita" Mejorado

**En Lista de Doctores:**
- ✅ Ahora muestra **indicador de carga** (spinner)
- ✅ Carga tus datos automáticamente
- ✅ Te lleva con el **doctor ya seleccionado**
- ✅ Empiezas en **Paso 2** (fecha)

---

## 🧪 Guía de Pruebas Rápidas

### ⚡ Verificación Express (5 minutos)

#### 1️⃣ Configurar Reglas de Firestore (2 min)

**CRÍTICO:** Sin esto NO funcionará nada.

1. Ve a: https://console.firebase.google.com
2. Tu proyecto → Firestore Database → Rules
3. Copia las reglas de la sección [Reglas de Firestore](#-reglas-de-firestore)
4. **Publicar**

✅ Hecho cuando veas "Publicadas" en verde

#### 2️⃣ Ejecutar la App (1 min)

```bash
flutter run
```

#### 3️⃣ Prueba Rápida de Usuario (2 min)

1. **Registra un Doctor:**
   ```
   Nombre: Test Doctor
   Email: test.doctor@demo.com
   Teléfono: 123456789
   Contraseña: test123
   ✅ Marcar "Soy doctor"
   Especialidad: Cardiología
   Licencia: TEST-001
   ```

2. **Como Doctor → Gestionar Horarios:**
   - Fecha: Mañana
   - Crear Horarios (9am-5pm)

3. **Cierra sesión**

4. **Registra un Paciente:**
   ```
   Nombre: Test Paciente
   Email: test.paciente@demo.com
   Teléfono: 987654321
   Contraseña: test123
   ❌ NO marcar "Soy doctor"
   ```

5. **Como Paciente → Agendar Cita:**
   - Selecciona: Test Doctor
   - Fecha: Mañana (misma que los horarios)
   - Horario: Cualquiera disponible
   - Síntomas: "Prueba del sistema"
   - **Confirmar**

6. **¿Ves "¡Cita Creada!"?**
   - ✅ SÍ → ¡Todo funciona!
   - ❌ NO → Ve a [Solución de Problemas](#-solución-de-problemas)

### 🔍 Verificar en Firebase Console

1. Ve a: https://console.firebase.google.com
2. Tu proyecto → Firestore Database

**Deberías ver 3 colecciones:**

#### 📁 usuarios
```
2 documentos:
- test.doctor@demo.com (isDoctor: true)
- test.paciente@demo.com (isDoctor: false)
```

#### 📁 disponibilidad_medicos
```
8 documentos (horarios de 9am a 5pm)
Uno debe tener:
- isAvailable: false
- appointmentId: [ID de tu cita]
```

#### 📁 citas
```
1 documento:
- patientName: Test Paciente
- doctorName: Test Doctor
- status: pending
- symptoms: Prueba del sistema
```

### ✅ Lista de Verificación Rápida

- [ ] Reglas de Firestore publicadas
- [ ] App ejecutándose sin errores
- [ ] Doctor registrado
- [ ] Horarios creados
- [ ] Paciente registrado
- [ ] Cita creada exitosamente
- [ ] Verificado en Firebase Console

**¿Todos marcados?** → ✅ **¡INTEGRACIÓN COMPLETA EXITOSA!** 🎉

---

## 🐛 Solución de Problemas

### No veo horarios disponibles
```
1. Verifica fecha: ¿Es la misma donde el doctor creó horarios?
2. Firebase Console → disponibilidad_medicos
3. ¿Existen documentos para esa fecha?
4. ¿isAvailable es true?
```

### Error al crear cita
```
1. ¿Configuraste las reglas de Firestore?
2. ¿Hay conexión a internet?
3. Revisa la consola: flutter logs
```

### No aparecen datos
```
1. Cierra sesión y vuelve a iniciar
2. Verifica en Firebase Console que los datos existen
3. Revisa las reglas de Firestore
```

### "Missing or insufficient permissions"
**Solución**: Asegúrate de haber configurado las reglas de Firestore correctamente.

### "Index not found"
**Solución**: Firestore te dará un enlace para crear el índice necesario. Haz clic en el enlace y espera a que se cree el índice.

### Los cambios no se reflejan en tiempo real
**Solución**: Verifica que estés usando `StreamBuilder` en lugar de `FutureBuilder` para datos en tiempo real.

### No puedo crear citas
**Solución**: 
1. Verifica que el doctor tenga horarios disponibles creados
2. Asegúrate de que la fecha seleccionada sea futura
3. Revisa que el usuario esté autenticado correctamente

---

## 🔧 Comandos Útiles

### Desarrollo

```bash
# Ejecutar en modo desarrollo
flutter run

# Ejecutar en web
flutter run -d chrome

# Hot reload (en app en ejecución)
r

# Hot restart (en app en ejecución)
R

# Analizar código
flutter analyze

# Formatear código
flutter format .

# Limpiar build
flutter clean
```

### Testing

```bash
# Ejecutar tests
flutter test

# Ejecutar tests con coverage
flutter test --coverage

# Ver coverage
genhtml coverage/lcov.info -o coverage/html
```

### Build

```bash
# Build para Android
flutter build apk

# Build para iOS
flutter build ios

# Build para Web
flutter build web

# Build para Windows
flutter build windows
```

### Logs y Debugging

```bash
# Ver logs en tiempo real
flutter logs

# Ver errores específicos
flutter run --verbose

# Limpiar caché
flutter clean
flutter pub get
```

---

## 📊 Modelos de Datos

### UserModel

```dart
{
  id: String,
  email: String,
  name: String,
  phone: String,
  profileImage: String?,
  createdAt: DateTime,
  updatedAt: DateTime,
  isDoctor: bool,
  specialty: String?,        // Solo doctores
  licenseNumber: String?,    // Solo doctores
  rating: double?,           // Solo doctores
  totalAppointments: int?,   // Solo doctores
  medicalHistory: String?,   // Solo pacientes
  age: int?,                 // Edad del usuario
  birthplace: String?        // Lugar de nacimiento
}
```

### AppointmentModel

```dart
{
  id: String,
  patientId: String,
  doctorId: String,
  patientName: String,
  doctorName: String,
  specialty: String,
  appointmentDate: DateTime,
  timeSlot: String,
  status: AppointmentStatus,
  type: AppointmentType,
  notes: String?,
  symptoms: String?,
  diagnosis: String?,
  prescription: String?,
  cost: double?,
  createdAt: DateTime,
  updatedAt: DateTime
}
```

### Enumeraciones

**AppointmentStatus:**
- `pending` - Cita pendiente de confirmación
- `confirmed` - Cita confirmada
- `completed` - Cita completada
- `cancelled` - Cita cancelada

**AppointmentType:**
- `consultation` - Consulta general
- `followUp` - Seguimiento
- `emergency` - Emergencia
- `routine` - Revisión rutinaria

---

## 🎨 Especialidades Médicas

El sistema soporta las siguientes especialidades médicas:

| Especialidad | Precio Base | Duración Promedio |
|--------------|-------------|-------------------|
| Medicina General | $50.00 | 30 minutos |
| Cardiología | $80.00 | 45 minutos |
| Dermatología | $60.00 | 30 minutos |
| Pediatría | $55.00 | 30 minutos |
| Ginecología | $70.00 | 40 minutos |
| Ortopedia | $75.00 | 45 minutos |
| Neurología | $90.00 | 60 minutos |
| Oftalmología | $65.00 | 30 minutos |

---

## 🎨 Configuración de Colores

### Paleta de Colores Principal

```dart
Primary Color:    #1976D2  // Azul médico
Secondary Color:  #42A5F5  // Azul claro
Accent Color:     #26A69A  // Verde agua
Error Color:      #E57373  // Rojo suave
Success Color:    #81C784  // Verde éxito
Warning Color:    #FFB74D  // Naranja advertencia
```

### Botones de Acceso Rápido

```dart
Invitado:  Purple (#9C27B0)
Usuario:   Green (#4CAF50)
Admin:     Orange (#FF9800)
```

---

## 📱 Compatibilidad de Plataformas

| Plataforma | Versión Mínima | Estado |
|------------|----------------|--------|
| Android | API 21 (Android 5.0) | Soportado |
| iOS | iOS 11.0+ | Soportado |
| Web | Navegadores modernos | Soportado |
| Windows | Windows 10+ | Soportado |
| macOS | macOS 10.14+ | Soportado |
| Linux | Ubuntu 18.04+ | Soportado |

---

## 🏗️ Arquitectura

### Patrón de Diseño

El proyecto implementa una arquitectura modular basada en:

```
Presentación (UI)
    ↓
Lógica de Negocio (Services)
    ↓
Acceso a Datos (Firebase)
```

### Flujo de Autenticación

```
Usuario → Login Page → Firebase Auth → Firestore → Dashboard
                ↓
          [Validación]
                ↓
           [UserModel]
```

---

## 📞 Información Académica

### Detalles del Proyecto

| Campo | Información |
|-------|-------------|
| **Institución** | Universidad [Nombre] |
| **Carrera** | Ingeniería en Sistemas / Desarrollo de Software |
| **Materia** | Desarrollo de Aplicaciones Móviles |
| **Periodo** | Cuarto Cuatrimestre |
| **Año** | 2025 |
| **Profesor** | [Nombre del Profesor] |

### Objetivos de Aprendizaje

- Desarrollo de aplicaciones multiplataforma con Flutter
- Integración de servicios backend en la nube (Firebase)
- Implementación de autenticación y autorización
- Diseño de bases de datos NoSQL (Firestore)
- Aplicación de patrones de diseño y arquitectura limpia
- Gestión de estado en aplicaciones móviles
- Desarrollo de interfaces de usuario responsivas

---

## 📞 Contacto y Soporte

### Desarrollador

**Nombre:** [Tu Nombre]  
**Email:** [tu.email@universidad.edu]  
**GitHub:** [@TuUsuario](https://github.com/TuUsuario)

### Soporte del Proyecto

Para reportar bugs o solicitar features:
- [Issues](https://github.com/[TU_USUARIO]/sistema_citas_medicas/issues)
- [Discussions](https://github.com/[TU_USUARIO]/sistema_citas_medicas/discussions)

---

## 📄 Licencia

Este proyecto es un trabajo académico desarrollado con fines educativos.

```
MIT License

Copyright (c) 2025 [Tu Nombre]

Se permite el uso, copia, modificación y distribución de este software
con fines académicos y educativos.
```

---

## 🙏 Agradecimientos

- **Flutter Team** - Framework de desarrollo
- **Firebase Team** - Backend as a Service
- **Material Design** - Sistema de diseño
- **Comunidad de Flutter** - Recursos y documentación
- **Universidad [Nombre]** - Apoyo académico

---

## 📊 Información del Repositorio

**Última Actualización:** Octubre 2025  
**Versión:** 1.0.0  
**Estado:** En Desarrollo Activo  
**Tipo:** Proyecto Académico

---

**Desarrollado con Flutter para el Cuarto Cuatrimestre - 2025**
