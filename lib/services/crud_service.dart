import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:image_picker/image_picker.dart';
import 'cloudinary_service.dart';

class CrudService {
  final CollectionReference items = FirebaseFirestore.instance.collection('items');

  final CloudinaryPublic _cloudinary = CloudinaryPublic(
    'yhlm9yv6',
    'serviko_uploads',
    cache: false,
  );

  final ImagePicker _picker = ImagePicker();

  // PICK + UPLOAD IMAGE
  Future<PickedImage?> pickImageForAddItem() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return null;

    final file = File(pickedFile.path);

    final response = await _cloudinary.uploadFile(
      CloudinaryFile.fromFile(
        file.path,
        resourceType: CloudinaryResourceType.Image,
      ),
    );

    return PickedImage(file: file, url: response.secureUrl);
  }

  // CREATE
  Future<void> addItems(String name, int quantity, {String? imageUrl}) {
    return items.add({
      'name': name,
      'quantity': quantity,
      'isFavorite': false,
      'image_url': imageUrl,
      'createdAt': Timestamp.now(),
    });
  }

  // READ
  Stream<QuerySnapshot> getItems() {
    return items.orderBy('createdAt', descending: true).snapshots();
  }

  // UPDATE
  Future<void> updateItems(
    String id,
    String name,
    int quantity, {
    String? imageUrl,
  }) {
    final data = <String, dynamic>{'name': name, 'quantity': quantity};
    if (imageUrl != null) data['image_url'] = imageUrl;
    return items.doc(id).update(data);
  }

  // ADD / REMOVE FAVORITE
  Future<void> updateFavorite(String id, bool isFavorite) {
    return items.doc(id).update({'isFavorite': isFavorite});
  }

  // GET FAVORITES
  Stream<QuerySnapshot> getFavoriteItems() {
    return items
        .where('isFavorite', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // DELETE
  Future<void> deleteItems(String id) {
    return items.doc(id).delete();
  }
}
