import 'dart:io';

class AppFile {
  final String name;
  final String fileName;
  final String fileType;
  final String mimeType;
  final String? path;
  final String? url;

  AppFile.fromPath({required this.path, required this.fileName})
      : name = fileName.contains('.')
      ? fileName.substring(0, fileName.lastIndexOf('.'))
      : fileName,
        fileType = fileName.contains('.') ? fileName.split('.').last : '',
        mimeType = extensionToMime(
            fileName.contains('.') ? fileName.split('.').last : ''),
        url = null;

  AppFile.fromUrl({required this.url, required this.fileName})
      : name = fileName.contains('.')
      ? fileName.substring(0, fileName.lastIndexOf('.'))
      : fileName,
        fileType = fileName.contains('.') ? fileName.split('.').last : '',
        mimeType = extensionToMime(
            fileName.contains('.') ? fileName.split('.').last : ''),
        path = null;

  bool get isImage => mimeType.startsWith('image/');
  bool get isPdf => mimeType == 'application/pdf';
  bool get canView => isImage || isPdf;
  File? get file => path != null ? File(path!) : null;

  static String extensionToMime(String ext) {
    switch (ext.toLowerCase()) {
      case 'png': return 'image/png';
      case 'jpg':
      case 'jpeg': return 'image/jpeg';
      case 'gif': return 'image/gif';
      case 'webp': return 'image/webp';
      case 'pdf': return 'application/pdf';
      case 'txt': return 'text/plain';
      default: return 'application/octet-stream';
    }
  }

  @override
  bool operator ==(Object other) =>
      other is AppFile && other.path == path && other.url == url;

  @override
  int get hashCode => (path ?? url).hashCode;
}