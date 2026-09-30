import 'package:latlong2/latlong.dart';

class AppConstants {
  // App Info
  static const String appNameAr = 'كابتن ميسان';
  static const String appNameEn = 'Maysan Captain';
  static const String appVersion = '1.0.2';
  static const int buildNumber = 27;

  // Supabase Configuration
  static const String supabaseUrl = 'https://aksvjsuniudzxumbaiph.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFrc3Zqc3VuaXVkenh1bWJhaXBoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODcxNDgxNzYsImV4cCI6MjEwMjcyNDE3Nn0.drN6_Q2kKePfzPCkTg5rQY-rM3jR7NYvJiSQglbpInY';

  // Super Admin Info
  static const String adminName = 'ميسان تك';
  static const String adminEmail = 'maysan.tech1@gmail.com';
  static const String adminPhone = '07832197406';
  static const String adminPassword = '33221144';

  // Developer Info
  static const String devCompanyAr = 'ميسان تك';
  static const String devCompanyEn = 'Maysan Tech';
  static const String devAuthorAr = 'علي سعدون الموسوي';
  static const String devAuthorEn = 'Ali Saadoon Al-Musawi';
  static const String devEmail = 'maysan.tech1@gmail.com';
  static const String devWebsite = 'https://maysan-tech.gt.tc';
  static const String devPhone = '+9647832197406';

  // Maysan Governorate Geographic Center (Al-Amarah City Center)
  static const LatLng maysanCenter = LatLng(31.8415, 47.1444);

