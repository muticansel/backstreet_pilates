# Bireysel ders ve kazanç kaydı

## Amaç

Yönetici, paketli grup derslerinden bağımsız verdiği bireysel dersleri üye
bazında kaydeder. Her kayıtta ders tutarı ve yöneticinin yüzde oranı girilir;
sistem kazancı otomatik hesaplar.

Örnek: `₺1.000` ders tutarı ve `%12,5` oran için kazanç `₺125` olur.

## Yönetici akışı

Admin dashboard içindeki **Private lessons / Bireysel dersler** kartı bireysel
ders ekranını açar.

1. **Record private lesson** seçilir.
2. Aktif üye seçilir.
3. Ders tarihi, ders tutarı ve yüzde oranı girilir.
4. Oran yalnızca `%10` ile `%100` arasındadır. Virgüllü oranlar (`12,5`) da
   kabul edilir.
5. Ekrandaki kazanç önizlemesi kayıt öncesi hesaplamayı gösterir.
6. Kayıt tamamlandığında geçmiş listesinde görünür; liste üye seçilerek
   filtrelenebilir.

Kaydedilmiş derslerde tutar, oran ve hesaplanmış kazanç birlikte gösterilir.

## Hesaplama ve doğrulama

Tutarlar veritabanında kuruş (`*_minor`) cinsinden saklanır. Oran yüzde puanın
yüzde biri olarak `rate_basis_points` alanında saklanır. Örneğin `%12,5`,
`1250` değeridir.

Kazanç veritabanında üretilen alan olarak hesaplanır:

```text
earning_minor = round(lesson_price_minor × rate_basis_points / 10_000)
```

Bu hesap istemcide yalnızca önizleme amaçlı tekrar edilir. Nihai değer
veritabanından gelir; istemcinin gönderdiği kazanç değeri yoktur.

`admin_record_individual_lesson` RPC'si şu kuralları uygular:

- çağrıyı yapan kullanıcı admin olmalıdır;
- ders tarihi gelecekte olamaz;
- ders tutarı pozitif olmalıdır;
- oran `%10–%100` aralığında olmalıdır;
- seçilen kullanıcı aktif profil olmalı ve admin olmamalıdır.

## Dashboard toplamı

Admin dashboard'daki **This month / Bu ay** tutarı şunların toplamıdır:

- ay içinde onaylanmış paket satışları;
- ders tarihi bu ay olan bireysel derslerin hesaplanmış kazancı.

Kart alt metni paket satışı ve bireysel ders adetlerini ayrı gösterir. Bireysel
dersin tamamı değil, yalnızca oranla hesaplanan kazanç toplama eklenir.

## Veritabanı kurulumu

Özellik, aşağıdaki migration ile kurulur:

```text
supabase/migrations/20261006000200_individual_lesson_income.sql
```

Supabase CLI kullanılmıyorsa, dosyanın tamamı Supabase SQL Editor'da bir kez
çalıştırılır. Migration şunları oluşturur:

- `public.individual_lesson_records` tablosu;
- üye ve tarih sorguları için indeksler;
- yalnızca adminlerin okuyabildiği RLS politikası;
- güvenli ekleme yapan `admin_record_individual_lesson` RPC'si.

Migration uygulanmadan yayınlanan istemci, dashboard metriğini ve bireysel
ders ekranını yükleyemez; bu nedenle mobil sürüm yayınından önce production
projesinde uygulandığı doğrulanmalıdır.

## Yaşam döngüsü notu

Kayıt dialog'u kapandıktan sonra Flutter'ın kapanış animasyonu biterken input
controller'ları kullanılmaya devam edebilir. Bu nedenle controller'lar dialog
sonucundan sonra kısa animasyon gecikmesiyle temizlenir. Ayrıca sayfa yenilemesi
`setState` içinde yalnızca eşzamanlı atama yapar; asenkron iş doğrudan
`setState` callback'ine konmaz.
