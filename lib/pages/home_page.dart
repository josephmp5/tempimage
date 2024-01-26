import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fleetingframes/pages/sign_up.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:scroll_snap_list/scroll_snap_list.dart';
import 'package:uuid/uuid.dart';

class HomePage extends StatefulWidget {
  final String userId;

  const HomePage({super.key, required this.userId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ImagePicker _picker = ImagePicker();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  bool progressIndicator = true;

  late StreamController<List<String>> photoStreamController;

  @override
  void initState() {
    super.initState();
    photoStreamController = StreamController<List<String>>();
    refreshPhotos();
  }

  @override
  void dispose() {
    photoStreamController.close();
    super.dispose();
  }

  void _updateProgressIndicator(bool show) {
    if (mounted) {
      setState(() {
        progressIndicator = show;
      });
    }
  }

  Future<void> refreshPhotos() async {
    _updateProgressIndicator(true);
    String? uid = _auth.currentUser?.uid;
    if (uid != null) {
      List<String> photos = await getUserPhotos(uid);
      photoStreamController.add(photos);
    }
    _updateProgressIndicator(false);
  }

  Future<void> pickCamera() async {
    _updateProgressIndicator(true);
    String? uid = _auth.currentUser?.uid;
    if (uid == null) {
      _updateProgressIndicator(false);
      return;
    }

    final bool canUpload = await canUserUpload(uid);
    if (!canUpload) {
      // Show a message or handle the limit being reached
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Upload Limit Reached"),
          content: Text("You can only upload 5 images per day."),
          actions: [
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
                _updateProgressIndicator(false);
              },
            ),
          ],
        ),
      );
      _updateProgressIndicator(false);
      return;
    }
    _updateProgressIndicator(true);
    final XFile? image =
        await _picker.pickImage(source: ImageSource.camera, imageQuality: 50);
    if (image == null) return;

    File file = File(image.path);
    String fileName = Uuid().v4() + '.jpg';
    Reference ref = _storage.ref().child('user_images/$uid/$fileName');

    UploadTask uploadTask = ref.putFile(file);
    await uploadTask.whenComplete(() async {
      final urlDownload = await ref.getDownloadURL();
      final uploadTime = Timestamp.now();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('photos')
          .add({
        'url': urlDownload,
        'uploaded': uploadTime,
        'fileName': fileName,
      });

      refreshPhotos();
    }).catchError((error) {
      // Handle any errors that occur during upload
      print("Error uploading file: $error");
    }).whenComplete(() {
      _updateProgressIndicator(
          false); // Ensure loader is hidden after upload completes or fails
    });
  }

  Future<bool> canUserUpload(String uid) async {
    final oneDayAgo =
        Timestamp.now().toDate().subtract(const Duration(days: 1));
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('photos')
        .where('uploaded', isGreaterThan: oneDayAgo)
        .get();

    return querySnapshot.docs.length < 5;
  }

  Future<List<String>> getUserPhotos(String uid) async {
    List<String> photoUrls = [];
    var photosSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('photos')
        .get();
    for (var photo in photosSnapshot.docs) {
      photoUrls.add(photo.data()['url'] as String);
    }
    return photoUrls;
  }

  Stream<List<String>> photoStream(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('photos')
        .snapshots()
        .transform(
      StreamTransformer.fromHandlers(
        handleData: (snapshot, sink) async {
          List<String> photoUrls = [];
          for (var doc in snapshot.docs) {
            photoUrls.add(doc.data()['url'] as String);
          }
          sink.add(photoUrls);
        },
      ),
    );
  }

  Future<void> deleteFirestoreData(String userId) async {
    // Check if the storage reference exists and then delete it
    var storageRef =
        FirebaseStorage.instance.ref().child('user_images/$userId');

    try {
      // List all files in the directory
      ListResult result = await storageRef.listAll();
      List<Reference> files = result.items;

      // Delete each file
      for (var file in files) {
        await file.delete();
      }
      print('All files deleted successfully');
    } catch (e) {
      print('Error occurred while deleting files: $e');
    }
    var userDocRef = FirebaseFirestore.instance.collection('users').doc(userId);

    // Check if the photos subcollection exists and has documents
    var photosCollection = userDocRef.collection('photos');
    var photosSnapshot = await photosCollection.get();

    if (photosSnapshot.docs.isNotEmpty) {
      // If the photos subcollection exists and has documents, delete them
      for (var doc in photosSnapshot.docs) {
        await doc.reference.delete();
      }
    }

    // Finally, delete the user's document
    await userDocRef.delete();
  }

  Future<void> _deleteAccount(BuildContext context) async {
    // Kullanıcıya bir onay mesajı göster
    bool confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
          style: TextStyle(
            fontSize: MediaQuery.of(context).size.width > 600 ? 24.0 : 20.0,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    // Kullanıcı onay verirse hesabı sil
    if (confirmDelete == true) {
      try {
        // Firestore verilerini sil
        await deleteFirestoreData(_auth.currentUser!.uid);

        // Kullanıcı hesabını sil
        await _auth.currentUser!.delete();

        // Hesap silme işlemi başarılı olduysa SignUpScreen sayfasına yönlendir
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SignUp()),
        );
      } on FirebaseAuthException catch (e) {
        print('An error occured while deleting: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4169E1),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
          title: Text(
            'Temp Image',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: MediaQuery.of(context).size.width > 600 ? 24.0 : 16.0,
            ),
          ),
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              _deleteAccount(context);
            },
          )),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF00BFFF),
              Color(0xFF1E90FF),
              Color(0xFF00008B),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(children: [
            const SizedBox(
              height: 15,
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Center(
                child: Text(
                    "Snap Temporarily, Save Space Permanently – Smart Photo Storage.",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w300,
                      fontSize:
                          MediaQuery.of(context).size.width > 600 ? 24.0 : 16.0,
                    )),
              ),
            ),
            const SizedBox(height: 15),
            progressIndicator
                ? const CircularProgressIndicator()
                : Expanded(
                    child: StreamBuilder<List<String>>(
                    stream: photoStream(widget.userId),
                    builder: (context, snapshot) {
                      // When the connection is waiting, show the loading indicator

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      // Handle any potential errors
                      if (snapshot.hasError) {
                        return const Center(
                            child: Text('Error loading photos'));
                      }

                      // If there's data, display it
                      if (snapshot.hasData &&
                          snapshot.data != null &&
                          snapshot.data!.isNotEmpty) {
                        // There are images
                        return _buildPhotoList(snapshot.data!);
                      } else {
                        // No images available
                        return Center(
                            child: Text(
                          'No photos available',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: MediaQuery.of(context).size.width > 600
                                ? 24.0
                                : 16.0,
                          ),
                        ));
                      }
                    },
                  )),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Card(
                color: const Color(0xFF483D8B),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "Click icon to upload your temporary photo.",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w400,
                      fontSize:
                          MediaQuery.of(context).size.width > 600 ? 24.0 : 16.0,
                    ),
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: pickCamera,
                  child: const Icon(Icons.camera_alt),
                ),
              ],
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildPhotoList(List<String> photos) {
    return ScrollSnapList(
      onItemFocus: (item) {},
      itemSize: 370,
      itemBuilder: (context, index) {
        return Container(
          height: 450,
          width: 350,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          child: InteractiveViewer(
            panEnabled: false,
            boundaryMargin: const EdgeInsets.all(80),
            maxScale: 4,
            minScale: 0.5,
            child: CachedNetworkImage(
              imageUrl: photos[index],
              placeholder: (context, url) => const Center(
                  child:
                      CircularProgressIndicator()), // Loading indicator while preloading
              errorWidget: (context, url, error) => const Icon(
                  Icons.error), // Error widget if image fails to load
            ),
          ),
        );
      },
      itemCount: photos.length,
      dynamicItemSize: true,
      scrollDirection: Axis.horizontal,
    );
  }
}
