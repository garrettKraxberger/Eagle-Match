import 'dart:io' as io; // avoid conflict with web
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:storage_client/storage_client.dart'; // Needed for FileOptions

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _cityController = TextEditingController();
  final _handicapController = TextEditingController();
  final _courseController = TextEditingController();

  final List<String> _states = [
    'Alabama', 'Alaska', 'Arizona', 'Arkansas', 'California', 'Colorado',
    'Connecticut', 'Delaware', 'Florida', 'Georgia', 'Hawaii', 'Idaho',
    'Illinois', 'Indiana', 'Iowa', 'Kansas', 'Kentucky', 'Louisiana',
    'Maine', 'Maryland', 'Massachusetts', 'Michigan', 'Minnesota',
    'Mississippi', 'Missouri', 'Montana', 'Nebraska', 'Nevada',
    'New Hampshire', 'New Jersey', 'New Mexico', 'New York',
    'North Carolina', 'North Dakota', 'Ohio', 'Oklahoma', 'Oregon',
    'Pennsylvania', 'Rhode Island', 'South Carolina', 'South Dakota',
    'Tennessee', 'Texas', 'Utah', 'Vermont', 'Virginia', 'Washington',
    'West Virginia', 'Wisconsin', 'Wyoming'
  ];

  String? _selectedState;
  io.File? _image;
  Uint8List? _imageBytes;
  String? _uploadedImageUrl;
  DateTime? _selectedBirthday;
  bool _loading = false;

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${p.basename(pickedFile.path)}';
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final filePath = 'public/$userId/$fileName';

    try {
      final storage = Supabase.instance.client.storage.from('profile_images');

      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        final res = await storage.uploadBinary(
          filePath,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
        print('Web upload response: $res');
        setState(() {
          _imageBytes = bytes;
          _uploadedImageUrl = storage.getPublicUrl(filePath);
        });
      } else {
        final file = io.File(pickedFile.path);
        final bytes = await file.readAsBytes();
        final res = await storage.uploadBinary(
          filePath,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
        print('Mobile upload response: $res');
        setState(() {
          _image = file;
          _uploadedImageUrl = storage.getPublicUrl(filePath);
        });
      }
    } catch (e) {
      print('Image upload failed: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Image upload failed.')));
    }
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not found. Please log in again.')),
      );
      return;
    }

    final data = {
      'id': userId,
      'first_name': _firstNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
      'birthday': _selectedBirthday?.toIso8601String(),
      'city': _cityController.text.trim(),
      'state': _selectedState,
      'handicap': double.tryParse(_handicapController.text.trim()),
      'home_course': _courseController.text.trim(),
      'profile_image_url': _uploadedImageUrl,
    };

    try {
      await Supabase.instance.client
          .from('users')
          .upsert(data)
          .select()
          .single();
      Navigator.pushReplacementNamed(context, '/home');
    } catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Profile save failed: $error')));
    }

    setState(() => _loading = false);
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _selectedBirthday = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatar = (kIsWeb && _imageBytes != null)
        ? CircleAvatar(radius: 40, backgroundImage: MemoryImage(_imageBytes!))
        : (!kIsWeb && _image != null)
            ? CircleAvatar(radius: 40, backgroundImage: FileImage(_image!))
            : const CircleAvatar(radius: 40, child: Icon(Icons.person));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Up Profile'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Center(
                child: Column(
                  children: [
                    avatar,
                    TextButton(
                      onPressed: _pickAndUploadImage,
                      child: const Text('Upload Profile Image'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'First Name'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter your first name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Last Name'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter your last name' : null,
              ),
              ListTile(
                title: Text(
                  _selectedBirthday == null
                      ? 'Select Birthday'
                      : 'Birthday: ${_selectedBirthday!.month}/${_selectedBirthday!.day}/${_selectedBirthday!.year}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickBirthday,
              ),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'City'),
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'State'),
                value: _selectedState,
                items: _states.map((String state) {
                  return DropdownMenuItem<String>(
                    value: state,
                    child: Text(state),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedState = value;
                  });
                },
                validator: (value) =>
                    value == null || value.isEmpty ? 'Please select a state' : null,
              ),
              TextFormField(
                controller: _handicapController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Handicap (GHIN or manual)',
                ),
              ),
              TextFormField(
                controller: _courseController,
                decoration: const InputDecoration(labelText: 'Home Course'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _submitProfile,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save & Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}