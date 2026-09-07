/// NAKHL & NAHL - Kurumsal ERP Cari Kart Veri Modeli
class CariKart {
  String? id;

  // 1. Temel ve Kimlik Bilgileri
  String cariKodu;
  String unvan;
  String cariTipi; // Musteri, Tedarikci, AliciSatici, Personel, Ortak
  String cariGrubu; // Toptanci, Perakendeci, YurtDisi, YurtIci, vb.
  String ozelKod1;
  String ozelKod2;

  // 2. Yasal ve Vergi Bilgileri
  String vergiDairesi;
  String vergiNo;
  String tckn;
  bool eFaturaMukellefi;
  String eFaturaSenaryosu; // Temel, Ticari
  String eFaturaAlias; // Posta kutusu alias (urn:mail:...)
  String mersisNo;
  String ticaretSicilNo;
  String ulkeKodu;
  String ulkeAdi;
  String vergiTipi;
  String kdvOrani;

  // 3. İletişim Bilgileri
  String faturaAdresi;
  String sevkAdresi;
  String sirketTelefonu;
  String cepTelefonu;
  String alternatifTelefon;
  String eposta;
  String eposta2;
  String webSitesi;
  String sehir;
  String ilce;
  String postaKodu;
  String lokasyon;

  // 4. Finansal ve Muhasebe Bilgileri
  String paraBirimi;
  String muhasebeKodu;
  String bankaAdi;
  String bankaSube;
  String iban;
  String iban2;
  String swiftKodu;
  bool kdvMuaf;
  String kdvMuafiyetKodu;
  String tevkifatKodu;

  // 5. Ticari ve Risk Yönetimi
  double riskLimiti;
  String riskKontrolTipi; // Durdur, Uyar, Serbest
  double teminatTutari;
  String teminatDetayi;
  int vadeGunu;
  String fiyatListesi; // Toptan, Bayi, Perakende
  double iskontoOrani;
  String odemePlani; // Nakit, KrediKarti, Havale, Cek

  // 6. Kurumsal ve Yetkili Kişi
  String yetkiliKisi;
  String yetkiliUnvan;
  String departman;
  String plasiyer;
  bool aktifMi;

  // 7. Takip ve Notlar
  String notlar;
  DateTime kayitTarihi;
  DateTime? guncellemeTarihi;
  String kayitDili;

  CariKart({
    this.id,
    required this.cariKodu,
    required this.unvan,
    this.cariTipi = 'Musteri',
    this.cariGrubu = 'Genel',
    this.ozelKod1 = '',
    this.ozelKod2 = '',
    this.vergiDairesi = '',
    this.vergiNo = '',
    this.tckn = '',
    this.eFaturaMukellefi = false,
    this.eFaturaSenaryosu = 'Temel',
    this.eFaturaAlias = '',
    this.mersisNo = '',
    this.ticaretSicilNo = '',
    required this.ulkeKodu,
    required this.ulkeAdi,
    required this.vergiTipi,
    required this.kdvOrani,
    this.faturaAdresi = '',
    this.sevkAdresi = '',
    this.sirketTelefonu = '',
    this.cepTelefonu = '',
    this.alternatifTelefon = '',
    this.eposta = '',
    this.eposta2 = '',
    this.webSitesi = '',
    this.sehir = '',
    this.ilce = '',
    this.postaKodu = '',
    this.lokasyon = '',
    required this.paraBirimi,
    this.muhasebeKodu = '120.01.001',
    this.bankaAdi = '',
    this.bankaSube = '',
    this.iban = '',
    this.iban2 = '',
    this.swiftKodu = '',
    this.kdvMuaf = false,
    this.kdvMuafiyetKodu = '',
    this.tevkifatKodu = '',
    this.riskLimiti = 0.0,
    this.riskKontrolTipi = 'Uyar',
    this.teminatTutari = 0.0,
    this.teminatDetayi = '',
    this.vadeGunu = 30,
    this.fiyatListesi = 'Standart',
    this.iskontoOrani = 0.0,
    this.odemePlani = 'Havale',
    this.yetkiliKisi = '',
    this.yetkiliUnvan = '',
    this.departman = '',
    this.plasiyer = '',
    this.aktifMi = true,
    this.notlar = '',
    DateTime? kayitTarihi,
    this.guncellemeTarihi,
    this.kayitDili = 'TR',
  }) : kayitTarihi = kayitTarihi ?? DateTime.now();

