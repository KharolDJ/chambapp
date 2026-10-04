import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../models/peticion.dart';
import '../models/premium_trabajador.dart';
import '../models/usuario.dart';
import '../providers/app_provider.dart';
import '../widgets/brillo_dorado.dart';
import '../widgets/color_avatar.dart';
import '../widgets/foto_image.dart';
import '../widgets/peticion_card.dart';
import 'login_screen.dart';
import 'perfil_publico_screen.dart';

// Cabecera del feed (título, búsqueda y filtros) en negro profundo fijo —
// no depende del tema claro/oscuro, es la identidad visual de esta zona
// puntual, pedida explícitamente en negro con texto claro encima.
const _fondoCabecera = AppColors.negroProfundo;
const _fillBusqueda = Color(0xFF1C1C1C);

enum OrdenFeed { cercania, recientes }

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  String? _categoriaFiltro;
  bool _soloUrgentes = false;
  OrdenFeed _ordenPor = OrdenFeed.cercania;
  Position? _posicionActual;
  String? _avisoUbicacion;
  String _busqueda = '';
  final _busquedaController = TextEditingController();
  final _scrollController = ScrollController();
  final _listaKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _obtenerUbicacion();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _obtenerUbicacion() async {
    try {
      final servicioActivo = await Geolocator.isLocationServiceEnabled();
      if (!servicioActivo) {
        setState(
          () => _avisoUbicacion =
              'Activa la ubicación para ordenar el feed por cercanía',
        );
        return;
      }

      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.deniedForever) {
        setState(
          () => _avisoUbicacion =
              'Sin permiso de ubicación, el feed se muestra en orden normal',
        );
        return;
      }

      final posicion = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          timeLimit: Duration(seconds: 8),
        ),
      );
      if (!mounted) return;
      setState(() {
        _posicionActual = posicion;
        _avisoUbicacion = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _avisoUbicacion = 'No se pudo obtener tu ubicación, el feed se muestra en orden normal',
      );
    }
  }

  double? _distanciaKm(Peticion p) {
    if (_posicionActual == null || p.lat == null || p.lng == null) return null;
    final metros = Geolocator.distanceBetween(
      _posicionActual!.latitude,
      _posicionActual!.longitude,
      p.lat!,
      p.lng!,
    );
    return metros / 1000;
  }

  void _mostrarFiltro(BuildContext context, List<String> categorias) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: const Text('Todas las categorías'),
              onTap: () {
                setState(() => _categoriaFiltro = null);
                Navigator.pop(context);
              },
            ),
            ...categorias.map(
              (c) => ListTile(
                title: Text(c),
                onTap: () {
                  setState(() => _categoriaFiltro = c);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _alternarOrden() {
    setState(() {
      _ordenPor = _ordenPor == OrdenFeed.cercania
          ? OrdenFeed.recientes
          : OrdenFeed.cercania;
    });
  }

  void _mostrarRadio(BuildContext context) {
    final provider = context.read<AppProvider>();
    const opciones = [1.0, 5.0, 10.0, 20.0, double.infinity];
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: opciones.map((km) {
            final activo = provider.radioBusquedaKm == km;
            return ListTile(
              title: Text(
                km.isInfinite
                    ? 'Toda la ciudad'
                    : '${km.toStringAsFixed(0)} km',
              ),
              trailing: activo
                  ? const Icon(Icons.check, color: AppColors.dorado)
                  : null,
              onTap: () {
                context.read<AppProvider>().actualizarRadioBusqueda(km);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool activo,
    required Color colorActivo,
    required VoidCallback onTap,
    bool desplegable = false,
  }) {
    // El texto ya no puede ser blanco fijo cuando está activo: el dorado de
    // marca es una superficie clara (blanco ilegible encima), mientras que
    // el rojo de "Urgente" sigue siendo oscuro (blanco sí funciona ahí) —
    // se decide por luminancia en vez de asumir un solo fondo posible.
    // Inactivo siempre en blanco: esta píldora vive sobre el fondo negro
    // fijo de la cabecera, no sobre el fondo de página del tema.
    final colorTexto = activo
        ? (colorActivo.computeLuminance() > 0.5
              ? AppColors.negroProfundo
              : Colors.white)
        : Colors.white;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: activo ? colorActivo : Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorTexto,
                ),
              ),
              if (desplegable) ...[
                const SizedBox(width: 2),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: colorTexto.withValues(alpha: activo ? 1 : 0.6),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final categorias = provider.peticiones
        .where((p) => !p.archivada)
        .map((p) => p.categoria)
        .toSet()
        .toList();

    if (provider.categoriaParaVerEnFeed != null) {
      final categoriaPendiente = provider.categoriaParaVerEnFeed!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _categoriaFiltro = categoriaPendiente);
        provider.categoriaParaVerEnFeedConsumida();
      });
    }

    final peticionesVisibles = provider.peticiones.where((p) => !p.archivada);
    var lista = _categoriaFiltro == null
        ? [...peticionesVisibles]
        : peticionesVisibles
              .where((p) => p.categoria == _categoriaFiltro)
              .toList();

    if (_soloUrgentes) {
      lista = lista.where((p) => p.esUrgente).toList();
    }

    if (_busqueda.trim().isNotEmpty) {
      final termino = _busqueda.trim().toLowerCase();
      lista = lista.where((p) {
        return p.barrio.toLowerCase().contains(termino) ||
            p.descripcion.toLowerCase().contains(termino) ||
            p.categoria.toLowerCase().contains(termino);
      }).toList();
    }

    final listaSinFiltroDeRadio = lista;

    if (_posicionActual != null) {
      lista = lista.where((p) {
        final distancia = _distanciaKm(p);
        if (distancia == null) return true;
        return distancia <= provider.radioBusquedaKm;
      }).toList();
    }

    // Urgentes (Visibilidad Premium pagada) primero, luego el criterio
    // elegido (cercanía o recientes). Se aplica siempre, haya o no
    // ubicación disponible.
    lista.sort((a, b) {
      if (a.esUrgente != b.esUrgente) {
        return a.esUrgente ? -1 : 1;
      }
      if (_ordenPor == OrdenFeed.cercania && _posicionActual != null) {
        final da = _distanciaKm(a);
        final db = _distanciaKm(b);
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return da.compareTo(db);
      }
      return b.creadaEn.compareTo(a.creadaEn);
    });

    final personasEncontradas = provider.buscarUsuariosPorNombre(_busqueda);
    final podioCategoria = _categoriaFiltro == null
        ? const <PremiumTrabajador>[]
        : provider.podioPara(_categoriaFiltro!);
    final esEmpleador = provider.rolActual == RolUsuario.empleador;
    final categoriasConPodio = provider.premiumTrabajadores
        .where((p) => p.activo)
        .map((p) => p.oficio)
        .toSet()
        .toList();

    final cargandoUbicacion =
        _posicionActual == null && _avisoUbicacion == null;

    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cerca de ti',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: _fondoCabecera,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 20,
        actions: [
          if (provider.usuarioActual == null)
            IconButton(
              icon: const Icon(Icons.login),
              tooltip: 'Iniciar sesión o registrarme',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          if (cargandoUbicacion)
            Container(
              color: _fondoCabecera,
              child: const LinearProgressIndicator(
                minHeight: 3,
                color: AppColors.dorado,
                backgroundColor: Colors.white24,
              ),
            ),
          if (_avisoUbicacion != null)
            Container(
              width: double.infinity,
              color: const Color(0xFFFAEEDA),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                _avisoUbicacion!,
                style: const TextStyle(fontSize: 12, color: Color(0xFFAD7A16)),
              ),
            ),
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: _fondoCabecera,
              // Esquinas inferiores redondeadas: suaviza la transición del
              // bloque negro hacia el contenido claro de abajo (las
              // superiores quedan a escuadra, contra el borde de pantalla).
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _busquedaController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Buscar...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 20,
                      color: Colors.white70,
                    ),
                    suffixIcon: _busqueda.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(
                              Icons.close,
                              size: 18,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              _busquedaController.clear();
                              setState(() => _busqueda = '');
                            },
                          ),
                    filled: true,
                    fillColor: _fillBusqueda,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) => setState(() => _busqueda = value),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _chip(
                        label: _categoriaFiltro == null
                            ? 'Categoría'
                            : _categoriaFiltro!,
                        activo: _categoriaFiltro != null,
                        // Blanco con texto negro (vía _chip, por luminancia)
                        // en vez del dorado anterior — se pidió así
                        // explícitamente para el estado seleccionado.
                        colorActivo: Colors.white,
                        desplegable: true,
                        onTap: () => _mostrarFiltro(context, categorias),
                      ),
                      _chip(
                        label: 'Urgente',
                        activo: _soloUrgentes,
                        colorActivo: const Color(0xFFB54834),
                        onTap: () =>
                            setState(() => _soloUrgentes = !_soloUrgentes),
                      ),
                      _chip(
                        label: _ordenPor == OrdenFeed.cercania
                            ? 'Cercanía'
                            : 'Recientes',
                        activo: false,
                        colorActivo: Colors.white,
                        onTap: _alternarOrden,
                      ),
                      _chip(
                        label: provider.radioBusquedaKm.isInfinite
                            ? 'Toda la ciudad'
                            : '${provider.radioBusquedaKm.toStringAsFixed(0)} km',
                        activo: false,
                        colorActivo: Colors.white,
                        desplegable: true,
                        onTap: () => _mostrarRadio(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Aire entre la cabecera oscura y lo que sigue (Destacados o el
          // feed) — antes tocaban directo y chocaban visualmente.
          const SizedBox(height: 14),
          Expanded(
            child: CustomScrollView(
              key: _listaKey,
              controller: _scrollController,
              slivers: [
                if (personasEncontradas.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _FranjaPersonas(personas: personasEncontradas),
                  ),
                if (podioCategoria.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _FranjaPodio(
                      categoria: _categoriaFiltro!,
                      podio: podioCategoria,
                    ),
                  )
                else if (_categoriaFiltro == null &&
                    esEmpleador &&
                    categoriasConPodio.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _DestacadosRotativos(
                      categorias: categoriasConPodio,
                      provider: provider,
                      onSeleccionar: (categoria) =>
                          setState(() => _categoriaFiltro = categoria),
                    ),
                  ),
                if (lista.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: lista.length != listaSinFiltroDeRadio.length
                          ? Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    provider.radioBusquedaKm.isInfinite
                                        ? 'No hay publicaciones que coincidan con tu búsqueda'
                                        : 'No hay publicaciones dentro de tu radio de búsqueda (${provider.radioBusquedaKm.toStringAsFixed(0)} km)',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: tema.textTheme.bodySmall?.color,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextButton(
                                    onPressed: () => _mostrarRadio(context),
                                    child: const Text(
                                      'Ampliar radio de búsqueda',
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Text(
                              _soloUrgentes
                                  ? 'No hay publicaciones urgentes con estos filtros'
                                  : 'No hay publicaciones con estos filtros',
                              style: TextStyle(
                                color: tema.textTheme.bodySmall?.color,
                              ),
                            ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => _TarjetaEscalable(
                          controlador: _scrollController,
                          viewportKey: _listaKey,
                          child: PeticionCard(
                            peticion: lista[i],
                            distanciaKm: _distanciaKm(lista[i]),
                          ),
                        ),
                        childCount: lista.length,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Envuelve una tarjeta del feed para que reaccione al scroll: la que está
/// más cerca del centro del viewport se ve a tamaño casi completo, y las
/// que se alejan hacia arriba/abajo se van achicando — efecto tipo
/// carrusel/lista dinámica. Se mide con RenderBox en cada tick de scroll
/// (AnimatedBuilder escuchando el mismo ScrollController de la lista) en
/// vez de un paquete externo; el costo es despreciable porque Sliver solo
/// construye las tarjetas cercanas al viewport.
class _TarjetaEscalable extends StatelessWidget {
  static const _escalaMinima = 0.94;
  static const _escalaMaxima = 1.0;

  final ScrollController controlador;
  final GlobalKey viewportKey;
  final Widget child;

  const _TarjetaEscalable({
    required this.controlador,
    required this.viewportKey,
    required this.child,
  });

  double _calcularEscala(BuildContext context) {
    final cajaViewport =
        viewportKey.currentContext?.findRenderObject() as RenderBox?;
    final cajaItem = context.findRenderObject() as RenderBox?;
    if (cajaViewport == null || cajaItem == null || !cajaItem.attached) {
      return _escalaMaxima;
    }

    final posicionItem = cajaItem.localToGlobal(
      Offset.zero,
      ancestor: cajaViewport,
    );
    final centroItem = posicionItem.dy + cajaItem.size.height / 2;
    final centroViewport = cajaViewport.size.height / 2;
    final distancia = (centroItem - centroViewport).abs();
    final distanciaMaxima = centroViewport + cajaItem.size.height / 2;
    if (distanciaMaxima <= 0) return _escalaMaxima;

    final factor = (distancia / distanciaMaxima).clamp(0.0, 1.0);
    return _escalaMaxima - factor * (_escalaMaxima - _escalaMinima);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controlador,
      builder: (_, hijo) {
        return Transform.scale(
          scale: _calcularEscala(context),
          alignment: Alignment.center,
          filterQuality: FilterQuality.low,
          child: hijo,
        );
      },
      child: child,
    );
  }
}

/// Franja horizontal deslizable con los usuarios cuyo nombre coincide con la
/// búsqueda actual del feed. Aparte de la lista de publicaciones para no
/// alterar su lógica de orden (premium/urgente/cercanía).
class _FranjaPersonas extends StatelessWidget {
  final List<Usuario> personas;
  const _FranjaPersonas({required this.personas});

  ImageProvider? _fotoSiExiste(Usuario u) => proveedorFoto(u.fotoPath);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 16, bottom: 6),
            child: Text(
              'PERSONAS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: Colors.grey,
              ),
            ),
          ),
          SizedBox(
            height: 88,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: personas.length,
              itemBuilder: (context, i) {
                final u = personas[i];
                final foto = _fotoSiExiste(u);
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PerfilPublicoScreen(usuarioId: u.id),
                      ),
                    ),
                    child: SizedBox(
                      width: 72,
                      child: Column(
                        children: [
                          Builder(
                            builder: (context) {
                              final colorAvatar = colorAvatarPara(u.id);
                              return CircleAvatar(
                                radius: 26,
                                backgroundColor: colorAvatar.fondo,
                                backgroundImage: foto,
                                child: foto == null
                                    ? Text(
                                        u.nombre[0].toUpperCase(),
                                        style: TextStyle(
                                          color: colorAvatar.texto,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      )
                                    : null,
                              );
                            },
                          ),
                          const SizedBox(height: 4),
                          Text(
                            u.nombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Vitrina de "quién está destacado ahora" en el feed general (sin filtro
/// de categoría) para el empleador. En vez de amontonar todas las
/// categorías en cuadritos pequeños, muestra una sola categoría a la vez
/// con el mismo diseño limpio de [_FranjaPodio] y va rotando sola cada
/// pocos segundos — así cada persona destacada tiene espacio real en vez
/// de competir por un cuadrito diminuto. Tocar el encabezado aplica el
/// filtro de esa categoría, igual que si se hubiera elegido desde el chip
/// "Categoría"; tocar un avatar va directo a ese perfil.
class _DestacadosRotativos extends StatefulWidget {
  final List<String> categorias;
  final AppProvider provider;
  final ValueChanged<String> onSeleccionar;
  const _DestacadosRotativos({
    required this.categorias,
    required this.provider,
    required this.onSeleccionar,
  });

  @override
  State<_DestacadosRotativos> createState() => _DestacadosRotativosState();
}

class _DestacadosRotativosState extends State<_DestacadosRotativos> {
  int _indice = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _iniciarRotacion();
  }

  void _iniciarRotacion() {
    _timer?.cancel();
    if (widget.categorias.length <= 1) return;
    // Antes 16s — "un poco más pausado" según lo confirmado.
    _timer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (!mounted) return;
      setState(() => _indice = (_indice + 1) % widget.categorias.length);
    });
  }

  @override
  void didUpdateWidget(covariant _DestacadosRotativos oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.categorias.length != oldWidget.categorias.length) {
      _indice = 0;
      _iniciarRotacion();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoria = widget.categorias[_indice % widget.categorias.length];
    final podio = widget.provider.podioPara(categoria);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, animacion) => FadeTransition(
            opacity: animacion,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.04, 0),
                end: Offset.zero,
              ).animate(animacion),
              child: child,
            ),
          ),
          child: _FranjaPodio(
            key: ValueKey(categoria),
            categoria: categoria,
            podio: podio,
            onCategoriaTap: () => widget.onSeleccionar(categoria),
          ),
        ),
        if (widget.categorias.length > 1)
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 12),
            child: Row(
              children: [
                for (var i = 0; i < widget.categorias.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(right: 5),
                    width: i == _indice ? 14 : 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: i == _indice
                          ? AppColors.dorado
                          : Theme.of(context).dividerColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Franja horizontal con los trabajadores destacados en el oficio filtrado
/// actualmente. Las 3 tarjetas se ven exactamente iguales entre sí — el
/// orden es solo quién se aprobó primero, no un ranking por calidad; darle
/// un tratamiento visual de 1°/2°/3° insinuaría una recomendación que no
/// corresponde a lo que se está vendiendo.
class _FranjaPodio extends StatelessWidget {
  final String categoria;
  final List<PremiumTrabajador> podio;
  final VoidCallback? onCategoriaTap;
  const _FranjaPodio({
    super.key,
    required this.categoria,
    required this.podio,
    this.onCategoriaTap,
  });

  ImageProvider? _fotoSiExiste(String? ruta) => proveedorFoto(ruta);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final tema = Theme.of(context);
    // Mismo anillo dorado animado que ya usan las tarjetas y perfiles
    // Premium aprobados (ver brillo_dorado.dart) — unifica esta franja con
    // esa identidad visual en vez de un borde estático aparte.
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: BrilloDoradoAnimado(
        borderRadius: BorderRadius.circular(16),
        builder: (context, t) => Container(
          decoration: BoxDecoration(
            color: tema.cardColor,
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: onCategoriaTap,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Destacados en $categoria',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                          color: Color(0xFFAD7A16),
                        ),
                      ),
                    ),
                    if (onCategoriaTap != null)
                      const Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: Color(0xFFAD7A16),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 104,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: podio.length,
                  itemBuilder: (context, i) {
                    final p = podio[i];
                    // [PremiumTrabajador] guarda una foto de perfil de
                    // calificación tomados al momento de activar Premium — si
                    // la persona no tenía foto o calificaciones todavía en ese
                    // momento, ese snapshot se queda así por los 30 días
                    // siguientes aunque actualice su perfil real. Se prefieren
                    // los datos en vivo de [todosLosUsuarios] cuando existen, y
                    // solo se cae al snapshot si esa persona no está cargada
                    // (ej. navegando sin sesión).
                    final coincidencias = provider.todosLosUsuarios.where(
                      (u) => u.id == p.usuarioId,
                    );
                    final usuarioEnVivo = coincidencias.isEmpty
                        ? null
                        : coincidencias.first;
                    final nombre = usuarioEnVivo?.nombre ?? p.usuarioNombre;
                    final foto = _fotoSiExiste(
                      usuarioEnVivo?.fotoPath ?? p.usuarioFotoPath,
                    );
                    final calificacionPromedio =
                        usuarioEnVivo?.calificacionPromedio ??
                        p.calificacionPromedio;
                    final numeroCalificaciones =
                        usuarioEnVivo?.numeroCalificaciones ??
                        p.numeroCalificaciones;
                    final colorAvatar = colorAvatarPara(p.usuarioId);
                    return Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                PerfilPublicoScreen(usuarioId: p.usuarioId),
                          ),
                        ),
                        child: SizedBox(
                          width: 80,
                          child: Column(
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundColor: colorAvatar.fondo,
                                    backgroundImage: foto,
                                    child: foto == null
                                        ? Text(
                                            nombre[0].toUpperCase(),
                                            style: TextStyle(
                                              color: colorAvatar.texto,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                            ),
                                          )
                                        : null,
                                  ),
                                  Positioned(
                                    bottom: -2,
                                    right: -2,
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      // Excepción explícita: la estrella de
                                      // perfil destacado conserva su estilo
                                      // dorado + blanco de siempre, sin el
                                      // ajuste de contraste negro-sobre-dorado
                                      // que sí se aplica al resto de la app.
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFAD7A16),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.star,
                                        size: 10,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                nombre,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface,
                                ),
                              ),
                              if (numeroCalificaciones > 0)
                                Text(
                                  '★ ${calificacionPromedio.toStringAsFixed(1)}',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    color: Color(0xFFAD7A16),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