  // Notable Districts, Sub-districts, Neighborhoods & Landmarks of Maysan Governorate
  static final List<MaysanLocation> maysanLocations = [
    // City Center, Squares & Bridges
    MaysanLocation(
      nameAr: 'مركز العمارة - ساحة الصدرين',
      nameEn: 'Al-Amarah Center - Sadrayn Sq.',
      districtAr: 'قضاء العمارة',
      coordinates: const LatLng(31.8436, 47.1452),
      isCenter: true,
    ),
    MaysanLocation(
      nameAr: 'كورنيش دجلة (شارع دجلة)',
      nameEn: 'Tigris Corniche (Dijla St)',
      districtAr: 'قضاء العمارة',
      coordinates: const LatLng(31.8385, 47.1510),
    ),
    MaysanLocation(
      nameAr: 'مجسر الجمهورية (شارع الجسر)',
      nameEn: 'Al-Jomhoureya Bridge',
      districtAr: 'قضاء العمارة',
      coordinates: const LatLng(31.8418, 47.1465),
    ),
    MaysanLocation(
      nameAr: 'السوق الكبير (سوق التجار)',
      nameEn: 'Grand Souq (Al-Amarah)',
      districtAr: 'قضاء العمارة',
      coordinates: const LatLng(31.8400, 47.1480),
    ),
    MaysanLocation(
      nameAr: 'شارع التربية (العمارة)',
      nameEn: 'Al-Tarbiya Street',
      districtAr: 'قضاء العمارة',
      coordinates: const LatLng(31.8455, 47.1475),
    ),
    MaysanLocation(
      nameAr: 'فلكة الطيارة',
      nameEn: 'Al-Tayara Roundabout',
      districtAr: 'قضاء العمارة',
      coordinates: const LatLng(31.8560, 47.1560),
    ),
    MaysanLocation(
      nameAr: 'فلكة حي الحسين',
      nameEn: 'Al-Hussein Roundabout',
      districtAr: 'قضاء العمارة',
      coordinates: const LatLng(31.8340, 47.1410),
    ),

    // Hospitals & Medical
    MaysanLocation(
      nameAr: 'مستشفى دجلة الأهلي',
      nameEn: 'Dijla Private Hospital',
      districtAr: 'قضاء العمارة',
      coordinates: const LatLng(31.8415, 47.1472),
    ),
    MaysanLocation(
      nameAr: 'مستشفى الزهراوي الجراحي',
      nameEn: 'Al-Zahrawi Surgical Hospital',
      districtAr: 'قضاء العمارة',
      coordinates: const LatLng(31.8425, 47.1468),
    ),
    MaysanLocation(
      nameAr: 'مستشفى الصدر التعليمي',
      nameEn: 'Al-Sadr Teaching Hospital',
      districtAr: 'قضاء العمارة',
      coordinates: const LatLng(31.8460, 47.1580),
    ),
    MaysanLocation(
      nameAr: 'مستشفى العمارة الأهلي العام',
      nameEn: 'Al-Amarah General Private Hospital',
      districtAr: 'قضاء العمارة',
      coordinates: const LatLng(31.8398, 47.1485),
    ),
    MaysanLocation(
      nameAr: 'متحف ميسان الحضاري',
      nameEn: 'Maysan Cultural Museum',
      districtAr: 'قضاء العمارة',
      coordinates: const LatLng(31.8440, 47.1488),
    ),
    MaysanLocation(
      nameAr: 'مستشفى الطفل والولادة',
      nameEn: 'Pediatric & Maternity Hospital',
      districtAr: 'قضاء العمارة',
      coordinates: const LatLng(31.8480, 47.1520),
    ),

    // Education & Universities
    MaysanLocation(
      nameAr: 'جامعة ميسان (مجمع الكليات)',
      nameEn: 'University of Maysan (Main)',
      districtAr: 'قضاء العمارة',
      coordinates: const LatLng(31.8650, 47.1250),
    ),
    MaysanLocation(
      nameAr: 'المعهد التقني / العمارة',
      nameEn: 'Technical Institute Al-Amarah',
      districtAr: 'قضاء العمارة',
      coordinates: const LatLng(31.8610, 47.1320),
    ),

    // Neighborhoods & Residential Areas
    MaysanLocation(
      nameAr: 'حي العواشة (العواشة)',
      nameEn: 'Al-Awasha District',
      districtAr: 'قضاء العمارة',
      coordinates: const LatLng(31.8385, 47.1495),
    ),
    MaysanLocation(
      nameAr: 'حي الدبيسات',
      nameEn: 'Al-Dubaisat District',
      districtAr: 'قضاء العمارة',
      coordinates: const LatLng(31.8465, 47.1420),
    ),
    MaysanLocation(
      nameAr: 'قطاع 28',
      nameEn: 'Sector 28 (Al-Qitaa)',
      districtAr: 'قضاء العمارة',
      coordinates: const LatLng(31.8540, 47.1680),
    ),
    MaysanLocation(
      nameAr: 'قطاع 30',
      nameEn: 'Sector 30 (Al-Qitaa)',
      districtAr: 'قضاء العمارة',
      coordinates: const LatLng(31.8560, 47.1710),
    ),
    MaysanLocation(
      nameAr: 'حي الغدير',
      nameEn: 'Al-Ghadir District',
      districtAr: 'قضاء العمارة',
      coordinates: const LatLng(31.8310, 47.1520),
    ),
    MaysanLocation(
      nameAr: 'حي النداء',
      nameEn: 'Al-Nidaa District',
      districtAr: 'قضاء العمارة',
      coordinates: const LatLng(31.8430, 47.1610),
    ),
    MaysanLocation(
      nameAr: 'حي الجامعة',
      nameEn: 'Al-Jamea District',
      districtAr: 'قضاء العمارة',
      coordinates: const LatLng(31.8620, 47.1280),
    ),
    MaysanLocation(
      nameAr: 'حي الخضراء',
      nameEn: 'Al-Khadraa District',
      districtAr: 'قضاء العمارة',
      coordinates: const LatLng(31.8440, 47.1510),
    ),
    MaysanLocation(
      nameAr: 'حي الكرامة',
      nameEn: 'Al-Karama District',
      districtAr: 'قضاء العمارة',
      coordinates: const LatLng(31.8490, 47.1560),
    ),
    MaysanLocation(
      nameAr: 'كورنيش العمارة (شارع دجلة)',
      nameEn: 'Al-Amarah Corniche (Tigris St)',
      districtAr: 'قضاء العمارة',
      coordinates: const LatLng(31.8390, 47.1450),
    ),
    MaysanLocation(
      nameAr: 'مجمع ميسان التجاري (ميسان مول)',
      nameEn: 'Maysan Mall',
      districtAr: 'قضاء العمارة',
      coordinates: const LatLng(31.8430, 47.1460),
    ),
    MaysanLocation(
      nameAr: 'حي المعلمين الجديد',
      nameEn: 'New Al-Muallimeen District',
      districtAr: 'قضاء العمارة',
      coordinates: const LatLng(31.8510, 47.1650),
    ),
    MaysanLocation(
      nameAr: 'حي المعلمين القديم',
      nameEn: 'Old Al-Muallimeen District',
      districtAr: 'قضاء العمارة',
      coordinates: const LatLng(31.8490, 47.1620),
    ),
    MaysanLocation(
      nameAr: 'حي الماجدية',
      nameEn: 'Al-Majidiya District',
      districtAr: 'قضاء العمارة',
      coordinates: const LatLng(31.8520, 47.1350),
    ),
    MaysanLocation(
      nameAr: 'حي الحسين (ع)',
      nameEn: 'Al-Hussein District',
      districtAr: 'قضاء العمارة',
      coordinates: const LatLng(31.8285, 47.1360),
    ),
    MaysanLocation(
      nameAr: 'حي القاهرة',
      nameEn: 'Al-Qahira District',
      districtAr: 'قضاء العمارة',
      coordinates: const LatLng(31.8590, 47.1470),
    ),
    MaysanLocation(
      nameAr: 'حي الدفاف',
      nameEn: 'Al-Dafaf District',
      districtAr: 'قضاء العمارة',
      coordinates: const LatLng(31.8475, 47.1320),
    ),
    MaysanLocation(
      nameAr: 'حي العروبة',
      nameEn: 'Al-Orouba District',
      districtAr: 'قضاء العمارة',
      coordinates: const LatLng(31.8540, 47.1530),
    ),
    MaysanLocation(
      nameAr: 'حي العسكري',
      nameEn: 'Al-Askari District',
      districtAr: 'قضاء العمارة',
      coordinates: const LatLng(31.8445, 47.1350),
    ),
    MaysanLocation(
      nameAr: 'حي الشرطة',
      nameEn: 'Al-Shorta District',
      districtAr: 'قضاء العمارة',
      coordinates: const LatLng(31.8420, 47.1360),
    ),
    MaysanLocation(
      nameAr: 'حي الشبانة',
      nameEn: 'Al-Shabbana District',
      districtAr: 'قضاء العمارة',
      coordinates: const LatLng(31.8480, 47.1420),
    ),
    MaysanLocation(
      nameAr: 'حي الشهداء',
      nameEn: 'Al-Shohadaa District',
      districtAr: 'قضاء العمارة',
      coordinates: const LatLng(31.8570, 47.1400),
    ),
    MaysanLocation(
      nameAr: 'حي الخليج العربي',
      nameEn: 'Arabian Gulf District',
      districtAr: 'قضاء العمارة',
      coordinates: const LatLng(31.8360, 47.1580),
    ),
    MaysanLocation(
      nameAr: 'حي الرسالة',
      nameEn: 'Al-Risala District',
      districtAr: 'قضاء العمارة',
      coordinates: const LatLng(31.8450, 47.1680),
    ),
    MaysanLocation(
      nameAr: 'حي الوحدة',
      nameEn: 'Al-Wahda District',
      districtAr: 'قضاء العمارة',
      coordinates: const LatLng(31.8530, 47.1720),
    ),
    MaysanLocation(
      nameAr: 'حي نهاوند',
      nameEn: 'Nahawand District',
      districtAr: 'قضاء العمارة',
      coordinates: const LatLng(31.8390, 47.1270),
    ),
    MaysanLocation(
      nameAr: 'ملعب ميسان الأولمبي',
      nameEn: 'Maysan Olympic Stadium',
      districtAr: 'قضاء العمارة',
      coordinates: const LatLng(31.8580, 47.1620),
    ),
    MaysanLocation(
      nameAr: 'كراج بغداد الموحد',
      nameEn: 'Baghdad Bus Garage',
      districtAr: 'قضاء العمارة',
      coordinates: const LatLng(31.8620, 47.1420),
    ),
    MaysanLocation(
      nameAr: 'كراج البصرة الموحد',
      nameEn: 'Basra Bus Garage',
      districtAr: 'قضاء العمارة',
      coordinates: const LatLng(31.8290, 47.1480),
    ),

    // Districts & Sub-districts of Maysan Governorate
    MaysanLocation(
      nameAr: 'قضاء الميمونة',
      nameEn: 'Al-Maymouna District',
      districtAr: 'قضاء الميمونة',
      coordinates: const LatLng(31.7050, 46.9620),
    ),
    MaysanLocation(
      nameAr: 'قضاء المجر الكبير',
      nameEn: 'Al-Majar Al-Kabir District',
      districtAr: 'قضاء المجر الكبير',
      coordinates: const LatLng(31.5830, 47.1650),
    ),
    MaysanLocation(
      nameAr: 'قضاء قلعة صالح',
      nameEn: 'Qalat Saleh District',
      districtAr: 'قضاء قلعة صالح',
      coordinates: const LatLng(31.5120, 47.2880),
    ),
    MaysanLocation(
      nameAr: 'قضاء علي الغربي',
      nameEn: 'Ali Al-Gharbi District',
      districtAr: 'قضاء علي الغربي',
      coordinates: const LatLng(32.4630, 46.6890),
    ),
    MaysanLocation(
      nameAr: 'قضاء الكحلاء',
      nameEn: 'Al-Kahla District',
      districtAr: 'قضاء الكحلاء',
      coordinates: const LatLng(31.7080, 47.3020),
    ),
    MaysanLocation(
      nameAr: 'ناحية المشرح',
      nameEn: 'Al-Musharrah Sub-district',
      districtAr: 'ناحية المشرح',
      coordinates: const LatLng(31.8150, 47.3450),
    ),
    MaysanLocation(
      nameAr: 'ناحية علي الشرقي',
      nameEn: 'Ali Al-Sharqi Sub-district',
      districtAr: 'ناحية علي الشرقي',
      coordinates: const LatLng(32.1800, 46.9000),
    ),
    MaysanLocation(
      nameAr: 'ناحية كميت',
      nameEn: 'Kumayt Sub-district',
      districtAr: 'ناحية كميت',
      coordinates: const LatLng(32.0620, 47.0100),
    ),
    MaysanLocation(
      nameAr: 'ناحية السلام',
      nameEn: 'Al-Salam Sub-district',
      districtAr: 'ناحية السلام',
      coordinates: const LatLng(31.6200, 46.9100),
    ),
    MaysanLocation(
      nameAr: 'ناحية العدل',
      nameEn: 'Al-Adl Sub-district',
      districtAr: 'ناحية العدل',
      coordinates: const LatLng(31.5200, 47.0800),
    ),
    MaysanLocation(
      nameAr: 'ناحية العزير',
      nameEn: 'Al-Uzayr Sub-district',
      districtAr: 'ناحية العزير',
      coordinates: const LatLng(31.3200, 47.4200),
    ),
    MaysanLocation(
      nameAr: 'ناحية بني هاشم',
      nameEn: 'Bani Hashim Sub-district',
      districtAr: 'ناحية بني هاشم',
      coordinates: const LatLng(31.7500, 47.4500),
    ),
  ];
}

class MaysanLocation {
  final String nameAr;
  final String nameEn;
  final String districtAr;
  final LatLng coordinates;
  final bool isCenter;

  const MaysanLocation({
    required this.nameAr,
    required this.nameEn,
    required this.districtAr,
    required this.coordinates,
    this.isCenter = false,
  });
}
