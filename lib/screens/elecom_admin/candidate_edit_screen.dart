import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:societree_app/config/api_config.dart';
import 'package:societree_app/services/api_service.dart';

class CandidateEditScreen extends StatefulWidget {
  final Map<String, dynamic> candidate;
  const CandidateEditScreen({super.key, required this.candidate});

  @override
  State<CandidateEditScreen> createState() => _CandidateEditScreenState();
}

class _CandidateEditScreenState extends State<CandidateEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final ApiService _api;

  final _studentIdCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _middleNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _organizationCtrl = TextEditingController();
  final _positionCtrl = TextEditingController();
  final _courseCtrl = TextEditingController();
  final _yearSectionCtrl = TextEditingController();
  final _platformCtrl = TextEditingController();
  final _partyNameCtrl = TextEditingController();

  String? _candidateType; // Independent or Political Party
  bool _submitting = false;

  // Allow updating candidate photo only
  final ImagePicker _picker = ImagePicker();
  XFile? _photo;
  bool _picking = false;

  // Dropdown state mirroring registration screen
  final List<String> _orgOptions = const ['USG', 'SITE', 'PAFE', 'AFPROTECHS'];
  final List<String> _courseOptions = const ['BSIT', 'BTLED', 'BFPT'];
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
  final Map<String, List<String>> _sectionsByCourse = const {
    'BSIT': [
      'BSIT-1A','BSIT-1B','BSIT-1C','BSIT-1D',
      'BSIT-2A','BSIT-2B','BSIT-2C','BSIT-2D',
      'BSIT-3A','BSIT-3B','BSIT-3C','BSIT-3D',
      'BSIT-4A','BSIT-4B','BSIT-4C','BSIT-4D','BSIT-4E','BSIT-4F',
    ],
    'BTLED': [
      'BTLED-ICT-1A','BTLED-ICT-2A','BTLED-ICT-3A','BTLED-ICT-4A',
      'BTLED-IA-1A','BTLED-IA-2A','BTLED-IA-3A','BTLED-IA-4A',
      'BTLED-HE-1A','BTLED-HE-2A','BTLED-HE-3A','BTLED-HE-4A',
    ],
    'BFPT': [
      'BFPT-1A','BFPT-1B','BFPT-1C','BFPT-1D',
      'BFPT-2A','BFPT-2B','BFPT-2C',
      'BFPT-3A','BFPT-3B','BFPT-3C',
      'BFPT-4A','BFPT-4B',
    ],
  };

  String? _organization;
  String? _position;
  String? _course;
  String? _section;

  @override
  void initState() {
    super.initState();
    _api = ApiService(baseUrl: apiBaseUrl);
    final c = widget.candidate;
    _studentIdCtrl.text = (c['student_id'] ?? '').toString();
    _firstNameCtrl.text = (c['first_name'] ?? '').toString();
    _middleNameCtrl.text = (c['middle_name'] ?? '').toString();
    _lastNameCtrl.text = (c['last_name'] ?? '').toString();
    _organization = (c['organization'] ?? '').toString().isEmpty ? null : (c['organization'] ?? '').toString();
    _position = (c['position'] ?? '').toString().isEmpty ? null : (c['position'] ?? '').toString();
    _course = (c['program'] ?? c['course'] ?? '').toString().isEmpty ? null : (c['program'] ?? c['course'] ?? '').toString();
    _section = (c['year_section'] ?? '').toString().isEmpty ? null : (c['year_section'] ?? '').toString();
    _platformCtrl.text = (c['platform'] ?? '').toString();
    _candidateType = (c['candidate_type'] ?? '').toString().isEmpty
        ? null
        : (c['candidate_type'] ?? '').toString();
    _partyNameCtrl.text = (c['party_name'] ?? '').toString();
  }

  @override
  void dispose() {
    _studentIdCtrl.dispose();
    _firstNameCtrl.dispose();
    _middleNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _organizationCtrl.dispose();
    _positionCtrl.dispose();
    _courseCtrl.dispose();
    _yearSectionCtrl.dispose();
    _platformCtrl.dispose();
    _partyNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final img = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (img != null) {
        setState(() { _photo = img; });
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final id = (widget.candidate['id'] ?? widget.candidate['candidate_id']) as int?;
      if (id == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Missing candidate id')));
        }
        return;
      }
      // Detect if anything actually changed
      final orig = widget.candidate;
      bool anyChanged = false;
      bool changed(String? a, String? b) => (a ?? '').trim() != (b ?? '').trim();
      if (changed(_studentIdCtrl.text, (orig['student_id'] ?? '').toString())) anyChanged = true;
      if (changed(_firstNameCtrl.text, (orig['first_name'] ?? '').toString())) anyChanged = true;
      if (changed(_middleNameCtrl.text, (orig['middle_name'] ?? '').toString())) anyChanged = true;
      if (changed(_lastNameCtrl.text, (orig['last_name'] ?? '').toString())) anyChanged = true;
      if (changed(_organization, (orig['organization'] ?? '').toString())) anyChanged = true;
      if (changed(_position, (orig['position'] ?? '').toString())) anyChanged = true;
      if (changed(_course, (orig['program'] ?? orig['course'] ?? '').toString())) anyChanged = true;
      if (changed(_section, (orig['year_section'] ?? '').toString())) anyChanged = true;
      if (changed(_platformCtrl.text, (orig['platform'] ?? '').toString())) anyChanged = true;
      if (changed(_candidateType, (orig['candidate_type'] ?? '').toString())) anyChanged = true;
      if (_candidateType == 'Political Party') {
        if (changed(_partyNameCtrl.text, (orig['party_name'] ?? '').toString())) anyChanged = true;
      }
      // Photo update is allowed
      if (_photo != null) anyChanged = true;
      if (!anyChanged) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No changes to save')));
        }
        return;
      }
      if (!anyChanged) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No changes to save')));
        }
        return;
      }

      final res = await _api.updateCandidateMultipart(
        candidateId: id,
        studentId: _studentIdCtrl.text.trim().isEmpty ? null : _studentIdCtrl.text.trim(),
        firstName: _firstNameCtrl.text.trim(),
        middleName: _middleNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        organization: _organization,
        position: _position,
        course: _course,
        yearSection: _section,
        platform: _platformCtrl.text.trim(),
        candidateType: _candidateType,
        partyName: _candidateType == 'Political Party' ? _partyNameCtrl.text.trim() : null,
        photoFilePath: _photo?.path,
        partyLogoFilePath: null,
      );
      final success = res['success'] == true;
      final msg = (res['message'] ?? (success ? 'Candidate updated' : 'Failed to update')).toString();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      if (success) {
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network error')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Candidate'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _studentIdCtrl,
              decoration: const InputDecoration(labelText: 'Student ID'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _firstNameCtrl,
              decoration: const InputDecoration(labelText: 'First Name'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _middleNameCtrl,
              decoration: const InputDecoration(labelText: 'Middle Name'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _lastNameCtrl,
              decoration: const InputDecoration(labelText: 'Last Name'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _organization,
              decoration: const InputDecoration(labelText: 'Organization'),
              items: _orgOptions
                  .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                  .toList(),
              onChanged: (v) => setState(() {
                _organization = v;
                // reset dependent
                if (!(( _positionsByOrg[_organization]?.contains(_position) ) ?? false)) {
                  _position = null;
                }
              }),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _position,
              decoration: const InputDecoration(labelText: 'Position'),
              items: (_positionsByOrg[_organization] ?? const <String>[]) 
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (v) => setState(() => _position = v),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _course,
              decoration: const InputDecoration(labelText: 'Program/Course'),
              items: _courseOptions
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() {
                _course = v;
                if (!(_sectionsByCourse[_course]?.contains(_section) ?? false)) {
                  _section = null;
                }
              }),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _section,
              decoration: const InputDecoration(labelText: 'Year & Section'),
              items: (_sectionsByCourse[_course] ?? const <String>[])
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _section = v),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _candidateType,
              decoration: const InputDecoration(labelText: 'Candidate Type'),
              items: const [
                DropdownMenuItem(value: 'Independent', child: Text('Independent')),
                DropdownMenuItem(value: 'Political Party', child: Text('Political Party')),
              ],
              onChanged: (v) => setState(() => _candidateType = v),
            ),
            const SizedBox(height: 8),
            if (_candidateType == 'Political Party') ...[
              TextFormField(
                controller: _partyNameCtrl,
                decoration: const InputDecoration(labelText: 'Party Name'),
                readOnly: true,
                enableInteractiveSelection: false,
              ),
              const SizedBox(height: 8),
            ],
            TextFormField(
              controller: _platformCtrl,
              decoration: const InputDecoration(labelText: 'Platform'),
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _picking ? null : _pickPhoto,
                    icon: const Icon(Icons.photo),
                    label: Text(_photo == null ? 'Change Photo (optional)' : 'Photo selected'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: Text(_submitting ? 'Saving...' : 'Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
