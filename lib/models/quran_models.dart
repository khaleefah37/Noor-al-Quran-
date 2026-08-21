class AyahModel {
  final int number;
  final int numberInSurah;
  final String textArabic;
  final String translation;

  const AyahModel({
    required this.number,
    required this.numberInSurah,
    required this.textArabic,
    required this.translation,
  });
}

class SurahModel {
  final int number;
  final String nameArabic;
  final String nameEnglish;
  final String translationName;
  final int totalAyahs;
  final String revelationType;
  final List<AyahModel> ayahs;

  const SurahModel({
    required this.number,
    required this.nameArabic,
    required this.nameEnglish,
    required this.translationName,
    required this.totalAyahs,
    required this.revelationType,
    required this.ayahs,
  });
}

const SurahModel surahAlFatihah = SurahModel(
  number: 1,
  nameArabic: 'الفاتحة',
  nameEnglish: 'Al-Fatihah',
  translationName: 'The Opening',
  totalAyahs: 7,
  revelationType: 'Meccan',
  ayahs: [
    AyahModel(
      number: 1,
      numberInSurah: 1,
      textArabic: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
      translation: 'In the name of Allah, the Entirely Merciful, the Especially Merciful.',
    ),
    AyahModel(
      number: 2,
      numberInSurah: 2,
      textArabic: 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
      translation: '[All] praise is [due] to Allah, Lord of the worlds -',
    ),
    AyahModel(
      number: 3,
      numberInSurah: 3,
      textArabic: 'الرَّحْمَٰنِ الرَّحِيمِ',
      translation: 'The Entirely Merciful, the Especially Merciful,',
    ),
    AyahModel(
      number: 4,
      numberInSurah: 4,
      textArabic: 'مَالِكِ يَوْمِ الدِّينِ',
      translation: 'Sovereign of the Day of Recompense.',
    ),
    AyahModel(
      number: 5,
      numberInSurah: 5,
      textArabic: 'إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ',
      translation: 'It is You we worship and You we ask for help.',
    ),
    AyahModel(
      number: 6,
      numberInSurah: 6,
      textArabic: 'اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ',
      translation: 'Guide us to the straight path -',
    ),
    AyahModel(
      number: 7,
      numberInSurah: 7,
      textArabic: 'صِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّالِّينَ',
      translation: 'The path of those upon whom You have bestowed favor, not of those who have evoked [Your] anger or of those who are astray.',
    ),
  ],
);
