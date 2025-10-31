import 'package:flutter/material.dart';

// 🎨 Colores de tu app
const kBeige = Color(0xFFF2E8D5);
const kOlive = Color(0xFF6B7C3F);
const kBrown = Color(0xFF5B4636);

class WebExplorarPage extends StatefulWidget {
  final String? section;
  const WebExplorarPage({super.key, this.section});

  @override
  State<WebExplorarPage> createState() => _WebExplorarPageState();
}

class _WebExplorarPageState extends State<WebExplorarPage> {
  final _lugaresKey = GlobalKey();
  final _vidaAntiguaKey = GlobalKey();
  final _fosilesKey = GlobalKey();
  final _vidaNuevaKey = GlobalKey();
  final _torotoroKey = GlobalKey();
  final _hombreKey = GlobalKey();

  late final Map<String, GlobalKey> _anchors = {
    'LUGARES EXPLORADOS': _lugaresKey,
    'VIDA ANTIGUA': _vidaAntiguaKey,
    'FÓSILES Y HUELLAS': _fosilesKey,
    'VIDA NUEVA': _vidaNuevaKey,
    'TOROTORO': _torotoroKey,
    'EL HOMBRE': _hombreKey,
  };

  late final Map<String, String> _normalizedIndex = {
    for (final k in _anchors.keys) _normalize(k): k,
  };

