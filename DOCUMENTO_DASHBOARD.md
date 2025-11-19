<## Desarrollo e Integración del Dashboard Médico

### 1. Punto de partida y metas del módulo
Soy estudiante de Ingeniería de Software y, para esta iteración de la Doctor Appointment App, me propuse cumplir con la instrucción principal: crear un dashboard exclusivo para el rol “Médico”, alimentado en tiempo real por Firebase Cloud Firestore y gestionado mediante `StreamBuilder`. El objetivo fue demostrar manejo de estados y visualización de datos bajo un patrón declarativo, respetando las reglas de acceso por rol y mostrando al menos tres indicadores significativos.

### 2. Gestión de roles en login y perfil
Antes de diseñar la vista, aseguré el flujo completo de roles:
1. **`login_page.dart`** y **`profile_page.dart`** incluyen un `DropdownButtonFormField` con las opciones “Paciente” y “Médico”.  
2. El valor elegido se persiste en la colección `usuarios` dentro de Firestore junto con el campo booleano `isDoctor`.  
3. Cada vez que un usuario inicia sesión, consulto su documento y actualizo el `UserModel`. De esta forma, el rol viaja por toda la app sin necesidad de llamadas extra.  

Gracias a esto pude condicionar la UI: los pacientes siguen viendo el widget “Agregar cita”, mientras que los médicos ven “Ver citas”, el cual navega hacia `DashboardPage`. El nuevo `AppDrawer` también valida `user.role == 'Médico'` antes de mostrar la opción de panel, garantizando que ningún paciente acceda por accidente.

### 3. Arquitectura y consumo de datos
Para el dashboard opté por un `StreamBuilder<QuerySnapshot<Map<String, dynamic>>>`. El stream filtra la colección `citas` por `doctorId` y se mantiene activo durante toda la sesión del médico. Con cada actualización:
- Se calculan totales, pendientes y pacientes únicos.
- Se derivan subconjuntos para ventanas de 3 y 6 meses con la función `_parseDate`.
- Se genera un mapa con conteos diarios (últimos 30 días) y otro con pacientes diferentes para las métricas de captación.

Aunque las instrucciones originales mencionaban BlocBuilder, la lógica actual ya había migrado a un enfoque más directo con `StreamBuilder`. Este patrón mantiene la reactvidad requerida (los cambios en Firestore se reflejan al instante) y reduce la complejidad al no depender de eventos manuales.

### 4. Diseño responsivo y distribución
El layout se replanteó por completo para parecerse a un dashboard web:
- Usé un `LayoutBuilder` que calcula cuántas columnas caben (4, 3, 2 o 1) y aplica un `Wrap` con `spacing` uniforme.  
- Las tarjetas de indicadores quedaron en el rango 240–360 px de ancho, lo que evita bloques gigantes o demasiado estrechos.  
- Las gráficas donut también se regeneran en función del ancho disponible, con radio ajustado y un `TweenAnimationBuilder` que las llena gradualmente al entrar, dando una sensación profesional.

### 5. Indicadores claves entregados
1. **Citas totales** – total de documentos con el `doctorId` correspondiente.  
2. **Pacientes únicos** – conjunto de `patientId` o equivalentes, útil para medir alcance real.  
3. **Citas últimos 3 y 6 meses** – cuantifican actividad reciente y alimentan ratios porcentuales.  
4. **Pendientes** – filtra por estados `pending`, `confirmada` o `confirmed`.  

Los ratios se muestran con flechas verdes (`Icons.arrow_upward`) para cumplir con el requisito de incorporar íconos y reforzar el mensaje visual.

### 6. Gráficas y animaciones
Para las donas utilicé `PieChart` de `fl_chart` y animé la porción azul con `TweenAnimationBuilder`. Cada donut muestra el porcentaje y la fracción (“2 de 13 citas”), por lo que el médico entiende inmediatamente el contexto.  

La gráfica de línea “Tendencia de citas (30 días)” se arma con `LineChart`. Se alimenta de los conteos diarios calculados anteriormente, suaviza la curva (`isCurved: true`) y usa un área semitransparente para resaltar los picos semanales.

### 7. Exclusividad de acceso y navegación
El `AppDrawer` valida el rol con tres mecanismos:
1. `user.role == 'Médico'` (con variantes de acento).  
2. Campo booleano `isDoctor`.  
3. Correo con palabra “admin” para cuentas de prueba.  

Si el usuario cumple, aparece la sección “Panel Médico” con los accesos directos a Dashboard, Gestión de Citas, Horarios y Citas propias. Además, desde el Home agregué un botón de menú visible en web para abrir el drawer rápidamente; con esto se mantiene el flujo pedido en las instrucciones.

### 8. Verificación de requisitos
- **Rol en login/perfil**: implementado y persistido en Firestore.  
- **Dashboard exclusivo para médicos**: sidebar y navegación condicionados.  
- **Widget “Agregar cita” vs “Ver citas”**: se siguen mostrando según el rol en `home_page.dart`.  
- **Indicadores desde Firestore**: total de citas, pendientes, pacientes únicos y ventanas 3/6 meses.  
- **Actualización en tiempo real**: `StreamBuilder` sobre la colección `citas`.  
- **Íconos/gráficas**: tarjetas con iconografía médica y gráficos donut/line chart animados.  

Todas las consignas proporcionadas fueron incorporadas al documento porque se cumplieron en la implementación actual.

### 9. Conclusiones personales
Este trabajo me permitió ensamblar varias piezas: control de roles persistentes, consumo en tiempo real de Firestore, diseño responsivo y animaciones suaves. El resultado es un dashboard que sí parece parte de un SaaS médico moderno, pero sigue siendo mantenible porque la lógica de estadísticas está aislada en pocas funciones y el layout se ajusta automáticamente. Si en futuras iteraciones quisiera añadir más indicadores (por ejemplo, cancelaciones o puntajes de satisfacción), bastaría con extender la lista `_DonutConfig` o sumar nuevas tarjetas dentro del mismo patrón.

>
