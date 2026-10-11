# NOVA Windows Cloud — Privacy Policy (Draft)

> **Owner action required before publication:** This is an implementation-based draft, not a published policy and not legal advice. Replace every bracketed field, confirm the intended audience and operating countries, review the current behavior, then publish this text at a stable HTTPS URL and enter that URL in the applicable AdMob settings. No public policy URL is configured by this repository.

- **Service:** NOVA Windows Cloud for Android
- **Developer / data controller:** `[DEVELOPER OR LEGAL ENTITY NAME]`
- **Privacy contact:** `[PRIVACY CONTACT EMAIL]`
- **Effective date:** `[PUBLICATION DATE]`
- **Intended audience / minimum age:** `[CONFIRM BEFORE PUBLICATION]`

## English

### 1. What the app does

NOVA Windows Cloud is an Android client that lets a user authorize a GitHub account, select or create a repository, manage GitHub Actions configuration, and request a Windows session. The Android app communicates with GitHub directly; the repository contains no NOVA-operated application server for account or session data.

### 2. Information handled by the app

- **GitHub account and repository information:** When you sign in, the app receives account details and reads repositories, workflow state, backup-release metadata, and GitHub Actions secret *names* needed to present the features you request. The app does not retrieve the values of existing GitHub Actions secrets.
- **Sign-in credentials:** GitHub access/refresh tokens, an optional GitHub App client secret, and temporary OAuth/PKCE state are stored in Android secure storage. They are used to communicate with GitHub and are removed on sign-out, except that the optional client secret is retained on the device by design.
- **Preferences and activity:** The selected repository, language preference, last interstitial-ad display time (used for the frequency cap), and a local activity history are stored on the device using app preferences. The activity history is limited to the most recent 100 entries and is intended to record operation types and safe metadata, not password or token values.
- **Windows and GitHub Actions secrets:** Values such as `ACCESS_PASSWORD`, `BACKUP_PASSWORD`, and an optional Tailscale key are sent over HTTPS to GitHub using the repository's public key and libsodium sealed-box encryption. `ACCESS_PASSWORD` may also remain temporarily in app memory so the session screen can display connection details; it is not written to app preferences. GitHub stores and uses the values as GitHub Actions secrets. NOVA's Android client has no NOVA-operated server receiving those secret values. GitHub Actions may process workflow inputs, logs, and session metadata under GitHub's terms and retention settings.
- **Session and backup information:** Depending on your choices, GitHub Actions may create a temporary Windows session and encrypted backup assets in your repository's GitHub Releases. The workflow uses AES-256-CBC with PBKDF2 for backup encryption. You control the repository, its releases, and the relevant GitHub secrets. Do not put passwords in public repositories or workflow logs.
- **Advertising:** The app integrates Google Mobile Ads (AdMob) and Google's User Messaging Platform (UMP). The release build uses the publisher's supplied AdMob identifiers; development builds use Google's official test identifiers. Depending on your region, consent choices, and Google's configuration, Google may process information such as advertising/device identifiers, IP address or IP-derived approximate location, ad interactions, and diagnostics to provide, measure, and protect advertising. Google's processing is governed by Google's privacy terms and the consent choices presented by UMP.
- **Optional connection providers:** If you enable browser access or RDP, GitHub Actions may use Cloudflare Tunnel and/or Tailscale. Those providers may receive connection and network metadata needed to deliver their services, under their own terms. Tailscale is optional; the app does not require it for browser access.

### 3. How information is used and shared

The app uses information to authenticate you, manage the GitHub repository and its Actions workflows, display session status, and—where permitted—request and show ads. GitHub receives the requests and secret values needed to perform the operations you initiate. Google receives advertising requests when ads are allowed by the consent state. Cloudflare and Tailscale are involved only when the corresponding connection method is configured and used. The developer does not sell account credentials or use them for unrelated advertising.

### 4. Storage, retention, and security

Credentials stored by the app remain on your device in Android secure storage. Preferences and activity history remain in the app's local storage until cleared or the app data is removed. GitHub controls the retention of repository data, Actions logs, secrets, and Releases assets; review your repository and GitHub account settings to manage them. Encrypted backups require the `BACKUP_PASSWORD` configured by you. Losing that password may make a backup unrecoverable. No security method is infallible, so protect your device and GitHub account and avoid sharing session links or passwords.

### 5. Your choices

You can sign out to remove the stored GitHub access and refresh tokens; the optional GitHub App client secret is retained unless you remove it separately or clear the app's data. You can revoke NOVA's authorization in GitHub, delete or change GitHub Actions secrets and Releases assets in your repository, and disable optional Tailscale/browser access in the workflow settings. Where UMP reports that a privacy-options entry point is required, use **Settings → Ad privacy choices** in the app to revisit Google's privacy options. Android settings can also be used to reset or uninstall the app.

### 6. Children, international use, and changes

The intended age group and child-directed status have not yet been confirmed by the app owner. **Do not publish this policy or activate production advertising until those settings are confirmed and the AdMob/UMP configuration is consistent with them.** GitHub, Google, Cloudflare, and Tailscale may process information in countries other than yours under their respective terms. The developer may update this policy when the app or its providers change; the published version should show its effective date.

