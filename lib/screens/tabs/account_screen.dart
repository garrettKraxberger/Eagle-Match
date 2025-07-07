import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  Map<String, dynamic>? _userData;
  bool _loading = true;

  Future<void> _loadUserData() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final response = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      // Clear any cached network images to ensure fresh image loads
      if (response['profile_image_url'] != null) {
        NetworkImage(response['profile_image_url']).evict();
      }

      setState(() {
        _userData = response;
        _loading = false;
      });
    } catch (e) {
      print('Error loading user data: $e');
      setState(() => _loading = false);
    }
  }

  void _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(userData: _userData!),
      ),
    );
    
    // Reload user data when returning from edit screen
    if (result == true) {
      await _loadUserData();
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_userData == null) {
      return const Scaffold(body: Center(child: Text('No user data found.')));
    }

    final age = _userData!["birthday"] != null
        ? DateTime.now().year - DateTime.parse(_userData!["birthday"]).year
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Account'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _navigateToEditProfile,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: _userData!["profile_image_url"] != null
                        ? NetworkImage(_userData!["profile_image_url"])
                        : null,
                    child: _userData!["profile_image_url"] == null
                        ? const Icon(Icons.person, size: 40)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${_userData!["first_name"] ?? ''} ${_userData!["last_name"] ?? ''}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (age != null)
                    Text(
                      '$age years old',
                      style: const TextStyle(fontSize: 16),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    '${_userData!["city"] ?? 'Unknown'}, ${_userData!["state"] ?? ''}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              title: const Text('Handicap'),
              subtitle: Text(_userData!["handicap"]?.toString() ?? 'Not set'),
            ),
            ListTile(
              title: const Text('Home Course'),
              subtitle: Text(_userData!["home_course"] ?? 'Not set'),
            ),
            if (_userData!["bio"] != null &&
                _userData!["bio"].toString().isNotEmpty)
              ListTile(
                title: const Text('Bio'),
                subtitle: Text(_userData!["bio"]),
              ),
          ],
        ),
      ),
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const EditProfileScreen({super.key, required this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _homeCourseController;
  late TextEditingController _bioController;
  XFile? _selectedImage;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _homeCourseController = TextEditingController(
      text: widget.userData['home_course'] ?? '',
    );
    _bioController = TextEditingController(text: widget.userData['bio'] ?? '');
  }

  Future<File?> _cropImage(XFile pickedFile) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: Colors.black,
          toolbarWidgetColor: Colors.white,
          lockAspectRatio: false,
        ),
        IOSUiSettings(title: 'Crop Image'),
        WebUiSettings(
          context: context,
        ),
      ],
    );
    return croppedFile != null ? File(croppedFile.path) : null;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    
    if (picked != null) {
      // Skip cropping on web as it's problematic, or make it optional
      if (kIsWeb) {
        // Use image directly on web
        setState(() => _selectedImage = picked);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image selected successfully!')),
        );
      } else {
        // Try cropping on mobile platforms
        try {
          final cropped = await _cropImage(picked);
          if (cropped != null) {
            setState(() => _selectedImage = XFile(cropped.path));
          } else {
            // User cancelled cropping, use original
            setState(() => _selectedImage = picked);
          }
        } catch (e) {
          print('Cropping failed: $e');
          // If cropping fails, use the original image
          setState(() => _selectedImage = picked);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Using original image')),
          );
        }
      }
    }
  }

Future<void> _saveChanges() async {
  if (!_formKey.currentState!.validate()) return;
  setState(() => _saving = true);

  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return;

  final updates = {
    'id': userId,
    'home_course': _homeCourseController.text,
    'bio': _bioController.text,
  };

  if (_selectedImage != null) {
    try {
      final ext = _selectedImage!.path.split('.').last;
      final filePath = 'avatars/$userId.$ext';
      final fileBytes = await _selectedImage!.readAsBytes();

      await Supabase.instance.client.storage
          .from('avatars')
          .uploadBinary(
            filePath,
            fileBytes,
            fileOptions: const FileOptions(upsert: true),
          );

      final publicUrl = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(filePath);

      // Add cache-busting parameter to ensure image updates immediately
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      updates['profile_image_url'] = '$publicUrl?t=$timestamp';
    } catch (e) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image upload failed: $e')),
      );
      return;
    }
  }

  try {
    print('Updating user with data: $updates'); // Debug log
    await Supabase.instance.client.from('users').upsert(updates);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
      Navigator.pop(context, true); // Return true to indicate success
    }
  } catch (e) {
    print('Error updating profile: $e'); // Debug log
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    }
  }

  setState(() => _saving = false);
}

  @override
  void dispose() {
    _homeCourseController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Center(
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: _selectedImage != null
                              ? (kIsWeb 
                                  ? NetworkImage(_selectedImage!.path) 
                                  : FileImage(File(_selectedImage!.path))) as ImageProvider
                              : (widget.userData['profile_image_url'] != null
                                      ? NetworkImage(
                                          widget.userData['profile_image_url'],
                                        )
                                      : null),
                          child: _selectedImage == null &&
                                  widget.userData['profile_image_url'] == null
                              ? const Icon(Icons.person, size: 40)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
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
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _homeCourseController,
                decoration: const InputDecoration(labelText: 'Home Course'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bioController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Bio'),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saving ? null : _saveChanges,
                child: _saving
                    ? const CircularProgressIndicator()
                    : const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}