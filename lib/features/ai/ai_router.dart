import 'ai_provider.dart';

/// NAKHL & NAHL — AI ROUTER & TASK CLASSIFICATION
/// ERP işlemlerini ve kullanıcı sorularını sınıflandırarak en uygun AI modeline yönlendirir.

enum AITaskType {
  generalQA('GENEL_SORU_CEVAP'),
  accounting('MUHASEBE_HESAP_PLANI'),
  tax('VERGI_ZEKAT'),
  legal('MEVZUAT_HUKUK'),
  customs('GUMRUK_TARIFE'),
  trade('DIS_TICARET_IHRACAT'),
  inventory('STOK_ENVANTER'),
  agriculture('TARIM_HASAT'),
  halal('HELAL_UYUMLULUK'),
  quality('KALITE_GIDA_GUVENLIGI'),
  finance('FINANS_KASA_NAKIT'),
  banking('BANKA_MUTABAKAT'),
  document('BELGE_YONETIMI'),
  ocr('GORSEL_METIN_OKUMA_OCR'),
  translation('DIL_CEVIRI_TRANSLITERASYON'),
  reporting('ANALITIK_RAPORLAMA'),
  userGuidance('5N1K_KULLANICI_REHBERI');

  final String code;
  const AITaskType(this.code);
}

class AIRouter {
  AIRouter._();
  static final AIRouter instance = AIRouter._();

  /// Görev türüne göre önerilen en yetkin sağlayıcıyı döner
  AIProviderType routeTask(AITaskType task) {
    switch (task) {
      case AITaskType.legal:
      case AITaskType.tax:
      case AITaskType.customs:
      case AITaskType.trade:
        return AIProviderType.claude; // Güçlü hukuk ve kural analizi

      case AITaskType.ocr:
      case AITaskType.document:
        return AIProviderType.gemini; // Güçlü multimodal & OCR

      case AITaskType.translation:
        return AIProviderType.qwen; // Çok dilli Doğu/Batı çeviri kabiliyeti

      case AITaskType.accounting:
      case AITaskType.finance:
      case AITaskType.banking:
        return AIProviderType.openAI; // Yapılandırılmış JSON & hesap planı doğruluğu

      case AITaskType.reporting:
      case AITaskType.inventory:
      case AITaskType.agriculture:
      case AITaskType.halal:
      case AITaskType.quality:
      case AITaskType.generalQA:
      case AITaskType.userGuidance:
        return AIProviderType.deepSeek; // Yüksek muhakeme & maliyet optimizasyonu
    }
  }
}
