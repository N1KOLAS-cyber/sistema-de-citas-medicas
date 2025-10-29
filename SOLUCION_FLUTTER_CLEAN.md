# Solución: Error al ejecutar `flutter clean` en Windows

## 📋 Problema

Al ejecutar `flutter clean` en Windows, aparecían errores indicando que varios directorios no podían ser eliminados porque estaban siendo usados por otros programas:

```
Failed to remove C:\Users\Soyni\dev\sistema_citas_medicas\.dart_tool
Failed to remove C:\Users\Soyni\dev\sistema_citas_medicas\ios\Flutter\ephemeral
Failed to remove C:\Users\Soyni\dev\sistema_citas_medicas\linux\flutter\ephemeral
Failed to remove C:\Users\Soyni\dev\sistema_citas_medicas\macos\Flutter\ephemeral
Failed to remove C:\Users\Soyni\dev\sistema_citas_medicas\windows\flutter\ephemeral
```

## 🔧 Solución Aplicada

### Paso 1: Finalizar procesos bloqueantes

Ejecutar los siguientes comandos para terminar todos los procesos de Dart, Flutter y ADB que puedan estar bloqueando los archivos:

```cmd
taskkill /F /IM dart.exe /T
taskkill /F /IM flutter.exe /T
taskkill /F /IM adb.exe /T
```

**Explicación de los parámetros:**
- `/F` - Forzar la terminación del proceso
- `/IM` - Especificar el nombre de la imagen (nombre del proceso)
- `/T` - Terminar el proceso y todos sus procesos secundarios

### Paso 2: Eliminar manualmente los directorios con PowerShell

Si `flutter clean` aún falla después de finalizar los procesos, usar PowerShell para eliminar manualmente los directorios:

```powershell
Remove-Item -Path ".\.dart_tool" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path ".\ios\Flutter\ephemeral" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path ".\linux\flutter\ephemeral" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path ".\macos\Flutter\ephemeral" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path ".\windows\flutter\ephemeral" -Recurse -Force -ErrorAction SilentlyContinue
```

**Explicación de los parámetros:**
- `-Path` - Ruta del directorio a eliminar
- `-Recurse` - Eliminar el directorio y todo su contenido
- `-Force` - Forzar la eliminación de archivos ocultos o de solo lectura
- `-ErrorAction SilentlyContinue` - Continuar silenciosamente si hay errores

### Paso 3: Ejecutar flutter clean

Después de finalizar los procesos y eliminar manualmente los directorios:

```cmd
flutter clean
```

### Paso 4: Restaurar las dependencias

Una vez que `flutter clean` se ejecute exitosamente:

```cmd
flutter pub get
```

## 🚀 Script Completo de Solución

### Para CMD (Command Prompt):

```cmd
@echo off
echo Finalizando procesos de Dart, Flutter y ADB...
taskkill /F /IM dart.exe /T 2>nul
taskkill /F /IM flutter.exe /T 2>nul
taskkill /F /IM adb.exe /T 2>nul

echo.
echo Limpiando proyecto Flutter...
flutter clean

echo.
echo Restaurando dependencias...
flutter pub get

echo.
echo Proceso completado!
pause
```

### Para PowerShell:

```powershell
# Finalizar procesos bloqueantes
Write-Host "Finalizando procesos de Dart, Flutter y ADB..." -ForegroundColor Yellow
taskkill /F /IM dart.exe /T 2>$null
taskkill /F /IM flutter.exe /T 2>$null
taskkill /F /IM adb.exe /T 2>$null

# Eliminar directorios manualmente
Write-Host "`nEliminando directorios bloqueados..." -ForegroundColor Yellow
Remove-Item -Path ".\.dart_tool" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path ".\ios\Flutter\ephemeral" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path ".\linux\flutter\ephemeral" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path ".\macos\Flutter\ephemeral" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path ".\windows\flutter\ephemeral" -Recurse -Force -ErrorAction SilentlyContinue

# Limpiar proyecto
Write-Host "`nLimpiando proyecto Flutter..." -ForegroundColor Yellow
flutter clean

# Restaurar dependencias
Write-Host "`nRestaurando dependencias..." -ForegroundColor Yellow
flutter pub get

