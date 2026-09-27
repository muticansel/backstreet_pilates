# Backstreet Pilates — veritabanı taslağı

Durum: Genel model inceleme taslağı. Temel katalog/profil/rol migration dosyası hazır; canlı veritabanına henüz uygulanmadı. Kurulum için SUPABASE_SETUP.md dosyasına bak.
Teknik öneri: Supabase üzerinde PostgreSQL; kullanıcı kimliği için Supabase Auth.

## Kesinleşen işletme kuralları

- İlk aşamada yalnızca fiziksel stüdyo dersleri var.
- Oran ve İncek iki ayrı şube; fiyatları farklı olabilir.
- Satın alınan paket yalnızca satın alındığı şubede kullanılabilir.
- Paketler çoğunlukla 8, 12, 20 veya 24 ders hakkı içerir.
- Toplam ders hakkı, haftalık ders sayısı ve geçerlilik süresi ayrı alanlardır.
- Örneğin 8 ders: haftada 2 ders / 4 hafta veya haftada 1 ders / 8 hafta.
- İlk sürümde gün ve saatleri sabit paketler satılacak.
- Paket süresi otomatik olarak ilk planlanan ders tarihinde başlar; admin başlangıcı değiştirebilir.
- İlk derse gelinmemesi başlangıcı ertelemez; mevcut no-show kuralı uygulanır.
- Gelecekte ders seçimi veya değişikliği sağlayan esnek paketler de satılabilecek.
- Rezervasyonlu derse gelinmezse ders hakkı kullanılmış sayılır.
- İleride iptal veya katılamama hakkı içeren paketler satılabilecek.
- Adminler iki şubeyi de yönetebilir ve birleşik/şube bazlı raporları görebilir.
- Ücretli videolar ileride ayrı dijital ürün ve erişim kayıtlarıyla eklenebilir.

## Henüz kararlaştırılmayan kurallar

1. Gelecekteki esnek paketlerde kullanıcı derslerini baştan serbestçe mi seçecek,
   yoksa sabit programındaki dersleri belirli koşullarla mı değiştirecek?
2. Haftalık limit takvim haftası mı, paket başlangıcından itibaren yedi günlük
   dönemler mi? Rezervasyon yapılmayan haftadaki hak devredilecek mi?
3. İlk paketlerde erken iptal de hak kaybı mı olacak? Geç iptal eşiği nedir?
4. Gelecekte katılamama hakkı: ders hakkı iadesi, telafi dersi, süre uzatma
   veya paket dondurma anlamlarından hangilerini içerecek?
5. Stüdyo tarafından iptal edilen ders için hak iadesi ve süre uzatma kuralı nedir?

Bu maddeler varsayılan bir iş kuralına dönüştürülmeden önce netleştirilmeli.
Özellikle rezervasyon yapılmaması ile rezervasyonlu derse gelinmemesi farklıdır.

## Önerilen tablolar

| Tablo | Amaç ve temel alanlar |
|---|---|
| profiles | Auth kullanıcı kimliği, ad, iletişim bilgileri |
| user_roles | Kullanıcı/admin rolü; yalnızca yetkili sunucu işlemiyle değişir |
| branches | Şube kimliği, ad, saat dilimi, aktiflik |
| membership_plans | Paket adı, toplam ders, haftalık ders sayısı, süre, scheduling_mode (fixed/flexible) |
| policy_versions | İptal süresi, hak korunan iptal sayısı, mazeret/no-show hakkı ve sonuçları; sürümlü koşullar |
| branch_offers | Şube, paket, koşul sürümü, fiyat, para birimi, satışa açıklık |
| user_memberships | Üye, şube, satış teklifi, satın alma anındaki hak/süre/rezervasyon tipi/koşul kopyası, satış tutarı, başlangıç ve bitiş, durum |
| membership_schedule_slots | Üyeliğin haftanın günü ve yerel saat bazında sabit programı, saat dilimi, geçerlilik aralığı |
| class_sessions | Şube, eğitmen, başlangıç/bitiş, kontenjan, durum |
| bookings | Üye, ders, kullanılan üyelik, durum, rezervasyon/iptal zamanı |
| credit_transactions | Üyelik, rezervasyon, artı/eksi ders hakkı, neden, benzersiz işlem anahtarı |
| policy_usages | İptal/mazeret hakkının hangi rezervasyonda kullanıldığı; tekrar kullanım engeli |
| payments | Satın alma, tutar, para birimi, yöntem, durum, ödeme zamanı, sağlayıcı referansı |
| refunds | Ödeme, iade tutarı, durum, zaman, benzersiz sağlayıcı referansı |
| audit_events | Admin değişiklikleri, yapan kişi, zaman, neden |
| video_series | Dijital seri kataloğu, erişim süresi ve yayın durumu |
| series_videos | Serinin sıralı video bilgileri; oynatma bağlantısı içermez |
| video_series_access | Kullanıcıya satın alma veya manuel işlemle tanınan süreli erişim |
| video_progress | Kullanıcının kendi video izleme ilerlemesi |

