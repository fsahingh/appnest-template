# Çalışma kuralları (Fatih)

Bu repo appnest.us'ta yayınlanan uygulamalardan biri (appnest-template, KUT, sharex). Kurallar üçünde de aynı.

## İletişim
- Türkçe yaz, adım adım anlat.
- Uygulamaların arayüz dili İngilizce kalır.
- Şifre, anahtar ve token'ları sohbete yazdırma. Cloudflare API'si ortamın ağ proxy'si üzerinden çalışır (token proxy tarafından eklenir).

## Onay ve değişiklik akışı
- Planı onaylamadan uygulamaya geçme.
- Tasarımda beklenti yüksek: yeni ekranları önce görsel çalışma (ekran görüntüleri) olarak göster, onaydan sonra uygula.
- Sunucuda büyük bir değişiklik yapmadan önce mutlaka sor. Cloudflare ayarları da buna dahil.
- Onaylanan değişikliklerde PR'ı sen aç ve sen merge et:
  1. Değişikliği hazırla, PR aç, ekran görüntüleriyle anlat.
  2. Fatih telefondan "onaylıyorum" yazar.
  3. PR'ı sen merge edersin. `main`'e merge olunca GitHub Actions değişikliği sunucuya kurar (appnest-template'te deploy işi atlanır).
  4. Kurulumun (Actions "Deploy" işinin) bitip bitmediğini kontrol edip haber ver. Hata olursa nedenini ve çözümünü anlat.
- Sunucuda komut çalıştırma erişimin yok; sunucuda yapılacak işler için komutu ver, Fatih çalıştırır.

## Genel kurallar
- Sitenin hiçbir yerinde Cloudflare'in kendi ekranları görünmemeli; hatalar appnest temasında bir sayfaya düşmeli.
- sharex'te trip ve club parası asla karışmaz.
