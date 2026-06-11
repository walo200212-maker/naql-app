import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';

class StorageService {
  final _uuid = const Uuid();

  Future<String> _uploadToCloudinary(XFile file, String folder, String publicId) async {
    final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/${AppConstants.cloudinaryCloudName}/image/upload');

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = AppConstants.cloudinaryUploadPreset
      ..fields['folder'] = folder
      ..fields['public_id'] = publicId
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        await file.readAsBytes(),
        filename: '$publicId.jpg',
      ));

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode != 200) {
      String message = body;
      try {
        final data = jsonDecode(body) as Map<String, dynamic>;
        message = (data['error']?['message'] as String?) ?? body;
      } catch (_) {}
      throw Exception('فشل رفع الملف: $message');
    }

    final data = jsonDecode(body) as Map<String, dynamic>;
    return data['secure_url'] as String;
  }

  Future<String> uploadTruckPhoto(String driverId, XFile file) async {
    return _uploadToCloudinary(file, AppConstants.truckPhotosPath, driverId);
  }

  Future<List<String>> uploadJobPhotos(String jobId, List<XFile> files) async {
    final urls = <String>[];
    for (final file in files) {
      final id = _uuid.v4();
      urls.add(
          await _uploadToCloudinary(file, '${AppConstants.jobPhotosPath}/$jobId', id));
    }
    return urls;
  }

  Future<String> uploadDriverDoc(
      String driverId, String docType, XFile file) async {
    return _uploadToCloudinary(file, 'driver_docs/$driverId', docType);
  }

  Future<void> deleteFile(String url) async {
    // Deleting from Cloudinary requires a signed (server-side) request,
    // which can't be done safely from client code — no-op for now.
  }
}
