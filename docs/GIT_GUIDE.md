# Git ve GitHub adımları

Komutları proje klasöründe çalıştır:

```sh
cd /Users/mutic/Desktop/personal/backstreet_pilates
```

## 1. Yerel repo oluştur

```sh
git init -b main
```

Bu adım tamamlandı. `.git` klasörü sürüm geçmişini tutar; GitHub'a henüz dosya göndermez.

## 2. Commit kimliğini tanımla

Aşağıdaki örnek değerleri kendi bilgilerinle değiştir. `--global` kullanılmadığı için
ayarlar yalnızca bu repo için geçerlidir.

```sh
git config user.name "AD SOYAD"
git config user.email "GITHUB E-POSTASI"
```

## 3. Dosyaları hazırla ve ilk kaydı oluştur

```sh
git add .
git diff --cached --stat
git commit -m "Initial Backstreet Pilates app"
git status
```

`add` dosyaları sonraki kayda hazırlar; `commit` yerel geçmişe bir kayıt ekler.
`.gitignore`, derleme çıktıları ve yerel IDE ayarlarını dışarıda tutar.
Flutter uygulamasının bağımlılık sürümlerini sabitleyen `pubspec.lock` repoya dahil edilir.

## 4. GitHub reposunu bağla

GitHub hesabında `backstreet_pilates` adında boş bir repo oluştur.
Görünürlüğünü seç; README, .gitignore ve lisans ekleme seçeneklerini boş bırak,
çünkü yerel projemizde dosyalar zaten var.

Repo adresini kendi adresinle değiştir:

```sh
git remote add origin https://github.com/muticansel/backstreet_pilates.git
git remote -v
git push -u origin main
```

Bu adım GitHub kimlik doğrulaması gerektirir. Şifre veya erişim tokenını sohbet içine yazma.
`push` commitleri GitHub'a gönderir; `-u` sonraki gönderimler için hedef dalı kaydeder.

## Sonraki değişiklikler

```sh
git status
git diff
git add DEGISTIRDIGIN_DOSYA
git commit -m "Yaptığın değişikliğin kısa açıklaması"
git push
```

Sayfa incelemelerine uygun şekilde küçük, anlaşılır commitler oluştur.
