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

  // Test Supabase connection
  Future<void> _testSupabaseConnection() async {
    try {
      print('Testing Supabase connection...');
      
      // Test auth
      final user = Supabase.instance.client.auth.currentUser;
      print('Current user: ${user?.id}');
      
      // Test storage access
      final buckets = await Supabase.instance.client.storage.listBuckets();
      print('Available buckets: ${buckets.map((b) => b.name).toList()}');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Supabase connection OK. User: ${user?.id}')),
      );
    } catch (e) {
      print('Supabase connection test failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Supabase connection failed: $e')),
      );
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated')),
      );
      return;
    }

    print('Starting image upload for user: $userId');
    
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Uploading image...')),
    );

    try {
      // Use a simpler file path structure
      final ext = p.extension(pickedFile.path);
      final fileName = '$userId$ext';
      final filePath = fileName; // Just use the filename without subdirectory
      
      print('File path: $filePath');
      print('File extension: $ext');

      final storage = Supabase.instance.client.storage.from('avatars');
      final bytes = await pickedFile.readAsBytes();
      
      print('File size: ${bytes.length} bytes');
      
      // Upload the image
      final uploadResult = await storage.uploadBinary(
        filePath,
        bytes,
        fileOptions: const FileOptions(
          upsert: true,
          contentType: 'image/jpeg', // Explicitly set content type
        ),
      );

      print('Upload result: $uploadResult');

      // Get public URL
      final publicUrl = storage.getPublicUrl(filePath);
      print('Public URL: $publicUrl');
      
      setState(() {
        if (kIsWeb) {
          _imageBytes = bytes;
        } else {
          _image = io.File(pickedFile.path);
        }
        _uploadedImageUrl = publicUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile image uploaded successfully!')),
      );
    } catch (e) {
      print('Image upload failed: $e');
      print('Error type: ${e.runtimeType}');
      
      // More specific error handling
      String errorMessage = 'Image upload failed';
      if (e.toString().contains('not found')) {
        errorMessage = 'Storage bucket not found. Please check Supabase configuration.';
      } else if (e.toString().contains('permission')) {
        errorMessage = 'Permission denied. Please check storage policies.';
      } else if (e.toString().contains('size')) {
        errorMessage = 'File too large. Please choose a smaller image.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
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
      Navigator.pushReplacementNamed(context, '/dash');
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
                    GestureDetector(
                      onTap: _pickAndUploadImage,
                      child: Stack(
                        children: [
                          (kIsWeb && _imageBytes != null)
                              ? CircleAvatar(
                                  radius: 50,
                                  backgroundImage: MemoryImage(_imageBytes!)
                                )
                              : (!kIsWeb && _image != null)
                                  ? CircleAvatar(
                                      radius: 50,
                                      backgroundImage: FileImage(_image!)
                                    )
                                  : const CircleAvatar(
                                      radius: 50,
                                      child: Icon(Icons.person, size: 40)
                                    ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap to add profile photo',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Debug button - remove this in production
              ElevatedButton(
                onPressed: _testSupabaseConnection,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('Test Supabase Connection'),
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