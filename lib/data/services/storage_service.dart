import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  Future<String> uploadTruckPhoto(String driverId, XFile file) async {
    final ref = _storage
        .ref()
        .child(AppConstants.truckPhotosPath)
        .child('$driverId.jpg');
    final task = await ref.putData(await file.readAsBytes());
    return await task.ref.getDownloadURL();
  }

  Future<List<String>> uploadJobPhotos(String jobId, List<XFile> files) async {
    final urls = <String>[];
    for (final file in files) {
      final id = _uuid.v4();
      final ref = _storage
          .ref()
          .child(AppConstants.jobPhotosPath)
          .child(jobId)
          .child('$id.jpg');
      final task = await ref.putData(await file.readAsBytes());
      urls.add(await task.ref.getDownloadURL());
    }
    return urls;
  }

  Future<String> uploadDriverDoc(
      String driverId, String docType, XFile file) async {
    final ref = _storage
        .ref()
        .child('driver_docs')
        .child(driverId)
        .child('$docType.jpg');
    final task = await ref.putData(await file.readAsBytes());
    return await task.ref.getDownloadURL();
  }

  Future<void> deleteFile(String url) async {
    try {
      await _storage.refFromURL(url).delete();
    } catch (_) {}
  }
}