  /// Cloud Firestore Map formatına dönüştürme
  Map<String, dynamic> toMap() {
    return {
      'cariKodu': cariKodu,
      'unvan': unvan,
      'cariTipi': cariTipi,
      'cariGrubu': cariGrubu,
      'ozelKod1': ozelKod1,
      'ozelKod2': ozelKod2,
      'vergiDairesi': vergiDairesi,
      'vergiNo': vergiNo,
      'tckn': tckn,
      'eFaturaMukellefi': eFaturaMukellefi,
      'eFaturaSenaryosu': eFaturaSenaryosu,
      'eFaturaAlias': eFaturaAlias,
      'mersisNo': mersisNo,
      'ticaretSicilNo': ticaretSicilNo,
      'ulkeKodu': ulkeKodu,
      'ulkeAdi': ulkeAdi,
      'vergiTipi': vergiTipi,
      'kdvOrani': kdvOrani,
      'faturaAdresi': faturaAdresi,
      'sevkAdresi': sevkAdresi,
      'sirketTelefonu': sirketTelefonu,
      'cepTelefonu': cepTelefonu,
      'alternatifTelefon': alternatifTelefon,
      'eposta': eposta,
      'eposta2': eposta2,
      'webSitesi': webSitesi,
      'sehir': sehir,
      'ilce': ilce,
      'postaKodu': postaKodu,
      'lokasyon': lokasyon,
      'paraBirimi': paraBirimi,
      'muhasebeKodu': muhasebeKodu,
      'bankaAdi': bankaAdi,
      'bankaSube': bankaSube,
      'iban': iban,
      'iban2': iban2,
      'swiftKodu': swiftKodu,
      'kdvMuaf': kdvMuaf,
      'kdvMuafiyetKodu': kdvMuafiyetKodu,
      'tevkifatKodu': tevkifatKodu,
      'riskLimiti': riskLimiti,
      'riskKontrolTipi': riskKontrolTipi,
      'teminatTutari': teminatTutari,
      'teminatDetayi': teminatDetayi,
      'vadeGunu': vadeGunu,
      'fiyatListesi': fiyatListesi,
      'iskontoOrani': iskontoOrani,
      'odemePlani': odemePlani,
      'yetkiliKisi': yetkiliKisi,
      'yetkiliUnvan': yetkiliUnvan,
      'departman': departman,
      'plasiyer': plasiyer,
      'aktifMi': aktifMi,
      'notlar': notlar,
      'kayitTarihi': kayitTarihi.toIso8601String(),
      'guncellemeTarihi': guncellemeTarihi?.toIso8601String(),
      'kayitDili': kayitDili,
    };
  }

