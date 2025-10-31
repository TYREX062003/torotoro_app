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
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // 📱 Modo móvil (< 600px)
                if (constraints.maxWidth < 600) {
                  return Row(
                    children: [
                      // Solo ícono
                      _buildCompactLogo(),
                      const Spacer(),
                      // Links en móvil (más compactos)
                      _buildMobileNavLinks(context),
                      const SizedBox(width: 10),
                      // Botón de login compacto
                      _buildCompactLoginButton(context),
                    ],
                  );
                }
                
                // 💻 Modo tablet/desktop
                return Row(
                  children: [
                    // Logo completo
                    _buildLogo(),
                    const Spacer(),
                    // Links normales
                    _buildNavLinks(context),
                    const SizedBox(width: 30),
                    // Botón de login completo
                    _buildLoginButton(context),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // Logo completo (desktop)
  Widget _buildLogo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: kOlive,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.landscape,
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

  // Logo compacto (móvil) - Solo ícono
  Widget _buildCompactLogo() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: kOlive,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.landscape,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  // Links de navegación (desktop)
  Widget _buildNavLinks(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _NavLink(
          label: 'Inicio',
          onTap: () {
            // Navegar al landing
            Navigator.of(context).pushReplacementNamed('/web-landing');
          },
        ),
        const SizedBox(width: 30),
        _NavLink(
          label: 'Explorar',
          onTap: () {
            // 🔥 NAVEGAR A LA PÁGINA DE EXPLORAR
            Navigator.of(context).pushNamed('/web-explorar');
          },
        ),
      ],
    );
  }

  // Links de navegación MÓVIL (más compactos)
  Widget _buildMobileNavLinks(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MobileNavLink(
          label: 'Inicio',
          onTap: () {
            Navigator.of(context).pushReplacementNamed('/web-landing');
          },
        ),
        const SizedBox(width: 15),
        _MobileNavLink(
          label: 'Explorar',
          onTap: () {
            // 🔥 NAVEGAR A LA PÁGINA DE EXPLORAR
            Navigator.of(context).pushNamed('/web-explorar');
          },
        ),
      ],
    );
  }

  // Botón completo (desktop)
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

  // Botón compacto (móvil) - Solo ícono
  Widget _buildCompactLoginButton(BuildContext context) {
    return IconButton(
      onPressed: () {
        Navigator.of(context).pushNamed('/web-login');
      },
      icon: const Icon(Icons.login, color: kOlive, size: 24),
      tooltip: 'Iniciar sesión',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }
}

// ============================================
// LINK DE NAVEGACIÓN (Desktop)
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

// ============================================
// LINK DE NAVEGACIÓN MÓVIL (Más compacto)
// ============================================
class _MobileNavLink extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _MobileNavLink({
    required this.label,
    required this.onTap,
  });

  @override
  State<_MobileNavLink> createState() => _MobileNavLinkState();
}

class _MobileNavLinkState extends State<_MobileNavLink> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Text(
        widget.label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: kBrown,
        ),
      ),
    );
  }
}