  String _normalize(String s) {
    final upper = s.toUpperCase();
    return upper
        .replaceAll('Á', 'A')
        .replaceAll('É', 'E')
        .replaceAll('Í', 'I')
        .replaceAll('Ó', 'O')
        .replaceAll('Ú', 'U')
        .replaceAll('Ü', 'U')
        .replaceAll('Ñ', 'N');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    final argSection =
        (args is Map && args['section'] is String) ? args['section'] as String : null;

    final target = widget.section ?? argSection;
    if (target != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollTo(target));
    }
  }

  void _scrollTo(String title) {
    final keyReal = _normalizedIndex[_normalize(title)];
    final ctx = keyReal != null ? _anchors[keyReal]?.currentContext : null;

    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        alignment: 0.06,
      );
    } else {
      Future.delayed(const Duration(milliseconds: 120), () {
        final retryKey = _normalizedIndex[_normalize(title)];
        final retryCtx = retryKey != null ? _anchors[retryKey]?.currentContext : null;
        if (retryCtx != null) {
          Scrollable.ensureVisible(
            retryCtx,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            alignment: 0.06,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sections = _data();

    return Scaffold(
      backgroundColor: kBeige,
      body: CustomScrollView(
        slivers: [
          // AppBar simple y limpio (SIN flecha)
          SliverAppBar(
            pinned: true,
            backgroundColor: kBeige,
            elevation: 0,
            automaticallyImplyLeading: false, // 🔥 Quita la flecha
          ),

          // NAVEGACIÓN - Ahora es el hero principal
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 30),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 15,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Título principal
                  const Text(
                    'Explora Toro Toro',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: kBrown,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Descubre cada rincón del parque',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black.withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  
                  // Navegación mejorada
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: _anchors.keys.map((t) {
                      return InkWell(
                        onTap: () => _scrollTo(t),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [kOlive, kOlive.withOpacity(0.85)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: kOlive.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            t,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              fontSize: 14,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          // SECCIONES
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final s = sections[index];
                  return KeyedSubtree(
                    key: s.key,
                    child: _SectionCard(
                      title: s.title,
                      subtitle: s.subtitle,
                      body: s.body,
                      imagePath: s.image,
                      flipped: index.isOdd,
                    ),
                  );
                },
                childCount: sections.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_SectionData> _data() => [
        _SectionData(
          key: _lugaresKey,
          title: 'LUGARES EXPLORADOS',
          subtitle: 'Umajalanta · Ciudad de Itas · Cañón & El Vergel · Siete Vueltas · Cementerio de Tortugas · Acantilado',
          body: 'Prepárate para sumergirte en la aventura más completa. La Caverna de Umajalanta, con sus túneles infinitos y ríos subterráneos, desafía a los exploradores con un espectáculo de estalactitas y estalagmitas. La Ciudad de Itas, esculpida por el viento y el agua, se alza como un laberinto pétreo digno de otra civilización. El Cañón de Toro Toro, acompañado por la cascada cristalina de El Vergel, mezcla vértigo y serenidad en un mismo paisaje. En Siete Vueltas, las rocas guardan la huella de antiguos mares, y en el Cementerio de Tortugas descansan gigantes fosilizados que caminaron mucho antes que nosotros. Y como broche de oro, El Acantilado: un mirador natural que corta la respiración, donde el abismo se abre ante ti mostrando un horizonte infinito.',
          image: 'assets/rocas.jpg',
        ),
        _SectionData(
          key: _vidaAntiguaKey,
          title: 'VIDA ANTIGUA',
          subtitle: 'Del antiguo mar a las montañas',
          body: 'Hace millones de años, lo que hoy es un valle árido estuvo cubierto por un océano inmenso que albergaba una diversidad de vida sorprendente. En esas aguas se formaron ammonites gigantes, corales y braquiópodos, cuyos restos aún permanecen incrustados en la roca como si fueran joyas naturales. Cada fósil marino es una ventana abierta al pasado, una prueba silenciosa de cómo la vida floreció primero en las profundidades, para luego conquistar la superficie. Al caminar por estas montañas, en realidad recorremos un antiguo lecho marino que la fuerza de los Andes elevó hasta convertirlo en cordillera.',
          image: 'assets/nose.jpg',
        ),
        _SectionData(
          key: _fosilesKey,
          title: 'FÓSILES Y HUELLAS',
          subtitle: 'Caminos de dinosaurios',
          body: 'En Toro Toro, los pasos de los dinosaurios siguen resonando con la fuerza del tiempo. Más de 3,500 huellas petrificadas conforman auténticos caminos prehistóricos que atraviesan cañones y laderas. Aquí caminaron saurópodos tan colosales que sus pisadas parecen pequeñas lagunas talladas en la roca; terópodos veloces y cazadores que dejaron su rastro como cicatrices profundas en el barro endurecido; e incluso cuadrúpedos blindados, auténticos tanques vivientes que arrastraban su peso por un mundo salvaje. Cada huella es un instante congelado: un grupo migrando en busca de alimento, un depredador acechando a su presa o un titán avanzando lento bajo la lluvia de hace millones de años.',
          image: 'assets/nose2.jpg',
        ),
        _SectionData(
          key: _vidaNuevaKey,
          title: 'VIDA NUEVA',
          subtitle: 'Ecosistemas actuales',
          body: 'Toro Toro no es solo un santuario de lo antiguo: es también un refugio vivo donde la naturaleza sigue escribiendo su propia historia. La paraba de frente roja, joya alada y en peligro de extinción, surca los cañones como un destello escarlata que tiñe el cielo de vida. En el valle, zorros sigilosos, vizcachas inquietas y quirquinchos resistentes recorren senderos milenarios, recordándonos que la evolución no se detuvo con los dinosaurios, sino que sigue latiendo en cada rincón. La flora, adaptada a la rudeza del clima, se aferra a la tierra con un coraje admirable: cactus erguidos como guardianes ancestrales, flores silvestres diminutas que desafían al sol implacable y arbustos que liberan perfumes que se mezclan con el aire frío de la montaña.',
          image: 'assets/rio.jpg',
        ),
        _SectionData(
          key: _torotoroKey,
          title: 'TOROTORO',
          subtitle: 'Parque Nacional • Potosí, Bolivia',
          body: 'Toro Toro es un lugar donde la tierra habla con voz profunda y antigua. Sus cañones interminables revelan capas de roca que guardan más de 80 millones de años de historia, como páginas abiertas de un libro escrito por el planeta mismo. Las cuevas se abren como portales hacia lo desconocido, donde la oscuridad guarda secretos geológicos y ecos de criaturas desaparecidas. Monolitos de piedra se alzan firmes, como guardianes de un paisaje kárstico único en el mundo, esculpido por agua, viento y tiempo. En cada rincón, un espectáculo distinto: cascadas escondidas entre paredes de roca, valles que parecen forjados por manos de gigantes y senderos que invitan a perderse en lo sagrado y lo salvaje.',
          image: 'assets/monolitos.jpg',
        ),
        _SectionData(
          key: _hombreKey,
          title: 'EL HOMBRE',
          subtitle: 'Rastro cultural',
          body: 'Toro Toro no solo cuenta la historia de la Tierra, también la de quienes aprendieron a vivir en ella y darle sentido. En sus paredes de roca descansan pinturas rupestres trazadas hace miles de años, donde escenas de caza, símbolos ancestrales y visiones cósmicas muestran cómo los primeros pueblos entendían el mundo. Cada trazo es una conversación entre el hombre y la naturaleza, un intento de inmortalizar la vida en piedra. Hoy, las comunidades quechuas mantienen viva esa herencia: sus ferias, danzas, música y relatos son puentes entre el pasado y el presente. Las leyendas narran espíritus de cuevas, guardianes de montañas y huellas sagradas que todavía se veneran.',
          image: 'assets/Roca.jpg',
        ),
      ];
}

// ============================================
// TARJETA DE SECCIÓN MEJORADA
// ============================================
class _SectionCard extends StatelessWidget {
  final String title, subtitle, body, imagePath;
  final bool flipped;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.body,
    required this.imagePath,
    this.flipped = false,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    final image = ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(imagePath, fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: kOlive.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.landscape, color: kOlive, size: 18),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: kOlive,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 18,
            color: kBrown,
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          body,
          textAlign: TextAlign.justify,
          style: TextStyle(
            fontSize: 15,
            height: 1.7,
            color: Colors.black.withOpacity(0.8),
            letterSpacing: 0.2,
          ),
        ),
      ],
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: kOlive.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!flipped) Expanded(flex: 5, child: image),
                  const SizedBox(width: 28),
                  Expanded(flex: 6, child: content),
                  if (flipped) ...[
                    const SizedBox(width: 28),
                    Expanded(flex: 5, child: image),
                  ],
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  image,
                  const SizedBox(height: 20),
                  content,
                ],
              ),
      ),
    );
  }
}

// ============================================
// DATA MODEL
// ============================================
class _SectionData {
  final GlobalKey key;
  final String title, subtitle, body, image;

  _SectionData({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.image,
  });
}