Write-Host "`nProceso completado!" -ForegroundColor Green
```

## 💡 Prevención: Evitar el problema en el futuro

### 1. Antes de ejecutar `flutter clean`

Siempre cierra:
- ✅ Visual Studio Code / Cursor
- ✅ Android Studio / IntelliJ IDEA
- ✅ Emuladores de Android
- ✅ Dispositivos conectados vía ADB
- ✅ Procesos de hot reload activos
- ✅ Cualquier terminal ejecutando Flutter

### 2. Excluir carpetas de Flutter de servicios de sincronización

Si usas OneDrive, Google Drive, Dropbox u otros servicios de sincronización en la nube, considera excluir estas carpetas de tu proyecto Flutter:

- `.dart_tool/`
- `build/`
- `ios/Flutter/ephemeral/`
- `linux/flutter/ephemeral/`
- `macos/Flutter/ephemeral/`
- `windows/flutter/ephemeral/`

**Para OneDrive:**
1. Clic derecho en la carpeta
2. Seleccionar "Liberar espacio"
3. O agregar a .gitignore y excluir de la sincronización

### 3. Configurar .gitignore correctamente

Asegúrate de que tu archivo `.gitignore` incluya:

```gitignore
# Flutter/Dart
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.packages
.pub-cache/
.pub/
build/

# Ephemeral
**/Flutter/ephemeral/
**/flutter/ephemeral/

# IDE
.idea/
.vscode/
*.iml
*.ipr
*.iws
```

## 🔍 Diagnóstico: Identificar qué está bloqueando los archivos

Si los pasos anteriores no funcionan, puedes identificar qué proceso está bloqueando los archivos:

### Opción 1: Usar Process Explorer (Microsoft Sysinternals)

1. Descargar [Process Explorer](https://docs.microsoft.com/en-us/sysinternals/downloads/process-explorer)
2. Ejecutar como administrador
3. Usar `Ctrl + F` para buscar el nombre del archivo o carpeta bloqueada
4. Finalizar el proceso que lo está bloqueando

### Opción 2: Usar PowerShell con Handle

```powershell
# Descargar Handle de Sysinternals
# https://docs.microsoft.com/en-us/sysinternals/downloads/handle

# Buscar qué proceso tiene abierto .dart_tool
handle.exe -a .dart_tool
```

### Opción 3: Reiniciar la computadora

Si todo lo demás falla, un reinicio simple del sistema suele resolver el problema.

## 📝 Comandos de Referencia Rápida

### Finalizar procesos específicos:
```cmd
taskkill /F /IM dart.exe /T
taskkill /F /IM adb.exe /T
taskkill /F /IM java.exe /T
taskkill /F /IM gradle.exe /T
```

### Ver procesos de Dart activos:
```cmd
tasklist | findstr dart
```

### Limpiar todo (nuclear option):
```powershell
# Finalizar todos los procesos relacionados
Get-Process | Where-Object {$_.ProcessName -like "*dart*" -or $_.ProcessName -like "*flutter*" -or $_.ProcessName -like "*adb*"} | Stop-Process -Force

# Eliminar todas las carpetas de build
Remove-Item -Path ".\build" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path ".\.dart_tool" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path ".\android\build" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path ".\ios\Flutter\ephemeral" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path ".\linux\flutter\ephemeral" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path ".\macos\Flutter\ephemeral" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path ".\windows\flutter\ephemeral" -Recurse -Force -ErrorAction SilentlyContinue

# Limpiar y restaurar
flutter clean
flutter pub get
```

## ✅ Verificación

Después de aplicar la solución, verifica que todo esté funcionando:

```cmd
# Verificar la instalación de Flutter
flutter doctor -v

# Verificar dependencias
flutter pub get

# Ejecutar el proyecto
flutter run
```

## 📚 Referencias

- [Flutter Clean Documentation](https://docs.flutter.dev/reference/flutter-cli#flutter-clean)
- [Stack Overflow: Can't delete folder because it is used](https://superuser.com/questions/1333118/cant-delete-empty-folder-because-it-is-used)
- [Sysinternals Suite](https://docs.microsoft.com/en-us/sysinternals/)

## 🆘 Soporte Adicional

Si el problema persiste después de aplicar todas estas soluciones:

1. Verifica que no tengas antivirus bloqueando los archivos
2. Ejecuta CMD o PowerShell como Administrador
3. Verifica permisos de la carpeta del proyecto
4. Considera mover el proyecto a una ruta más corta (ej: `C:\dev\proyecto`)
5. Consulta la comunidad de Flutter en Discord o GitHub

---

**Fecha de creación:** 16 de Octubre, 2025  
**Proyecto:** Sistema de Citas Médicas  
**Sistema Operativo:** Windows 10/11

