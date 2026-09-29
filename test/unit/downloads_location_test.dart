import 'package:edusistem_front/core/utils/downloads_io.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('describeSavedLocation', () {
    test('primary storage document becomes "Almacenamiento interno"', () {
      final saved = describeSavedLocation(
        Uri.parse('/document/primary:Download/Notas%201.xlsx'),
        fallbackName: 'notas.xlsx',
      );
      expect(saved.fileName, 'Notas 1.xlsx');
      expect(saved.folder, 'Almacenamiento interno/Download');
      expect(
        saved.message,
        '«Notas 1.xlsx» guardado en Almacenamiento interno/Download.',
      );
    });

    test('raw path under emulated storage is made readable', () {
      final saved = describeSavedLocation(
        Uri.parse('/document/raw:/storage/emulated/0/Documents/a.pdf'),
        fallbackName: 'x.pdf',
      );
      expect(saved.fileName, 'a.pdf');
      expect(saved.folder, 'Almacenamiento interno/Documents');
    });

    test('opaque provider ids keep the requested name, no folder', () {
      final saved = describeSavedLocation(
        Uri.parse('/document/msf:1234'),
        fallbackName: 'plantilla.xlsx',
      );
      expect(saved.fileName, 'plantilla.xlsx');
      expect(saved.folder, isNull);
      expect(saved.message, contains('ubicación que elegiste'));
    });

    test('desktop file path is used as is', () {
      final saved = describeSavedLocation(
        Uri.file('/home/ana/Escritorio/reporte.xlsx'),
        fallbackName: 'reporte.xlsx',
      );
      expect(saved.folder, '/home/ana/Escritorio');
    });
  });
}
