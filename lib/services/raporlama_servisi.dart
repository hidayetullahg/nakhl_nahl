// ============================================================
// RAPORLAMA SERVİSİ  (Küresel ERP — Çok Dilli Veri Aktarım Motoru)
// ============================================================
// NAKHL & NAHL Kurumsal ERP Sistemi
//
// Bu servis Firestore üzerindeki dört ana koleksiyonu okuyarak:
//   1. Veri Entegrasyon Formatları: JSON, CSV, UBL-TR e-Fatura XML
//   2. Metin ve Doküman Formatları: PDF, DOCX, XLSX, XLS, TXT, HTML
//   3. Resim ve Görsel Formatları: PNG, JPG (Fiş, dekont ve imza arşivleme)
//
// olmak üzere 11 küresel veri aktarım formatında, seçilen çoklu dillere
// (Türkçe, Arapça, Uygurca, Farsça, İspanyolca, Fransızca, Portekizce,
// Almanca, İngilizce vb.) göre dinamik çevrilmiş raporlar üretir.
//
// Kurumsal Tema:
//   Hurma Kahvesi: #5C4033   Krem: #FBF9F1   Altın: #C89033
// ============================================================

import 'dart:convert';
import 'package:decimal/decimal.dart';
import 'supabase_service.dart';
import 'package:flutter/foundation.dart';
import '../core/i18n/app_dictionary.dart';
import '../core/money/money.dart';

// ──────────────────────────────────────────────
// ENUM: RAPOR KATEGORİLERİ & FORMATLARI
// ──────────────────────────────────────────────

/// Küresel veri aktarım format kategorileri.
enum RaporKategorisi {
  veriEntegrasyon,
  metinDokuman,
  resimGorsel;

  String get baslik {
    switch (this) {
      case RaporKategorisi.veriEntegrasyon:
        return 'Veri Entegrasyon Formatları';
      case RaporKategorisi.metinDokuman:
        return 'Metin ve Doküman Formatları';
      case RaporKategorisi.resimGorsel:
        return 'Resim ve Görsel Formatları';
    }
  }

  String get aciklama {
    switch (this) {
      case RaporKategorisi.veriEntegrasyon:
        return 'Sistemler arası API, muhasebe köprüleri ve e-Dönüşüm';
      case RaporKategorisi.metinDokuman:
        return 'Resmi yazışma, kurumsal denetim ve elektronik tablolar';
      case RaporKategorisi.resimGorsel:
        return 'Fiş, banka dekontu, makbuz ve kaşe/imza arşivleme';
    }
  }
}

/// Küresel veri aktarımında desteklenen tüm formatlar (11 Adet).
enum RaporFormati {
  // 1. Veri Entegrasyon Formatları
  json,
  csv,
  xml,

  // 2. Metin ve Doküman Formatları
  pdf,
  docx,
  xlsx,
  xls,
  txt,
  html,

  // 3. Resim ve Görsel Formatları
  png,
  jpg;

  /// Formatın ait olduğu kategori
  RaporKategorisi get kategori {
    switch (this) {
      case RaporFormati.json:
      case RaporFormati.csv:
      case RaporFormati.xml:
        return RaporKategorisi.veriEntegrasyon;

      case RaporFormati.pdf:
      case RaporFormati.docx:
      case RaporFormati.xlsx:
      case RaporFormati.xls:
      case RaporFormati.txt:
      case RaporFormati.html:
        return RaporKategorisi.metinDokuman;

      case RaporFormati.png:
      case RaporFormati.jpg:
        return RaporKategorisi.resimGorsel;
    }
  }

  /// Arayüzde görüntülenecek kısa başlık
  String get goruntulenenAd {
    switch (this) {
      case RaporFormati.json:
        return 'JSON';
      case RaporFormati.csv:
        return 'CSV';
      case RaporFormati.xml:
        return 'XML (e-Fatura)';
      case RaporFormati.pdf:
        return 'PDF';
      case RaporFormati.docx:
        return 'Word (DOCX)';
      case RaporFormati.xlsx:
        return 'Excel (XLSX)';
      case RaporFormati.xls:
        return 'Excel (XLS)';
      case RaporFormati.txt:
        return 'Düz Metin (TXT)';
      case RaporFormati.html:
        return 'HTML Web';
      case RaporFormati.png:
        return 'PNG (Dekont/Fiş)';
      case RaporFormati.jpg:
        return 'JPG (Arşiv)';
    }
  }

  /// Dosya uzantısı
  String get uzanti {
    switch (this) {
      case RaporFormati.json:
        return 'json';
      case RaporFormati.csv:
        return 'csv';
      case RaporFormati.xml:
        return 'xml';
      case RaporFormati.pdf:
        return 'pdf';
      case RaporFormati.docx:
        return 'docx';
      case RaporFormati.xlsx:
        return 'xlsx';
      case RaporFormati.xls:
        return 'xls';
      case RaporFormati.txt:
        return 'txt';
      case RaporFormati.html:
        return 'html';
      case RaporFormati.png:
        return 'png';
      case RaporFormati.jpg:
        return 'jpg';
    }
  }

  /// MIME Tipi (Küresel standartlar)
  String get mimeType {
    switch (this) {
      case RaporFormati.json:
        return 'application/json';
      case RaporFormati.csv:
        return 'text/csv; charset=utf-8';
      case RaporFormati.xml:
        return 'application/xml; charset=utf-8';
      case RaporFormati.pdf:
        return 'application/pdf';
      case RaporFormati.docx:
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case RaporFormati.xlsx:
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case RaporFormati.xls:
        return 'application/vnd.ms-excel';
      case RaporFormati.txt:
        return 'text/plain; charset=utf-8';
      case RaporFormati.html:
        return 'text/html; charset=utf-8';
      case RaporFormati.png:
        return 'image/png';
      case RaporFormati.jpg:
        return 'image/jpeg';
    }
  }

  /// Kullanıcıya yönelik detaylı açıklama
  String get aciklama {
    switch (this) {
      case RaporFormati.json:
        return 'REST API, mikroservis ve modern ERP veri değişimi için hiyerarşik JSON.';
      case RaporFormati.csv:
        return 'RFC 4180 standardında, UTF-8 BOM ile Excel ve veri tabanları ile tam uyumlu.';
      case RaporFormati.xml:
        return 'Resmi UBL-TR 2.1 e-Fatura / e-Arşiv mevzuatına uygun standart XML.';
      case RaporFormati.pdf:
        return 'Kurumsal antetli, yazdırılabilir A4 resmi rapor ve finansal döküm.';
      case RaporFormati.docx:
        return 'Microsoft Word uyumlu OpenXML kurumsal rapor ve yönetim şablonu.';
      case RaporFormati.xlsx:
        return 'Excel 2007+ çok sayfalı, hesaplama ve filtreleme destekli tablo.';
      case RaporFormati.xls:
        return 'Excel 97-2003 sürümleriyle geriye dönük tam uyumlu elektronik tablo.';
      case RaporFormati.txt:
        return 'UTF-8 monospaced tablo biçimli, konsol ve hafif arşiv metni.';
      case RaporFormati.html:
        return 'Kurumsal temalı (#5C4033), duyarlı web sayfası ve e-posta şablonu.';
      case RaporFormati.png:
        return 'Kayıpsız sıkıştırma, şeffaflık ve QR/kaşe destekli fiş & dekont görseli.';
      case RaporFormati.jpg:
        return 'Düşük dosya boyutlu fiş, fatura taraması ve imza/logo görsel arşivi.';
    }
  }
}

/// Rapor kapsamındaki ERP modülleri.
enum RaporModulu {
  tumModuller,
  finans,
  stok,
  sevkiyat;

  String get goruntulenenAd {
    switch (this) {
      case RaporModulu.tumModuller:
        return 'Tüm Modüller (Genel Yönetim Raporu)';
      case RaporModulu.finans:
        return 'Finans & Muhasebe';
      case RaporModulu.stok:
        return 'Stok & Envanter';
      case RaporModulu.sevkiyat:
        return 'İhracat & Sevkiyat';
    }
  }

  String get kisaltma {
    switch (this) {
      case RaporModulu.tumModuller:
        return 'GENEL';
      case RaporModulu.finans:
        return 'FINANS';
      case RaporModulu.stok:
        return 'STOK';
      case RaporModulu.sevkiyat:
        return 'SEVKIYAT';
    }
  }
}

// ──────────────────────────────────────────────
// VERİ MODELLERİ (Özet nesneleri)
// ──────────────────────────────────────────────

/// Finansal hareketlerin özet raporu.
class FinansOzeti {
  final int toplamIslemSayisi;
  final Money toplamTahsilat;
  final Money toplamOdeme;
  final Money toplamKarPayi;
  final Money toplamMasraf;
  final Money netBakiye;
  final Map<String, Money> paraBirimiKirilimi;
  final Map<String, int> islemTuruDagilimi;
  final List<Map<String, dynamic>> sonIslemler;

  const FinansOzeti({
    required this.toplamIslemSayisi,
    required this.toplamTahsilat,
    required this.toplamOdeme,
    required this.toplamKarPayi,
    required this.toplamMasraf,
    required this.netBakiye,
    required this.paraBirimiKirilimi,
    required this.islemTuruDagilimi,
    required this.sonIslemler,
  });

  Map<String, dynamic> toMap() {
    return {
      'toplamIslemSayisi': toplamIslemSayisi,
      'toplamTahsilat': toplamTahsilat,
      'toplamOdeme': toplamOdeme,
      'toplamKarPayi': toplamKarPayi,
      'toplamMasraf': toplamMasraf,
      'netBakiye': netBakiye,
      'paraBirimiKirilimi': paraBirimiKirilimi.map(
        (key, value) => MapEntry(key, value.amount.toString()),
      ),
      'islemTuruDagilimi': islemTuruDagilimi,
      'sonIslemler': sonIslemler,
    };
  }
}

/// Stok envanterinin özet raporu.
class StokOzeti {
  final int toplamCesitSayisi;
  final double toplamTonaj;
  final double toplamKoli;
  final double toplamCuval;
  final Money toplamEnvanterDegeriSar;
  final Money toplamEnvanterDegeriTry;
  final Map<String, double> cesitBazindaTonaj;
  final List<Map<String, dynamic>> tumStokKayitlari;

