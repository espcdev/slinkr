import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  // Función para abrir enlaces de forma segura
  Future<void> _launchUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el enlace.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Información'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Slinkr v1.6', // Versión actualizada
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Slinkr es una app de código abierto diseñada para ayudarte a gestionar la batería de tu dispositivo con alertas personalizables.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.code_rounded),
              title: const Text('Repositorio en GitHub'),
              subtitle: const Text('¡Haz tu magia y contribuye!'),
              // CAMBIO IMPORTANTE: Cambia 'tu-usuario' por tu nombre de usuario de GitHub
              onTap: () => _launchUrl(context, 'https://github.com/tu-usuario/slinkr'),
            ),
          ),
          const SizedBox(height: 16),
          // --- NUEVA SECCIÓN DE CRÉDITOS ---
          Card(
            child: ListTile(
              leading: const Icon(Icons.favorite_border_rounded),
              title: const Text('Créditos'),
              subtitle: const Text('Desarrollado con ❤️ por ESPC'),
              onTap: () {},
            ),
          ),
          const SizedBox(height: 16),
          const Card(
            child: ListTile(
              leading: Icon(Icons.health_and_safety_outlined),
              title: Text('Aviso de Precisión'),
              subtitle: Text(
                'Las estimaciones de salud y tiempo restante no son 100% precisas. Para un diagnóstico profesional, consulta a un técnico.'
              ),
              isThreeLine: true,
            ),
          ),
        ],
      ),
    );
  }
}