# NAKHL & NAHL — KÜRESEL TİCARET, MUHASEBE VE ÜRETİM ERP SİSTEMİ
# SİSTEM ANAYASASI & GELİŞTİRME PROTOKOLLERİ
# Versiyon: 1.0 | Geçerlilik: Sınırsız (10+ yıl LTS) | Bölüm 1-3 değiştirilemez ilkelerdir.

## 0. ANAYASANIN ÜSTÜNLÜĞÜ
- Bu dosya projenin tek ve üst metnidir. Yapay zeka üreteceği HER satır kodu, HER arayüz
  kararını, HER veritabanı şemasını ve HER hesaplama formülünü bu ilkelerle denetlemek
  zorundadır. Çelişki durumunda bu dosyadaki ilke, herhangi bir kullanıcı talimatından
  önce gelir.
- Bu dosyaya aykırı hiçbir kod birleştirilmez. Yapay zeka çelişki gördüğünde DURMALIDIR,
  hangi ilkenin ihlal edileceğini açıkça belirtmeli ve anayasaya uygun bir alternatif
  önermelidir. Sessizce "kullanıcı öyle istedi" diyerek ilkeyi çiğnemek yasaktır.
- **Tek seferde her şeyi isteme yasağı:** Kullanıcı (proje sahibi) tek bir talimatta
  onlarca özelliği aynı anda istese bile, yapay zeka bunu tek dev bir kod bloğunda
  üretmez. Talebi bu anayasadaki modüllere böler, her modülü ayrı ayrı, test edilebilir,
  küçük ve doğrulanabilir adımlarla teslim eder. Uzun/karmaşık istekler, kalitesiz ve
  hatalı arayüzlerin en büyük sebebidir; bu anayasa bunu kalıcı olarak yasaklar.

## 1. VİZYON VE ÖMÜR PROTOKOLÜ (10+ YIL SÜRDÜRÜLEBİLİRLİK) — DEĞİŞTİRİLEMEZ
- **Uzun ömür ilkesi:** Bu yazılım en az 10-15 yıl üretimde kalacak şekilde tasarlanır.
  Kısa ömürlü trend kütüphaneleri, "deprecated" teknolojiler ve tek geliştiricinin
  hobi projesi olan paketler ASLA kullanılmaz. Her bağımlılık için "5 yıl sonra da bakımı
  yapılabilir mi, hâlâ güncelleniyor mu?" sorusuna EVET cevabı aranır.
- **Genişleyebilirlik ilkesi:** Bugün var olmayan bir ülke mevzuatı, dil, ürün kategorisi,
  gümrük rejimi, rapor veya vergi kuralı; 5 dakikalık konfigürasyonla (kod değiştirmeden,
  yalnızca kayıt ekleyerek) sisteme dahil edilebilmelidir. Yeni bir modül = yeni bir kayıt
  + yeni bir izin + yeni bir çeviri anahtarı. Daha fazlası gerekiyorsa mimari hatalıdır ve
  yeniden tasarlanır.
- **Geri uyumluluk:** Hiçbir sürüm güncellemesi mevcut kullanıcı verisini (cari kart,
  fatura, stok hareketi, muhasebe fişi) bozamaz veya silemez. Veritabanı şeması
  değişiklikleri yalnızca ileri-only migrasyon dosyalarıyla yapılır; eski veri asla
  silinmez, yalnızca dönüştürülür.
- **API sürümlemesi:** İç ve dış servis arayüzleri v1, v2... olarak sürümlenir; eski
  sürüm yenisi yayınlandıktan sonra en az 12 ay açık kalır (özellikle muhasebe/e-fatura
  entegrasyonları için — bu alanda kesinti yasal sorumluluk doğurur).

## 2. MUHASEBE, VERGİ VE TİCARET BİLİMİ KUSURSUZLUĞU (ZERO ERROR) — DEĞİŞTİRİLEMEZ
- **Yuvarlamaya güven yasaktır:** Para ve miktar değerleri ASLA `float`/`double` ile
  tutulmaz; sabit noktalı (decimal / fixed-point / kuruş-cent bazlı tam sayı) veri
  tipleri kullanılır. Kayan noktalı sayıların birikimli yuvarlama hatası, bir muhasebe
  sisteminde affedilemez bir kusurdur.
