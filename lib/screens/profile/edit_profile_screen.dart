import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/usga_theme.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  
  const EditProfileScreen({super.key, required this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _handicapController;
  late TextEditingController _locationController;
  late TextEditingController _phoneController;
  late TextEditingController _birthDateController;
  
  DateTime? _birthDate;
  bool _loading = false;
  
  @override
  void initState() {
    super.initState();
    
    // Split full name into first and last name
    final fullName = widget.userData['full_name'] ?? '';
    final nameParts = fullName.split(' ');
    final firstName = nameParts.isNotEmpty ? nameParts.first : '';
    final lastName = nameParts.length > 1 ? nameParts.skip(1).join(' ') : '';
    
    _firstNameController = TextEditingController(text: firstName);
    _lastNameController = TextEditingController(text: lastName);
    _handicapController = TextEditingController(text: widget.userData['handicap']?.toString() ?? '');
    _locationController = TextEditingController(text: widget.userData['location'] ?? '');
    _phoneController = TextEditingController(text: widget.userData['phone'] ?? '');
    
    // Parse birth_date from userData or calculate from age
    if (widget.userData['birth_date'] != null) {
      try {
        _birthDate = DateTime.parse(widget.userData['birth_date']);
        _birthDateController = TextEditingController(text: _formatDateForInput(_birthDate!));
      } catch (e) {
        _birthDate = null;
        _birthDateController = TextEditingController();
      }
    } else if (widget.userData['age'] != null) {
      // Convert existing age to approximate birth date
      final age = widget.userData['age'] as int;
      final currentYear = DateTime.now().year;
      _birthDate = DateTime(currentYear - age, 1, 1);
      _birthDateController = TextEditingController(text: _formatDateForInput(_birthDate!));
    } else {
      _birthDateController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _handicapController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  String _formatDateForInput(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final updates = <String, dynamic>{
        'full_name': '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'.trim(),
        'birth_date': _birthDate?.toIso8601String().split('T')[0], // Store as DATE format
        'handicap': double.tryParse(_handicapController.text.trim()),
        'location': _locationController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Only include phone if the column exists (might not exist yet)
      try {
        if (_phoneController.text.trim().isNotEmpty) {
          updates['phone'] = _phoneController.text.trim();
        }
      } catch (e) {
        // Phone column might not exist yet, skip it
        print('Phone column not available: $e');
      }

      await Supabase.instance.client
          .from('profiles')
          .update(updates)
          .eq('id', user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: USGATheme.successGreen,
          ),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $error'),
            backgroundColor: USGATheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: USGATheme.backgroundWhite,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _loading ? null : _saveProfile,
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: USGATheme.accentRed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(USGATheme.spacingLg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Image Section
              _buildProfileImageSection(),
              
              const SizedBox(height: USGATheme.spacingXl),
              
              // Personal Information
              USGATheme.sectionHeader('Personal Information'),
              const SizedBox(height: USGATheme.spacingSm),
              USGATheme.modernCard(
                child: Column(
                  children: [
                    // First and Last Name Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _firstNameController,
                            label: 'First Name',
                            hint: 'Enter first name',
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'First name is required';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: USGATheme.spacingMd),
                        Expanded(
                          child: _buildTextField(
                            controller: _lastNameController,
                            label: 'Last Name',
                            hint: 'Enter last name',
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Last name is required';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: USGATheme.spacingMd),
                    
                    // Birth Date - Full Width
                    _buildBirthDatePicker(),
                    
                    const SizedBox(height: USGATheme.spacingMd),
                    
                    // Handicap - Full Width
                    _buildTextField(
                      controller: _handicapController,
                      label: 'Handicap',
                      hint: 'USGA handicap (optional)',
                      icon: Icons.sports_golf,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          final handicap = double.tryParse(value.trim());
                          if (handicap == null || handicap < -10 || handicap > 54) {
                            return 'Enter valid handicap (-10 to 54)';
                          }
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: USGATheme.spacingLg),

              // Contact Information
              USGATheme.sectionHeader('Contact Information'),
              const SizedBox(height: USGATheme.spacingSm),
              USGATheme.modernCard(
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      hint: 'Your phone number',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: USGATheme.spacingMd),
                    _buildTextField(
                      controller: _locationController,
                      label: 'Location',
                      hint: 'City, State or general area',
                      icon: Icons.location_on,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: USGATheme.spacing2xl),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : () => _saveProfile(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: USGATheme.primaryNavy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: USGATheme.spacingMd),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(USGATheme.radiusMd),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: USGATheme.spacingLg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImageSection() {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundImage: widget.userData['profile_image_url'] != null
                    ? NetworkImage(widget.userData['profile_image_url'])
                    : null,
                backgroundColor: USGATheme.surfaceGray,
                child: widget.userData['profile_image_url'] == null
                    ? const Icon(
                        Icons.person,
                        size: 60,
                        color: USGATheme.textSecondary,
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: USGATheme.accentRed,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: USGATheme.backgroundWhite,
                      width: 2,
                    ),
                  ),
                  child: IconButton(
                    onPressed: _changeProfileImage,
                    icon: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: USGATheme.spacingSm),
          TextButton(
            onPressed: _changeProfileImage,
            child: const Text(
              'Change Profile Photo',
              style: TextStyle(
                color: USGATheme.accentRed,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(
        color: USGATheme.textPrimary,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon, color: USGATheme.textSecondary) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(USGATheme.radiusMd),
          borderSide: const BorderSide(color: USGATheme.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(USGATheme.radiusMd),
          borderSide: const BorderSide(color: USGATheme.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(USGATheme.radiusMd),
          borderSide: const BorderSide(color: USGATheme.accentRed, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(USGATheme.radiusMd),
          borderSide: BorderSide(color: USGATheme.error, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(USGATheme.radiusMd),
          borderSide: BorderSide(color: USGATheme.error, width: 2),
        ),
        filled: true,
        fillColor: USGATheme.surfaceGray.withOpacity(0.3),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: USGATheme.spacingMd,
          vertical: USGATheme.spacingSm,
        ),
      ),
    );
  }

  Widget _buildBirthDatePicker() {
    final currentAge = _birthDate != null 
        ? DateTime.now().year - _birthDate!.year - 
          (DateTime.now().isBefore(DateTime(_birthDate!.year + (DateTime.now().year - _birthDate!.year), _birthDate!.month, _birthDate!.day)) ? 1 : 0)
        : null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Birth Date',
          style: TextStyle(
            color: USGATheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        
        // Modern date display button
        GestureDetector(
          onTap: () => _showIOSDatePicker(),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(USGATheme.spacingMd),
            decoration: BoxDecoration(
              color: USGATheme.surfaceGray.withOpacity(0.3),
              borderRadius: BorderRadius.circular(USGATheme.radiusMd),
              border: Border.all(color: USGATheme.borderLight),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.cake_rounded,
                  color: USGATheme.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: USGATheme.spacingMd),
                Expanded(
                  child: Text(
                    _birthDate != null 
                        ? _formatDateForDisplay(_birthDate!)
                        : 'Select your birth date',
                    style: TextStyle(
                      color: _birthDate != null 
                          ? USGATheme.textPrimary 
                          : USGATheme.textTertiary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: USGATheme.textTertiary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        
        if (currentAge != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Age: $currentAge',
              style: const TextStyle(
                color: USGATheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  String _formatDateForDisplay(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> _showIOSDatePicker() async {
    DateTime tempDate = _birthDate ?? DateTime(DateTime.now().year - 25);
    
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 350,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(USGATheme.radiusLg),
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: USGATheme.spacingLg,
                vertical: USGATheme.spacingMd,
              ),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: USGATheme.borderLight),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: USGATheme.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const Text(
                    'Select Birth Date',
                    style: TextStyle(
                      color: USGATheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _birthDate = tempDate;
                        _birthDateController.text = _formatDateForInput(tempDate);
                      });
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        color: USGATheme.accentRed,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // iOS-style date picker with scrollable wheels
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: tempDate,
                minimumDate: DateTime(DateTime.now().year - 100),
                maximumDate: DateTime(DateTime.now().year - 16),
                onDateTimeChanged: (DateTime newDate) {
                  tempDate = newDate;
                },
                backgroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _changeProfileImage() {
    // Show options for changing profile image
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(USGATheme.radiusLg),
        ),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(USGATheme.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Change Profile Photo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: USGATheme.textPrimary,
              ),
            ),
            const SizedBox(height: USGATheme.spacingLg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageFromCamera();
                  },
                ),
                _buildImageOption(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageFromGallery();
                  },
                ),
                if (widget.userData['profile_image_url'] != null)
                  _buildImageOption(
                    icon: Icons.delete,
                    label: 'Remove',
                    onTap: () {
                      Navigator.pop(context);
                      _removeProfileImage();
                    },
                  ),
              ],
            ),
            const SizedBox(height: USGATheme.spacingLg),
          ],
        ),
      ),
    );
  }

  Widget _buildImageOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: USGATheme.surfaceGray,
              shape: BoxShape.circle,
              border: Border.all(color: USGATheme.borderLight),
            ),
            child: Icon(
              icon,
              color: USGATheme.textSecondary,
              size: 30,
            ),
          ),
          const SizedBox(height: USGATheme.spacingXs),
          Text(
            label,
            style: const TextStyle(
              color: USGATheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _pickImageFromCamera() {
    // TODO: Implement camera image picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Camera functionality will be available soon'),
      ),
    );
  }

  void _pickImageFromGallery() {
    // TODO: Implement gallery image picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Gallery functionality will be available soon'),
      ),
    );
  }

  void _removeProfileImage() {
    // TODO: Implement remove profile image
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Remove image functionality will be available soon'),
      ),
    );
  }
}
