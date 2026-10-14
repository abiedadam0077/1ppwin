const screens = [
  { id: "startup", group: "البداية", title: ["بدء التطبيق", "Startup"], description: ["التهيئة واستعادة الجلسة المحفوظة.", "Initialization and session restore."], states: [["loading", "جارٍ التهيئة", "Loading"]], defaultState: "loading" },
  { id: "login", group: "البداية", title: ["الترحيب وتسجيل الدخول", "Welcome & sign-in"], description: ["طرق المصادقة والحالات المعلقة والأخطاء.", "Authentication methods, pending and error states."], states: [["idle", "اختيار طريقة الدخول", "Choose sign-in method"], ["busy", "جارٍ الاتصال", "Connecting"], ["error", "خطأ في تسجيل الدخول", "Sign-in error"]], defaultState: "idle" },
  { id: "device", group: "البداية", title: ["تأكيد رمز GitHub", "GitHub device code"], description: ["الرمز، النسخ، فتح GitHub، الانتظار والإلغاء.", "Code, copy, open GitHub, waiting and cancel."], states: [["waiting", "بانتظار موافقة GitHub", "Waiting for GitHub"], ["requesting", "طلب الرمز", "Requesting code"], ["expired", "انتهت صلاحية الرمز", "Code expired"], ["success", "تمت المصادقة", "Authorized"]], defaultState: "waiting" },
  { id: "login-success", group: "البداية", title: ["نجاح تسجيل الدخول", "Sign-in success"], description: ["تأكيد الحساب الحقيقي قبل المتابعة.", "Confirm the returned account before continuing."], states: [["success", "متصل", "Connected"]], defaultState: "success" },
  { id: "home", group: "المساحة الرئيسية", title: ["لوحة التحكم", "Dashboard"], description: ["حالة Windows، إعداد المستودع، النسخ والإجراء الرئيسي.", "Windows status, repo setup, backups and primary action."], states: [["ready", "جاهز للبدء", "Ready to start"], ["needs-setup", "يحتاج إلى إعداد", "Needs setup"], ["running", "جلسة قيد التشغيل", "Session running"], ["no-repo", "لم يُحدد مستودع", "No repository"], ["error", "تعذر تحديث الحالة", "Status error"]], defaultState: "ready" },
  { id: "repos", group: "المساحة الرئيسية", title: ["المستودعات", "Repositories"], description: ["البحث والفلاتر والجاهزية والاختيار والإنشاء.", "Search, filters, readiness, selection and creation."], states: [["list", "قائمة المستودعات", "Repository list"], ["loading", "تحميل", "Loading"], ["empty", "لا توجد مستودعات", "No repositories"], ["search-empty", "لا توجد نتائج", "No results"], ["error", "خطأ في التحميل", "Load error"], ["permission", "صلاحيات ناقصة", "Missing permissions"]], defaultState: "list" },
  { id: "create-repo", group: "الإعداد والتشغيل", title: ["إنشاء مستودع", "Create repository"], description: ["الاسم والخصوصية والتثبيت الاختياري للـWorkflow.", "Name, visibility and optional workflow installation."], states: [["form", "النموذج", "Form"], ["submitting", "جارٍ الإنشاء", "Creating"], ["error", "فشل الإنشاء", "Creation failed"], ["success", "تم الإنشاء", "Created"]], defaultState: "form" },
  { id: "repo-setup", group: "الإعداد والتشغيل", title: ["إعداد المستودع", "Repository setup"], description: ["فحص Workflow والأسرار وإصلاح الإعداد.", "Inspect workflow and secrets; repair setup."], states: [["missing", "Workflow غير موجود", "Workflow missing"], ["repair", "التحديث مطلوب", "Repair required"], ["ready", "الإعداد مكتمل", "Setup complete"], ["permission", "صلاحية مطلوبة", "Permission required"]], defaultState: "repair" },
  { id: "security", group: "الإعداد والتشغيل", title: ["الأمان والأسرار", "Security & secrets"], description: ["الأسرار المطلوبة والاختيارية، الحفظ والتحقق.", "Required/optional secrets, save and verify."], states: [["missing", "أسرار مطلوبة", "Secrets required"], ["ready", "الأسرار مضبوطة", "Secrets configured"], ["saving", "جارٍ الحفظ", "Saving"], ["permission", "لا توجد صلاحية للأسرار", "Secrets permission denied"], ["success", "تم التحقق من الحفظ", "Save verified"]], defaultState: "missing" },
  { id: "permissions", group: "الإعداد والتشغيل", title: ["دليل صلاحيات GitHub", "GitHub permissions guide"], description: ["التعليمات داخل الإعدادات وعند رفض الوصول.", "Guidance shown in settings and permission errors."], states: [["guide", "خطوات التمكين", "Enablement steps"], ["error", "الوصول مرفوض", "Access denied"]], defaultState: "guide", parent: "settings" },
  { id: "session", group: "الإعداد والتشغيل", title: ["إعداد الجلسة", "Session setup"], description: ["المدة والاستعادة أو التثبيت الجديد وخيارات الوصول.", "Duration, restore/fresh install and access options."], states: [["restore", "استعادة نسخة", "Restore backup"], ["fresh", "تثبيت جديد", "Fresh install"], ["no-backup", "لا توجد نسخة مكتملة", "No complete backup"]], defaultState: "restore" },
  { id: "progress", group: "الإعداد والتشغيل", title: ["تقدم Workflow", "Workflow progress"], description: ["قائمة الخطوات المبنية على GitHub Actions وحالاتها.", "GitHub Actions-backed steps and their states."], states: [["queued", "في قائمة الانتظار", "Queued"], ["running", "قيد التنفيذ", "Running"], ["failure", "فشل التشغيل", "Run failed"], ["success", "اكتمل التشغيل", "Run completed"]], defaultState: "running" },
  { id: "ready", group: "الإعداد والتشغيل", title: ["Windows جاهز والاتصال", "Windows ready & access"], description: ["روابط الوصول ومعلومات الاتصال والإيقاف الآمن.", "Access routes, connection details and graceful stop."], states: [["connected", "اتصال متاح", "Connected"], ["web-only", "وصول المتصفح فقط", "Web only"], ["rdp-only", "وصول RDP فقط", "RDP only"], ["no-access", "لا يوجد وصول مفعّل", "No access enabled"], ["loading", "جارٍ جلب الرابط", "Loading route"]], defaultState: "connected" },
  { id: "backups", group: "السجل والإدارة", title: ["النسخ والاستعادة", "Backups & restore"], description: ["أحدث نسخة، سجل الإصدارات والحالات الفارغة والخطأ.", "Latest backup, release history, empty and error states."], states: [["list", "نسخ متاحة", "Backups available"], ["loading", "جارٍ التحميل", "Loading"], ["empty", "لا توجد نسخ", "No backups"], ["no-repo", "لا يوجد مستودع محدد", "No repository"], ["error", "خطأ في التحميل", "Load error"], ["permission", "صلاحية Releases ناقصة", "Releases permission denied"], ["incomplete", "نسخة غير مكتملة", "Incomplete backup"]], defaultState: "list" },
  { id: "backup-detail", group: "السجل والإدارة", title: ["تفاصيل النسخة", "Backup details"], description: ["لوحة تفاصيل مضافة فوق بيانات BackupInfo الحالية؛ بلا حذف.", "Proposed details sheet over existing BackupInfo; no delete."], states: [["complete", "مكتملة", "Complete"], ["incomplete", "غير مكتملة", "Incomplete"]], defaultState: "complete", parent: "backups" },
  { id: "activity", group: "السجل والإدارة", title: ["سجل النشاط", "Activity log"], description: ["العمليات المحلية الحقيقية وفلاتر النجاح والفشل.", "Real local operations and success/failure filters."], states: [["list", "سجل مختلط", "Mixed activity"], ["empty", "السجل فارغ", "Empty log"], ["success", "العمليات الناجحة", "Successful only"], ["failed", "العمليات الفاشلة", "Failed only"]], defaultState: "list" },
  { id: "settings", group: "السجل والإدارة", title: ["الإعدادات", "Settings"], description: ["الحساب واللغة والمستودع والأمان والصلاحيات والخروج.", "Account, language, repository, security, permissions and logout."], states: [["signed-in", "حساب متصل", "Signed in"], ["no-repo", "لا يوجد مستودع", "No repository"]], defaultState: "signed-in" },
  { id: "pat-dialog", group: "حوارات وتأكيدات", title: ["حوار PAT", "PAT dialog"], description: ["إدخال مخفي، رابط إنشاء الرمز، الإرسال والخطأ.", "Masked entry, token creation link, submit and error."], states: [["empty", "فارغ", "Empty"], ["invalid", "رمز مرفوض", "Rejected token"], ["busy", "جارٍ التحقق", "Verifying"], ["error", "خطأ اتصال", "Connection error"]], defaultState: "empty", parent: "login" },
  { id: "client-secret-dialog", group: "حوارات وتأكيدات", title: ["حوار Client Secret", "Client secret dialog"], description: ["قيمة اختيارية تُحفظ في التخزين الآمن على الجهاز.", "Optional value saved in device secure storage."], states: [["empty", "غير محفوظ", "Not saved"], ["saved", "محفوظ", "Saved"], ["saving", "جارٍ الحفظ", "Saving"]], defaultState: "empty", parent: "login" },
  { id: "manual-callback-dialog", group: "حوارات وتأكيدات", title: ["إدخال رابط العودة يدوياً", "Manual callback input"], description: ["رابط OAuth أو رمز منفرد، مع التحقق وإظهار الخطأ.", "OAuth URL or bare code, validation and error."], states: [["empty", "بانتظار الإدخال", "Awaiting input"], ["invalid", "إدخال غير صالح", "Invalid input"], ["busy", "جارٍ التبادل", "Exchanging code"]], defaultState: "empty", parent: "login" },
  { id: "restore-confirm", group: "حوارات وتأكيدات", title: ["تأكيد الاستعادة", "Restore confirmation"], description: ["شرح أثر الاستعادة قبل إرسال تشغيل Workflow.", "Explain restore impact before workflow dispatch."], states: [["confirm", "بانتظار التأكيد", "Awaiting confirmation"], ["busy", "جارٍ بدء الاستعادة", "Starting restore"], ["error", "تعذر بدء الاستعادة", "Restore error"]], defaultState: "confirm", parent: "backups" },
  { id: "stop-confirm", group: "حوارات وتأكيدات", title: ["تأكيد إيقاف Windows", "Stop Windows confirmation"], description: ["إيقاف آمن مع حفظ النسخة أو إلغاء فوري.", "Graceful save-and-stop or immediate cancellation."], states: [["confirm", "اختيار الإيقاف", "Choose stop mode"], ["busy", "جارٍ الإرسال", "Sending request"], ["error", "تعذر الإيقاف", "Stop error"]], defaultState: "confirm", parent: "ready" },
  { id: "clear-confirm", group: "حوارات وتأكيدات", title: ["تأكيد مسح سجل النشاط", "Clear activity confirmation"], description: ["مقترح أمان: يمسح السجل المحلي فقط، لا GitHub.", "Safety addition: clears local history only, not GitHub."], states: [["confirm", "بانتظار التأكيد", "Awaiting confirmation"]], defaultState: "confirm", parent: "activity" },
  { id: "logout-confirm", group: "حوارات وتأكيدات", title: ["تأكيد تسجيل الخروج", "Sign-out confirmation"], description: ["مقترح أمان قبل إزالة حالة الدخول والمستودع المحفوظ.", "Safety addition before clearing login and selected repo."], states: [["confirm", "بانتظار التأكيد", "Awaiting confirmation"]], defaultState: "confirm", parent: "settings" }
];

