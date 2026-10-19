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
| `deploy/backup-apps.sh` | Her gece tüm uygulamaların SQLite veritabanını `~/backups/<app>/` altına yedekler (30 gün) |

## Yeni oturum için notlar (KUT'tan öğrenilenler)

- **Kullanılan portlar:** `kut` → 8001. Yeni uygulamaya sıradaki boş portu ver (önce sunucuda `grep -h APP_PORT /opt/apps/*/.env`).
- **Panel kartı:** Yeni uygulama yayına çıkınca `dashboard/index.html` içindeki uygulama listesine kart ekle. İkon için uygulamanın kendi `/static/icons/icon-192.png` dosyasını kullan. Sunucuda `deploy/setup-dashboard.sh` ile güncellenir; bu repo push'ta otomatik yayına çıkmaz (Deploy işi şablonun kendisinde atlanır).
- **Herkese açık sayfalar:** Giriş istemeyen bir yol gerekirse (paylaşım linki gibi), Cloudflare Access'te o yollar için ayrı bir *bypass* uygulaması aç (KUT'ta `KUT public links`: `/g`, `/api/view`, `/play`, `/api/play`, `/host`, `/api/host`, `/static`). Statik dosyalar bypass'ta olursa ikonlar da başka sayfalarda kullanılabilir.
- **Fontlar:** Google Fonts yerine `app/static/fonts` altında kendi sunucumuzdan ver.
- **iPhone ana ekran uygulaması:** `manifest.webmanifest`, `apple-touch-icon` ve kökte `/favicon.ico` + `/apple-touch-icon.png` yolları. Ana ekrandan açılınca tarayıcı olmadığı için aşağı çekip yenileme ve kenardan geri kaydırma uygulamada yazılmalı (KUT `app.js` → `homeScreenGestures`).
- **Çalışma şekli:** Türkçe, adım adım. Sunucuda büyük değişiklikten önce sor. Yeni tasarımlarda önce görsel çalışma göster, onaydan sonra uygula.
- **Kullanılan portlar (güncel):** `kut` → 8001, `sharex` → 8002.
- **Kendi girişini yapan uygulamalar (sharex):** sharex'in ana Access kuralı Bypass; giriş `/auth/google` ve `/auth/email` yollarından, uygulamanın kendi oturumuyla. Paneldeki kartı `https://sharex.appnest.us/auth/google` adresine gider: panelden gelen kişi zaten Google ile girmiş olduğu için sharex'e sormadan girer.
- **Cloudflare ekranı görünmemeli (genel kural):** Kullanıcı sitenin hiçbir yerinde Cloudflare'in kendi sayfalarını görmemeli; hatalar appnest temasında bir sayfaya düşmeli. Tek giriş yöntemi Google olduğu için Access uygulamalarında `auto_redirect_to_identity` açık olmalı (seçim ekranı atlanır). Sign out, `/cdn-cgi/access/logout`'u arka planda `fetch` ile çağırıp `https://appnest.us/`'a gitmeli (panel, KUT ve sharex böyle).
- **Önbellek:** Cloudflare `.js`/`.css` dosyalarını kenar sunucularında ve tarayıcıda (4 saat) saklar. Adında sürüm olmayan uygulama kodu için sunucu `Cache-Control: no-cache` göndermeli, service worker da `fetch(..., {cache: "no-cache"})` kullanmalı (sharex `app/main.py` ve `sw.js`).

## Yedekleme

- Sunucuda her gece `deploy/backup-apps.sh` çalışır (deploy kullanıcısının crontab'ı). Her uygulamanın veritabanı `~/backups/<app>/<app>-YYYY-MM-DD.db.gz` olarak saklanır, 30 günden eskiler silinir, kayıt `~/backups/backup.log`'da.
- Datawagon'da sunucunun otomatik yedeği (snapshot) açık; günlük yedekler de sunucunun içinde olduğu için ona dahil.
- Geri yükleme (örnek sharex): `gunzip -k ~/backups/sharex/sharex-TARIH.db.gz`, sonra `cd /opt/apps/sharex && docker compose stop web && docker compose cp ~/backups/sharex/sharex-TARIH.db web:/app/data/sharex.db && docker compose start web` (WAL dosyaları varsa önce silinmeli; emin değilsen sor).

## İleride karar verilecekler

- **Yetkiye göre yönlendiren panel:** appnest.us → Sign in → panel, kişinin e-postasına göre: birden çok uygulama → sadece yetkili kartlar; tek uygulama → doğrudan o uygulama; hiçbiri → "No access yet" sayfası. Panel küçük bir FastAPI uygulaması olur, uygulamalar sunucu içinden gizli anahtarla "bu e-posta yetkili mi" cevabı verir, Cloudflare'de panelin kuralı "Google ile giren herkes" olur.
- **"No access yet" sayfası ve "Ask for access" formu:** Tasarım hazır (`no-access-page` dalında `landing/no-access.html`). Düğme e-posta yerine bir form olacak; istek sharex'teki gibi bir onay listesine düşecek. Yukarıdaki panelle birlikte yapılacak.
- **Sunucu dışı yedek (Cloudflare R2):** Datawagon'un kendisinde sorun olursa diye; şifreli, ücretsiz katman yeterli.
