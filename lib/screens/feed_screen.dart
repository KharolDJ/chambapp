import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../models/peticion.dart';
import '../providers/app_provider.dart';
import '../widgets/peticion_card.dart';
import 'login_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _obtenerUbicacion();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  Future<void> _obtenerUbicacion() async {
    try {
      final servicioActivo = await Geolocator.isLocationServiceEnabled();
      if (!servicioActivo) {
        setState(() => _avisoUbicacion = 'Activa la ubicación para ordenar el feed por cercanía');
        return;
      }

      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.denied || permiso == LocationPermission.deniedForever) {
        setState(() => _avisoUbicacion = 'Sin permiso de ubicación, el feed se muestra en orden normal');
        return;
      }

      final posicion = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _posicionActual = posicion;
        _avisoUbicacion = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _avisoUbicacion = 'No se pudo obtener tu ubicación, el feed se muestra en orden normal');
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Todas las categorías'),
              onTap: () {
                setState(() => _categoriaFiltro = null);
                Navigator.pop(context);
              },
            ),
            ...categorias.map((c) => ListTile(
                  title: Text(c),
                  onTap: () {
                    setState(() => _categoriaFiltro = c);
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _mostrarOrden(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Cercanía'),
              trailing: _ordenPor == OrdenFeed.cercania ? const Icon(Icons.check, color: Color(0xFF0F6E56)) : null,
              onTap: () {
                setState(() => _ordenPor = OrdenFeed.cercania);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Más recientes'),
              trailing: _ordenPor == OrdenFeed.recientes ? const Icon(Icons.check, color: Color(0xFF0F6E56)) : null,
              onTap: () {
                setState(() => _ordenPor = OrdenFeed.recientes);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarRadio(BuildContext context) {
    final provider = context.read<AppProvider>();
    const opciones = [1.0, 5.0, 10.0, 20.0, double.infinity];
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: opciones.map((km) {
            final activo = provider.radioBusquedaKm == km;
            return ListTile(
              title: Text(km.isInfinite ? 'Toda la ciudad' : '${km.toStringAsFixed(0)} km'),
              trailing: activo ? const Icon(Icons.check, color: Color(0xFF0F6E56)) : null,
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
    IconData? icono,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: activo ? colorActivo : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: activo ? colorActivo : Colors.grey.shade300),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icono != null) ...[
                Icon(icono, size: 15, color: activo ? Colors.white : Colors.grey.shade700),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: activo ? Colors.white : const Color(0xFF26312D),
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
    final categorias = provider.peticiones.map((p) => p.categoria).toSet().toList();

    var lista = _categoriaFiltro == null
        ? [...provider.peticiones]
        : provider.peticiones.where((p) => p.categoria == _categoriaFiltro).toList();

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

    final cargandoUbicacion = _posicionActual == null && _avisoUbicacion == null;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F0),
      appBar: AppBar(
        title: const Text('Cerca de ti'),
        backgroundColor: const Color(0xFFFAF7F0),
        foregroundColor: const Color(0xFF26312D),
        elevation: 0,
        actions: [
          if (provider.usuarioActual == null)
            IconButton(
              icon: const Icon(Icons.login),
              tooltip: 'Iniciar sesión o registrarme',
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
            ),
        ],
      ),
      body: Column(
        children: [
          if (cargandoUbicacion)
            const LinearProgressIndicator(
              minHeight: 3,
              color: Color(0xFF0F6E56),
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
            color: const Color(0xFFFAF7F0),
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
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  onChanged: (value) => setState(() => _busqueda = value),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _chip(
                        label: _categoriaFiltro == null ? 'Categoría ▾' : '$_categoriaFiltro ▾',
                        activo: _categoriaFiltro != null,
                        colorActivo: const Color(0xFF0F6E56),
                        onTap: () => _mostrarFiltro(context, categorias),
                      ),
                      _chip(
                        label: 'Urgente',
                        icono: Icons.bolt,
                        activo: _soloUrgentes,
                        colorActivo: const Color(0xFFB54834),
                        onTap: () => setState(() => _soloUrgentes = !_soloUrgentes),
                      ),
                      _chip(
                        label: _ordenPor == OrdenFeed.cercania ? 'Ordenar: Cercanía ▾' : 'Ordenar: Recientes ▾',
                        activo: false,
                        colorActivo: const Color(0xFF0F6E56),
                        onTap: () => _mostrarOrden(context),
                      ),
                      _chip(
                        label: provider.radioBusquedaKm.isInfinite
                            ? 'Toda la ciudad ▾'
                            : '${provider.radioBusquedaKm.toStringAsFixed(0)} km ▾',
                        icono: Icons.location_on_outlined,
                        activo: false,
                        colorActivo: const Color(0xFF0F6E56),
                        onTap: () => _mostrarRadio(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: lista.isEmpty
                ? Center(
                    child: lista.length != listaSinFiltroDeRadio.length
                        ? Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  provider.radioBusquedaKm.isInfinite
                                      ? 'No hay publicaciones que coincidan con tu búsqueda'
                                      : 'No hay publicaciones dentro de tu radio de búsqueda (${provider.radioBusquedaKm.toStringAsFixed(0)} km)',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: () => _mostrarRadio(context),
                                  child: const Text('Ampliar radio de búsqueda'),
                                ),
                              ],
                            ),
                          )
                        : Text(
                            _soloUrgentes
                                ? 'No hay publicaciones urgentes con estos filtros'
                                : 'No hay publicaciones con estos filtros',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: lista.length,
                    itemBuilder: (context, i) => PeticionCard(
                      peticion: lista[i],
                      distanciaKm: _distanciaKm(lista[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
