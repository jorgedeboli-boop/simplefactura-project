import '../models/rol.dart';

/// Roles base del tenant (coinciden con 03_seed_paises_iva.sql).
/// Fallback si el endpoint roles_listar no esta disponible en el servidor.
class RolesCatalogo {
  static final List<Rol> porDefecto = [
    Rol(id: 1, nombre: 'Administrador', nivel: 1, descripcion: 'Acceso total'),
    Rol(id: 2, nombre: 'Gestor', nivel: 2, descripcion: 'Gestion comercial'),
    Rol(id: 3, nombre: 'Comercial', nivel: 3, descripcion: 'Ventas y facturacion'),
    Rol(id: 4, nombre: 'Solo lectura', nivel: 4, descripcion: 'Consulta unicamente'),
  ];
}
