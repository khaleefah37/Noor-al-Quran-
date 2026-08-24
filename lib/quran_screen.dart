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
  List<QuranSurah> surahs = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadQuran();
  }

  Future<void> loadQuran() async {
    final jsonString =
        await rootBundle.loadString('assets/data/quran.json');
    final data = jsonDecode(jsonString);

    final List<dynamic> items =
        data is List ? data : (data['data'] ?? []);

    final result = <QuranSurah>[];

    for (final item in items) {
      final ayahItems =
          (item['ayahs'] ?? item['verses'] ?? []) as List<dynamic>;

      result.add(
        QuranSurah(
          number: item['id'] ?? item['number'] ?? result.length + 1,
          name: item['name'] ?? item['arabicName'] ?? '',
          englishName:
              item['englishName'] ?? item['english_name'] ?? '',
          revelationType:
              item['revelationType'] ?? item['revelation_type'] ?? '',
          ayahs: [
            for (var i = 0; i < ayahItems.length; i++)
              QuranAyah(
                number:
                    ayahItems[i]['numberInSurah'] ?? i + 1,
                text: ayahItems[i]['text'] ?? '',
              ),
          ],
        ),
      );
    }

    if (!mounted) return;

    setState(() {
      surahs = result;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Noor Al-Quran'),
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
              surah.name,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '${surah.englishName} • ${surah.ayahs.length} Ayahs',
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
  final QuranSurah surah;

  const SurahReaderScreen({
    super.key,
    required this.surah,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(surah.name),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: surah.ayahs.length,
        itemBuilder: (context, index) {
          final ayah = surah.ayahs[index];

          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  ayah.text,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                    fontSize: 25,
                    height: 1.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '﴿${ayah.number}﴾',
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
