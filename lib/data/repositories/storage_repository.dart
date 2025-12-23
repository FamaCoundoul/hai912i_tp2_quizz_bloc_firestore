// ========================================
// storage_repository.dart
// Repository pour Firebase Storage
// ========================================

import 'dart:typed_data'; //
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageRepository {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  // ==========================================
  // AVATARS
  // ==========================================

  Future<String?> uploadAvatar(String userId, XFile imageFile) async {
    try {
      print('📤 Upload avatar pour $userId...');

      String fileName = 'avatar_$userId.jpg';
      Reference ref = _storage.ref().child('avatars').child(fileName);

      SettableMetadata metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'userId': userId},
      );

      // ✅ TOUJOURS utiliser putData() sur Web ET Mobile
      Uint8List bytes = await imageFile.readAsBytes();
      UploadTask uploadTask = ref.putData(bytes, metadata);

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      print('✅ Avatar uploadé: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ Erreur upload avatar: $e');
      print('Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  // ✅ RETOURNE XFile (pas File)
  Future<XFile?> pickImageFromGallery() async {
    try {
      print('🖼️ Sélection image...');

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image != null) {
        print('✅ Image sélectionnée: ${image.path}');
        return image; // ✅ Retourner XFile directement
      }
    } catch (e) {
      print('❌ Erreur sélection image: $e');
    }
    return null;
  }

  // ✅ RETOURNE XFile (pas File)
  Future<XFile?> takePhotoWithCamera() async {
    try {
      print('📸 Capture photo...');

      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (photo != null) {
        print('✅ Photo capturée: ${photo.path}');
        return photo; // ✅ Retourner XFile directement
      }
    } catch (e) {
      print('❌ Erreur capture photo: $e');
    }
    return null;
  }

  Future<bool> deleteAvatar(String userId) async {
    try {
      print('🗑️ Suppression avatar...');

      String fileName = 'avatar_$userId.jpg';
      Reference ref = _storage.ref().child('avatars').child(fileName);

      await ref.delete();
      print('✅ Avatar supprimé');
      return true;
    } catch (e) {
      print('❌ Erreur suppression: $e');
      return false;
    }
  }

  // ==========================================
  // SONS (Pour Question 4)
  // ==========================================

  Future<String?> uploadSoundFromBytes(String fileName, Uint8List bytes) async {
    try {
      print('📤 Upload son: $fileName...');

      Reference ref = _storage.ref().child('sounds').child(fileName);

      SettableMetadata metadata = SettableMetadata(
        contentType: 'audio/mpeg',
      );

      UploadTask uploadTask = ref.putData(bytes, metadata);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      print('✅ Son uploadé: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ Erreur upload son: $e');
      return null;
    }
  }

  Future<String?> getSoundUrl(String fileName) async {
    try {
      Reference ref = _storage.ref().child('sounds').child(fileName);
      String downloadUrl = await ref.getDownloadURL();

      print('✅ URL son récupérée: $fileName');
      return downloadUrl;
    } catch (e) {
      print('❌ Son non trouvé: $fileName');
      return null;
    }
  }
}