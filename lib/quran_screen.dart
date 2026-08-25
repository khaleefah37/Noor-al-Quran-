Future<void> loadQuran() async {
  try {
    final jsonString =
        await rootBundle.loadString('assets/data/quran.json');

    final List<dynamic> data = jsonDecode(jsonString);

    final result = <SurahModel>[];

    for (final item in data) {
      final List<dynamic> textItems =
          (item['text'] ?? []) as List<dynamic>;

      final ayahs = <AyahModel>[];

      for (var i = 0; i < textItems.length; i++) {
        final verse = textItems[i];

        if (verse is String) {
          ayahs.add(
            AyahModel(
              number: i + 1,
              numberInSurah: i + 1,
              textArabic: verse,
              translation: '',
            ),
          );
        } else if (verse is Map<String, dynamic>) {
          ayahs.add(
            AyahModel(
              number: verse['id'] ?? i + 1,
              numberInSurah:
                  verse['numberInSurah'] ?? i + 1,
              textArabic:
                  verse['text'] ?? verse['arabic'] ?? '',
              translation:
                  verse['translation'] ?? '',
            ),
          );
        }
      }

      result.add(
        SurahModel(
          number: item['id'] ?? result.length + 1,
          nameArabic: item['name'] ?? '',
          nameEnglish:
              item['translation'] ?? '',
          translationName:
              item['translation'] ?? '',
          totalAyahs:
              item['total_verse'] ?? ayahs.length,
          revelationType:
              item['revelationType'] ?? '',
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
