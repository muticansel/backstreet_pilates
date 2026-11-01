# Supabase canlıya çıkış, ortam ayrımı ve yedekleme planı

## Amaç

Mevcut Seoul Supabase projesini yalnızca development olarak bırakıp, AB
bölgesinde ondan tamamen ayrı bir production ortamı kurmak.
Dağıtımlar GitHub Actions ile yapılır; production değişiklikleri manuel onaydan
geçer. Kabul edilen veri kaybı hedefi en fazla 24 saattir.

## Ortamlar ve yayın akışı

| Ortam | Proje | Veri | Dağıtım |
|---|---|---|---|
| Development | Mevcut Seoul projesi veya yerel CLI | Sentetik | Özellik dalı |
| Production | Yeni AB projesi | Gerçek kullanıcı verisi | `main` + manuel onay |

- Flutter derlemeleri her ortamın `SUPABASE_URL` ve
  `SUPABASE_PUBLISHABLE_KEY` değerlerini yalnız CI secret’larından alır.
- Service-role key, veritabanı şifresi ve Firebase servis hesabı Flutter
  uygulamasına girmez.
- SQL Editor ile geçmişte uygulanmış migration’lar production kurulmadan önce
  `supabase migration list` ve gerekirse `supabase migration repair` ile
  yerel migration geçmişiyle eşitlenir.
- Production şema değişiklikleri yalnızca ileri yönlü migration ile yapılır;
  uygulanmış migration düzenlenmez veya geri alınmaz.

## Veri saklama ve temizlik

- 30 günü aşan ham operasyon verisi, silinmeden önce kullanıcı-ay toplamına
  dönüştürülür:
  - tamamlanan grup ders sayısı,
  - no-show sayısı,
  - onaylanmış özel ders sayısı.
- `member_activity_monthly_summaries` yalnız sayısal özetleri saklar.
- Finansal veriler, paket talep ve üyelik kayıtları, profil/hesap kayıtları,
  denetim kayıtları ve başarısız/bekleyen bildirim olayları otomatik silinmez.
- `pg_cron` ile çalışan retention işi her gece UTC 00:15’te çalışır; son
  başarılı çalışmayı GitHub Actions health-check denetler.

## Yedekleme ve kurtarma

- Production Supabase ücretli planda günlük yedekle çalışır; bu 24 saatlik RPO
  için birincil korumadır.
- Her ay boş geçici bir AB kurtarma projesine geri yükleme tatbikatı yapılır;
  RLS, giriş, paket, ders, private lesson ve push webhook akışları doğrulanır.
- Harici AWS/S3 yedekleme kullanılmaz. Projede henüz Storage nesnesi yoktur;
  Storage kullanımı eklendiğinde dosya yedekleme ve geri yükleme planı ayrıca
  onaylanır.

## GitHub Actions ve secret’lar

- `validate.yml`: PR’larda Flutter format/analyze/test ve migration isim
  doğrulaması.
- `deploy-production.yml`: production Environment onayından sonra migration ve
  Edge Function dağıtımı.
- `retention-health.yml`: retention işinin 26 saat içinde başarılı çalışıp
  çalışmadığını denetler.
- `production` GitHub Environment için required reviewer kullanılır. Secret
  değerleri Git’e, loglara veya Flutter build dosyalarına yazılmaz.

## Uygulama sırası

1. AB’de boş `backstreet-pilates-production` projesini oluştur.
2. GitHub’da `production` Environment’ını, gerekli secret’ları ve production
   onay kuralını tanımla.
3. Production migration geçmişini uzlaştır, migration’ları uygula ve SQL
   testlerini çalıştır.
4. Production’da Auth, RLS, Edge Function, webhook, push ve gerçek cihaz
   testlerini canlı kullanıcı almadan önce tamamla.
5. Supabase’in production yedekleme kapsamını doğrula ve bir kurtarma tatbikatı
   yapmadan production’a veri taşıma veya canlı kullanıcı
   alma.
6. Production dağıtımını `main` üzerinden, onay kapısından sonra çalıştır.
7. İlk hafta Supabase yedekleme durumu, retention, başarısız RPC/push ve RLS redlerini günlük
   kontrol et.

## Dış kaynakta yapılacaklar

Bu repo dosyaları altyapı otomasyonunu hazırlar ancak aşağıdaki kaynaklar
otomatik oluşturulmaz: AB Supabase production projesi, GitHub
Environment secret’ları, `pg_cron` etkinleştirmesi ve ilk restore tatbikatı.
Adım adım kurulum için
[LIVE_OPERATIONS.md](../LIVE_OPERATIONS.md) belgesini kullan.
