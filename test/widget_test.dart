// Pruebas de la lógica que no depende de Firebase: el número de WhatsApp,
// la ubicación aproximada de las publicaciones, qué datos de un interesado
// se guardan dentro de una publicación y los mensajes de pago de Wompi.
// (La prueba anterior abría la app completa y fallaba porque Firebase no
// está disponible en el entorno de pruebas.)

import 'package:flutter_test/flutter_test.dart';

import 'package:chambapp/models/peticion.dart';
import 'package:chambapp/models/usuario.dart';
import 'package:chambapp/screens/pago_wompi_screen.dart';
import 'package:chambapp/utils/formatos.dart';

void main() {
  group('numeroWhatsApp', () {
    test('antepone 57 a un celular de 10 dígitos', () {
      expect(numeroWhatsApp('3001234567'), '573001234567');
    });

    test('no duplica el 57 si ya viene con el indicativo', () {
      expect(numeroWhatsApp('573001234567'), '573001234567');
      expect(numeroWhatsApp('+57 300 123 4567'), '573001234567');
    });
  });

  test('redondearCoordenada deja 3 decimales (unos 100 metros)', () {
    expect(redondearCoordenada(7.119876), 7.12);
    expect(redondearCoordenada(-73.121049), -73.121);
  });

  test('el celular de un interesado no se guarda dentro de la publicación', () {
    final interesado = Usuario(
      id: 'u1',
      nombre: 'Ana',
      correo: 'ana@example.com',
      celular: '3001234567',
    );
    final mapa = Peticion.interesadoAMapa(interesado);
    expect(mapa.containsKey('celular'), isFalse);
    expect(mapa['nombre'], 'Ana');
  });

  group('ResultadoPagoWompi.mensajeNoAprobado', () {
    test('un pago pendiente no se presenta como rechazado', () {
      const r = ResultadoPagoWompi(estado: 'PENDING', transaccionId: 'tx-1');
      expect(r.mensajeNoAprobado, contains('en proceso'));
      expect(r.mensajeNoAprobado, contains('tx-1'));
    });

    test('un pago rechazado avisa que no hubo cobro', () {
      const r = ResultadoPagoWompi(estado: 'DECLINED', transaccionId: 'tx-2');
      expect(r.mensajeNoAprobado, contains('rechazó'));
    });
  });
}
