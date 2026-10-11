/// Número listo para `https://wa.me/`: los celulares colombianos se
/// registran con 10 dígitos, pero si alguien lo escribió con el indicativo
/// 57 no se le vuelve a anteponer (antes quedaba 5757…, un número inválido).
String numeroWhatsApp(String celular) {
  final digitos = celular.replaceAll(RegExp(r'\D'), '');
  if (digitos.length > 10 && digitos.startsWith('57')) return digitos;
  return '57$digitos';
}

/// Redondea una coordenada a 3 decimales (unos 100 metros) antes de
/// guardarla en una publicación, que cualquiera puede leer: alcanza para
/// ordenar el feed por cercanía sin revelar la dirección exacta de quien
/// publica.
double redondearCoordenada(double valor) => (valor * 1000).round() / 1000;
