import 'dart:typed_data';

abstract class IImageStorageService {
  Future<Uint8List> downloadImage(
    String imageUrl, {
    int maxSize = 10 * 1024 * 1024,
  });
  
  Future uploadImage(String imageUrl, Uint8List image);
}