Tabloların nihai alanları ve ilişkileri SQL incelemesinde tek tek ele alınacak.
Tek veritabanı kullanılacak; şube ayrımı ilişkiler ve erişim kurallarıyla sağlanacak.

## Paket örnekleri

| Paket | Toplam hak | Haftalık ders | Süre | Şube |
|---|---:|---:|---:|---|
| 8 ders / yoğun | 8 | 2 | 4 hafta | Oran |
| 8 ders / standart | 8 | 1 | 8 hafta | Oran |
| 8 ders / yoğun | 8 | 2 | 4 hafta | İncek |

Fiyatlar henüz belirlenmedi. Aynı paketin iki şubedeki satış fiyatı bağımsızdır.
Satın alma tutarı ile başarılı tahsilat toplamı ayrı kavramlardır.
Para tutarları kuruş gibi en küçük para birimiyle tam sayı olarak saklanır.
Tarihler saat dilimini koruyan zaman damgalarıyla tutulur; takvim ve raporlar
şubenin Europe/Istanbul saat dilimine göre değerlendirilir.

## Paket başlangıcı ve admin düzeltmesi

Başlangıcın kaynağı ilk planlanan ders tarihidir; satın alma veya ilk fiili
katılım tarihi değildir. İlk ders gelecekteyse program önceden hazırlanabilir,
ancak geçerlilik süresi o dersin tarihinde başlar.

Önerilen alanlar: `first_scheduled_session_id`, `original_start_date`,
`effective_start_date`, `start_source` (first_lesson/admin_override) ve
satın alma koşullarındaki süre üzerinden hesaplanan `end_date_exclusive`.
Tarih bazlı süre şubenin saat diliminde değerlendirilir: başlangıç günü dahil,
başlangıç + paket hafta sayısı × 7 gün olan bitiş sınırı hariç önerilir.
Bu sınır hesaplama yaklaşımı taslak önerisidir.

Admin düzeltmesi için önerilen davranış:

- Admin yeni başlangıcı ve değişiklik nedenini girer. Bitiş, satın alınan
  paketin süresine göre yeniden hesaplanır; toplam ders hakkı değişmez.
- Önceki/yeni başlangıç ve bitiş, değişikliği yapan admin, zaman ve neden
  `audit_events` içinde aynı işlemde kaydedilir.
- Rezervasyonlar sessizce taşınmaz. Yeni aralık dışında kalan gelecek dersler
  varsa adminin yeni programı belirlemesi ve kontenjanların doğrulanması gerekir.
- Tarih değişikliği ile gereken gelecek rezervasyon değişiklikleri birlikte
  onaylanır veya tümü geri alınır; kısmi program bırakılmaz.
- Katılınmış/no-show dersleri ve geçmiş hak hareketleri korunur. Yeni tarih
  aralığı bu geçmişle çelişiyorsa sıradan tarih düzeltmesi reddedilir; ayrı ve
  açık bir düzeltme işlemi gerekir. Eski haklar otomatik geri verilmez.
