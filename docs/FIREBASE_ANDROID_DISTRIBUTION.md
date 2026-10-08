# Firebase App Distribution ile Android cihaz testi

Bu belge, gerçek Android cihazlara test sürümü göndermek için Firebase App
Distribution kullanımını anlatır. Bu akış TestFlight'a benzer: belirlenen
testçilere e-posta daveti gider, onlar da yayımlanan sürümü indirir ve sonraki
sürümlerde güncelleme bildirimi alır.

## 0. Önemli: Android uygulama kimliğini kesinleştir

Google Play'e ilk yüklenen paketin application ID'si sonradan değiştirilemez.
Bu projede şu an örnek Flutter değeri bulunmaktadır:

```text
com.example.backstreet_pilates
```

Firebase'e veya Google Play'e kayıt yapmadan önce benzersiz, nihai bir kimlik
seçilmelidir. iOS bundle identifier ile tutarlı öneri:

```text
com.muticansel.backstreetpilates
```

Bu değişiklik `android/app/build.gradle.kts` içindeki hem `namespace` hem de
`applicationId` alanına uygulanır. Kotlin `MainActivity` dosya yolu ve package
satırı da aynı kimliğe taşınmalıdır. Bu adım tamamlanmadan Firebase Android
uygulaması oluşturulmamalıdır.

## 1. Firebase Console'da Android uygulamasını kaydet

1. Mevcut Backstreet Pilates Firebase projesini aç. Yoksa Firebase Console'da
   proje oluştur.
2. **Project overview → Add app → Android** seç.
3. Android package name alanına, 0. adımda kesinleştirdiğin application ID'yi
   harf harf aynı gir.
4. App nickname olarak `Backstreet Pilates Android` kullanılabilir.
5. Gerekirse SHA-1 daha sonra eklenebilir; Firebase App Distribution için
   ilk aşamada zorunlu değildir. Google Sign-In gibi Android OAuth özellikleri
   eklenirse gerekir.
6. Firebase'in verdiği `google-services.json` dosyasını indir ve şu konuma koy:

```text
android/app/google-services.json
```

Bu dosya build makinesinde bulunmalı, ancak rastgele paylaşılmamalıdır. CI
kullanılırsa güvenli secret/file yöntemiyle build anında yerleştirilir.

## 2. Android Firebase Gradle yapılandırmasını tamamla

Bu projede `firebase_core` ve `firebase_messaging` Flutter bağımlılıkları
mevcut, ancak Android Google Services Gradle eklentisi ayrıca eklenmelidir.

`android/settings.gradle.kts` içindeki `plugins` bloğuna ekle:

```kotlin
id("com.google.gms.google-services") version "4.5.0" apply false
```

`android/app/build.gradle.kts` içindeki `plugins` bloğuna ekle:

```kotlin
id("com.google.gms.google-services")
```

Ardından build doğrulaması yap:

```bash
flutter clean
flutter pub get
flutter build apk --debug
```

`Firebase.initializeApp()` uygulamada zaten çağrılıyor. Bu nedenle
`google-services.json` ve Gradle eklentisi doğru olduğunda Android Firebase
başlatma işlemi otomatik tamamlanır.

## 3. Release imzalama anahtarı oluştur

Gerçek testçi dağıtımında debug anahtarı yerine kalıcı bir upload key kullan.
Parolaları sohbete veya Git'e ekleme.

```bash
keytool -genkeypair -v \
  -keystore ~/backstreet-pilates-upload.keystore \
  -alias backstreet-pilates \
  -keyalg RSA -keysize 2048 -validity 10000
```

macOS terminali `Unable to locate a Java Runtime` hatası verirse, Android
Studio'nun gömülü Java aracını doğrudan kullan:

```bash
"/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/keytool" \
  -genkeypair -v \
  -keystore ~/backstreet-pilates-upload.keystore \
  -alias backstreet-pilates \
  -keyalg RSA -keysize 2048 -validity 10000
```

Ardından yerel olarak `android/key.properties` oluştur:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=backstreet-pilates
storeFile=/absolute/path/to/backstreet-pilates-upload.keystore
```

`key.properties` ve `.keystore` dosyaları Git'e eklenmez. Release signing
config'i `android/app/build.gradle.kts` içinde bu dosyadan okunacak şekilde
ayarlanmalıdır. Google Play'e geçildiğinde bu anahtar, Play App Signing upload
key'i olarak kullanılır.

## 4. Test APK'sı üret

Firebase App Distribution ile ilk gerçek cihaz testi için APK en pratik
formattır. Her test sürümünde `pubspec.yaml` içindeki build numarasını artır:

```yaml
version: 0.1.0+7
```

Ardından release APK üret:

```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://vjzoquvdoyndflcjulun.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

Çıktı:

```text
build/app/outputs/flutter-apk/app-release.apk
```

Publishable key mobil istemcide kullanılabilir; service-role/secret anahtarlar
asla APK'ya, Dart define'a veya Git'e eklenmez.

## 5. Firebase App Distribution ile testçi dağıtımı

1. Firebase Console'da doğru Android uygulamasını seç.
2. Sol menüden **Release & Monitor → App Distribution** bölümünü aç.
3. İlk kullanımda **Get started** seç.
4. `app-release.apk` dosyasını yükle.
5. Release notes ekle. Örnek: `Bireysel ders kaydı, dashboard yenileme ve UI düzeltmeleri.`
6. **Testers & Groups** bölümünde testçilerin Google hesaplarına ait e-posta
   adreslerini ekle veya `Android QA` adlı bir grup oluştur.
7. Bu grubu release'e ekleyip dağıtımı tamamla.
8. Firebase'in davet e-postasını testçilere gönder. Testçi Google hesabıyla
   daveti kabul eder, cihazında indirme akışını tamamlar ve uygulamayı açar.

Her yeni APK yüklemesinde aynı testçi grubunu seç. Testçiler yeni sürümün
hazır olduğuna dair bildirim/e-posta alır.

## 6. Gerçek cihaz test kontrol listesi

- Uygulama açılıyor ve Supabase'e bağlanıyor mu?
- Giriş/kayıt, paketler, dersler ve admin ekranları çalışıyor mu?
- Android bildirim izni verildiğinde FCM token'ı `user_push_devices` tablosuna
  kaydoluyor mu?
- Arka plandayken yeni ders ve ödeme bildirimleri geliyor mu?
- Farklı Android sürümlerinde tema, klavye ve form alanları düzgün mü?

Push bildirimi testi için Firebase Android uygulamasının package name'i,
derlenen APK'nın application ID'siyle birebir aynı olmalıdır.

## 7. Sonraki aşama: Google Play Internal testing

Firebase App Distribution hızlı QA için uygundur. Play Store üzerinden,
TestFlight'a en yakın resmi beta akışı istenirse Android App Bundle üret:

```bash
flutter build appbundle --release \
  --dart-define=SUPABASE_URL=https://vjzoquvdoyndflcjulun.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

Çıktı `build/app/outputs/bundle/release/app-release.aab` olur. Bu dosya Google
Play Console → **Testing → Internal testing** kanalına yüklenir. Firebase App
Distribution ve Google Play Internal testing aynı amaç için iki alternatif
akıştır; ilk gerçek cihaz denemesinde Firebase APK dağıtımı daha hızlıdır.

## Resmi kaynaklar

- [Firebase App Distribution](https://firebase.google.com/docs/app-distribution)
- [Firebase ile Android dağıtımı](https://firebase.google.com/docs/app-distribution/android/distribute-gradle)
- [Google Play test kanalları](https://support.google.com/googleplay/android-developer/answer/9845334)
