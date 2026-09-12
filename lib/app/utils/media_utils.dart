import 'package:image_picker/image_picker.dart';

class MediaUtils {
  static Future<XFile?> pickImage() async {
    final picker = ImagePicker();
    return await picker.pickImage(source: ImageSource.gallery);
  }

  static Future<XFile?> pickVideo() async {
    final picker = ImagePicker();
    return await picker.pickVideo(source: ImageSource.gallery);
  }
}