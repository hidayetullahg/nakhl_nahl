# PHASE_09 — AI PROVIDERS

Amaç: Gemini/OpenAI/Anthropic/Azure/self-hosted sağlayıcılarını sunucu tarafı güvenli gateway ile bağlamak.

Oku/tara: `lib/features/ai/`, provider migration'ları, Edge Function/secret altyapısı ve audit log.

Kural: API key browser/local storage/SharedPreferences/client payload içinde tutulmaz; istemci yalnızca maskeli son dört haneyi görür. Çağrılar server-side function üzerinden geçer. Bütçe limiti ve audit zorunludur. AI çıktı `PROPOSAL`, insan onayı olmadan kalıcı kayıt değildir.

Test: client secret absence, masked retrieval, budget rejection, approval enforcement.

Kapı: secret scan, `.agent/scripts/verify.sh`; anahtar istemez/çıktılamaz; raporla ve dur.
