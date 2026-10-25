import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/branding/app_branding.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/theme/clay_theme.dart';
import '../../auth/application/auth_providers.dart';
import '../../home/presentation/home_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const Color _coral = Color(0xFFEF4444);
  bool _dueReminders = true;
  bool _classAlerts = true;
  bool _soundEnabled = true;
  String _pingStatus = '';
  bool _isPinging = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  void _loadPrefs() {
    final prefs = ref.read(sharedPreferencesProvider);
    if (prefs != null) {
      setState(() {
        _dueReminders = prefs.getBool('pref_due_reminders') ?? true;
        _classAlerts = prefs.getBool('pref_class_alerts') ?? true;
        _soundEnabled = prefs.getBool('pref_sound') ?? true;
      });
    }
  }

  void _setPref(String key, bool val) {
    final prefs = ref.read(sharedPreferencesProvider);
    prefs?.setBool(key, val);
  }

  Future<void> _testServerConnection() async {
    setState(() {
      _isPinging = true;
      _pingStatus = 'Testing connection...';
    });
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 4),
        receiveTimeout: const Duration(seconds: 4),
      ));
      final res = await dio.get('${ApiConfig.coreBaseUrl}/api/health');
      if (res.statusCode == 200) {
        setState(() {
          _pingStatus = 'Connected! Server is healthy (200 OK)';
        });
      } else {
        setState(() {
          _pingStatus = 'Server replied with status ${res.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _pingStatus = 'Connection error: ${e.toString().split('\n').first}';
      });
    } finally {
      if (mounted) setState(() => _isPinging = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentThemeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Preferences'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          // Section: Appearance
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(
              'APPEARANCE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: ClayTokens.secondaryText,
                letterSpacing: 0.8,
              ),
            ),
          ),
          ClayCard(
            depth: 3,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.palette_rounded,
                        size: 20, color: ClayTokens.deepIndigo),
                    SizedBox(width: 8),
                    Text(
                      'Theme Mode',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.system,
                      label: Text('System'),
                      icon: Icon(Icons.brightness_auto_rounded),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      label: Text('Light'),
                      icon: Icon(Icons.light_mode_rounded),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      label: Text('Dark'),
                      icon: Icon(Icons.dark_mode_rounded),
                    ),
                  ],
                  selected: {currentThemeMode},
                  onSelectionChanged: (selected) {
                    ref
                        .read(themeModeProvider.notifier)
                        .setThemeMode(selected.first);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section: Backend & Services
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(
              'SERVER & SERVICES',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: ClayTokens.secondaryText,
                letterSpacing: 0.8,
              ),
            ),
          ),
          ClayCard(
            depth: 3,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.dns_rounded,
                        size: 20, color: ClayTokens.deepIndigo),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Backend Node.js Core API',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: ClayTokens.deepIndigo.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        ApiConfig.coreBaseUrl,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: ClayTokens.deepIndigo,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.smart_toy_rounded,
                        size: 20, color: ClayTokens.mintDark),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'AI Mentor Service (Port 8001)',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: ClayTokens.mint.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        ApiConfig.mlBaseUrl,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: ClayTokens.mintDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isPinging ? null : _testServerConnection,
                        icon: _isPinging
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.speed_rounded, size: 16),
                        label: const Text('Test Backend Connection'),
                      ),
                    ),
                  ],
                ),
                if (_pingStatus.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    _pingStatus,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _pingStatus.contains('Connected')
                          ? ClayTokens.mintDark
                          : _coral,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section: Notifications
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(
              'NOTIFICATIONS & ALERTS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: ClayTokens.secondaryText,
                letterSpacing: 0.8,
              ),
            ),
          ),
          ClayCard(
            depth: 3,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Assignment Due Reminders',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Notify 24 hours and 2 hours before due dates',
                      style: TextStyle(fontSize: 11)),
                  value: _dueReminders,
                  activeThumbColor: ClayTokens.deepIndigo,
                  onChanged: (val) {
                    setState(() => _dueReminders = val);
                    _setPref('pref_due_reminders', val);
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Class Schedule Alerts',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Alert 15 minutes before virtual lectures begin',
                      style: TextStyle(fontSize: 11)),
                  value: _classAlerts,
                  activeThumbColor: ClayTokens.deepIndigo,
                  onChanged: (val) {
                    setState(() => _classAlerts = val);
                    _setPref('pref_class_alerts', val);
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Sound & Haptic Feedback',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Play subtle sounds on submission and grading',
                      style: TextStyle(fontSize: 11)),
                  value: _soundEnabled,
                  activeThumbColor: ClayTokens.deepIndigo,
                  onChanged: (val) {
                    setState(() => _soundEnabled = val);
                    _setPref('pref_sound', val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section: About
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(
              'ABOUT APPLICATION',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: ClayTokens.secondaryText,
                letterSpacing: 0.8,
              ),
            ),
          ),
          ClayCard(
            depth: 3,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClayContainer(
                      width: 42,
                      height: 42,
                      depth: 3,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6B5EFF), Color(0xFF4335C9)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      child: const Center(
                        child: Icon(Icons.school_rounded,
                            color: Colors.white, size: 22),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppBranding.appName,
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'Version 2.0.0 (Production Build)',
                          style: TextStyle(
                            fontSize: 12,
                            color: ClayTokens.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Unified Learning & Virtual Classroom delivers claymorphic modern UI, role-secured classroom management, automated grading, and an integrated AI Mentor.',
                  style: TextStyle(fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
