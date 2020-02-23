import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:owl/general/services/IImageStorageService.dart';

class FirebaseStorageService implements IImageStorageService {
  final FirebaseStorage _firebaseStorage = FirebaseStorage(
    storageBucket: 'gs://owl-client-8ddda.appspot.com/',
  );

  @override
  Future<Uint8List> downloadImage(
    String imageUrl, {
    int maxSize = 10 * 1024 * 1024,
  }) async {
    Uint8List image;
    try {
      image = await _firebaseStorage.ref().child(imageUrl).getData(maxSize);
    } catch (e) {
      print(e);
    }

    return image;
  }

  @override
  Future uploadImage(String imageUrl, Uint8List image) async {
    await _firebaseStorage.ref().child(imageUrl).putData(image).onComplete;
  }
}
