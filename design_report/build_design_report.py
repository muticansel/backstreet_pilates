from __future__ import annotations

import shutil
import tempfile
import zipfile
import re
from pathlib import Path


REFERENCE = Path(
    "/Users/mutic/.codex/plugins/cache/openai-curated-remote/openai-templates/0.1.1/"
    "skills/artifact-template-design-report/assets/reference.docx"
)
OUTPUT = Path(__file__).with_name("backstreet_pilates_design_review.docx")


REPLACEMENTS = {
    "Report title": "Backstreet Pilates Tasarım Değerlendirmesi",
    "Short subtitle describing the report up to two lines of text": (
        "Kaynak kodu ve mevcut sayfa inceleme notlarına dayalı ürün arayüzü değerlendirmesi"
    ),
    "Prepared by [Author]": "Hazırlayan Codex",
    "[Month YYYY]": "Ekim 2026",
    "Contents": "İçindekiler",
    "Executive summary": "Yönetici özeti",
    "At a glance": "Kısa bakış",
    "Introduction": "Kapsam",
    "Key findings": "Ana bulgular",
    "Context and conditions": "Mevcut temel",
    "Patterns in the evidence": "Desenler",
    "Implications": "Etkiler",
    "Recommendations": "Öneriler",
    "Conclusion": "Sonuç",
    "Appendix": "Ek",
    "Notes": "İnceleme notları",
    "Source placeholders": "İncelenen kaynaklar",
    "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.": (
        "Uygulamanın temel görsel yönü tutarlı: krem zemin, adaçayı yeşili ve editoryal başlıklar Pilates bağlamına uygun, sakin bir karakter kuruyor. Buna karşın üye ve yönetici akışları büyüdükçe bilgi önceliği, etiketleme ve durum hiyerarşisi aynı netlikle taşınmıyor."
    ),
    "Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.": (
        "Öncelik, yeni bir görsel dil eklemek değil; mevcut dili görev odaklı hale getirmek olmalı. İlk yatırım: alt gezinme adlarını netleştirmek, kart yoğunluğunu azaltmak ve bekleyen ya da kritik işlemleri her rolde daha görünür kılmak."
    ),
    "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt.": (
        "Alt navigasyondaki “Explore” ve “My plan” etiketleri, ekranların gerçek içeriğiyle “Paketler” ve “Derslerim” kadar doğrudan eşleşmiyor."
    ),
    "Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.": (
        "Ana sayfa aynı anda paket, ilerleme, paket keşfi ve geçmiş pratik kartlarını öne çıkarıyor; ilk bakışta tek bir sonraki adım belirgin değil."
    ),
    "Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.": (
        "İnceleme belgeleri birçok yüzeyde önizleme veya henüz uygulanmamış veri katmanını işaret ediyor; gerçek veri, boş ve hata durumları tasarımın birinci sınıf parçaları olmalı."
    ),
    "Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo.": (
        "Bu değerlendirme Flutter kaynakları, tema tanımları, dashboard ve kimlik doğrulama yerleşimleri ile mevcut sayfa inceleme notları üzerinden yapıldı. Canlı kullanıcı testi ya da üretim analitiği kullanılmadığı için bulgular arayüz ve bilgi mimarisi varsayımlarıdır."
    ),
    "Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt.": (
        "Öneriler önce üye deneyimini, ardından yoğun operasyon ekranlarını ele alır. Amaç marka hissini korurken üyeyi bir sonraki işe, yöneticiyi ise açık operasyona daha az düşünerek ulaştırmaktır."
    ),
    "Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam quaerat voluptatem.": (
        "Tasarım sistemi iyi bir başlangıç veriyor: geniş boşluk, yuvarlatılmış alanlar, belirgin form alanları ve yeşil birincil eylem tutarlı. Sorun, ürün yüzeyleri çoğaldığında bu sakin estetiğin görev önemini yeterince ayırmaması."
    ),
    "Ut enim ad minima veniam, quis nostrum exercitationem ullam corporis suscipit laboriosam, nisi ut aliquid ex ea commodi consequatur.": (
        "Tema yalnızca birkaç çekirdek rengi ve temel bileşeni merkezileştiriyor. Dashboard, admin, onay ve takvim gibi karmaşık yüzeyler için durum renkleri, kart rolleri, boş durumlar ve rozet kuralları görünür bir bileşen sözleşmesine henüz dönüşmemiş."
    ),
    "Quis autem vel eum iure reprehenderit qui in ea voluptate velit esse quam nihil molestiae consequatur, vel illum qui dolorem eum fugiat.": (
        "Üye ana sayfası ilham verici içerikle işlem içeriğini aynı seviyede sunuyor. Yönetici tarafta da dört sekme ve rozetler önemli iş sinyalleri taşıyor; ancak acil iş, bilgi amaçlı özet ve keşif arasında görsel ayrım daha keskin olabilir."
    ),
    "Key takeaway. At vero eos et accusamus et iusto odio dignissimos ducimus qui blanditiis praesentium voluptatum deleniti atque corrupti.": (
        "Ana çıkarım. Marka dili korunmalı; fakat her ekranda önce kullanıcının bugün yapması gereken tek işi, sonra destekleyici bilgiyi göstermelidir."
    ),
    "Et harum quidem rerum facilis est et expedita distinctio. Nam libero tempore, cum soluta nobis est eligendi optio cumque nihil impedit.": (
        "Bilgi hiyerarşisi iyileşirse üyeler paket, ders ve özel ders akışlarında daha az yön arar; yöneticiler ise onay, katılım ve ödeme kuyruğunu daha çabuk tarar. Bu değişiklikler yeni özelliklerden önce mevcut akışların anlaşılabilirliğini güçlendirir."
    ),
    "Theme": "Tema",
    "Observation": "Gözlem",
    "Implication": "Etkisi",
    "Lorem": "Gezinme",
    "Dolor sit amet": "“Explore” ve “My plan” içerikle bire bir eşleşmiyor",
    "Consectetur adipiscing": "Hedef ekrana gitme niyeti zayıflıyor",
    "Ipsum": "Öncelik",
    "Sed do eiusmod": "Ana sayfada eşit ağırlıklı çok sayıda kart var",
    "Tempor incididunt": "Bir sonraki adım belirsizleşiyor",
    "Dolor": "Durumlar",
    "Ut labore et dolore": "Önizleme, boş, hata ve bekleyen durumlar dağıtık",
    "Magna aliqua": "Güven ve taranabilirlik düşebilir",
    "Temporibus autem quibusdam et aut officiis debitis aut rerum necessitatibus saepe eveniet ut et voluptates repudiandae sint et molestiae non recusandae.": (
        "Aşağıdaki sıra, düşük riskli tasarım sistemi düzeltmeleriyle başlayıp ekran bazlı iyileştirmelere ilerler. Her adımı gerçek cihazda, küçük ekran ve Türkçe metin uzunluklarıyla doğrulayın."
    ),
    "Clarify the objective. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.": (
        "1. Gezinmeyi içerikle eşleştirin. Üye navigasyonunu “Ana Sayfa”, “Paketler”, “Derslerim”, “Planım” gibi doğrudan adlarla yeniden test edin. Bir hedef yalnızca gelecekteki bir kavramsa, onu aktif navigasyon yerine ilgili karttan başlatın."
    ),
    "Sequence the work. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.": (
        "2. Dashboardu görev sırasına göre kurun. En üstte yaklaşan ders veya özel ders çağrısı; ikinci sırada paket hakkı; ilerleme ve editoryal içerik daha aşağıda yer alsın. Veri yokken aynı konumda açık bir boş durum ve tek bir eylem gösterin."
    ),
    "Review the outcome. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.": (
        "3. Durum sistemini belgeleyin. Başarılı, uyarı, bekleyen, reddedilmiş, devre dışı ve hata durumları için renk, ikon, metin ve erişilebilirlik kuralları tanımlayın. Admin rozetleri sadece sayı değil, etki düzeyini de taşısın."
    ),
    "Itaque earum rerum hic tenetur a sapiente delectus, ut aut reiciendis voluptatibus maiores alias consequatur aut perferendis doloribus asperiores repellat.": (
        "Backstreet Pilates görsel olarak karakterli ve tutarlı bir başlangıca sahip. En güçlü iyileştirme alanı, estetik katmanını büyütmek değil; aynı sistemi gerçek görevler, durumlar ve veri belirsizliği çevresinde daha disiplinli kullanmaktır."
    ),
    "Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.": (
        "İlk tasarım turu üyelerin ana sayfa ve ders akışıyla sınırlanmalı; bunu admin Today ekranı izlemelidir. Böylece ortak durum ve rozet ilkeleri uygulamanın en görünür iki bağlamında test edilir."
    ),
    "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Integer nec odio. Praesent libero. Sed cursus ante dapibus diam.": (
        "Kanıt sınırı: Bu rapor kaynak ve doküman incelemesidir; ekran görüntüsü tabanlı görsel test, kullanıcı araştırması veya erişilebilirlik denetimi değildir. Bulgular uygulama yayımlanmadan önce cihaz üzerinde doğrulanmalıdır."
    ),
    "Suspendisse potenti. Nunc feugiat mi a tellus consequat imperdiet. Vestibulum sapien. Proin quam. Etiam ultrices.": (
        "İzlenecek ölçütler: ders veya paket hedefini bulma süresi, ana görevden geri dönüş, bekleyen işlem çözüm süresi, boş durumdan eyleme geçiş ve Türkçe metinde taşma/okunabilirlik."
    ),
    "[Author or organization]. [Source title]. [Publisher], [Year].": "Backstreet Pilates. README.md ve docs/BLUEPRINT.md. Yerel proje kaynakları, Ekim 2026.",
    "[Author or organization]. [Report or article title]. [Month Year].": "Backstreet Pilates. docs/PROGRESS.md ve docs/reviews/04-member-dashboard.md. Yerel proje kaynakları, Ekim 2026.",
    "[Dataset owner]. [Dataset name and version]. Accessed [Month Year].": "Backstreet Pilates. lib/theme/app_theme.dart, dashboard_page.dart ve auth_layout.dart. Yerel proje kaynakları, Ekim 2026.",
    "[Interviewee or team]. [Interview or workshop notes]. [Date].": "Backstreet Pilates. docs/reviews/05-admin-dashboard.md, 09-member-classes.md ve 15-private-lesson-calendar.md. Yerel proje kaynakları, Ekim 2026.",
    "Template note. Replace bracketed placeholders, update the table of contents, and confirm page references before publishing.": (
        "Not: İçindekiler alanı, belge Microsoft Word ile açıldığında otomatik güncellenmek üzere ayarlanmıştır."
    ),
}