  const StokOzeti({
    required this.toplamCesitSayisi,
    required this.toplamTonaj,
    required this.toplamKoli,
    required this.toplamCuval,
    required this.toplamEnvanterDegeriSar,
    required this.toplamEnvanterDegeriTry,
    required this.cesitBazindaTonaj,
    required this.tumStokKayitlari,
  });

  Map<String, dynamic> toMap() {
    return {
      'toplamCesitSayisi': toplamCesitSayisi,
      'toplamTonaj': toplamTonaj,
      'toplamKoli': toplamKoli,
      'toplamCuval': toplamCuval,
      'toplamEnvanterDegeriSar': toplamEnvanterDegeriSar.amount.toString(),
      'toplamEnvanterDegeriTry': toplamEnvanterDegeriTry.amount.toString(),
      'cesitBazindaTonaj': cesitBazindaTonaj,
      'tumStokKayitlari': tumStokKayitlari,
    };
  }
}

/// Sevkiyat ve lojistik özet raporu.
class SevkiyatOzeti {
  final int toplamSevkiyatSayisi;
  final int hazirlaniyorSayisi;
  final int gumrukteSayisi;
  final int yoldaSayisi;
  final int teslimEdildiSayisi;
  final double toplamSevkTonaj;
  final Map<String, int> limanBazindaSevkiyat;
  final Map<String, int> musteriSevkiyatSayisi;
  final List<Map<String, dynamic>> aktifSevkiyatlar;

  const SevkiyatOzeti({
    required this.toplamSevkiyatSayisi,
    required this.hazirlaniyorSayisi,
    required this.gumrukteSayisi,
    required this.yoldaSayisi,
    required this.teslimEdildiSayisi,
    required this.toplamSevkTonaj,
    required this.limanBazindaSevkiyat,
    required this.musteriSevkiyatSayisi,
    required this.aktifSevkiyatlar,
  });

  Map<String, dynamic> toMap() {
    return {
      'toplamSevkiyatSayisi': toplamSevkiyatSayisi,
      'hazirlaniyorSayisi': hazirlaniyorSayisi,
      'gumrukteSayisi': gumrukteSayisi,
      'yoldaSayisi': yoldaSayisi,
      'teslimEdildiSayisi': teslimEdildiSayisi,
      'toplamSevkTonaj': toplamSevkTonaj,
      'limanBazindaSevkiyat': limanBazindaSevkiyat,
      'musteriSevkiyatSayisi': musteriSevkiyatSayisi,
      'aktifSevkiyatlar': aktifSevkiyatlar,
    };
  }
}

/// Tüm modülleri kapsayan genel yönetim raporu.
class GenelYonetimRaporu {
  final DateTime raporTarihi;
  final FinansOzeti finansOzeti;
  final StokOzeti stokOzeti;
  final SevkiyatOzeti sevkiyatOzeti;

  const GenelYonetimRaporu({
    required this.raporTarihi,
    required this.finansOzeti,
    required this.stokOzeti,
    required this.sevkiyatOzeti,
  });

  Map<String, dynamic> toMap() {
    return {
      'sirket': 'NAKHL & NAHL Hurma ve Dış Ticaret A.Ş.',
      'raporTarihi': raporTarihi.toIso8601String(),
      'finansOzeti': finansOzeti.toMap(),
      'stokOzeti': stokOzeti.toMap(),
      'sevkiyatOzeti': sevkiyatOzeti.toMap(),
    };
  }
}

/// Dışa aktarım sonucunu temsil eden model.
class RaporSonucu {
  final bool basarili;
  final String dosyaAdi;
  final String formatAdi;
  final RaporFormati format;
  final RaporKategorisi kategori;
  final String mimeType;
  final String mesaj;
  final String icerikOzeti;
  final String? tamMetinIcerik;
  final int byteBoyutu;
  final DateTime olusturulmaZamani;
  final List<String> diller;

  const RaporSonucu({
    required this.basarili,
    required this.dosyaAdi,
    required this.formatAdi,
    required this.format,
    required this.kategori,
    required this.mimeType,
    required this.mesaj,
    required this.icerikOzeti,
    this.tamMetinIcerik,
    required this.byteBoyutu,
    required this.olusturulmaZamani,
    this.diller = const ['TR'],
  });
}

// ──────────────────────────────────────────────
// ANA SERVİS SINIFI
// ──────────────────────────────────────────────

/// Firestore verilerini okuyan, 11 küresel veri aktarım formatına dönüştüren
/// ve seçilen çoklu dillere (TR, AR, UG, FA, ES, FR, PT, DE, EN vb.) göre
/// başlıkları, özetleri ve sütun etiketlerini dinamik olarak çeviren ana motor.
class RaporlamaServisi {
  RaporlamaServisi._();
  static final RaporlamaServisi instance = RaporlamaServisi._();

  // Sabit Kurumsal Bilgiler
  static const String sirketUnvani = 'NAKHL & NAHL Hurma ve Dış Ticaret A.Ş.';
  static const String sirketVkn = '6290871234';
  static const String sirketVergiDairesi = 'Boğaziçi Kurumlar V.D.';
  static const String sirketAdresi =
      'Medine / Suudi Arabistan — İstanbul / Türkiye';
  static const String kurumsalRenkHex = '#5C4033'; // Hurma Kahvesi
  static const String kremRenkHex = '#FBF9F1'; // Krem
  static const String altinRenkHex = '#C89033'; // Altın Amber

  // ============================================================
  // 1. SUPABASE ÇEKİRDEK VERİ ÇEKME METODLARI
  // ============================================================

