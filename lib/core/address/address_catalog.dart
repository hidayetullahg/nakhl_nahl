// ==============================================================================
// NAKHL & NAHL — EVRENSEL HİYERARŞİK ADRES KATALOĞU (ADDRESS CATALOG)
// Suudi Arabistan, Türkiye, BAE, Almanya, Mısır ve Diğer Ülkeler
// ==============================================================================

class AddressRegion {
  final String code;
  final String name;
  final String nativeName;
  final String countryCode;

  const AddressRegion({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.countryCode,
  });
}

class AddressCity {
  final String name;
  final String nativeName;
  final String regionCode;
  final String countryCode;

  const AddressCity({
    required this.name,
    required this.nativeName,
    required this.regionCode,
    required this.countryCode,
  });
}

class AddressDistrict {
  final String name;
  final String nativeName;
  final String cityName;
  final String? postalCodePrefix;

  const AddressDistrict({
    required this.name,
    required this.nativeName,
    required this.cityName,
    this.postalCodePrefix,
  });
}

class AddressNeighborhood {
  final String name;
  final String districtName;
  final String postalCode;

  const AddressNeighborhood({
    required this.name,
    required this.districtName,
    required this.postalCode,
  });
}

class AddressCatalog {
  AddressCatalog._();

  // ── 1. BÖLGELER (REGIONS / PROVINCES) ──
  static const List<AddressRegion> regions = [
    // Suudi Arabistan (13 İdari Bölge)
    AddressRegion(countryCode: 'SA', code: 'SA-01', name: 'Riyad Bölgesi', nativeName: 'منطقة الرياض'),
    AddressRegion(countryCode: 'SA', code: 'SA-02', name: 'Mekke Bölgesi', nativeName: 'منطقة مكة المكرمة'),
    AddressRegion(countryCode: 'SA', code: 'SA-03', name: 'Medine Bölgesi', nativeName: 'منطقة المدينة المنورة'),
    AddressRegion(countryCode: 'SA', code: 'SA-04', name: 'Doğu Bölgesi (Şarkiye)', nativeName: 'المنطقة الشرقية'),
    AddressRegion(countryCode: 'SA', code: 'SA-05', name: 'El-Kasım Bölgesi', nativeName: 'منطقة القصيم'),
    AddressRegion(countryCode: 'SA', code: 'SA-06', name: 'Asir Bölgesi', nativeName: 'منطقة عسير'),
    AddressRegion(countryCode: 'SA', code: 'SA-07', name: 'Tebük Bölgesi', nativeName: 'منطقة تبوك'),
    AddressRegion(countryCode: 'SA', code: 'SA-08', name: 'Hail Bölgesi', nativeName: 'منطقة حائل'),
    AddressRegion(countryCode: 'SA', code: 'SA-09', name: 'Kuzey Sınır Bölgesi', nativeName: 'منطقة الحدود الشمالية'),
    AddressRegion(countryCode: 'SA', code: 'SA-10', name: 'Cazan Bölgesi', nativeName: 'منطقة جازان'),
    AddressRegion(countryCode: 'SA', code: 'SA-11', name: 'Necran Bölgesi', nativeName: 'منطقة نجران'),
    AddressRegion(countryCode: 'SA', code: 'SA-12', name: 'El-Baha Bölgesi', nativeName: 'منطقة الباحة'),
    AddressRegion(countryCode: 'SA', code: 'SA-14', name: 'El-Cevf Bölgesi', nativeName: 'منطقة الجوف'),

    // Türkiye (7 Coğrafi Bölge)
    AddressRegion(countryCode: 'TR', code: 'TR-MAR', name: 'Marmara Bölgesi', nativeName: 'Marmara'),
    AddressRegion(countryCode: 'TR', code: 'TR-ICA', name: 'İç Anadolu Bölgesi', nativeName: 'İç Anadolu'),
    AddressRegion(countryCode: 'TR', code: 'TR-EGE', name: 'Ege Bölgesi', nativeName: 'Ege'),
    AddressRegion(countryCode: 'TR', code: 'TR-AKD', name: 'Akdeniz Bölgesi', nativeName: 'Akdeniz'),
    AddressRegion(countryCode: 'TR', code: 'TR-GDA', name: 'Güneydoğu Anadolu Bölgesi', nativeName: 'Güneydoğu Anadolu'),
    AddressRegion(countryCode: 'TR', code: 'TR-KAR', name: 'Karadeniz Bölgesi', nativeName: 'Karadeniz'),
    AddressRegion(countryCode: 'TR', code: 'TR-DOA', name: 'Doğu Anadolu Bölgesi', nativeName: 'Doğu Anadolu'),

    // BAE (7 Emirlik)
    AddressRegion(countryCode: 'AE', code: 'AE-DU', name: 'Dubai', nativeName: 'دبي'),
    AddressRegion(countryCode: 'AE', code: 'AE-AZ', name: 'Abu Dabi', nativeName: 'أبو ظبي'),
    AddressRegion(countryCode: 'AE', code: 'AE-SH', name: 'Şarika (Sharjah)', nativeName: 'الشارقة'),
    AddressRegion(countryCode: 'AE', code: 'AE-AJ', name: 'Acman', nativeName: 'عجمان'),
    AddressRegion(countryCode: 'AE', code: 'AE-RK', name: 'Resü\'l-Hayme', nativeName: 'رأس الخيمة'),
    AddressRegion(countryCode: 'AE', code: 'AE-FU', name: 'Füceyre', nativeName: 'الفجيرة'),
    AddressRegion(countryCode: 'AE', code: 'AE-UQ', name: 'Ümmü\'l-Kayveyn', nativeName: 'أم القيوين'),

    // Almanya (Öne Çıkan Eyaletler)
    AddressRegion(countryCode: 'DE', code: 'DE-BY', name: 'Bayern (Bavyera)', nativeName: 'Bayern'),
    AddressRegion(countryCode: 'DE', code: 'DE-BW', name: 'Baden-Württemberg', nativeName: 'Baden-Württemberg'),
    AddressRegion(countryCode: 'DE', code: 'DE-NW', name: 'Nordrhein-Westfalen', nativeName: 'Nordrhein-Westfalen'),
    AddressRegion(countryCode: 'DE', code: 'DE-HE', name: 'Hessen', nativeName: 'Hessen'),
    AddressRegion(countryCode: 'DE', code: 'DE-BE', name: 'Berlin', nativeName: 'Berlin'),
    AddressRegion(countryCode: 'DE', code: 'DE-HH', name: 'Hamburg', nativeName: 'Hamburg'),

    // Mısır
    AddressRegion(countryCode: 'EG', code: 'EG-C', name: 'Kahire Valiliği', nativeName: 'محافظة القاهرة'),
    AddressRegion(countryCode: 'EG', code: 'EG-ALX', name: 'İskenderiye Valiliği', nativeName: 'محافظة الإسكندرية'),
    AddressRegion(countryCode: 'EG', code: 'EG-GZ', name: 'Gize Valiliği', nativeName: 'محافظة الجيزة'),
  ];

