import 'dart:convert';

import 'package:cepu/models/post.dart';
import 'package:cepu/services/post_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final TextEditingController _descriptionController = TextEditingController();

  String? _base64Image;
  String? _latitude;
  String? _longitude;
  String? _category;

  bool _isSubmitting = false;
  bool _isGettingLocation = false;

  List<String> get categories => [
        'Jalan Rusak',
        'Lampu Jalan Mati',
        'Lawan Arah',
        'Merokok di Jalan',
        'Tidak Pakai Helm',
      ];

  // ================= IMAGE =================
  Future<void> pickImageAndConvert() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _base64Image = base64Encode(bytes);
      });
    }
  }

  Future<void> _getLocation() async {
    setState(() => _isGettingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnack("Layanan lokasi dimatikan");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showSnack("Izin lokasi ditolak");
        return;
      }

      final position = await Geolocator.getCurrentPosition();

      setState(() {
        _latitude = position.latitude.toString();
        _longitude = position.longitude.toString();
      });
    } catch (e) {
      debugPrint("ERROR LOCATION: $e");
      _showSnack("Gagal ambil lokasi");
    } finally {
      if (mounted) {
        setState(() => _isGettingLocation = false);
      }
    }
  }

  Future<void> _submitPost() async {
    if (_base64Image == null) {
      _showSnack("Pilih gambar dulu");
      return;
    }

    if (_category == null) {
      _showSnack("Pilih kategori dulu");
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      _showSnack("Isi deskripsi dulu");
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // ambil lokasi kalau belum ada
      if (_latitude == null || _longitude == null) {
        await _getLocation();
      }

      final user = FirebaseAuth.instance.currentUser;

      print("MULAI SIMPAN KE FIRESTORE...");


      await PostService.addPost(
        Post(
          image: _base64Image,
          description: _descriptionController.text.trim(),
          category: _category,
          latitude: _latitude,
          longitude: _longitude,
          userId: user?.uid,
          userFullName: user?.displayName,
        ),
      );

      print("BERHASIL MASUK FIRESTORE");

      if (!mounted) return;

      _showSnack("Posting berhasil disimpan");

      Navigator.pop(context);
    } catch (e) {
      print("ERROR FIRESTORE: $e");

      if (!mounted) return;
      _showSnack("Gagal simpan: $e");
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  void _showCategorySelect() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return ListView(
          children: categories.map((cat) {
            return ListTile(
              title: Text(cat),
              onTap: () {
                setState(() => _category = cat);
                Navigator.pop(context);
              },
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildImagePreview() {
    if (_base64Image == null) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        color: Colors.grey.shade200,
        child: const Text("Belum ada gambar"),
      );
    }

    return Image.memory(
      base64Decode(_base64Image!),
      height: 180,
      fit: BoxFit.cover,
      width: double.infinity,
    );
  }

  Widget _buildLocationInfo() {
    if (_latitude == null || _longitude == null) {
      return const Text("Lokasi belum diambil");
    }

    return Text("Lat: $_latitude\nLng: $_longitude");
  }

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Post")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildImagePreview(),
            const SizedBox(height: 10),

            OutlinedButton(
              onPressed: _isSubmitting ? null : pickImageAndConvert,
              child: const Text("Pick Image"),
            ),

            const SizedBox(height: 10),

            OutlinedButton(
              onPressed: _isSubmitting ? null : _showCategorySelect,
              child: const Text("Select Category"),
            ),

            Text(_category ?? "Belum pilih kategori"),

            const SizedBox(height: 10),

            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: "Deskripsi",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            OutlinedButton(
              onPressed:
                  (_isSubmitting || _isGettingLocation) ? null : _getLocation,
              child: Text(
                _isGettingLocation
                    ? "Mengambil lokasi..."
                    : "Get Location",
              ),
            ),

            _buildLocationInfo(),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitPost,
              child: Text(
                _isSubmitting ? "Submitting..." : "Submit",
              ),
            ),
          ],
        ),
      ),
    );
  }
}