# Simple Factura

Facturación sencilla para España, México, Costa Rica, Panamá, Guatemala, Colombia, Chile, Perú y Ecuador.

Dominio de la app: `my.simplefactura.app`
Color de marca: `#398bf7`

## Arquitectura general

**Multi-tenant con una base de datos independiente por cliente.** Cuando un cliente se registra y paga (futura web de marketing), se le aprovisiona una base de datos propia con todos sus datos aislados del resto. Hoy empezamos con un tenant de pruebas creado a mano.

```
simplefactura_control      <- 1 sola base, lista de tenants + enrutamiento de sesiones
sf_cliente_pruebas         <- base del tenant de pruebas (usuarios, facturas, clientes...)
sf_<siguiente_cliente>     <- una base nueva por cada cliente que se dé de alta
```

### ¿Cómo sabe la API a qué base conectarse?

1. El usuario hace login enviando `empresa` (identificador del tenant, ej. `cliente_pruebas`) + `email` + `password`.
2. El backend busca ese tenant en `simplefactura_control.tenants`, valida el usuario en la base de ese tenant, y genera un `token`.
3. El token se guarda en `simplefactura_control.tokens_globales` (token → tenant + usuario).
4. En cada petición siguiente, la app solo manda el token (`Authorization: Bearer ...`); el backend lo busca en `tokens_globales` para saber a qué base conectarse. No hace falta reenviar el identificador de empresa en cada llamada.

### Por qué MariaDB 10.1 condiciona el diseño

10.1 no tiene tipo `JSON` nativo, ni CTEs (`WITH ...`), ni funciones de ventana. El esquema evita todo eso: los permisos de roles usan una tabla pivote (`roles_permisos`) en vez de una columna JSON, y las consultas son SQL clásico.

## Base de datos

Carpeta `database/`, ejecutar en este orden:

| Archivo | Qué hace |
|---|---|
| `01_control_schema.sql` | Crea `simplefactura_control` (tenants, planes, tokens_globales, países) |
| `02_tenant_schema.sql` | Plantilla de base para UN tenant (sustituir `{DB_NAME}`) |
| `03_seed_paises_iva.sql` | Países, tipos de IVA/IGV/ITBMS, roles, permisos, series de numeración |
| `04_seed_cliente_pruebas.sql` | Datos del tenant de pruebas + INSERT a preparar en `simplefactura_control` |

Para dar de alta el cliente de pruebas manualmente:

```bash
mysql -u root -p -e "CREATE DATABASE sf_cliente_pruebas DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
# En 02_tenant_schema.sql, sustituir {DB_NAME} por sf_cliente_pruebas antes de ejecutar
mysql -u root -p sf_cliente_pruebas < database/02_tenant_schema.sql
mysql -u root -p sf_cliente_pruebas < database/03_seed_paises_iva.sql
mysql -u root -p sf_cliente_pruebas < database/04_seed_cliente_pruebas.sql   # PARTE 1

mysql -u root -p -e "CREATE DATABASE simplefactura_control DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -u root -p simplefactura_control < database/01_control_schema.sql
mysql -u root -p simplefactura_control < database/03_seed_paises_iva.sql   # solo la parte de paises, o adaptar
# Luego ejecutar el INSERT comentado al final de 04_seed_cliente_pruebas.sql (PARTE 2)
```

**Login de prueba:** empresa `cliente_pruebas`, email `admin@empresapruebas.test`, contraseña `Prueba1234!` (cambiar en cuanto se use en un entorno real).

## Backend (`backend/`)

PHP puro **sin clases**, solo funciones. Cada endpoint es un archivo que responde JSON.

```
config/constantes.php   credenciales y configuración
config/db.php           conexión mysqli procedural + helpers db_consultar() / db_ejecutar()
lib/respuesta.php        responder_json() / responder_error()
lib/auth.php              tokens, auth_requerir_sesion(), auth_requerir_permiso()
lib/validacion.php        validar_campos_requeridos(), validar_email()...
lib/utilidades.php        generar_numero_documento() (correlativo legal), calcular_totales_documento()
endpoints/*.php           un archivo por acción (auth_login, clientes_crear, etc.)
index.php                 router: /api/index.php?accion=clientes_listar
```