  // ── 2. ŞEHİRLER (CITIES) ──
  static const List<AddressCity> cities = [
    // Suudi Arabistan Şehirleri
    AddressCity(countryCode: 'SA', regionCode: 'SA-01', name: 'Riyad', nativeName: 'الرياض'),
    AddressCity(countryCode: 'SA', regionCode: 'SA-01', name: 'El-Harc', nativeName: 'الخرج'),
    AddressCity(countryCode: 'SA', regionCode: 'SA-01', name: 'ed-Diriye', nativeName: 'الدرعية'),
    AddressCity(countryCode: 'SA', regionCode: 'SA-01', name: 'El-Mecmea', nativeName: 'المجمعة'),
    AddressCity(countryCode: 'SA', regionCode: 'SA-02', name: 'Cidde', nativeName: 'جدة'),
    AddressCity(countryCode: 'SA', regionCode: 'SA-02', name: 'Mekke-i Mükerreme', nativeName: 'مكة المكرمة'),
    AddressCity(countryCode: 'SA', regionCode: 'SA-02', name: 'Taif', nativeName: 'الطائف'),
    AddressCity(countryCode: 'SA', regionCode: 'SA-02', name: 'Rabığ', nativeName: 'رابغ'),
    AddressCity(countryCode: 'SA', regionCode: 'SA-03', name: 'Medine-i Münevvere', nativeName: 'المدينة المنورة'),
    AddressCity(countryCode: 'SA', regionCode: 'SA-03', name: 'Yanbu', nativeName: 'ينبع'),
    AddressCity(countryCode: 'SA', regionCode: 'SA-03', name: 'El-Ula', nativeName: 'العلا'),
    AddressCity(countryCode: 'SA', regionCode: 'SA-03', name: 'Bedir', nativeName: 'بدر'),
    AddressCity(countryCode: 'SA', regionCode: 'SA-04', name: 'Dammam', nativeName: 'الدمام'),
    AddressCity(countryCode: 'SA', regionCode: 'SA-04', name: 'El-Huber', nativeName: 'الخبر'),
    AddressCity(countryCode: 'SA', regionCode: 'SA-04', name: 'Cubeyl', nativeName: 'الجبيل'),
    AddressCity(countryCode: 'SA', regionCode: 'SA-04', name: 'El-Ahsa (Hufuf)', nativeName: 'الأحساء / الهفوف'),
    AddressCity(countryCode: 'SA', regionCode: 'SA-04', name: 'Katif', nativeName: 'القطيف'),
    AddressCity(countryCode: 'SA', regionCode: 'SA-05', name: 'Burayde', nativeName: 'بريدة'),
    AddressCity(countryCode: 'SA', regionCode: 'SA-05', name: 'Uneyze', nativeName: 'عنيزة'),
    AddressCity(countryCode: 'SA', regionCode: 'SA-06', name: 'Ebha', nativeName: 'أبها'),
    AddressCity(countryCode: 'SA', regionCode: 'SA-06', name: 'Hamis Müşayt', nativeName: 'خميس مشيط'),
    AddressCity(countryCode: 'SA', regionCode: 'SA-07', name: 'Tebük', nativeName: 'تبوك'),
    AddressCity(countryCode: 'SA', regionCode: 'SA-08', name: 'Hail', nativeName: 'حائل'),
    AddressCity(countryCode: 'SA', regionCode: 'SA-10', name: 'Cazan', nativeName: 'جازان'),
    AddressCity(countryCode: 'SA', regionCode: 'SA-11', name: 'Necran', nativeName: 'نجران'),

    // Türkiye Şehirleri (Öncü İller)
    AddressCity(countryCode: 'TR', regionCode: 'TR-MAR', name: 'İstanbul', nativeName: 'İstanbul'),
    AddressCity(countryCode: 'TR', regionCode: 'TR-MAR', name: 'Bursa', nativeName: 'Bursa'),
    AddressCity(countryCode: 'TR', regionCode: 'TR-MAR', name: 'Kocaeli', nativeName: 'Kocaeli'),
    AddressCity(countryCode: 'TR', regionCode: 'TR-MAR', name: 'Sakarya', nativeName: 'Sakarya'),
    AddressCity(countryCode: 'TR', regionCode: 'TR-MAR', name: 'Tekirdağ', nativeName: 'Tekirdağ'),
    AddressCity(countryCode: 'TR', regionCode: 'TR-MAR', name: 'Balıkesir', nativeName: 'Balıkesir'),
    AddressCity(countryCode: 'TR', regionCode: 'TR-MAR', name: 'Çanakkale', nativeName: 'Çanakkale'),
    AddressCity(countryCode: 'TR', regionCode: 'TR-MAR', name: 'Yalova', nativeName: 'Yalova'),
    AddressCity(countryCode: 'TR', regionCode: 'TR-MAR', name: 'Edirne', nativeName: 'Edirne'),
    AddressCity(countryCode: 'TR', regionCode: 'TR-ICA', name: 'Ankara', nativeName: 'Ankara'),
    AddressCity(countryCode: 'TR', regionCode: 'TR-ICA', name: 'Konya', nativeName: 'Konya'),
    AddressCity(countryCode: 'TR', regionCode: 'TR-ICA', name: 'Kayseri', nativeName: 'Kayseri'),
    AddressCity(countryCode: 'TR', regionCode: 'TR-ICA', name: 'Eskişehir', nativeName: 'Eskişehir'),
    AddressCity(countryCode: 'TR', regionCode: 'TR-ICA', name: 'Sivas', nativeName: 'Sivas'),
    AddressCity(countryCode: 'TR', regionCode: 'TR-EGE', name: 'İzmir', nativeName: 'İzmir'),
    AddressCity(countryCode: 'TR', regionCode: 'TR-EGE', name: 'Manisa', nativeName: 'Manisa'),
    AddressCity(countryCode: 'TR', regionCode: 'TR-EGE', name: 'Denizli', nativeName: 'Denizli'),
    AddressCity(countryCode: 'TR', regionCode: 'TR-EGE', name: 'Aydın', nativeName: 'Aydın'),
    AddressCity(countryCode: 'TR', regionCode: 'TR-EGE', name: 'Muğla', nativeName: 'Muğla'),
    AddressCity(countryCode: 'TR', regionCode: 'TR-AKD', name: 'Antalya', nativeName: 'Antalya'),
    AddressCity(countryCode: 'TR', regionCode: 'TR-AKD', name: 'Adana', nativeName: 'Adana'),
    AddressCity(countryCode: 'TR', regionCode: 'TR-AKD', name: 'Mersin', nativeName: 'Mersin'),
    AddressCity(countryCode: 'TR', regionCode: 'TR-AKD', name: 'Hatay', nativeName: 'Hatay'),
    AddressCity(countryCode: 'TR', regionCode: 'TR-GDA', name: 'Gaziantep', nativeName: 'Gaziantep'),
    AddressCity(countryCode: 'TR', regionCode: 'TR-GDA', name: 'Şanlıurfa', nativeName: 'Şanlıurfa'),
    AddressCity(countryCode: 'TR', regionCode: 'TR-GDA', name: 'Diyarbakır', nativeName: 'Diyarbakır'),
    AddressCity(countryCode: 'TR', regionCode: 'TR-GDA', name: 'Mardin', nativeName: 'Mardin'),
    AddressCity(countryCode: 'TR', regionCode: 'TR-KAR', name: 'Samsun', nativeName: 'Samsun'),
    AddressCity(countryCode: 'TR', regionCode: 'TR-KAR', name: 'Trabzon', nativeName: 'Trabzon'),
    AddressCity(countryCode: 'TR', regionCode: 'TR-DOA', name: 'Erzurum', nativeName: 'Erzurum'),
    AddressCity(countryCode: 'TR', regionCode: 'TR-DOA', name: 'Malatya', nativeName: 'Malatya'),
    AddressCity(countryCode: 'TR', regionCode: 'TR-DOA', name: 'Van', nativeName: 'Van'),

    // BAE Şehirleri
    AddressCity(countryCode: 'AE', regionCode: 'AE-DU', name: 'Dubai', nativeName: 'دبي'),
    AddressCity(countryCode: 'AE', regionCode: 'AE-AZ', name: 'Abu Dabi', nativeName: 'أبو ظبي'),
    AddressCity(countryCode: 'AE', regionCode: 'AE-AZ', name: 'Al Ain', nativeName: 'العين'),
    AddressCity(countryCode: 'AE', regionCode: 'AE-SH', name: 'Şarika', nativeName: 'الشارقة'),

    // Almanya Şehirleri
    AddressCity(countryCode: 'DE', regionCode: 'DE-BE', name: 'Berlin', nativeName: 'Berlin'),
    AddressCity(countryCode: 'DE', regionCode: 'DE-BY', name: 'Münih (München)', nativeName: 'München'),
    AddressCity(countryCode: 'DE', regionCode: 'DE-BY', name: 'Nürnberg', nativeName: 'Nürnberg'),
    AddressCity(countryCode: 'DE', regionCode: 'DE-HE', name: 'Frankfurt am Main', nativeName: 'Frankfurt'),
    AddressCity(countryCode: 'DE', regionCode: 'DE-NW', name: 'Köln', nativeName: 'Köln'),
    AddressCity(countryCode: 'DE', regionCode: 'DE-NW', name: 'Düsseldorf', nativeName: 'Düsseldorf'),
    AddressCity(countryCode: 'DE', regionCode: 'DE-NW', name: 'Dortmund', nativeName: 'Dortmund'),
    AddressCity(countryCode: 'DE', regionCode: 'DE-BW', name: 'Stuttgart', nativeName: 'Stuttgart'),
    AddressCity(countryCode: 'DE', regionCode: 'DE-HH', name: 'Hamburg', nativeName: 'Hamburg'),

    // Mısır Şehirleri
    AddressCity(countryCode: 'EG', regionCode: 'EG-C', name: 'Kahire (Cairo)', nativeName: 'القاهرة'),
    AddressCity(countryCode: 'EG', regionCode: 'EG-ALX', name: 'İskenderiye', nativeName: 'الإسكندرية'),
    AddressCity(countryCode: 'EG', regionCode: 'EG-GZ', name: 'Gize', nativeName: 'الجيزة'),
  ];

