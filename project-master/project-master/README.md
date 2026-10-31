# Inventario Inteligente

Aplicación móvil Flutter para gestionar el inventario de un pequeño comercio o
bodega: consulta de existencias, registro de entradas y salidas, generación y
lectura de códigos de barras y QR, e historial de movimientos.

**Curso:** Programación de Dispositivos Móviles II — UMES
**Periodo:** Segundo semestre 2026 — Proyecto de cierre 1

## Funcionalidades

- **Productos:** alta, edición, baja lógica (desactivar) y reactivación. Cada
  producto tiene código único, categoría, precios de compra y venta, stock
  mínimo y valor en inventario.
- **Códigos:** genera un código de barras Code 128 y un código QR por producto.
  El QR codifica únicamente el código del producto (nunca el stock, que cambia
  con cada movimiento). Se pueden imprimir o compartir como PDF.
- **Escaneo:** lectura de códigos de barras y QR con la cámara, más una entrada
  manual para equipos sin cámara.
- **Movimientos:** entradas, salidas y ajustes por conteo físico. Las salidas
  nunca pueden superar las existencias; todo movimiento exige un motivo y queda
  registrado con responsable y fecha.
- **Historial:** listado completo con filtros por tipo y rango de fechas.
- **Tablero:** indicadores de productos activos, stock bajo, movimientos y valor
  total del inventario.
- **Reportes:** resumen del inventario y exportación a CSV (Excel compatible).

## Arquitectura

Se separa el dominio (reglas de negocio), los datos (SQLite) y la presentación,
por funcionalidad:

```
lib/
  app/                 composición raíz, rutas y tema
  core/                constantes, base de datos, tema, utilidades y widgets
  features/
    categories/        categorías de productos
    products/          gestión de productos
    movements/         entradas, salidas, ajustes e historial
    scanner/           lectura de códigos con la cámara
    labels/            generación e impresión de etiquetas
    reports/           indicadores y exportación CSV
    home/              tablero y navegación principal
```

Reglas clave del dominio:

- El stock **solo** cambia mediante movimientos, nunca editando el producto.
- Un producto con movimientos se desactiva en lugar de eliminarse, para
  conservar el historial.
- El movimiento y la actualización de stock se guardan en una sola transacción.
- Las reglas se validan tanto en la capa de dominio como dentro de la
  transacción, para que no puedan eludirse.

## Estado y persistencia

- `provider` para el estado de productos, categorías, movimientos y tablero.
- `sqflite` para la base de datos local con llaves foráneas activadas.
- Al primer arranque se cargan datos de demostración: 3 categorías y 15
  productos con su entrada inicial.

## Requisitos

- Flutter 3.47 o superior
- Android SDK (compilación y ejecución en Android)
- Java 21

## Ejecución

```bash
flutter pub get
flutter run
```

## Pruebas

```bash
flutter analyze
flutter test
```

Las pruebas cubren las reglas de inventario (entradas, salidas, ajustes y
validaciones) y los repositorios sobre una base de datos en memoria, incluida
la atomicidad del stock y la conservación del historial al desactivar.

## Compilación

```bash
flutter build apk --debug
```

El APK se genera en `build/app/outputs/flutter-apk/`.
