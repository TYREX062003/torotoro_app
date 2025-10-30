import 'package:flutter/material.dart';

// 🎨 Colores
const kBeige = Color(0xFFF2E8D5);
const kOlive = Color(0xFF6B7C3F);
const kBrown = Color(0xFF5B4636);

class WebNavbar extends StatelessWidget {
  const WebNavbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: kBeige,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Row(
              children: [
                // 🔥 Logo + Título
                _buildLogo(),
                
                const Spacer(),
                
                // 🔥 Links de navegación
                _buildNavLinks(context),
                
                const SizedBox(width: 30),
                
                // 🔥 Botón "Iniciar sesión"
                _buildLoginButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: kOlive,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.pets,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'Toro Toro',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: kBrown,
          ),
        ),
      ],
    );
  }

  Widget _buildNavLinks(BuildContext context) {
    return Row(
      children: [
        _NavLink(
          label: 'Inicio',
          onTap: () {
            // Scroll to top
          },
        ),
        const SizedBox(width: 30),
        _NavLink(
          label: 'Explorar',
          onTap: () {
            // Scroll to explore section
          },
        ),
      ],
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    return FilledButton(
      onPressed: () {
        Navigator.of(context).pushNamed('/web-login');
      },
      style: FilledButton.styleFrom(
        backgroundColor: kOlive,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: const Text(
        'Iniciar sesión',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ============================================
// LINK DE NAVEGACIÓN
// ============================================
class _NavLink extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _NavLink({
    required this.label,
    required this.onTap,
  });

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            fontSize: 16,
            fontWeight: _isHovered ? FontWeight.w700 : FontWeight.w600,
            color: _isHovered ? kOlive : kBrown,
          ),
          child: Text(widget.label),
        ),
      ),
    );
  }
}