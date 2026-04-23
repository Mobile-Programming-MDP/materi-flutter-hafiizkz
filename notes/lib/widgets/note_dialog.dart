import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:notes/models/note.dart';
import 'package:notes/services/note_service.dart';

class NoteDialog extends StatefulWidget {
  final Note? note;
  const NoteDialog({super.key, this.note});
  @override
  State<NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<NoteDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  File? _imageFile;
  String? _base64Image;

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _descriptionController.text = widget.note!.title;
      _base64Image = widget.note!.imageBase64;
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      String base64String = base64Encode(bytes);
      setState(() {
        _base64Image = base64String;
        _imageFile = File(pickedFile.path);
      });
      print("Base64 String: $base64String");
    } else {
      print("No image selected.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.note == null ? 'Add Notes' : 'Update Notes'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Title: ', textAlign: TextAlign.start),
          TextField(controller: _titleController),
          const Padding(
            padding: EdgeInsets.only(top: 20),
            child: Text('Description: '),
          ),
          TextField(controller: _descriptionController),
          const Padding(
            padding: EdgeInsets.only(top: 20),
            child: Text('Image: '),
          ),
          Expanded(
            child: _base64Image != null
                ? Image.memory(
                    base64Decode(_base64Image!),
                    width: 250,
                    height: 250,
                    fit: BoxFit.cover,
                  )
                : Center(
                    child: Icon(
                      Icons.add_a_photo,
                      size: 50,
                      color: Colors.grey,
                    ),
                  ),
          ),
          TextButton(onPressed: _pickImage, child: const Text('Pick Image')),
          TextButton(
            onPressed: () {},
            child: const Text('Get Current Location'),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            if (widget.note == null) {
              NoteService.addNote(
                Note(
                  title: _titleController.text,
                  description: _descriptionController.text,
                  imageBase64: _base64Image,
                ),
              ).whenComplete(() {
                Navigator.of(context).pop();
              });
            } else {
              NoteService.updateNote(
                Note(
                  id: widget.note!.id,
                  title: _titleController.text,
                  description: _descriptionController.text,
                  createdAt: widget.note!.createdAt,
                  imageBase64: _base64Image,
                ),
              ).whenComplete(() => Navigator.of(context).pop());
            }
          },
          child: Text(widget.note == null ? 'Add' : 'Update'),
        ),
      ],
    );
  }
}