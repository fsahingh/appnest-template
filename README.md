# appnest-template

appnest.us'ta yayınlanan Python web uygulamaları için şablon.

**Yığın:** FastAPI + Uvicorn, Jinja2 + HTMX, SQLite, Docker Compose, GitHub Actions ile otomatik deploy.

## Nasıl çalışır

```
tarayıcı ──https──> nginx (sunucu) ──> 127.0.0.1:<port> ──> Docker konteyneri (uvicorn)
```

- Repo adı = uygulama adı = subdomain. `app1` reposu → `https://app1.appnest.us`
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
   kodu çeker, `.env` oluşturur, konteyneri başlatır, nginx'i ayarlar ve HTTPS sertifikası alır.
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
| `deploy/nginx.conf.example` | Betiğin oluşturduğu nginx ayarının örneği |
| `landing/index.html` | appnest.us ana sayfası ("under construction"). Sunucuda `/var/www/appnest/` altına kopyalanır |
