import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

enum PickSource { camera, library, files }

class FilePick {
  final String path;
  final String name;
  final String mimeType;

  FilePick({required this.path, required this.name, required this.mimeType});
}

Future<FilePick?> pickFile(PickSource source) async {
  switch (source) {
    case PickSource.camera:
      final XFile? image = await ImagePicker().pickImage(source: ImageSource.camera);
      if (image == null) return null;
      return FilePick(path: image.path, name: image.name, mimeType: 'image/jpeg');

    case PickSource.library:
      final XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image == null) return null;
      return FilePick(path: image.path, name: image.name, mimeType: 'image/jpeg');

    case PickSource.files:
      final FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      );
      if (result == null) return null;
      final PlatformFile file = result.files.single;
      return FilePick(
        path: file.path!,
        name: file.name,
        mimeType: file.extension == 'pdf' ? 'application/pdf' : 'image/${file.extension}',
      );
  }
}