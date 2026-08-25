import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import 'quran_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final session = await AudioSession.instance;
  await session.configure(
    const AudioSessionConfiguration.music(),
  );

  runApp(const NoorAlQuranApp());
}

class NoorAlQuranApp extends StatelessWidget {
  const NoorAlQuranApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Noor Al-Quran',
      debugShowCheckedModeBanner: false,

      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF09090B),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF059669),
          secondary: Color(0xFF10B981),
          surface: Color(0xFF18181B),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF18181B),
        ),
      ),

      routes: {
        '/quran': (_) => const QuranScreen(),
      },

      home: const MainTabScreen(),
    );
  }
}

class MainTabScreen extends StatefulWidget {
  const MainTabScreen({super.key});

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  int _currentIndex = 0;

  String? _customAudioPath;

  void _onCustomAudioSaved(String path) {
    setState(() {
      _customAudioPath = path;
      _currentIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const QuranScreen(),

      AdminUploadScreen(
        onAudioSaved: _onCustomAudioSaved,
      ),
    ];

    return Scaffold(
      body: screens[_currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,

        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },

        backgroundColor: const Color(0xFF18181B),
        selectedItemColor: const Color(0xFF10B981),
        unselectedItemColor: Colors.grey,

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Quran',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings),
            label: 'Admin MP3',
          ),
        ],
      ),
    );
  }
}


// ============================================================
// ADMIN AUDIO UPLOAD SCREEN
// ============================================================

class AdminUploadScreen extends StatefulWidget {
  final Function(String path) onAudioSaved;

  const AdminUploadScreen({
    super.key,
    required this.onAudioSaved,
  });

  @override
  State<AdminUploadScreen> createState() =>
      _AdminUploadScreenState();
}

