# Canlı Supabase operasyon rehberi

`vjzoquvdoyndflcjulun` Seoul projesi yalnızca development içindir; gerçek üye, ödeme veya cihaz verisi içermez.

## Ortamlar ve dağıtım

| Ortam | Supabase projesi | Veri | Kaynak dal |
|---|---|---|---|
| Local/development | Mevcut Seoul projesi veya yerel CLI | Sentetik | Özellik dalı |
| Production | Yeni AB projesi | Gerçek | `main` |

Yalnız production için yeni, boş bir AB projesi oluştur. Production, development projesinin klonu veya aynı Project Ref’i olamaz. Production projesinde Auth redirect URL, e-posta şablonları, iOS/Android bundle ayarları ve Storage politikaları doğrulanır.

GitHub repository settings altında yalnız `production` Environment’ını oluştur. Required reviewer ve yalnız `main` branch kuralı tanımla. GitHub Environment’a şu secret’ları ekle:

| Secret | Kullanım |
|---|---|
| `SUPABASE_ACCESS_TOKEN`, `SUPABASE_PROJECT_REF` | Edge Function dağıtımı |
| `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY` | Ortam bazlı Flutter build yapılandırması |
| `PRODUCTION_DATABASE_URL` | IPv4 uyumlu Session pooler üzerinden migration ve SQL health check bağlantısı |

`FIREBASE_SERVICE_ACCOUNT_JSON` ve `NOTIFICATION_WEBHOOK_SECRET` GitHub
Environment secret’ı değildir. Bunları production Supabase projesinde **Edge
Functions → Secrets** altında ekle. `send-push-notification` bu değerleri
yalnız çalışma anında okur; hiçbir değer Git’e veya Flutter’a girmez.

`validate.yml` her PR’da Flutter ve migration ad kontrollerini çalıştırır. `deploy-production.yml`, production migration’larını GitHub Actions’ın IPv4 ağıyla uyumlu Session pooler bağlantısı üzerinden ve Edge Function’ları production Environment onayından sonra uygular. Development projesine otomatik dağıtım yapılmaz; geliştirme ve sentetik veri işlemleri yerel olarak veya hesap sahibinin açık onayıyla yürütülür.

`20260927000400_activate_incek_8_2_4_offer.sql` yalnız development seed
verisindeki `demo-8-2-4` paketi ile İncek teklifini etkinleştirir. Production
boş başladığı ve sentetik paket/fiyat taşınmayacağı için workflow bu sürümü SQL
çalıştırmadan production migration geçmişinde uygulanmış olarak işaretler.
Bu bilinçli istisna yalnız bu sürüm içindir. Gerçek production şube, paket ve
teklifleri daha sonra ayrı, ileri yönlü bir migration ile eklenmelidir.

İlk dağıtımdan önce SQL Editor ile development’a uygulanmış migration’ları envanterle: `supabase migration list` ile yerel dosyaları karşılaştır, gereken kayıtlarda `supabase migration repair` kullan ve sonra production şema değişikliklerini yalnız CLI/CI ile yap. Production migration geri alınmaz; düzeltme her zaman yeni, ileri yönlü migration olarak eklenir.

## Otomatik saklama politikası

`20261015000100_operational_data_retention.sql` 30 günü aşmış operasyon geçmişini kullanıcı/ay toplamına dönüştürür:

- Grup dersleri, no-show ve onaylı özel ders sayıları `member_activity_monthly_summaries` tablosuna atomik olarak eklenir.
- Başarılı teslim edilmiş bildirimler, tamamlanmış grup dersi ham kayıtları ve sonuçlanmış özel ders istekleri uygun olduğunda silinir.
- Ödeme, paket talebi, üyelik, profil, denetim verisi ve başarısız/bekleyen bildirimler otomatik silinmez.

Migration’dan sonra production’da Supabase Dashboard’dan `pg_cron` açılır ve `supabase/ops/enable_operational_retention_cron.sql` bir kez çalıştırılır. İş UTC 00:15’te (Türkiye’de 03:15) çalışır. `retention-health.yml`, son başarılı çalışmanın 26 saatten eski olması halinde başarısız olur; GitHub failure bildirimleri en az iki operasyon sorumlusuna yönlendirilir.

## Supabase yedekleri ve geri yükleme

Production projesinde Supabase’in dahilî veritabanı yedeklerinin etkin ve plan
tarafından destekleniyor olduğunu doğrula. Harici AWS/S3 yedekleme bu aşamada
kullanılmıyor; AWS hesabı, S3 bucket, KMS anahtarı ve ilgili GitHub secret’ları
gerekmiyor.

Bu projede henüz Supabase Storage kullanılmıyor. İleride profil fotoğrafı,
video veya başka Storage nesneleri eklenecekse, Supabase veritabanı
yedeklerinden bağımsız bir Storage yedekleme/geri-yükleme kararı canlıya
çıkmadan önce yeniden alınmalıdır.

Her ay boş, geçici bir AB kurtarma projesinde en yeni kullanılabilir Supabase
veritabanı yedeğiyle geri yükleme tatbikatı yap; RLS, member/admin girişi,
paket/ders/private lesson akışlarını ve push webhook’unu doğrula. Tarih, geri
yükleme süresi ve eksikleri incident kaydına yaz.

## Olay anı prosedürü

1. Incident sorumlusu uygulamayı bakım moduna alır ve yazma işlemlerini durdurur.
2. En son güvenli Supabase yedeği önce yeni kurtarma projesinde doğrulanır.
3. Production restore veya proje geçişi yapılır; gerekirse yeni URL/key içeren acil mobil sürüm yayınlanır.
4. Auth, RLS, RPC, Edge Function secret’ları, cron, webhook ve Storage policy’leri tekrar doğrulanır.
5. Kullanıcılara veri etkisi bildirilir; root-cause ve önleyici aksiyon kayda alınır.

PITR başlangıç kapsamı dışındadır. Günlük yedekle karşılanamayan ödeme veya yoklama kaybı riski oluşursa, PITR için ayrı maliyet/onay kararı alınır.
