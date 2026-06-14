import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/offline_analysis_sync_service.dart';
import 'about_screen.dart';
import 'batch_analysis_screen.dart';
import 'history_screen.dart';
import 'health_assistant_screen.dart';
import 'image_upload_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  Timer? _syncTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncPendingAnalyses();
    _syncTimer = Timer.periodic(
      const Duration(seconds: 45),
      (_) => _syncPendingAnalyses(),
    );
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncPendingAnalyses();
    }
  }

  Future<void> _syncPendingAnalyses() async {
    await OfflineAnalysisSyncService.instance.syncPendingAnalyses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Malaria Detection'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 24),
            _HomeAction(
              icon: Icons.photo_library,
              label: 'Upload Image',
              onTap: () => _openUpload(context, ImageSource.gallery),
            ),
            _HomeAction(
              icon: Icons.camera_alt,
              label: 'Capture Image',
              onTap: () => _openUpload(context, ImageSource.camera),
            ),
            _HomeAction(
              icon: Icons.collections,
              label: 'Batch Analysis',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BatchAnalysisScreen(),
                  ),
                );
              },
            ),
            _HomeAction(
              icon: Icons.chat,
              label: 'AI Health Assistant',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HealthAssistantScreen(),
                  ),
                );
              },
            ),
            _HomeAction(
              icon: Icons.history,
              label: 'View Result History',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                );
              },
            ),
            _HomeAction(
              icon: Icons.info,
              label: 'About App',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AboutScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return FutureBuilder<User?>(
      future: AuthService.instance.currentUser(),
      builder: (context, snapshot) {
        final fullName = snapshot.data?.fullName ?? 'Welcome';
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFE6FFFB),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.health_and_safety,
                color: Color(0xFF087F7A),
                size: 42,
              ),
              const SizedBox(height: 18),
              Text(
                'Hello, $fullName',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Upload or capture a blood smear image to screen for malaria entirely on the device, with saved history and optional sync support.',
                style: TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 15,
                  height: 1.45,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openUpload(BuildContext context, ImageSource source) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ImageUploadScreen(initialSource: source),
      ),
    );
  }
}

class _HomeAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HomeAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6FFFB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: const Color(0xFF087F7A)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
