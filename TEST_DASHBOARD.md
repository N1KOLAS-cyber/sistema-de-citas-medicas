# 🧪 TEST: Verificar Dashboard en Sidebar

## Pasos para Verificar

1. **Ejecuta la app**: `flutter run`
2. **Inicia sesión** como usuario médico (o cambia tu rol a "Médico" en el perfil)
3. **Abre el sidebar** (botón ☰)
4. **Revisa la consola** para ver los logs de debug:
   ```
   🔍 DEBUG AppDrawer - Usuario: [nombre]
   🔍 DEBUG AppDrawer - Role: [rol]
   🔍 DEBUG AppDrawer - isDoctor: [true/false]
   🔍 DEBUG AppDrawer - isMedico: [true/false]
   ```

## Qué Buscar en el Sidebar

Si `isMedico: true`, deberías ver:
- ✅ Sección "Panel Médico" (con divider arriba)
- ✅ Opción "Dashboard" (primera en Panel Médico)
- ✅ Icono azul de dashboard
- ✅ Título "Dashboard" en negrita
- ✅ Subtítulo "Estadísticas y análisis médico"

Si `isMedico: false`, NO deberías ver:
- ❌ Sección "Panel Médico"
- ❌ Opción "Dashboard"

## Solución Rápida

Si no aparece el Dashboard:

1. Ve a "Mi Perfil" desde el sidebar
2. Busca el selector de rol (dropdown)
3. Selecciona "Médico"
4. Espera el mensaje de confirmación
5. Cierra y vuelve a abrir el sidebar
6. Deberías ver "Panel Médico" con "Dashboard"

## Verificación en Firestore

1. Abre Firebase Console
2. Firestore Database → colección `usuarios`
3. Busca tu documento por `id` (UID)
4. Verifica que tenga:
   ```json
   {
     "role": "Médico",
     "isDoctor": true
   }
   ```

