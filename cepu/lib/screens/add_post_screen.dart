import 'dart:convert';
import 'package:cepu/models/post.dart';
import 'package:cepu/services/post_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http; // Added 'as http'

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
  bool _isGettingAI = false; // Renamed for clarity

  List<String> get categories => [
        'Jalan Rusak',
        'Lampu Jalan Mati',
        'Lawan Arah',
        'Merokok di Jalan',
        'Tidak Pakai Helm',
      ];

  Future<void> pickImageAndConvert() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _base64Image = base64Encode(bytes);
      });
      // Automatically call AI after picking image
      _generateDescriptionWithAI();
    }
  }

  Future<void> _getLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 10));

      setState(() {
        _latitude = position.latitude.toString();
        _longitude = position.longitude.toString();
      });
    } catch (e) {
      debugPrint('Location Error: $e');
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  Future<void> _generateDescriptionWithAI() async {
    if (_base64Image == null) return;
    setState(() => _isGettingAI = true);

    try {
      const apiKey = 'YOUR_ACTUAL_API_KEY'; // Use your real key here
      const url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey';

      final body = jsonEncode({
        "contents": [
          {
            "parts": [
              {
                "inlineData": {"mimeType": "image/jpeg", "data": _base64Image},
              },
              {
                "text": "Berdasarkan foto ini, identifikasi satu kategori dari: ${categories.join(', ')}. "
                    "Format output: \nKategori: [nama]\nDeskripsi: [teks]",
              },
            ],
          },
        ],
      });

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String text = data['candidates'][0]['content']['parts'][0]['text'];
        
        // Simple parsing logic
        final lines = text.split('\n');
        for (var line in lines) {
          if (line.startsWith('Kategori:')) {
            String detectedCat = line.replaceFirst('Kategori:', '').trim();
            if (categories.contains(detectedCat)) {
              setState(() => _category = detectedCat);
            }
          } else if (line.startsWith('Deskripsi:')) {
            _descriptionController.text = line.replaceFirst('Deskripsi:', '').trim();
          }
        }
      }
    } catch (e) {
      debugPrint('AI Error: $e');
    } finally {
      if (mounted) setState(() => _isGettingAI = false);
    }
  }

  // ... (Keep your _showCategorySelect, _buildImagePreview, _buildLocationInfo, and _submitPost as they were)

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

// 4. Fungsi Widget tampil gambar
  Widget _buildImagePreview() {
    return Container(
      width: double.infinity,
      height: 220, // Sedikit lebih tinggi agar proporsional
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
      ),
      child: _base64Image == null
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image_search_rounded, 
                     size: 50, 
                     color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text(
                  'Belum ada foto terpilih',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            )
          : Stack(
              children: [
                // Gambar Utama
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.memory(
                    base64Decode(_base64Image!),
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                // Overlay Gradasi (opsional, agar tombol terlihat jelas)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircleAvatar(
                      backgroundColor: Colors.red.withOpacity(0.8),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            _base64Image = null;
                            _category = null; // Opsional: reset kategori jika gambar dihapus
                            _descriptionController.clear();
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
  Future<void> _submitPost() async {
    if(_base64Image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Silakan pilih gambar terlebih dahulu")),
      );
      return;
    }
    if(_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Silakan pilih lokasi terlebih dahulu")),
      );
      return;
    }
       if(_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Silakan pilih lokasi terlebih dahulu")),
      );
      return;
    }
    
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add new post")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildImagePreview(),
            if (_isGettingAI) const LinearProgressIndicator(), // Show AI loading
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _isSubmitting ? null : pickImageAndConvert,
              child: const Text('Pick Image'),
            ),
            const SizedBox(height: 16),
            // ... (Rest of your UI code)
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitPost,
              child: Text(_isSubmitting ? 'Submitting...' : 'Submit'),
            ),
          ],
        ),
      ),
    );
  }
}