**Patrón para agregar un endpoint nuevo** (ej. `presupuestos_crear`):
1. Crear `endpoints/presupuestos_crear.php` siguiendo el mismo patrón que `clientes_crear.php`: validar método HTTP, `auth_requerir_sesion()`, `auth_requerir_permiso()`, validar entrada, `db_ejecutar()`, `responder_json()`.
2. Registrar la acción en el array `$rutas` de `index.php`.

Todavía **faltan por construir** (siguiendo el mismo patrón): proveedores, presupuestos, facturas (normal/simplificada/rectificativa), y el flujo de generación de PDF.

## App Flutter (`flutter_app/`)

Gestión de estado con **Provider** (la opción más simple de mantener). Un solo código para móvil, escritorio y web — en web, el usuario imprime facturas usando el diálogo de impresión del navegador, sin integraciones especiales.

```
lib/theme/app_theme.dart      color de marca (#398bf7) y estilos
lib/services/api_service.dart  cliente HTTP hacia el backend PHP
lib/providers/auth_provider.dart  estado de sesión (login/logout/restaurar)
lib/models/                    modelos (Usuario, Empresa...)
lib/screens/login_screen.dart  pantalla de login (empresa + email + password)
lib/screens/home_screen.dart   placeholder, aquí cuelgan los módulos
assets/logo/                   logotipo de marca
```

Antes de compilar: ajustar `ApiService.baseUrl` en `lib/services/api_service.dart` a la URL real del backend.

**Todavía faltan por construir:** pantallas de clientes, proveedores, presupuestos, facturas y configuración de empresa/usuarios — cada una consumirá los endpoints ya construidos o los que se agreguen siguiendo el patrón descrito arriba.

## Regímenes de IVA/IGV soportados (2026)

| País | Impuesto | Tasa general | Otras tasas |
|---|---|---|---|
| España | IVA | 21% | 10%, 4% |
| México | IVA | 16% | 8% (frontera, hasta 31/12/2026), 0% |
| Costa Rica | IVA | 13% | 4%, 2%, 1% |
| Panamá | ITBMS | 7% | 10% (alcohol/hospedaje), 15% (tabaco) |
| Guatemala | IVA | 12% | — |
| Colombia | IVA | 19% | 5%, 0% |
| Chile | IVA | 19% | — |
| Perú | IGV | 18% | — |
| Ecuador | IVA | 15% | 0% |

Cada tenant guarda su propio catálogo de tasas en su tabla `iva_tipos` (sembrado al aprovisionar), así que si un país cambia su tasa solo hay que actualizar ese registro por tenant afectado.

**Importante:** este modelo cubre el cálculo de IVA/IGV y la numeración correlativa de documentos, pero **no implementa facturación electrónica ante las autoridades fiscales** (CFDI en México, DIAN en Colombia, SII en Chile, SUNAT en Perú, etc.). Cada país tiene su propio esquema de facturación electrónica obligatoria con requisitos distintos (firma digital, XML, folios autorizados, APIs gubernamentales o de PACs certificados). Eso es un desarrollo país por país que queda pendiente para una siguiente fase.

## Próximos pasos sugeridos

1. Completar los endpoints que faltan (proveedores, presupuestos, facturas) siguiendo el patrón ya establecido.
2. Construir las pantallas Flutter correspondientes.
3. Generación de PDF de factura/presupuesto (del lado del backend, para poder enviarlo también por email).
4. Página de marketing + cobro + aprovisionamiento automático de tenants (crear BD, ejecutar los 3 scripts SQL, insertar en `tenants`).
5. Evaluar, país por país, el requisito de facturación electrónica antes de salir a producción en ese país.
