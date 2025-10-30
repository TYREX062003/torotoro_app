import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:torotoro_app/webnav/web_navbar.dart';
import 'package:torotoro_app/webnav/hero_section.dart';

// 🎨 Colores de tu app
const kBeige = Color(0xFFF2E8D5);
const kOlive = Color(0xFF6B7C3F);
const kBrown = Color(0xFF5B4636);

class LandingPage extends StatelessWidget {
  final bool showUserMessage;
  
  const LandingPage({
    super.key, 
    this.showUserMessage = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBeige,
      body: Stack(
        children: [
          // Contenido principal con scroll
          SingleChildScrollView(
            child: Column(
              children: [
                // Espacio para el navbar
                const SizedBox(height: 80),
                
                // 🔥 Hero Section con QR e ilustración
                const HeroSection(),
                
                const SizedBox(height: 80),
                
                // 🔥 Sección "Explorar" - Info del parque
                _buildExploreSection(context),
                
                const SizedBox(height: 80),
                
                // 🔥 Footer
                _buildFooter(context),
              ],
            ),
          ),
          
          // Navbar sticky (siempre visible arriba)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: WebNavbar(),
          ),
          
          // 🔥 Mensaje para usuarios normales (no admin)
          if (showUserMessage)
            Positioned.fill(
              child: _buildUserMessageOverlay(context),
            ),
        ],
      ),
    );
  }

  // ============================================
  // SECCIÓN "EXPLORAR"
  // ============================================
  Widget _buildExploreSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      color: Colors.white.withValues(alpha: 0.5),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              // Título
              const Text(
                'Explora Torotoro',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: kBrown,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Descubre los tesoros paleontológicos y naturales del Parque Nacional Torotoro',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black87,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 50),
              
              // Grid de características
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 900 ? 3 : 
                                        constraints.maxWidth > 600 ? 2 : 1;
                  
                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 30,
                    crossAxisSpacing: 30,
                    childAspectRatio: 1.2,
                    children: [
                      _buildFeatureCard(
                        icon: Icons.hiking_outlined,
                        title: 'Fósiles',
                        description: 'Huellas de dinosaurios de hace millones de años',
                      ),
                      _buildFeatureCard(
                        icon: Icons.water_drop_outlined,
                        title: 'Cavernas',
                        description: 'Sistemas de cuevas espectaculares y únicas',
                      ),
                      _buildFeatureCard(
                        icon: Icons.landscape_outlined,
                        title: 'Rutas',
                        description: 'Senderos guiados por paisajes increíbles',
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: kOlive),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: kBrown,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ============================================
  // FOOTER
  // ============================================
  Widget _buildFooter(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      color: kBrown,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              const Text(
                'Parque Nacional Torotoro',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Descubre la historia natural de Bolivia',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 30),
              Text(
                '© 2025 Torotoro App. Todos los derechos reservados.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================
  // MENSAJE PARA USUARIOS NO-ADMIN
  // ============================================
  Widget _buildUserMessageOverlay(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.phone_android,
                size: 64,
                color: kOlive,
              ),
              const SizedBox(height: 24),
              const Text(
                '¡Hola!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: kBrown,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Esta versión web es solo para administradores.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Para explorar Torotoro, descarga nuestra aplicación móvil escaneando el código QR arriba.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushReplacementNamed('/web-landing');
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: kOlive,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text(
                    'Cerrar sesión',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}