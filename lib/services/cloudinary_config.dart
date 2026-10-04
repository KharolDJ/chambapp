/// Configuración de Cloudinary para subir fotos (perfil, publicaciones,
/// cédula de verificación) y que se vean igual en cualquier dispositivo —
/// antes se guardaba solo la ruta local del archivo, que no existe fuera
/// del celular donde se tomó la foto.
///
/// El "upload preset" en modo Unsigned está pensado para vivir en el
/// código del cliente (no es un secreto como una API key privada) — así
/// es como Cloudinary espera que se use desde apps móviles sin backend.
class CloudinaryConfig {
  static const cloudName = 'lzdwyjkn';
  static const uploadPreset = 'chambapp_fotos';
}
