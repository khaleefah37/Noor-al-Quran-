import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/quran_models.dart';

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  List<SurahModel> surahs = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadQuran();
  }

  Future<void> loadQuran() async {
    try {
      final jsonString =
          await rootBundle.loadString('assets/data/quran.json');

      final decoded = jsonDecode(jsonString);

      if (decoded is! List) {
        throw Exception('Quran JSON must contain a list of Surahs');
      }

      final result = <SurahModel>[];

      for (final item in decoded) {
        if (item is! Map) continue;

        final rawText = item['text'];

        final List<dynamic> verses =
            rawText is List ? rawText : <dynamic>[];

        final ayahs = <AyahModel>[];

        for (int i = 0; i < verses.length; i++) {
          final verse = verses[i];

          String arabicText = '';

          if (verse is String) {
            arabicText = verse;
          } else if (verse is Map) {
            arabicText =
                (verse['text'] ??
                        verse['textArabic'] ??
                        verse['arabic'] ??
                        '')
                    .toString();
          }

          ayahs.add(
            AyahModel(
              number: i + 1,
              numberInSurah: i + 1,
              textArabic: arabicText,
              translation: '',
            ),
          );
        }

        result.add(
          SurahModel(
            number: int.tryParse('${item['id']}') ?? result.length + 1,
            nameArabic: '${item['name'] ?? ''}',
            nameEnglish: '${item['translation'] ?? ''}',
            translationName: '${item['translation'] ?? ''}',
            totalAyahs:
                int.tryParse('${item['total_verse']}') ?? ayahs.length,
            revelationType: '${item['revelationType'] ?? ''}',
            ayahs: ayahs,
          ),
        );
      }

      if (!mounted) return;

      setState(() {
        surahs = result;
        loading = false;
        error = null;
      });

      debugPrint('Quran loaded successfully: ${result.length} Surahs');
    } catch (e) {
      debugPrint('Quran loading error: $e');

      if (!mounted) return;

      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading Quran...'),
            ],
          ),
        ),
      );
    }

    if (error != null || surahs.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Noor Al-Quran'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 60,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Quran data could not be loaded',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  error ?? 'No Surahs found in the Quran data.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      loading = true;
                      error = null;
                    });
                    loadQuran();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Noor Al-Quran',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: surahs.length,
        itemBuilder: (context, index) {
          final surah = surahs[index];

          return Card(
            margin: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 5,
            ),
            child: ListTile(
              leading: CircleAvatar(
                child: Text('${surah.number}'),
              ),
              title: Text(
                surah.nameArabic,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                '${surah.nameEnglish} • ${surah.totalAyahs} Ayahs',
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SurahReaderScreen(surah: surah),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class SurahReaderScreen extends StatelessWidget {
  final SurahModel surah;

  const SurahReaderScreen({
    super.key,
    required this.surah,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(surah.nameArabic),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: surah.ayahs.length,
        itemBuilder: (context, index) {
          final ayah = surah.ayahs[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    ayah.textArabic,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      fontSize: 25,
                      height: 1.9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '﴿${ayah.numberInSurah}﴾',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 16,
                    ),
                  ),
                  if (ayah.translation.isNotEmpty) ...[
                    const Divider(),
                    Text(
                      ayah.translation,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