### 7. Contact and privacy requests

For privacy questions or requests, contact `[PRIVACY CONTACT EMAIL]`. The developer identity, contact address, applicable rights process, and any legally required representative must be completed before publication.

---

## العربية

### سياسة الخصوصية — مسودة غير منشورة

**يجب على مالك التطبيق قبل النشر:** تعبئة جميع الحقول بين الأقواس، وتأكيد الفئة العمرية والدول المستهدفة، ومراجعة السلوك الفعلي، ثم نشر النص على رابط HTTPS ثابت وإدخال الرابط في إعدادات AdMob عند الحاجة. لا يوجد في هذا المستودع رابط سياسة خصوصية منشور أو مُتحقق منه.

- **التطبيق:** NOVA Windows Cloud لنظام Android
- **المطوّر / مسؤول معالجة البيانات:** `[اسم المطوّر أو الجهة القانونية]`
- **بريد الخصوصية:** `[بريد التواصل]`
- **تاريخ السريان:** `[تاريخ النشر]`
- **الفئة العمرية المقصودة:** `[يجب التأكيد قبل النشر]`

تطبيق NOVA عميل Android يتصل بـGitHub مباشرةً لتسجيل الدخول، وعرض المستودعات، وإدارة GitHub Actions، وطلب جلسة Windows. لا يتضمن المستودع خادماً تابعاً لـNOVA لمعالجة الحسابات أو الجلسات.

يعالج التطبيق معلومات حساب GitHub والمستودعات وحالة Workflows وأسماء أسرار GitHub Actions، ولا يقرأ قيم الأسرار الموجودة مسبقاً. تُحفظ رموز الوصول والتحديث وبيانات OAuth الاختيارية في التخزين الآمن على Android؛ وعند تسجيل الخروج تُحذف الرموز، بينما يبقى GitHub App Client Secret الاختياري محفوظاً محلياً إلى أن يُحذف أو تُمسح بيانات التطبيق. يُحفظ المستودع المحدد واللغة ووقت آخر إعلان بيني (لضبط الحدّ الزمني بين الإعلانات) وسجل نشاط محلي محدود بآخر 100 عملية. لا يُقصد أن يتضمن سجل النشاط كلمات المرور أو الرموز.

عند حفظ أسرار مثل `ACCESS_PASSWORD` و`BACKUP_PASSWORD` ومفتاح Tailscale الاختياري، يشفّرها التطبيق بمفتاح GitHub العام باستخدام sealed-box من libsodium ويرسلها عبر HTTPS إلى GitHub. قد تبقى `ACCESS_PASSWORD` مؤقتاً في ذاكرة التطبيق كي تعرض شاشة الجلسة معلومات الاتصال؛ ولا تُحفظ في تفضيلات التطبيق. يخزّن GitHub القيم ويستخدمها GitHub Actions؛ لا يستقبل خادم تابع لـNOVA هذه القيم. قد تعالج GitHub Actions مدخلات التشغيل والسجلات ومعلومات الجلسة وفق شروط GitHub وإعدادات الاحتفاظ لديه. قد تُحفظ النسخ الاحتياطية المشفرة ضمن GitHub Releases في مستودعك، ويستخدم Workflow تشفير AES-256-CBC مع PBKDF2. أنت تتحكم بالمستودع والأسرار وملفات Releases، وفقدان `BACKUP_PASSWORD` قد يمنع استعادة النسخة.

يتكامل التطبيق مع Google Mobile Ads (AdMob) وUMP. يستخدم إصدار الإنتاج معرّفات AdMob التي زوّد بها مالك التطبيق، بينما تستخدم نسخ التطوير معرّفات اختبار Google الرسمية. وفقاً للمنطقة وخيارات الموافقة وإعدادات Google، قد تعالج Google معرّفات الإعلانات أو الجهاز، وعنوان IP أو موقعاً تقريبياً مستنتجاً منه، وتفاعلات الإعلانات وبيانات التشخيص. تخضع هذه المعالجة لشروط Google وخيارات الموافقة التي يعرضها UMP.

عند اختيار الوصول عبر المتصفح أو RDP، قد يستخدم GitHub Actions خدمة Cloudflare Tunnel و/أو Tailscale، وقد تتلقى هذه الجهات بيانات الاتصال والشبكة اللازمة لتقديم الخدمة وفق شروطها. Tailscale اختياري. يمكنك تسجيل الخروج، وإلغاء تفويض NOVA من GitHub، وإدارة أسرار GitHub وملفات Releases من مستودعك، وإيقاف وسائل الوصول الاختيارية. إذا تطلب UMP رابطاً لخيارات الخصوصية، استخدم **الإعدادات ← خيارات خصوصية الإعلانات**.

لم يؤكد مالك التطبيق بعد الفئة العمرية أو ما إذا كان التطبيق موجهاً للأطفال. **يجب عدم نشر هذه السياسة أو تفعيل الإعلانات الإنتاجية قبل تأكيد ذلك ومطابقة إعدادات AdMob وUMP.** للتواصل: `[بريد التواصل]`. يجب تعبئة هوية المطوّر والبريد وإجراءات طلبات الخصوصية قبل النشر.
