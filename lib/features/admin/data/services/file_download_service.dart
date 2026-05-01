import 'file_download_service_stub.dart'
    if (dart.library.html) 'file_download_service_web.dart' as impl;

Future<void> downloadBytes({
  required List<int> bytes,
  required String fileName,
  required String mimeType,
}) {
  return impl.downloadBytes(
    bytes: bytes,
    fileName: fileName,
    mimeType: mimeType,
  );
}
