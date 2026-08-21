import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'models/quran_models.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());
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
      SurahReaderScreen(customAudioPath: _customAudioPath),
      AdminUploadScreen(onAudioSaved: _onCustomAudioSaved),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (idx) => setState(() => _currentIndex = idx),
        backgroundColor: const Color(0xFF18181B),
        selectedItemColor: const Color(0xFF10B981),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Surah Al-Fatihah',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings),
            label: 'Admin MP3 Upload',
          ),
        ],
      ),
    );
  }
}

class SurahReaderScreen extends StatefulWidget {
  final String? customAudioPath;
  const SurahReaderScreen({super.key, this.customAudioPath});

  @override
  State<SurahReaderScreen> createState() => _SurahReaderScreenState();
}

class _SurahReaderScreenState extends State<SurahReaderScreen> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isOfflineDownloaded = false;
  bool _isDownloading = false;

  final String _defaultCdnUrl = "https://server8.mp3quran.net/afs/001.mp3";

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initAudio();
    _checkOfflineStatus();
  }

  Future<void> _initAudio() async {
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing && state.processingState != ProcessingState.completed;
        });
      }
    });

    _audioPlayer.positionStream.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });

    _audioPlayer.durationStream.listen((dur) {
      if (mounted && dur != null) setState(() => _duration = dur);
    });

    try {
      if (widget.customAudioPath != null && File(widget.customAudioPath!).existsSync()) {
        await _audioPlayer.setFilePath(widget.customAudioPath!);
      } else {
        final localFile = await _getLocalAudioFile();
        if (localFile.existsSync()) {
          await _audioPlayer.setFilePath(localFile.path);
        } else {
          await _audioPlayer.setUrl(_defaultCdnUrl);
        }
      }
    } catch (e) {
      debugPrint("Audio load error: $e");
    }
  }

  Future<File> _getLocalAudioFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File("${dir.path}/surah_001.mp3");
  }

  Future<void> _checkOfflineStatus() async {
    final file = await _getLocalAudioFile();
    if (mounted) {
      setState(() {
        _isOfflineDownloaded = file.existsSync();
      });
    }
  }

  Future<void> _downloadForOffline() async {
    setState(() => _isDownloading = true);
    try {
      final file = await _getLocalAudioFile();
      if (widget.customAudioPath != null && File(widget.customAudioPath!).existsSync()) {
        await File(widget.customAudioPath!).copy(file.path);
      } else {
        final dio = Dio();
        await dio.download(_defaultCdnUrl, file.path);
      }
      setState(() {
        _isOfflineDownloaded = true;
        _isDownloading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Surah Al-Fatihah saved for offline playback!')),
        );
      }
    } catch (e) {
      setState(() => _isDownloading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    }
  }

  void _togglePlay() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Noor Al-Quran (نور القرآن)', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF18181B),
        actions: [
          IconButton(
            icon: Icon(_isOfflineDownloaded ? Icons.offline_pin : Icons.download_for_offline),
            color: _isOfflineDownloaded ? const Color(0xFF10B981) : Colors.white,
            onPressed: _isDownloading ? null : _downloadForOffline,
            tooltip: _isOfflineDownloaded ? 'Saved Offline' : 'Download for Offline',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF064E3B), Color(0xFF18181B)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF047857).withOpacity(0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Surah Al-Fatihah', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('The Opening • 7 Ayahs (Meccan)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                const Text('الفاتحة', style: TextStyle(fontSize: 26, color: Color(0xFF34D399), fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: surahAlFatihah.ayahs.length,
              itemBuilder: (context, idx) {
                final ayah = surahAlFatihah.ayahs[idx];
                return Card(
                  color: const Color(0xFF18181B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: const Color(0xFF27272A),
                              child: Text('${ayah.numberInSurah}', style: const TextStyle(fontSize: 11, color: Colors.white)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          ayah.textArabic,
                          textAlign: TextAlign.right,
                          style: GoogleFonts.amiri(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 2.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          ayah.translation,
                          style: const TextStyle(fontSize: 13, color: Color(0xFFD4D4D8)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF18181B),
              border: Border(top: BorderSide(color: Color(0xFF27272A))),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  ),
                  child: Slider(
                    value: _position.inSeconds.toDouble().clamp(0.0, _duration.inSeconds.toDouble()),
                    max: _duration.inSeconds.toDouble() > 0 ? _duration.inSeconds.toDouble() : 1.0,
                    activeColor: const Color(0xFF10B981),
                    inactiveColor: const Color(0xFF3F3F46),
                    onChanged: (val) {
                      _audioPlayer.seek(Duration(seconds: val.toInt()));
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDuration(_position), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      Text(_formatDuration(_duration), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.replay_10),
                      onPressed: () {
                        final target = _position - const Duration(seconds: 10);
                        _audioPlayer.seek(target < Duration.zero ? Duration.zero : target);
                      },
                    ),
                    const SizedBox(width: 16),
                    FloatingActionButton(
                      backgroundColor: const Color(0xFF059669),
                      onPressed: _togglePlay,
                      child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.forward_10),
                      onPressed: () {
                        final target = _position + const Duration(seconds: 10);
                        _audioPlayer.seek(target > _duration ? _duration : target);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AdminUploadScreen extends StatefulWidget {
  final Function(String path) onAudioSaved;
  const AdminUploadScreen({super.key, required this.onAudioSaved});

  @override
  State<AdminUploadScreen> createState() => _AdminUploadScreenState();
}

class _AdminUploadScreenState extends State<AdminUploadScreen> {
  bool _isAuthenticated = false;
  final TextEditingController _passcodeController = TextEditingController();
  String? _selectedFilePath;
  String? _selectedFileName;
  bool _isSaving = false;

  void _login() {
    if (_passcodeController.text.trim() == 'noor2026') {
      setState(() => _isAuthenticated = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid Admin PIN. (Default: noor2026)')),
      );
    }
  }

  Future<void> _pickMp3File() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'm4a', 'aac'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFilePath = result.files.single.path;
        _selectedFileName = result.files.single.name;
      });
    }
  }

  Future<void> _saveAndConnectAudio() async {
    if (_selectedFilePath == null) return;
    setState(() => _isSaving = true);

    try {
      final dir = await getApplicationDocumentsDirectory();
      final destination = File("${dir.path}/custom_fatihah.mp3");
      await File(_selectedFilePath!).copy(destination.path);

      widget.onAudioSaved(destination.path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Custom MP3 connected to Surah Al-Fatihah!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving audio: $e')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin Authentication'), backgroundColor: const Color(0xFF18181B)),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 64, color: Color(0xFF10B981)),
              const SizedBox(height: 16),
              const Text('Enter Admin Security PIN', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Default passcode: noor2026', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              TextField(
                controller: _passcodeController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Admin PIN',
                  filled: true,
                  fillColor: const Color(0xFF18181B),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: _login,
                child: const Text('Login as Administrator', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Audio Uploader'),
        backgroundColor: const Color(0xFF18181B),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => setState(() => _isAuthenticated = false),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF18181B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF27272A)),
              ),
              child: const Text(
                'Upload your custom recitation MP3 for Surah Al-Fatihah. Once saved, it will be stored persistently on the device and connected to the main audio player.',
                style: TextStyle(fontSize: 13, color: Colors.white70),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.audio_file, color: Color(0xFF10B981), size: 32),
              label: Text(
                _selectedFileName ?? 'Select MP3 File from Device',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              onPressed: _pickMp3File,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _selectedFilePath != null && !_isSaving ? _saveAndConnectAudio : null,
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Save & Connect to Al-Fatihah', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
