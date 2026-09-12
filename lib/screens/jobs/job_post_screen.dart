import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:agribased/models/job_model.dart';
import 'package:agribased/services/job/job_service.dart';
import 'package:agribased/services/storage_router_service.dart';

class JobPostScreen extends StatefulWidget {
  final JobPostType postType;
  final JobPost? jobToEdit;

  const JobPostScreen({super.key, required this.postType, this.jobToEdit});

  bool get isEditing => jobToEdit != null;

  @override
  State<JobPostScreen> createState() => _JobPostScreenState();
}

class _JobPostScreenState extends State<JobPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final JobService _jobService = JobService();

  bool _isLoading = false;

  // Common fields
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _locationStateController = TextEditingController();
  final _phoneController = TextEditingController();

  // Contact Info fields (for both types)
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _facebookController = TextEditingController();
  final _twitterController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _whatsappController = TextEditingController();

  // Farmer job specific fields
  final _farmNameController = TextEditingController();
  final _salaryController = TextEditingController();
  final _positionsController = TextEditingController();
  final _requirementsController = TextEditingController();
  final _benefitsController = TextEditingController();

  // Job seeker specific fields
  final _skillsController = TextEditingController();
  final _experienceController = TextEditingController();
  final _educationController = TextEditingController();
  final _expectedSalaryController = TextEditingController();
  final _availabilityController = TextEditingController();
  final _preferredLocationController = TextEditingController();

  // Documents (for job seekers)
  final List<File> _selectedDocuments = [];
  List<String> _uploadedDocumentUrls = [];

  JobCategory _selectedCategory = JobCategory.generalLabor;
  String _selectedSalaryPeriod = 'monthly';
  String _selectedDuration = 'permanent';
  DateTime? _startDate;
  DateTime? _endDate;

  double? _latitude;
  double? _longitude;

  final List<String> _salaryPeriods = ['hourly', 'daily', 'weekly', 'monthly'];
  final List<String> _durations = [
    'temporary',
    'permanent',
    'seasonal',
    'contract',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserPhone();
    _populateFieldsIfEditing();
  }

  void _populateFieldsIfEditing() {
    final job = widget.jobToEdit;
    if (job == null) return;

    // Populate common fields
    _titleController.text = job.title;
    _descriptionController.text = job.description;
    _locationController.text = job.location;
    _locationStateController.text = job.locationState ?? '';
    _phoneController.text = job.userPhone ?? '';
    _selectedCategory = job.category;
    _latitude = job.latitude;
    _longitude = job.longitude;

    final isFarmerJob = widget.postType == JobPostType.farmerJob;

    if (isFarmerJob) {
      // Farmer job fields
      _farmNameController.text = job.farmName ?? '';
      _salaryController.text = job.salary?.toString() ?? '';
      _selectedSalaryPeriod = job.salaryPeriod ?? 'monthly';
      _selectedDuration = job.duration ?? 'permanent';
      _positionsController.text = job.positionsAvailable?.toString() ?? '';
      _requirementsController.text = job.requirements?.join(', ') ?? '';
      _benefitsController.text = job.benefits?.join(', ') ?? '';
      _startDate = job.startDate;
      _endDate = job.endDate;
    } else {
      // Job seeker fields
      _skillsController.text = job.skills ?? '';
      _experienceController.text = job.experience ?? '';
      _educationController.text = job.education ?? '';
      _expectedSalaryController.text = job.expectedSalary ?? '';
      _availabilityController.text = job.availability ?? '';
      _preferredLocationController.text = job.preferredLocation ?? '';
      // Load existing document URLs
      if (job.documentUrls != null) {
        _uploadedDocumentUrls = List.from(job.documentUrls!);
      }
    }
  }

  Future<void> _loadUserPhone() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('farmers')
          .doc(user.uid)
          .get();
      final phone =
          doc.data()?['phone'] ??
          doc.data()?['contact_number'] ??
          doc.data()?['phone_number'];
      final email = doc.data()?['email'];
      if (phone != null) {
        _phoneController.text = phone.toString();
      }
      if (email != null) {
        _emailController.text = email.toString();
      }
    }
  }

  Future<void> _pickAndUploadDocument() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final file = File(pickedFile.path);
      final user = FirebaseAuth.instance.currentUser;
      final url = await StorageRouterService.instance.uploadFile(
        file: file,
        folder: 'farmers/job_documents/${user?.uid ?? 'anonymous'}',
      );

      if (url != null) {
        setState(() {
          _uploadedDocumentUrls.add(url);
          _selectedDocuments.add(file);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Document uploaded successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading document: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _takeAndUploadDocument() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (pickedFile == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final file = File(pickedFile.path);
      final user = FirebaseAuth.instance.currentUser;
      final url = await StorageRouterService.instance.uploadFile(
        file: file,
        folder: 'farmers/job_documents/${user?.uid ?? 'anonymous'}',
      );

      if (url != null) {
        setState(() {
          _uploadedDocumentUrls.add(url);
          _selectedDocuments.add(file);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Document uploaded successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading document: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _removeDocument(int index) {
    setState(() {
      _uploadedDocumentUrls.removeAt(index);
      if (index < _selectedDocuments.length) {
        _selectedDocuments.removeAt(index);
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _locationStateController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _facebookController.dispose();
    _twitterController.dispose();
    _linkedinController.dispose();
    _whatsappController.dispose();
    _farmNameController.dispose();
    _salaryController.dispose();
    _positionsController.dispose();
    _requirementsController.dispose();
    _benefitsController.dispose();
    _skillsController.dispose();
    _experienceController.dispose();
    _educationController.dispose();
    _expectedSalaryController.dispose();
    _availabilityController.dispose();
    _preferredLocationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFarmerJob = widget.postType == JobPostType.farmerJob;
    final isEditing = widget.isEditing;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        title: Text(
          isEditing
              ? (isFarmerJob ? 'Edit Job' : 'Edit Profile')
              : (isFarmerJob ? 'Post a Job' : 'Create Job Profile'),
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isFarmerJob
                      ? Colors.green.shade50
                      : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isFarmerJob
                        ? Colors.green.shade200
                        : Colors.blue.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isFarmerJob ? Icons.work : Icons.person_search,
                      color: isFarmerJob ? Colors.green : Colors.blue,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isFarmerJob
                                ? 'Looking for Workers?'
                                : 'Looking for a Farm Job?',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            isFarmerJob
                                ? 'Post a job to find helpers for your farm'
                                : 'Create a profile to help farmers find you',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Category Selection
              Text(
                'Job Category',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<JobCategory>(
                initialValue: _selectedCategory,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                items: JobCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(_getCategoryDisplay(category)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 16),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: isFarmerJob ? 'Job Title *' : 'Headline / Title *',
                  hintText: isFarmerJob
                      ? 'e.g., Harvest Workers Needed'
                      : 'e.g., Experienced Farm Worker',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  if (value.length < 5) {
                    return 'Title must be at least 5 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description *',
                  hintText: isFarmerJob
                      ? 'Describe the job duties, requirements, etc.'
                      : 'Describe your experience, skills, and what you are looking for',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  if (value.length < 20) {
                    return 'Description must be at least 20 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Location
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        labelText: 'Town/City *',
                        hintText: 'e.g., Harare',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.location_on),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a location';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _locationStateController,
                      decoration: InputDecoration(
                        labelText: 'Province',
                        hintText: 'e.g., Mashonaland',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Contact Phone
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Contact Phone Number *',
                  hintText: 'e.g., +263 77 123 4567',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a phone number';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Contact Information Section
              Text(
                'Contact Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'e.g., contact@farm.com',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 16),

              // Website
              TextFormField(
                controller: _websiteController,
                decoration: InputDecoration(
                  labelText: 'Website (optional)',
                  hintText: 'e.g., www.farmwebsite.com',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.language),
                ),
                keyboardType: TextInputType.url,
              ),

              const SizedBox(height: 16),

              // Social Media Links
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _facebookController,
                      decoration: InputDecoration(
                        labelText: 'Facebook',
                        hintText: 'Profile URL',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(
                          Icons.facebook,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _twitterController,
                      decoration: InputDecoration(
                        labelText: 'Twitter/X',
                        hintText: 'Profile URL',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(
                          Icons.alternate_email,
                          color: Colors.lightBlue,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // LinkedIn & WhatsApp
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _linkedinController,
                      decoration: InputDecoration(
                        labelText: 'LinkedIn',
                        hintText: 'Profile URL',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(
                          Icons.business,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _whatsappController,
                      decoration: InputDecoration(
                        labelText: 'WhatsApp',
                        hintText: 'e.g., +263 77 123 4567',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.chat, color: Colors.green),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Conditional fields based on post type
              if (isFarmerJob) ...[
                _buildFarmerJobFields(),
              ] else ...[
                _buildJobSeekerFields(),
              ],

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFarmerJob
                        ? Colors.green.shade700
                        : Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Text(
                          isEditing
                              ? (isFarmerJob
                                    ? 'Save Changes'
                                    : 'Update Profile')
                              : (isFarmerJob ? 'Post Job' : 'Create Profile'),
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Note about approval
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isEditing
                      ? Colors.blue.shade50
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isEditing
                        ? Colors.blue.shade200
                        : Colors.orange.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isEditing ? Icons.info_outline : Icons.info_outline,
                      color: isEditing
                          ? Colors.blue.shade700
                          : Colors.orange.shade700,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isEditing
                            ? 'Your changes will be saved immediately. You can edit your post anytime.'
                            : 'Your post will be reviewed by an admin before it goes live. This usually takes 24-48 hours.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isEditing
                              ? Colors.blue.shade700
                              : Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFarmerJobFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Job Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 16),

        // Farm Name
        TextFormField(
          controller: _farmNameController,
          decoration: InputDecoration(
            labelText: 'Farm Name',
            hintText: 'e.g., Green Valley Farm',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.agriculture),
          ),
        ),

        const SizedBox(height: 16),

        // Salary
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _salaryController,
                decoration: InputDecoration(
                  labelText: 'Salary (USD)',
                  hintText: 'e.g., 300',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _selectedSalaryPeriod,
                decoration: InputDecoration(
                  labelText: 'Period',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _salaryPeriods.map((period) {
                  return DropdownMenuItem(value: period, child: Text(period));
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedSalaryPeriod = value;
                    });
                  }
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Duration
        DropdownButtonFormField<String>(
          initialValue: _selectedDuration,
          decoration: InputDecoration(
            labelText: 'Employment Type',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.schedule),
          ),
          items: _durations.map((duration) {
            return DropdownMenuItem(
              value: duration,
              child: Text(duration[0].toUpperCase() + duration.substring(1)),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedDuration = value;
              });
            }
          },
        ),

        const SizedBox(height: 16),

        // Positions Available
        TextFormField(
          controller: _positionsController,
          decoration: InputDecoration(
            labelText: 'Number of Positions',
            hintText: 'e.g., 5',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.people),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
        ),

        const SizedBox(height: 16),

        // Date Range
        Row(
          children: [
            Expanded(
              child: _buildDatePicker(
                label: 'Start Date',
                selectedDate: _startDate,
                onSelect: (date) => setState(() => _startDate = date),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDatePicker(
                label: 'End Date (Optional)',
                selectedDate: _endDate,
                onSelect: (date) => setState(() => _endDate = date),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Requirements
        TextFormField(
          controller: _requirementsController,
          decoration: InputDecoration(
            labelText: 'Requirements (comma separated)',
            hintText: 'e.g., Physical fitness, Experience with tractors',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.checklist),
          ),
        ),

        const SizedBox(height: 16),

        // Benefits
        TextFormField(
          controller: _benefitsController,
          decoration: InputDecoration(
            labelText: 'Benefits (comma separated)',
            hintText: 'e.g., Accommodation, Meals provided',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.card_giftcard),
          ),
        ),
      ],
    );
  }

  Widget _buildJobSeekerFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Profile',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 16),

        // Skills
        TextFormField(
          controller: _skillsController,
          decoration: InputDecoration(
            labelText: 'Skills',
            hintText: 'e.g., Tractor driving, Irrigation, Livestock care',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.build),
          ),
          maxLines: 2,
        ),

        const SizedBox(height: 16),

        // Experience
        TextFormField(
          controller: _experienceController,
          decoration: InputDecoration(
            labelText: 'Experience',
            hintText: 'e.g., 3 years on commercial farms',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.timeline),
          ),
        ),

        const SizedBox(height: 16),

        // Education
        TextFormField(
          controller: _educationController,
          decoration: InputDecoration(
            labelText: 'Education / Certifications',
            hintText: 'e.g., Certificate in Agriculture',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.school),
          ),
        ),

        const SizedBox(height: 16),

        // Expected Salary
        TextFormField(
          controller: _expectedSalaryController,
          decoration: InputDecoration(
            labelText: 'Expected Salary',
            hintText: 'e.g., \$200 - \$400 per month',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.attach_money),
          ),
        ),

        const SizedBox(height: 16),

        // Availability
        TextFormField(
          controller: _availabilityController,
          decoration: InputDecoration(
            labelText: 'Availability',
            hintText: 'e.g., Immediately, From January 2026',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.event_available),
          ),
        ),

        const SizedBox(height: 16),

        // Preferred Location
        TextFormField(
          controller: _preferredLocationController,
          decoration: InputDecoration(
            labelText: 'Preferred Work Location',
            hintText: 'e.g., Mashonaland West, Anywhere in Zimbabwe',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.map),
          ),
        ),

        const SizedBox(height: 24),

        // Documents Section
        Text(
          'Documents (Optional)',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Upload CV, certificates, or other documents to support your profile',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),

        // Document Upload Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _pickAndUploadDocument,
                icon: const Icon(Icons.photo_library),
                label: const Text('Gallery'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _takeAndUploadDocument,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Camera'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Uploaded Documents List
        if (_uploadedDocumentUrls.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Uploaded Documents (${_uploadedDocumentUrls.length})',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                ..._uploadedDocumentUrls.asMap().entries.map((entry) {
                  final index = entry.key;
                  final url = entry.value;
                  return ListTile(
                    dense: true,
                    leading: const Icon(
                      Icons.insert_drive_file,
                      color: Colors.blue,
                    ),
                    title: Text(
                      'Document ${index + 1}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    subtitle: Text(
                      url.length > 40 ? '${url.substring(0, 40)}...' : url,
                      style: const TextStyle(fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.red,
                        size: 20,
                      ),
                      onPressed: () => _removeDocument(index),
                    ),
                    onTap: () {
                      // Open document preview or link
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Document URL: $url')),
                      );
                    },
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime? selectedDate,
    required Function(DateTime) onSelect,
  }) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) {
          onSelect(date);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          prefixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          selectedDate != null
              ? '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'
              : 'Select date',
          style: TextStyle(
            color: selectedDate != null ? Colors.black : Colors.grey,
          ),
        ),
      ),
    );
  }

  String _getCategoryDisplay(JobCategory category) {
    switch (category) {
      case JobCategory.generalLabor:
        return 'General Labor';
      case JobCategory.harvesting:
        return 'Harvesting';
      case JobCategory.planting:
        return 'Planting & Seeding';
      case JobCategory.irrigation:
        return 'Irrigation';
      case JobCategory.livestock:
        return 'Livestock & Animals';
      case JobCategory.machinery:
        return 'Machinery Operation';
      case JobCategory.technical:
        return 'Technical & Specialist';
      case JobCategory.management:
        return 'Management & Supervision';
      case JobCategory.sales:
        return 'Sales & Marketing';
      case JobCategory.other:
        return 'Other';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final isFarmerJob = widget.postType == JobPostType.farmerJob;
      final isEditing = widget.isEditing;

      if (isEditing) {
        // Update existing job
        await _jobService.updateJob(
          jobId: widget.jobToEdit!.id,
          category: _selectedCategory,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          location: _locationController.text.trim(),
          locationState: _locationStateController.text.trim().isEmpty
              ? null
              : _locationStateController.text.trim(),
          userPhone: _phoneController.text.trim(),
          // Farmer job fields
          farmName: isFarmerJob && _farmNameController.text.isNotEmpty
              ? _farmNameController.text.trim()
              : null,
          salary: isFarmerJob && _salaryController.text.isNotEmpty
              ? double.tryParse(_salaryController.text)
              : null,
          salaryPeriod: isFarmerJob ? _selectedSalaryPeriod : null,
          duration: isFarmerJob ? _selectedDuration : null,
          startDate: _startDate,
          endDate: _endDate,
          positionsAvailable:
              isFarmerJob && _positionsController.text.isNotEmpty
              ? int.tryParse(_positionsController.text)
              : null,
          requirements: isFarmerJob && _requirementsController.text.isNotEmpty
              ? _requirementsController.text
                    .split(',')
                    .map((s) => s.trim())
                    .toList()
              : null,
          benefits: isFarmerJob && _benefitsController.text.isNotEmpty
              ? _benefitsController.text
                    .split(',')
                    .map((s) => s.trim())
                    .toList()
              : null,
          // Job seeker fields
          skills: !isFarmerJob && _skillsController.text.isNotEmpty
              ? _skillsController.text.trim()
              : null,
          experience: !isFarmerJob && _experienceController.text.isNotEmpty
              ? _experienceController.text.trim()
              : null,
          education: !isFarmerJob && _educationController.text.isNotEmpty
              ? _educationController.text.trim()
              : null,
          expectedSalary:
              !isFarmerJob && _expectedSalaryController.text.isNotEmpty
              ? _expectedSalaryController.text.trim()
              : null,
          availability: !isFarmerJob && _availabilityController.text.isNotEmpty
              ? _availabilityController.text.trim()
              : null,
          preferredLocation:
              !isFarmerJob && _preferredLocationController.text.isNotEmpty
              ? _preferredLocationController.text.trim()
              : null,
          // Contact Info
          contactEmail: _emailController.text.isNotEmpty
              ? _emailController.text.trim()
              : null,
          website: _websiteController.text.isNotEmpty
              ? _websiteController.text.trim()
              : null,
          facebookUrl: _facebookController.text.isNotEmpty
              ? _facebookController.text.trim()
              : null,
          twitterUrl: _twitterController.text.isNotEmpty
              ? _twitterController.text.trim()
              : null,
          linkedinUrl: _linkedinController.text.isNotEmpty
              ? _linkedinController.text.trim()
              : null,
          whatsappNumber: _whatsappController.text.isNotEmpty
              ? _whatsappController.text.trim()
              : null,
          // Documents
          documentUrls: _uploadedDocumentUrls.isNotEmpty
              ? _uploadedDocumentUrls
              : null,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        // Create new job
        await _jobService.postJob(
          postType: widget.postType,
          category: _selectedCategory,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          location: _locationController.text.trim(),
          locationState: _locationStateController.text.trim().isEmpty
              ? null
              : _locationStateController.text.trim(),
          locationCountry: 'Zimbabwe',
          latitude: _latitude,
          longitude: _longitude,
          // Farmer job fields
          farmName: isFarmerJob && _farmNameController.text.isNotEmpty
              ? _farmNameController.text.trim()
              : null,
          salary: isFarmerJob && _salaryController.text.isNotEmpty
              ? double.tryParse(_salaryController.text)
              : null,
          salaryPeriod: isFarmerJob ? _selectedSalaryPeriod : null,
          duration: isFarmerJob ? _selectedDuration : null,
          startDate: _startDate,
          endDate: _endDate,
          positionsAvailable:
              isFarmerJob && _positionsController.text.isNotEmpty
              ? int.tryParse(_positionsController.text)
              : null,
          requirements: isFarmerJob && _requirementsController.text.isNotEmpty
              ? _requirementsController.text
                    .split(',')
                    .map((s) => s.trim())
                    .toList()
              : null,
          benefits: isFarmerJob && _benefitsController.text.isNotEmpty
              ? _benefitsController.text
                    .split(',')
                    .map((s) => s.trim())
                    .toList()
              : null,
          // Job seeker fields
          skills: !isFarmerJob && _skillsController.text.isNotEmpty
              ? _skillsController.text.trim()
              : null,
          experience: !isFarmerJob && _experienceController.text.isNotEmpty
              ? _experienceController.text.trim()
              : null,
          education: !isFarmerJob && _educationController.text.isNotEmpty
              ? _educationController.text.trim()
              : null,
          expectedSalary:
              !isFarmerJob && _expectedSalaryController.text.isNotEmpty
              ? _expectedSalaryController.text.trim()
              : null,
          availability: !isFarmerJob && _availabilityController.text.isNotEmpty
              ? _availabilityController.text.trim()
              : null,
          preferredLocation:
              !isFarmerJob && _preferredLocationController.text.isNotEmpty
              ? _preferredLocationController.text.trim()
              : null,
          // Contact Info
          contactEmail: _emailController.text.isNotEmpty
              ? _emailController.text.trim()
              : null,
          website: _websiteController.text.isNotEmpty
              ? _websiteController.text.trim()
              : null,
          facebookUrl: _facebookController.text.isNotEmpty
              ? _facebookController.text.trim()
              : null,
          twitterUrl: _twitterController.text.isNotEmpty
              ? _twitterController.text.trim()
              : null,
          linkedinUrl: _linkedinController.text.isNotEmpty
              ? _linkedinController.text.trim()
              : null,
          whatsappNumber: _whatsappController.text.isNotEmpty
              ? _whatsappController.text.trim()
              : null,
          // Documents
          documentUrls: _uploadedDocumentUrls.isNotEmpty
              ? _uploadedDocumentUrls
              : null,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Posted successfully! Awaiting admin approval.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
