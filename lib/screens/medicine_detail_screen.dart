import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../backend/models/medicine.dart';
import '../backend/services/dose_window.dart';
import '../app_state.dart';
import '../theme/app_theme.dart';
import 'add_medicine_screen.dart';

class MedicineDetailScreen extends StatelessWidget {
  static const String routeName = '/medicine_detail';

  const MedicineDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final medicine = ModalRoute.of(context)!.settings.arguments as Medicine?;
    if (medicine == null) {
      return const Scaffold(
        body: Center(child: Text('No medicine selected')),
      );
    }
    return _MedicineDetailView(medicine: medicine);
  }
}

class _MedicineDetailView extends StatefulWidget {
  final Medicine medicine;

  const _MedicineDetailView({required this.medicine});

  @override
  State<_MedicineDetailView> createState() => _MedicineDetailViewState();
}

class _MedicineDetailViewState extends State<_MedicineDetailView> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Medicine get medicine => widget.medicine;

  static const List<Color> _accentColors = [
    AppColors.primary,
    AppColors.success,
    AppColors.secondary,
    AppColors.warning,
    Color(0xFF4FACFE),
  ];

  Color get _accent =>
      _accentColors[medicine.colorIndex % _accentColors.length];

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: _accent,
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
            actions: [
              GestureDetector(
                onTap: () {
                  Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          AddMedicineScreen(editingMedicine: medicine),
                    ),
                  ).then((didEdit) {
                    if (didEdit == true && context.mounted) {
                      Navigator.of(context).pop();
                    }
                  });
                },
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(38),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.edit_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
              GestureDetector(
                onTap: () => _showDeleteDialog(context, state),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(38),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete_outline,
                      color: Colors.white, size: 20),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_accent, _accent.withAlpha(204)],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 48),
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(38),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                            color: Colors.white.withAlpha(77), width: 2),
                      ),
                      child: Center(
                        child: Text(
                          medicine.type.icon,
                          style: const TextStyle(fontSize: 44),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      medicine.name,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (medicine.dose.isNotEmpty)
                      Text(
                        medicine.dose,
                        style: GoogleFonts.poppins(
                          color: Colors.white.withAlpha(204),
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StatusBanner(medicine: medicine),
                  const SizedBox(height: 20),
                  _InfoGrid(medicine: medicine),
                  if (medicine.notes != null &&
                      medicine.notes!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _NotesCard(notes: medicine.notes!),
                  ],
                  const SizedBox(height: 20),
                  if (medicine.isPending) ...[
                    _TakeAction(
                      medicine: medicine,
                      onTake: () => _takeMedicine(context, state),
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _takeMedicine(BuildContext context, AppState state) async {
    await state.takeMedicine(medicine.id);
    if (context.mounted) Navigator.of(context).pop();
  }

  void _showDeleteDialog(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Delete Medicine',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Remove "${medicine.name}" permanently?',
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
              await state.deleteMedicine(medicine.id);
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
              }
            },
            child: Text('Delete',
                style: GoogleFonts.poppins(
                    color: AppColors.error, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final Medicine medicine;

  const _StatusBanner({required this.medicine});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;
    String label;

    switch (medicine.status) {
      case MedicineStatus.taken:
        bg = AppColors.success.withAlpha(26);
        fg = AppColors.success;
        icon = Icons.check_circle_rounded;
        label = 'Taken on time — Great job! 🎉';
        break;
      case MedicineStatus.missed:
        bg = AppColors.error.withAlpha(26);
        fg = AppColors.error;
        icon = Icons.cancel_rounded;
        label = 'This dose was missed';
        break;
      case MedicineStatus.takenLate:
        bg = AppColors.warning.withAlpha(38);
        fg = AppColors.warningDark;
        icon = Icons.watch_later_rounded;
        label = 'Taken late — try to be on time next time';
        break;
      case MedicineStatus.pending:
        bg = AppColors.primary.withAlpha(20);
        fg = AppColors.primary;
        icon = Icons.access_time_rounded;
        final window = DoseWindowHelper.compute(medicine.time);
        label = switch (window) {
          DoseWindow.beforeWindow => () {
              final until = DoseWindowHelper.timeUntilWindowOpens(medicine.time);
              final h = until.inHours;
              final m = until.inMinutes % 60;
              final s = until.inSeconds % 60;
              final cd = h > 0 ? '${h}h ${m}m' : m > 0 ? '${m}m ${s}s' : '${s}s';
              return 'Available in $cd · Scheduled for ${medicine.time}';
            }(),
          DoseWindow.inWindow =>
            'Take now — window open until 1 hour after ${medicine.time}',
          DoseWindow.lateWindow =>
            'Overdue — please take as soon as possible',
          DoseWindow.missed => 'Dose window has passed',
        };
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Icon(icon, color: fg, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                  color: fg, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  final Medicine medicine;

  const _InfoGrid({required this.medicine});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _InfoTile(
          icon: Icons.access_time_rounded,
          label: 'Time',
          value: medicine.time,
          color: AppColors.primary,
        ),
        _InfoTile(
          icon: Icons.medication_rounded,
          label: 'Type',
          value: medicine.type.label,
          color: AppColors.success,
        ),
        _InfoTile(
          icon: Icons.repeat_rounded,
          label: 'Schedule',
          value: medicine.repeatSummary,
          color: AppColors.secondary,
        ),
        _InfoTile(
          icon: Icons.medical_services_outlined,
          label: 'Dose',
          value: medicine.dose.isNotEmpty ? medicine.dose : 'Not set',
          color: AppColors.warning,
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.themed(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: context.textPrimaryColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: context.textLightColor,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  final String notes;

  const _NotesCard({required this.notes});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.themed(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notes_rounded,
                  color: context.textSecondaryColor, size: 18),
              const SizedBox(width: 8),
              Text(
                'Notes',
                style: GoogleFonts.poppins(
                  color: context.textSecondaryColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            notes,
            style: GoogleFonts.poppins(
              color: context.textPrimaryColor,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _TakeAction extends StatelessWidget {
  final Medicine medicine;
  final VoidCallback onTake;

  const _TakeAction({required this.medicine, required this.onTake});

  @override
  Widget build(BuildContext context) {
    final window = DoseWindowHelper.compute(medicine.time);

    if (window == DoseWindow.beforeWindow) {
      final until = DoseWindowHelper.timeUntilWindowOpens(medicine.time);
      final h = until.inHours;
      final m = until.inMinutes % 60;
      final s = until.inSeconds % 60;
      final countdown = h > 0 ? '${h}h ${m}m' : m > 0 ? '${m}m ${s}s' : '${s}s';
      return Container(
        height: 54,
        decoration: BoxDecoration(
          color: context.textLightColor.withAlpha(30),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'Available in $countdown',
            style: GoogleFonts.poppins(
              color: context.textLightColor,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    if (window == DoseWindow.missed) {
      return Container(
        height: 54,
        decoration: BoxDecoration(
          color: AppColors.error.withAlpha(20),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.error.withAlpha(77)),
        ),
        child: Center(
          child: Text(
            'Dose window has passed',
            style: GoogleFonts.poppins(
              color: AppColors.error,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    final isLate = window == DoseWindow.lateWindow;
    return GestureDetector(
      onTap: onTake,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          gradient: isLate ? null : AppColors.primaryGradient,
          color: isLate ? AppColors.warning.withAlpha(38) : null,
          borderRadius: BorderRadius.circular(16),
          border: isLate
              ? Border.all(color: AppColors.warning.withAlpha(102))
              : null,
          boxShadow: isLate
              ? null
              : [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(77),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isLate
                    ? Icons.watch_later_rounded
                    : Icons.check_circle_rounded,
                color: isLate ? AppColors.warningDark : Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isLate ? 'Take (Late)' : 'Take Medicine',
                style: GoogleFonts.poppins(
                  color: isLate ? AppColors.warningDark : Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