  // ── 3. İLÇELER (DISTRICTS) ──
  static const List<AddressDistrict> districts = [
    // Suudi Arabistan - Riyad İlçeleri
    AddressDistrict(cityName: 'Riyad', name: 'El-Olaya', nativeName: 'العليا', postalCodePrefix: '12211'),
    AddressDistrict(cityName: 'Riyad', name: 'El-Malaz', nativeName: 'الملز', postalCodePrefix: '12831'),
    AddressDistrict(cityName: 'Riyad', name: 'El-Murabba', nativeName: 'المربع', postalCodePrefix: '12612'),
    AddressDistrict(cityName: 'Riyad', name: 'El-Yasmin', nativeName: 'الياسمين', postalCodePrefix: '13322'),
    AddressDistrict(cityName: 'Riyad', name: 'El-Sahafa', nativeName: 'الصحافة', postalCodePrefix: '13315'),
    AddressDistrict(cityName: 'Riyad', name: 'El-Suleymaniye', nativeName: 'السليمانية', postalCodePrefix: '12242'),
    AddressDistrict(cityName: 'Riyad', name: 'En-Nefel', nativeName: 'النفل', postalCodePrefix: '13312'),
    AddressDistrict(cityName: 'Riyad', name: 'Hittin', nativeName: 'حطين', postalCodePrefix: '13512'),
    AddressDistrict(cityName: 'Riyad', name: 'El-Aqiq', nativeName: 'العقيق', postalCodePrefix: '13515'),
    AddressDistrict(cityName: 'Riyad', name: 'El-Wurud', nativeName: 'الورود', postalCodePrefix: '12252'),
    AddressDistrict(cityName: 'Riyad', name: 'Qurtubah', nativeName: 'قرطبة', postalCodePrefix: '13245'),

    // Suudi Arabistan - Medine İlçeleri
    AddressDistrict(cityName: 'Medine-i Münevvere', name: 'Merkez / El-Harem', nativeName: 'المنطقة المركزية / الحرم', postalCodePrefix: '42311'),
    AddressDistrict(cityName: 'Medine-i Münevvere', name: 'Kuba', nativeName: 'قباء', postalCodePrefix: '42315'),
    AddressDistrict(cityName: 'Medine-i Münevvere', name: 'Uhud', nativeName: 'أحد', postalCodePrefix: '42321'),
    AddressDistrict(cityName: 'Medine-i Münevvere', name: 'El-Halidiyye', nativeName: 'الخالدية', postalCodePrefix: '42317'),
    AddressDistrict(cityName: 'Medine-i Münevvere', name: 'Seyyidü\'ş-Şüheda', nativeName: 'سيد الشهداء', postalCodePrefix: '42323'),
    AddressDistrict(cityName: 'Medine-i Münevvere', name: 'El-İstiklal', nativeName: 'الاستقلال', postalCodePrefix: '42319'),
    AddressDistrict(cityName: 'Medine-i Münevvere', name: 'El-Baki', nativeName: 'البقيع', postalCodePrefix: '42312'),
    AddressDistrict(cityName: 'Medine-i Münevvere', name: 'El-Uyun', nativeName: 'العيون', postalCodePrefix: '42331'),

    // Suudi Arabistan - Cidde İlçeleri
    AddressDistrict(cityName: 'Cidde', name: 'El-Balad (Tarihi Bölge)', nativeName: 'البلد', postalCodePrefix: '22233'),
    AddressDistrict(cityName: 'Cidde', name: 'El-Hamra', nativeName: 'الحمراء', postalCodePrefix: '23212'),
    AddressDistrict(cityName: 'Cidde', name: 'El-Rawdah', nativeName: 'الروضة', postalCodePrefix: '23432'),
    AddressDistrict(cityName: 'Cidde', name: 'El-Shati (Kordon)', nativeName: 'الشاطئ', postalCodePrefix: '23513'),
    AddressDistrict(cityName: 'Cidde', name: 'El-Mohammadiyyah', nativeName: 'المحمدية', postalCodePrefix: '23617'),
    AddressDistrict(cityName: 'Cidde', name: 'Al-Safa', nativeName: 'الصفا', postalCodePrefix: '23451'),
    AddressDistrict(cityName: 'Cidde', name: 'Obhur', nativeName: 'أبحر الشمالية', postalCodePrefix: '23811'),

    // Suudi Arabistan - Mekke İlçeleri
    AddressDistrict(cityName: 'Mekke-i Mükerreme', name: 'Merkez / El-Harem', nativeName: 'المنطقة المركزية', postalCodePrefix: '24231'),
    AddressDistrict(cityName: 'Mekke-i Mükerreme', name: 'El-Aziziyah', nativeName: 'العزيزية', postalCodePrefix: '24243'),
    AddressDistrict(cityName: 'Mekke-i Mükerreme', name: 'El-Shawqiyyah', nativeName: 'الشوقية', postalCodePrefix: '24351'),
    AddressDistrict(cityName: 'Mekke-i Mükerreme', name: 'El-Rusaifah', nativeName: 'الرصيفة', postalCodePrefix: '24232'),
    AddressDistrict(cityName: 'Mekke-i Mükerreme', name: 'Mina', nativeName: 'منى', postalCodePrefix: '24247'),

    // Suudi Arabistan - Dammam & Huber
    AddressDistrict(cityName: 'Dammam', name: 'El-Shati', nativeName: 'الشاطئ الغربي', postalCodePrefix: '32413'),
    AddressDistrict(cityName: 'Dammam', name: 'El-Faisaliyah', nativeName: 'الفيصلية', postalCodePrefix: '32272'),
    AddressDistrict(cityName: 'El-Huber', name: 'Corniche', nativeName: 'الكورنيش', postalCodePrefix: '34412'),
    AddressDistrict(cityName: 'El-Huber', name: 'Al-Bandariyah', nativeName: 'البندرية', postalCodePrefix: '34423'),

    // Türkiye - İstanbul İlçeleri
    AddressDistrict(cityName: 'İstanbul', name: 'Fatih', nativeName: 'Fatih', postalCodePrefix: '34080'),
    AddressDistrict(cityName: 'İstanbul', name: 'Kadıköy', nativeName: 'Kadıköy', postalCodePrefix: '34710'),
    AddressDistrict(cityName: 'İstanbul', name: 'Şişli', nativeName: 'Şişli', postalCodePrefix: '34360'),
    AddressDistrict(cityName: 'İstanbul', name: 'Beşiktaş', nativeName: 'Beşiktaş', postalCodePrefix: '34353'),
    AddressDistrict(cityName: 'İstanbul', name: 'Üsküdar', nativeName: 'Üsküdar', postalCodePrefix: '34664'),
    AddressDistrict(cityName: 'İstanbul', name: 'Bakırköy', nativeName: 'Bakırköy', postalCodePrefix: '34140'),
    AddressDistrict(cityName: 'İstanbul', name: 'Başakşehir', nativeName: 'Başakşehir', postalCodePrefix: '34480'),
    AddressDistrict(cityName: 'İstanbul', name: 'Beyoğlu', nativeName: 'Beyoğlu', postalCodePrefix: '34430'),
    AddressDistrict(cityName: 'İstanbul', name: 'Pendik', nativeName: 'Pendik', postalCodePrefix: '34890'),
    AddressDistrict(cityName: 'İstanbul', name: 'Ümraniye', nativeName: 'Ümraniye', postalCodePrefix: '34760'),
    AddressDistrict(cityName: 'İstanbul', name: 'Zeytinburnu', nativeName: 'Zeytinburnu', postalCodePrefix: '34020'),
    AddressDistrict(cityName: 'İstanbul', name: 'Esenyurt', nativeName: 'Esenyurt', postalCodePrefix: '34510'),
    AddressDistrict(cityName: 'İstanbul', name: 'Sarıyer', nativeName: 'Sarıyer', postalCodePrefix: '34450'),
    AddressDistrict(cityName: 'İstanbul', name: 'Ataşehir', nativeName: 'Ataşehir', postalCodePrefix: '34758'),
    AddressDistrict(cityName: 'İstanbul', name: 'Kartal', nativeName: 'Kartal', postalCodePrefix: '34860'),

    // Türkiye - Ankara İlçeleri
    AddressDistrict(cityName: 'Ankara', name: 'Çankaya', nativeName: 'Çankaya', postalCodePrefix: '06690'),
    AddressDistrict(cityName: 'Ankara', name: 'Yenimahalle', nativeName: 'Yenimahalle', postalCodePrefix: '06170'),
    AddressDistrict(cityName: 'Ankara', name: 'Keçiören', nativeName: 'Keçiören', postalCodePrefix: '06280'),
    AddressDistrict(cityName: 'Ankara', name: 'Mamak', nativeName: 'Mamak', postalCodePrefix: '06260'),
    AddressDistrict(cityName: 'Ankara', name: 'Altındağ', nativeName: 'Altındağ', postalCodePrefix: '06030'),
    AddressDistrict(cityName: 'Ankara', name: 'Etimesgut', nativeName: 'Etimesgut', postalCodePrefix: '06790'),
    AddressDistrict(cityName: 'Ankara', name: 'Gölbaşı', nativeName: 'Gölbaşı', postalCodePrefix: '06830'),

    // Türkiye - İzmir İlçeleri
    AddressDistrict(cityName: 'İzmir', name: 'Konak', nativeName: 'Konak', postalCodePrefix: '35250'),
    AddressDistrict(cityName: 'İzmir', name: 'Karşıyaka', nativeName: 'Karşıyaka', postalCodePrefix: '35580'),
    AddressDistrict(cityName: 'İzmir', name: 'Bornova', nativeName: 'Bornova', postalCodePrefix: '35040'),
    AddressDistrict(cityName: 'İzmir', name: 'Buca', nativeName: 'Buca', postalCodePrefix: '35390'),
    AddressDistrict(cityName: 'İzmir', name: 'Bayraklı', nativeName: 'Bayraklı', postalCodePrefix: '35530'),

    // Türkiye - Bursa & Antalya
    AddressDistrict(cityName: 'Bursa', name: 'Osmangazi', nativeName: 'Osmangazi', postalCodePrefix: '16040'),
    AddressDistrict(cityName: 'Bursa', name: 'Nilüfer', nativeName: 'Nilüfer', postalCodePrefix: '16140'),
    AddressDistrict(cityName: 'Bursa', name: 'Yıldırım', nativeName: 'Yıldırım', postalCodePrefix: '16320'),
    AddressDistrict(cityName: 'Antalya', name: 'Muratpaşa', nativeName: 'Muratpaşa', postalCodePrefix: '07040'),
    AddressDistrict(cityName: 'Antalya', name: 'Konyaaltı', nativeName: 'Konyaaltı', postalCodePrefix: '07070'),
    AddressDistrict(cityName: 'Antalya', name: 'Kepez', nativeName: 'Kepez', postalCodePrefix: '07025'),
    AddressDistrict(cityName: 'Antalya', name: 'Alanya', nativeName: 'Alanya', postalCodePrefix: '07400'),

    // BAE - Dubai & Abu Dabi İlçeleri
    AddressDistrict(cityName: 'Dubai', name: 'Downtown Dubai', nativeName: 'وسط مدينة دبي', postalCodePrefix: '00000'),
    AddressDistrict(cityName: 'Dubai', name: 'Business Bay', nativeName: 'الخليج التجاري', postalCodePrefix: '00000'),
    AddressDistrict(cityName: 'Dubai', name: 'Deira', nativeName: 'ديرة', postalCodePrefix: '00000'),
    AddressDistrict(cityName: 'Dubai', name: 'Bur Dubai', nativeName: 'بر دبي', postalCodePrefix: '00000'),
    AddressDistrict(cityName: 'Dubai', name: 'Dubai Marina', nativeName: 'مرسى دبي', postalCodePrefix: '00000'),
    AddressDistrict(cityName: 'Dubai', name: 'Al Barsha', nativeName: 'البرشاء', postalCodePrefix: '00000'),
    AddressDistrict(cityName: 'Dubai', name: 'Jebel Ali (Serbest Bölge)', nativeName: 'جبل علي', postalCodePrefix: '00000'),
    AddressDistrict(cityName: 'Abu Dabi', name: 'Corniche / Al Khalidiya', nativeName: 'الخالدية', postalCodePrefix: '00000'),
    AddressDistrict(cityName: 'Abu Dabi', name: 'Al Reem Island', nativeName: 'جزيرة الريم', postalCodePrefix: '00000'),

    // Almanya - Berlin & Münih
    AddressDistrict(cityName: 'Berlin', name: 'Mitte', nativeName: 'Mitte', postalCodePrefix: '10115'),
    AddressDistrict(cityName: 'Berlin', name: 'Charlottenburg', nativeName: 'Charlottenburg', postalCodePrefix: '10585'),
    AddressDistrict(cityName: 'Berlin', name: 'Kreuzberg', nativeName: 'Kreuzberg', postalCodePrefix: '10961'),
    AddressDistrict(cityName: 'Münih (München)', name: 'Altstadt-Lehel', nativeName: 'Altstadt', postalCodePrefix: '80331'),
    AddressDistrict(cityName: 'Münih (München)', name: 'Schwabing', nativeName: 'Schwabing', postalCodePrefix: '80802'),
    AddressDistrict(cityName: 'Frankfurt am Main', name: 'Innenstadt / Financial Dist.', nativeName: 'Innenstadt', postalCodePrefix: '60311'),
  ];

