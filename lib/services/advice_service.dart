/**
 * ADVICE SERVICE - SERVICIO DE CONSEJOS MÉDICOS
 * 
 * Este archivo contiene métodos para obtener consejos médicos aleatorios
 * desde una colección en Firestore.
 */

import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class AdviceService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _adviceCollection = 'consejos_medicos';

  /**
   * Obtiene un consejo médico aleatorio de la colección
   * @return Future<String> - Texto del consejo médico
   */
  static Future<String> getRandomAdvice() async {
    try {
      // Obtener todos los consejos
      final snapshot = await _firestore.collection(_adviceCollection).get();
      
      if (snapshot.docs.isEmpty) {
        return 'Mantén un estilo de vida saludable con ejercicio regular y una dieta balanceada.';
      }

      // Seleccionar uno aleatorio
      final random = Random();
      final randomIndex = random.nextInt(snapshot.docs.length);
      final randomDoc = snapshot.docs[randomIndex];
      
      return randomDoc.data()['consejo'] ?? 'Cuida tu salud visitando al médico regularmente.';
    } catch (e) {
      // En caso de error, retornar un consejo por defecto
      return 'La prevención es la mejor medicina. Realiza chequeos médicos regulares.';
    }
  }

  /**
   * Inicializa la colección con 50 consejos médicos si no existe
   * Este método debería ejecutarse una vez desde la consola de Firebase o desde admin tools
   */
  static Future<void> initializeAdvices() async {
    final List<String> consejos = [
     'Bebe al menos 8 vasos de agua al día para mantenerte hidratado.',
      'Duerme entre 7-9 horas cada noche para un descanso óptimo.',
      'Realiza al menos 30 minutos de ejercicio moderado 5 días a la semana.',
      'Come 5 porciones de frutas y verduras al día.',
      'Evita el consumo excesivo de azúcar y alimentos procesados.',
      'Lávate las manos frecuentemente para prevenir enfermedades.',
      'Realiza chequeos médicos anuales aunque te sientas bien.',
      'Practica técnicas de relajación para reducir el estrés.',
      'Usa protector solar todos los días, incluso en días nublados.',
      'Evita fumar y limita el consumo de alcohol.',
      'Mantén un peso saludable según tu estatura y edad.',
      'Haz pausas activas si trabajas sentado por largos períodos.',
      'Consume pescado al menos 2 veces por semana.',
      'Incluye alimentos ricos en fibra en tu dieta diaria.',
      'Vacúnate según el calendario de vacunación recomendado.',
      'Evita el uso excesivo de dispositivos electrónicos antes de dormir.',
      'Practica buena higiene dental cepillándote 3 veces al día.',
      'Mantén una postura correcta al sentarte y caminar.',
      'Consume proteínas magras como pollo, pescado y legumbres.',
      'Realiza estiramientos después del ejercicio.',
      'Evita el consumo de alimentos muy altos en sodio.',
      'Toma suplementos vitamínicos solo si un médico lo recomienda.',
      'Pasa tiempo al aire libre para obtener vitamina D del sol.',
      'Controla tus niveles de presión arterial regularmente.',
      'Mantén una actitud positiva y busca apoyo emocional cuando lo necesites.',
      'Evita automedicarte; consulta siempre con un profesional.',
      'Come despacio y mastica bien tus alimentos.',
      'Reduce el consumo de cafeína, especialmente antes de dormir.',
      'Incluye granos enteros en tu dieta diaria.',
      'Realiza ejercicios de flexibilidad y equilibrio.',
      'Mantén un diario de comidas para identificar intolerancias.',
      'Evita el contacto directo con personas enfermas.',
      'Consume alimentos ricos en omega-3 para la salud cardiovascular.',
      'Practica la meditación o mindfulness para reducir ansiedad.',
      'Mantén tu casa bien ventilada para mejorar la calidad del aire.',
      'Limpia y desinfecta regularmente las superficies que tocas frecuentemente.',
      'Usa zapatos cómodos y adecuados para tu actividad.',
      'Realiza ejercicios de fuerza al menos 2 veces por semana.',
      'Consume alimentos probióticos para mejorar tu salud digestiva.',
      'Evita saltarte comidas; come en horarios regulares.',
      'Mantén una buena higiene personal diariamente.',
      'Controla tus niveles de azúcar en sangre si tienes riesgo de diabetes.',
      'Realiza ejercicios cardiovasculares como caminar, correr o nadar.',
      'Evita el estrés crónico mediante técnicas de manejo del tiempo.',
      'Consume té verde que tiene propiedades antioxidantes.',
      'Mantén un entorno de trabajo ergonómico para evitar lesiones.',
      'Evita el consumo de alimentos muy calientes o muy fríos de forma frecuente.',
      'Realiza actividades que disfrutes para mantener tu bienestar mental.',
      'Consume alimentos ricos en calcio para fortalecer tus huesos.',
      'Mantén un estilo de vida activo en todas las etapas de la vida.',
    ];

    try {
      // Verificar si ya existen consejos
      final snapshot = await _firestore.collection(_adviceCollection).limit(1).get();
      
      if (snapshot.docs.isNotEmpty) {
        // Ya existen consejos, no crear duplicados
        return;
      }

      // Crear todos los consejos en batch
      WriteBatch batch = _firestore.batch();
      
      for (int i = 0; i < consejos.length; i++) {
        final docRef = _firestore.collection(_adviceCollection).doc();
        batch.set(docRef, {
          'consejo': consejos[i],
          'indice': i + 1,
          'creadoEn': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      print('Error al inicializar consejos: $e');
    }
  }
}