- Admin başlangıcı değiştirdikten sonra otomatik hesaplama bunu ezmez.
  Sonraki ders iptalleri başlangıcı kendiliğinden ileri taşımaz; stüdyo iptalinin
  süreye etkisi ayrıca kararlaştırılacak politikaya göre ele alınır.

## Sabit program ve gelecekte esnek paketler

`fixed` ilk sürümün rezervasyon tipidir. Örneğin Oran şubesinde 8 derslik,
4 haftalık bir paket için salı 18.00 ve perşembe 18.00 programı tanımlanır.
Öneri: üyelik aktive edilirken bu programdan tarihli 8 rezervasyon oluşturulur.
Haftalık program tanımı ile gerçekleşecek tarihli ders kayıtları ayrı tutulur.

- Her rezervasyon gerçek bir `class_sessions` kaydına bağlanır; yalnızca haftanın
  günü ve saatini kaydetmek kontenjan garantisi sağlamaz.
- Aktivasyon öncesinde tüm tarihler, paket süresi, ders sayısı ve kontenjan kontrol edilir.
  Tatil, eksik ders veya dolu kontenjan varsa eksik program sessizce onaylanmaz;
  admin uygun programı düzeltir. Tatil/telafi koşulları ayrıca kararlaştırılacak.
- Program ve rezervasyonların oluşturulması atomik ve tekrar çağrılmaya dayanıklı olur.
  Aynı aktivasyon isteği ikinci bir rezervasyon dizisi oluşturmaz.
- Sabit pakette kullanıcı kendiliğinden gün/saat değiştiremez. Yetkili adminin
  düzeltmeleri eski geçmişi korur ve işlem kaydına alınır.
- Gelecekte `flexible` paket tipi aynı tarihli ders ve rezervasyon tablolarını kullanır.
  Şube kısıtı devam eder; ders değiştirme koşulları ayrıca sürümlenir.
- Ders değişikliği desteklendiğinde yeni kontenjanı alma ve eski rezervasyonu bırakma
  tek işlem olur. Yeni derste yer yoksa eski rezervasyon korunur.
- Esnek rezervasyon tipi tek başına ücretsiz iptal veya mazeret hakkı vermez;
  bu haklar paket koşullarında ayrı tanımlanır.

Tüm sabit rezervasyonlar başta oluşturulduğunda boşta ders bakiyesi sıfır olabilir;
bu, derslerin tamamına katılındığı anlamına gelmez. Kullanıcıya ve admin raporuna
**planlanmış gelecek ders**, **katılınan ders**, **gelinmeyen ders** ve **rezervasyona
ayrılmamış hak** ayrı gösterilir. No-show, planlanmış dersin durumu değiştirilerek
kaydedilir; tekrar hak düşülmez.

## Rezervasyon ve ders hakkı için önerilen işlem modeli

1. Sunucu, üyeliğin aktifliğini, dersin üyelik süresi içinde olmasını, aynı
   şubeyi, haftalık sınırı, kalan hakkı ve kontenjanı birlikte kontrol eder.
2. Kontenjan ve üyelik kaydı eşzamanlı taleplere karşı korunarak rezervasyon
   oluşturulur; ders hakkı bir kez düşülür. İşlem bütünüyle başarılı olur veya geri alınır.
3. Katılım veya no-show kaydedildiğinde ikinci kez hak düşülmez.
4. Koşullara uygun iptalde ters kayıtla hak geri verilir. İlk kayıt silinmez.
5. Gelecekte mazeret hakkı varsa bu hakkın tüketimi ile ders iadesi aynı işlemde yapılır.
6. Aynı istek tekrar geldiğinde benzersiz işlem anahtarı sayesinde ikinci rezervasyon,
   ikinci düşüm veya ikinci iade oluşturulmaz.

Aynı üyenin aynı derste birden fazla aktif rezervasyonu olamaz. İptal edilmiş
rezervasyondan sonra yeniden kayıt senaryosu ayrıca desteklenir. Rezervasyon,
üyelik ve dersin aynı şubede olması veritabanı seviyesinde de korunur.
Paket koşulları veya fiyatları değiştiğinde önceki satışların koşulları değişmez.
Kalan hak ile henüz kullanılabilir hak ayrılır: süresi dolmuş paket, kayıtlı
bakiyesi pozitif olsa da yeni rezervasyona izin vermez.