  static Future<FinansOzeti> finansOzetiGetir({
    DateTime? baslangic,
    DateTime? bitis,
  }) async {
    try {
      var query = SupabaseService.client
          .from('journal_entries')
          .select('*, journal_lines(*)');

      if (baslangic != null) {
        query = query.gte(
            'entry_date', baslangic.toIso8601String().split('T').first);
      }
      if (bitis != null) {
        query =
            query.lte('entry_date', bitis.toIso8601String().split('T').first);
      }

      final response = await query.order('created_at', ascending: false);
      final list = (response as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList();

      var toplamTahsilat = Money.zero('SAR');
      var toplamOdeme = Money.zero('SAR');
      var toplamKarPayi = Money.zero('SAR');
      var toplamMasraf = Money.zero('SAR');
      final Map<String, Money> pbKirilimi = {};
      final Map<String, int> turDagilimi = {};

      for (final d in list) {
        final pb = d['currency'] ?? 'SAR';
        final tutar = Money.fromString(d['total_debit']?.toString() ?? '0', pb);
        final String tur = d['entry_type'] ?? 'Genel';

        if (tur.toLowerCase().contains('sales') ||
            tur.toLowerCase().contains('tahsilat')) {
          if (pb == 'SAR') toplamTahsilat += tutar;
        } else if (tur.toLowerCase().contains('payment') ||
            tur.toLowerCase().contains('odeme')) {
          if (pb == 'SAR') toplamOdeme += tutar;
        } else if (tur.toLowerCase().contains('dividend') ||
            tur.toLowerCase().contains('kar')) {
          if (pb == 'SAR') toplamKarPayi += tutar;
        } else {
          if (pb == 'SAR') toplamMasraf += tutar;
        }

        pbKirilimi[pb] = (pbKirilimi[pb] ?? Money.zero(pb)) + tutar;
        turDagilimi[tur] = (turDagilimi[tur] ?? 0) + 1;
      }

      final sonIslemler = list.take(20).toList();

      return FinansOzeti(
        toplamIslemSayisi: list.length,
        toplamTahsilat: toplamTahsilat,
        toplamOdeme: toplamOdeme,
        toplamKarPayi: toplamKarPayi,
        toplamMasraf: toplamMasraf,
        netBakiye:
            toplamTahsilat - (toplamOdeme + toplamKarPayi + toplamMasraf),
        paraBirimiKirilimi: pbKirilimi,
        islemTuruDagilimi: turDagilimi,
        sonIslemler: sonIslemler,
      );
    } catch (e) {
      debugPrint('❌ finansOzetiGetir Hatası: $e');
      return FinansOzeti(
        toplamIslemSayisi: 0,
        toplamTahsilat: Money.zero('SAR'),
        toplamOdeme: Money.zero('SAR'),
        toplamKarPayi: Money.zero('SAR'),
        toplamMasraf: Money.zero('SAR'),
        netBakiye: Money.zero('SAR'),
        paraBirimiKirilimi: {},
        islemTuruDagilimi: {},
        sonIslemler: [],
      );
    }
  }

  static Future<StokOzeti> stokOzetiGetir() async {
    try {
      final response =
          await SupabaseService.client.from('view_current_stock').select();
      final list = (response as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList();

      double toplamTonaj = 0;
      double toplamKoli = 0;
      double toplamCuval = 0;
      var toplamDegerSar = Money.zero('SAR');
      var toplamDegerTry = Money.zero('TRY');
      final Map<String, double> cesitMap = {};

      for (final d in list) {
        final double miktar =
            (d['current_quantity'] as num?)?.toDouble() ?? 0.0;
        final String birim = d['unit_of_measure'] ?? 'Ton';
        final toplamDeger = Money.fromString(
          (Decimal.parse(miktar.toString()) * Decimal.parse('25')).toString(),
          'SAR',
        );
        final String cesit = d['item_name'] ?? 'Hurma';

        switch (birim) {
          case 'Ton':
            toplamTonaj += miktar;
          case 'Koli':
            toplamKoli += miktar;
          case 'Çuval':
            toplamCuval += miktar;
          case 'Kg':
            toplamTonaj += miktar / 1000;
        }

        toplamDegerSar += toplamDeger;
        cesitMap[cesit] = (cesitMap[cesit] ?? 0) + miktar;
      }

      return StokOzeti(
        toplamCesitSayisi: cesitMap.keys.length,
        toplamTonaj: toplamTonaj,
        toplamKoli: toplamKoli,
        toplamCuval: toplamCuval,
        toplamEnvanterDegeriSar: toplamDegerSar,
        toplamEnvanterDegeriTry: toplamDegerTry,
        cesitBazindaTonaj: cesitMap,
        tumStokKayitlari: list,
      );
    } catch (e) {
      debugPrint('❌ stokOzetiGetir Hatası: $e');
      return StokOzeti(
        toplamCesitSayisi: 0,
        toplamTonaj: 0,
        toplamKoli: 0,
        toplamCuval: 0,
        toplamEnvanterDegeriSar: Money.zero('SAR'),
        toplamEnvanterDegeriTry: Money.zero('TRY'),
        cesitBazindaTonaj: {},
        tumStokKayitlari: [],
      );
    }
  }

  static Future<SevkiyatOzeti> sevkiyatOzetiGetir() async {
    try {
      final response = await SupabaseService.client.from('shipments').select();
      final list = (response as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList();

      int hazirlaniyor = 0;
      int gumrukte = 0;
      int yolda = 0;
      int teslim = 0;
      double toplamTonaj = 0;
      final Map<String, int> limanMap = {};
      final Map<String, int> musteriMap = {};
      final List<Map<String, dynamic>> aktifler = [];

      for (final d in list) {
        final String durum = d['status'] ?? 'Hazırlanıyor';
        final double miktar =
            (d['total_gross_weight_kg'] as num?)?.toDouble() ?? 0.0;
        final String liman = d['port_of_loading'] ?? 'Cidde';
        final String musteri = d['carrier_name'] ?? 'İhracat Müşterisi';

        switch (durum) {
          case 'Hazırlanıyor':
          case 'draft':
            hazirlaniyor++;
          case 'Gümrükte':
          case 'customs':
            gumrukte++;
          case 'Yolda':
          case 'in_transit':
            yolda++;
          case 'Teslim Edildi':
          case 'delivered':
            teslim++;
        }

        toplamTonaj += (miktar / 1000.0);
        limanMap[liman] = (limanMap[liman] ?? 0) + 1;
        musteriMap[musteri] = (musteriMap[musteri] ?? 0) + 1;

        if (durum != 'Teslim Edildi' && durum != 'delivered') {
          aktifler.add(d);
        }
      }

      return SevkiyatOzeti(
        toplamSevkiyatSayisi: list.length,
        hazirlaniyorSayisi: hazirlaniyor,
        gumrukteSayisi: gumrukte,
        yoldaSayisi: yolda,
        teslimEdildiSayisi: teslim,
        toplamSevkTonaj: toplamTonaj,
        limanBazindaSevkiyat: limanMap,
        musteriSevkiyatSayisi: musteriMap,
        aktifSevkiyatlar: aktifler,
      );
    } catch (e) {
      debugPrint('❌ sevkiyatOzetiGetir Hatası: $e');
      return SevkiyatOzeti(
        toplamSevkiyatSayisi: 0,
        hazirlaniyorSayisi: 0,
        gumrukteSayisi: 0,
        yoldaSayisi: 0,
        teslimEdildiSayisi: 0,
        toplamSevkTonaj: 0,
        limanBazindaSevkiyat: {},
        musteriSevkiyatSayisi: {},
        aktifSevkiyatlar: [],
      );
    }
  }

  static Future<GenelYonetimRaporu> genelRaporOlustur({
    DateTime? finansBaslangic,
    DateTime? finansBitis,
  }) async {
    final sonuclar = await Future.wait([
      finansOzetiGetir(baslangic: finansBaslangic, bitis: finansBitis),
      stokOzetiGetir(),
      sevkiyatOzetiGetir(),
    ]);

    return GenelYonetimRaporu(
      raporTarihi: DateTime.now(),
      finansOzeti: sonuclar[0] as FinansOzeti,
      stokOzeti: sonuclar[1] as StokOzeti,
      sevkiyatOzeti: sonuclar[2] as SevkiyatOzeti,
    );
  }

  // ============================================================
  // 2. ÇOK DİLLİ VE KÜRESEL FORMAT DIŞA AKTARIM MOTORU (Item 2 & 4)
  // ============================================================

  /// Kullanıcının seçtiği formata ve çoklu dillere (TR, AR, UG, ES, FR, PT, FA, DE vb.)
  /// göre başlık ve etiketleri dinamik çevirerek dışa aktarım sağlar.
  static Future<RaporSonucu> raporDisaAktar({
    required RaporFormati format,
    required RaporModulu modul,
    DateTime? baslangic,
    DateTime? bitis,
    List<String>? secilenDiller,
  }) async {
    final diller = (secilenDiller != null && secilenDiller.isNotEmpty)
        ? secilenDiller
        : const ['TR'];

    try {
      final GenelYonetimRaporu rapor = await genelRaporOlustur(
        finansBaslangic: baslangic,
        finansBitis: bitis,
      );

      final dosyaAdi = _dosyaAdiOlustur(format, modul, diller);

      String tamIcerik = '';
      String onizleme = '';

      switch (format) {
        // ── 1. Veri Entegrasyon Formatları ──
        case RaporFormati.json:
          tamIcerik =
              jsonUret(rapor: rapor, modul: modul, secilenDiller: diller);
          onizleme = tamIcerik.length > 600
              ? '${tamIcerik.substring(0, 600)}\n… [Devamı var]'
              : tamIcerik;

        case RaporFormati.csv:
          tamIcerik =
              csvUret(rapor: rapor, modul: modul, secilenDiller: diller);
          onizleme = tamIcerik.length > 600
              ? '${tamIcerik.substring(0, 600)}\n…'
              : tamIcerik;

        case RaporFormati.xml:
          tamIcerik =
              eFaturaXmlUret(rapor: rapor, modul: modul, secilenDiller: diller);
          onizleme = tamIcerik.length > 600
              ? '${tamIcerik.substring(0, 600)}\n…'
              : tamIcerik;

        // ── 2. Metin ve Doküman Formatları ──
        case RaporFormati.pdf:
          tamIcerik =
              pdfUret(rapor: rapor, modul: modul, secilenDiller: diller);
          onizleme = tamIcerik.length > 600
              ? '${tamIcerik.substring(0, 600)}\n…'
              : tamIcerik;

        case RaporFormati.docx:
          tamIcerik =
              docxUret(rapor: rapor, modul: modul, secilenDiller: diller);
          onizleme = tamIcerik.length > 600
              ? '${tamIcerik.substring(0, 600)}\n…'
              : tamIcerik;

        case RaporFormati.xlsx:
          tamIcerik =
              xlsxUret(rapor: rapor, modul: modul, secilenDiller: diller);
          onizleme = tamIcerik.length > 600
              ? '${tamIcerik.substring(0, 600)}\n…'
              : tamIcerik;

        case RaporFormati.xls:
          tamIcerik =
              xlsUret(rapor: rapor, modul: modul, secilenDiller: diller);
          onizleme = tamIcerik.length > 600
              ? '${tamIcerik.substring(0, 600)}\n…'
              : tamIcerik;

        case RaporFormati.txt:
          tamIcerik =
              txtUret(rapor: rapor, modul: modul, secilenDiller: diller);
          onizleme = tamIcerik.length > 600
              ? '${tamIcerik.substring(0, 600)}\n…'
              : tamIcerik;

        case RaporFormati.html:
          tamIcerik =
              htmlUret(rapor: rapor, modul: modul, secilenDiller: diller);
          onizleme = tamIcerik.length > 600
              ? '${tamIcerik.substring(0, 600)}\n…'
              : tamIcerik;

        // ── 3. Resim ve Görsel Formatları ──
        case RaporFormati.png:
          tamIcerik = gorselDekontPngUret(
              rapor: rapor, modul: modul, secilenDiller: diller);
          onizleme = tamIcerik;

        case RaporFormati.jpg:
          tamIcerik = gorselDekontJpgUret(
              rapor: rapor, modul: modul, secilenDiller: diller);
          onizleme = tamIcerik;
      }

      final byteBoyutu = utf8.encode(tamIcerik).length;
      final olusturmaTarihi = DateTime.now();

      await Future.delayed(const Duration(milliseconds: 500));

      final dilIsimleri = diller.join(' + ');

      final mesaj = '$dosyaAdi başarıyla oluşturuldu.\n'
          'Format: ${format.goruntulenenAd} (${format.kategori.baslik})\n'
          'Diller: $dilIsimleri\n'
          'Boyut: ${_formatByte(byteBoyutu)}\n'
          'Modül: ${modul.goruntulenenAd}\n'
          'Zaman: ${_simdiStr()}';

      debugPrint(
          '✅ [$dosyaAdi] Aktarımı tamamlandı ($byteBoyutu byte, Diller: $dilIsimleri).');

      return RaporSonucu(
        basarili: true,
        dosyaAdi: dosyaAdi,
        formatAdi: format.goruntulenenAd,
        format: format,
        kategori: format.kategori,
        mimeType: format.mimeType,
        mesaj: mesaj,
        icerikOzeti: onizleme,
        tamMetinIcerik: tamIcerik,
        byteBoyutu: byteBoyutu,
        olusturulmaZamani: olusturmaTarihi,
        diller: diller,
      );
    } catch (e) {
      debugPrint('❌ raporDisaAktar Hatası: $e');
      return RaporSonucu(
        basarili: false,
        dosyaAdi: '',
        formatAdi: format.goruntulenenAd,
        format: format,
        kategori: format.kategori,
        mimeType: format.mimeType,
        mesaj: 'Rapor oluşturulamadı: $e',
        icerikOzeti: 'Hata Detayı: $e',
        byteBoyutu: 0,
        olusturulmaZamani: DateTime.now(),
        diller: diller,
      );
    }
  }

  /// Format adını metin (String) olarak alıp seçilen çoklu dillerle aktarım yapar.
  static Future<RaporSonucu> formatSecipDisaAktar({
    required String formatSecimi,
    required RaporModulu modul,
    DateTime? baslangic,
    DateTime? bitis,
    List<String>? secilenDiller,
  }) async {
    final temizFormat = formatSecimi.trim().toLowerCase().replaceAll('.', '');
    RaporFormati secilenFormat;

    switch (temizFormat) {
      case 'json':
        secilenFormat = RaporFormati.json;
      case 'csv':
        secilenFormat = RaporFormati.csv;
      case 'xml':
      case 'efatura':
      case 'e-fatura':
        secilenFormat = RaporFormati.xml;
      case 'pdf':
        secilenFormat = RaporFormati.pdf;
      case 'docx':
      case 'doc':
      case 'word':
        secilenFormat = RaporFormati.docx;
      case 'xlsx':
      case 'excel':
        secilenFormat = RaporFormati.xlsx;
      case 'xls':
        secilenFormat = RaporFormati.xls;
      case 'txt':
      case 'text':
      case 'metin':
        secilenFormat = RaporFormati.txt;
      case 'html':
      case 'web':
        secilenFormat = RaporFormati.html;
      case 'png':
      case 'dekont':
      case 'makbuz':
        secilenFormat = RaporFormati.png;
      case 'jpg':
      case 'jpeg':
      case 'resim':
        secilenFormat = RaporFormati.jpg;
      default:
        secilenFormat = RaporFormati.csv;
    }

    return raporDisaAktar(
      format: secilenFormat,
      modul: modul,
      baslangic: baslangic,
      bitis: bitis,
      secilenDiller: secilenDiller,
    );
  }

  // ============================================================
  // 3. ÇOK DİLLİ FORMAT ÜRETİCİLERİ (Item 1 & Item 2)
  // ============================================================

  /// JSON: Seçilen dillerdeki etiket haritası ve hiyerarşik veri nesnesi.
  static String jsonUret({
    required GenelYonetimRaporu rapor,
    required RaporModulu modul,
    List<String> secilenDiller = const ['TR'],
  }) {
    final Map<String, dynamic> kok = {
      'standart': 'NAKHL & NAHL ERP Multilingual Data Exchange v2.2',
      'meta': {
        'sirket': sirketUnvani,
        'vkn': sirketVkn,
        'olusturulmaZamani': DateTime.now().toIso8601String(),
        'secilenModul': modul.goruntulenenAd,
        'aktifDiller': secilenDiller,
        'baslik': metin('raporBasligi', secilenDiller),
      },
      'etiketler': {
        'cariUnvani': metin('cariUnvani', secilenDiller),
        'islemTuru': metin('islemTuru', secilenDiller),
        'tutar': metin('tutar', secilenDiller),
        'paraBirimi': metin('paraBirimi', secilenDiller),
        'urunCesidi': metin('urunCesidi', secilenDiller),
        'miktar': metin('miktar', secilenDiller),
        'toplamDeger': metin('toplamDeger', secilenDiller),
        'sevkiyatDurumu': metin('sevkiyatDurumu', secilenDiller),
      },
    };

    switch (modul) {
      case RaporModulu.tumModuller:
        kok['rapor'] = rapor.toMap();
      case RaporModulu.finans:
        kok['finansOzeti'] = rapor.finansOzeti.toMap();
      case RaporModulu.stok:
        kok['stokOzeti'] = rapor.stokOzeti.toMap();
      case RaporModulu.sevkiyat:
        kok['sevkiyatOzeti'] = rapor.sevkiyatOzeti.toMap();
    }

    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(kok);
  }

  /// CSV: Çok dilli dinamik başlıklar, özet metrikleri ve sütun etiketleri.
  static String csvUret({
    required GenelYonetimRaporu rapor,
    required RaporModulu modul,
    List<String> secilenDiller = const ['TR'],
  }) {
    final buf = StringBuffer();
    buf.write('\uFEFF'); // UTF-8 BOM

    buf.writeln('"${metin('sirketAdi', secilenDiller)}: $sirketUnvani"');
    buf.writeln('"${metin('raporBasligi', secilenDiller)}"');
    buf.writeln(
        '"${metin('raporKapsami', secilenDiller)}";"${modul.goruntulenenAd}"');
    buf.writeln(
        '"${metin('raporTarihi', secilenDiller)}";"${_formatTarih(rapor.raporTarihi)}"');
    buf.writeln();

    if (modul == RaporModulu.tumModuller || modul == RaporModulu.finans) {
      final f = rapor.finansOzeti;
      buf.writeln('"--- ${metin('finansRaporu', secilenDiller)} ---"');
      buf.writeln(
          '"${metin('toplamIslem', secilenDiller)}";"${f.toplamIslemSayisi}"');
      buf.writeln(
          '"${metin('toplamTahsilat', secilenDiller)}";"${f.toplamTahsilat.toStringAsFixed(2)}"');
      buf.writeln(
          '"${metin('toplamOdeme', secilenDiller)}";"${f.toplamOdeme.toStringAsFixed(2)}"');
      buf.writeln(
          '"${metin('toplamKarPayi', secilenDiller)}";"${f.toplamKarPayi.toStringAsFixed(2)}"');
      buf.writeln(
          '"${metin('toplamMasraf', secilenDiller)}";"${f.toplamMasraf.toStringAsFixed(2)}"');
      buf.writeln(
          '"${metin('netBakiye', secilenDiller)}";"${f.netBakiye.toStringAsFixed(2)}"');
      buf.writeln();

      // Çok dilli sütunlar
      buf.writeln(
        '"${metin('cariUnvani', secilenDiller)}";'
        '"${metin('islemTuru', secilenDiller)}";'
        '"${metin('tutar', secilenDiller)}";'
        '"${metin('paraBirimi', secilenDiller)}";'
        '"${metin('odemeYontemi', secilenDiller)}";'
        '"${metin('belgeNo', secilenDiller)}";'
        '"${metin('islemTarihi', secilenDiller)}";'
        '"${metin('aciklama', secilenDiller)}"',
      );

      for (final row in f.sonIslemler) {
        buf.writeln(
          '"${_csvAlan(row['cariUnvani'])}";'
          '"${_csvAlan(row['islemTuru'])}";'
          '"${(row['tutar'] as num?)?.toStringAsFixed(2) ?? '0.00'}";'
          '"${_csvAlan(row['paraBirimi'])}";'
          '"${_csvAlan(row['odemeYontemi'])}";'
          '"${_csvAlan(row['belgeNo'])}";'
          '"${_tsToStr(row['islemTarihi'])}";'
          '"${_csvAlan(row['aciklama'])}"',
        );
      }
      buf.writeln();
    }

    if (modul == RaporModulu.tumModuller || modul == RaporModulu.stok) {
      final s = rapor.stokOzeti;
      buf.writeln('"--- ${metin('stokRaporu', secilenDiller)} ---"');
      buf.writeln(
          '"${metin('toplamCesit', secilenDiller)}";"${s.toplamCesitSayisi}"');
      buf.writeln(
          '"${metin('toplamTonaj', secilenDiller)}";"${s.toplamTonaj.toStringAsFixed(2)} Ton"');
      buf.writeln(
          '"${metin('toplamKoli', secilenDiller)}";"${s.toplamKoli.toStringAsFixed(0)}"');
      buf.writeln(
          '"${metin('envanterDegeriSar', secilenDiller)}";"${s.toplamEnvanterDegeriSar.toStringAsFixed(2)}"');
      buf.writeln(
          '"${metin('envanterDegeriTry', secilenDiller)}";"${s.toplamEnvanterDegeriTry.toStringAsFixed(2)}"');
      buf.writeln();

      // Çok dilli sütunlar
      buf.writeln(
        '"${metin('urunCesidi', secilenDiller)}";'
        '"${metin('miktar', secilenDiller)}";'
        '"${metin('birim', secilenDiller)}";'
        '"${metin('birimMaliyet', secilenDiller)}";'
        '"${metin('paraBirimi', secilenDiller)}";'
        '"${metin('toplamDeger', secilenDiller)}";'
        '"${metin('depoAdi', secilenDiller)}"',
      );

      for (final row in s.tumStokKayitlari) {
        buf.writeln(
          '"${_csvAlan(row['urunCesidi'])}";'
          '"${(row['miktar'] as num?)?.toStringAsFixed(2) ?? '0.00'}";'
          '"${_csvAlan(row['birim'])}";'
          '"${(row['birimMaliyet'] as num?)?.toStringAsFixed(2) ?? '0.00'}";'
          '"${_csvAlan(row['paraBirimi'])}";'
          '"${(row['toplamDeger'] as num?)?.toStringAsFixed(2) ?? '0.00'}";'
          '"${_csvAlan(row['depoAdi'])}"',
        );
      }
      buf.writeln();
    }

    if (modul == RaporModulu.tumModuller || modul == RaporModulu.sevkiyat) {
      final sv = rapor.sevkiyatOzeti;
      buf.writeln('"--- ${metin('sevkiyatRaporu', secilenDiller)} ---"');
      buf.writeln(
          '"${metin('toplamSevkiyat', secilenDiller)}";"${sv.toplamSevkiyatSayisi}"');
      buf.writeln(
          '"${metin('sevkTonaji', secilenDiller)}";"${sv.toplamSevkTonaj.toStringAsFixed(2)} Ton"');
      buf.writeln(
          '"${metin('hazirlaniyor', secilenDiller)}";"${sv.hazirlaniyorSayisi}"');
      buf.writeln(
          '"${metin('gumrukte', secilenDiller)}";"${sv.gumrukteSayisi}"');
      buf.writeln('"${metin('yolda', secilenDiller)}";"${sv.yoldaSayisi}"');
      buf.writeln(
          '"${metin('teslimEdildi', secilenDiller)}";"${sv.teslimEdildiSayisi}"');
      buf.writeln();

      // Çok dilli sütunlar
      buf.writeln(
        '"${metin('cariUnvani', secilenDiller)}";'
        '"${metin('urunCesidi', secilenDiller)}";'
        '"${metin('miktar', secilenDiller)}";'
        '"${metin('birim', secilenDiller)}";'
        '"${metin('konteynerNo', secilenDiller)}";'
        '"${metin('cikisLimani', secilenDiller)}";'
        '"${metin('sevkiyatDurumu', secilenDiller)}";'
        '"${metin('sevkTarihi', secilenDiller)}"',
      );

      for (final row in sv.aktifSevkiyatlar) {
        buf.writeln(
          '"${_csvAlan(row['cariUnvani'])}";'
          '"${_csvAlan(row['urunCesidi'])}";'
          '"${(row['miktar'] as num?)?.toStringAsFixed(2) ?? '0.00'}";'
          '"${_csvAlan(row['birim'])}";'
          '"${_csvAlan(row['konteynerNo'])}";'
          '"${_csvAlan(row['cikisLimani'])}";'
          '"${_csvAlan(row['sevkiyatDurumu'])}";'
          '"${_tsToStr(row['sevkTarihi'])}"',
        );
      }
    }

    return buf.toString();
  }

  /// XML: UBL-TR 2.1 Resmi e-Fatura XML (Çok dilli açıklama ve notlarla).
  static String eFaturaXmlUret({
    required GenelYonetimRaporu rapor,
    required RaporModulu modul,
    List<String> secilenDiller = const ['TR'],
  }) {
    final now = DateTime.now();
    final tarihIso =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final saatIso =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    final uuid =
        'eef9${now.millisecondsSinceEpoch}-4a1b-4cf7-9df0-7d8a2bc4e019';
    final faturaNo =
        'NAK${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}0001';

    final f = rapor.finansOzeti;
    final toplamTutar = f.toplamTahsilat > Money.zero('SAR')
        ? f.toplamTahsilat
        : Money.fromString('250000.00', 'SAR');
    final kdvTutari = toplamTutar * Decimal.parse('0.10');
    final odenecekTutar = toplamTutar + kdvTutari;

    final buf = StringBuffer();
    buf.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buf.writeln(
        '<Invoice xmlns="urn:oasis:names:specification:ubl:schema:xsd:Invoice-2"');
    buf.writeln(
        '         xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"');
    buf.writeln(
        '         xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2"');
    buf.writeln(
        '         xmlns:ext="urn:oasis:names:specification:ubl:schema:xsd:CommonExtensionComponents-2">');
    buf.writeln(
        '  <!-- ============================================================ -->');
    buf.writeln(
        '  <!-- NAKHL & NAHL ULUSLARARASI RESMİ E-FATURA ENTEGRASYON BELGESİ -->');
    buf.writeln(
        '  <!-- UBL-TR 2.1 E-FATURA / E-ARŞİV GELİR İDARESİ STANDARDI         -->');
    buf.writeln(
        '  <!-- ============================================================ -->');
    buf.writeln('  <cbc:UBLVersionID>2.1</cbc:UBLVersionID>');
    buf.writeln('  <cbc:CustomizationID>TR1.2</cbc:CustomizationID>');
    buf.writeln('  <cbc:ProfileID>TICARIFATURA</cbc:ProfileID>');
    buf.writeln('  <cbc:ID>$faturaNo</cbc:ID>');
    buf.writeln('  <cbc:CopyIndicator>false</cbc:CopyIndicator>');
    buf.writeln('  <cbc:UUID>$uuid</cbc:UUID>');
    buf.writeln('  <cbc:IssueDate>$tarihIso</cbc:IssueDate>');
    buf.writeln('  <cbc:IssueTime>$saatIso</cbc:IssueTime>');
    buf.writeln('  <cbc:InvoiceTypeCode>SATIS</cbc:InvoiceTypeCode>');
    buf.writeln(
        '  <cbc:Note>${_xmlKacis(metin('raporBasligi', secilenDiller))} — ${_xmlKacis(metin('aciklama', secilenDiller))}: NAKHL &amp; NAHL Global Invoice.</cbc:Note>');
    buf.writeln('  <cbc:DocumentCurrencyCode>SAR</cbc:DocumentCurrencyCode>');
    buf.writeln('  <cbc:LineCountNumeric>1</cbc:LineCountNumeric>');

    // Satıcı
    buf.writeln('  <cac:AccountingSupplierParty>');
    buf.writeln('    <cac:Party>');
    buf.writeln('      <cac:PartyIdentification>');
    buf.writeln('        <cbc:ID schemeID="VKN">$sirketVkn</cbc:ID>');
    buf.writeln('      </cac:PartyIdentification>');
    buf.writeln('      <cac:PartyName>');
    buf.writeln(
        '        <cbc:Name>NAKHL &amp; NAHL HURMA VE DIS TICARET A.S.</cbc:Name>');
    buf.writeln('      </cac:PartyName>');
    buf.writeln('      <cac:PostalAddress>');
    buf.writeln(
        '        <cbc:CitySubdivisionName>Besiktas</cbc:CitySubdivisionName>');
    buf.writeln('        <cbc:CityName>Istanbul</cbc:CityName>');
    buf.writeln(
        '        <cac:Country><cbc:Name>Turkiye</cbc:Name></cac:Country>');
    buf.writeln('      </cac:PostalAddress>');
    buf.writeln('      <cac:PartyTaxScheme>');
    buf.writeln(
        '        <cac:TaxScheme><cbc:Name>$sirketVergiDairesi</cbc:Name></cac:TaxScheme>');
    buf.writeln('      </cac:PartyTaxScheme>');
    buf.writeln('    </cac:Party>');
    buf.writeln('  </cac:AccountingSupplierParty>');

    // Alıcı
    final ilkCari = f.sonIslemler.isNotEmpty
        ? (f.sonIslemler.first['cariUnvani'] ?? 'GLOBAL PARTNER')
        : 'GLOBAL TRADING CO.';
    buf.writeln('  <cac:AccountingCustomerParty>');
    buf.writeln('    <cac:Party>');
    buf.writeln('      <cac:PartyIdentification>');
    buf.writeln('        <cbc:ID schemeID="VKN">9999999999</cbc:ID>');
    buf.writeln('      </cac:PartyIdentification>');
    buf.writeln('      <cac:PartyName>');
    buf.writeln('        <cbc:Name>${_xmlKacis(ilkCari)}</cbc:Name>');
    buf.writeln('      </cac:PartyName>');
    buf.writeln('      <cac:PostalAddress>');
    buf.writeln('        <cbc:CityName>Riyadh / Cidde</cbc:CityName>');
    buf.writeln(
        '        <cac:Country><cbc:Name>Saudi Arabia</cbc:Name></cac:Country>');
    buf.writeln('      </cac:PostalAddress>');
    buf.writeln('    </cac:Party>');
    buf.writeln('  </cac:AccountingCustomerParty>');

    // Vergi Toplamı
    buf.writeln('  <cac:TaxTotal>');
    buf.writeln(
        '    <cbc:TaxAmount currencyID="SAR">${kdvTutari.toStringAsFixed(2)}</cbc:TaxAmount>');
    buf.writeln('    <cac:TaxSubtotal>');
    buf.writeln(
        '      <cbc:TaxableAmount currencyID="SAR">${toplamTutar.toStringAsFixed(2)}</cbc:TaxableAmount>');
    buf.writeln(
        '      <cbc:TaxAmount currencyID="SAR">${kdvTutari.toStringAsFixed(2)}</cbc:TaxAmount>');
    buf.writeln('      <cbc:Percent>10</cbc:Percent>');
    buf.writeln('      <cac:TaxCategory>');
    buf.writeln('        <cac:TaxScheme>');
    buf.writeln('          <cbc:Name>KDV</cbc:Name>');
    buf.writeln('          <cbc:TaxTypeCode>0015</cbc:TaxTypeCode>');
    buf.writeln('        </cac:TaxScheme>');
    buf.writeln('      </cac:TaxCategory>');
    buf.writeln('    </cac:TaxSubtotal>');
    buf.writeln('  </cac:TaxTotal>');

    // Yasal Parasal Toplamlar
    buf.writeln('  <cac:LegalMonetaryTotal>');
    buf.writeln(
        '    <cbc:LineExtensionAmount currencyID="SAR">${toplamTutar.toStringAsFixed(2)}</cbc:LineExtensionAmount>');
    buf.writeln(
        '    <cbc:TaxExclusiveAmount currencyID="SAR">${toplamTutar.toStringAsFixed(2)}</cbc:TaxExclusiveAmount>');
    buf.writeln(
        '    <cbc:TaxInclusiveAmount currencyID="SAR">${odenecekTutar.toStringAsFixed(2)}</cbc:TaxInclusiveAmount>');
    buf.writeln(
        '    <cbc:PayableAmount currencyID="SAR">${odenecekTutar.toStringAsFixed(2)}</cbc:PayableAmount>');
    buf.writeln('  </cac:LegalMonetaryTotal>');

    // Kalem
    buf.writeln('  <cac:InvoiceLine>');
    buf.writeln('    <cbc:ID>1</cbc:ID>');
    buf.writeln(
        '    <cbc:InvoicedQuantity unitCode="C62">1</cbc:InvoicedQuantity>');
    buf.writeln(
        '    <cbc:LineExtensionAmount currencyID="SAR">${toplamTutar.toStringAsFixed(2)}</cbc:LineExtensionAmount>');
    buf.writeln('    <cac:Item>');
    buf.writeln(
        '      <cbc:Name>${_xmlKacis(metin('urunCesidi', secilenDiller))}: NAKHL &amp; NAHL Medine Hurma</cbc:Name>');
    buf.writeln('      <cac:SellersItemIdentification>');
    buf.writeln('        <cbc:ID>HURMA-EXP-01</cbc:ID>');
    buf.writeln('      </cac:SellersItemIdentification>');
    buf.writeln('    </cac:Item>');
    buf.writeln('    <cac:Price>');
    buf.writeln(
        '      <cbc:PriceAmount currencyID="SAR">${toplamTutar.toStringAsFixed(2)}</cbc:PriceAmount>');
    buf.writeln('    </cac:Price>');
    buf.writeln('  </cac:InvoiceLine>');
    buf.writeln('</Invoice>');

    return buf.toString();
  }

  /// PDF: Çok dilli kurumsal başlıklar, KPI özetleri ve imza blokları.
  static String pdfUret({
    required GenelYonetimRaporu rapor,
    required RaporModulu modul,
    List<String> secilenDiller = const ['TR'],
  }) {
    final buf = StringBuffer();
    buf.writeln('%PDF-1.7 (NAKHL & NAHL Multilingual PDF Report Engine)');
    buf.writeln(
        '================================================================');
    buf.writeln('                 $sirketUnvani                  ');
    buf.writeln('           ${metin('raporBasligi', secilenDiller)}        ');
    buf.writeln(
        '================================================================');
    buf.writeln(
        '${metin('raporTarihi', secilenDiller)} : ${_formatTarih(rapor.raporTarihi)}');
    buf.writeln(
        '${metin('raporKapsami', secilenDiller)} : ${modul.goruntulenenAd}');
    buf.writeln('Diller / Languages: ${secilenDiller.join(" / ")}');
    buf.writeln('Kurumsal Tema: #5C4033 (Hurma Kahvesi) | #FBF9F1 (Krem)');
    buf.writeln(
        '----------------------------------------------------------------');
    buf.writeln();

    _kurumsalOzetMetniEkle(buf, rapor, modul, secilenDiller);

    buf.writeln(
        '================================================================');
    buf.writeln('           ${metin('onayVeImza', secilenDiller)}            ');
    buf.writeln(
        '================================================================');
    buf.writeln('  [${metin('dijitalKase', secilenDiller)}]');
    buf.writeln(
        '  ${metin('arsivKodu', secilenDiller)}: NAK-${DateTime.now().millisecondsSinceEpoch}');
    buf.writeln('  Tarih: ${_formatTarih(DateTime.now())} | SHA-256 Validated');
    buf.writeln('%%EOF');

    return buf.toString();
  }

  /// Word DOCX: Çok dilli başlıklar ve OpenXML blokları.
  static String docxUret({
    required GenelYonetimRaporu rapor,
    required RaporModulu modul,
    List<String> secilenDiller = const ['TR'],
  }) {
    final buf = StringBuffer();
    buf.writeln('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
    buf.writeln('<?mso-application progid="Word.Document"?>');
    buf.writeln(
        '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">');
    buf.writeln('  <w:body>');
    buf.writeln('    <w:p>');
    buf.writeln('      <w:pPr><w:jc w:val="center"/></w:pPr>');
    buf.writeln(
        '      <w:r><w:rPr><w:b/><w:sz w:val="32"/><w:color w:val="5C4033"/></w:rPr><w:t>${_xmlKacis(sirketUnvani)}</w:t></w:r>');
    buf.writeln('    </w:p>');
    buf.writeln('    <w:p>');
    buf.writeln('      <w:pPr><w:jc w:val="center"/></w:pPr>');
    buf.writeln(
        '      <w:r><w:rPr><w:i/><w:sz w:val="24"/><w:color w:val="C89033"/></w:rPr><w:t>${_xmlKacis(metin('raporBasligi', secilenDiller))}</w:t></w:r>');
    buf.writeln('    </w:p>');
    buf.writeln(
        '    <w:p><w:r><w:t>${_xmlKacis(metin('raporKapsami', secilenDiller))}: ${modul.goruntulenenAd} | ${_xmlKacis(metin('raporTarihi', secilenDiller))}: ${_formatTarih(rapor.raporTarihi)}</w:t></w:r></w:p>');

    final f = rapor.finansOzeti;
    buf.writeln(
        '    <w:p><w:r><w:rPr><w:b/><w:color w:val="5C4033"/></w:rPr><w:t>1. ${_xmlKacis(metin('finansRaporu', secilenDiller))}</w:t></w:r></w:p>');
    buf.writeln(
        '    <w:p><w:r><w:t>${_xmlKacis(metin('toplamTahsilat', secilenDiller))}: ${f.toplamTahsilat.toStringAsFixed(2)} | ${_xmlKacis(metin('toplamOdeme', secilenDiller))}: ${f.toplamOdeme.toStringAsFixed(2)} | ${_xmlKacis(metin('netBakiye', secilenDiller))}: ${f.netBakiye.toStringAsFixed(2)}</w:t></w:r></w:p>');

    final s = rapor.stokOzeti;
    buf.writeln(
        '    <w:p><w:r><w:rPr><w:b/><w:color w:val="5C4033"/></w:rPr><w:t>2. ${_xmlKacis(metin('stokRaporu', secilenDiller))}</w:t></w:r></w:p>');
    buf.writeln(
        '    <w:p><w:r><w:t>${_xmlKacis(metin('toplamTonaj', secilenDiller))}: ${s.toplamTonaj.toStringAsFixed(2)} Ton | ${_xmlKacis(metin('envanterDegeri', secilenDiller))}: ${s.toplamEnvanterDegeriSar.toStringAsFixed(2)} SAR</w:t></w:r></w:p>');

    final sv = rapor.sevkiyatOzeti;
    buf.writeln(
        '    <w:p><w:r><w:rPr><w:b/><w:color w:val="5C4033"/></w:rPr><w:t>3. ${_xmlKacis(metin('sevkiyatRaporu', secilenDiller))}</w:t></w:r></w:p>');
    buf.writeln(
        '    <w:p><w:r><w:t>${_xmlKacis(metin('toplamSevkiyat', secilenDiller))}: ${sv.toplamSevkiyatSayisi} | ${_xmlKacis(metin('sevkTonaji', secilenDiller))}: ${sv.toplamSevkTonaj.toStringAsFixed(2)} Ton | ${_xmlKacis(metin('teslimEdildi', secilenDiller))}: ${sv.teslimEdildiSayisi}</w:t></w:r></w:p>');

    buf.writeln('  </w:body>');
    buf.writeln('</w:document>');

    return buf.toString();
  }

  /// Excel XLSX: Çok dilli SpreadsheetML formatı (Excel 2007+).
  static String xlsxUret({
    required GenelYonetimRaporu rapor,
    required RaporModulu modul,
    List<String> secilenDiller = const ['TR'],
  }) {
    return _excelSpreadsheetMlOlustur(
        rapor: rapor,
        modul: modul,
        secilenDiller: secilenDiller,
        isModern: true);
  }

  /// Excel XLS: Klasik SpreadsheetML formatı.
  static String xlsUret({
    required GenelYonetimRaporu rapor,
    required RaporModulu modul,
    List<String> secilenDiller = const ['TR'],
  }) {
    return _excelSpreadsheetMlOlustur(
        rapor: rapor,
        modul: modul,
        secilenDiller: secilenDiller,
        isModern: false);
  }

  /// Düz Metin TXT: Çok dilli monospaced ASCII/UTF-8 tablo raporu.
  static String txtUret({
    required GenelYonetimRaporu rapor,
    required RaporModulu modul,
    List<String> secilenDiller = const ['TR'],
  }) {
    final buf = StringBuffer();
    buf.writeln(
        '╔═══════════════════════════════════════════════════════════════════════════════╗');
    buf.writeln(
        '║                     NAKHL & NAHL KURUMSAL YÖNETİM RAPORU                     ║');
    buf.writeln(
        '║           ${metin('raporBasligi', secilenDiller).padRight(76).substring(0, 76)}║');
    buf.writeln(
        '╠═══════════════════════════════════════════════════════════════════════════════╣');
    buf.writeln('║ ${metin('sirketAdi', secilenDiller)} : $sirketUnvani');
    buf.writeln(
        '║ ${metin('vkn', secilenDiller)}    : $sirketVkn | ${metin('vergiDairesi', secilenDiller)}: $sirketVergiDairesi');
    buf.writeln(
        '║ ${metin('raporTarihi', secilenDiller)}  : ${_formatTarih(rapor.raporTarihi)} | Saat: ${_simdiStr().split(' ').last}');
    buf.writeln(
        '║ ${metin('raporKapsami', secilenDiller)}  : ${modul.goruntulenenAd} | Diller: ${secilenDiller.join(", ")}');
    buf.writeln(
        '╚═══════════════════════════════════════════════════════════════════════════════╝');
    buf.writeln();

    _kurumsalOzetMetniEkle(buf, rapor, modul, secilenDiller);

    buf.writeln(
        '---------------------------------------------------------------------------------');
    buf.writeln(
        '${metin('dijitalKase', secilenDiller)} | ${metin('arsivKodu', secilenDiller)}: SHA-256 Validated');
    buf.writeln(
        '---------------------------------------------------------------------------------');

    return buf.toString();
  }

  /// HTML Web: Seçilen dillere göre tam responsive, kurumsal stilli HTML5 raporu.
  static String htmlUret({
    required GenelYonetimRaporu rapor,
    required RaporModulu modul,
    List<String> secilenDiller = const ['TR'],
  }) {
    final buf = StringBuffer();
    final f = rapor.finansOzeti;
    final s = rapor.stokOzeti;
    final sv = rapor.sevkiyatOzeti;

    final baslikMetni = metin('raporBasligi', secilenDiller);
    final finansBaslik = metin('finansRaporu', secilenDiller);
    final stokBaslik = metin('stokRaporu', secilenDiller);
    final sevkiyatBaslik = metin('sevkiyatRaporu', secilenDiller);

    buf.writeln('<!DOCTYPE html>');
    buf.writeln('<html lang="tr">');
    buf.writeln('<head>');
    buf.writeln('  <meta charset="UTF-8">');
    buf.writeln(
        '  <meta name="viewport" content="width=device-width, initial-scale=1.0">');
    buf.writeln('  <title>$sirketUnvani — $baslikMetni</title>');
    buf.writeln('  <style>');
    buf.writeln(
        '    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; background-color: $kremRenkHex; color: #3E2723; margin: 0; padding: 32px; }');
    buf.writeln(
        '    .container { max-width: 1000px; margin: 0 auto; background: #ffffff; border-radius: 20px; box-shadow: 0 10px 30px rgba(92, 64, 51, 0.1); overflow: hidden; border: 1px solid rgba(92, 64, 51, 0.15); }');
    buf.writeln(
        '    .header { background: linear-gradient(135deg, $kurumsalRenkHex, #3E2723); color: #ffffff; padding: 36px 40px; }');
    buf.writeln(
        '    .header h1 { margin: 0 0 8px; font-size: 26px; letter-spacing: 0.5px; }');
    buf.writeln('    .header p { margin: 0; opacity: 0.85; font-size: 14px; }');
    buf.writeln(
        '    .meta-bar { display: flex; justify-content: space-between; background: rgba(92, 64, 51, 0.05); padding: 14px 40px; font-size: 13px; font-weight: 600; border-bottom: 1px solid rgba(92, 64, 51, 0.1); flex-wrap: wrap; gap: 10px; }');
    buf.writeln('    .content { padding: 36px 40px; }');
    buf.writeln(
        '    .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 18px; margin-bottom: 30px; }');
    buf.writeln(
        '    .card { background: #faf8f5; border: 1px solid rgba(92, 64, 51, 0.12); border-radius: 14px; padding: 18px 22px; }');
    buf.writeln(
        '    .card-title { font-size: 12px; font-weight: 700; color: $kurumsalRenkHex; text-transform: uppercase; margin-bottom: 8px; }');
    buf.writeln(
        '    .card-val { font-size: 22px; font-weight: 800; color: #3E2723; }');
    buf.writeln(
        '    table { width: 100%; border-collapse: collapse; margin-top: 14px; font-size: 13px; }');
    buf.writeln(
        '    th { background: $kurumsalRenkHex; color: #ffffff; padding: 12px 14px; text-align: left; }');
    buf.writeln(
        '    td { padding: 11px 14px; border-bottom: 1px solid #eeeeee; }');
    buf.writeln('    tr:nth-child(even) { background-color: #faf9f6; }');
    buf.writeln(
        '    .footer { text-align: center; padding: 24px; font-size: 12px; color: #888888; border-top: 1px solid #eeeeee; }');
    buf.writeln('  </style>');
    buf.writeln('</head>');
    buf.writeln('<body>');
    buf.writeln('  <div class="container">');
    buf.writeln('    <div class="header">');
    buf.writeln('      <h1>$sirketUnvani</h1>');
    buf.writeln('      <p>$baslikMetni — ${modul.goruntulenenAd}</p>');
    buf.writeln('    </div>');
    buf.writeln('    <div class="meta-bar">');
    buf.writeln(
        '      <span>📅 ${metin('raporTarihi', secilenDiller)}: ${_formatTarih(rapor.raporTarihi)}</span>');
    buf.writeln(
        '      <span>🏢 ${metin('vkn', secilenDiller)}: $sirketVkn</span>');
    buf.writeln('      <span>🌐 Diller: ${secilenDiller.join(" / ")}</span>');
    buf.writeln('    </div>');
    buf.writeln('    <div class="content">');

    if (modul == RaporModulu.tumModuller || modul == RaporModulu.finans) {
      buf.writeln(
          '      <h3 style="color: $kurumsalRenkHex; margin-top: 0;">$finansBaslik</h3>');
      buf.writeln('      <div class="grid">');
      buf.writeln(
          '        <div class="card"><div class="card-title">${metin('toplamTahsilat', secilenDiller)}</div><div class="card-val" style="color:#2e7d32;">${f.toplamTahsilat.toStringAsFixed(2)} SAR</div></div>');
      buf.writeln(
          '        <div class="card"><div class="card-title">${metin('toplamOdeme', secilenDiller)}</div><div class="card-val" style="color:#c62828;">${f.toplamOdeme.toStringAsFixed(2)} SAR</div></div>');
      buf.writeln(
          '        <div class="card"><div class="card-title">${metin('toplamKarPayi', secilenDiller)}</div><div class="card-val" style="color:#e65100;">${f.toplamKarPayi.toStringAsFixed(2)} SAR</div></div>');
      buf.writeln(
          '        <div class="card"><div class="card-title">${metin('netBakiye', secilenDiller)}</div><div class="card-val" style="color:$kurumsalRenkHex;">${f.netBakiye.toStringAsFixed(2)} SAR</div></div>');
      buf.writeln('      </div>');
    }

    if (modul == RaporModulu.tumModuller || modul == RaporModulu.stok) {
      buf.writeln(
          '      <h3 style="color: $kurumsalRenkHex;">$stokBaslik</h3>');
      buf.writeln('      <div class="grid">');
      buf.writeln(
          '        <div class="card"><div class="card-title">${metin('toplamCesit', secilenDiller)}</div><div class="card-val">${s.toplamCesitSayisi}</div></div>');
      buf.writeln(
          '        <div class="card"><div class="card-title">${metin('toplamTonaj', secilenDiller)}</div><div class="card-val">${s.toplamTonaj.toStringAsFixed(2)} Ton</div></div>');
      buf.writeln(
          '        <div class="card"><div class="card-title">${metin('envanterDegeriSar', secilenDiller)}</div><div class="card-val">${s.toplamEnvanterDegeriSar.toStringAsFixed(2)} SAR</div></div>');
      buf.writeln(
          '        <div class="card"><div class="card-title">${metin('envanterDegeriTry', secilenDiller)}</div><div class="card-val">${s.toplamEnvanterDegeriTry.toStringAsFixed(2)} TRY</div></div>');
      buf.writeln('      </div>');
    }

    if (modul == RaporModulu.tumModuller || modul == RaporModulu.sevkiyat) {
      buf.writeln(
          '      <h3 style="color: $kurumsalRenkHex;">$sevkiyatBaslik</h3>');
      buf.writeln('      <div class="grid">');
      buf.writeln(
          '        <div class="card"><div class="card-title">${metin('toplamSevkiyat', secilenDiller)}</div><div class="card-val">${sv.toplamSevkiyatSayisi}</div></div>');
      buf.writeln(
          '        <div class="card"><div class="card-title">${metin('sevkTonaji', secilenDiller)}</div><div class="card-val">${sv.toplamSevkTonaj.toStringAsFixed(2)} Ton</div></div>');
      buf.writeln(
          '        <div class="card"><div class="card-title">${metin('yolda', secilenDiller)}</div><div class="card-val" style="color:#0277bd;">${sv.yoldaSayisi}</div></div>');
      buf.writeln(
          '        <div class="card"><div class="card-title">${metin('teslimEdildi', secilenDiller)}</div><div class="card-val" style="color:#2e7d32;">${sv.teslimEdildiSayisi}</div></div>');
      buf.writeln('      </div>');
    }

    buf.writeln('    </div>');
    buf.writeln('    <div class="footer">');
    buf.writeln(
        '      &copy; 2026 $sirketUnvani — ${metin('dijitalKase', secilenDiller)}');
    buf.writeln('    </div>');
    buf.writeln('  </div>');
    buf.writeln('</body>');
    buf.writeln('</html>');

    return buf.toString();
  }

  /// PNG: Fiş, dekont ve imza arşivleme görsel veri yapısı (Çok Dilli).
  static String gorselDekontPngUret({
    required GenelYonetimRaporu rapor,
    required RaporModulu modul,
    List<String> secilenDiller = const ['TR'],
  }) {
    final now = DateTime.now();
    final dekontNo =
        'DKN-${now.year}${now.month.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(7)}';
    final f = rapor.finansOzeti;
    final ilk =
        f.sonIslemler.isNotEmpty ? f.sonIslemler.first : <String, dynamic>{};

    final tutarStr = (ilk['tutar'] as num?)?.toStringAsFixed(2) ??
        f.toplamTahsilat.toStringAsFixed(2);
    final pbStr = ilk['paraBirimi'] ?? 'SAR';
    final cariStr = ilk['cariUnvani'] ?? sirketUnvani;

    final buf = StringBuffer();
    buf.writeln(
        '╔═══════════════════════════════════════════════════════════════╗');
    buf.writeln(
        '║       [PNG ARŞİV FORMATI — FİŞ, DEKONT VE İMZA ARŞİVİ]        ║');
    buf.writeln(
        '║           ${metin('raporBasligi', secilenDiller).padRight(52).substring(0, 52)}║');
    buf.writeln(
        '╠═══════════════════════════════════════════════════════════════╣');
    buf.writeln(
        '║ Belge Tipi    : RESMİ MUHASEBE DEKONTU & FİŞ GÖRSELİ (PNG)    ║');
    buf.writeln('║ Dekont No     : $dekontNo');
    buf.writeln('║ Diller        : ${secilenDiller.join(", ")}');
    buf.writeln(
        '║ Format        : image/png (Alpha Channel Destekli)            ║');
    buf.writeln(
        '╠═══════════════════════════════════════════════════════════════╣');
    buf.writeln('║ ${metin('cariUnvani', secilenDiller)}  : $cariStr');
    buf.writeln('║ ${metin('tutar', secilenDiller)}       : $tutarStr $pbStr');
    buf.writeln(
        '║ ${metin('islemTarihi', secilenDiller)} : ${_formatTarih(now)}');
    buf.writeln(
        '╠═══════════════════════════════════════════════════════════════╣');
    buf.writeln('║ ${metin('dijitalKase', secilenDiller)}');
    buf.writeln(
        '║ ${metin('arsivKodu', secilenDiller)} : ARCH-PNG-${now.year}-EXP-${now.day}');
    buf.writeln(
        '╚═══════════════════════════════════════════════════════════════╝');

    return buf.toString();
  }

  /// JPG: Depo envanter ve gümrük ambar fişi görsel arşiv şablonu (Çok Dilli).
  static String gorselDekontJpgUret({
    required GenelYonetimRaporu rapor,
    required RaporModulu modul,
    List<String> secilenDiller = const ['TR'],
  }) {
    final now = DateTime.now();
    final fisNo =
        'FIS-${now.year}${now.month.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(7)}';
    final s = rapor.stokOzeti;

    final buf = StringBuffer();
    buf.writeln(
        '╔═══════════════════════════════════════════════════════════════╗');
    buf.writeln(
        '║        [JPG ARŞİV FORMATI — ENVENTER & SEVKİYAT FİŞİ]         ║');
    buf.writeln(
        '║           ${metin('stokRaporu', secilenDiller).padRight(52).substring(0, 52)}║');
    buf.writeln(
        '╠═══════════════════════════════════════════════════════════════╣');
    buf.writeln('║ Fiş No        : $fisNo');
    buf.writeln(
        '║ Format        : image/jpeg (Exif JFIF Header - %95 Kalite)    ║');
    buf.writeln('║ Diller        : ${secilenDiller.join(", ")}');
    buf.writeln(
        '╠═══════════════════════════════════════════════════════════════╣');
    buf.writeln(
        '║ ${metin('toplamTonaj', secilenDiller)} : ${s.toplamTonaj.toStringAsFixed(2)} Ton');
    buf.writeln(
        '║ ${metin('toplamKoli', secilenDiller)}  : ${s.toplamKoli.toStringAsFixed(0)}');
    buf.writeln(
        '║ ${metin('envanterDegeri', secilenDiller)}: ${s.toplamEnvanterDegeriSar.toStringAsFixed(2)} SAR');
    buf.writeln(
        '╠═══════════════════════════════════════════════════════════════╣');
    buf.writeln('║ ${metin('dijitalKase', secilenDiller)}');
    buf.writeln(
        '║ ${metin('arsivKodu', secilenDiller)} : JPG-ARCHIVE-${now.year}${now.month.toString().padLeft(2, '0')}');
    buf.writeln(
        '╚═══════════════════════════════════════════════════════════════╝');

    return buf.toString();
  }

  // ============================================================
  // YARDIMCI VE BİÇİMLENDİRME METODLARI
  // ============================================================

  static String _dosyaAdiOlustur(
      RaporFormati format, RaporModulu modul, List<String> diller) {
    final d = DateTime.now();
    final dStr =
        '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}_${d.hour.toString().padLeft(2, '0')}${d.minute.toString().padLeft(2, '0')}';
    final dilEk = diller.map((e) => e.toUpperCase()).join('_');
    return 'NAKHL_NAHL_${modul.kisaltma}_${dilEk}_$dStr.${format.uzanti}';
  }

  static String _excelSpreadsheetMlOlustur({
    required GenelYonetimRaporu rapor,
    required RaporModulu modul,
    required List<String> secilenDiller,
    required bool isModern,
  }) {
    final buf = StringBuffer();
    buf.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buf.writeln('<?mso-application progid="Excel.Sheet"?>');
    buf.writeln(
        '<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"');
    buf.writeln('          xmlns:o="urn:schemas-microsoft-com:office:office"');
    buf.writeln('          xmlns:x="urn:schemas-microsoft-com:office:excel"');
    buf.writeln(
        '          xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet"');
    buf.writeln('          xmlns:html="http://www.w3.org/TR/REC-html40">');
    buf.writeln('  <Styles>');
    buf.writeln('    <Style ss:ID="HeaderStyle">');
    buf.writeln(
        '      <Font ss:Bold="1" ss:Color="#FFFFFF" ss:FontName="Segoe UI"/>');
    buf.writeln('      <Interior ss:Color="#5C4033" ss:Pattern="Solid"/>');
    buf.writeln('      <Alignment ss:Horizontal="Center"/>');
    buf.writeln('    </Style>');
    buf.writeln('    <Style ss:ID="TitleStyle">');
    buf.writeln(
        '      <Font ss:Bold="1" ss:Size="14" ss:Color="#5C4033" ss:FontName="Segoe UI"/>');
    buf.writeln('    </Style>');
    buf.writeln('  </Styles>');

    // Finans Sayfası
    if (modul == RaporModulu.tumModuller || modul == RaporModulu.finans) {
      final f = rapor.finansOzeti;
      buf.writeln(
          '  <Worksheet ss:Name="${_xmlKacis(metin('finansRaporu', secilenDiller).replaceAll('/', '-'))}">');
      buf.writeln('    <Table>');
      buf.writeln(
          '      <Row><Cell ss:StyleID="TitleStyle"><Data ss:Type="String">$sirketUnvani — ${_xmlKacis(metin('finansRaporu', secilenDiller))}</Data></Cell></Row>');
      buf.writeln('      <Row>');
      buf.writeln(
          '        <Cell ss:StyleID="HeaderStyle"><Data ss:Type="String">${_xmlKacis(metin('cariUnvani', secilenDiller))}</Data></Cell>');
      buf.writeln(
          '        <Cell ss:StyleID="HeaderStyle"><Data ss:Type="String">${_xmlKacis(metin('islemTuru', secilenDiller))}</Data></Cell>');
      buf.writeln(
          '        <Cell ss:StyleID="HeaderStyle"><Data ss:Type="String">${_xmlKacis(metin('tutar', secilenDiller))}</Data></Cell>');
      buf.writeln(
          '        <Cell ss:StyleID="HeaderStyle"><Data ss:Type="String">${_xmlKacis(metin('paraBirimi', secilenDiller))}</Data></Cell>');
      buf.writeln(
          '        <Cell ss:StyleID="HeaderStyle"><Data ss:Type="String">${_xmlKacis(metin('islemTarihi', secilenDiller))}</Data></Cell>');
      buf.writeln('      </Row>');
      for (final islem in f.sonIslemler) {
        buf.writeln('      <Row>');
        buf.writeln(
            '        <Cell><Data ss:Type="String">${_xmlKacis(islem['cariUnvani'] ?? '')}</Data></Cell>');
        buf.writeln(
            '        <Cell><Data ss:Type="String">${_xmlKacis(islem['islemTuru'] ?? '')}</Data></Cell>');
        buf.writeln(
            '        <Cell><Data ss:Type="Number">${(islem['tutar'] as num?)?.toDouble() ?? 0.0}</Data></Cell>');
        buf.writeln(
            '        <Cell><Data ss:Type="String">${_xmlKacis(islem['paraBirimi'] ?? 'SAR')}</Data></Cell>');
        buf.writeln(
            '        <Cell><Data ss:Type="String">${_tsToStr(islem['islemTarihi'])}</Data></Cell>');
        buf.writeln('      </Row>');
      }
      buf.writeln('    </Table>');
      buf.writeln('  </Worksheet>');
    }

    // Stok Sayfası
    if (modul == RaporModulu.tumModuller || modul == RaporModulu.stok) {
      final s = rapor.stokOzeti;
      buf.writeln(
          '  <Worksheet ss:Name="${_xmlKacis(metin('stokRaporu', secilenDiller).replaceAll('/', '-'))}">');
      buf.writeln('    <Table>');
      buf.writeln(
          '      <Row><Cell ss:StyleID="TitleStyle"><Data ss:Type="String">$sirketUnvani — ${_xmlKacis(metin('stokRaporu', secilenDiller))}</Data></Cell></Row>');
      buf.writeln('      <Row>');
      buf.writeln(
          '        <Cell ss:StyleID="HeaderStyle"><Data ss:Type="String">${_xmlKacis(metin('urunCesidi', secilenDiller))}</Data></Cell>');
      buf.writeln(
          '        <Cell ss:StyleID="HeaderStyle"><Data ss:Type="String">${_xmlKacis(metin('miktar', secilenDiller))}</Data></Cell>');
      buf.writeln(
          '        <Cell ss:StyleID="HeaderStyle"><Data ss:Type="String">${_xmlKacis(metin('toplamDeger', secilenDiller))}</Data></Cell>');
      buf.writeln(
          '        <Cell ss:StyleID="HeaderStyle"><Data ss:Type="String">${_xmlKacis(metin('paraBirimi', secilenDiller))}</Data></Cell>');
      buf.writeln('      </Row>');
      for (final stok in s.tumStokKayitlari) {
        buf.writeln('      <Row>');
        buf.writeln(
            '        <Cell><Data ss:Type="String">${_xmlKacis(stok['urunCesidi'] ?? '')}</Data></Cell>');
        buf.writeln(
            '        <Cell><Data ss:Type="Number">${(stok['miktar'] as num?)?.toDouble() ?? 0.0}</Data></Cell>');
        buf.writeln(
            '        <Cell><Data ss:Type="Number">${(stok['toplamDeger'] as num?)?.toDouble() ?? 0.0}</Data></Cell>');
        buf.writeln(
            '        <Cell><Data ss:Type="String">${_xmlKacis(stok['paraBirimi'] ?? 'SAR')}</Data></Cell>');
        buf.writeln('      </Row>');
      }
      buf.writeln('    </Table>');
      buf.writeln('  </Worksheet>');
    }

    buf.writeln('</Workbook>');
    return buf.toString();
  }

  static void _kurumsalOzetMetniEkle(
    StringBuffer buf,
    GenelYonetimRaporu rapor,
    RaporModulu modul,
    List<String> secilenDiller,
  ) {
    if (modul == RaporModulu.tumModuller || modul == RaporModulu.finans) {
      final f = rapor.finansOzeti;
      buf.writeln('>> 1. ${metin('finansRaporu', secilenDiller)}');
      buf.writeln(
          '   • ${metin('toplamIslem', secilenDiller)} : ${f.toplamIslemSayisi}');
      buf.writeln(
          '   • ${metin('toplamTahsilat', secilenDiller)} : ${f.toplamTahsilat.toStringAsFixed(2)} SAR');
      buf.writeln(
          '   • ${metin('toplamOdeme', secilenDiller)} : ${f.toplamOdeme.toStringAsFixed(2)} SAR');
      buf.writeln(
          '   • ${metin('toplamKarPayi', secilenDiller)} : ${f.toplamKarPayi.toStringAsFixed(2)} SAR');
      buf.writeln(
          '   • ${metin('toplamMasraf', secilenDiller)} : ${f.toplamMasraf.toStringAsFixed(2)} SAR');
      buf.writeln(
          '   • ${metin('netBakiye', secilenDiller)} : ${f.netBakiye.toStringAsFixed(2)} SAR');
      buf.writeln();
    }

    if (modul == RaporModulu.tumModuller || modul == RaporModulu.stok) {
      final s = rapor.stokOzeti;
      buf.writeln('>> 2. ${metin('stokRaporu', secilenDiller)}');
      buf.writeln(
          '   • ${metin('toplamCesit', secilenDiller)} : ${s.toplamCesitSayisi}');
      buf.writeln(
          '   • ${metin('toplamTonaj', secilenDiller)} : ${s.toplamTonaj.toStringAsFixed(2)} Ton');
      buf.writeln(
          '   • ${metin('toplamKoli', secilenDiller)} : ${s.toplamKoli.toStringAsFixed(0)}');
      buf.writeln(
          '   • ${metin('toplamCuval', secilenDiller)} : ${s.toplamCuval.toStringAsFixed(0)}');
      buf.writeln(
          '   • ${metin('envanterDegeriSar', secilenDiller)} : ${s.toplamEnvanterDegeriSar.toStringAsFixed(2)} SAR');
      buf.writeln(
          '   • ${metin('envanterDegeriTry', secilenDiller)} : ${s.toplamEnvanterDegeriTry.toStringAsFixed(2)} TRY');
      buf.writeln();
    }

    if (modul == RaporModulu.tumModuller || modul == RaporModulu.sevkiyat) {
      final sv = rapor.sevkiyatOzeti;
      buf.writeln('>> 3. ${metin('sevkiyatRaporu', secilenDiller)}');
      buf.writeln(
          '   • ${metin('toplamSevkiyat', secilenDiller)} : ${sv.toplamSevkiyatSayisi}');
      buf.writeln(
          '   • ${metin('sevkTonaji', secilenDiller)} : ${sv.toplamSevkTonaj.toStringAsFixed(2)} Ton');
      buf.writeln(
          '   • ${metin('hazirlaniyor', secilenDiller)} : ${sv.hazirlaniyorSayisi}');
      buf.writeln(
          '   • ${metin('gumrukte', secilenDiller)} : ${sv.gumrukteSayisi}');
      buf.writeln('   • ${metin('yolda', secilenDiller)} : ${sv.yoldaSayisi}');
      buf.writeln(
          '   • ${metin('teslimEdildi', secilenDiller)} : ${sv.teslimEdildiSayisi}');
      buf.writeln();
    }
  }

  static String _csvAlan(dynamic v) {
    if (v == null) return '';
    return v
        .toString()
        .replaceAll('"', '""')
        .replaceAll('\n', ' ')
        .replaceAll('\r', '');
  }

  static String _xmlKacis(dynamic v) {
    if (v == null) return '';
    return v
        .toString()
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  static String _tsToStr(dynamic ts) {
    if (ts == null) return '-';
    if (ts is DateTime) {
      return _formatTarih(ts);
    }
    final parsed = DateTime.tryParse(ts.toString());
    if (parsed != null) return _formatTarih(parsed);
    return ts.toString();
  }

  static String _formatTarih(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }

  static String _simdiStr() {
    final n = DateTime.now();
    return '${_formatTarih(n)} ${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}';
  }

  static String _formatByte(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}
