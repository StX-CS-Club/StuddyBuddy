import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import 'app_file.dart';

enum PickSource { camera, library, files }

Future<AppFile?> pickFile(PickSource source) async {
  switch (source) {
    case PickSource.camera:
      final XFile? image =
          await ImagePicker().pickImage(source: ImageSource.camera);
      if (image == null) return null;
      return AppFile.fromPath(path: image.path, fileName: image.name);

    case PickSource.library:
      final XFile? image =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image == null) return null;
      return AppFile.fromPath(path: image.path, fileName: image.name);

    case PickSource.files:
      final FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      );
      if (result == null) return null;
      final PlatformFile file = result.files.single;
      return AppFile.fromPath(
        path: file.path!,
        fileName: file.name,
      );
  }
}
