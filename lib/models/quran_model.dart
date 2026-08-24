class QuranAyah {
  final int number;
  final String text;

  const QuranAyah({
    required this.number,
    required this.text,
  });
}

class QuranSurah {
  final int number;
  final String name;
  final String englishName;
  final String revelationType;
  final List<QuranAyah> ayahs;

  const QuranSurah({
    required this.number,
    required this.name,
    required this.englishName,
    required this.revelationType,
    required this.ayahs,
  });
}