  // ── 4. MAHALLELER (NEIGHBORHOODS) ──
  static const List<AddressNeighborhood> neighborhoods = [
    // Riyad
    AddressNeighborhood(districtName: 'El-Olaya', name: 'Kral Fahd Yolu Mah.', postalCode: '12211'),
    AddressNeighborhood(districtName: 'El-Olaya', name: 'Al Wurud Kuzey Mah.', postalCode: '12214'),
    AddressNeighborhood(districtName: 'El-Malaz', name: 'Salahuddin Mah.', postalCode: '12831'),
    AddressNeighborhood(districtName: 'El-Malaz', name: 'Al Jami\'ah Mah.', postalCode: '12836'),
    AddressNeighborhood(districtName: 'El-Murabba', name: 'Müze Mah.', postalCode: '12612'),
    AddressNeighborhood(districtName: 'El-Yasmin', name: 'Kuzey Bulvarı Mah.', postalCode: '13322'),
    AddressNeighborhood(districtName: 'El-Sahafa', name: 'Teknoloji Caddesi Mah.', postalCode: '13315'),

    // Medine
    AddressNeighborhood(districtName: 'Merkez / El-Harem', name: 'Mescid-i Nebevi Kuzey', postalCode: '42311'),
    AddressNeighborhood(districtName: 'Merkez / El-Harem', name: 'Mescid-i Nebevi Güney', postalCode: '42312'),
    AddressNeighborhood(districtName: 'Kuba', name: 'Mescid-i Kuba Çevresi', postalCode: '42315'),
    AddressNeighborhood(districtName: 'Uhud', name: 'Şüheda Caddesi Mah.', postalCode: '42321'),
    AddressNeighborhood(districtName: 'El-Halidiyye', name: 'Kral Abdulaziz Yolu', postalCode: '42317'),

    // Cidde
    AddressNeighborhood(districtName: 'El-Hamra', name: 'Filistin Cad. Mah.', postalCode: '23212'),
    AddressNeighborhood(districtName: 'El-Balad', name: 'Eski Liman Mah.', postalCode: '22233'),
    AddressNeighborhood(districtName: 'El-Rawdah', name: 'Prens Muhammed Cad.', postalCode: '23432'),
    AddressNeighborhood(districtName: 'El-Shati (Kordon)', name: 'Korniş Bulvarı Mah.', postalCode: '23513'),

    // Fatih (İstanbul)
    AddressNeighborhood(districtName: 'Fatih', name: 'Akşemsettin Mah.', postalCode: '34080'),
    AddressNeighborhood(districtName: 'Fatih', name: 'Balat Mah.', postalCode: '34087'),
    AddressNeighborhood(districtName: 'Fatih', name: 'İskenderpaşa Mah.', postalCode: '34091'),
    AddressNeighborhood(districtName: 'Fatih', name: 'Molla Gürani Mah.', postalCode: '34093'),
    AddressNeighborhood(districtName: 'Fatih', name: 'Süleymaniye Mah.', postalCode: '34116'),
    AddressNeighborhood(districtName: 'Fatih', name: 'Topkapı Mah.', postalCode: '34093'),

    // Kadıköy (İstanbul)
    AddressNeighborhood(districtName: 'Kadıköy', name: 'Caferağa Mah. (Moda)', postalCode: '34710'),
    AddressNeighborhood(districtName: 'Kadıköy', name: 'Caddebostan Mah.', postalCode: '34728'),
    AddressNeighborhood(districtName: 'Kadıköy', name: 'Fenerbahçe Mah.', postalCode: '34726'),
    AddressNeighborhood(districtName: 'Kadıköy', name: 'Suadiye Mah.', postalCode: '34740'),
    AddressNeighborhood(districtName: 'Kadıköy', name: 'Acıbadem Mah.', postalCode: '34718'),

    // Çankaya (Ankara)
    AddressNeighborhood(districtName: 'Çankaya', name: 'Kızılay Mah.', postalCode: '06420'),
    AddressNeighborhood(districtName: 'Çankaya', name: 'Tunalı Hilmi Mah.', postalCode: '06680'),
    AddressNeighborhood(districtName: 'Çankaya', name: 'Gaziosmanpaşa Mah.', postalCode: '06700'),
    AddressNeighborhood(districtName: 'Çankaya', name: 'Ayrancı Mah.', postalCode: '06540'),

    // Konak (İzmir)
    AddressNeighborhood(districtName: 'Konak', name: 'Alsancak Mah.', postalCode: '35220'),
    AddressNeighborhood(districtName: 'Konak', name: 'Göztepe Mah.', postalCode: '35290'),
  ];

