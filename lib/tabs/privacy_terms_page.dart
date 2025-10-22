import 'package:flutter/material.dart';

/// Pantalla de Términos y Condiciones y Política de Privacidad
class PrivacyTermsPage extends StatelessWidget {
  const PrivacyTermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Privacidad y Términos"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Términos y Condiciones',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const Text(
              'NERV - Sistema de Citas Médicas',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const Divider(height: 32),

            // Sección 1: Introducción
            _buildSection(
              title: '1. Introducción',
              content: 'Al utilizar NERV - Sistema de Citas Médicas, usted acepta los presentes '
                  'términos y condiciones. Este sistema está diseñado para facilitar la comunicación '
                  'entre pacientes y profesionales de la salud, garantizando la privacidad y seguridad '
                  'de su información médica.',
            ),

            // Sección 2: Recopilación de Datos
            _buildSection(
              title: '2. Recopilación de Datos Personales',
              content: 'NERV recopila y almacena la siguiente información:\n\n'
                  '• Datos de identificación: Nombre completo, correo electrónico, número de teléfono\n'
                  '• Información médica: Historial médico, enfermedades, alergias, padecimientos\n'
                  '• Datos de citas: Fechas, horarios, síntomas reportados, diagnósticos\n'
                  '• Datos profesionales (doctores): Especialidad, número de licencia médica\n\n'
                  'Esta información es necesaria para proporcionar el servicio de gestión de citas médicas.',
            ),

            // Sección 3: Uso de los Datos
            _buildSection(
              title: '3. Uso Privado de la Información',
              content: 'Los datos recopilados se utilizan exclusivamente para:\n\n'
                  '• Gestión y coordinación de citas médicas\n'
                  '• Comunicación entre pacientes y profesionales de la salud\n'
                  '• Mantenimiento del historial médico del paciente\n'
                  '• Mejora del servicio y experiencia del usuario\n\n'
                  '⚠️ IMPORTANTE: Sus datos NO serán compartidos con terceros sin su consentimiento expreso.',
            ),

            // Sección 4: Fundamento Legal
            _buildSection(
              title: '4. Fundamento Legal',
              content: 'La recopilación y tratamiento de datos personales está respaldada por:\n\n'
                  '🇲🇽 Legislación Mexicana:\n'
                  '• Ley Federal de Protección de Datos Personales en Posesión de Particulares (LFPDPPP)\n'
                  '• Artículo 6° - Principios de protección de datos\n'
                  '• Artículo 8° - Consentimiento del titular\n'
                  '• Artículo 16° - Derecho de acceso, rectificación, cancelación y oposición (ARCO)\n\n'
                  '🏥 Normativa de Salud:\n'
                  '• Ley General de Salud - Artículo 100 Bis\n'
                  '• NOM-024-SSA3-2012 (Sistemas de información de registro electrónico para la salud)\n'
                  '• Secreto profesional médico conforme al Artículo 36 del Reglamento de la Ley General de Salud',
            ),

            // Sección 5: Derechos del Usuario
            _buildSection(
              title: '5. Derechos ARCO',
              content: 'Como titular de los datos, usted tiene derecho a:\n\n'
                  '• ACCESO: Conocer qué datos personales tenemos\n'
                  '• RECTIFICACIÓN: Corregir datos inexactos o incompletos\n'
                  '• CANCELACIÓN: Solicitar eliminación de sus datos\n'
                  '• OPOSICIÓN: Negarse al tratamiento de sus datos\n\n'
                  'Para ejercer estos derechos, contacte a: soporte@sistemacitas.com',
            ),

            // Sección 6: Seguridad
            _buildSection(
              title: '6. Medidas de Seguridad',
              content: 'Implementamos medidas de seguridad técnicas y administrativas:\n\n'
                  '🔒 Autenticación mediante Firebase Authentication\n'
                  '🔐 Cifrado de datos en tránsito y reposo\n'
                  '🛡️ Reglas de seguridad de Firestore configuradas\n'
                  '👤 Acceso restringido según roles de usuario\n'
                  '📊 Auditoría de accesos y modificaciones',
            ),

            // Sección 7: Datos Sensibles
            _buildSection(
              title: '7. Tratamiento de Datos Sensibles de Salud',
              content: 'La información médica es considerada DATO SENSIBLE conforme al Artículo 3, '
                  'fracción VI de la LFPDPPP.\n\n'
                  'Su tratamiento requiere consentimiento expreso y se realiza bajo estrictas medidas '
                  'de confidencialidad. Solo el paciente y su médico tratante tienen acceso a esta información.\n\n'
                  'El personal médico está sujeto al secreto profesional establecido en la legislación sanitaria.',
            ),

            // Sección 8: Conservación
            _buildSection(
              title: '8. Conservación de Datos',
              content: 'Los datos personales se conservan mientras la cuenta esté activa.\n\n'
                  'Puede solicitar la eliminación de su cuenta y todos sus datos en cualquier momento.\n\n'
                  'Los datos médicos se conservan según lo establecido en la NOM-004-SSA3-2012 '
                  '(expediente clínico) por un periodo mínimo de 5 años.',
            ),

            // Sección 9: Contacto
            _buildSection(
              title: '9. Contacto',
              content: 'Para consultas sobre privacidad y protección de datos:\n\n'
                  '📧 Email: privacidad@sistemacitas.com\n'
                  '📞 Teléfono: +52 (555) 123-4567\n'
                  '🏢 Oficina de Privacidad\n\n'
                  'Tiempo de respuesta: 20 días hábiles conforme a la LFPDPPP',
            ),

            const SizedBox(height: 24),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📜 Última actualización: Octubre 2025',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '⚖️ Este documento está elaborado conforme a la legislación mexicana vigente.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Botón de aceptar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('He Leído y Acepto'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.black87,
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }
}