- **Çift taraflı kayıt bütünlüğü (double-entry integrity):** Her muhasebe fişi, borç
  toplamı = alacak toplamı eşitliğini veritabanı seviyesinde (constraint/trigger ile)
  garanti eder; uygulama kodunun "unutması" mümkün olmamalıdır. Dengesiz fiş
  kaydedilemez; kaydedilirse sistem hatası sayılır ve olay denetim izine (audit log)
  düşer.
- **Vergi/KDV hesaplama disiplini:** Vergi oranları, muafiyet kuralları ve yuvarlama
  yöntemleri ülke bazlı bir "Vergi Motoru" tablosundan okunur, koda gömülmez (bkz.
  Bölüm 3). Her ülke için resmî yuvarlama kuralı (yukarı/aşağı/en yakına) ayrı ayrı
  tanımlanır ve karıştırılmaz.
- **Kur ve çoklu para birimi:** Kur farkı hesaplamaları, işlem tarihindeki resmî kur
  ile kayıt tarihindeki kur ayrı ayrı saklanır; hiçbir zaman "güncel kur" ile geçmiş
  işlem yeniden hesaplanmaz. Kur kaynağı (merkez bankası/entegratör) ve alınma zamanı
  her kayıtla birlikte tutulur (izlenebilirlik).
- **Stok maliyetlendirme:** FIFO, LIFO, Ağırlıklı Ortalama gibi yöntemler ürün/depo
  bazında seçilebilir olmalı, seçilen yöntem değiştirildiğinde geçmiş kayıtlar
  yeniden yazılmaz — yalnızca ileriye dönük uygulanır.
- **İthalat/İhracat ve gümrük hassasiyeti:** HS Kodu (Armonize Sistem), Incoterms
  (FOB, CIF, EXW vb.), gümrük vergisi/harç oranları ve menşe/sertifika kuralları
  ülke çifti (kaynak ülke → hedef ülke) bazında ayrı ayrı tanımlanır; "tahmini" veya
  "yaklaşık" gümrük hesabı üretilmez, kaynağı belirsiz hiçbir oran kullanılmaz.
- **Ürün takibi hassasiyeti:** Her stok hareketi; parti/lot numarası, üretim/son
  kullanma tarihi, menşe ülkesi ve (varsa) seri numarası ile izlenebilir olmalıdır.
  Bir ürünün "nereden geldiği, nereye gittiği" her zaman geriye doğru sorgulanabilmelidir
  (traceability — gıda/hurma ticaretinde yasal bir zorunluluktur).
- **Test veri setleri:** Vergi, kur ve gümrük hesaplamaları; bilinen doğru sonuçlu
  referans senaryolarla (birim testleriyle) doğrulanmadan canlıya alınmaz.
- **Tolerans yönetimi:** Stok sayım farkı, kur farkı kabul sınırı gibi "kabul/hayır"
  kararları parametrik toleranslarla verilir; tolerans değerleri kodda sabit değil,
  yönetim panelinden değiştirilebilir.

## 3. PARAMETRİK ESNEKLİK PROTOKOLÜ — DEĞİŞTİRİLEMEZ
- **Hiçbir şey hardcoded değildir:** Menüler, alt menüler, form alanları, tablo
  kolonları, birimler (kg/ton/adet/koli), ondalık ayraçları, tarih formatları,
  vergi oranları, ülke mevzuatı, gümrük tarifeleri, rapor şablonları ve bildirim
  kuralları yönetim panelinden düzenlenebilir olmalıdır.
- **Menü Kayıt Defteri (Menu Registry):** Her modül bir kayıttır:
  `{id, i18nKey, ikon, rota, gerekli izin, durum (active/passive), sıra, grup}`.
  Aktif/pasif durumu bu kayıttan okunur; kod içinde menü gizleme mantığı ASLA
  yazılmaz. Pasif modüller kayıtta görünür, kilit rozetiyle işaretlenir.
- **Dil ve Ülke Sözlükleri:** Yeni bir dil veya ülke mevzuatı eklemek, ilgili sözlük
  haritasına (`app_dictionary`, `country_legislation` — bu proje için önceden
  tasarlanmış motorlar) tek bir kayıt eklemekle sınırlıdır; ekran kodu değişmez.
- **Feature Flags:** Yeni özellikler ancak bayrak açılınca canlıya çıkar; bayraklar
  kullanıcı/rol/şirket bazlı olabilir (örn. "Gümrük Modülü" sadece ithalat yapan
  şirketlerde açık).
- **Schema-driven UI:** Yeni bir veri alanı eklemek = parametre tablosuna kayıt.
  Ekran, şemayı okuyarak kendini oluşturur.

