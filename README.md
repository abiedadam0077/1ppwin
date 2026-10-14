# 1ppwin — Windows 11 Pro على GitHub Actions (مع حفظ البيانات) 💻

هاد الريبو فيه GitHub Action (`.github/workflows/windows11.yml`) كيشغّل **Windows 11 Pro حقيقي**
(عن طريق Docker [`dockur/windows`](https://github.com/dockur/windows) + KVM) على سيرفر ديال GitHub.

- كتشعلو من تاب **Actions** وقتما بغيتي.
- كيبقى خدام حتى **~5 ساعات و نص** (GitHub ما كيعطيش كثر من 6 ساعات للجوب، الوقت الباقي محجوز للحفظ).
- ملي كيسالي الوقت (ولا ملي تطفي Windows بيدك) كيطفا **بشكل نقي** و كيتحفظ **الديسك كامل**
  (الملفات، الخلفية، البرامج، الإعدادات… **كلشي**) كـ backup **مشفّر** فـ **Releases** ديال الريبو.
- المرة الجاية ملي تعاود تشعلو، كيرجع آخر backup → Windows كيبان **بحال ما خليتيه بالضبط**،
  ما كيتبدل والو: لا الخلفية لا الملفات لا الإعدادات.

---

## 1) الإعداد (مرة وحدة)

1. **Merge** هاد الكود لـ `main` (زر *Run workflow* ما كيبانش حتى يكون الملف فـ الـ branch الرئيسي).
2. سير لـ **Settings → Secrets and variables → Actions → New repository secret** وزيد هادو:

| Secret | شنو هو |
|---|---|
| `BACKUP_PASSWORD` | كلمة سر لتشفير الـ backup. **ما تنساهاش أبداً** — بلا بيها البيانات ما كترجعش. |
| `ACCESS_PASSWORD` | كلمة السر ديال الدخول للـ web viewer **و** ديال المستخدم فـ Windows. |
| `TAILSCALE_AUTHKEY` *(اختياري)* | إلا بغيتي تدخل بـ **RDP** (Remote Desktop) عبر [Tailscale](https://tailscale.com) — شوف القسم 4. |

> ⚠️ الريبو **public** → أي واحد يقدر يشوف الـ logs و Releases. داكشي علاش:
> - الـ backup **مشفّر بـ AES-256** بكلمة السر ديالك (`BACKUP_PASSWORD`)،
> - والـ web viewer **محمي بكلمة سر** (`ACCESS_PASSWORD`).
>
> ما تحطش كلمات السر فـ الكود، غير فـ Secrets.

## 2) التشغيل (كل مرة بغيتي تخدم)

1. **Actions → Windows 11 Pro → Run workflow**.
   - `hours`: شحال من ساعة بغيتي تخليه خدام (ماكس ~5.3).
   - `fresh_install`: خليه **مطفي** (إلا شعلتيه كيتجاهل الـ backup وكيدير Windows جديد نقي).
2. دخل للجوب اللي خدام → فـ أول الصفحة (Summary) ولا فـ الـ step **"Start web access"**
   غادي تلقى رابط بحال: `https://xxxx-xxxx.trycloudflare.com`
3. حلّو فـ المتصفح (حتى فـ الهاتف كيخدم) → كطلب منك:
   - user: `Docker`
   - password: `ACCESS_PASSWORD` ديالك
4. **أول مرة** كيتنصّب Windows أوتوماتيكيا (~20–40 دقيقة، غير تسنى). من بعد المرات كيقلع
   مباشرة من الـ backup فـ دقايق.

الرابط كيتعاود يطبع كل 10 دقايق فـ الـ step **"Windows is running"** مع الوقت الباقي.

## 3) الإطفاء والحفظ

- **الأحسن:** طفي Windows من **Start → Power → Shut down** → الجوب كيحس بيه وكيحفظ فـ الحين
  وما كتضيعش الدقايق الباقية.
- ولا خليه حتى يسالي الوقت → كيطفا بوحدو وكيحفظ.
- ❌ ما تديرش **Cancel** للجوب إلا للضرورة القصوى (ممكن الحفظ ما يكملش وتضيع تغييرات هاد الجلسة).

الـ backup كيتقسم لأجزاء (< 2GB) ويترفع لـ Release سميتو `win11-backup-<التاريخ>`.
كيتخلاو آخر **2** backups (القديم كيتمسح أوتوماتيكيا). الـ restore ما كياخد إلا backup كامل (فيه ملف `COMPLETE`).

## 4) RDP من الهاتف بـ Tailscale (اختياري، أحسن من المتصفح)

1. دير حساب فـ https://tailscale.com ← **Settings ← Keys ← Generate auth key**
   وشعل **Reusable** و **Ephemeral** ← كوبي المفتاح (`tskey-auth-...`).
2. حطو فـ Secret سميتو `TAILSCALE_AUTHKEY`.
3. فـ الهاتف: نزّل تطبيق **Tailscale** ودخل بنفس الحساب وشعلو (Connect).
4. نزّل **Windows App** (Microsoft Remote Desktop سابقا) من المتجر.
5. شعل الـ workflow، وتسنى حتى يبان فـ log ديال **"Connect Tailscale"** الـ IP (`100.x.x.x`).
6. فـ Windows App: **+ ← Add PC** ← PC name = `100.x.x.x` (ولا `win11-github`)
   ← User account: `Docker` + `ACCESS_PASSWORD` ← Save ← Connect.

## 5) الإعدادات (فـ أعلى ملف الـ workflow → `env:`)

| متغير | الافتراضي | ملاحظة |
|---|---|---|
| `WIN_VERSION` | `11` | Windows 11 Pro |
| `WIN_USER` | `Docker` | اسم المستخدم (كيتطبق غير فـ أول تنصيب) |
| `LANGUAGE` / `REGION` / `KEYBOARD` | English / en-US / en-US | مثلا `French` / `fr-FR` / `fr-FR` (أول تنصيب فقط) |
| `RAM_SIZE` | `12G` | الـ runner فيه 16GB |
| `CPU_CORES` | `4` | الـ runner فيه 4 cores |
| `DISK_SIZE` | `64G` | sparse: غير المساحة المستعملة هي اللي كتتحفظ |
| `KEEP_BACKUPS` | `2` | شحال من backup قديم كيتخلا |

## ملاحظات مهمة

- **الوقت:** الحد الأقصى ديال أي جوب فـ GitHub Actions هو **6 ساعات**. حنا كنستعملو ~5 ساعات و نص
  للخدمة و كنخليو ~40 دقيقة فـ اللخر للإطفاء النقي + رفع الـ backup. إلا كان عندك بيانات بزاف،
  زيد `SAVE_RESERVE_MIN` شوية (مثلا 50).
- **السرعة:** الحفظ والاسترجاع كياخدو وقت حسب حجم البيانات (~15GB ≈ 10–20 دقيقة).
  كل ما خليتي Windows خفيف (ما تكبّرش ملفات ضخامة) كل ما كان أسرع.
- **الترخيص:** الـ ISO كيتحمّل رسمي من عند Microsoft. التنشيط (Activation) اختياري —
  ويندوز كيخدم بلا تنشيط مع شي حدود صغيرة فـ التخصيص.
- كل جلسة كتبدا فـ سيرفر جديد، ولكن الديسك ديالك كيرجع كيف ما هو.
- ما تستعملش هادشي لحوايج كتخالف
  [شروط GitHub Actions](https://docs.github.com/en/site-policy/github-terms/github-terms-for-additional-products-and-features#actions).

---

## 📱 تطبيق NOVA Windows Cloud (Android)

هاد الريبو فيه حتى تطبيق Flutter كامل (`lib/` + `android/`) كيكون لوحة تحكم لنفس السيستيم:
تدخل بـ GitHub، تختار الريبو، كتب الأسرار فالابليكاسيون وكتضاف بوحدها لـ GitHub Secrets،
تشغّل الويندوز، تتابع المراحل، وتشوف رابط الجلسة وTailscale — كلشي من الهاتف.

### تسجيل الدخول
- **Device Flow** (RFC 8628) هو الافتراضي: بلا Client Secret، بلا redirect، بلا deep link.
  التطبيق كيعطيك كود من 8 أحرف → كتحل `github.com/login/device` → كتأكدو → التطبيق كيتسجل بوحدو.
- **خيار متقدم:** الدخول عبر المتصفح (web flow + PKCE). GitHub كيطلب فهاد الحالة
  الـ **client secret** ديال الـ GitHub App (PKCE بوحدو ما كافياش عند GitHub)،
  وكتقدر تلصقو من «إعدادات متقدمة» — كيتخزن غير فـ Keystore ديال الهاتف، عمرو ما كيدخل فـ الـ APK.
- التطبيق كيطلب `offline_access` → التوكن 8 سوايع + **refresh token** 6 شهور كيتجدد بوحدو،
  (توكن الـ device flow كيتجدد بلا client secret).

### الأمان فال تطبيق
- الأسرار كتشفرو فالهاتف بـ **crypto_box_seal** (X25519 + XSalsa20-Poly1305 + Blake2b)
  قبل ما يتبعتو لـ GitHub API — نفس الطريقة الرسمية ديال GitHub.
- التوكن + refresh token كيتخزنو غير فـ **Android Keystore** (flutter_secure_storage).

### بناء الـ APK
كيتم أوتوماتيكيا مع كل push لـ `main` عبر `.github/workflows/build-apk.yml`:
- الـ APK كيبان فـ **Actions → Build APK → Artifacts**،
- وكيتنشر حتى كـ Release ثابت برابط تحميل مباشر:
  `.../releases/download/apk-latest/NOVA-Windows-Cloud.apk`

### الإعداد (مرة وحدة)
1. فصّفحة الـ GitHub App ديالك، تأكد بلي الـ Callback URL هو:
   `novawindowscloud://oauth/callback`، وبلي **Device Flow → Enable device flow** مشعّل
   (هو اللي كيخلي التسجيل بالكود يخدم — وهو الافتراضي فالتطبيق).
2. الصلاحيات المطلوبة فالـ GitHub App:
   Actions (R/W)، Secrets (R/W)، Contents (R/W)، Administration (R/W اختياري لإنشاء ريبو)، Profile (R).
3. ثبّت الـ App على الريبو ديالك (Install App).
4. شغّل الـ APK، سجل الدخول، اختار الريبو، دخل الأسرار، وشغّل Windows. 🚀

---

## 🎮 Minecraft Java Cloud (ميزة مستقلة)

التطبيق يوفّر أيضاً جلسة Linux مستقلة لـ **Minecraft Java Edition** بسير عمل خاص ومستودع GitHub خاص منفصل عن Windows. الاختيار واضح بين حساب Microsoft الرسمي (PKCE والتحقق من ملكية Java) وحساب Offline محلي باسم تختارو وتحفظو على الهاتف. الحساب المحلي ماشي حساب Java رسمي، والخوادم اللي كتطلب المصادقة الرسمية تقدر ترفضو. النسخ الاحتياطية للعوالم فقط كتتشفّر قبل حفظها في GitHub Releases؛ Windows Workflow وTailscale ما كيتبدلوش.

راجع [دليل إعداد Minecraft Java Cloud](docs/MINECRAFT_CLOUD.md) قبل الاستخدام؛ كلمة مرور العارض وكلمة مرور النسخ الاحتياطي مطلوبتان في الوضعين، وMicrosoft Client ID مطلوب غير لحساب Microsoft. العرض كيعتمد على Mesa برمجياً، لذلك GPU وFPS والـlatency ماشي مضمونين، والإيقاف الآمن ضروري باش تترفع نسخة العالم.