  /// Cloud Firestore Map'ten nesne türetme
  factory CariKart.fromMap(Map<String, dynamic> map, {String? docId}) {
    return CariKart(
      id: docId,
      cariKodu: map['cariKodu'] ?? '',
      unvan: map['unvan'] ?? '',
      cariTipi: map['cariTipi'] ?? 'Musteri',
      cariGrubu: map['cariGrubu'] ?? 'Genel',
      ozelKod1: map['ozelKod1'] ?? '',
      ozelKod2: map['ozelKod2'] ?? '',
      vergiDairesi: map['vergiDairesi'] ?? '',
      vergiNo: map['vergiNo'] ?? '',
      tckn: map['tckn'] ?? '',
      eFaturaMukellefi: map['eFaturaMukellefi'] ?? false,
      eFaturaSenaryosu: map['eFaturaSenaryosu'] ?? 'Temel',
      eFaturaAlias: map['eFaturaAlias'] ?? '',
      mersisNo: map['mersisNo'] ?? '',
      ticaretSicilNo: map['ticaretSicilNo'] ?? '',
      ulkeKodu: map['ulkeKodu'] ?? 'TR',
      ulkeAdi: map['ulkeAdi'] ?? 'Türkiye',
      vergiTipi: map['vergiTipi'] ?? 'VKN',
      kdvOrani: map['kdvOrani'] ?? '%20',
      faturaAdresi: map['faturaAdresi'] ?? '',
      sevkAdresi: map['sevkAdresi'] ?? '',
      sirketTelefonu: map['sirketTelefonu'] ?? '',
      cepTelefonu: map['cepTelefonu'] ?? '',
      alternatifTelefon: map['alternatifTelefon'] ?? '',
      eposta: map['eposta'] ?? '',
      eposta2: map['eposta2'] ?? '',
      webSitesi: map['webSitesi'] ?? '',
      sehir: map['sehir'] ?? '',
      ilce: map['ilce'] ?? '',
      postaKodu: map['postaKodu'] ?? '',
      lokasyon: map['lokasyon'] ?? '',
      paraBirimi: map['paraBirimi'] ?? 'TRY',
      muhasebeKodu: map['muhasebeKodu'] ?? '120.01.001',
      bankaAdi: map['bankaAdi'] ?? '',
      bankaSube: map['bankaSube'] ?? '',
      iban: map['iban'] ?? '',
      iban2: map['iban2'] ?? '',
      swiftKodu: map['swiftKodu'] ?? '',
      kdvMuaf: map['kdvMuaf'] ?? false,
      kdvMuafiyetKodu: map['kdvMuafiyetKodu'] ?? '',
      tevkifatKodu: map['tevkifatKodu'] ?? '',
      riskLimiti: (map['riskLimiti'] as num?)?.toDouble() ?? 0.0,
      riskKontrolTipi: map['riskKontrolTipi'] ?? 'Uyar',
      teminatTutari: (map['teminatTutari'] as num?)?.toDouble() ?? 0.0,
      teminatDetayi: map['teminatDetayi'] ?? '',
      vadeGunu: map['vadeGunu'] ?? 30,
      fiyatListesi: map['fiyatListesi'] ?? 'Standart',
      iskontoOrani: (map['iskontoOrani'] as num?)?.toDouble() ?? 0.0,
      odemePlani: map['odemePlani'] ?? 'Havale',
      yetkiliKisi: map['yetkiliKisi'] ?? '',
      yetkiliUnvan: map['yetkiliUnvan'] ?? '',
      departman: map['departman'] ?? '',
      plasiyer: map['plasiyer'] ?? '',
      aktifMi: map['aktifMi'] ?? true,
      notlar: map['notlar'] ?? '',
      kayitTarihi: map['kayitTarihi'] != null
          ? DateTime.tryParse(map['kayitTarihi'])
          : null,
      guncellemeTarihi: map['guncellemeTarihi'] != null
          ? DateTime.tryParse(map['guncellemeTarihi'])
          : null,
      kayitDili: map['kayitDili'] ?? 'TR',
    );
  }

  /// Telefon Rehberine Aktarım için vCard (.vcf) Standart Metni (RFC 6350)
  String toVCard() {
    final buffer = StringBuffer();
    buffer.writeln('BEGIN:VCARD');
    buffer.writeln('VERSION:3.0');
    buffer.writeln('FN:$unvan');
    if (yetkiliKisi.isNotEmpty) {
      buffer.writeln('N:$yetkiliKisi;;;;');
      buffer.writeln('TITLE:$yetkiliUnvan');
    } else {
      buffer.writeln('N:$unvan;;;;');
    }
    buffer.writeln('ORG:$unvan;$departman');
    if (cepTelefonu.isNotEmpty) {
      buffer.writeln('TEL;TYPE=CELL,VOICE:$cepTelefonu');
    }
    if (sirketTelefonu.isNotEmpty) {
      buffer.writeln('TEL;TYPE=WORK,VOICE:$sirketTelefonu');
    }
    if (alternatifTelefon.isNotEmpty) {
      buffer.writeln('TEL;TYPE=OTHER,VOICE:$alternatifTelefon');
    }
    if (eposta.isNotEmpty) {
      buffer.writeln('EMAIL;TYPE=PREF,INTERNET:$eposta');
    }
    if (eposta2.isNotEmpty) {
      buffer.writeln('EMAIL;TYPE=WORK,INTERNET:$eposta2');
    }
    if (webSitesi.isNotEmpty) {
      buffer.writeln('URL:$webSitesi');
    }
    if (faturaAdresi.isNotEmpty || sehir.isNotEmpty) {
      buffer
          .writeln('ADR;TYPE=WORK:;;$faturaAdresi;$sehir;;$postaKodu;$ulkeAdi');
    }
    buffer.writeln(
        'NOTE:Cari Kodu: $cariKodu | Vergi No: $vergiNo | Para Birimi: $paraBirimi');
    buffer.writeln('END:VCARD');
    return buffer.toString();
  }
}