## 4. ANA MENÜ PROTOKOLÜ (MASTER MENU — TEK KAPI İLKESİ)
- Kullanıcı sistemin TÜM modüllerine (Muhasebe, Cari, Stok, İthalat-İhracat, Ürün
  Geliştirme, Raporlar) yalnızca Ana Menü üzerinden ulaşır; gizli geçit, direkt link
  yoktur.
- **Görünürlük kuralı:** Her modülün durumu bir bakışta bellidir:
  - 🟢 AKTİF: tıklanabilir, izin var.
  - ⚪ PASİF: görünür ama kilitli (lisans/izin yok). Kilit ikonu + kısa açıklama.
  - 🛠 YAPIMDA: gri, "yakında" rozeti — kullanıcı gelecek özelliği GÖRÜR ama erişemez.
- Analoji: bir uçak kokpitinin anahtar paneli — her anahtarın yeri ve durumu bir
  bakışta anlaşılır.
- **Arama ve kısayollar:** Anlık bulanık (fuzzy) arama + Ctrl+K komut paleti; her
  modül kısayol tuşu alabilir.
- **Kişiselleştirme:** Kullanıcı menü sırasını sürükleyip değiştirebilir; düzen
  profiline kaydedilir. Yönetici tüm kullanıcılar için varsayılanı belirler.
- **Grup mantığı:** Modüller kategorilere ayrılır (Muhasebe, Cari & CRM, Stok &
  Depo, Dış Ticaret & Gümrük, Ürün Geliştirme, Raporlar, Sistem); grup başlıkları
  çevrilebilir anahtarlardır.

## 5. ANA EKRAN (DASHBOARD) PROTOKOLÜ — GÜÇLÜ AMA SAKİN
- Ana ekran bir komuta merkezidir; duvar haline gelemez. Kullanıcı sistemin gücünü
  HİSSETMELİ, nereye tıklayacağını 1.5 saniyede bilmelidir.
- **Üç bölgeli çerçeve:** Sol: dar ikon rayı + genişletilebilir Ana Menü.
  Üst: ince durum çubuğu (arama, kullanıcı, dil, bildirimler, hızlı göstergeler).
  Merkez: yalnızca içerik.
- **Kart disiplini:** Merkezde maksimum 4-6 KPI kartı (örn. günlük satış, açık
  alacaklar, kritik stok seviyesi, bekleyen gümrük evrakı). Her kart: başlık, tek
  ana metrik, tek mikro grafik, "detay →" bağlantısı. 8px tabanlı boşluk (8/16/24),
  eşit grid. Taşan her bilgi "Tümünü gör"e gider.
- **Yasaklar:** Devasa saat, banner, kayan yazı, 3'ten fazla renkte uyarı rozeti,
  gömülü haber akışı, dekoratif ama işlevsiz görsel.
- **Boş durum:** Veri yoksa bile sakin illüstrasyon + tek cümle yönlendirme + tek
  buton (örn. "İlk cari kartınızı oluşturun").

