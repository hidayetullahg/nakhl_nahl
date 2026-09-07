import '../models/cari_kart_model.dart';

/// NAKHL & NAHL - Cari Kart İçe / Dışa Aktarım, Telefon Rehberi ve Yazdırma Servisi
class CariExportService {
  /// 1. CSV Formatında Dışa Aktarma (Excel Uyumlu UTF-8 BOM ile)
  static String exportToCsv(List<CariKart> cariler) {
    final buffer = StringBuffer();
    // Excel'in Türkçe, Arapça, Çince karakterleri doğru açması için UTF-8 BOM eklenir
    buffer.write('\uFEFF');

    // Başlıklar
    buffer.writeln(
      'Cari Kodu;Unvan;Cari Tipi;Cari Grubu;Ulke;Para Birimi;Vergi Dairesi;Vergi No/Kimlik;KDV Orani;'
      'Sirket Telefonu;Cep Telefonu;E-Posta;Web Sitesi;Sehir;Fatura Adresi;IBAN;Risk Limiti;Vade (Gun);Yetkili Kisi',
    );

    for (final c in cariler) {
      buffer.writeln(
        '${_cleanCsv(c.cariKodu)};'
        '${_cleanCsv(c.unvan)};'
        '${_cleanCsv(c.cariTipi)};'
        '${_cleanCsv(c.cariGrubu)};'
        '${_cleanCsv(c.ulkeKodu)};'
        '${_cleanCsv(c.paraBirimi)};'
        '${_cleanCsv(c.vergiDairesi)};'
        '${_cleanCsv(c.vergiNo)};'
        '${_cleanCsv(c.kdvOrani)};'
        '${_cleanCsv(c.sirketTelefonu)};'
        '${_cleanCsv(c.cepTelefonu)};'
        '${_cleanCsv(c.eposta)};'
        '${_cleanCsv(c.webSitesi)};'
        '${_cleanCsv(c.sehir)};'
        '${_cleanCsv(c.faturaAdresi)};'
        '${_cleanCsv(c.iban)};'
        '${c.riskLimiti};'
        '${c.vadeGunu};'
        '${_cleanCsv(c.yetkiliKisi)}',
      );
    }

    return buffer.toString();
  }

  /// 2. CSV / Excel Metninden Toplu Cari Kart İçe Aktarma (Bulk Import)
  static List<CariKart> parseCsv(String csvData) {
    final List<CariKart> cariler = [];
    final lines = csvData.split('\n');

    if (lines.length <= 1) return cariler;

    // İlk satır başlık kabul edilir
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      // Hem noktalı virgül (;) hem virgül (,) desteği
      final separator = line.contains(';') ? ';' : ',';
      final parts = line.split(separator);

      if (parts.isNotEmpty && parts[0].trim().isNotEmpty) {
        final cari = CariKart(
          cariKodu: parts.isNotEmpty
              ? parts[0].trim()
              : 'CR-${DateTime.now().millisecondsSinceEpoch}',
          unvan: parts.length > 1 ? parts[1].trim() : 'İsimsiz Cari',
          cariTipi: parts.length > 2 && parts[2].trim().isNotEmpty
              ? parts[2].trim()
              : 'Musteri',
          cariGrubu: parts.length > 3 && parts[3].trim().isNotEmpty
              ? parts[3].trim()
              : 'Genel',
          ulkeKodu: parts.length > 4 && parts[4].trim().isNotEmpty
              ? parts[4].trim()
              : 'TR',
          ulkeAdi: parts.length > 4 ? parts[4].trim() : 'Türkiye',
          paraBirimi: parts.length > 5 && parts[5].trim().isNotEmpty
              ? parts[5].trim()
              : 'TRY',
          vergiDairesi: parts.length > 6 ? parts[6].trim() : '',
          vergiNo: parts.length > 7 ? parts[7].trim() : '',
          vergiTipi: 'Vergi No',
          kdvOrani: parts.length > 8 && parts[8].trim().isNotEmpty
              ? parts[8].trim()
              : '%20',
          sirketTelefonu: parts.length > 9 ? parts[9].trim() : '',
          cepTelefonu: parts.length > 10 ? parts[10].trim() : '',
          eposta: parts.length > 11 ? parts[11].trim() : '',
          webSitesi: parts.length > 12 ? parts[12].trim() : '',
          sehir: parts.length > 13 ? parts[13].trim() : '',
          faturaAdresi: parts.length > 14 ? parts[14].trim() : '',
          iban: parts.length > 15 ? parts[15].trim() : '',
          riskLimiti: parts.length > 16
              ? (double.tryParse(parts[16].trim()) ?? 0.0)
              : 0.0,
          vadeGunu:
              parts.length > 17 ? (int.tryParse(parts[17].trim()) ?? 30) : 30,
          yetkiliKisi: parts.length > 18 ? parts[18].trim() : '',
        );

        cariler.add(cari);
      }
    }

