class SupabaseFile {
  final String url;
  final String fileName;
  final String name;
  final String fileType;
  final String mimeType;

  SupabaseFile({required this.url, required this.fileName})
      : name = fileName.split('.').first,
        fileType = fileName.split('.').last,
        mimeType = extensionToMime(fileName.split('.').last);

  static String extensionToMime(String ext) {
    switch (ext.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }

  @override
  bool operator ==(Object other) => other is SupabaseFile && other.url == url;

  @override
  int get hashCode => url.hashCode;
}
