import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

// 🎨 Colores
const kBeige = Color(0xFFF2E8D5);
const kOlive = Color(0xFF6B7C3F);
const kBrown = Color(0xFF5B4636);

class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Responsive: stacked en mobile, row en desktop
              if (constraints.maxWidth < 900) {
                return Column(
                  children: [
                    _buildLeftContent(context),
                    const SizedBox(height: 60),
                    _buildRightIllustration(),
                  ],
                );
              }
              
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 🔥 Izquierda: Texto + Botón
                  Expanded(
                    flex: 5,
                    child: _buildLeftContent(context),
                  ),
                  
                  const SizedBox(width: 80),
                  
                  // 🔥 Derecha: Ilustración con QR
                  Expanded(
                    flex: 5,
                    child: _buildRightIllustration(),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ============================================
  // CONTENIDO IZQUIERDO
  // ============================================
  Widget _buildLeftContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título principal
        const Text(
          'Verificación\npor QR',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: kBrown,
            height: 1.2,
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Descripción
        Text(
          'Escanea el código QR para descargar la aplicación móvil de Torotoro y comenzar tu aventura explorando fósiles, cavernas y rutas increíbles.',
          style: TextStyle(
            fontSize: 18,
            color: Colors.black.withValues(alpha: 0.8),
            height: 1.6,
          ),
        ),
        
        const SizedBox(height: 40),
        
        // Botón "Explorar Ahora"
        FilledButton(
          onPressed: () {
            // Scroll hacia la sección "Explorar"
            Scrollable.ensureVisible(
              context,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          },
          style: FilledButton.styleFrom(
            backgroundColor: kOlive,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Explorar Ahora',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================
  // ILUSTRACIÓN DERECHA (QR + Personas)
  // ============================================
  Widget _buildRightIllustration() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 500),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Fondo decorativo (formas orgánicas)
          ..._buildDecorativeShapes(),
          
          // QR Code (centro) - VERSIÓN CORREGIDA
          _buildQRCode(),
          
          // Personas ilustradas
          _buildIllustrations(),
        ],
      ),
    );
  }

  List<Widget> _buildDecorativeShapes() {
    return [
      // Círculos concéntricos de fondo
      Positioned(
        top: 80,
        right: 50,
        child: Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: kOlive.withValues(alpha: 0.1),
              width: 30,
            ),
          ),
        ),
      ),
      Positioned(
        top: 50,
        right: 20,
        child: Container(
          width: 360,
          height: 360,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: kOlive.withValues(alpha: 0.05),
              width: 30,
            ),
          ),
        ),
      ),
      
      // Formas decorativas (hojas)
      Positioned(
        bottom: 80,
        left: 20,
        child: _buildLeafShape(kOlive.withValues(alpha: 0.3)),
      ),
      Positioned(
        bottom: 50,
        left: 60,
        child: _buildLeafShape(kOlive.withValues(alpha: 0.2)),
      ),
    ];
  }

  Widget _buildLeafShape(Color color) {
    return Container(
      width: 60,
      height: 80,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(40),
        ),
      ),
    );
  }

  // ============================================
  // QR CODE REAL - CON ENLACE AL APK
  // ============================================
  Widget _buildQRCode() {
    // 🔥 CONFIGURA TU URL DE DESCARGA AQUÍ
    // Opciones para subir tu APK:
    // 
    // 1️⃣ Firebase Storage (Recomendado):
    //    - Ve a Firebase Console → Storage
    //    - Sube app-release.apk
    //    - Obtén la URL pública
    //    Ejemplo: "https://firebasestorage.googleapis.com/v0/b/tu-proyecto.appspot.com/o/torotoro-app.apk?alt=media&token=xxxxx"
    //
    // 2️⃣ Google Drive:
    //    - Sube el APK y hazlo público
    //    - Usa: "https://drive.google.com/uc?export=download&id=TU_FILE_ID"
    //
    // 3️⃣ GitHub Releases:
    //    - Crea un release y adjunta el APK
    //    - Copia la URL de descarga directa
    //
    // 4️⃣ Dropbox:
    //    - Sube el APK y genera enlace público
    //    - Cambia ?dl=0 por ?dl=1 al final
    
    // 🔥 URL de descarga del APK desde Firebase Storage
    const String apkDownloadUrl = "https://firebasestorage.googleapis.com/v0/b/proyecttorotoro.firebasestorage.app/o/downloads%2Fapp-release.apk?alt=media&token=acb0daf0-c5e5-4d06-97b9-b1423f0b7310";
    
    return Center(
      child: Container(
        width: 240,
        height: 240,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // QR Code real usando qr_flutter
            Flexible(
              child: Center(
                child: QrImageView(
                  data: apkDownloadUrl,
                  version: QrVersions.auto,
                  size: 180,
                  backgroundColor: Colors.white,
                  foregroundColor: kBrown,
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                  padding: const EdgeInsets.all(4),
                  gapless: true,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Escanea para descargar',
              style: TextStyle(
                fontSize: 11,
                color: Colors.black.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIllustrations() {
    return Stack(
      children: [
        // Persona 1 (arriba, señalando)
        Positioned(
          top: 0,
          right: 80,
          child: _buildPersonIcon(
            color: const Color(0xFF9B7EBD),
            icon: Icons.person,
            size: 80,
          ),
        ),
        
        // Persona 2 (abajo, con teléfono)
        Positioned(
          bottom: 0,
          right: 100,
          child: _buildPersonIcon(
            color: const Color(0xFFE07A5F),
            icon: Icons.phone_android,
            size: 80,
          ),
        ),
        
        // Burbuja de chat
        Positioned(
          top: 40,
          right: 10,
          child: _buildChatBubble(),
        ),
      ],
    );
  }

  Widget _buildPersonIcon({
    required Color color,
    required IconData icon,
    required double size,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: size * 0.5,
      ),
    );
  }

  Widget _buildChatBubble() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4D06F),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble, color: Colors.white, size: 20),
          SizedBox(width: 8),
          Icon(Icons.circle, color: Colors.white, size: 6),
          SizedBox(width: 4),
          Icon(Icons.circle, color: Colors.white, size: 6),
        ],
      ),
    );
  }
}