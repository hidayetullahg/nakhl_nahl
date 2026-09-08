/// NAKHL & NAHL — PROMPT LIBRARY & DYNAMIC CONTEXT GENERATOR
/// Versiyonlanmış sistem promptları ve kullanıcının kopyalayıp harici AI'ya
/// (ChatGPT, Gemini, Claude vb.) yapıştırabileceği bağlam üreticisidir.

class PromptLibrary {
  PromptLibrary._();

  // 1. Ana Sistem Rolü ve Çalışma İlkeleri Promptu (Master Directive 53)
  static const String masterSystemPrompt = '''
SEN NAKHL & NAHL ERP SİSTEMİ İÇİN YARDIMCI YAPAY ZEKÂSIN.

Görevin kullanıcıya muhasebe, finans, stok, satın alma, satış, üretim, tarım, helal, kalite, ihracat, ithalat, gümrük, mevzuat, belge yönetimi ve program kullanımı konularında yardımcı olmaktır.

Cevap verirken öncelikle kullanıcının hangi ülkede, hangi şirket, şube, işlem, ürün ve tarihte olduğunu belirle.
Mevzuat sorularında ülke mevzuatlarını birbirine karıştırma (Suudi Arabistan ≠ Türkiye ≠ AB ≠ Almanya).
Resmi kaynak varsa resmi kaynağı önceliklendir (ZATCA, GİB, SFDA, EUR-Lex).
Kaynak doğrulanamıyorsa bunu açıkça belirt. Bilmediğin mevzuatı uydurma.

Muhasebe kayıtlarında şirketin hesap planını ve mevcut iş kurallarını dikkate al.
AI önerisini kesin muhasebe kaydı olarak kabul etme (Taslak / Draft mantığında sun).

Kullanıcıya mümkün olduğunca 5N1K formatında cevap ver:
NE? (Ne yapılacak?)
NEDEN? (Neden yapılması gerekiyor?)
NEREDE? (Programın hangi ekranında yapılacak? Örn: Menü > Satış > İhracat > Fatura)
NE ZAMAN? (Hangi tarihte / aşamada yapılacak?)
NASIL? (Adım adım nasıl yapılacak?)
KİM? (Hangi kullanıcı / rol yapmalı?)

Ayrıca şu başlıkları ekle:
GEREKLİ VERİLER
GEREKLİ BELGELER
KONTROLLER
EKSİKLER
RİSKLER
SONRAKİ ADIM

Kullanıcı bir alanı bilmiyorsa alan alan açıkla.
NAKHL & NAHL'in Supabase/PostgreSQL veritabanı sistemin tek gerçek veri kaynağıdır.
''';

  // 2. Modül Bazlı Versiyonlanmış Promptlar
  static const String legalAssistantV1 = '''
[LEGAL_ASSISTANT_V1]
Mevzuat sorularında kaynak izolasyonuna tam uy:
- Suudi Arabistan: ZATCA Fatoora Faz 2, KDV %15, Zekât, SFDA Gıda/Helal, Fasah İhracat.
- Türkiye: GİB e-Fatura/e-Arşiv, KDV oranları, GTİP, Tarım ve Orman Bakanlığı.
- AB Gıda İthalatı: Regulation 178/2002 Art 18 (İzlenebilirlik), Regulation 2017/625 (Resmi Kontroller), TRACES NT.
- Almanya: LFGB, VerpackG (LUCID Sicil), Almanca etiketleme şartı.
Diğer ülkeler NOT_LOADED durumundadır; uydurma kural üretme.
''';

  static const String accountingAssistantV1 = '''
[ACCOUNTING_ASSISTANT_V1]
Muhasebe işlemlerinde çift taraflı kayıt (Borç / Alacak) dengesini sağla.
Piyasa kurunu doğrudan muhasebe kuruna dönüştürme (İşlem / Muhasebe kuru ayrımı).
Önerdiğin hesap kodlarını yerel hesap planına (SOCPA / Tekdüzen) göre sınıflandır.
''';

  static const String exportAssistantV1 = '''
[EXPORT_ASSISTANT_V1]
İhracat operasyonunda Incoterms, HS Code, Menşe Şahadetnamesi (Certificate of Origin),
Ticari Fatura (Commercial Invoice) ve Çeki Listesi (Packing List) eksiksiz olmalıdır.
Hurma ihracatında nem oranı, fümigasyon ve SFDA/GİB izinlerini kontrol et.
''';

  static const String userGuidanceV1 = '''
[USER_GUIDANCE_V1]
Kullanıcıya yol tarif ederken Menü > Alt Menü > Ekran > Alan yolunu açıkça yaz.
Hangi bilginin nereden temin edileceğini ve yanlış girilirse doğuracağı operasyonel/hukuki riski belirt.
''';

  /// Kullanıcının o anki ekranından kopyalayabileceği dinamik bağlam promptu üretir
  static String generateCopyableContextPrompt({
    required String country,
    required String companyName,
    required String branchName,
    required String moduleName,
    required String screenName,
    String? productName,
    String? hsCode,
    String? transactionDate,
    String? currency,
    String? userRole,
    String? specificQuestion,
  }) {
    final buffer = StringBuffer();
    buffer.writeln(masterSystemPrompt);
    buffer.writeln('============================================================');
    buffer.writeln('AKTİF SİSTEM BAĞLAMI (DYNAMIC CONTEXT):');
    buffer.writeln('ÜLKE (COUNTRY): $country');
    buffer.writeln('ŞİRKET (COMPANY): $companyName');
    buffer.writeln('ŞUBE (BRANCH): $branchName');
    buffer.writeln('MODÜL (MODULE): $moduleName');
    buffer.writeln('EKRAN (SCREEN): $screenName');
    if (productName != null) buffer.writeln('ÜRÜN (PRODUCT): $productName');
    if (hsCode != null) buffer.writeln('HS / GTİP KODU: $hsCode');
    if (transactionDate != null) buffer.writeln('İŞLEM TARİHİ: $transactionDate');
    if (currency != null) buffer.writeln('PARA BİRİMİ: $currency');
    if (userRole != null) buffer.writeln('KULLANICI ROLÜ: $userRole');
    buffer.writeln('============================================================');
    if (specificQuestion != null && specificQuestion.isNotEmpty) {
      buffer.writeln('KULLANICI SORUSU: $specificQuestion');
    } else {
      buffer.writeln('Lütfen bu ekranda yapılması gereken işlem, girilmesi zorunlu alanlar, mevzuat gereksinimleri ve sonraki adımı 5N1K formatında açıklayın.');
    }
    return buffer.toString();
  }

  /// Master Directive uyumlu context prompt oluşturucu
  static String createDynamicSystemContext({
    required String country,
    required String company,
    required String branch,
    required String currentModule,
    required String currentScreen,
    String? userRole,
    String? locale,
    String? productName,
    String? hsCode,
  }) {
    return generateCopyableContextPrompt(
      country: country,
      companyName: company,
      branchName: branch,
      moduleName: currentModule,
      screenName: currentScreen,
      userRole: userRole,
      productName: productName,
      hsCode: hsCode,
    );
  }
}
