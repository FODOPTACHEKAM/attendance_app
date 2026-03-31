import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/attendance_provider.dart';
import '../theme.dart';

/// Lecturer dashboard for real-time session monitoring
class LecturerDashboardPage extends StatefulWidget {
  const LecturerDashboardPage({super.key});

  @override
  State<LecturerDashboardPage> createState() => _LecturerDashboardPageState();
}

class _LecturerDashboardPageState extends State<LecturerDashboardPage> {
  @override
  void initState() {
    super.initState();
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        context.read<AttendanceProvider>().refreshRecords();
        _startAutoRefresh();
      }
    });
  }

  Future<void> _regeneratePin() async {
    final provider = context.read<AttendanceProvider>();
    final newPin = await provider.regeneratePin();
    
    if (mounted && newPin != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('New PIN: $newPin')),
      );
    }
  }

  Future<void> _endSession() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Session?'),
        content: const Text(
          'This will close the session and generate the attendance report. Students will no longer be able to register.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('End Session'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final provider = context.read<AttendanceProvider>();
    final filePath = await provider.endSessionAndGenerateReport();

    if (mounted) {
      if (filePath != null) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Session Ended'),
            content: Text('Report saved to:\n$filePath'),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/');
                },
                child: const Text('Done'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Failed to generate report'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Session'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                context.read<AttendanceProvider>().refreshRecords(),
          ),
          IconButton(
            icon: const Icon(Icons.stop),
            onPressed: _endSession,
          ),
        ],
      ),
      body: Consumer<AttendanceProvider>(
        builder: (context, provider, _) {
          final session = provider.activeSession;
          if (session == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No active session'),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton(
                    onPressed: () => context.go('/setup'),
                    child: const Text('Create Session'),
                  ),
                ],
              ),
            );
          }

          final stats = provider.getStats();

          return SingleChildScrollView(
            padding: AppSpacing.paddingMd,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Session Info Card
                _SessionInfoCard(session: session, onRegeneratePin: _regeneratePin),
                const SizedBox(height: AppSpacing.md),

                // Statistics Cards
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Total',
                        value: stats['total'].toString(),
                        icon: Icons.people,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _StatCard(
                        title: 'Verified',
                        value: stats['verified'].toString(),
                        icon: Icons.check_circle,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _StatCard(
                        title: 'Pending',
                        value: stats['pending'].toString(),
                        icon: Icons.pending,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Attendance Heatmap
                Card(
                  child: Padding(
                    padding: AppSpacing.paddingMd,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Real-Time Attendance Heatmap',
                          style: context.textStyles.titleLarge?.semiBold,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (provider.currentRecords.isEmpty)
                          const Padding(
                            padding: AppSpacing.paddingLg,
                            child: Center(
                              child: Text('No students registered yet'),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: provider.currentRecords.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: AppSpacing.sm),
                            itemBuilder: (context, index) {
                              final record = provider.currentRecords[index];
                              return _AttendanceRecordTile(record: record);
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SessionInfoCard extends StatelessWidget {
  final dynamic session;
  final VoidCallback onRegeneratePin;

  const _SessionInfoCard({
    required this.session,
    required this.onRegeneratePin,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.courseName,
                        style: context.textStyles.headlineSmall?.bold,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Started: ${DateFormat('HH:mm').format(session.startTime)}',
                        style: context.textStyles.bodyMedium?.withColor(
                          Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // QR Code for quick access
                Container(
                  padding: AppSpacing.paddingSm,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: QrImageView(
                    data: 'attendance://register?pin=${session.currentPin}',
                    size: 80,
                  ),
                ),
              ],
            ),
            const Divider(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current PIN',
                      style: context.textStyles.labelSmall?.withColor(
                        Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      session.currentPin ?? 'N/A',
                      style: context.textStyles.headlineMedium?.bold.withColor(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                FilledButton.icon(
                  onPressed: onRegeneratePin,
                  icon: const Icon(Icons.refresh),
                  label: const Text('New PIN'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              style: context.textStyles.headlineMedium?.bold.withColor(color),
            ),
            Text(
              title,
              style: context.textStyles.labelSmall?.withColor(
                Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceRecordTile extends StatelessWidget {
  final dynamic record;

  const _AttendanceRecordTile({required this.record});

  @override
  Widget build(BuildContext context) {
    final isVerified = record.isVerified && record.isPinVerified;
    final statusColor = isVerified ? Colors.green : Colors.orange;

    return Container(
      padding: AppSpacing.paddingSm,
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isVerified ? Icons.check_circle : Icons.pending,
            color: statusColor,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.studentName,
                  style: context.textStyles.bodyMedium?.semiBold,
                ),
                Text(
                  'Matricule: ${record.matricule}',
                  style: context.textStyles.bodySmall?.withColor(
                    Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${record.connectionDurationMinutes} min',
                style: context.textStyles.labelMedium?.semiBold,
              ),
              Text(
                DateFormat('HH:mm').format(record.joinedAt),
                style: context.textStyles.labelSmall?.withColor(
                  Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
