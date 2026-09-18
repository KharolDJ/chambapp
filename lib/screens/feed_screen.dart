import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../models/peticion.dart';
import '../models/premium_trabajador.dart';
import '../models/usuario.dart';
import '../providers/app_provider.dart';
import '../widgets/color_avatar.dart';
import '../widgets/peticion_card.dart';
import 'login_screen.dart';
import 'perfil_publico_screen.dart';

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
                  ? const Icon(Icons.check, color: AppColors.azulCeleste)
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
    Widget? icono,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: activo ? colorActivo : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: activo ? colorActivo : Theme.of(context).dividerColor,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icono != null) ...[icono, const SizedBox(width: 4)],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: activo
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
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
      lista = lista.where((p) => p.urgente).toList();
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

    // Premium primero, luego urgente, luego el criterio elegido (cercanía o
    // recientes). Se aplica siempre, haya o no ubicación disponible.
    lista.sort((a, b) {
      if (a.premiumAprobada != b.premiumAprobada) {
        return a.premiumAprobada ? -1 : 1;
      }
      if (a.urgente != b.urgente) {
        return a.urgente ? -1 : 1;
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
        title: const Text('Cerca de ti'),
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
            const LinearProgressIndicator(
              minHeight: 3,
              color: AppColors.azulCeleste,
              backgroundColor: Color(0xFFE1F5EE),
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
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _busquedaController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por barrio, categoría o descripción...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _busqueda.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              _busquedaController.clear();
                              setState(() => _busqueda = '');
                            },
                          ),
                    filled: true,
                    fillColor: tema.cardColor,
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
                            ? 'Categoría ▾'
                            : '$_categoriaFiltro ▾',
                        activo: _categoriaFiltro != null,
                        colorActivo: AppColors.azulCeleste,
                        onTap: () => _mostrarFiltro(context, categorias),
                      ),
                      _chip(
                        label: 'Urgente',
                        icono: SizedBox(
                          width: 20,
                          height: 20,
                          child: Image.asset(
                            'assets/icon/urgente.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        activo: _soloUrgentes,
                        colorActivo: const Color(0xFFEF4444),
                        onTap: () =>
                            setState(() => _soloUrgentes = !_soloUrgentes),
                      ),
                      _chip(
                        label: _ordenPor == OrdenFeed.cercania
                            ? 'Cercanía'
                            : 'Recientes',
                        icono: _ordenPor == OrdenFeed.cercania
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: Image.asset(
                                  'assets/icon/cercania.png',
                                  fit: BoxFit.contain,
                                ),
                              )
                            : Icon(
                                Icons.access_time,
                                size: 15,
                                color: tema.textTheme.bodySmall?.color,
                              ),
                        activo: false,
                        colorActivo: AppColors.azulCeleste,
                        onTap: _alternarOrden,
                      ),
                      _chip(
                        label: provider.radioBusquedaKm.isInfinite
                            ? 'Toda la ciudad ▾'
                            : '${provider.radioBusquedaKm.toStringAsFixed(0)} km ▾',
                        icono: SizedBox(
                          width: 20,
                          height: 20,
                          child: Image.asset(
                            'assets/icon/toda_la_ciudad.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        activo: false,
                        colorActivo: AppColors.azulCeleste,
                        onTap: () => _mostrarRadio(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
                    child: _CarruselPodios(
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

  ImageProvider? _fotoSiExiste(Usuario u) {
    final ruta = u.fotoPath;
    if (ruta == null) return null;
    final archivo = File(ruta);
    if (!archivo.existsSync()) return null;
    return FileImage(archivo);
  }

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

/// Carrusel de categorías con Podio activo, visible en el feed general (sin
/// filtro de categoría) para el empleador — vitrina de "quién está
/// destacado ahora" sin obligar a filtrar manualmente primero. Tocar una
/// tarjeta aplica el filtro de esa categoría, igual que si se hubiera
/// elegido desde el chip "Categoría".
class _CarruselPodios extends StatelessWidget {
  final List<String> categorias;
  final AppProvider provider;
  final ValueChanged<String> onSeleccionar;
  const _CarruselPodios({
    required this.categorias,
    required this.provider,
    required this.onSeleccionar,
  });

  ImageProvider? _fotoSiExiste(String? ruta) {
    if (ruta == null) return null;
    final archivo = File(ruta);
    if (!archivo.existsSync()) return null;
    return FileImage(archivo);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 16, bottom: 8),
            child: Row(
              children: [
                Icon(
                  Icons.emoji_events,
                  size: 15,
                  color: AppColors.azulCeleste,
                ),
                SizedBox(width: 6),
                Text(
                  'DESTACADOS POR CATEGORÍA',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: AppColors.azulCeleste,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 118,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categorias.length,
              itemBuilder: (context, i) {
                final categoria = categorias[i];
                final podio = provider.podioPara(categoria);
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => onSeleccionar(categoria),
                    child: Container(
                      width: 168,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.azulCeleste,
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.azulCeleste.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            categoria,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const Spacer(),
                          SizedBox(
                            height: 32,
                            child: Stack(
                              children: [
                                for (var j = 0; j < podio.length; j++)
                                  Positioned(
                                    left: j * 20.0,
                                    child: CircleAvatar(
                                      radius: 16,
                                      backgroundColor: Theme.of(context)
                                          .cardColor,
                                      child: Builder(
                                        builder: (context) {
                                          final foto = _fotoSiExiste(
                                            podio[j].usuarioFotoPath,
                                          );
                                          final colorAvatar = colorAvatarPara(
                                            podio[j].usuarioId,
                                          );
                                          return CircleAvatar(
                                            radius: 14,
                                            backgroundColor: colorAvatar.fondo,
                                            backgroundImage: foto,
                                            child: foto == null
                                                ? Text(
                                                    podio[j].usuarioNombre[0]
                                                        .toUpperCase(),
                                                    style: TextStyle(
                                                      color: colorAvatar.texto,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 11,
                                                    ),
                                                  )
                                                : null,
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${provider.vipActivosPara(categoria).length} VIP en rotación',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.color,
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

/// Franja horizontal con los trabajadores destacados en el oficio filtrado
/// actualmente. Las 3 tarjetas se ven exactamente iguales entre sí — el
/// orden es solo quién se aprobó primero, no un ranking por calidad; darle
/// un tratamiento visual de 1°/2°/3° insinuaría una recomendación que no
/// corresponde a lo que se está vendiendo.
class _FranjaPodio extends StatelessWidget {
  final String categoria;
  final List<PremiumTrabajador> podio;
  const _FranjaPodio({required this.categoria, required this.podio});

  ImageProvider? _fotoSiExiste(String? ruta) {
    if (ruta == null) return null;
    final archivo = File(ruta);
    if (!archivo.existsSync()) return null;
    return FileImage(archivo);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.azulCeleste, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.azulCeleste.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.emoji_events,
                size: 15,
                color: Color(0xFFAD7A16),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  'PODIO DE RECOMENDADOS · ${categoria.toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.4,
                    color: Color(0xFFAD7A16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: podio.length,
              itemBuilder: (context, i) {
                final p = podio[i];
                final foto = _fotoSiExiste(p.usuarioFotoPath);
                final colorAvatar = colorAvatarPara(p.usuarioId);
                return Padding(
                  padding: const EdgeInsets.only(right: 14),
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
                      width: 72,
                      child: Column(
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.azulCeleste,
                                ),
                                child: CircleAvatar(
                                  radius: 24,
                                  backgroundColor: colorAvatar.fondo,
                                  backgroundImage: foto,
                                  child: foto == null
                                      ? Text(
                                          p.usuarioNombre[0].toUpperCase(),
                                          style: TextStyle(
                                            color: colorAvatar.texto,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 17,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                              Positioned(
                                bottom: -2,
                                right: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFAD7A16),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.star,
                                    size: 9,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            p.usuarioNombre,
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
