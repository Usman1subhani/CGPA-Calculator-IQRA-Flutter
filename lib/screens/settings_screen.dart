import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_info.dart';
import '../app_state.dart';
import '../theme.dart';
import '../widgets/screen_header.dart';
import 'grading_scale_screen.dart';

const _kPrivacyPolicyUrl = String.fromEnvironment('PRIVACY_POLICY_URL');
const _kPlayStoreUrl = String.fromEnvironment('PLAY_STORE_URL');

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '1.0.0 (1)';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() => _version = '${info.version} (${info.buildNumber})');
      }
    } catch (_) {
      // Keep default.
    }
  }

  Future<void> _launch(String url) async {
    if (url.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This link is not configured yet.')),
        );
      }
      return;
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not open $url')));
      }
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open $url')));
    }
  }

  Future<bool> _confirm(
    String title,
    String message, {
    String confirmLabel = 'Confirm',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
          children: [
            const ScreenHeader(title: 'Settings'),
            const SectionLabel('Appearance'),
            SettingsCardTile(
              icon: Icons.brightness_6_rounded,
              iconColor: AppColors.primary,
              title: 'Theme',
              subtitle: 'Follows your device setting by default',
              trailing: DropdownButton<ThemeMode>(
                value: state.themeMode,
                isDense: true,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(
                    value: ThemeMode.system,
                    child: Text('System'),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.light,
                    child: Text('Light'),
                  ),
                  DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                ],
                onChanged: (mode) {
                  if (mode != null) state.setThemeMode(mode);
                },
              ),
            ),
            const SectionLabel('General'),
            SettingsCardTile(
              icon: Icons.school_rounded,
              iconColor: AppColors.primary,
              title: 'Grading Scale',
              subtitle: 'View both admission-batch scales',
              onTap: () => openGradingScaleReference(context),
            ),
            SettingsCardTile(
              icon: Icons.star_rounded,
              iconColor: AppColors.accent,
              title: 'Rate Us',
              subtitle: _kPlayStoreUrl.isEmpty
                  ? 'Available after the app is published'
                  : 'Enjoying the app? Leave a review',
              subtitleColor: theme.colorScheme.primary,
              onTap: () => _launch(_kPlayStoreUrl),
            ),
            SettingsCardTile(
              icon: Icons.share_rounded,
              iconColor: AppColors.primary,
              title: 'Share App',
              onTap: () => SharePlus.instance.share(
                ShareParams(
                  text: _kPlayStoreUrl.isEmpty
                      ? 'Check out ${AppInfo.appName} for GPA & CGPA calculations.'
                      : 'Check out ${AppInfo.appName} for GPA & CGPA calculations: $_kPlayStoreUrl',
                ),
              ),
            ),
            SettingsCardTile(
              icon: Icons.person_rounded,
              iconColor: Colors.deepPurple,
              title: 'About Developer',
              subtitle: AppInfo.developerName,
              onTap: () => showAboutDialog(
                context: context,
                applicationName: AppInfo.appName,
                applicationVersion: _version,
                children: [
                  Text(
                    'An independent student calculator that supports grading scales published by '
                    '${AppInfo.universityName}. It is not affiliated with or endorsed by the university.',
                  ),
                ],
              ),
            ),
            SettingsCardTile(
              icon: Icons.shield_rounded,
              iconColor: AppColors.primary,
              title: 'Privacy Policy',
              subtitle: _kPrivacyPolicyUrl.isEmpty
                  ? 'Configure a public URL before publishing'
                  : null,
              onTap: () => _launch(_kPrivacyPolicyUrl),
            ),
            SettingsCardTile(
              icon: Icons.info_rounded,
              iconColor: Colors.blue,
              title: 'App Version',
              trailing: Text(_version, style: theme.textTheme.bodyMedium),
            ),
            const SectionLabel('Data'),
            SettingsCardTile(
              icon: Icons.delete_rounded,
              iconColor: AppColors.error,
              title: 'Clear Calculation History',
              onTap: () async {
                final ok = await _confirm(
                  'Clear history?',
                  'All saved GPA and CGPA calculations will be deleted.',
                  confirmLabel: 'Clear',
                );
                if (ok) {
                  await state.clearHistory();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('History cleared')),
                    );
                  }
                }
              },
            ),
            SettingsCardTile(
              icon: Icons.restart_alt_rounded,
              iconColor: Colors.orange,
              title: 'Reset Local Storage',
              subtitle: 'Erases all app data and settings',
              onTap: () async {
                final ok = await _confirm(
                  'Reset app data?',
                  'This clears history, theme, and all saved settings. This cannot be undone.',
                  confirmLabel: 'Reset',
                );
                if (ok) {
                  await state.resetAll();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Local storage reset')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
