import 'dart:io';

// ============================================================
// MÁSCARAS DE ATRIBUTOS (BITMASK CONSTANTS)
// ============================================================
const int incluirArchivos = 1 << 0;     // 0001 = 1
const int incluirCarpetas = 1 << 1;     // 0010 = 2
const int calcularTamano = 1 << 2;      // 0100 = 4
const int calcularProfundidad = 1 << 3; // 1000 = 8

// ============================================================
// CLASE CONTENEDORA DE MÉTRICAS
// ============================================================
class DirectoryMetrics {
  int files = 0;
  int folders = 0;
  int totalBytes = 0;
  int maxDepth = 0;

  void reset() {
    files = 0;
    folders = 0;
    totalBytes = 0;
    maxDepth = 0;
  }

  @override
  String toString() {
    return 'Archivos: $files | Carpetas: $folders | Tamaño: $totalBytes bytes | Profundidad Máx: $maxDepth';
  }
}

// ============================================================
// FUNCIÓN RECURSIVA DE ANÁLISIS
// ============================================================
void analizarDirectorio(
  Directory directorio,
  DirectoryMetrics metricas, {
  int profundidad = 0,
  int maxProfundidad = 3,
  List<String>? extensiones,
  int mascara = incluirArchivos | incluirCarpetas | calcularTamano | calcularProfundidad,
}) {
  // Guarda de profundidad
  if (profundidad > maxProfundidad) {
    return;
  }

  // Actualizar profundidad máxima alcanzada
  if ((mascara & calcularProfundidad) != 0) {
    if (profundidad > metricas.maxDepth) {
      metricas.maxDepth = profundidad;
    }
  }

  try {
    // Evitar seguir enlaces simbólicos para prevenir bucles de recursión infinitos
    List<FileSystemEntity> elementos = directorio.listSync(followLinks: false);

    for (var elemento in elementos) {
      if (elemento is File) {
        if ((mascara & incluirArchivos) != 0) {
          String fileName = elemento.path.split(Platform.pathSeparator).last;
          String extension = '';

          if (fileName.contains('.') && !fileName.startsWith('.')) {
            extension = fileName.split('.').last.toLowerCase();
          }

          bool extensionValida = extensiones == null ||
              (extension.isNotEmpty && extensiones.map((e) => e.toLowerCase()).contains(extension));

          if (extensionValida) {
            metricas.files++;

            if ((mascara & calcularTamano) != 0) {
              metricas.totalBytes += elemento.lengthSync();
            }
          }
        }
      } else if (elemento is Directory) {
        // Contabilizar carpeta si la máscara lo permite
        if ((mascara & incluirCarpetas) != 0) {
          metricas.folders++;
        }

        // Desacoplado: La recursión se ejecuta independientemente de si se contabilizan o no las carpetas
        analizarDirectorio(
          elemento,
          metricas,
          profundidad: profundidad + 1,
          maxProfundidad: maxProfundidad,
          extensiones: extensiones,
          mascara: mascara,
        );
      }
    }
  } catch (e) {
    // Manejo de excepciones de permisos o rutas inaccesibles
  }
}

// ============================================================
// ARNÉS DE PRUEBAS DE VERIFICACIÓN (VERIFICATION TEST HARNESS)
// ============================================================
void ejecutarArnesDePruebas() {
  print("\n====================================");
  print("   EJECUTANDO HARNESS DE PRUEBAS");
  print("====================================\n");

  Directory tempDir = Directory.systemTemp.createTempSync('dart_tree_test_');

  try {
    // Creación de estructura de prueba
    Directory subDir1 = Directory('${tempDir.path}/sub1')..createSync();
    Directory subDir2 = Directory('${tempDir.path}/sub1/sub2')..createSync();

    File('${tempDir.path}/file1.txt').writeAsStringSync('Hello World'); // 11 bytes
    File('${tempDir.path}/sub1/file2.dart').writeAsStringSync('void main(){}'); // 13 bytes
    File('${tempDir.path}/sub1/sub2/file3.txt').writeAsStringSync('Deep file'); // 9 bytes

    DirectoryMetrics metricas = DirectoryMetrics();

    // Caso 1: Análisis Completo (Sin límite de extensión)
    analizarDirectorio(
      tempDir,
      metricas,
      maxProfundidad: 5,
      extensiones: null,
      mascara: incluirArchivos | incluirCarpetas | calcularTamano | calcularProfundidad,
    );

    print('Prueba 1 (Análisis Completo):');
    print('  Esperado -> Archivos: 3 | Carpetas: 2 | Tamaño: 33 bytes | Profundidad: 2');
    print('  Obtenido -> ${metricas.toString()}');
    assert(metricas.files == 3 && metricas.folders == 2 && metricas.totalBytes == 33 && metricas.maxDepth == 2);

    // Caso 2: Filtro por extensión (.txt únicamente)
    metricas.reset();
    analizarDirectorio(
      tempDir,
      metricas,
      maxProfundidad: 5,
      extensiones: ['txt'],
      mascara: incluirArchivos | incluirCarpetas | calcularTamano | calcularProfundidad,
    );

    print('\nPrueba 2 (Filtro .txt):');
    print('  Esperado -> Archivos: 2 | Carpetas: 2 | Tamaño: 20 bytes | Profundidad: 2');
    print('  Obtenido -> ${metricas.toString()}');
    assert(metricas.files == 2 && metricas.totalBytes == 20);

    // Caso 3: Límite de Profundidad (maxProfundidad = 1)
    metricas.reset();
    analizarDirectorio(
      tempDir,
      metricas,
      maxProfundidad: 1,
      extensiones: null,
      mascara: incluirArchivos | incluirCarpetas | calcularTamano | calcularProfundidad,
    );

    print('\nPrueba 3 (Límite Profundidad = 1):');
    print('  Esperado -> Archivos: 2 | Carpetas: 2 | Profundidad: 1');
    print('  Obtenido -> ${metricas.toString()}');
    assert(metricas.files == 2 && metricas.maxDepth == 1);

    print('\n[SUCCESS] Todas las pruebas del Harness pasaron correctamente.\n');
  } finally {
    tempDir.deleteSync(recursive: true);
  }
}

void main() {
  ejecutarArnesDePruebas();
}