const stateNames = {
  loading: ["جارٍ التحميل", "Loading"], ready: ["جاهز", "Ready"], idle: ["هادئ", "Idle"], busy: ["جارٍ التنفيذ", "In progress"], error: ["خطأ", "Error"],
  "needs-setup": ["يحتاج إلى إعداد", "Needs setup"], running: ["قيد التشغيل", "Running"], "no-repo": ["لا يوجد مستودع", "No repository"],
  list: ["قائمة", "List"], empty: ["فارغ", "Empty"], "search-empty": ["لا نتائج", "No results"], permission: ["صلاحية ناقصة", "Permission denied"],
  form: ["النموذج", "Form"], submitting: ["جارٍ الإرسال", "Submitting"], success: ["نجاح", "Success"], missing: ["ناقص", "Missing"], repair: ["إصلاح", "Repair"],
  saving: ["جارٍ الحفظ", "Saving"], restore: ["استعادة", "Restore"], fresh: ["جديد", "Fresh install"], "no-backup": ["لا توجد نسخة", "No backup"],
  queued: ["بالانتظار", "Queued"], failure: ["فشل", "Failure"], connected: ["متصل", "Connected"], "web-only": ["ويب فقط", "Web only"],
  "rdp-only": ["RDP فقط", "RDP only"], "no-access": ["لا يوجد وصول", "No access"], "incomplete": ["غير مكتمل", "Incomplete"], "signed-in": ["متصل", "Signed in"],
  "backup-detail": ["تفاصيل النسخة", "Backup details"], invalid: ["غير صالح", "Invalid"], saved: ["محفوظ", "Saved"], confirm: ["تأكيد", "Confirmation"],
  guide: ["الدليل", "Guide"], requesting: ["جارٍ الطلب", "Requesting"], expired: ["منتهي", "Expired"]
};

const screenMap = Object.fromEntries(screens.map((screen) => [screen.id, screen]));
const currentStates = Object.fromEntries(screens.map((screen) => [screen.id, screen.defaultState]));
let currentScreen = "home";
let currentDesign = "a";
let currentLocale = "ar";
let activityFilter = "all";
let toastTimer;

const iconPaths = {
  home: '<path d="m3 10 9-7 9 7v10a1 1 0 0 1-1 1h-5v-6H9v6H4a1 1 0 0 1-1-1z"/>',
  folder: '<path d="M3 6.5A1.5 1.5 0 0 1 4.5 5H10l2 2h7.5A1.5 1.5 0 0 1 21 8.5v9a1.5 1.5 0 0 1-1.5 1.5h-15A1.5 1.5 0 0 1 3 17.5z"/><path d="M3.5 9h17"/>',
  backup: '<path d="M20 7v5h-5"/><path d="M19 12a7.5 7.5 0 1 1-1.5-4.5L20 12"/><path d="M12 8v4l2.5 1.5"/>',
  history: '<path d="M3 12a9 9 0 1 0 2.6-6.4L3 8"/><path d="M3 3v5h5"/><path d="M12 7v5l3 2"/>',
  settings: '<path d="M12 8.5a3.5 3.5 0 1 0 0 7 3.5 3.5 0 0 0 0-7z"/><path d="m19.4 15 .1.1 1 1.8-1.8 3.1-2-.5a7.8 7.8 0 0 1-1.4.8l-.7 1.9h-3.6l-.7-1.9a7.8 7.8 0 0 1-1.4-.8l-2 .5-1.8-3.1 1-1.8a8 8 0 0 1 0-1.7l-1-1.8L7 8.4l2 .5a7.8 7.8 0 0 1 1.4-.8l.7-1.9h3.6l.7 1.9a7.8 7.8 0 0 1 1.4.8l2-.5 1.8 3.1-1 1.8a8 8 0 0 1-.2 1.7z"/>',
  refresh: '<path d="M20 7v5h-5"/><path d="M19 12a7.5 7.5 0 1 1-2-5"/>',
  github: '<path d="M9 19c-4.3 1.4-4.3-2.5-6-3m12 6v-3.9a3.4 3.4 0 0 0-1-2.6c3.3-.4 6.8-1.6 6.8-7A5.5 5.5 0 0 0 19.3 4a5.1 5.1 0 0 0-.1-4S18 .6 15 2.6a13.5 13.5 0 0 0-7 0C5 .6 3.8 0 3.8 0a5.1 5.1 0 0 0-.1 4A5.5 5.5 0 0 0 2.2 7.5c0 5.4 3.5 6.6 6.8 7A3.4 3.4 0 0 0 8 17.1V22"/>',
  shield: '<path d="M12 22s8-4 8-11V5l-8-3-8 3v6c0 7 8 11 8 11z"/><path d="m9 12 2 2 4-4"/>',
  key: '<circle cx="8" cy="15" r="5"/><path d="m11.5 11.5 9-9 2 2-2 2 2 2-3 3-2-2-2 2"/>',
  windows: '<path d="M2 5.5 10.5 4v7H2zM12 3.7 22 2v9H12zM2 13h8.5v7L2 18.5zM12 13h10v9l-10-1.7z"/>',
  plus: '<path d="M12 5v14M5 12h14"/>',
  arrow: '<path d="M5 12h14M13 6l6 6-6 6"/>',
  copy: '<rect x="8" y="8" width="12" height="12" rx="2"/><path d="M16 8V5a2 2 0 0 0-2-2H5a2 2 0 0 0-2 2v9a2 2 0 0 0 2 2h3"/>',
  external: '<path d="M14 3h7v7M10 14 21 3"/><path d="M19 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V7a2 2 0 0 1 2-2h6"/>',
  check: '<path d="m5 12 4 4L19 6"/>',
  alert: '<path d="M10.3 3.9 1.8 18.5A2 2 0 0 0 3.5 21h17a2 2 0 0 0 1.7-2.5L13.7 3.9a2 2 0 0 0-3.4 0z"/><path d="M12 9v4m0 4h.01"/>',
  lock: '<rect x="4" y="10" width="16" height="11" rx="2"/><path d="M8 10V7a4 4 0 1 1 8 0v3"/>',
  clock: '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',
  user: '<circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0 1 16 0"/>',
  cloud: '<path d="M7 18h10a4 4 0 0 0 .6-8A6 6 0 0 0 6 9.5 4.2 4.2 0 0 0 7 18z"/>',
  search: '<circle cx="10.8" cy="10.8" r="6.8"/><path d="m16 16 5 5"/>',
  chevron: '<path d="m9 18 6-6-6-6"/>',
  restore: '<path d="M3 12a9 9 0 1 0 2.6-6.4L3 8"/><path d="M3 3v5h5m4-1v5l3 2"/>',
  trash: '<path d="M3 6h18M8 6V4h8v2m3 0-1 14H6L5 6m4 4v6m6-6v6"/>',
  logout: '<path d="M10 17l5-5-5-5m5 5H3"/><path d="M12 3h6a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-6"/>',
  close: '<path d="m18 6-12 12M6 6l12 12"/>',
  code: '<path d="m8 8-4 4 4 4m8-8 4 4-4 4m-2-11-4 14"/>',
  globe: '<circle cx="12" cy="12" r="10"/><path d="M2 12h20M12 2a15 15 0 0 1 0 20M12 2a15 15 0 0 0 0 20"/>',
  network: '<circle cx="6" cy="6" r="3"/><circle cx="18" cy="18" r="3"/><path d="M8 8l8 8M18 6h.01M6 18h.01"/>',
  more: '<circle cx="5" cy="12" r="1"/><circle cx="12" cy="12" r="1"/><circle cx="19" cy="12" r="1"/>',
  shieldAlert: '<path d="M12 22s8-4 8-11V5l-8-3-8 3v6c0 7 8 11 8 11z"/><path d="M12 8v4m0 4h.01"/>'
};