  // ── SORGULAMA VE FİLTRE YARDIMCILARI ──

  /// Belirli bir ülkenin bölgelerini getirir
  static List<AddressRegion> getRegionsByCountry(String countryCode) {
    return regions.where((r) => r.countryCode.toUpperCase() == countryCode.toUpperCase()).toList();
  }

  /// Belirli bir ülkedeki (ve istenirse belirli bir bölgedeki) şehirleri getirir
  static List<AddressCity> getCities({required String countryCode, String? regionCode, String? regionName}) {
    return cities.where((c) {
      if (c.countryCode.toUpperCase() != countryCode.toUpperCase()) return false;
      if (regionCode != null && regionCode.isNotEmpty && c.regionCode != regionCode) return false;
      if (regionName != null && regionName.isNotEmpty) {
        final reg = regions.firstWhere(
          (r) => r.name.toLowerCase() == regionName.toLowerCase() || r.nativeName.toLowerCase() == regionName.toLowerCase(),
          orElse: () => const AddressRegion(code: '', name: '', nativeName: '', countryCode: ''),
        );
        if (reg.code.isNotEmpty && c.regionCode != reg.code) return false;
      }
      return true;
    }).toList();
  }

  /// Belirli bir şehirdeki ilçeleri getirir
  static List<AddressDistrict> getDistrictsByCity(String cityName) {
    if (cityName.isEmpty) return [];
    return districts.where((d) => d.cityName.toLowerCase() == cityName.toLowerCase()).toList();
  }

  /// Belirli bir ilçedeki mahalleleri getirir
  static List<AddressNeighborhood> getNeighborhoodsByDistrict(String districtName) {
    if (districtName.isEmpty) return [];
    return neighborhoods.where((n) => n.districtName.toLowerCase() == districtName.toLowerCase()).toList();
  }
}
