import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import '../../providers/providers.dart';
import 'health_model.dart';
import '../../core/widgets/animations.dart';
import '../../core/widgets/theme_toggle.dart';

class HealthProfileScreen extends ConsumerStatefulWidget {
  const HealthProfileScreen({super.key});
  @override ConsumerState<HealthProfileScreen> createState() => _State();
}

class _State extends ConsumerState<HealthProfileScreen> {
  final _name    = TextEditingController();
  final _day     = TextEditingController();
  final _month   = TextEditingController();
  final _year    = TextEditingController();
  String? _selectedBlood;
  final _emName  = TextEditingController();
  final _emPhone = TextEditingController();
  final _allergyCtrl = TextEditingController();
  final _conditionCtrl = TextEditingController();
  List<String> _allergies = [];
  List<String> _conditions = [];
  bool _saving = false;

  final List<String> _bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];

  @override
  void initState() {
    super.initState();
    final p = ref.read(healthServiceProvider).getProfile();
    if (p != null) {
      _name.text = p.name;
      _parseDob(p.dob);
      if (_bloodGroups.contains(p.bloodType)) {
        _selectedBlood = p.bloodType;
      }
      _emName.text = p.emergencyContact; _emPhone.text = p.emergencyPhone;
      _allergies = List.from(p.allergies);
      _conditions = List.from(p.chronicConditions);
    }
  }

  void _parseDob(String dob) {
    // Expected format YYYY-MM-DD
    final parts = dob.split('-');
    if (parts.length == 3) {
      _year.text = parts[0];
      _month.text = parts[1];
      _day.text = parts[2];
    }
  }

  Future<void> _pickContact() async {
    try {
      // Request permission explicitly to avoid SecurityException crash
      final status = await Permission.contacts.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Contacts permission is required to pick a contact')),
          );
        }
        return;
      }

      // openExternalPick() launches the system picker
      final contact = await FlutterContacts.openExternalPick();
      if (contact != null) {
        // Fetch full contact to get phone numbers
        final full = await FlutterContacts.getContact(contact.id);
        if (full != null) {
          setState(() {
            _emName.text = full.displayName;
            if (full.phones.isNotEmpty) {
              _emPhone.text = full.phones.first.number;
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking contact: $e')),
        );
      }
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final dob = '${_year.text}-${_month.text.padLeft(2, '0')}-${_day.text.padLeft(2, '0')}';
    final profile = HealthProfile(
      name: _name.text.trim(), dob: dob,
      bloodType: _selectedBlood ?? '', allergies: _allergies,
      chronicConditions: _conditions,
      emergencyContact: _emName.text.trim(),
      emergencyPhone: _emPhone.text.trim(),
      deviceId: const Uuid().v4(),
    );
    // Save locally only — no server call
    await ref.read(healthServiceProvider).saveProfile(profile);
    if (mounted) { 
      setState(() => _saving = false); 
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile saved successfully'),
          backgroundColor: Color(0xFF3FB950),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    }
  }

  Future<bool> _onWillPop() async {
    final currentProfile = HealthProfile(
      name: _name.text.trim(),
      dob: '${_year.text}-${_month.text.padLeft(2, '0')}-${_day.text.padLeft(2, '0')}',
      bloodType: _selectedBlood ?? '',
      allergies: _allergies,
      chronicConditions: _conditions,
      emergencyContact: _emName.text.trim(),
      emergencyPhone: _emPhone.text.trim(),
      deviceId: '', // Not relevant for comparison
    );

    final saved = ref.read(healthServiceProvider).getProfile();
    final bool hasChanged = saved == null || 
        saved.name != currentProfile.name ||
        saved.dob != currentProfile.dob ||
        saved.bloodType != currentProfile.bloodType ||
        saved.emergencyContact != currentProfile.emergencyContact ||
        saved.emergencyPhone != currentProfile.emergencyPhone ||
        saved.allergies.length != _allergies.length ||
        saved.chronicConditions.length != _conditions.length;

    if (hasChanged && !_saving) {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unsaved Changes'),
          content: const Text('You have unsaved changes. Are you sure you want to leave?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Stay')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE05252)),
              child: const Text('Discard'),
            ),
          ],
        ),
      );
      return result ?? false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // Determine if we can pop without a dialog
    final saved = ref.read(healthServiceProvider).getProfile();
    final bool hasChanged = saved == null || 
        saved.name != _name.text.trim() ||
        saved.dob != '${_year.text}-${_month.text.padLeft(2, '0')}-${_day.text.padLeft(2, '0')}' ||
        saved.bloodType != (_selectedBlood ?? '') ||
        saved.emergencyContact != _emName.text.trim() ||
        saved.emergencyPhone != _emPhone.text.trim() ||
        saved.allergies.length != _allergies.length ||
        saved.chronicConditions.length != _conditions.length;

    final canPop = !hasChanged || _saving;

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: const ThemeToggle(),
          title: const Hero(
            tag: 'medical_info_card',
            child: Material(
              color: Colors.transparent,
              child: Text('Health Profile'),
            ),
          ),
          centerTitle: true,
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: const Color(0xFF3FB950).withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(6)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.offline_bolt_rounded, size: 12, color: Color(0xFF3FB950)),
                SizedBox(width: 4),
                Text('Offline', style: TextStyle(fontSize: 11, color: Color(0xFF3FB950))),
              ]),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          children: [
            FadeInTranslate(delay: const Duration(milliseconds: 100), child: _field('Full Name', _name, Icons.person_rounded)),
            FadeInTranslate(
              delay: const Duration(milliseconds: 150),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Date of Birth', style: TextStyle(fontSize: 12, color: Color(0xFF7D8590))),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: _dobBlock('DD', _day)),
                  const SizedBox(width: 12),
                  Expanded(child: _dobBlock('MM', _month)),
                  const SizedBox(width: 12),
                  Expanded(child: _dobBlock('YYYY', _year, flex: 2)),
                ]),
              ]),
            ),
            const SizedBox(height: 16),
            FadeInTranslate(
              delay: const Duration(milliseconds: 200),
              child: DropdownButtonFormField<String>(
                initialValue: _selectedBlood,
                decoration: const InputDecoration(
                  labelText: 'Blood Group',
                  prefixIcon: Icon(Icons.bloodtype_rounded, size: 20),
                ),
                items: _bloodGroups
                    .map((group) => DropdownMenuItem(
                          value: group,
                          child: Text(group),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _selectedBlood = val),
              ),
            ),
            const SizedBox(height: 16),
            FadeInTranslate(
              delay: const Duration(milliseconds: 250),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Allergies', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 4, children: [
                  ..._allergies.map((a) => Chip(
                      label: Text(a),
                      deleteIconColor: const Color(0xFFE05252),
                      onDeleted: () => setState(() => _allergies.remove(a)))),
                  ActionChip(
                    label: const Text('+ Add'),
                    onPressed: () => showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                              title: const Text('Add Allergy'),
                              content: TextField(
                                  controller: _allergyCtrl,
                                  decoration: const InputDecoration(hintText: 'e.g. penicillin')),
                              actions: [
                                TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      if (_allergyCtrl.text.isNotEmpty) {
                                        setState(() {
                                          _allergies.add(_allergyCtrl.text.trim());
                                          _allergyCtrl.clear();
                                        });
                                      }
                                    },
                                    child: const Text('Add'))
                              ],
                            )),
                  ),
                ]),
              ]),
            ),
            const SizedBox(height: 16),
            FadeInTranslate(
              delay: const Duration(milliseconds: 300),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Chronic Conditions', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 4, children: [
                  ..._conditions.map((c) => Chip(
                      label: Text(c),
                      deleteIconColor: const Color(0xFFE05252),
                      onDeleted: () => setState(() => _conditions.remove(c)))),
                  ActionChip(
                    label: const Text('+ Add'),
                    onPressed: () => showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                              title: const Text('Add Condition'),
                              content: TextField(
                                  controller: _conditionCtrl,
                                  decoration: const InputDecoration(hintText: 'e.g. Diabetes')),
                              actions: [
                                TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      if (_conditionCtrl.text.isNotEmpty) {
                                        setState(() {
                                          _conditions.add(_conditionCtrl.text.trim());
                                          _conditionCtrl.clear();
                                        });
                                      }
                                    },
                                    child: const Text('Add'))
                              ],
                            )),
                  ),
                ]),
              ]),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),
            FadeInTranslate(
              delay: const Duration(milliseconds: 350),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Emergency Contact', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _field('Contact Name', _emName, Icons.contacts_rounded,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.contact_page_rounded, color: Color(0xFF58A6FF)),
                      onPressed: _pickContact,
                      tooltip: 'Select from contacts',
                    )),
                _field('Phone Number', _emPhone, Icons.phone_rounded, type: TextInputType.phone),
              ]),
            ),
            const SizedBox(height: 8),
            const Text('Saved locally on device — no internet required', style: TextStyle(fontSize: 11, color: Color(0xFF7D8590))),
            const SizedBox(height: 28),
            FadeInTranslate(
              delay: const Duration(milliseconds: 400),
              child: BouncingWidget(
                onTap: _saving ? null : _save,
                child: ElevatedButton(
                  onPressed: _saving ? null : () {}, // Handled by BouncingWidget
                  child: _saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save Profile'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, IconData icon,
      {TextInputType type = TextInputType.text, Widget? suffixIcon}) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: ctrl, keyboardType: type,
        decoration: InputDecoration(labelText: label,
            prefixIcon: Icon(icon, size: 20),
            suffixIcon: suffixIcon)));

  Widget _dobBlock(String hint, TextEditingController ctrl, {int flex = 1}) =>
    TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      maxLength: hint.length == 4 ? 4 : 2,
      decoration: InputDecoration(
        hintText: hint,
        counterText: '',
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
}
