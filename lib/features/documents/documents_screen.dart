import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../../core/widgets/theme_toggle.dart';
import '../../services/local_notification_service.dart';
import '../../core/widgets/animations.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});
  @override State<DocumentsScreen> createState() => _State();
}

class _State extends State<DocumentsScreen> {
  bool _connecting = false;
  bool _isDigiLockerConnected = false;
  bool _fetchingDocs = false;
  late ScrollController _scrollController;
  bool _showBackToTop = false;

  final Map<String, ({String? path, bool isVerified, String? expiry})> _docs = {
    'Driver\'s Licence': (path: null, isVerified: false, expiry: null),
    'Vehicle Registration (RC)': (path: null, isVerified: false, expiry: null),
    'Aadhar Card / Identity Proof': (path: null, isVerified: false, expiry: null),
    'Vehicle Insurance Policy': (path: null, isVerified: false, expiry: null),
    'Health Insurance Card': (path: null, isVerified: false, expiry: null),
    'PUC Certificate': (path: null, isVerified: false, expiry: null),
    'RSA Membership': (path: null, isVerified: false, expiry: null),
    'Medical Report': (path: null, isVerified: false, expiry: null),
  };

  // Controllers for Insurance/Expiry specific fields
  final _policyNum = TextEditingController();
  final _provider = TextEditingController();
  final _expiryCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      final show = _scrollController.offset > 300;
      if (show != _showBackToTop) {
        setState(() => _showBackToTop = show);
      }
    });
  }

  @override
  void dispose() {
    _policyNum.dispose();
    _provider.dispose();
    _expiryCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Documents synchronized')),
      );
    }
  }

  Future<void> _pick(String key) async {
    final needsPolicy = key == 'Vehicle Insurance Policy';
    final needsExpiry = ['Driver\'s Licence', 'Vehicle Insurance Policy', 'PUC Certificate'].contains(key);
    
    if (needsPolicy || needsExpiry) {
      _showDetailsDialog(key, needsPolicy, needsExpiry);
    } else {
      final img = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (img != null) {
        setState(() => _docs[key] = (path: img.path, isVerified: false, expiry: null));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$key uploaded successfully')),
          );
        }
      }
    }
  }

  void _showDetailsDialog(String key, bool needsPolicy, bool needsExpiry) {
    _expiryCtrl.clear();
    _policyNum.clear();
    _provider.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Details for $key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (needsPolicy) ...[
              TextField(controller: _provider, decoration: const InputDecoration(labelText: 'Provider Name')),
              const SizedBox(height: 8),
              TextField(controller: _policyNum, decoration: const InputDecoration(labelText: 'Policy Number')),
              const SizedBox(height: 8),
            ],
            if (needsExpiry)
              TextField(
                controller: _expiryCtrl, 
                decoration: const InputDecoration(labelText: 'Expiry Date (DD/MM/YYYY)', hintText: '31/12/2025'),
                keyboardType: TextInputType.datetime,
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final img = await ImagePicker().pickImage(source: ImageSource.gallery);
              if (img != null && mounted) {
                setState(() {
                  _docs[key] = (path: img.path, isVerified: false, expiry: _expiryCtrl.text.isEmpty ? null : _expiryCtrl.text);
                });
                
                if (needsExpiry && _expiryCtrl.text.isNotEmpty) {
                  _scheduleReminder(key, _expiryCtrl.text);
                }
                
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Upload & Save'),
          ),
        ],
      ),
    );
  }

  void _scheduleReminder(String docName, String dateStr) {
    try {
      final date = DateFormat('dd/MM/yyyy').parse(dateStr);
      LocalNotificationService.scheduleExpiryReminder(
        docName.hashCode.abs(), 
        docName, 
        "Your $docName", 
        date
      );
    } catch (e) {
      // Invalid date format
    }
  }

  void _viewDoc(String name, String path) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(name),
            leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
          ),
          body: Center(
            child: Hero(
              tag: 'doc_$name',
              child: path.startsWith('DIGILOCKER') 
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.verified_user_rounded, size: 80, color: Color(0xFF3FB950)),
                      const SizedBox(height: 16),
                      Text('Verified $name', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Text('Official Government Record', style: TextStyle(color: Color(0xFF7D8590))),
                    ],
                  )
                : InteractiveViewer(child: Image.file(File(path))),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _shareEmergencyDocs() async {
    final List<XFile> filesToShare = [];
    String text = "Emergency Documents from CrashGuard:\n";
    
    _docs.forEach((name, data) {
      if (data.path != null && !data.path!.startsWith('DIGILOCKER')) {
        filesToShare.add(XFile(data.path!));
      } else if (data.isVerified) {
        text += "• $name: Verified via DigiLocker\n";
      }
    });

    if (_policyNum.text.isNotEmpty) {
      text += "• Insurance Policy: ${_policyNum.text} (${_provider.text})\n";
    }

    if (filesToShare.isEmpty && text.length < 50) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No documents uploaded to share')));
      return;
    }

    if (filesToShare.isNotEmpty) {
      await Share.shareXFiles(filesToShare, text: text);
    } else {
      await Share.share(text);
    }
  }

  Future<void> _connectDigiLocker() async {
    setState(() => _connecting = true);
    await Future.delayed(const Duration(milliseconds: 2000));
    if (mounted) {
      setState(() {
        _connecting = false;
        _isDigiLockerConnected = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connected to DigiLocker India')),
      );
    }
  }

  Future<void> _fetchFromDigiLocker() async {
    setState(() => _fetchingDocs = true);
    // Simulate API calls to fetch issued documents (RC and DL)
    await Future.delayed(const Duration(milliseconds: 2500));
    if (mounted) {
      setState(() {
        _fetchingDocs = false;
        _docs['Vehicle Registration (RC)'] = (path: 'DIGILOCKER_RC_VERIFIED', isVerified: true, expiry: null);
        _docs['Driver\'s Licence'] = (path: 'DIGILOCKER_DL_VERIFIED', isVerified: true, expiry: '15/06/2030');
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verified RC and Driving Licence fetched successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    floatingActionButton: _showBackToTop
        ? FadeInTranslate(
            offset: const Offset(0, 10),
            child: FloatingActionButton(
              mini: true,
              backgroundColor: const Color(0xFFE05252),
              onPressed: () {
                _scrollController.animateTo(0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic);
              },
              child: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
            ),
          )
        : null,
    body: RefreshIndicator(
      onRefresh: _onRefresh,
      color: const Color(0xFFE05252),
      displacement: 80,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverAppBar(
            expandedHeight: 120.0,
            pinned: true,
            stretch: true,
            centerTitle: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            leading: const ThemeToggle(),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_rounded, color: Color(0xFFE05252)),
                onPressed: _shareEmergencyDocs,
                tooltip: 'Emergency Share',
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text('Documents',
                  style: TextStyle(
                      color: Theme.of(context).textTheme.titleLarge?.color,
                      fontWeight: FontWeight.bold)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFFE05252).withValues(alpha: 0.1),
                      Theme.of(context).scaffoldBackgroundColor,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // DigiLocker Connection Card
                FadeInTranslate(
                  delay: const Duration(milliseconds: 100),
                  child: BouncingWidget(
                    onTap: _isDigiLockerConnected 
                        ? (_fetchingDocs ? null : _fetchFromDigiLocker)
                        : _connectDigiLocker,
                    child: _buildDigiLockerCard(),
                  ),
                ),
                
                const SizedBox(height: 24),
                const FadeInTranslate(
                  delay: Duration(milliseconds: 150),
                  child: Text('Official & Personal Documents', 
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF7D8590))),
                ),
                const SizedBox(height: 12),
                
                ..._docs.entries.indexed.map((item) {
                  final i = item.$1;
                  final e = item.$2;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: FadeInTranslate(
                      delay: Duration(milliseconds: 200 + (i * 50)),
                      child: BouncingWidget(
                        onTap: e.value.path != null ? () => _viewDoc(e.key, e.value.path!) : () => _pick(e.key),
                        child: _buildDocTile(e.key, e.value),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildDigiLockerCard() {
    return GestureDetector(
      onTap: _isDigiLockerConnected 
          ? (_fetchingDocs ? null : _fetchFromDigiLocker)
          : _connectDigiLocker,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: _isDigiLockerConnected 
                ? const Color(0xFF3FB950).withValues(alpha: 0.05)
                : const Color(0xFF58A6FF).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _isDigiLockerConnected 
                ? const Color(0xFF3FB950).withValues(alpha: 0.3)
                : const Color(0xFF58A6FF).withValues(alpha: 0.3))),
        child: Row(children: [
          if (_connecting || _fetchingDocs)
            const SizedBox(width: 24, height: 24, 
                child: CircularProgressIndicator(strokeWidth: 2))
          else 
            Icon(_isDigiLockerConnected ? Icons.verified_user_rounded : Icons.cloud_queue_rounded,
                color: _isDigiLockerConnected ? const Color(0xFF3FB950) : const Color(0xFF58A6FF)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('DigiLocker India', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(_isDigiLockerConnected 
                ? (_fetchingDocs ? 'Fetching documents...' : 'Connected • Tap to fetch RC/DL') 
                : 'Fetch official govt. documents',
                style: TextStyle(color: _isDigiLockerConnected ? const Color(0xFF3FB950) : const Color(0xFF7D8590), fontSize: 12)),
          ])),
          if (!_isDigiLockerConnected && !_connecting)
            const Icon(Icons.link_rounded, color: Color(0xFF58A6FF)),
          if (_isDigiLockerConnected && !_fetchingDocs)
            const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF3FB950)),
        ]),
      ),
    );
  }

  Widget _buildDocTile(String name, ({String? path, bool isVerified, String? expiry}) data) {
    final bool hasFile = data.path != null;
    final isInsurance = name == 'Vehicle Insurance Policy';
    
    return Hero(
      tag: 'doc_$name',
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor)),
          child: Column(
            children: [
              Row(children: [
                Icon(hasFile ? Icons.check_circle_rounded : Icons.upload_file_rounded,
                    color: hasFile ? const Color(0xFF3FB950) : const Color(0xFF7D8590)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (data.isVerified)
                    const Row(children: [
                      Icon(Icons.verified_rounded, size: 12, color: Color(0xFF3FB950)),
                      SizedBox(width: 4),
                      Text('Verified via DigiLocker', 
                          style: TextStyle(color: Color(0xFF3FB950), fontSize: 11, fontWeight: FontWeight.bold)),
                    ])
                  else
                    Text(hasFile ? 'Uploaded locally • Tap to view' : 'Tap to upload',
                        style: const TextStyle(color: Color(0xFF7D8590), fontSize: 12)),
                ])),
                if (hasFile)
                  const Icon(Icons.visibility_rounded, size: 18, color: Color(0xFF7D8590))
                else if (!data.isVerified)
                  const Icon(Icons.chevron_right_rounded, color: Color(0xFF7D8590)),
              ]),
              if (hasFile && (data.expiry != null || (isInsurance && _policyNum.text.isNotEmpty))) ...[
                const Divider(height: 24),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  if (isInsurance && _policyNum.text.isNotEmpty)
                    _infoBadge('Policy: ${_policyNum.text}'),
                  if (data.expiry != null)
                    _infoBadge('Expires: ${data.expiry}', isExpiry: true),
                ]),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoBadge(String text, {bool isExpiry = false}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: (isExpiry ? const Color(0xFFE05252) : const Color(0xFF58A6FF)).withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(text, style: TextStyle(fontSize: 10, color: isExpiry ? const Color(0xFFE05252) : const Color(0xFF58A6FF), fontWeight: FontWeight.w500)),
  );
}
