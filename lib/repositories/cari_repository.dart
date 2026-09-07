import '../models/cari_kart_model.dart';
import '../services/supabase_service.dart';
import '../core/tenant/tenant_context.dart';

class CariRepository {
  CariRepository._();
  static final CariRepository instance = CariRepository._();

  /// Aktif tenant'a ait carileri listeler
  Future<List<CariKart>> getCariler(
      {String? cariTipi, String? aramaMetni}) async {
    try {
      final tenantId = TenantContext.instance.activeTenantId;
      if (tenantId == null) return [];

      var query = SupabaseService.client
          .from('cariler')
          .select()
          .eq('tenant_id', tenantId);

      if (cariTipi != null && cariTipi.isNotEmpty) {
        query = query.eq('cari_tipi', cariTipi);
      }

      if (aramaMetni != null && aramaMetni.trim().isNotEmpty) {
        query = query.ilike('unvan', '%${aramaMetni.trim()}%');
      }

      final response = await query.order('olusturma_tarihi', ascending: false);

      return (response as List<dynamic>).map((data) {
        final map = data as Map<String, dynamic>;
        return CariKart(
          id: map['id'],
          cariKodu: map['cari_kodu'] ?? '',
          unvan: map['unvan'] ?? '',
          cariTipi: map['cari_tipi'] ?? 'Musteri',
          cariGrubu: map['cari_grubu'] ?? 'Genel',
          ozelKod1: map['ozel_kod1'] ?? '',
          ozelKod2: map['ozel_kod2'] ?? '',
          vergiDairesi: map['vergi_dairesi'] ?? '',
          vergiNo: map['vergi_no'] ?? '',
          tckn: map['tckn'] ?? '',
          eFaturaMukellefi: map['e_fatura_mukellefi'] ?? false,
          eFaturaSenaryosu: map['e_fatura_senaryosu'] ?? 'Temel',
          eFaturaAlias: map['e_fatura_alias'] ?? '',
          mersisNo: map['mersis_no'] ?? '',
          ticaretSicilNo: map['ticaret_sicil_no'] ?? '',
          ulkeKodu: map['ulke_kodu'] ?? 'SA',
          ulkeAdi: map['ulke_adi'] ?? 'Suudi Arabistan',
          vergiTipi: map['vergi_tipi'] ?? 'TRN',
          kdvOrani: map['kdv_orani'] ?? '%15',
          faturaAdresi: map['fatura_adresi'] ?? '',
          sevkAdresi: map['sevk_adresi'] ?? '',
          sirketTelefonu: map['sirket_telefonu'] ?? '',
          cepTelefonu: map['cep_telefonu'] ?? '',
          alternatifTelefon: map['alternatif_telefon'] ?? '',
          eposta: map['eposta'] ?? '',
          eposta2: map['eposta2'] ?? '',
          webSitesi: map['web_sitesi'] ?? '',
          sehir: map['sehir'] ?? '',
          ilce: map['ilce'] ?? '',
          postaKodu: map['posta_kodu'] ?? '',
          lokasyon: map['lokasyon'] ?? '',
          paraBirimi: map['para_birimi'] ?? 'SAR',
          muhasebeKodu: map['muhasebe_kodu'] ?? '120.01.001',
          bankaAdi: map['banka_adi'] ?? '',
          bankaSube: map['banka_sube'] ?? '',
          iban: map['iban'] ?? '',
          iban2: map['iban2'] ?? '',
          swiftKodu: map['swift_kodu'] ?? '',
          kdvMuaf: map['kdv_muaf'] ?? false,
          kdvMuafiyetKodu: map['kdv_muafiyet_kodu'] ?? '',
          tevkifatKodu: map['tevkifat_kodu'] ?? '',
          riskLimiti: (map['risk_limiti'] as num?)?.toDouble() ?? 0.0,
          riskKontrolTipi: map['risk_kontrol_tipi'] ?? 'Uyar',
          teminatTutari: (map['teminat_tutari'] as num?)?.toDouble() ?? 0.0,
          teminatDetayi: map['teminat_detayi'] ?? '',
          vadeGunu: map['vade_gunu'] ?? 30,
          fiyatListesi: map['fiyat_listesi'] ?? 'Standart',
          iskontoOrani: (map['iskonto_orani'] as num?)?.toDouble() ?? 0.0,
          odemePlani: map['odeme_plani'] ?? 'Havale',
          yetkiliKisi: map['yetkili_kisi'] ?? '',
          yetkiliUnvan: map['yetkili_unvan'] ?? '',
          departman: map['departman'] ?? '',
          plasiyer: map['plasiyer'] ?? '',
          aktifMi: map['aktif_mi'] ?? true,
          notlar: map['notlar'] ?? '',
          kayitTarihi: map['olusturma_tarihi'] != null
              ? DateTime.tryParse(map['olusturma_tarihi'])
              : null,
          guncellemeTarihi: map['guncelleme_tarihi'] != null
              ? DateTime.tryParse(map['guncelleme_tarihi'])
              : null,
          kayitDili: map['kayit_dili'] ?? 'TR',
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Yeni Cari Kart ekler (Tenant izole)
  Future<CariKart?> cariKaydet(CariKart cari) async {
    try {
      final tenantId = TenantContext.instance.activeTenantId;
      if (tenantId == null)
        throw Exception('Aktif bir şirket/tenant seçilmedi.');

      final payload = {
        'tenant_id': tenantId,
        'company_id': TenantContext.instance.activeCompanyId,
        'cari_kodu': cari.cariKodu.trim(),
        'unvan': cari.unvan.trim(),
        'cari_tipi': cari.cariTipi,
        'cari_grubu': cari.cariGrubu,
        'ozel_kod1': cari.ozelKod1,
        'ozel_kod2': cari.ozelKod2,
        'vergi_dairesi': cari.vergiDairesi,
        'vergi_no': cari.vergiNo,
        'tckn': cari.tckn,
        'e_fatura_mukellefi': cari.eFaturaMukellefi,
        'e_fatura_senaryosu': cari.eFaturaSenaryosu,
        'e_fatura_alias': cari.eFaturaAlias,
        'mersis_no': cari.mersisNo,
        'ticaret_sicil_no': cari.ticaretSicilNo,
        'ulke_kodu': cari.ulkeKodu,
        'ulke_adi': cari.ulkeAdi,
        'vergi_tipi': cari.vergiTipi,
        'kdv_orani': cari.kdvOrani,
        'fatura_adresi': cari.faturaAdresi,
        'sevk_adresi': cari.sevkAdresi,
        'sirket_telefonu': cari.sirketTelefonu,
        'cep_telefonu': cari.cepTelefonu,
        'alternatif_telefon': cari.alternatifTelefon,
        'eposta': cari.eposta,
        'eposta2': cari.eposta2,
        'web_sitesi': cari.webSitesi,
        'sehir': cari.sehir,
        'ilce': cari.ilce,
        'posta_kodu': cari.postaKodu,
        'lokasyon': cari.lokasyon,
        'para_birimi': cari.paraBirimi,
        'muhasebe_kodu': cari.muhasebeKodu,
        'banka_adi': cari.bankaAdi,
        'banka_sube': cari.bankaSube,
        'iban': cari.iban,
        'iban2': cari.iban2,
        'swift_kodu': cari.swiftKodu,
        'kdv_muaf': cari.kdvMuaf,
        'kdv_muafiyet_kodu': cari.kdvMuafiyetKodu,
        'tevkifat_kodu': cari.tevkifatKodu,
        'risk_limiti': cari.riskLimiti,
        'risk_kontrol_tipi': cari.riskKontrolTipi,
        'teminat_tutari': cari.teminatTutari,
        'teminat_detayi': cari.teminatDetayi,
        'vade_gunu': cari.vadeGunu,
        'fiyat_listesi': cari.fiyatListesi,
        'iskonto_orani': cari.iskontoOrani,
        'odeme_plani': cari.odemePlani,
        'yetkili_kisi': cari.yetkiliKisi,
        'yetkili_unvan': cari.yetkiliUnvan,
        'departman': cari.departman,
        'plasiyer': cari.plasiyer,
        'aktif_mi': cari.aktifMi,
        'notlar': cari.notlar,
        'kayit_dili': cari.kayitDili,
        'guncelleme_tarihi': DateTime.now().toIso8601String(),
      };

      final response = await SupabaseService.client
          .from('cariler')
          .insert(payload)
          .select()
          .single();

      cari.id = response['id'];
      return cari;
    } catch (e) {
      rethrow;
    }
  }
}
