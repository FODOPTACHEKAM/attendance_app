import 'package:flutter/material.dart';
import '../theme.dart';
import 'captive_preview_page.dart';

class CaptiveEditorPage extends StatefulWidget {
  final String initialTitle;
  final String initialCourse;

  const CaptiveEditorPage({
    super.key,
    this.initialTitle = 'Student Portal',
    this.initialCourse = 'Course',
  });

  @override
  State<CaptiveEditorPage> createState() => _CaptiveEditorPageState();
}

class _CaptiveEditorPageState extends State<CaptiveEditorPage> {
  late TextEditingController _titleController;
  late TextEditingController _courseController;
  late TextEditingController _fullNameLabelController;
  late TextEditingController _emailLabelController;
  late TextEditingController _matriculeLabelController;
  late TextEditingController _submitButtonController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _courseController = TextEditingController(text: widget.initialCourse);
    _fullNameLabelController = TextEditingController(text: 'Full Name');
    _emailLabelController = TextEditingController(text: 'Email Address');
    _matriculeLabelController = TextEditingController(text: 'Matricule');
    _submitButtonController = TextEditingController(text: 'Submit');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _courseController.dispose();
    _fullNameLabelController.dispose();
    _emailLabelController.dispose();
    _matriculeLabelController.dispose();
    _submitButtonController.dispose();
    super.dispose();
  }

  String generateHtml() {
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${_titleController.text}</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <style>
        body { background-color: #f9fafb; }
    </style>
</head>
<body class="flex items-center justify-center min-h-screen">
    <div class="bg-white p-8 rounded-2xl shadow-sm border border-gray-100 w-full max-w-md">
        <div class="text-center mb-8">
            <h1 class="text-2xl font-bold text-gray-900">${_titleController.text}</h1>
            <p class="text-gray-500 mt-1">Course: ${_courseController.text}</p>
        </div>
        <form action="/register" method="POST" class="space-y-6">
            <div>
                <label class="block text-sm font-semibold text-gray-900 mb-2">
                    ${_fullNameLabelController.text}
                </label>
                <input type="text" name="full_name" placeholder="Enter your full name" required class="w-full px-4 py-3 rounded-lg border border-gray-200 focus:outline-none focus:ring-2 focus:ring-black focus:border-transparent transition duration-200">
            </div>
            <div>
                <label class="block text-sm font-semibold text-gray-900 mb-2">
                    ${_emailLabelController.text}
                </label>
                <input type="email" name="email" placeholder="Enter your email" required class="w-full px-4 py-3 rounded-lg border border-gray-200 focus:outline-none focus:ring-2 focus:ring-black focus:border-transparent transition duration-200">
            </div>
            <div>
                <label class="block text-sm font-semibold text-gray-900 mb-2">
                    ${_matriculeLabelController.text}
                </label>
                <input type="text" name="matricule" placeholder="Enter your matricule" required class="w-full px-4 py-3 rounded-lg border border-gray-200 focus:outline-none focus:ring-2 focus:ring-black focus:border-transparent transition duration-200">
            </div>
            <div id="gps-status" class="text-center py-2 text-sm text-gray-500 hidden">
                📍 GPS Location Captured ✓
            </div>
            <input type="hidden" name="latitude" id="latitude">
            <input type="hidden" name="longitude" id="longitude">
            <button type="submit" id="submit-btn" class="w-full bg-black text-white font-semibold py-3 rounded-lg hover:bg-gray-800 transition duration-300">
                ${_submitButtonController.text}
            </button>
        </form>
        <script>
            document.addEventListener('DOMContentLoaded', function() {
                const form = document.getElementById('regForm');
                const submitBtn = document.getElementById('submit-btn');
                const gpsStatus = document.getElementById('gps-status');
                const latInput = document.getElementById('latitude');
                const lngInput = document.getElementById('longitude');

                form.addEventListener('submit', async function(e) {
                    e.preventDefault();
                    
                    submitBtn.disabled = true;
                    submitBtn.textContent = 'Capturing GPS...';
                    
                    if (navigator.geolocation) {
                        navigator.geolocation.getCurrentPosition(
                            function(position) {
                                latInput.value = position.coords.latitude.toString();
                                lngInput.value = position.coords.longitude.toString();
                                gpsStatus.classList.remove('hidden');
                                submitBtn.textContent = '${_submitButtonController.text}';
                                form.submit();
                            },
                            function(error) {
                                alert('GPS access denied or unavailable. Attendance may not be verified.');
                                form.submit();
                            },
                            { 
                                enableHighAccuracy: true, 
                                timeout: 10000, 
                                maximumAge: 60000 
                            }
                        );
                    } else {
                        alert('Geolocation not supported');
                        form.submit();
                    }
                });
            });
        </script>
    </div>
</body>
</html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Captive Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              Navigator.pop(context, generateHtml());
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: AppSpacing.paddingMd,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Portal Title',
                        prefixIcon: Icon(Icons.title),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _courseController,
                      decoration: const InputDecoration(
                        labelText: 'Course Name (subtitle)',
                        prefixIcon: Icon(Icons.school),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Card(
              child: Padding(
                padding: AppSpacing.paddingMd,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Field Labels',
                      style: context.textStyles.titleMedium?.bold,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _fullNameLabelController,
                      decoration: const InputDecoration(labelText: 'Full Name Label'),
                    ),
                    TextFormField(
                      controller: _emailLabelController,
                      decoration: const InputDecoration(labelText: 'Email Label'),
                    ),
                    TextFormField(
                      controller: _matriculeLabelController,
                      decoration: const InputDecoration(labelText: 'Matricule Label'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _submitButtonController,
                      decoration: const InputDecoration(labelText: 'Submit Button Text'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, generateHtml()),
                    child: const Text('Save & Use'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CaptivePreviewPage(htmlContent: generateHtml()),
                        ),
                      );
                    },
                    child: const Text('Preview'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
