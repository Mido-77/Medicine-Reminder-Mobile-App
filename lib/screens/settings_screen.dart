import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_state.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  static const String routeName = '/settings';

  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            backgroundColor: AppColors.primary,
            leading: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(38),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back_ios_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Settings',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel('Notifications'),
                  const SizedBox(height: 8),
                  _SettingsCard(
                    children: [
                      _SwitchTile(
                        icon: Icons.notifications_rounded,
                        label: 'Reminder Notifications',
                        subtitle: 'Get notified before your medicine time',
                        color: AppColors.primary,
                        value: state.notificationsEnabled,
                        onChanged: (v) =>
                            state.updateSettings(notifications: v),
                      ),
                      _Divider(),
                      _SwitchTile(
                        icon: Icons.vibration_rounded,
                        label: 'Vibration',
                        subtitle: 'Vibrate on reminder alerts',
                        color: AppColors.success,
                        value: true,
                        onChanged: (_) {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SectionLabel('Reminder Sound'),
                  const SizedBox(height: 8),
                  _SettingsCard(
                    children: _buildSoundOptions(state),
                  ),
                  const SizedBox(height: 20),
                  _SectionLabel('Appearance'),
                  const SizedBox(height: 8),
                  _SettingsCard(
                    children: [
                      _SwitchTile(
                        icon: Icons.dark_mode_rounded,
                        label: 'Dark Mode',
                        subtitle: 'Switch to dark theme',
                        color: const Color(0xFF4A4A8A),
                        value: state.darkMode,
                        onChanged: (v) => state.updateSettings(darkMode: v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SectionLabel('Data'),
                  const SizedBox(height: 8),
                  _SettingsCard(
                    children: [
                      _TapTile(
                        icon: Icons.backup_rounded,
                        label: 'Backup Data',
                        subtitle: 'Export your medicine data',
                        color: AppColors.success,
                        onTap: () => _showSnack(context, 'Backup coming soon!'),
                      ),
                      _Divider(),
                      _TapTile(
                        icon: Icons.restore_rounded,
                        label: 'Restore Data',
                        subtitle: 'Import from backup',
                        color: AppColors.warning,
                        onTap: () => _showSnack(context, 'Restore coming soon!'),
                      ),
                      _Divider(),
                      _TapTile(
                        icon: Icons.delete_forever_rounded,
                        label: 'Clear All Data',
                        subtitle: 'Remove all medicines and history',
                        color: AppColors.error,
                        onTap: () => _confirmClear(context, state),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SectionLabel('About'),
                  const SizedBox(height: 8),
                  _SettingsCard(
                    children: [
                      _InfoTile(label: 'Version', value: '1.0.0'),
                      _Divider(),
                      _InfoTile(label: 'Build', value: '2025.04.24'),
                      _Divider(),
                      _TapTile(
                        icon: Icons.star_rounded,
                        label: 'Rate MediCare',
                        subtitle: 'Tell us what you think',
                        color: AppColors.warning,
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSoundOptions(AppState state) {
    const sounds = ['Default', 'Chime', 'Bell', 'Silent'];
    final List<Widget> widgets = [];
    for (int i = 0; i < sounds.length; i++) {
      final s = sounds[i];
      widgets.add(
        Builder(
          builder: (context) => GestureDetector(
            onTap: () => state.updateSettings(reminderSound: s),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    s == 'Silent'
                        ? Icons.volume_off_rounded
                        : Icons.music_note_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      s,
                      style: GoogleFonts.poppins(
                        color: context.textPrimaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (state.reminderSound == s)
                    const Icon(Icons.check_circle_rounded,
                        color: AppColors.primary, size: 20),
                ],
              ),
            ),
          ),
        ),
      );
      if (i < sounds.length - 1) widgets.add(_Divider());
    }
    return widgets;
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins()),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _confirmClear(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Clear All Data',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text(
          'This will delete all your medicines and history. This cannot be undone.',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await state.clearAllData();
            },
            child: Text('Clear',
                style: GoogleFonts.poppins(
                    color: AppColors.error, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ─── Reusable Widgets ────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.poppins(
        color: context.textLightColor,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.themed(context),
      ),
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      color: context.dividerColorThemed,
      indent: 56,
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: context.textPrimaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    color: context.textLightColor,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: color,
            activeTrackColor: color.withAlpha(128),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}

class _TapTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _TapTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withAlpha(26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      color: label.contains('Clear')
                          ? AppColors.error
                          : context.textPrimaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      color: context.textLightColor,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: context.textLightColor, size: 20),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: context.textPrimaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: context.textSecondaryColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