function icon(name) { return `<svg viewBox="0 0 24 24" aria-hidden="true">${iconPaths[name] || iconPaths.cloud}</svg>`; }
function tx(ar, en) { return currentLocale === "ar" ? ar : en; }
function dirAttr() { return currentLocale === "ar" ? "rtl" : "ltr"; }
function escapeHtml(value) { return String(value).replace(/[&<>"']/g, (ch) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[ch])); }
function status(text, kind = "neutral", loading = false) { return `<span class="status-pill ${kind}${loading ? " loading" : ""}">${text}</span>`; }
function button(label, { go = null, action = null, kind = "primary", iconName = null, full = false, small = false, aria = null } = {}) {
  const attrs = go ? `data-go="${go}"` : action ? `data-action="${action}"` : `data-action="preview-only"`;
  return `<button type="button" class="btn btn-${kind}${full ? " btn-full" : ""}${small ? " btn-small" : ""}" ${attrs}${aria ? ` aria-label="${escapeHtml(aria)}"` : ""}>${iconName ? icon(iconName) : ""}<span>${label}</span></button>`;
}
function field(label, placeholder, { type = "text", dir = null, value = "", help = "", error = "" } = {}) {
  const direction = dir || (type === "url" || type === "password" ? "ltr" : dirAttr());
  return `<label class="field"><span class="field-label">${label}</span><span class="field-box"><input type="${type}" dir="${direction}" placeholder="${placeholder}" value="${value}" autocomplete="off" aria-label="${label}"></span>${help ? `<small class="field-help">${help}</small>` : ""}${error ? `<small class="field-error">${error}</small>` : ""}</label>`;
}
function surface(content, extra = "") { return `<section class="surface ${extra}">${content}</section>`; }
function sectionHeading(title, sub = "") { return `<div class="section-heading"><h3>${title}</h3>${sub ? `<small>${sub}</small>` : ""}</div>`; }
function sampleRepo(name = "windows-lab") { return `<bdi class="repo-ltr">sample-owner/${escapeHtml(name)}</bdi>`; }
function statusBar() { return `<div class="status-bar"><span>9:41</span><span class="status-indicators"><span class="signal" aria-hidden="true"><i></i><i></i><i></i><i></i></span><span>Wi-Fi</span><span class="battery" aria-label="Battery 82 percent"></span></span></div>`; }
function bottomNav(active) {
  const tabs = [
    ["home", "home", ["الرئيسية", "Home"]], ["repos", "folder", ["المستودعات", "Repos"]], ["backups", "backup", ["نسخ واستعادة", "Backups"]], ["activity", "history", ["النشاط", "Activity"]], ["settings", "settings", ["الإعدادات", "Settings"]]
  ];
  return `<footer class="page-footer"><nav class="bottom-tabs" aria-label="${tx("التنقل الرئيسي", "Main navigation")}">${tabs.map(([id, glyph, label]) => `<button type="button" class="tab-button" data-nav="${id}" aria-current="${active === id ? "page" : "false"}" aria-label="${label[currentLocale === "ar" ? 0 : 1]}"><span class="tab-icon">${icon(glyph)}</span><span class="tab-label">${label[currentLocale === "ar" ? 0 : 1]}</span></button>`).join("")}</nav></footer><div class="safe-bottom"></div>`;
}
function appShell(title, subtitle, body, { tab = null, back = null, action = null, noHeader = false } = {}) {
  const header = noHeader ? "" : `<header class="app-header">${back ? `<button type="button" class="icon-button" data-go="${back}" aria-label="${tx("رجوع", "Back")}">${icon("chevron")}</button>` : `<div class="header-mark" aria-hidden="true">N</div>`}<div class="header-title"><strong>${title}</strong>${subtitle ? `<small>${subtitle}</small>` : ""}</div>${action ? `<button type="button" class="icon-button" ${action.attr || "data-action=preview-only"} aria-label="${action.label}">${icon(action.icon || "more")}</button>` : ""}</header>`;
  return `<div class="app-screen" lang="${currentLocale}" dir="${dirAttr()}">${statusBar()}${header}<main class="page-content">${body}</main>${tab ? bottomNav(tab) : ""}</div>`;
}
function statusIllustration(glyph = "cloud") { return `<div class="state-illustration">${icon(glyph)}</div>`; }
function repoTitle(title = "windows-lab", sub = "Cloud runner · main") { return `<div class="row-grow"><span class="row-title ltr">${escapeHtml(title)}</span><span class="repo-ltr">sample-owner/${escapeHtml(title)}</span><span class="row-sub">${sub}</span></div>`; }
function checkRow(title, subtitle, state = "done") { return `<div class="check-row"><span class="checkmark ${state === "done" ? "" : state === "pending" ? "pending" : "missing"}">${state === "done" ? "✓" : state === "pending" ? "!" : "·"}</span><div class="row-grow"><span class="row-title">${title}</span><span class="row-sub">${subtitle}</span></div>${state === "done" ? status(tx("مكتمل", "Complete"), "success") : state === "pending" ? status(tx("مطلوب", "Required"), "warning") : status(tx("غير مضبوط", "Not set"), "neutral")}</div>`; }
function settingRow(glyph, title, subtitle, go = null) { return `<button type="button" class="setting-row" ${go ? `data-go="${go}"` : "data-action=preview-only"}><span class="setting-icon">${icon(glyph)}</span><span class="row-grow"><span class="row-title">${title}</span>${subtitle ? `<span class="row-sub">${subtitle}</span>` : ""}</span>${icon("chevron")}</button>`; }
function toggleRow(title, subtitle, checked, id) { return `<div class="switch-row"><div class="switch-copy"><span class="row-title">${title}</span><span class="row-sub">${subtitle}</span></div><button type="button" class="toggle" role="switch" aria-checked="${checked}" aria-label="${title}" data-action="toggle" data-toggle-id="${id}"></button></div>`; }
function fullTitle(kicker, title, subtitle) { return `<p class="page-kicker">${kicker}</p><h1 class="page-title">${title}</h1>${subtitle ? `<p class="page-subtitle">${subtitle}</p>` : ""}`; }

function renderStartup(state) {
  const content = `<div class="startup-view"><div class="startup-logo"><span class="header-mark">N</span><div class="ltr"><strong>NOVA</strong><small>WINDOWS CLOUD</small></div></div><div class="windows-mark">${icon("windows")}</div><h1>${tx("بيئة Windows السحابية", "Your Windows cloud workspace")}</h1><p>${tx("جارٍ استعادة إعدادات التطبيق والتحقق من الجلسة المحفوظة…", "Restoring app preferences and checking your saved session…")}</p><div class="progress-track"><div class="progress-fill" style="width:42%"></div></div><span class="startup-status">${status(tx("تهيئة آمنة", "Secure initialization"), "neutral", true)}</span></div>`;
  return `<div class="app-screen startup-screen" lang="${currentLocale}" dir="${dirAttr()}">${statusBar()}<main class="page-content startup-content">${content}</main><div class="safe-bottom"></div></div>`;
}

function renderLogin(state) {
  const error = state === "error" ? `<div class="notice danger" role="alert">${icon("alert")} ${tx("تعذر إكمال تسجيل الدخول. تحقق من الاتصال أو أعد المحاولة. لا تُسجّل تفاصيل الرمز.", "Sign-in could not be completed. Check the connection or retry. Token details are never logged.")}</div>` : "";
  const busy = state === "busy";
  const body = `<div class="welcome-mark"><div class="header-mark">N</div><div class="ltr"><strong>NOVA</strong><small>WINDOWS CLOUD</small></div></div>${fullTitle(tx("سحابة Windows الخاصة بك", "Your Windows cloud"), tx("ابدأ من GitHub", "Start with GitHub"), tx("اربط حسابك للوصول إلى مستودعاتك وتشغيل Windows بأمان.", "Connect your account to access repositories and launch Windows securely."))}${error}${state === "error" ? button(tx("إعادة المحاولة برمز الجهاز", "Retry with device code"), { go: "device", kind: "secondary", full: true, iconName: "refresh" }) : ""}${surface(`<div class="surface-header"><h2 class="surface-title">${tx("الطريقة الموصى بها", "Recommended method")}</h2>${status(tx("آمن", "Secure"), "success")}</div><p class="surface-note">${tx("رمز مؤقت تؤكده على موقع GitHub؛ لا حاجة إلى نسخ رمز شخصي.", "A temporary code confirmed on GitHub; no personal token required.")}</p><div class="button-row">${button(busy ? tx("جارٍ الاتصال…", "Connecting…") : tx("المتابعة برمز الجهاز", "Continue with device code"), { go: "device", iconName: "github", full: true })}</div>`, "surface-hero")}${sectionHeading(tx("طرق أخرى", "Other methods"))}${surface(`${settingRow("globe", tx("المتصفح", "Browser"), tx("OAuth PKCE مع رابط عودة آمن", "OAuth PKCE with secure callback"), null)}${settingRow("key", tx("رمز شخصي PAT", "Personal token (PAT)"), tx("يُدخل بشكل مخفي ويُحفظ بأمان", "Masked entry, stored securely"), "pat-dialog")}${settingRow("code", tx("خيارات متقدمة", "Advanced options"), tx("Client Secret أو إدخال رابط العودة يدوياً", "Client secret or manual callback entry"), "client-secret-dialog")}`)}<p class="login-privacy">${icon("shield")} ${tx("لا تُضمّن بيانات الدخول داخل التطبيق أو سجلات النشاط.", "Credentials are not embedded in the app or activity log.")}</p>`;
  return appShell(tx("مرحباً بك", "Welcome"), tx("إدارة Windows 11 من GitHub Actions", "Manage Windows 11 through GitHub Actions"), body, { noHeader: true });
}

function renderDevice(state) {
  const expired = state === "expired";
  const requesting = state === "requesting";
  const success = state === "success";
  const body = `${fullTitle(tx("تأكيد آمن", "Secure authorization"), tx("أكمل الربط على GitHub", "Finish on GitHub"), tx("افتح صفحة التحقق وأدخل الرمز المؤقت. لا تغلق هذه الشاشة أثناء الانتظار.", "Open the verification page and enter the temporary code. Keep this screen open while waiting."))}${expired ? `<div class="notice danger">${tx("انتهت صلاحية الرمز. اطلب رمزاً جديداً للمتابعة.", "This code expired. Request a new code to continue.")}</div>${button(tx("طلب رمز جديد", "Request a new code"), { action: "request-code", kind: "secondary", full: true, iconName: "refresh" })}` : ""}${success ? `<div class="notice info">${tx("تمت الموافقة؛ جارٍ تجهيز حسابك…", "Approved; preparing your account…")}</div>` : ""}${surface(`<div class="surface-header"><h2 class="surface-title">${tx("رمز الجهاز", "Device code")}</h2>${status(success ? tx("تم", "Done") : expired ? tx("منتهي", "Expired") : tx(requesting ? "جارٍ الطلب" : "بانتظارك", requesting ? "Requesting" : "Waiting for you"), success ? "success" : expired ? "danger" : "warning", requesting || (!expired && !success))}</div><span class="security-code">${requesting ? "········" : expired ? "EXPIRED" : "AB12-CD34"}</span>${requesting || expired ? "" : `<div class="button-row">${button(tx("نسخ الرمز", "Copy code"), { action: "copy", kind: "secondary", iconName: "copy" })}${button(tx("فتح GitHub", "Open GitHub"), { action: "preview-only", kind: "primary", iconName: "external" })}</div>`}`, "surface-hero")}${surface(`<div class="row"><div class="item-icon">${icon("clock")}</div><div class="row-grow"><span class="row-title">${tx("بانتظار موافقتك", "Waiting for approval")}</span><span class="row-sub">${tx("تنتهي صلاحية الرمز حسب مؤقّت GitHub.", "The code expires according to GitHub's timer.")}</span></div>${status(tx("قيد الانتظار", "Pending"), "warning", !expired && !success)}</div><div class="keyline"></div><p class="surface-note">${tx("بعد الموافقة سنحمّل المستودعات ونفحص إعداد Workflow والأسرار.", "After approval, repositories load and workflow/secrets are checked.")}</p>`)}<div class="button-row">${button(tx("إلغاء", "Cancel"), { go: "login", kind: "quiet" })}${success ? button(tx("متابعة", "Continue"), { go: "login-success", kind: "primary" }) : ""}</div>`;
  return appShell(tx("ربط GitHub", "Connect GitHub"), tx("تأكيد رمز الجهاز", "Device authorization"), body, { back: "login" });
}

function renderLoginSuccess() {
  const body = `<div class="success-orbit"><div class="success-mark">${icon("check")}</div></div>${fullTitle(tx("تم الربط بنجاح", "Connected successfully"), tx("أهلاً بك في NOVA", "Welcome to NOVA"), tx("تم التحقق من الحساب. يمكنك الآن اختيار مستودع وإكمال الإعداد.", "Your account is verified. Choose a repository and finish setup."))}${surface(`<div class="row"><div class="avatar">S</div><div class="row-grow"><span class="row-title">Sample Account</span><span class="repo-ltr">@sample-owner</span></div>${status(tx("GitHub متصل", "GitHub connected"), "success")}</div>`, "surface-hero")}${button(tx("الانتقال إلى لوحة التحكم", "Continue to dashboard"), { go: "home", full: true, iconName: "arrow" })}`;
  return appShell(tx("اكتمل تسجيل الدخول", "Sign-in complete"), "", body, { noHeader: true });
}

function renderHome(state) {
  if (state === "no-repo") {
    const body = `${fullTitle(tx("مساحة العمل", "Workspace"), tx("اختر مستودع Windows", "Choose a Windows repository"), tx("سنفحص الإعداد الحقيقي قبل تشغيل أي جلسة.", "We will inspect the real setup before starting a session."))}${surface(`<div class="empty-panel">${statusIllustration("folder")}<h3>${tx("لم يتم اختيار مستودع", "No repository selected")}</h3><p>${tx("اختر مستودعاً موجوداً أو أنشئ واحداً لبدء إعداد Windows.", "Choose an existing repository or create one to start setup.")}</p>${button(tx("استعراض المستودعات", "Browse repositories"), { go: "repos", full: true, iconName: "folder" })}</div>`)}`;
    return appShell(tx("الرئيسية", "Home"), tx("لوحة Windows Cloud", "Windows Cloud overview"), body, { tab: "home" });
  }
  if (state === "error") {
    const body = `${fullTitle(tx("لوحة التحكم", "Dashboard"), tx("تعذر تحديث الحالة", "Could not refresh status"), tx("لا نعرض بيانات قديمة على أنها مباشرة. أعد المحاولة أو تحقق من اتصال GitHub.", "Stale data is not shown as live. Retry or check GitHub connectivity."))}${surface(`<div class="error-panel">${statusIllustration("alert")}<h3>${tx("حالة المستودع غير متاحة", "Repository status unavailable")}</h3><p>${tx("قد يكون الاتصال مؤقتاً أو صلاحية GitHub غير كافية.", "The connection may be temporary or GitHub permissions may be insufficient.")}</p>${button(tx("إعادة الفحص", "Retry status check"), { action: "preview-only", kind: "secondary", iconName: "refresh" })}</div>`)}`;
    return appShell(tx("الرئيسية", "Home"), tx("حالة GitHub", "GitHub status"), body, { tab: "home" });
  }
  const needsSetup = state === "needs-setup";
  const running = state === "running";
  const stateLabel = needsSetup ? tx("إعداد مطلوب", "Setup needed") : running ? tx("قيد التشغيل", "Running") : tx("جاهز للبدء", "Ready to start");
  const stateKind = needsSetup ? "warning" : running ? "success" : "success";
  const primary = needsSetup ? button(tx("إكمال إعداد المستودع", "Complete repository setup"), { go: "repo-setup", full: true, iconName: "settings" }) : running ? button(tx("عرض التقدم والاتصال", "View progress & access"), { go: "progress", full: true, iconName: "activity" }) : button(tx("إعداد جلسة Windows", "Configure Windows session"), { go: "session", full: true, iconName: "windows" });
  const summary = currentDesign === "a" ? `<div class="surface surface-hero"><div class="hero-status"><span class="surface-title">${tx("حالة Windows 11", "Windows 11 status")}</span>${status(stateLabel, stateKind, running)}</div><div class="hero-system"><div class="windows-mark">${icon("windows")}</div><div><h2>Windows 11 Pro</h2><p>${tx("المستودع المحدد", "Selected repository")}</p><span class="repo-ltr">sample-owner/windows-lab</span></div></div>${running ? `<div class="stat-grid"><div class="stat"><span class="stat-label">${tx("الوقت المتبقي", "Time remaining")}</span><span class="stat-value">02:14:00</span></div><div class="stat"><span class="stat-label">${tx("حالة Workflow", "Workflow")}</span><span class="stat-value">${tx("جارٍ التنفيذ", "In progress")}</span></div></div>` : `<div class="small-grid"><div class="stat"><span class="stat-label">${tx("Workflow", "Workflow")}</span><span class="stat-value">${needsSetup ? tx("يحتاج تحديثاً", "Needs repair") : tx("جاهز", "Ready")}</span></div><div class="stat"><span class="stat-label">${tx("الأسرار", "Secrets")}</span><span class="stat-value">${needsSetup ? tx("تحقق مطلوب", "Check required") : tx("مؤكدة", "Verified")}</span></div></div>`}${primary}</div>` : `<div class="surface surface-hero aurora-dashboard"><div class="hero-status"><span class="page-kicker">NOVA CLOUD · WINDOWS</span>${status(stateLabel, stateKind, running)}</div><div class="aurora-orbit"><div class="windows-mark">${icon("windows")}</div><span class="orbit orbit-one"></span><span class="orbit orbit-two"></span></div><h2 class="aurora-title">Windows 11 Pro</h2><span class="repo-ltr">sample-owner/windows-lab</span><div class="stat-grid"><div class="stat"><span class="stat-label">${running ? tx("الوقت المتبقي", "Time remaining") : tx("Workflow", "Workflow")}</span><span class="stat-value">${running ? "02:14:00" : needsSetup ? tx("يحتاج تحديثاً", "Needs repair") : tx("جاهز", "Ready")}</span></div><div class="stat"><span class="stat-label">${tx("النسخة الأخيرة", "Latest backup")}</span><span class="stat-value">${tx("مكتملة", "Complete")}</span></div></div>${primary}</div>`;
  const setupChecks = surface(`<div class="surface-header"><h3 class="surface-title">${tx("جاهزية المستودع", "Repository readiness")}</h3>${button(tx("التفاصيل", "Details"), { go: "repo-setup", kind: "quiet", small: true })}</div>${checkRow(tx("ملف Windows Workflow", "Windows workflow file"), ".github/workflows/windows11.yml", needsSetup ? "pending" : "done")}${checkRow(tx("أسرار التشغيل المطلوبة", "Required runtime secrets"), "ACCESS_PASSWORD · BACKUP_PASSWORD", needsSetup ? "missing" : "done")}`);
  const backup = surface(`<div class="row"><div class="item-icon">${icon("backup")}</div><div class="row-grow"><span class="row-title">${tx("آخر نسخة مكتملة", "Latest complete backup")}</span><span class="row-sub">${tx("تفاصيل النسخ من GitHub Releases", "Backup details from GitHub Releases")}</span></div>${status(tx("جاهزة", "Ready"), "success")}</div><div class="button-row">${button(tx("عرض النسخ والاستعادة", "View backups & restore"), { go: "backups", kind: "secondary", full: true, iconName: "backup" })}</div>`);
  const shortcuts = `<div class="quick-grid">${button(tx("المستودعات", "Repositories"), { go: "repos", kind: "quiet", iconName: "folder" })}${button(tx("الأمان", "Security"), { go: "security", kind: "quiet", iconName: "shield" })}</div>`;
  const body = `<div class="dashboard-greeting"><span>${tx("مرحباً بعودتك", "Welcome back")}</span><span class="repo-ltr">@sample-owner</span></div>${summary}${setupChecks}${backup}${sectionHeading(tx("اختصارات", "Quick actions"))}${shortcuts}`;
  return appShell(tx("الرئيسية", "Home"), tx("مركز التحكم", "Control center"), body, { tab: "home", action: { label: tx("تحديث الحالة", "Refresh status"), icon: "refresh", attr: "data-action=preview-only" } });
}

function repoCard(name, selected, statusText, kind = "success") {
  return `<button type="button" class="list-item repo-card ${selected ? "is-selected" : ""}" data-go="repo-setup" aria-label="${tx("فتح إعداد المستودع", "Open repository setup")}: sample-owner/${name}"><span class="item-icon">${icon("folder")}</span><span class="row-grow"><span class="row-title ltr">${name}</span><span class="repo-ltr">sample-owner/${name}</span><span class="item-meta"><span class="meta-chip">${tx("خاص", "Private")}</span><span class="meta-chip">main</span></span></span><span>${status(statusText, kind)}</span></button>`;
}
function renderRepos(state) {
  const search = `<label class="field search-field"><span class="field-label">${tx("البحث في المستودعات", "Search repositories")}</span><span class="field-box">${icon("search")}<input type="search" placeholder="${tx("اسم المستودع أو الوصف", "Repository name or description")}" aria-label="${tx("البحث", "Search")}"></span></label>`;
  const chips = `<div class="chips" role="group" aria-label="${tx("تصفية المستودعات", "Filter repositories")}">${[tx("الكل", "All"), tx("جاهز", "Ready"), tx("يحتاج إعداد", "Needs setup"), tx("خاص", "Private"), tx("عام", "Public")].map((label, index) => `<button type="button" class="chip ${index === 0 ? "active" : ""}" data-action="filter-chip">${label}</button>`).join("")}</div>`;
  let list = "";
  if (state === "loading") list = `<div class="surface">${status(tx("جارٍ جلب المستودعات وفحص الجاهزية…", "Loading repositories and checking readiness…"), "neutral", true)}<div class="keyline"></div>${repoCard("windows-lab", false, tx("جارٍ الفحص", "Checking"), "neutral")}</div>`;
  else if (state === "empty") list = `<div class="empty-panel">${statusIllustration("folder")}<h3>${tx("لا توجد مستودعات بعد", "No repositories yet")}</h3><p>${tx("أنشئ مستودع Windows أو راجع صلاحيات GitHub.", "Create a Windows repository or review GitHub permissions.")}</p>${button(tx("إنشاء مستودع", "Create repository"), { go: "create-repo", full: true, iconName: "plus" })}</div>`;
  else if (state === "search-empty") list = `<div class="empty-panel">${statusIllustration("search")}<h3>${tx("لا توجد نتائج مطابقة", "No matching repositories")}</h3><p>${tx("غيّر كلمات البحث أو الفلاتر للعثور على المستودع.", "Change the search or filters to find a repository.")}</p>${button(tx("مسح البحث والفلاتر", "Clear search and filters"), { action: "preview-only", kind: "secondary", full: true })}</div>`;
  else if (state === "error") list = `<div class="error-panel" role="alert">${statusIllustration("alert")}<h3>${tx("تعذر تحميل المستودعات", "Could not load repositories")}</h3><p>${tx("تحقق من اتصال GitHub وحاول مجدداً.", "Check GitHub connectivity and try again.")}</p>${button(tx("إعادة المحاولة", "Retry"), { action: "preview-only", kind: "secondary", iconName: "refresh" })}</div>`;
  else if (state === "permission") list = `<div class="notice danger">${tx("يتطلب الوصول صلاحيات مستودع/Workflow. لا نعرض أزرار إعداد لا يمكن تنفيذها.", "Repository/workflow permission is required. Setup actions stay unavailable until access is fixed.")}</div><div class="surface">${button(tx("عرض خطوات الصلاحيات", "View permission steps"), { go: "permissions", kind: "secondary", full: true, iconName: "shield" })}</div>`;
  else list = `<div class="list-caption"><span>${tx("3 مستودعات توضيحية", "3 illustrative repositories")}</span>${status(tx("فحص مكتمل", "Checks complete"), "success")}</div><div class="item-list">${repoCard("windows-lab", true, tx("جاهز", "Ready"), "success")}${repoCard("win-dev", false, tx("أسرار ناقصة", "Secrets missing"), "warning")}${repoCard("cloud-test", false, tx("يحتاج إصلاحاً", "Needs repair"), "warning")}</div>${button(tx("إنشاء مستودع جديد", "Create a new repository"), { go: "create-repo", kind: "secondary", full: true, iconName: "plus" })}`;
  const body = `${fullTitle(tx("مستودعات GitHub", "GitHub repositories"), tx("اختر مساحة Windows", "Choose a Windows workspace"), tx("نتائج الفحص تُحمّل من GitHub؛ الحالات هنا توضيحية للعرض فقط.", "Readiness comes from GitHub; sample states here are for design review only."))}${search}${chips}${list}`;
  return appShell(tx("المستودعات", "Repositories"), tx("الاختيار والتهيئة", "Select and configure"), body, { tab: "repos", action: { label: tx("تحديث المستودعات", "Refresh repositories"), icon: "refresh" } });
}

function renderCreateRepo(state) {
  const isError = state === "error";
  const isSuccess = state === "success";
  const body = `${fullTitle(tx("مساحة جديدة", "New workspace"), tx("إنشاء مستودع Windows", "Create a Windows repository"), tx("يُنشأ المستودع على GitHub باستخدام صلاحيات حسابك.", "The repository is created on GitHub using your account permissions."))}${isSuccess ? `<div class="notice info">${tx("تم الإنشاء. سيُحدّد المستودع الجديد ثم تُحدّث القائمة.", "Created. The new repository will be selected and the list refreshed.")}</div>` : ""}${surface(`<div class="field"><label class="field-label" for="repo-name">${tx("اسم المستودع", "Repository name")}</label><span class="field-box"><input id="repo-name" class="ltr" placeholder="windows-11-cloud" value=""></span>${isError ? `<small class="field-error">${tx("تحقق من الاسم والصلاحيات ثم أعد المحاولة.", "Check the name and permissions, then retry.")}</small>` : `<small class="field-help">${tx("أدخل اسماً واضحاً بدون مسافات.", "Choose a clear name without spaces.")}</small>`}</div><div class="switch-row"><span class="setting-icon">${icon("lock")}</span><div class="switch-copy"><span class="row-title">${tx("مستودع خاص", "Private repository")}</span><span class="row-sub">${tx("مقيد بحسابك وصلاحيات GitHub.", "Restricted to your account and GitHub permissions.")}</span></div><button class="toggle" type="button" role="switch" aria-checked="true" aria-label="${tx("مستودع خاص", "Private repository")}" data-action="toggle"></button></div><div class="switch-row"><span class="setting-icon">${icon("code")}</span><div class="switch-copy"><span class="row-title">${tx("تثبيت Windows Workflow الآن", "Install Windows workflow now")}</span><span class="row-sub">${tx("يرفع ملف workflow المضمّن إلى الفرع الافتراضي.", "Uploads the bundled workflow to the default branch.")}</span></div><button class="toggle" type="button" role="switch" aria-checked="true" aria-label="${tx("تثبيت Workflow", "Install workflow")}" data-action="toggle"></button></div>`, "surface-hero")}${button(state === "submitting" ? tx("جارٍ الإنشاء…", "Creating…") : isSuccess ? tx("فتح إعداد المستودع", "Open repository setup") : tx("إنشاء المستودع", "Create repository"), { go: isSuccess ? "repo-setup" : null, action: isSuccess ? null : "preview-only", full: true, iconName: isSuccess ? "arrow" : "plus" })}<p class="login-privacy">${icon("shield")} ${tx("لا يغادر الرمز الشخصي جهازك إلا في طلب GitHub الآمن.", "Your personal token is sent only in the secure GitHub request.")}</p>`;
  return appShell(tx("إنشاء مستودع", "Create repository"), tx("GitHub · Windows Cloud", "GitHub · Windows Cloud"), body, { back: "repos" });
}

function renderRepoSetup(state) {
  const workflowState = state === "missing" ? "missing" : state === "repair" ? "pending" : "done";
  const secretState = state === "ready" ? "done" : state === "permission" ? "pending" : "missing";
  const error = state === "permission" ? `<div class="notice danger">${tx("لا تسمح صلاحيات GitHub الحالية بقراءة الأسرار أو تحديث Workflow.", "Current GitHub permissions do not allow secret inspection or workflow updates.")}</div>` : "";
  const body = `${fullTitle(tx("إعداد المستودع", "Repository setup"), tx("تحقق قبل التشغيل", "Verify before launch"), tx("كل حالة مرتبطة بفحص حقيقي من GitHub في التطبيق.", "Every status in the app is backed by a real GitHub check."))}${surface(`<div class="row"><div class="item-icon">${icon("folder")}</div>${repoTitle("windows-lab", tx("الفرع الافتراضي: main", "Default branch: main"))}${status(state === "ready" ? tx("جاهز", "Ready") : tx("مراجعة", "Review"), state === "ready" ? "success" : "warning")}</div>`, "surface-hero")}${surface(`<h2 class="surface-title">${tx("قائمة التجهيز", "Setup checklist")}</h2>${checkRow(tx("Windows Workflow", "Windows workflow"), ".github/workflows/windows11.yml", workflowState)}${checkRow(tx("أسرار الوصول والنسخ", "Access and backup secrets"), "ACCESS_PASSWORD · BACKUP_PASSWORD", secretState)}${checkRow(tx("TAILSCALE_AUTHKEY", "TAILSCALE_AUTHKEY"), tx("اختياري للوصول عبر RDP", "Optional for RDP access"), state === "ready" ? "done" : "missing")}`)}${error}<div class="button-row">${button(state === "ready" ? tx("فحص Workflow", "Inspect workflow") : state === "missing" ? tx("تثبيت Workflow", "Install workflow") : tx("إصلاح Workflow", "Repair workflow"), { action: "preview-only", kind: "primary", iconName: "code" })}${button(tx("إعداد الأسرار", "Configure secrets"), { go: "security", kind: "secondary", iconName: "shield" })}</div>${state === "ready" ? button(tx("إعداد جلسة Windows", "Configure Windows session"), { go: "session", full: true, iconName: "windows" }) : ""}`;
  return appShell(tx("إعداد المستودع", "Repository setup"), sampleRepo(), body, { back: "repos" });
}

function renderSecurity(state) {
  const permissionError = state === "permission";
  const success = state === "success";
  const body = `${fullTitle(tx("حماية بياناتك", "Protect your data"), tx("أسرار GitHub Actions", "GitHub Actions secrets"), tx("تُشفّر القيم بالمفتاح العام للمستودع قبل إرسالها، ثم نتحقق من وجود الأسماء.", "Values are sealed to the repository public key before upload; secret names are verified."))}${surface(`<div class="surface-header"><h2 class="surface-title">${tx("حالة التهيئة", "Configuration status")}</h2>${status(success ? tx("تم التحقق", "Verified") : permissionError ? tx("صلاحية ناقصة", "Permission needed") : tx("مطلوب", "Required"), success ? "success" : permissionError ? "danger" : "warning")}</div>${checkRow("ACCESS_PASSWORD", tx("كلمة مرور حساب Windows", "Windows account password"), success ? "done" : "missing")}${checkRow("BACKUP_PASSWORD", tx("تشفير النسخة الاحتياطية", "Backup encryption password"), success ? "done" : "missing")}${checkRow("TAILSCALE_AUTHKEY", tx("اختياري · وصول RDP", "Optional · RDP access"), "pending")}`, "surface-hero")}${permissionError ? `<div class="notice danger">${tx("تعذر الوصول إلى أسرار المستودع. راجع صلاحيات GitHub App أو استخدم PAT مناسباً.", "Secrets could not be accessed. Review GitHub App permissions or use a suitable PAT.")}</div>${button(tx("عرض خطوات الصلاحيات", "View permission steps"), { go: "permissions", kind: "secondary", full: true, iconName: "shield" })}` : ""}${surface(`<div class="field"><span class="field-label">ACCESS_PASSWORD · ${tx("مطلوب", "Required")}</span><span class="field-box"><input type="password" value="••••••••••" dir="ltr" aria-label="ACCESS_PASSWORD"><button class="icon-button" type="button" data-action="toggle-password" aria-label="${tx("إظهار أو إخفاء", "Show or hide")}">${icon("lock")}</button></span><small class="field-help">${tx("اتركه فارغاً للاحتفاظ بالسر الموجود على GitHub.", "Leave blank to keep the existing GitHub secret.")}</small></div><div class="field"><span class="field-label">BACKUP_PASSWORD · ${tx("مطلوب", "Required")}</span><span class="field-box"><input type="password" value="••••••••••" dir="ltr" aria-label="BACKUP_PASSWORD"><button class="icon-button" type="button" data-action="toggle-password" aria-label="${tx("إظهار أو إخفاء", "Show or hide")}">${icon("lock")}</button></span><small class="field-help">${tx("اتركه فارغاً للاحتفاظ بالسر الموجود على GitHub.", "Leave blank to keep the existing GitHub secret.")}</small></div><div class="field"><span class="field-label">TAILSCALE_AUTHKEY · ${tx("اختياري", "Optional")}</span><span class="field-box"><input type="password" placeholder="${tx("اختياري لتفعيل RDP", "Optional for RDP")}" dir="ltr" aria-label="TAILSCALE_AUTHKEY"><button class="icon-button" type="button" data-action="toggle-password" aria-label="${tx("إظهار أو إخفاء", "Show or hide")}">${icon("lock")}</button></span></div><div class="button-row">${button(tx("توليد كلمات قوية", "Generate strong passwords"), { action: "preview-only", kind: "secondary", iconName: "key" })}${button(tx("نسخ", "Copy"), { action: "copy", kind: "quiet", iconName: "copy" })}</div>`, "surface")}${button(state === "saving" ? tx("جارٍ الحفظ والتحقق…", "Saving and verifying…") : success ? tx("تم الحفظ والتحقق", "Saved and verified") : tx("حفظ الأسرار على GitHub", "Save secrets to GitHub"), { action: "preview-only", full: true, iconName: success ? "check" : "shield" })}<p class="login-privacy">${icon("lock")} ${tx("تُخفى القيم افتراضياً ولا تُكتب في سجل النشاط.", "Values stay masked by default and are not written to activity history.")}</p>`;
  return appShell(tx("الأمان", "Security"), sampleRepo(), body, { back: "repo-setup" });
}

function renderSession(state) {
  const noBackup = state === "no-backup";
  const fresh = state === "fresh" || state === "no-backup";
  const duration = `<div class="duration-choice"><div class="surface-header"><h3 class="surface-title">${tx("مدة الجلسة", "Session duration")}</h3><strong class="duration-value">4 ${tx("ساعات", "hours")}</strong></div><div class="duration-track"><div class="duration-line"><span style="width:75%"></span></div><div class="duration-labels"><span>1</span><span>2</span><span>3</span><span class="selected">4</span><span>5 ${tx("ساعات", "h")}</span></div></div><small class="field-help">${tx("الحد الأقصى خمس ساعات.", "Maximum duration is five hours.")}</small></div>`;
  const mode = `<div class="mode-options"><button type="button" class="mode-option ${fresh ? "" : "selected"}" data-action="mode-select" aria-pressed="${!fresh}" ${noBackup ? "disabled" : ""}><span class="mode-radio"></span><span><strong>${tx("استعادة آخر نسخة", "Restore latest backup")}</strong><small>${tx("متابعة العمل من الحالة المحفوظة.", "Continue from the saved state.")}</small></span>${status(tx("موصى به", "Recommended"), noBackup ? "neutral" : "success")}</button><button type="button" class="mode-option ${fresh ? "selected" : ""}" data-action="mode-select" aria-pressed="${fresh}"><span class="mode-radio"></span><span><strong>${tx("تثبيت جديد", "Fresh install")}</strong><small>${tx("يتجاهل النسخة السابقة؛ الملفات لن تُستعاد.", "Skips the previous backup; files will not be restored.")}</small></span>${fresh ? status(tx("مختار", "Selected"), "warning") : ""}</button></div>`;
  const body = `${fullTitle(tx("قبل التشغيل", "Before launch"), tx("خصص جلسة Windows", "Configure your Windows session"), tx("تُرسل الخيارات إلى مدخلات Workflow الفعلية.", "Options are sent to the actual workflow inputs."))}${currentDesign === "a" ? surface(`<div class="setup-step"><span class="step-number">01</span><div class="step-content">${duration}</div></div><div class="keyline"></div><div class="setup-step"><span class="step-number">02</span><div class="step-content"><h3 class="surface-title">${tx("اختيار بدء التشغيل", "Startup mode")}</h3>${mode}</div></div>`, "surface surface-hero session-wizard") : `<div class="session-aura"><div class="duration-orb"><small>${tx("المدة", "DURATION")}</small><strong>04</strong><span>${tx("ساعات", "HOURS")}</span></div>${mode}</div>`}${noBackup ? `<div class="notice danger">${tx("لا توجد نسخة مكتملة؛ خيار الاستعادة غير متاح. اختر التثبيت الجديد أو أنشئ نسخة لاحقاً.", "No complete backup is available; restore is disabled. Choose fresh install or create a backup later.")}</div>` : fresh ? `<div class="notice">${tx("التثبيت الجديد لا يستعيد ملفات النسخة الحالية.", "Fresh install does not restore files from the existing backup.")}</div>` : ""}${surface(`<div class="surface-header"><h3 class="surface-title">${tx("خيارات الوصول", "Access options")}</h3><span class="surface-note">${tx("يمكن تعديلها لكل جلسة", "Per-session controls")}</span></div>${toggleRow(tx("وصول عبر المتصفح", "Browser access"), tx("Cloudflare Tunnel", "Cloudflare Tunnel"), true, "web")}${toggleRow(tx("اتصال RDP", "RDP access"), tx("يتطلب إعداد Tailscale", "Requires Tailscale setup"), true, "rdp")}`)}${surface(`<div class="row"><div class="item-icon">${icon(fresh ? "windows" : "restore")}</div><div class="row-grow"><span class="row-title">${tx("ملخص التشغيل", "Launch summary")}</span><span class="row-sub">${sampleRepo()}</span><span class="row-sub">4 ${tx("ساعات", "hours")} · ${fresh ? tx("تثبيت جديد", "Fresh install") : tx("استعادة النسخة المكتملة الأخيرة", "Restore latest complete backup")}</span></div></div>`, "surface-hero")}${button(tx("بدء Workflow Windows", "Start Windows workflow"), { go: "progress", full: true, iconName: "windows" })}`;
  return appShell(tx("إعداد الجلسة", "Session setup"), sampleRepo(), body, { back: "home" });
}

const progressSteps = [
  ["فحص الصلاحيات", "Check permissions"], ["التحقق من الأسرار", "Verify secrets"], ["تجهيز الخادم وKVM", "Prepare runner and KVM"], ["استعادة النسخة", "Restore backup"], ["بدء Windows 11", "Start Windows 11"], ["تفعيل طرق الوصول", "Enable access routes"]
];
function renderProgress(state) {
  const fail = state === "failure";
  const queued = state === "queued";
  const done = state === "success";
  const index = queued ? 0 : fail ? 2 : done ? 5 : 3;
  const steps = progressSteps.map((step, i) => `<div class="timeline-step"><span class="timeline-dot ${i < index || done ? "done" : i === index && !fail ? "current" : ""}">${i < index || done ? "✓" : i + 1}</span><span class="timeline-copy"><strong>${step[currentLocale === "ar" ? 0 : 1]}</strong><small>${i < index || done ? tx("تم التحقق", "Verified") : i === index && !fail ? tx("جارٍ التنفيذ…", "In progress…") : tx("بانتظار الخطوة السابقة", "Waiting for previous step")}</small></span>${i === index && !fail ? status(tx("نشطة", "Active"), "neutral", true) : ""}</div>`).join("");
  const body = `${fullTitle(tx("تحديث مباشر", "Live update"), fail ? tx("تعذر تشغيل Windows", "Windows launch failed") : done ? tx("اكتمل التشغيل", "Launch complete") : tx("تجهيز جلسة Windows", "Preparing Windows session"), tx("المصدر: حالة GitHub Actions الفعلية. هذه النسب والخطوات توضيحية في النموذج فقط.", "Source: actual GitHub Actions state. Percent and example steps here are illustrative only."))}${currentDesign === "a" ? surface(`<div class="surface-header"><h2 class="surface-title">${tx("تقدم Workflow", "Workflow progress")}</h2>${status(queued ? tx("في الانتظار", "Queued") : fail ? tx("فشل", "Failed") : done ? tx("مكتمل", "Complete") : tx("قيد التنفيذ", "In progress"), fail ? "danger" : done ? "success" : "warning", !fail && !done)}</div><div class="progress-track"><div class="progress-fill" style="width:${queued ? 8 : fail ? 46 : done ? 100 : 62}%"></div></div><p class="surface-note">${queued ? tx("ينتظر Runner متاحاً…", "Waiting for an available runner…") : fail ? tx("فشلت خطوة تجهيز البيئة.", "The environment setup step failed.") : done ? tx("تم تجهيز مسار الاتصال.", "The access route is ready.") : tx("الخطوة الحالية: استعادة النسخة.", "Current step: restoring the backup.")}</p><div class="timeline">${steps}</div>`, "surface surface-hero") : surface(`<div class="progress-ring" data-value="${queued ? 8 : fail ? 46 : done ? 100 : 62}%" aria-label="${queued ? 8 : fail ? 46 : done ? 100 : 62} percent complete"></div><div class="hero-status"><span class="surface-title">${tx("حالة التشغيل", "Run status")}</span>${status(queued ? tx("بالانتظار", "Queued") : fail ? tx("فشل", "Failed") : done ? tx("مكتمل", "Complete") : tx("قيد التنفيذ", "In progress"), fail ? "danger" : done ? "success" : "warning", !fail && !done)}</div><div class="progress-track"><div class="progress-fill" style="width:${queued ? 8 : fail ? 46 : done ? 100 : 62}%"></div></div><div class="timeline">${steps}</div>`, "surface surface-hero")}${fail ? `<div class="error-panel">${statusIllustration("alert")}<h3>${tx("الخطوة الفاشلة: تجهيز الخادم", "Failed step: runner preparation")}</h3><p>${tx("افتح سجل التشغيل على GitHub لعرض التفاصيل الفعلية. لا تُعرض سجلات وهمية هنا.", "Open the GitHub run for real details. No fabricated logs are shown here.")}${sampleRepo()}</p>${button(tx("عرض التشغيل على GitHub", "Open run on GitHub"), { action: "preview-only", kind: "secondary", iconName: "external" })}</div>` : ""}${queued || !done && !fail ? button(tx("إلغاء التشغيل", "Cancel run"), { go: "stop-confirm", kind: "danger", full: true, iconName: "close" }) : done ? button(tx("عرض Windows والاتصال", "View Windows and access"), { go: "ready", full: true, iconName: "arrow" }) : button(tx("العودة إلى الإعداد", "Back to setup"), { go: "session", kind: "secondary", full: true })}`;
  return appShell(tx("تقدم التشغيل", "Run progress"), sampleRepo(), body, { back: "home", action: { label: tx("تحديث", "Refresh"), icon: "refresh" } });
}

function renderReady(state) {
  const noAccess = state === "no-access";
  const loading = state === "loading";
  const web = state === "connected" || state === "web-only" || loading;
  const rdp = state === "connected" || state === "rdp-only";
  const body = `${fullTitle(tx("الجلسة نشطة", "Session active"), tx("Windows جاهز", "Windows is ready"), tx("المعلومات أدناه مصدرها جلسة GitHub الحالية؛ القيم الموضحة أمثلة للتصميم فقط.", "Details come from the current GitHub session; values shown are design examples only."))}${surface(`<div class="hero-status"><span class="surface-title">Windows 11 Pro</span>${status(noAccess ? tx("لا يوجد وصول", "No access") : tx("قيد التشغيل", "Running"), noAccess ? "warning" : "success")}</div><div class="hero-system"><div class="windows-mark">${icon("windows")}</div><div><h2>${noAccess ? tx("النظام يعمل", "System is running") : tx("الجلسة متصلة", "Session connected")}</h2><p>${tx("الوقت المتبقي", "Time remaining")}: <b class="ltr">02:14:00</b></p></div></div><div class="progress-track"><div class="progress-fill" style="width:58%"></div></div>`, "surface-hero")}${noAccess ? `<div class="notice">${tx("Windows يعمل لكن لا يوجد مسار وصول مفعّل. فعّل Web أو RDP في إعداد الجلسة.", "Windows is running, but no access route is enabled. Enable Web or RDP in session settings.")}</div>` : ""}${surface(`<div class="surface-header"><h3 class="surface-title">${tx("طرق الاتصال", "Connection routes")}</h3>${status(loading ? tx("جارٍ التحديث", "Updating") : tx("بيانات الجلسة", "Session data"), loading ? "warning" : "neutral", loading)}</div>${web ? `<div class="connection-row"><span class="setting-icon">${icon("globe")}</span><span class="row-grow"><span class="row-title">${tx("فتح في المتصفح", "Open in browser")}</span><span class="row-sub ltr">https://••••••••</span></span>${loading ? status(tx("جارٍ الجلب", "Fetching"), "warning", true) : button(tx("فتح", "Open"), { action: "preview-only", kind: "secondary", small: true, iconName: "external" })}</div>` : ""}${rdp ? `<div class="connection-row"><span class="setting-icon">${icon("network")}</span><span class="row-grow"><span class="row-title">${tx("Tailscale · RDP", "Tailscale · RDP")}</span><span class="row-sub ltr">100.x.x.x:3389</span></span>${button(tx("نسخ", "Copy"), { action: "copy", kind: "quiet", small: true, iconName: "copy" })}</div>` : ""}<div class="keyline"></div><div class="connection-row"><span class="setting-icon">${icon("user")}</span><span class="row-grow"><span class="row-title">${tx("مستخدم Windows", "Windows user")}</span><span class="row-sub ltr">runneradmin</span></span></div><div class="connection-row"><span class="setting-icon">${icon("key")}</span><span class="row-grow"><span class="row-title">${tx("كلمة المرور", "Password")}</span><span class="row-sub">${tx("محفوظة في الذاكرة لهذه الجلسة فقط", "Held in memory for this session only")}</span></span>${button(tx("نسخ", "Copy"), { action: "copy", kind: "quiet", small: true, iconName: "copy" })}</div>`, "surface")}${button(tx("نسخ معلومات الاتصال", "Copy connection details"), { action: "copy", kind: "secondary", full: true, iconName: "copy" })}<div class="keyline"></div>${button(tx("إيقاف Windows وحفظ النسخة", "Stop Windows and save backup"), { go: "stop-confirm", kind: "danger", full: true, iconName: "backup" })}`;
  return appShell(tx("Windows جاهز", "Windows ready"), sampleRepo(), body, { back: "home", action: { label: tx("تحديث الاتصال", "Refresh connection"), icon: "refresh" } });
}

function backupItem(name, date, complete = true) {
  return `<button class="list-item backup-item" type="button" data-go="backup-detail" aria-label="${tx("تفاصيل نسخة", "Backup details")}"><span class="item-icon">${icon("backup")}</span><span class="row-grow"><span class="row-title ltr">${name}</span><span class="row-sub">${date} · 1.4 GB · 6 ${tx("أجزاء", "parts")}</span><span class="item-meta"><span class="meta-chip">GitHub Releases</span></span></span>${status(complete ? tx("مكتملة", "Complete") : tx("غير مكتملة", "Incomplete"), complete ? "success" : "danger")}</button>`;
}
function renderBackups(state) {
  let content = "";
  if (state === "no-repo") content = `<div class="empty-panel">${statusIllustration("folder")}<h3>${tx("لا يوجد مستودع محدد", "No repository selected")}</h3><p>${tx("اختر مستودع Windows أولاً لعرض نسخه.", "Choose a Windows repository to view its backups.")}</p>${button(tx("اختيار مستودع", "Choose repository"), { go: "repos", full: true, iconName: "folder" })}</div>`;
  else if (state === "empty") content = `<div class="empty-panel">${statusIllustration("backup")}<h3>${tx("لا توجد نسخ احتياطية", "No backups available")}</h3><p>${tx("تُنشأ النسخة عند الإيقاف الآمن لـWindows وتُحفظ في GitHub Releases.", "A backup is created on graceful Windows stop and stored in GitHub Releases.")}</p>${button(tx("إعداد جلسة Windows", "Configure Windows session"), { go: "session", kind: "secondary", full: true, iconName: "windows" })}</div>`;
  else if (state === "loading") content = `<div class="surface">${status(tx("جارٍ تحميل إصدارات النسخ…", "Loading backup releases…"), "neutral", true)}<div class="keyline"></div>${backupItem("loading…", "—")}</div>`;
  else if (state === "error") content = `<div class="error-panel" role="alert">${statusIllustration("alert")}<h3>${tx("تعذر تحميل النسخ", "Could not load backups")}</h3><p>${tx("أعد المحاولة وتحقق من الاتصال أو صلاحيات Releases.", "Retry and check connectivity or Release permissions.")}</p>${button(tx("إعادة المحاولة", "Retry"), { action: "preview-only", kind: "secondary", iconName: "refresh" })}</div>`;
  else if (state === "permission") content = `<div class="notice danger">${tx("لا توجد صلاحية للوصول إلى GitHub Releases.", "Permission to access GitHub Releases is missing.")}</div>${surface(`${checkRow(tx("مستودع صحيح", "Repository access"), tx("تأكد من تثبيت GitHub App", "Confirm GitHub App installation"), "pending")}${checkRow(tx("صلاحيات Contents", "Contents permission"), tx("اقرأ/اكتب حسب إعداد التطبيق", "Read/write according to app setup"), "missing")}${button(tx("عرض خطوات الصلاحيات", "View permission steps"), { go: "permissions", kind: "secondary", full: true, iconName: "shield" })}`)}`;
  else {
    const incomplete = state === "incomplete";
    content = `${surface(`<div class="backup-feature"><div class="state-illustration">${icon("backup")}</div><div class="row-grow"><span class="row-title">${tx("أحدث نسخة مكتملة", "Latest complete backup")}</span><span class="row-sub">12 Oct 2026 · 1.4 GB · 6 ${tx("أجزاء", "parts")}</span></div>${status(tx("جاهزة للاستعادة", "Ready to restore"), "success")}</div><div class="button-row">${button(tx("استعادة الأحدث", "Restore latest"), { go: "restore-confirm", iconName: "restore", full: true })}</div>`, "surface-hero")}${sectionHeading(tx("كل النسخ", "All backups"), tx("من GitHub Releases", "From GitHub Releases"))}<div class="item-list">${backupItem("windows-backup-20261010", "10 Oct 2026", true)}${backupItem("windows-backup-20261008", "08 Oct 2026", true)}${backupItem("windows-backup-20261006", "06 Oct 2026", !incomplete)}</div>`;
  }
  const body = `${fullTitle(tx("نسخ مشفرة", "Encrypted backups"), tx("النسخ والاستعادة", "Backups & restore"), tx("المصدر الفعلي: GitHub Releases للمستودع المحدد.", "Source: GitHub Releases for the selected repository."))}${surface(`<div class="row"><span class="item-icon">${icon("folder")}</span><div class="row-grow"><span class="row-title">${tx("المستودع المحدد", "Selected repository")}</span>${sampleRepo()}</div>${status(tx("3 عناصر", "3 items"), "neutral")}</div>`, "repo-context")}${content}`;
  return appShell(tx("النسخ والاستعادة", "Backups & restore"), sampleRepo(), body, { tab: "backups", action: { label: tx("تحديث النسخ", "Refresh backups"), icon: "refresh" } });
}

function activityRow(kind, title, detail, time) {
  return `<div class="activity-item"><span class="activity-symbol ${kind === "failed" ? "failed" : ""}">${icon(kind === "failed" ? "alert" : "check")}</span><span class="activity-copy"><strong>${title}</strong><small>${detail}</small></span><time class="activity-time">${time}</time></div>`;
}
function renderActivity(state) {
  const events = [
    ["success", tx("بدء تشغيل Windows 11", "Started Windows 11"), "sample-owner/windows-lab · 4h", "10:32"],
    ["success", tx("حفظ الأسرار والتحقق منها", "Saved and verified secrets"), "ACCESS_PASSWORD · BACKUP_PASSWORD", "09:58"],
    ["failed", tx("تحديث المستودعات", "Repository refresh failed"), tx("تعذر الاتصال بـGitHub", "Could not reach GitHub"), "أمس"],
    ["success", tx("اختيار مستودع", "Selected repository"), "sample-owner/windows-lab", "أمس"]
  ].filter((entry) => state === "success" ? entry[0] === "success" : state === "failed" ? entry[0] === "failed" : true);
  const content = state === "empty" ? `<div class="empty-panel">${statusIllustration("history")}<h3>${tx("لا يوجد نشاط بعد", "No activity yet")}</h3><p>${tx("ستظهر هنا العمليات الفعلية التي ينفذها التطبيق.", "Real operations performed by the app will appear here.")}</p></div>` : surface(`<div class="chips"><button class="chip ${activityFilter === "all" ? "active" : ""}" type="button" data-action="activity-all">${tx("الكل", "All")}</button><button class="chip ${activityFilter === "success" ? "active" : ""}" type="button" data-action="activity-success">${tx("ناجحة", "Successful")}</button><button class="chip ${activityFilter === "failed" ? "active" : ""}" type="button" data-action="activity-failed">${tx("فاشلة", "Failed")}</button></div>${events.length ? events.map((e) => activityRow(e[0], e[1], e[2], e[3])).join("") : `<div class="empty-panel">${statusIllustration("history")}<h3>${tx("لا توجد نتائج لهذا الفلتر", "No entries for this filter")}</h3><p>${tx("اختر فلترًا آخر لعرض سجل النشاط.", "Choose another filter to view activity.")}</p></div>`}`);
  const body = `${fullTitle(tx("عمليات التطبيق", "App operations"), tx("سجل النشاط", "Activity log"), tx("محفوظ محلياً حتى 100 حدث؛ التفاصيل الحساسة تُحذف قبل الحفظ.", "Stored locally (up to 100 entries); sensitive details are sanitized."))}${content}${state === "empty" ? "" : button(tx("مسح سجل النشاط", "Clear activity history"), { go: "clear-confirm", kind: "danger", full: true, iconName: "trash" })}`;
  return appShell(tx("النشاط", "Activity"), tx("سجل محلي", "Local history"), body, { tab: "activity", action: { label: tx("مسح السجل", "Clear history"), icon: "trash", attr: `data-go="clear-confirm"` } });
}

function renderSettings(state) {
  const noRepo = state === "no-repo";
  const body = `${fullTitle(tx("تفضيلات التطبيق", "App preferences"), tx("الإعدادات", "Settings"), tx("إدارة الحساب واللغة والمستودع دون تغيير صلاحيات GitHub.", "Manage account, language and repository without changing GitHub permissions."))}${surface(`<div class="row"><div class="avatar">S</div><div class="row-grow"><span class="row-title">Sample Account</span><span class="repo-ltr">@sample-owner</span></div>${status(tx("متصل", "Connected"), "success")}</div>`, "surface-hero")}${surface(`<div class="surface-header"><h3 class="surface-title">${tx("اللغة", "Language")}</h3>${icon("globe")}</div><div class="language-pills"><button type="button" class="chip ${currentLocale === "ar" ? "active" : ""}" data-locale="ar">العربية</button><button type="button" class="chip ${currentLocale === "en" ? "active" : ""}" data-locale="en">English</button><button type="button" class="chip" data-action="preview-only">Français</button></div>`)}${surface(`<div class="surface-header"><h3 class="surface-title">${tx("المستودع الحالي", "Current repository")}</h3></div><div class="row"><span class="item-icon">${icon("folder")}</span><div class="row-grow"><span class="repo-ltr">${noRepo ? tx("لم يتم الاختيار", "Not selected") : "sample-owner/windows-lab"}</span><span class="row-sub">${tx("اضغط لإدارة الاختيار", "Tap to manage selection")}</span></div></div>${button(tx("تغيير المستودع", "Change repository"), { go: "repos", kind: "quiet", full: true })}`)}${surface(`${settingRow("shield", tx("الأمان والأسرار", "Security & secrets"), tx("حالة القيم المطلوبة والاختيارية", "Required and optional secret status"), "security")}${settingRow("folder", tx("إعداد المستودع", "Repository setup"), tx("Workflow وصلاحيات المستودع", "Workflow and repository permissions"), "repo-setup")}${settingRow("key", tx("تسجيل الدخول برمز PAT", "Sign in with a PAT"), tx("خيار بديل للمصادقة", "Alternative sign-in method"), "pat-dialog")}${settingRow("shieldAlert", tx("صلاحيات GitHub App", "GitHub App permissions"), tx("خطوات الإصلاح والبديل PAT", "Fix steps and PAT alternative"), "permissions")}${settingRow("cloud", tx("حول NOVA", "About NOVA"), tx("Windows عبر GitHub Actions · نسخ مشفرة", "Windows via GitHub Actions · encrypted backups"))}`)}${button(tx("تسجيل الخروج", "Sign out"), { go: "logout-confirm", kind: "danger", full: true, iconName: "logout" })}`;
  return appShell(tx("الإعدادات", "Settings"), tx("الحساب والواجهة", "Account & interface"), body, { tab: "settings" });
}

function renderPermissionsDialog(state) {
  const error = state === "error";
  return `<div class="dialog-card" role="dialog" aria-modal="true" aria-labelledby="dialog-title"><div class="dialog-head"><div class="state-illustration">${icon(error ? "shieldAlert" : "shield")}</div><div><h2 id="dialog-title">${tx("صلاحيات GitHub إضافية", "Additional GitHub permissions")}</h2><p>${tx("تأكد من تثبيت GitHub App على المستودع الصحيح.", "Confirm the GitHub App is installed on the selected repository.")}</p></div></div>${error ? `<div class="notice danger">${tx("ما زال الطلب مرفوضاً. تحقق من إعدادات التثبيت ثم أعد الفحص.", "The request is still denied. Review installation settings and retry.")}</div>` : ""}${surface(`${checkRow(tx("Actions", "Actions"), tx("قراءة وكتابة تشغيل Workflow", "Workflow run read/write"), "pending")}${checkRow(tx("Secrets", "Secrets"), tx("قراءة الأسماء وكتابة الأسرار", "List names and write secrets"), "pending")}${checkRow(tx("Contents", "Contents"), tx("تثبيت أو إصلاح ملف Workflow", "Install or repair workflow file"), "pending")}`)}<p class="surface-note">${tx("البديل: استخدم PAT بنطاقات repo وworkflow المطلوبة.", "Alternative: use a PAT with the required repo and workflow scopes.")}</p><div class="dialog-actions">${button(tx("فتح تثبيت GitHub App", "Open GitHub App installation"), { action: "preview-only", kind: "primary", iconName: "external", full: true })}${button(tx("استخدام PAT", "Use a PAT"), { go: "pat-dialog", kind: "secondary", full: true })}${button(tx("إغلاق", "Close"), { go: "settings", kind: "quiet", full: true })}</div></div>`;
}

function dialogHead(glyph, title, subtitle) { return `<div class="dialog-head"><div class="state-illustration">${icon(glyph)}</div><div><h2 id="dialog-title">${title}</h2><p>${subtitle}</p></div></div>`; }
function renderDialog(id, state) {
  if (id === "permissions") return renderPermissionsDialog(state);
  if (id === "pat-dialog") {
    const error = state === "invalid" || state === "error";
    return `<div class="dialog-card" role="dialog" aria-modal="true" aria-labelledby="dialog-title">${dialogHead("key", tx("تسجيل الدخول باستخدام PAT", "Sign in with a PAT"), tx("الصق الرمز. سيبقى مخفياً ويُحفظ في التخزين الآمن.", "Paste the token. It stays masked and is stored securely."))}${field(tx("رمز GitHub الشخصي", "GitHub personal token"), "github_pat_••••••••", { type: "password", dir: "ltr", error: error ? tx("الرمز غير صالح أو لا يملك الصلاحيات المطلوبة.", "Token is invalid or lacks required scopes.") : "" })}<p class="field-help">${tx("المطلوب: صلاحيات repo وworkflow. لا تشارك هذا الرمز.", "Required scopes: repo and workflow. Never share this token.")}</p><div class="dialog-actions">${button(state === "busy" ? tx("جارٍ التحقق…", "Verifying…") : tx("التحقق وتسجيل الدخول", "Verify and sign in"), { action: "preview-only", full: true, iconName: "github" })}${button(tx("إنشاء PAT على GitHub", "Create a PAT on GitHub"), { action: "preview-only", kind: "secondary", full: true, iconName: "external" })}${button(tx("إلغاء", "Cancel"), { go: "login", kind: "quiet", full: true })}</div></div>`;
  }
  if (id === "client-secret-dialog") {
    return `<div class="dialog-card" role="dialog" aria-modal="true" aria-labelledby="dialog-title">${dialogHead("key", tx("Client Secret اختياري", "Optional client secret"), tx("يُستخدم فقط إذا طلب تدفق OAuth ذلك، ويُخزن بأمان على هذا الجهاز.", "Used only if the OAuth flow requires it; stored securely on this device."))}${field(tx("Client Secret", "Client secret"), "••••••••••••", { type: "password", dir: "ltr", help: state === "saved" ? tx("تم التخزين على الجهاز.", "Saved securely on this device.") : tx("لن يُضمّن داخل APK أو سجل النشاط.", "Not embedded in the APK or activity log.") })}${button(state === "saving" ? tx("جارٍ الحفظ…", "Saving…") : state === "saved" ? tx("محفوظ بأمان", "Saved securely") : tx("حفظ على هذا الجهاز", "Save on this device"), { action: "preview-only", full: true, iconName: "lock" })}<div class="dialog-actions">${button(tx("إدخال رابط العودة يدوياً", "Enter callback manually"), { go: "manual-callback-dialog", kind: "secondary", full: true })}${button(tx("إغلاق", "Close"), { go: "login", kind: "quiet", full: true })}</div></div>`;
  }
  if (id === "manual-callback-dialog") {
    const error = state === "invalid";
    return `<div class="dialog-card" role="dialog" aria-modal="true" aria-labelledby="dialog-title">${dialogHead("code", tx("أدخل رابط العودة", "Enter callback URL"), tx("إذا لم يفتح الرابط التطبيق، الصق الرابط كاملاً أو رمز code فقط.", "If the app did not open from the callback, paste the full URL or just the code."))}${field(tx("رابط العودة أو الرمز", "Callback URL or code"), "novawindowscloud://oauth/callback?code=…", { type: "text", dir: "ltr", error: error ? tx("لم نعثر على رمز صالح. ابدأ تسجيل الدخول مجدداً أو تحقق من الرابط.", "No valid code was found. Restart sign-in or check the URL.") : "" })}<div class="kbd-note ltr">novawindowscloud://oauth/callback?code=…&amp;state=…</div><div class="dialog-actions">${button(state === "busy" ? tx("جارٍ التحقق…", "Verifying…") : tx("متابعة", "Continue"), { action: "preview-only", full: true, iconName: "arrow" })}${button(tx("إلغاء", "Cancel"), { go: "login", kind: "quiet", full: true })}</div></div>`;
  }
  if (id === "backup-detail") {
    const incomplete = state === "incomplete";
    return `<div class="dialog-card" role="dialog" aria-modal="true" aria-labelledby="dialog-title">${dialogHead("backup", tx("تفاصيل النسخة", "Backup details"), "windows-backup-20261010")}${status(incomplete ? tx("غير مكتملة — لا يمكن استعادتها", "Incomplete — cannot restore") : tx("مكتملة وجاهزة", "Complete and ready"), incomplete ? "danger" : "success")}<div class="stat-grid"><div class="stat"><span class="stat-label">${tx("تاريخ الإنشاء", "Created")}</span><span class="stat-value">10 Oct 2026</span></div><div class="stat"><span class="stat-label">${tx("الحجم", "Total size")}</span><span class="stat-value">1.4 GB</span></div><div class="stat"><span class="stat-label">${tx("الأجزاء", "Parts")}</span><span class="stat-value">6</span></div><div class="stat"><span class="stat-label">${tx("المصدر", "Source")}</span><span class="stat-value">Release</span></div></div><p class="surface-note">${tx("المعلومات أعلاه نموذج توضيحي؛ التطبيق يعرض بيانات BackupInfo الفعلية.", "Illustrative values; the app displays actual BackupInfo metadata.")}</p><div class="dialog-actions">${button(tx("استعادة هذه النسخة", "Restore this backup"), { go: "restore-confirm", full: true, iconName: "restore" })}${button(tx("إغلاق التفاصيل", "Close details"), { go: "backups", kind: "quiet", full: true })}</div></div>`;
  }
  if (id === "restore-confirm") {
    const error = state === "error";
    return `<div class="dialog-card" role="alertdialog" aria-modal="true" aria-labelledby="dialog-title">${dialogHead(error ? "alert" : "restore", tx("استعادة نسخة Windows؟", "Restore this Windows backup?"), tx("سيُرسل Workflow جديداً ليستعيد الملفات والإعدادات من النسخة المشفرة المحددة.", "A new workflow run will restore files and settings from the selected encrypted backup."))}${error ? `<div class="notice danger">${tx("تعذر بدء الاستعادة. لم يتغير Windows؛ تحقق من Workflow والصلاحيات.", "Restore could not start. Windows is unchanged; check workflow and permissions.")}</div>` : ""}<div class="notice">${tx("قد تستبدل الاستعادة حالة Windows الحالية. تأكد من اختيار النسخة الصحيحة.", "Restoring may replace the current Windows state. Confirm the correct snapshot is selected.")}</div><div class="dialog-actions dual">${button(tx("إلغاء", "Cancel"), { go: "backups", kind: "quiet" })}${button(state === "busy" ? tx("جارٍ البدء…", "Starting…") : tx("تأكيد الاستعادة", "Confirm restore"), { go: "session", kind: "primary", iconName: "restore" })}</div></div>`;
  }
  if (id === "stop-confirm") {
    const error = state === "error";
    return `<div class="dialog-card" role="alertdialog" aria-modal="true" aria-labelledby="dialog-title">${dialogHead(error ? "alert" : "backup", tx("إيقاف Windows؟", "Stop Windows?"), tx("اختر الإيقاف الآمن أو الإلغاء الفوري.", "Choose graceful save-and-stop or immediate cancellation."))}${error ? `<div class="notice danger">${tx("لم يؤكد GitHub استلام الطلب. تحقق من حالة التشغيل قبل إعادة المحاولة.", "GitHub did not confirm the request. Check run status before retrying.")}</div>` : ""}${surface(`<div class="check-row"><span class="checkmark">✓</span><div class="row-grow"><span class="row-title">${tx("إيقاف آمن وحفظ النسخة", "Graceful stop and save")}</span><span class="row-sub">${tx("يرسل إشارة إغلاق Windows وإنشاء Backup مشفر.", "Requests Windows shutdown and an encrypted backup.")}</span></div></div><div class="check-row"><span class="checkmark missing">!</span><div class="row-grow"><span class="row-title">${tx("إلغاء فوري", "Immediate cancellation")}</span><span class="row-sub">${tx("يوقف Workflow وقد لا يحفظ النسخة الحالية.", "Cancels the workflow and may not save the current state.")}</span></div></div>`, "surface-hero")}<div class="dialog-actions">${button(state === "busy" ? tx("جارٍ الإرسال…", "Sending…") : tx("إيقاف آمن وحفظ النسخة", "Graceful stop and save"), { go: "home", full: true, iconName: "backup" })}${button(tx("إلغاء التشغيل فوراً", "Cancel run immediately"), { go: "home", kind: "danger", full: true, iconName: "close" })}${button(tx("العودة للجلسة", "Keep session open"), { go: "ready", kind: "quiet", full: true })}</div></div>`;
  }
  if (id === "clear-confirm") {
    return `<div class="dialog-card" role="alertdialog" aria-modal="true" aria-labelledby="dialog-title">${dialogHead("trash", tx("مسح سجل النشاط؟", "Clear activity history?"), tx("سيُحذف السجل المحلي المحفوظ على هذا الجهاز.", "The activity history stored locally on this device will be removed."))}<div class="notice info">${tx("لن تُحذف سجلات GitHub Actions أو Releases أو النسخ الاحتياطية.", "GitHub Actions runs, Releases, and backups will not be deleted.")}</div><div class="dialog-actions dual">${button(tx("إبقاء السجل", "Keep history"), { go: "activity", kind: "quiet" })}${button(tx("مسح محلي", "Clear locally"), { action: "clear-preview", kind: "danger", iconName: "trash" })}</div></div>`;
  }
  if (id === "logout-confirm") {
    return `<div class="dialog-card" role="alertdialog" aria-modal="true" aria-labelledby="dialog-title">${dialogHead("logout", tx("تسجيل الخروج من GitHub؟", "Sign out of GitHub?"), tx("سيُزال رمز الدخول والمستودع المحدد من حالة التطبيق على هذا الجهاز.", "The app will clear the sign-in token and selected repository from this device."))}<div class="notice">${tx("لن تُحذف المستودعات أو الأسرار أو النسخ من GitHub.", "Repositories, secrets, and backups on GitHub will not be deleted.")}</div><div class="dialog-actions dual">${button(tx("إلغاء", "Cancel"), { go: "settings", kind: "quiet" })}${button(tx("تسجيل الخروج", "Sign out"), { go: "login", kind: "danger", iconName: "logout" })}</div></div>`;
  }
  return `<div class="dialog-card">${button(tx("إغلاق", "Close"), { go: "home", kind: "quiet", full: true })}</div>`;
}

function renderPage(id, state) {
  switch (id) {
    case "startup": return renderStartup(state);
    case "login": return renderLogin(state);
    case "device": return renderDevice(state);
    case "login-success": return renderLoginSuccess(state);
    case "home": return renderHome(state);
    case "repos": return renderRepos(state);
    case "create-repo": return renderCreateRepo(state);
    case "repo-setup": return renderRepoSetup(state);
    case "security": return renderSecurity(state);
    case "session": return renderSession(state);
    case "progress": return renderProgress(state);
    case "ready": return renderReady(state);
    case "backups": return renderBackups(state);
    case "activity": return renderActivity(state);
    case "settings": return renderSettings(state);
    default: return renderHome("ready");
  }
}

function renderScreen() {
  const spec = screenMap[currentScreen];
  const state = currentStates[currentScreen] || spec.defaultState;
  const title = spec.title[currentLocale === "ar" ? 0 : 1];
  const description = spec.description[currentLocale === "ar" ? 0 : 1];
  document.getElementById("screenTitle").textContent = title;
  document.getElementById("screenGroup").textContent = spec.group;
  document.getElementById("screenDescription").textContent = description;
  document.documentElement.lang = currentLocale;
  document.documentElement.dir = dirAttr();
  document.body.classList.toggle("design-a", currentDesign === "a");
  document.body.classList.toggle("design-b", currentDesign === "b");
  document.getElementById("designA").classList.toggle("is-active", currentDesign === "a");
  document.getElementById("designB").classList.toggle("is-active", currentDesign === "b");
  document.getElementById("designA").setAttribute("aria-pressed", String(currentDesign === "a"));
  document.getElementById("designB").setAttribute("aria-pressed", String(currentDesign === "b"));
  document.getElementById("captionVariant").textContent = currentDesign === "a" ? tx("A · غرفة التحكم", "A · Control Room") : tx("B · أورورا", "B · Aurora");
  document.getElementById("captionText").textContent = tx("محتوى الصفحة قابل للتمرير. استخدم القائمة لاختبار شاشة أخرى، واختر الحالة لمراجعة التحميل والفراغ والخطأ والنجاح والتأكيد.", "Scroll within the phone. Choose another screen or state to review loading, empty, error, success and confirmation.");
  const stateSelect = document.getElementById("stateSelect");
  stateSelect.innerHTML = spec.states.map(([value, ar, en]) => `<option value="${value}" ${value === state ? "selected" : ""}>${currentLocale === "ar" ? ar : en}</option>`).join("");
  document.getElementById("localeSelect").value = currentLocale;
  const mount = document.getElementById("screenMount");
  if (spec.parent) {
    const parentSpec = screenMap[spec.parent];
    const parentState = currentStates[spec.parent] || parentSpec.defaultState;
    mount.innerHTML = `<div class="dialog-host">${renderPage(spec.parent, parentState)}<div class="dialog-layer">${renderDialog(currentScreen, state)}</div></div>`;
  } else {
    mount.innerHTML = renderPage(currentScreen, state);
  }
  mount.setAttribute("dir", dirAttr());
  document.querySelectorAll(".screen-link").forEach((element) => {
    element.classList.toggle("is-active", element.dataset.screen === currentScreen);
    element.setAttribute("aria-current", element.dataset.screen === currentScreen ? "page" : "false");
  });
  const descriptor = stateNames[state];
  if (descriptor) document.getElementById("screenDescription").textContent = `${description} · ${descriptor[currentLocale === "ar" ? 0 : 1]}`;
}

function buildScreenList() {
  const list = document.getElementById("screenList");
  let lastGroup = "";
  const groupsEn = { "البداية": "START", "المساحة الرئيسية": "MAIN APP", "الإعداد والتشغيل": "SETUP & RUN", "السجل والإدارة": "HISTORY & SETTINGS", "حوارات وتأكيدات": "DIALOGS & CONFIRMATIONS" };
  list.innerHTML = screens.map((screen, index) => {
    const groupLabel = currentLocale === "ar" ? screen.group : (groupsEn[screen.group] || screen.group);
    const heading = screen.group !== lastGroup ? `<div class="screen-group-label">${groupLabel}</div>` : "";
    lastGroup = screen.group;
    return `${heading}<button type="button" class="screen-link" data-screen="${screen.id}" aria-current="false"><span class="screen-index">${String(index + 1).padStart(2, "0")}</span><span>${screen.title[currentLocale === "ar" ? 0 : 1]}</span></button>`;
  }).join("");
  document.getElementById("screenCount").textContent = String(screens.length);
}

function showToast(message = tx("المعاينة غير متصلة؛ لا يُرسل هذا الإجراء إلى GitHub.", "Preview only; this action does not contact GitHub.")) {
  const toast = document.getElementById("toast");
  toast.textContent = message;
  toast.classList.add("is-visible");
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => toast.classList.remove("is-visible"), 2400);
}
function goToScreen(id) {
  if (!screenMap[id]) return;
  currentScreen = id;
  renderScreen();
  const mount = document.querySelector(".page-content");
  if (mount) mount.scrollTop = 0;
}

buildScreenList();
renderScreen();

document.getElementById("designA").addEventListener("click", () => { currentDesign = "a"; renderScreen(); });
document.getElementById("designB").addEventListener("click", () => { currentDesign = "b"; renderScreen(); });
document.getElementById("stateSelect").addEventListener("change", (event) => { currentStates[currentScreen] = event.target.value; renderScreen(); });
document.getElementById("localeSelect").addEventListener("change", (event) => { currentLocale = event.target.value; renderScreen(); buildScreenList(); });
document.getElementById("screenList").addEventListener("click", (event) => {
  const button = event.target.closest("[data-screen]");
  if (button) goToScreen(button.dataset.screen);
});
document.getElementById("screenMount").addEventListener("click", (event) => {
  const target = event.target.closest("button");
  if (!target) return;
  if (target.dataset.go) {
    goToScreen(target.dataset.go);
    return;
  }
  if (target.dataset.nav) {
    goToScreen(target.dataset.nav);
    return;
  }
  if (target.dataset.locale) {
    currentLocale = target.dataset.locale;
    renderScreen();
    buildScreenList();
    return;
  }
  if (target.dataset.action === "toggle") {
    target.setAttribute("aria-checked", String(target.getAttribute("aria-checked") !== "true"));
    return;
  }
  if (target.dataset.action === "toggle-password") {
    const input = target.parentElement.querySelector("input");
    if (input) input.type = input.type === "password" ? "text" : "password";
    return;
  }
  if (target.dataset.action === "activity-all") { activityFilter = "all"; currentStates.activity = "list"; renderScreen(); return; }
  if (target.dataset.action === "activity-success") { activityFilter = "success"; currentStates.activity = "success"; renderScreen(); return; }
  if (target.dataset.action === "activity-failed") { activityFilter = "failed"; currentStates.activity = "failed"; renderScreen(); return; }
  if (target.dataset.action === "mode-select") {
    const selected = target.getAttribute("aria-pressed") !== "true";
    document.querySelectorAll(".mode-option").forEach((option) => { option.classList.remove("selected"); option.setAttribute("aria-pressed", "false"); });
    target.classList.toggle("selected", selected);
    target.setAttribute("aria-pressed", String(selected));
    return;
  }
  if (target.dataset.action === "filter-chip") {
    target.parentElement.querySelectorAll(".chip").forEach((chip) => chip.classList.remove("active"));
    target.classList.add("active");
    return;
  }
  if (target.dataset.action === "request-code") { currentStates.device = "requesting"; renderScreen(); return; }
  if (target.dataset.action === "clear-preview") { currentStates.activity = "empty"; activityFilter = "all"; goToScreen("activity"); return; }
  if (target.dataset.action === "copy") {
    showToast(tx("تمت محاكاة النسخ — النموذج لا يقرأ بيانات حقيقية.", "Copy interaction previewed; no real data is read."));
    return;
  }
  showToast();
});