    return cariler;
  }

  /// 3. Örnek CSV Şablonu (Kullanıcının Excel'e yapıştırıp doldurması için)
  static String generateSampleCsvTemplate() {
    return 'Cari Kodu;Unvan;Cari Tipi;Cari Grubu;Ulke;Para Birimi;Vergi Dairesi;Vergi No/Kimlik;KDV Orani;Sirket Telefonu;Cep Telefonu;E-Posta;Web Sitesi;Sehir;Fatura Adresi;IBAN;Risk Limiti;Vade (Gun);Yetkili Kisi\n'
        'CR-TR-001;Anadolu Dış Ticaret A.Ş.;Musteri;Toptanci;TR;TRY;Boğaziçi;1234567890;%20;+90 212 555 0101;+90 532 555 0102;info@anadolu.com;www.anadolu.com;İstanbul;Maslak Mah. No:1;TR330006100511123456789012;250000;45;Ahmet Yılmaz\n'
        'CR-SA-002;Al-Nakhl Dates Trading LLC;Tedarikci;YurtDisi;SA;SAR;Riyadh;300123456700003;%15;+966 11 444 0101;+966 50 444 0102;sales@alnakhl.sa;www.alnakhl.sa;Riyadh;King Fahd Road;SA0380000000608010167519;500000;60;Fahad Al-Otaibi';
  }

  /// 4. Telefon Rehberine Aktarım vCard (.vcf)
  static String toVCard(CariKart cari) {
    return cari.toVCard();
  }

  /// 5. Resmi A4 Yazdırma Özeti Metni
  static String generatePrintableSummary(CariKart c) {
    final buffer = StringBuffer();
    buffer.writeln(
        '================================================================');
    buffer.writeln(
        '          NAKHL & NAHL — RESMİ CARİ HESAP BİLGİ KARTI           ');
    buffer.writeln(
        '================================================================');
    buffer.writeln(
        'Rapor Tarihi: ${DateTime.now().toLocal().toString().split('.')[0]}');
    buffer.writeln(
        '----------------------------------------------------------------');
    buffer.writeln('1. TEMEL VE KİMLİK BİLGİLERİ');
    buffer.writeln('  Cari Kodu       : ${c.cariKodu}');
    buffer.writeln('  Ticari Unvan    : ${c.unvan}');
    buffer.writeln('  Cari Tipi       : ${c.cariTipi} | Grubu: ${c.cariGrubu}');
    buffer.writeln('  Çalışma Durumu  : ${c.aktifMi ? "AKTİF" : "PASİF"}');
    buffer.writeln(
        '----------------------------------------------------------------');
    buffer.writeln('2. YASAL VE VERGİ MEVZUATI');
    buffer.writeln('  Ülke & Mevzuat  : ${c.ulkeAdi} (${c.ulkeKodu})');
    buffer.writeln('  Vergi Numarası  : ${c.vergiNo} (${c.vergiTipi})');
    buffer.writeln('  Devlet Kimlik No: ${c.tckn.isNotEmpty ? c.tckn : "-"}');
    buffer.writeln(
        '  Vergi İdaresi   : ${c.vergiDairesi.isNotEmpty ? c.vergiDairesi : "-"}');
    buffer.writeln('  KDV Oranı       : ${c.kdvOrani}');
    buffer.writeln(
        '  E-Fatura Durumu : ${c.eFaturaMukellefi ? "E-Fatura Mükellefi (${c.eFaturaSenaryosu})" : "E-Arşiv / Klasik"}');
    buffer.writeln(
        '  Mersis / Sicil  : ${c.mersisNo.isNotEmpty ? c.mersisNo : "-"} / ${c.ticaretSicilNo.isNotEmpty ? c.ticaretSicilNo : "-"}');
    buffer.writeln(
        '----------------------------------------------------------------');
    buffer.writeln('3. İLETİŞİM VE ADRES BİLGİLERİ');
    buffer.writeln(
        '  Şirket Tel      : ${c.sirketTelefonu.isNotEmpty ? c.sirketTelefonu : "-"}');
    buffer.writeln(
        '  Cep Tel         : ${c.cepTelefonu.isNotEmpty ? c.cepTelefonu : "-"}');
    buffer.writeln(
        '  Alternatif Tel  : ${c.alternatifTelefon.isNotEmpty ? c.alternatifTelefon : "-"}');
    buffer.writeln(
        '  E-Posta         : ${c.eposta} ${c.eposta2.isNotEmpty ? " / " + c.eposta2 : ""}');
    buffer.writeln(
        '  Web Sitesi      : ${c.webSitesi.isNotEmpty ? c.webSitesi : "-"}');
    buffer.writeln(
        '  Fatura Adresi   : ${c.faturaAdresi} ${c.sehir.isNotEmpty ? " - " + c.sehir : ""}');
    if (c.sevkAdresi.isNotEmpty) {
      buffer.writeln('  Sevk Adresi     : ${c.sevkAdresi}');
    }
    buffer.writeln(
        '----------------------------------------------------------------');
    buffer.writeln('4. FİNANSAL VE TİCARİ ŞARTLAR');
    buffer.writeln('  İşlem Para Birimi: ${c.paraBirimi}');
    buffer.writeln('  Muhasebe Kodu   : ${c.muhasebeKodu}');
    buffer.writeln(
        '  Banka & IBAN    : ${c.bankaAdi.isNotEmpty ? c.bankaAdi + " - " : ""}${c.iban}');
    buffer.writeln(
        '  Risk Limiti     : ${c.riskLimiti} ${c.paraBirimi} (Kontrol: ${c.riskKontrolTipi})');
    buffer.writeln(
        '  Vade Süresi     : ${c.vadeGunu} Gün | İskonto: %${c.iskontoOrani}');
    buffer.writeln('  Ödeme Yöntemi   : ${c.odemePlani}');
    buffer.writeln(
        '----------------------------------------------------------------');
    buffer.writeln('5. YETKİLİ KİŞİ VE NOTLAR');
    buffer.writeln(
        '  İlgili Yetkili  : ${c.yetkiliKisi} ${c.yetkiliUnvan.isNotEmpty ? "(" + c.yetkiliUnvan + ")" : ""}');
    buffer.writeln(
        '  Departman       : ${c.departman.isNotEmpty ? c.departman : "-"} | Plasiyer: ${c.plasiyer.isNotEmpty ? c.plasiyer : "-"}');
    if (c.notlar.isNotEmpty) {
      buffer.writeln('  Özel Notlar     : ${c.notlar}');
    }
    buffer.writeln(
        '================================================================');
    return buffer.toString();
  }

  static String _cleanCsv(String value) {
    if (value.contains(';') || value.contains('\n') || value.contains('"')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