# A few template sentences are split across styled runs. These are replaced as
# individual text nodes after the longer paragraph substitutions above.
RUN_REPLACEMENTS = {
    "Key takeaway. ": "Ana çıkarım. ",
    "At vero eos et accusamus et iusto odio dignissimos ducimus qui blanditiis praesentium voluptatum deleniti atque corrupti.": (
        "Marka dili korunmalı; fakat her ekranda önce kullanıcının bugün yapması gereken tek işi, sonra destekleyici bilgiyi göstermelidir."
    ),
    "Clarify the objective. ": "1. Gezinmeyi içerikle eşleştirin. ",
    "Sequence the work. ": "2. Dashboardu görev sırasına göre kurun. ",
    "Review the outcome. ": "3. Durum sistemini belgeleyin. ",
    "Template note. ": "Not: ",
    "Replace bracketed placeholders, update the table of contents, and confirm page references before publishing.": (
        "İçindekiler alanı, belge Microsoft Word ile açıldığında otomatik güncellenmek üzere ayarlanmıştır."
    ),
}


def replace_xml_text(xml: bytes) -> bytes:
    text = xml.decode("utf-8")
    for old, new in sorted(REPLACEMENTS.items(), key=lambda item: len(item[0]), reverse=True):
        text = text.replace(old, new)
    for old, new in sorted(RUN_REPLACEMENTS.items(), key=lambda item: len(item[0]), reverse=True):
        text = text.replace(old, new)
    recommendation_bodies = {
        "1. Gezinmeyi içerikle eşleştirin. ": (
            "Üye navigasyonunu Ana Sayfa, Paketler, Derslerim ve Planım gibi doğrudan adlarla yeniden test edin. Bir hedef yalnızca gelecekteki bir kavramsa, onu aktif navigasyon yerine ilgili karttan başlatın."
        ),
        "2. Dashboardu görev sırasına göre kurun. ": (
            "En üstte yaklaşan ders veya özel ders çağrısı; ikinci sırada paket hakkı; ilerleme ve editoryal içerik daha aşağıda yer alsın. Veri yokken aynı konumda açık bir boş durum ve tek bir eylem gösterin."
        ),
        "3. Durum sistemini belgeleyin. ": (
            "Başarılı, uyarı, bekleyen, reddedilmiş, devre dışı ve hata durumları için renk, ikon, metin ve erişilebilirlik kuralları tanımlayın. Admin rozetleri sadece sayı değil, etki düzeyini de taşısın."
        ),
    }
    for label, body in recommendation_bodies.items():
        pattern = rf"(<w:t[^>]*>{re.escape(label)}</w:t>.*?<w:t[^>]*>).*?(</w:t>)"
        text, count = re.subn(
            pattern, r"\1" + body + r"\2", text, count=1, flags=re.DOTALL
        )
        if count != 1:
            raise RuntimeError(f"Recommendation run not found: {label}")
    text = text.replace(
        "Gezinme ipsum dolor sit amet, consectetur adipiscing elit. Integer nec odio. Praesent libero. Sed cursus ante dapibus diam.",
        "Kanıt sınırı: Bu rapor kaynak ve doküman incelemesidir; ekran görüntüsü tabanlı görsel test, kullanıcı araştırması veya erişilebilirlik denetimi değildir. Bulgular uygulama yayımlanmadan önce cihaz üzerinde doğrulanmalıdır.",
    )
    return text.encode("utf-8")


def enable_update_fields(xml: bytes) -> bytes:
    text = xml.decode("utf-8")
    marker = "</w:settings>"
    if "<w:updateFields" not in text:
        text = text.replace(marker, '<w:updateFields w:val="true"/>' + marker)
    return text.encode("utf-8")


def main() -> None:
    with tempfile.TemporaryDirectory() as temp_dir:
        temp_output = Path(temp_dir) / OUTPUT.name
        with zipfile.ZipFile(REFERENCE) as source, zipfile.ZipFile(
            temp_output, "w", zipfile.ZIP_DEFLATED
        ) as target:
            for item in source.infolist():
                data = source.read(item.filename)
                if item.filename == "word/document.xml":
                    data = replace_xml_text(data)
                elif item.filename == "word/settings.xml":
                    data = enable_update_fields(data)
                target.writestr(item, data)
        shutil.copy2(temp_output, OUTPUT)


if __name__ == "__main__":
    main()
