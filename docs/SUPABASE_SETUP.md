# Supabase geliştirme kurulumu

## Durum

- `supabase_flutter` 2.17.2 kuruldu; sürümler pubspec.lock içinde kayıtlı.
- Temel SQL migration, geliştirme verisi ve erişim kontrolü testi hazır.
- Flutter analizi, 3 widget testi ve Supabase bağımlılıklarıyla iOS simülatör derlemesi başarılı.
- Bulut projesi kullanıcı tarafından oluşturuldu: https://vjzoquvdoyndflcjulun.supabase.co.
- Paylaşılan ekranda bölge Seoul (ap-northeast-2), durum Healthy.
- İlk migration, seed ve erişim testi kullanıcı tarafından SQL Editor'da başarıyla uygulandı.
- Flutter giriş/kayıt ekranları halen demo. Bu aşamada ağ bağlantısı veya gerçek hesap oluşturma açılmadı.
- Docker ve Supabase CLI kurulu değil; bulut SQL Editor yolunda gerekli değiller.

SQL Editor: https://supabase.com/dashboard/project/vjzoquvdoyndflcjulun/sql/new

## 1. Hesap ve proje (tamamlanan hesap oluşturma adımları)

1. https://supabase.com/dashboard/sign-up adresinde hesap oluştur ve giriş yap.
2. Geliştirme için `backstreet-pilates-dev` adlı proje oluştur. Ücretsiz plan seçeneği
   hesabında uygunsa geliştirme için onu kullan; ücretli planı ayrıca değerlendirelim.
3. Proje bölgesini oluşturma sırasında birlikte seçelim. Gerçek müşteri verisi bu ortama girilmez.
4. Veritabanı şifresini kendin belirle ve güvenli bir yerde sakla; sohbete/Git'e ekleme.
5. Proje hazır olduğunda Project URL ve publishable key bağlantı için kullanılacak.
   Secret/service-role anahtarı veya veritabanı şifresi Flutter'a konulmaz.

## 2. İlk SQL kurulumu ve inceleme sırası

Yalnızca bu uygulamaya ayrılmış boş geliştirme projesinde SQL Editor kullan:

1. `supabase/migrations/20260927000100_initial_catalog.sql` dosyasını incele ve bir kez çalıştır.
2. `supabase/seed.sql` dosyasını incele ve çalıştır.
3. `supabase/tests/access_checks.sql` dosyasını çalıştır; hata olmadan tamamlanmalı.

İlk dosya transaction içinde uygulanır. Başarıyla uygulandıktan sonra tekrar çalıştırma.
Seed tekrarlanabilir; mevcut fiyatları veya kayıtları üzerine yazmaz.
Test dosyası geçici Auth kullanıcılarıyla erişimi sınar, sonunda ROLLBACK yapar.
Test hata verirse açık transaction için ROLLBACK çalıştır; sebebi gidermeden ilerleme.
Testler boş geliştirme projesi ve değiştirilmemiş seed içindir.

SQL Editor üzerinden uygulama Supabase CLI migration geçmişini otomatik güncellemez.
Hangi dosyanın hangi projede uygulandığını PROGRESS.md içinde kaydet. CLI'ya geçerken
önce migration geçmişini bu durumla eşleştir; aynı SQL'i tekrar push etme.

## 3. Oluşturulan model

- `profiles`: kullanıcı kendi profilini, admin tüm profilleri okur; ad/telefon değiştirilebilir.
- `user_roles`: signup otomatik member rolü verir. Kullanıcı metadatası admin yetkisi vermez.
- `branches`: Oran ve İncek.
- `membership_plans`: toplam hak, haftalık ders, hafta süresi ve fixed/flexible tipi.
- `branch_offers`: şube/paket bazında kuruş cinsinden fiyat; satın alma kaydı değildir.

İlk admin, hesabı Auth üzerinden oluşturulduktan sonra yalnızca güvenilir sunucu/SQL Editor
üzerinden `user_roles` kaydı güncellenerek atanır. Kullanıcı UUID'si ve hesap sahibi
kontrol edilmeden rol verilmez. Uygulama admini bile istemciden rol atayamaz.

RLS her tabloda açık. Anonim istemcinin bu tablolara erişimi yok. Üyeler aktif kataloğu,
adminler iki şubedeki aktif/pasif kataloğu görür ve yönetir.

## 4. Örnek verilerin sınırları

5 paket varyantı ve iki şubede toplam 10 fiyat kaydı oluşturulur.
8 ders için hem haftada 1 / 8 hafta hem haftada 2 / 4 hafta örneği var.
12, 20, 24 ders örnekleri haftada 2 ders varsayımıyla yalnızca test amacıyla eklenir.
Tüm örnek paketler ve teklifler satışa kapalıdır; fiyatlar uydurmadır.
Rezervasyon, paket satın alma, para tahsilatı, iptal/mazeret koşulları bu migration'da yoktur.
Süre başlangıcı ve admin değişikliği, sonraki satın alınmış üyelik aşamasında uygulanacak.

## 5. Flutter bağlantısı — sonraki sayfa incelemesi

Paket kuruldu ancak `main.dart` içinde henüz Supabase.initialize çağrısı yok.
Hesap/proje hazır olunca, gerçek login/signup incelemesinde Project URL ve publishable
key `--dart-define` ile aktarılacak; oturum yönlendirmesi ve e-posta doğrulaması eklenecek.
Publishable key uygulamada görülebilir; veri güvenliğini RLS sağlar.

Resmi kaynaklar:
- https://supabase.com/docs/guides/getting-started/quickstarts/flutter
- https://supabase.com/docs/guides/auth/managing-user-data
- https://supabase.com/docs/guides/database/postgres/row-level-security
- https://supabase.com/docs/guides/deployment/database-migrations
