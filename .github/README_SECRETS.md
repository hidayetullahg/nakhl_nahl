# NAKHL&NAHL — GitHub Secrets Konfigürasyon Rehberi

## Gerekli Secrets

GitHub repository ayarlarında **Settings → Secrets and variables → Actions** bölümünden aşağıdaki secret'ları ekleyin.

### CI Workflow (ci.yml)

| Secret Adı | Açıklama | Zorunlu |
|---|---|---|
| `SUPABASE_URL` | Supabase proje URL'i (örn: `https://xxxxx.supabase.co`) | Sadece build için |
| `SUPABASE_ANON_KEY` | Supabase public/anon key (RLS korumalı, client-safe) | Sadece build için |

### Deploy Workflow (deploy.yml)

| Secret Adı | Açıklama | Zorunlu |
|---|---|---|
| `SUPABASE_ACCESS_TOKEN` | Supabase CLI erişim token'ı (Dashboard → Account → Access Tokens) | ✅ Evet |
| `SUPABASE_PROJECT_ID` | Supabase proje referans ID'si (Dashboard → Settings → General) | ✅ Evet |

### Environment-Specific Secrets (Önerilen)

Deploy workflow'da `environment` kullanıldığı için, GitHub'da **Environments** tanımlayabilirsiniz:

1. **Settings → Environments → New environment**
2. `staging` ve `production` adında iki environment oluşturun
3. Her environment için ayrı secret'lar tanımlayın
4. `production` environment'ına **Required reviewers** ekleyin

## Güvenlik Kuralları

> ⚠️ **ASLA** aşağıdakileri repository'ye commit etmeyin:
>
> - `service_role` key
> - JWT secret
> - Database connection string
> - `.env` dosyaları (`.gitignore`'da zaten engellidir)

> ℹ️ `SUPABASE_ANON_KEY` RLS koruması altında olduğu için client uygulamalarında kullanılabilir.
> Ancak yine de GitHub Secrets üzerinden yönetilmesi best practice'dir.

## Secret Ekleme Adımları

1. GitHub repository'nize gidin
2. **Settings** → **Secrets and variables** → **Actions**
3. **New repository secret** tıklayın
4. Secret adını ve değerini girin
5. **Add secret** ile kaydedin
