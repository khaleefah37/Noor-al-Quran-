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

  @override
  void initState() {
    super.initState();
    loadQuran();
  }

  Future<void> loadQuran() async {
    try {
      final jsonString =
          await rootBundle.loadString('assets/data/quran.json');

      final List<dynamic> data = jsonDecode(jsonString);

      final result = <SurahModel>[];

      for (final item in data) {
        final List<dynamic> verses = item['text'] ?? [];

        final ayahs = <AyahModel>[];

        for (var i = 0; i < verses.length; i++) {
          ayahs.add(
            AyahModel(
              number: i + 1,
              numberInSurah: i + 1,
              textArabic: verses[i].toString(),
              translation: '',
            ),
          );
        }

        result.add(
          SurahModel(
            number: item['id'] ?? result.length + 1,
            nameArabic: item['name'] ?? '',
            nameEnglish: item['translation'] ?? '',
            translationName: item['translation'] ?? '',
            totalAyahs: item['total_verse'] ?? ayahs.length,
            revelationType: item['revelationType'] ?? '',
            ayahs: ayahs,
          ),
        );
      }

      if (!mounted) return;

      setState(() {
        surahs = result;
        loading = false;
      });
    } catch (e) {
      debugPrint('Quran loading error: $e');

      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (surahs.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Noor Al-Quran'),
        ),
        body: const Center(
          child: Text(
            'Quran data could not be loaded.',
            style: TextStyle(fontSize: 16),
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

          return ListTile(
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
            trailing: Text(surah.revelationType),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SurahReaderScreen(surah: surah),
                ),
              );
            },
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
        padding: const EdgeInsets.all(16),
        itemCount: surah.ayahs.length,
        itemBuilder: (context, index) {
          final ayah = surah.ayahs[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 14),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    ayah.textArabic,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      fontSize: 25,
                      height: 1.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (ayah.translation.isNotEmpty)
                    Text(
                      ayah.translation,
                      style: const TextStyle(fontSize: 14),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    '﴿${ayah.numberInSurah}﴾',
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
