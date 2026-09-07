/// ============================================================
/// AKILLI CARİ KOD ÜRETİCİ  (Madde 7.1)
/// ============================================================
/// Kod formatı:  [ÜLKE]-[BİZİM ŞİRKET KISALTMAMIZ]-[TARİH ddMMyy]-
///               [CARİ TİPİ]-[GİZLİ RİSK KODU]-[GÜNLÜK SIRA NO]
///
/// ÖNEMLİ: Buradaki şirket kısaltması, MÜŞTERİNİN değil, bu programı
/// kullanan BİZİM kendi şirketimizin sabit kısaltmasıdır.
///
/// Örnek çıktı: TR-HGLTD-050926-COSTU-AB-0001
library smart_code_generator;

enum CariTipi { musteri, tedarikci, ortak }

/// Yönetici tarafından atanan, tamamen ticari/finansal disipline dayalı,
/// hakaret veya iftira içermeyen objektif risk sınıfları (Madde 7.3).
enum GizliRiskKodu {
  aa, // Mükemmel: sorunsuz ödeyen, düzenli, güvenilir
  ab, // Düzenli/Yeni: aktif çalışan hesap, dönemsel esneklik
  za, // Borçlu: yakın takip gerektiren bakiye
  zz, // Sürekli aksatan: riskli ödeme disiplini
  zzxx, // Yüksek riskli / dolandırıcılık şüphesi
}

const Map<GizliRiskKodu, String> riskKoduAciklamalari = {
  GizliRiskKodu.aa: 'AA — Mükemmel müşteri (sorunsuz ödeme, yüksek güven)',
  GizliRiskKodu.ab: 'AB — Düzenli / yeni müşteri (aktif, dönemsel esneklik)',
  GizliRiskKodu.za: 'ZA — Borçlu müşteri (yakın takip gerektirir)',
  GizliRiskKodu.zz: 'ZZ — Ödemeyi sürekli aksatan (riskli)',
  GizliRiskKodu.zzxx:
      'ZZXX — Yüksek riskli / dolandırıcılık şüphesi (kara liste)',
};

String _riskKisaKod(GizliRiskKodu risk) {
  switch (risk) {
    case GizliRiskKodu.aa:
      return 'AA';
    case GizliRiskKodu.ab:
      return 'AB';
    case GizliRiskKodu.za:
      return 'ZA';
    case GizliRiskKodu.zz:
      return 'ZZ';
    case GizliRiskKodu.zzxx:
      return 'ZZXX';
  }
}

String _tarihStr(DateTime t) {
  String iki(int n) => n.toString().padLeft(2, '0');
  return '${iki(t.day)}${iki(t.month)}${t.year.toString().substring(2)}';
}

/// Akıllı cari kodu üretir.
/// [siraNo] gerçek sistemde günlük sayaçtan (Firestore transaction/counter)
/// alınmalıdır; burada varsayılan olarak dışarıdan verilir.
String akilliCariKoduUret({
  required String ulkeKisaKodu,
  required String bizimSirketKisaltmamiz,
  required CariTipi cariTipi,
  required GizliRiskKodu riskKodu,
  required int siraNo,
  DateTime? tarih,
}) {
  final String tipKodu;
  switch (cariTipi) {
    case CariTipi.musteri:
      tipKodu = 'COSTU';
      break;
    case CariTipi.tedarikci:
      tipKodu = 'SUPPL';
      break;
    case CariTipi.ortak:
      tipKodu = 'PARTN';
      break;
  }
  final gun = _tarihStr(tarih ?? DateTime.now());
  final sira = siraNo.toString().padLeft(4, '0');
  return '$ulkeKisaKodu-${bizimSirketKisaltmamiz.toUpperCase()}-$gun-$tipKodu-${_riskKisaKod(riskKodu)}-$sira';
}