class _AdminUploadScreenState
    extends State<AdminUploadScreen> {
  bool _isAuthenticated = false;

  final TextEditingController _passcodeController =
      TextEditingController();

  String? _selectedFilePath;
  String? _selectedFileName;

  bool _isSaving = false;

  List<FileSystemEntity> _savedFiles = [];

  String? _selectedSavedPath;

  @override
  void initState() {
    super.initState();
    _loadSavedFiles();
  }

  @override
  void dispose() {
    _passcodeController.dispose();
    super.dispose();
  }

  // ==========================================================
  // ADMIN LOGIN
  // ==========================================================

  void _login() {
    if (_passcodeController.text.trim() == 'noor2026') {
      setState(() {
        _isAuthenticated = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Invalid Admin PIN.',
          ),
        ),
      );
    }
  }

  // ==========================================================
  // PICK AUDIO FILE
  // ==========================================================

  Future<void> _pickMp3File() async {
    final result =
        await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'mp3',
        'wav',
        'm4a',
        'aac',
      ],
    );

    if (result != null &&
        result.files.single.path != null) {
      setState(() {
        _selectedFilePath =
            result.files.single.path;

        _selectedFileName =
            result.files.single.name;
      });
    }
  }

  // ==========================================================
  // LOAD SAVED AUDIO FILES
  // ==========================================================

  Future<void> _loadSavedFiles() async {
    final dir =
        await getApplicationDocumentsDirectory();

    final files = Directory(dir.path)
        .listSync()
        .where(
          (file) {
            final path =
                file.path.toLowerCase();

            return path.endsWith('.mp3') ||
                path.endsWith('.m4a') ||
                path.endsWith('.wav') ||
                path.endsWith('.aac');
          },
        )
        .toList();

    if (!mounted) return;

    setState(() {
      _savedFiles = files;

      if (_savedFiles.isNotEmpty &&
          _selectedSavedPath == null) {
        _selectedSavedPath =
            _savedFiles.last.path;
      }
    });
  }

  // ==========================================================
  // SAVE AND CONNECT AUDIO
  // ==========================================================

  Future<void> _saveAndConnectAudio() async {
    if (_selectedFilePath == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final dir =
          await getApplicationDocumentsDirectory();

      final basename =
          _selectedFileName ??
              _selectedFilePath!
                  .split(Platform.pathSeparator)
                  .last;

      final timestamp =
          DateTime.now()
              .millisecondsSinceEpoch;

      final destination = File(
        '${dir.path}/custom_${timestamp}_$basename',
      );

      await File(_selectedFilePath!)
          .copy(destination.path);

      await _loadSavedFiles();

      widget.onAudioSaved(
        destination.path,
      );

      if (!mounted) return;

      setState(() {
        _selectedSavedPath =
            destination.path;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Custom recitation saved successfully!',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Error saving audio: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ==========================================================
  // CONNECT SAVED AUDIO
  // ==========================================================

  Future<void> _connectSelectedSaved() async {
    if (_selectedSavedPath == null) {
      return;
    }

    widget.onAudioSaved(
      _selectedSavedPath!,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Selected recitation connected!',
        ),
      ),
    );
  }

  // ==========================================================
  // DELETE AUDIO
  // ==========================================================

  Future<void> _deleteSaved(
    String path,
  ) async {
    try {
      final file = File(path);

      if (await file.exists()) {
        await file.delete();
      }

      await _loadSavedFiles();

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Saved recitation deleted.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Delete failed: $e',
          ),
        ),
      );
    }
  }

  // ==========================================================
  // LOGIN SCREEN
  // ==========================================================

  Widget _buildLoginScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Authentication',
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            const Icon(
              Icons.lock,
              size: 70,
              color: Color(0xFF10B981),
            ),

            const SizedBox(height: 20),

            const Text(
              'Admin Access',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Enter your administrator PIN.',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 25),

            TextField(
              controller:
                  _passcodeController,

              obscureText: true,

              decoration:
                  InputDecoration(
                hintText: 'Admin PIN',

                filled: true,

                fillColor:
                    const Color(0xFF18181B),

                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              height: 50,

              child: ElevatedButton(
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF059669),
                ),

                onPressed: _login,

                child: const Text(
                  'Login as Administrator',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // ADMIN SCREEN
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      return _buildLoginScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Audio Uploader',
        ),

        actions: [
          IconButton(
            icon: const Icon(
              Icons.logout,
            ),

            onPressed: () {
              setState(() {
                _isAuthenticated =
                    false;
              });
            },
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: ListView(
          children: [
            Container(
              padding:
                  const EdgeInsets.all(16),

              decoration:
                  BoxDecoration(
                color:
                    const Color(0xFF18181B),

                borderRadius:
                    BorderRadius.circular(
                  12,
                ),

                border: Border.all(
                  color:
                      const Color(0xFF27272A),
                ),
              ),

              child: const Text(
                'Upload a recitation audio file. '
                'The file will be stored on the device.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ),

            const SizedBox(height: 24),

            OutlinedButton.icon(
              style:
                  OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 22,
                ),

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
              ),

              icon: const Icon(
                Icons.audio_file,
                color:
                    Color(0xFF10B981),
                size: 32,
              ),

              label: Text(
                _selectedFileName ??
                    'Select Audio File',
                style: const TextStyle(
                  color: Colors.white,
                ),
              ),

              onPressed:
                  _pickMp3File,
            ),

            const SizedBox(height: 18),

            ElevatedButton.icon(
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFF059669),

                padding:
                    const EdgeInsets.symmetric(
                  vertical: 16,
                ),
              ),

              icon: const Icon(
                Icons.save,
              ),

              label: Text(
                _isSaving
                    ? 'Saving...'
                    : 'Save Audio',
              ),

              onPressed:
                  _isSaving
                      ? null
                      : _saveAndConnectAudio,
            ),

            const SizedBox(height: 30),

            const Text(
              'Saved Recitations',
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            if (_savedFiles.isEmpty)
              const Padding(
                padding:
                    EdgeInsets.all(20),
                child: Text(
                  'No saved recitations yet.',
                  textAlign:
                     
