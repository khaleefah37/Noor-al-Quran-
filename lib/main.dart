import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'quran_screen.dart';

Future<void> main() async {
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
      ),

      home: const MainTabScreen(),

      routes: {
        '/quran': (_) => const QuranScreen(),
      },
    );
  }
}

class MainTabScreen extends StatefulWidget {
  const MainTabScreen({super.key});

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  int currentIndex = 0;

  String? customAudioPath;

  void onCustomAudioSaved(String path) {
    setState(() {
      customAudioPath = path;
      currentIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: currentIndex == 0
          ? const QuranScreen()
          : AdminUploadScreen(
              onAudioSaved: onCustomAudioSaved,
            ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,

        onTap: (index) {
          setState(() {
            currentIndex = index;
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
            label: 'Admin',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ADMIN UPLOAD
// ============================================================

class AdminUploadScreen extends StatefulWidget {
  final void Function(String path) onAudioSaved;

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
  bool authenticated = false;
  bool saving = false;

  final TextEditingController pinController =
      TextEditingController();

  String? selectedFilePath;
  String? selectedFileName;

  List<FileSystemEntity> savedFiles = [];

  @override
  void initState() {
    super.initState();
    loadSavedFiles();
  }

  @override
  void dispose() {
    pinController.dispose();
    super.dispose();
  }

  // ==========================================================
  // LOGIN
  // ==========================================================

  void login() {
    if (pinController.text.trim() == 'noor2026') {
      setState(() {
        authenticated = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid Admin PIN.'),
        ),
      );
    }
  }

  // ==========================================================
  // PICK AUDIO
  // ==========================================================

  Future<void> pickAudio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'mp3',
        'wav',
        'm4a',
        'aac',
      ],
    );

    if (result == null) return;

    final path = result.files.single.path;

    if (path == null) return;

    setState(() {
      selectedFilePath = path;
      selectedFileName = result.files.single.name;
    });
  }

  // ==========================================================
  // LOAD SAVED FILES
  // ==========================================================

  Future<void> loadSavedFiles() async {
    final directory =
        await getApplicationDocumentsDirectory();

    final files = Directory(directory.path)
        .listSync()
        .where((file) {
          final path = file.path.toLowerCase();

          return path.endsWith('.mp3') ||
              path.endsWith('.wav') ||
              path.endsWith('.m4a') ||
              path.endsWith('.aac');
        })
        .toList();

    if (!mounted) return;

    setState(() {
      savedFiles = files;
    });
  }

  // ==========================================================
  // SAVE AUDIO
  // ==========================================================

  Future<void> saveAudio() async {
    if (selectedFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an audio file first.'),
        ),
      );
      return;
    }

    setState(() {
      saving = true;
    });

    try {
      final directory =
          await getApplicationDocumentsDirectory();

      final originalName =
          selectedFileName ??
          selectedFilePath!.split(
            Platform.pathSeparator,
          ).last;

      final timestamp =
          DateTime.now().millisecondsSinceEpoch;

      final destination = File(
        '${directory.path}/custom_${timestamp}_$originalName',
      );

      await File(selectedFilePath!)
          .copy(destination.path);

      await loadSavedFiles();

      widget.onAudioSaved(destination.path);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Recitation saved successfully.',
          ),
        ),
      );

      setState(() {
        selectedFilePath = null;
        selectedFileName = null;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Save failed: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  // ==========================================================
  // DELETE AUDIO
  // ==========================================================

  Future<void> deleteFile(String path) async {
    try {
      final file = File(path);

      if (await file.exists()) {
        await file.delete();
      }

      await loadSavedFiles();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recitation deleted.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Delete failed: $e'),
        ),
      );
    }
  }

  // ==========================================================
  // LOGIN SCREEN
  // ==========================================================

  Widget loginScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Authentication'),
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

            const SizedBox(height: 10),

            const Text(
              'Enter administrator PIN.',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 25),

            TextField(
              controller: pinController,
              obscureText: true,

              decoration: InputDecoration(
                hintText: 'Admin PIN',
                filled: true,
                fillColor: const Color(0xFF18181B),

                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              height: 50,

              child: ElevatedButton(
                onPressed: login,

                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF059669),
                ),

                child: const Text(
                  'Login',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
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

  Widget adminScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Audio Uploader',
        ),

        actions: [
          IconButton(
            icon: const Icon(Icons.logout),

            onPressed: () {
              setState(() {
                authenticated = false;
              });
            },
          ),
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),

        children: [
          Container(
            padding: const EdgeInsets.all(16),

            decoration: BoxDecoration(
              color: const Color(0xFF18181B),

              borderRadius:
                  BorderRadius.circular(12),

              border: Border.all(
                color: const Color(0xFF27272A),
              ),
            ),

            child: const Text(
              'Select a Quran recitation audio file. '
              'It will be saved on this device.',
              style: TextStyle(
                color: Colors.white70,
              ),
            ),
          ),

          const SizedBox(height: 24),

          OutlinedButton.icon(
            onPressed: pickAudio,

            icon: const Icon(
              Icons.audio_file,
              color: Color(0xFF10B981),
            ),

            label: Text(
              selectedFileName ??
                  'Select Audio File',
            ),

            style: OutlinedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(
                vertical: 20,
              ),
            ),
          ),

          const SizedBox(height: 16),

          ElevatedButton.icon(
            onPressed: saving
                ? null
                : saveAudio,

            icon: const Icon(Icons.save),

            label: Text(
              saving
                  ? 'Saving...'
                  : 'Save Recitation',
            ),

            style: ElevatedButton.styleFrom(
              backgroundColor:
                  const Color(0xFF059669),

              padding:
                  const EdgeInsets.symmetric(
                vertical: 16,
              ),
            ),
          ),

          const SizedBox(height: 30),

          const Text(
            'Saved Recitations',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          if (savedFiles.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),

              child: Text(
                'No saved recitations.',
                textAlign: TextAlign.center,

                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),

          for (final file in savedFiles)
            Card(
              color: const Color(0xFF18181B),

              child: ListTile(
                leading: const Icon(
                  Icons.music_note,
                  color: Color(0xFF10B981),
                ),

                title: Text(
                  file.path.split(
                    Platform.pathSeparator,
                  ).last,

                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                ),

                trailing: IconButton(
                  icon: const Icon(
                    Icons.delete,
                    color: Colors.redAccent,
                  ),

                  onPressed: () {
                    deleteFile(file.path);
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!authenticated) {
      return loginScreen();
    }

    return adminScreen();
  }
}            ),
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
                     