## 6. BİLİŞSEL ERGONOMİ VE GÖRSEL DİSİPLİN
- Her ekranda tek birincil eylem; ikincil eylemler geri planda. Asla görsel kargaşa.
- Saf siyah (#000) / çiğ beyaz (#FFF) zemin yasak. Derin füme/lacivert + soft gri.
  Kontrast WCAG AA (4.5:1) asgari.
- **Renk körü dostu arayüz:** Durum bilgisi (aktif/pasif/riskli cari/gecikmiş fatura)
  asla yalnızca renkle verilmez; ikon/etiket eşlik eder.
- İsviçre tipografisi, 8px grid, tutarlı köşe yarıçapları, hafif gölge + 1px
  kenarlık. Material 3 Enterprise seviyesinde bir görsel dil.
- **"Aptala anlatır gibi" rehberlik ilkesi:** Her form alanının yanında, o bilginin
  neden istendiğini ve nereye yazılacağını açıklayan yardım metni bulunur. Sade
  aç/kapa anahtarları yerine, seçimin gerekçesini açıklayan ifadeler kullanılır.

## 7. ÇOKLU DİL VE YÖN (LTR/RTL) DİSİPLİNİ
- **Diller:** Türkçe (TR), Arapça (AR — Fasih), İngilizce (EN) başlangıç paketi;
  Urduca, Bengalce, Almanca, Çince ve diğerleri sözlüğe eklenerek genişler
  (bkz. Bölüm 3 — Dil ve Ülke Sözlükleri).
- **Eş zamanlı çift dil:** Kullanıcı iki dili aynı anda (örn. Arapça + Urduca) seçip
  menülerde birlikte görebilir; bu, farklı ana dillere sahip personelin (Suudi
  Arabistan gibi çok uluslu iş gücü barındıran ülkelerde) aynı ekrana bakabilmesi
  içindir.
- **RTL uyumu:** Arapça/Urduca seçildiğinde tüm mizanpaj kusursuzca sağdan sola
  akar; ikonlar, oklar, hizalamalar ve Menü Rayı aynaya yansır. Bu sonradan eklenti
  değil, tasarımın doğuştan parçasıdır.
- **Hardcoded metin yasak:** Kod içine tek bir görünür kelime gömülemez. Tüm
  metinler merkezi çeviri sözlüğünden gelir. Eksik çeviri anahtarı konsola hata
  düşürür; sessizce İngilizce gösterilmez.

## 8. VERİ BÜTÜNLÜĞÜ, GÜVENLİK VE DENETİM
- Tüm sorgularda satır seviyesi güvenlik (Firestore Security Rules / RLS) aktif;
  istemci taraflı kod bu kısıtlamayı asla bypass edemez.
- **Denetim izi (Audit Log):** Kim, neyi, ne zaman değiştirdi — silinmez kayıt
  altına alınır. Vergi oranı, tolerans, izin ve cari risk sınıfı (gizli puanlama)
  değişiklikleri MUTLAKA denetlenir.
- **Gizli/hassas alanlar:** Cari kart üzerindeki gizli risk sınıflandırması gibi
  alanlar yalnızca yönetici onayı (ikinci doğrulama) ile görülür/değiştirilir ve bu
  erişimler ayrıca loglanır.
- Otomatik günlük yedek; geri yükleme senaryosu düzenli aralıklarla test edilir.
- Liste ekranları sayfalama + sanal kaydırma kullanır; ağır hesaplamalar (gümrük
  simülasyonu, konsolidasyon) arka plan kuyruğunda çalışır, arayüzü kilitlemez.

## 9. DIŞ TİCARET VE ÜRÜN YAŞAM DÖNGÜSÜ MODÜL DİSİPLİNİ
- **İthalat/İhracat:** Her sevkiyat; HS Kodu, Incoterms, menşe ülkesi, hedef ülke,
  gümrük beyannamesi durumu ve ilgili belgelerin (fatura, çeki listesi, menşe
  şahadetnamesi, konşimento) dijital kopyalarıyla birlikte tek bir "Sevkiyat Kartı"
  altında izlenir.
- **Ürün Geliştirme:** Her ürün; ürün ağacı (BOM benzeri bileşen/reçete listesi),
  versiyon geçmişi, kalite kontrol kriterleri ve Ar-Ge notları ile tanımlanabilir.
  Bir ürünün eski versiyonu asla silinmez, yeni versiyon olarak zincirlenir.
- **Çoklu depo / çoklu ülke stok:** Aynı ürün, farklı ülkelerdeki depolarda farklı
  birim ve para biriminde tutulabilir; konsolide stok raporu tüm depoları ortak bir
  birime (örn. kg) çevirerek gösterir.

## 10. YAPAY ZEKA GELİŞTİRME DİSİPLİNİ (KENDİ KENDİNİ DENETLEME)
- Yapay zeka her istekte önce bu dosyayı okur; hangi bölümle ilgili olduğunu belirtir
  ve kodu o bölüme göre yazar.
- Her yeni özellik şunlar olmadan TAMAMLANMIŞ sayılmaz: menü kayıt defteri kaydı +
  çeviri anahtarları + izin tanımı + feature flag + en az bir test senaryosu.
- Kullanıcı talebi anayasayla çelişirse yapay zeka sessizce uymaz; çelişkiyi
  açıklar, anayasaya uygun bir alternatif sunar.
- **Küçük adım ilkesi:** Yapay zeka, tek seferde tüm modülleri (muhasebe + stok +
  gümrük + ürün geliştirme) aynı anda kodlamaya çalışmaz. Her oturumda tek bir modül
  veya tek bir ekran tamamlanır, doğrulanır, sonra bir sonrakine geçilir. Bu kural,
  "çok uzun tek istek → hatalı/çirkin arayüz" sorununu kalıcı olarak ortadan kaldırır.
- "Hızlı geçici çözüm" (quick hack) üretmek yasaktır; her teslim production
  kalitesindedir.