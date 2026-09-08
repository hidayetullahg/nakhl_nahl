# PHASE_06 — PRODUCT VARIANTS AND UOM

Amaç: Kalite/boyut/nem kombinasyonlarını ayrı SKU, stokta tek temel birim, gösterimde parametrik birim/para birimi yapmak.

Oku/tara: product/item/stock modelleri, repository, stok ekranı, Money çekirdeği ve migration'lar.

Uygula: Attribute axis/value tabloları parametrik; SKU deterministik ve otomatik; g/kg/ton dönüşümü exact Decimal; tenant display currencies N adet; kur tarihi/kaynağı görünür.

Test: variant ayrışması, deterministik SKU, kayıpsız UOM, rounding ve multi-currency toplam.

Kapı: `.agent/scripts/verify.sh`; ürün mevcut davranışını kanıtlamadan değiştirme; raporla ve dur.
