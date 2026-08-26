import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../models/peticion.dart';
import '../providers/app_provider.dart';
import '../widgets/peticion_card.dart';
import 'configuracion_screen.dart';
import 'login_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  String? _categoriaFiltro;
  Position? _posicionActual;
  String? _avisoUbicacion;
  bool _modoBusqueda = false;
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final categorias = provider.peticiones.map((p) => p.categoria).toSet().toList();
    var lista = _categoriaFiltro == null
        ? [...provider.peticiones]
        : provider.peticiones.where((p) => p.categoria == _categoriaFiltro).toList();

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

      lista.sort((a, b) {
        final da = _distanciaKm(a);
        final db = _distanciaKm(b);
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return da.compareTo(db);
      });
    }

    final cargandoUbicacion = _posicionActual == null && _avisoUbicacion == null;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F0),
      appBar: AppBar(
        title: _modoBusqueda
            ? TextField(
                controller: _busquedaController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Buscar por barrio, categoría o descripción...',
                  border: InputBorder.none,
                ),
                onChanged: (value) => setState(() => _busqueda = value),
              )
            : const Text('Cerca de ti'),
        backgroundColor: const Color(0xFFFAF7F0),
        foregroundColor: const Color(0xFF26312D),
        elevation: 0,
        actions: [
          if (_modoBusqueda)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() {
                _modoBusqueda = false;
                _busqueda = '';
                _busquedaController.clear();
              }),
            )
          else ...[
            if (provider.usuarioActual == null)
              IconButton(
                icon: const Icon(Icons.login),
                tooltip: 'Iniciar sesión o registrarme',
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
              ),
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Buscar por barrio o zona',
              onPressed: () => setState(() => _modoBusqueda = true),
            ),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () => _mostrarFiltro(context, categorias),
            ),
          ],
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
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const ConfiguracionScreen()),
                                  ),
                                  child: const Text('Ampliar radio de búsqueda'),
                                ),
                              ],
                            ),
                          )
                        : const Text('No hay publicaciones en esta categoría'),
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