## Yetkiler ve ödemeler

- Kullanıcı yalnızca kendi kişisel verisini, üyeliğini, ödemelerini ve rezervasyonlarını görür.
- Ders takvimi gibi ortak veriler kişisel üye bilgileri olmadan okunabilir.
- Kullanıcı rolünü, paket bakiyesini, fiyatı veya ödeme durumunu doğrudan değiştiremez.
- Admin rolü sunucu/veritabanı tarafında doğrulanır; iki şubeyi kapsar.
- Supabase RLS ve sunucu işlemleri birlikte tasarlanır; ayrı kullanıcılarla erişim testleri yapılır.
- Yönetici/service-role anahtarları Flutter uygulamasına eklenmez.
- Kart bilgileri saklanmaz. Çevrimiçi ödeme, sağlayıcının doğrulanmış sunucu bildirimiyle işlenir.
- Ödeme bildirimleri tekrar geldiğinde yeniden paket veya tahsilat oluşturulmaz.
- Manuel tahsilat desteklenirse admin, ödeme yöntemi ve işlem kaydı tutulur.

## Raporlar

- Şube/ay/paket bazında satış adedi.
- Başarılı tahsilatlar, başarılı iadeler ve iade sonrası tahsilat toplamı.
- Aktif üyelikler, ders hakları, doluluk, katılım ve no-show sayıları.
- Satış tarihi ve tahsilat tarihi raporlarda ayrı filtrelenir.
- İadeler gerçekleştiği ayda gösterilir; satışla bağlantısı korunur.
- Kâr hesabı kapsam dışı: gider verileri olmadan kâr raporu üretilmez.

## Uygulama sırası

1. Açık işletme kurallarını yanıtla ve bu taslağı incele.
2. Şubeler, paketler ve tekliflerle başla; SQL migration ve örnek verileri incele.
3. Kimlik, roller, erişim politikaları ve üyelik modelini kur.
4. Rezervasyon, hak hareketleri ve eşzamanlılık testlerini ekle.
5. Ödemeleri ve raporları ayrı bir aşamada bağla.

Bu aşamada Flutter sayfaları ve demo giriş davranışı değişmedi.

## Video library foundation

Ücretli video serileri için ilk veri ve RLS taslağı
`docs/VIDEO_LIBRARY.md` içinde, incelenecek migration ise
`supabase/migrations/20260927000200_video_library.sql` içindedir. Video dosyası
veya kalıcı oynatma URL'si public şemada tutulmaz; erişimi geçerli kullanıcıya
sunucu tarafında kısa ömürlü oynatma bağlantısı verilir. Bu migration henüz canlı
Supabase projesinde çalıştırılmadı.

Video satın alma, oynatma ve güvenlik mimarisi karar kaydı
`docs/VIDEO_LIBRARY.md` dosyasında tutulur. Planlanan ayrım şudur: Flutter
yalnızca store satın alma arayüzünü ve oynatıcıyı içerir; RevenueCat doğrulanmış
store olaylarını Edge Function'a gönderir; Edge Function erişimi ve kısa ömürlü
oynatma bağlantısını yönetir. Kalıcı ödeme veya oynatma sırları istemciye
eklenmez.

## Nakit paket satın alma akışı

Kullanıcının nakit ödeme talebi, admin onayı ve üyelik oluşturma taslağı
`docs/CASH_PURCHASE_FLOW.md` dosyasında; incelenecek SQL ise
`supabase/migrations/20260927000300_cash_purchase_requests.sql` dosyasındadır.
Her satış teklifi önceden tek bir şubeye bağlıdır; kullanıcı ayrı bir şube
seçmez. İstemci yalnızca bu hazır teklife ait nakit talebini oluşturabilir.
Talebin onaylanması ve üyeliğin oluşturulması, admin denetimi yapan ayrı sunucu
fonksiyonudur. Bu migration henüz canlı Supabase projesinde çalıştırılmadı.
