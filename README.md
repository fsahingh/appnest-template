# appnest-template

appnest.us'ta yayınlanan Python web uygulamaları için şablon.

**Yığın:** FastAPI + Uvicorn, Jinja2 + HTMX, SQLite, Docker Compose, GitHub Actions ile otomatik deploy.

## Nasıl çalışır

```
tarayıcı ──https──> Cloudflare (Access: Google ile giriş) ──mTLS──> nginx (sunucu) ──> 127.0.0.1:<port> ──> Docker (uvicorn)
```

- Repo adı = uygulama adı = subdomain. `app1` reposu → `https://app1.appnest.us`
- **Tüm `*.appnest.us` uygulamaları Cloudflare Access arkasındadır.** Giriş yapmamış kimse uygulamaya ulaşamaz.
- nginx uygulamaları Cloudflare Origin sertifikasıyla sunar ve sadece Cloudflare'in
  *Authenticated Origin Pull* istemci sertifikasını gösteren bağlantıları kabul eder
  (sunucu IP'sine doğrudan gelen istekler 400 ile reddedilir, giriş atlanamaz).
- Giriş yapan kullanıcının e-postası uygulamaya `Cf-Access-Authenticated-User-Email` başlığıyla gelir.
- Her uygulamanın sunucuda kendi portu vardır (8001, 8002, ...). Port sadece sunucuya açıktır.
- `main` dalına push → GitHub Actions sunucuya SSH ile bağlanır →
  `cd /opt/apps/<app> && git pull && docker compose up -d --build`
- SQLite veritabanı `data` adlı Docker volume'unda durur, deploy'larda silinmez.

## Yeni uygulama

1. GitHub'da bu şablondan yeni repo oluştur: **Use this template → Create a new repository**.
   Repo adı küçük harf, rakam ve tire içermeli (subdomain olacak).
2. Repo → **Settings → Secrets and variables → Actions** → üç secret ekle:
   | Secret | Değer |
   |---|---|
   | `SSH_HOST` | `155.94.163.73` |
   | `SSH_USER` | `deploy` |
   | `SSH_KEY` | Sunucudaki `~/.ssh/gha_deploy` dosyasının içeriği (private key) |
3. Sunucuda (deploy kullanıcısıyla):
   ```bash
   new-app.sh <app-adi> <port>      # örnek: new-app.sh app1 8001
   ```
   Betik ekrana bir deploy key basar ve bekler. Onu repo → **Settings → Deploy keys → Add deploy key**
   bölümüne ekleyip (write access KAPALI) Enter'a bas. Gerisini betik yapar:
   kodu çeker, `.env` oluşturur, konteyneri başlatır ve nginx'i ayarlar. Sertifika gerekmez
   (Cloudflare wildcard origin sertifikası `/etc/ssl/cloudflare/` altında hazır).
4. Bundan sonra her `git push` (main) otomatik deploy olur.

Kullanılan portları görmek için sunucuda: `grep -h APP_PORT /opt/apps/*/.env`

## Yerelde çalıştırma

```bash
python -m venv .venv && source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```
→ http://127.0.0.1:8000

## Dosyalar

| Dosya | Görevi |
|---|---|
| `app/main.py` | FastAPI uygulaması (örnek: SQLite'ta tutulan HTMX sayaç) |
| `app/templates/` | Jinja2 şablonları, `_` ile başlayanlar HTMX parçaları |
| `Dockerfile` | Python 3.12 imajı, root olmayan kullanıcı, healthcheck |
| `docker-compose.yml` | Port `127.0.0.1:${APP_PORT}`, `data` volume'u |
| `.github/workflows/deploy.yml` | main'e push'ta sunucuda deploy |
| `deploy/new-app.sh` | Sunucuda yeni uygulama kurulumu |
| `dashboard/index.html` | apps.appnest.us paneli (uygulama kartları, Sign out). Kurulum/güncelleme: `deploy/setup-dashboard.sh` |
| `landing/index.html` | appnest.us ana sayfası (Sign in butonu). Sunucuda `/var/www/appnest/` altına kopyalanır |

## Yeni oturum için notlar (KUT'tan öğrenilenler)

- **Kullanılan portlar:** `kut` → 8001. Yeni uygulamaya sıradaki boş portu ver (önce sunucuda `grep -h APP_PORT /opt/apps/*/.env`).
- **Panel kartı:** Yeni uygulama yayına çıkınca `dashboard/index.html` içindeki uygulama listesine kart ekle. İkon için uygulamanın kendi `/static/icons/icon-192.png` dosyasını kullan. Sunucuda `deploy/setup-dashboard.sh` ile güncellenir; bu repo push'ta otomatik yayına çıkmaz (Actions'taki "Deploy failed" normal).
- **Herkese açık sayfalar:** Giriş istemeyen bir yol gerekirse (paylaşım linki gibi), Cloudflare Access'te o yollar için ayrı bir *bypass* uygulaması aç (KUT'ta `KUT public links`: `/g`, `/api/view`, `/play`, `/api/play`, `/host`, `/api/host`, `/static`). Statik dosyalar bypass'ta olursa ikonlar da başka sayfalarda kullanılabilir.
- **Fontlar:** Google Fonts yerine `app/static/fonts` altında kendi sunucumuzdan ver.
- **iPhone ana ekran uygulaması:** `manifest.webmanifest`, `apple-touch-icon` ve kökte `/favicon.ico` + `/apple-touch-icon.png` yolları. Ana ekrandan açılınca tarayıcı olmadığı için aşağı çekip yenileme ve kenardan geri kaydırma uygulamada yazılmalı (KUT `app.js` → `homeScreenGestures`).
- **Çalışma şekli:** Türkçe, adım adım. Sunucuda büyük değişiklikten önce sor. Yeni tasarımlarda önce görsel çalışma göster, onaydan sonra uygula.
