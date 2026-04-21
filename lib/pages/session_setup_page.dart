import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/hotspot_service.dart';
import 'captive_editor_page.dart';
import '../providers/attendance_provider.dart';
import '../theme.dart';

/// Page for setting up a new attendance session
class SessionSetupPage extends StatefulWidget {
  const SessionSetupPage({super.key});

  @override
  State<SessionSetupPage> createState() => _SessionSetupPageState();
}

class _SessionSetupPageState extends State<SessionSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _courseNameController = TextEditingController();
  final _gracePeriodController = TextEditingController(text: '5');
  final _connectionTimeController = TextEditingController(text: '15');
  final _gpsRadiusController = TextEditingController(text: '0.1');
  final _maxAttendanceController = TextEditingController(text: '30');

  bool _hasUploadedPrevious = false;
  bool _hotspotActive = false;
  String? _hotspotUrl;
  String _ssid = '';
  String _pass = '12345678';
  bool _isHotspotLoading = false;

  @override
  void dispose() {
    _gpsRadiusController.dispose();
    _gpsRadiusController.dispose();
    _courseNameController.dispose();
    _gracePeriodController.dispose();
    _connectionTimeController.dispose();
    _maxAttendanceController.dispose();
    super.dispose();
  }

  Future<void> _toggleHotspot() async {
    if (_isHotspotLoading) return;
    
    setState(() {
      _isHotspotLoading = true;
    });

    try {
      if (_hotspotActive) {
        await HotspotService.stopHotspot();
        if (mounted) {
          setState(() {
            _hotspotActive = false;
            _hotspotUrl = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Hotspot stopped')),
          );
        }
      } else {
        final course = _courseNameController.text.isNotEmpty ? _courseNameController.text : 'Session';
        final ssid = 'Attendance-$course';
        _ssid = ssid;
        final result = await HotspotService.startHotspot(ssid, _pass);
        final url = await HotspotService.getLocalServerUrl();
        if (mounted) {
          if (result != null) {
            setState(() {
              _hotspotActive = true;
              _hotspotUrl = url;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Hotspot Started!'),
                    Text('SSID: $_ssid'),
                    Text('Pass: $_pass'),
                    Text('Portal: $url'),
                  ],
                ),
                duration: const Duration(seconds: 5),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Hotspot activation may require manual confirmation in settings'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hotspot error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isHotspotLoading = false;
        });
      }
    }
  }

  Future<void> _launchPortal() async {
    final url = _hotspotUrl ?? (await HotspotService.getLocalServerUrl());
    if (url != null) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch portal')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Start hotspot first')),
        );
      }
    }
  }

  Future<void> _uploadPreviousSession() async {
    final provider = context.read<AttendanceProvider>();
    final success = await provider.uploadPreviousSession();
    
    if (mounted) {
      setState(() {
        _hasUploadedPrevious = success;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Previous session data loaded successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Failed to load previous session'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _createSession() async {
    if (!_formKey.currentState!.validate()) return;

    // Auto start hotspot if not active
    if (!_hotspotActive) {
      await _toggleHotspot();
      await Future.delayed(const Duration(seconds: 2)); // Wait server start
    }

    final provider = context.read<AttendanceProvider>();
    
    await provider.createSession(
      courseName: _courseNameController.text,
      gracePeriodMinutes: int.parse(_gracePeriodController.text),
      requiredConnectionMinutes: int.parse(_connectionTimeController.text),
      maxAttendanceCount: int.parse(_maxAttendanceController.text),
      gpsRadiusKm: double.parse(_gpsRadiusController.text),
    );

    if (mounted) {
      if (provider.error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Session started! Hotspot: $_ssid')),
        );
        context.go('/dashboard');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error!),
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
        title: const Text('Setup New Session'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                'Configure Attendance Session',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'Set up the parameters for your attendance session and optionally upload previous session data for cumulative tracking.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),

              // Upload Previous Session Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _hasUploadedPrevious ? Icons.check_circle : Icons.upload_file,
                            color: _hasUploadedPrevious
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Upload Previous Session (Optional)',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Load previous attendance data to maintain cumulative totals. The system will automatically map existing student records.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.tonal(
                        onPressed: _uploadPreviousSession,
                        child: const Text('Choose Excel File'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Course Name
              TextFormField(
                controller: _courseNameController,
                decoration: const InputDecoration(
                  labelText: 'Course Name',
                  hintText: 'e.g., Computer Science 101',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.book),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Grace Period
              TextFormField(
                controller: _gracePeriodController,
                decoration: const InputDecoration(
                  labelText: 'Grace Period (minutes)',
                  hintText: 'Late arrival tolerance',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.timer),
                  suffixText: 'min',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  if (int.tryParse(value!) == null) return 'Must be a number';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Required Connection Time
              TextFormField(
                controller: _connectionTimeController,
                decoration: const InputDecoration(
                  labelText: 'Required Connection Time (minutes)',
                  hintText: 'Minimum time to stay connected',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.wifi),
                  suffixText: 'min',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  if (int.tryParse(value!) == null) return 'Must be a number';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Max Attendance Count
              TextFormField(
                controller: _maxAttendanceController,
                decoration: const InputDecoration(
                  labelText: 'Maximum Attendance Count',
                  hintText: 'Total number of sessions',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  if (int.tryParse(value!) == null) return 'Must be a number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _gpsRadiusController,
                decoration: const InputDecoration(
                  labelText: 'GPS Radius (km)',
                  hintText: '0.1 = 100m allowed area',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                  suffixText: 'km',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  final km = double.tryParse(value!);
                  if (km == null || km <= 0 || km > 10) return 'Between 0.01-10km';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Create Session Button
              Consumer<AttendanceProvider>(
                builder: (context, provider, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton(
                        onPressed: provider.isLoading ? null : _createSession,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: provider.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Start Session'),
                        ),
                      ),
                      // Hotspot Toggle Button
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _toggleHotspot,
                        icon: _isHotspotLoading 
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(_hotspotActive ? Icons.wifi_off : Icons.wifi_tethering),
                        label: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Text(_hotspotActive ? 'Stop Hotspot Portal' : 'Start Hotspot Portal'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_hotspotActive)
                        OutlinedButton.icon(
                          onPressed: () async {
                            final html = await Navigator.push<String>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CaptiveEditorPage(
                                  initialTitle: _courseNameController.text.isNotEmpty ? 'Student Portal - ${_courseNameController.text}' : 'Student Portal',
                                  initialCourse: _courseNameController.text.isNotEmpty ? _courseNameController.text : 'Course',
                                ),
                              ),
                            );
                            if (html != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Custom HTML saved! Restart portal to use.')),
                              );
                            }
                          },
                          icon: const Icon(Icons.edit),
                          label: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            child: Text('Edit Captive HTML'),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _launchPortal,
                          icon: const Icon(Icons.visibility),
                          label: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            child: Text('View My Captive Page'),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
