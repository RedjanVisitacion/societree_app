import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';

class CandidateRegistrationScreen extends StatefulWidget {
  final ApiService api;
  final String? initialCandidateType;
  final String? initialPartyName;
  const CandidateRegistrationScreen({super.key, required this.api, this.initialCandidateType, this.initialPartyName});

  @override
  State<CandidateRegistrationScreen> createState() => _CandidateRegistrationScreenState();
}

class _CandidateRegistrationScreenState extends State<CandidateRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _studentIdCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _middleNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _platformCtrl = TextEditingController();
  final _partyNameCtrl = TextEditingController();
  bool _submitting = false;
  String? _organization;
  String? _course;
  String? _position;
  String? _section;
  String? _candidateType; // Independent or Political Party
  final ImagePicker _picker = ImagePicker();
  XFile? _pickedImage;

  final List<String> _orgOptions = const ['USG', 'SITE', 'PAFE', 'AFPROTECHS'];
  final List<String> _courseOptions = const ['BSIT', 'BTLED', 'BFPT'];
  final List<String> _candidateTypeOptions = const ['Independent', 'Political Party'];
  final Map<String, List<String>> _positionsByOrg = const {
    'USG': [
      'President',
      'Vice President',
      'General Secretary',
      'Associate Secretary',
      'Treasurer',
      'Auditor',
      'Public Information Officer',
      'BSIT Representative',
      'BTLED Representative',
      'BFPT Representative',
    ],
    'SITE': [
      'President',
      'Vice President',
      'General Secretary',
      'Associate Secretary',
      'Treasurer',
      'Auditor',
      'Public Information Officer',
    ],
    'PAFE': [
      'President',
      'Vice President',
      'General Secretary',
      'Associate Secretary',
      'Treasurer',
      'Auditor',
      'Public Information Officer',
    ],
    'AFPROTECHS': [
      'President',
      'Vice President',
      'General Secretary',
      'Associate Secretary',
      'Treasurer',
      'Auditor',
      'Public Information Officer',
    ],
  };

  @override
  void initState() {
    super.initState();
    _candidateType = widget.initialCandidateType;
    if (widget.initialCandidateType == 'Political Party' && (widget.initialPartyName ?? '').isNotEmpty) {
      _partyNameCtrl.text = widget.initialPartyName!;
    }
  }

  final Map<String, List<String>> _sectionsByCourse = const {
    'BSIT': [
      'BSIT-1A', 'BSIT-1B', 'BSIT-1C', 'BSIT-1D',
      'BSIT-2A', 'BSIT-2B', 'BSIT-2C', 'BSIT-2D',
      'BSIT-3A', 'BSIT-3B', 'BSIT-3C', 'BSIT-3D',
      'BSIT-4A', 'BSIT-4B', 'BSIT-4C', 'BSIT-4D', 'BSIT-4E', 'BSIT-4F'
    ],
    'BTLED': [
      'BTLED-ICT-1A', 'BTLED-ICT-2A', 'BTLED-ICT-3A', 'BTLED-ICT-4A',
      'BTLED-IA-1A', 'BTLED-IA-2A', 'BTLED-IA-3A', 'BTLED-IA-4A',
      'BTLED-HE-1A', 'BTLED-HE-2A', 'BTLED-HE-3A', 'BTLED-HE-4A',
    ],
    'BFPT': [
      'BFPT-1A', 'BFPT-1B', 'BFPT-1C', 'BFPT-1D',
      'BFPT-2A', 'BFPT-2B', 'BFPT-2C',
      'BFPT-3A', 'BFPT-3B', 'BFPT-3C',
      'BFPT-4A', 'BFPT-4B',
    ],
  };

  @override
  void dispose() {
    _studentIdCtrl.dispose();
    _firstNameCtrl.dispose();
    _middleNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _partyNameCtrl.dispose();
    _platformCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final img = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (img != null) {
      setState(() => _pickedImage = img);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      String? photoPath;
      if (_pickedImage != null) {
        try {
          final f = File(_pickedImage!.path);
          final len = await f.length();
          if (len <= 2 * 1024 * 1024) {
            photoPath = _pickedImage!.path;
          } else {
            // Skip large photo to avoid server 500 due to upload limits
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Photo is larger than 2MB, uploading without photo.')),
            );
          }
        } catch (_) {
          // ignore and proceed without photo
        }
      }
      final res = await widget.api.registerCandidateMultipart(
        studentId: _studentIdCtrl.text.trim(),
        firstName: _firstNameCtrl.text.trim(),
        middleName: _middleNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        organization: _organization!,
        position: _position!,
        course: _course!,
        yearSection: _section!,
        platform: _platformCtrl.text.trim(),
        candidateType: _candidateType,
        partyName: _candidateType == 'Political Party' ? _partyNameCtrl.text.trim() : null,
        photoFilePath: photoPath,
      );
      final success = res['success'] == true;
      final msg = (res['message'] ?? (success ? 'Candidate registered' : 'Failed')).toString();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      if (success) {
        _formKey.currentState!.reset();
        _studentIdCtrl.clear();
        _firstNameCtrl.clear();
        _middleNameCtrl.clear();
        _lastNameCtrl.clear();
        _platformCtrl.clear();
        if (widget.initialCandidateType == 'Political Party' && (widget.initialPartyName ?? '').isNotEmpty) {
          _partyNameCtrl.text = widget.initialPartyName!;
        } else {
          _partyNameCtrl.clear();
        }
        setState(() {
          _organization = null;
          _course = null;
          _position = null;
          _section = null;
          _candidateType = widget.initialCandidateType ?? _candidateType;
          _pickedImage = null;
        });
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network error')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Register Candidate')),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_pickedImage != null) ...[
                      AspectRatio(
                        aspectRatio: 16/9,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(File(_pickedImage!.path), fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: _submitting ? null : _pickImage,
                        icon: const Icon(Icons.photo_library),
                        label: Text(_pickedImage == null ? 'Choose Photo' : 'Change Photo'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _studentIdCtrl,
                      decoration: const InputDecoration(labelText: 'Candidate student ID'),
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    TextFormField(
                      controller: _firstNameCtrl,
                      decoration: const InputDecoration(labelText: 'First name'),
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    TextFormField(
                      controller: _middleNameCtrl,
                      decoration: const InputDecoration(labelText: 'Middle name (N/A if nothing)'),
                      textInputAction: TextInputAction.next,
                    ),
                    TextFormField(
                      controller: _lastNameCtrl,
                      decoration: const InputDecoration(labelText: 'Last name'),
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    if (widget.initialCandidateType != null) ...[
                      InputDecorator(
                        decoration: const InputDecoration(labelText: 'Candidate type'),
                        child: Text(widget.initialCandidateType!),
                      ),
                    ] else ...[
                      DropdownButtonFormField<String>(
                        value: _candidateType,
                        items: _candidateTypeOptions
                            .map((t) => DropdownMenuItem<String>(value: t, child: Text(t)))
                            .toList(),
                        decoration: const InputDecoration(labelText: 'Candidate type'),
                        onChanged: (v) => setState(() {
                          _candidateType = v;
                          if (_candidateType != 'Political Party') {
                            _partyNameCtrl.clear();
                          }
                        }),
                        validator: (v) => v == null || v.isEmpty ? 'Select a candidate type' : null,
                      ),
                    ],
                    if (_candidateType == 'Political Party') ...[
                      TextFormField(
                        controller: _partyNameCtrl,
                        decoration: const InputDecoration(labelText: 'Party name'),
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          if (_candidateType == 'Political Party') {
                            return (v == null || v.trim().isEmpty) ? 'Party name is required' : null;
                          }
                          return null;
                        },
                      ),
                    ],
                    DropdownButtonFormField<String>(
                      value: _organization,
                      items: _orgOptions
                          .map((o) => DropdownMenuItem<String>(value: o, child: Text(o)))
                          .toList(),
                      decoration: const InputDecoration(labelText: 'Organization'),
                      onChanged: (v) => setState(() {
                        _organization = v;
                        _position = null;
                      }),
                      validator: (v) => v == null || v.isEmpty ? 'Select an organization' : null,
                    ),
                    if (_organization != null) ...[
                      DropdownButtonFormField<String>(
                        value: _position,
                        items: (_positionsByOrg[_organization] ?? const <String>[]) 
                            .map((p) => DropdownMenuItem<String>(value: p, child: Text(p)))
                            .toList(),
                        decoration: const InputDecoration(labelText: 'Position'),
                        onChanged: (v) => setState(() => _position = v),
                        validator: (v) => v == null || v.isEmpty ? 'Select a position' : null,
                      ),
                    ],
                    DropdownButtonFormField<String>(
                      value: _course,
                      items: _courseOptions
                          .map((c) => DropdownMenuItem<String>(value: c, child: Text(c)))
                          .toList(),
                      decoration: const InputDecoration(labelText: 'Program'),
                      onChanged: (v) => setState(() {
                        _course = v;
                        _section = null;
                      }),
                      validator: (v) => v == null || v.isEmpty ? 'Select a course' : null,
                    ),
                    if (_course != null) ...[
                      DropdownButtonFormField<String>(
                        value: _section,
                        items: (_sectionsByCourse[_course] ?? const <String>[]) 
                            .map((s) => DropdownMenuItem<String>(value: s, child: Text(s)))
                            .toList(),
                        decoration: const InputDecoration(labelText: 'Section'),
                        onChanged: (v) => setState(() => _section = v),
                        validator: (v) => v == null || v.isEmpty ? 'Select a section' : null,
                      ),
                    ],
                    TextFormField(
                      controller: _platformCtrl,
                      decoration: const InputDecoration(labelText: 'Platform'),
                      keyboardType: TextInputType.multiline,
                      maxLines: 4,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _submitting ? null : _submit,
                      icon: const Icon(Icons.save),
                      label: Text(_submitting ? 'Submitting...' : 'Submit'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
