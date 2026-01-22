import { addPropertyControls, ControlType } from "framer"
import { useState, useRef, useEffect, useCallback } from "react"

// ============================================
// Types & Interfaces
// ============================================
interface Food {
    name: string
    amount: string
    calories: string
}

interface TimestampFormatted {
    date: string
    time: string
    day: string
}

interface ButtonProps {
    children: React.ReactNode
    variant?: "primary" | "secondary" | "ghost"
    disabled?: boolean
    onClick?: () => void
    style?: React.CSSProperties
}

interface IconButtonProps {
    onClick?: () => void
    children: React.ReactNode
    color?: string
}

interface HeaderProps {
    left?: React.ReactNode
    center?: React.ReactNode
    right?: React.ReactNode
    background?: string
    color?: string
}

interface BottomSheetProps {
    show: boolean
    onClose: () => void
    children: React.ReactNode
}

interface CardProps {
    capturedImage: string | null
    timestamp: Date | null
    totalCalories: number
    cardRef: React.RefObject<HTMLDivElement>
    lang?: string
    theme?: string
    foods?: Food[]
    aspectRatio?: { width: number; height: number }
}

interface SheetProps {
    show: boolean
    onClose: () => void
    t: (key: string, params?: Record<string, any>) => string
    isPro?: boolean
    aiCredits?: number
    onBuyPro?: () => void
    onActivate?: () => void
}

// ============================================
// Design System
// ============================================
const DS = {
    colors: {
        black: "#000000",
        white: "#FFFFFF",
        gray: {
            50: "#FAFAFA",
            100: "#F5F5F5",
            200: "#EEEEEE",
            300: "#E0E0E0",
            400: "#BDBDBD",
            500: "#9E9E9E",
            600: "#757575",
            700: "#616161",
            800: "#424242",
            900: "#212121",
        },
        danger: "#E53935",
    },
    font: {
        body: "'Pretendard', -apple-system, BlinkMacSystemFont, system-ui, sans-serif",
        system: "-apple-system, BlinkMacSystemFont, 'SF Pro Rounded', system-ui, sans-serif",
        digital: "'DS-Digital', monospace",
        neon: "'Orbitron', sans-serif",
    },
    radius: { sm: 10, md: 14, lg: 18, xl: 22, full: 9999 },
    transition: {
        fast: "all 0.15s cubic-bezier(0.4, 0, 0.2, 1)",
        normal: "all 0.2s cubic-bezier(0.4, 0, 0.2, 1)",
        smooth: "all 0.3s cubic-bezier(0.4, 0, 0.2, 1)",
        spring: "all 0.4s cubic-bezier(0.34, 1.56, 0.64, 1)",
    },
    header: { height: 52, paddingX: 8, iconSize: 44 },
    content: { paddingX: 20 },
    fontSize: { xs: 11, sm: 13, md: 15, lg: 17, xl: 20 },
    popup: { paddingX: 24, paddingBottom: 20 },
}

let html2canvasModule: any = null
if (typeof window !== "undefined") {
    import(
        "https://cdnjs.cloudflare.com/ajax/libs/html2canvas/1.4.1/html2canvas.esm.min.js"
    )
        .then((mod) => {
            html2canvasModule = mod.default
        })
        .catch(() => {})
}

if (typeof document !== "undefined") {
    if (!document.querySelector('link[href*="pretendard"]')) {
        const l = document.createElement("link")
        l.href =
            "https://cdn.jsdelivr.net/gh/orioncactus/pretendard/dist/web/static/pretendard.css"
        l.rel = "stylesheet"
        document.head.appendChild(l)
    }
    if (!document.querySelector('link[href*="ds-digital"]')) {
        const l = document.createElement("link")
        l.href = "https://fonts.cdnfonts.com/css/ds-digital"
        l.rel = "stylesheet"
        document.head.appendChild(l)
    }
    if (!document.querySelector('link[href*="Orbitron"]')) {
        const l = document.createElement("link")
        l.href =
            "https://fonts.googleapis.com/css2?family=Orbitron:wght@400;700&display=swap"
        l.rel = "stylesheet"
        document.head.appendChild(l)
    }
    if (!document.getElementById("font-preload-container")) {
        const c = document.createElement("div")
        c.id = "font-preload-container"
        c.style.cssText =
            "position:fixed;left:-9999px;top:-9999px;visibility:hidden;"
        c.innerHTML =
            '<span style="font-family:DS-Digital,monospace;font-weight:700">00:00</span><span style="font-family:Orbitron,sans-serif;font-weight:700">00:00</span>'
        document.body?.appendChild(c)
    }
    // Global button styles for hover/active effects
    if (!document.getElementById("ms-global-styles")) {
        const style = document.createElement("style")
        style.id = "ms-global-styles"
        style.textContent = `
            * { -webkit-tap-highlight-color: transparent; }
            button { transition: all 0.15s ease; }
            button:active:not(:disabled) { transform: scale(0.97); }
            button:hover:not(:disabled) { filter: brightness(0.95); }
            input {
                transition: all 0.15s ease;
                -webkit-appearance: none;
            }
            input:focus {
                outline: none;
                background: #f8f8f8 !important;
            }
            input::placeholder {
                color: #bbb;
            }
            @keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }
            @keyframes slideIn { from { opacity: 0; transform: translateY(8px); } to { opacity: 1; transform: translateY(0); } }
        `
        document.head.appendChild(style)
    }
}

const SCREENS = {
    LANGUAGE: "language",
    CAMERA: "camera",
    ANALYZING: "analyzing",
    RESULT: "result",
    COMPLETE: "complete",
    SETTINGS: "settings",
}
const CARD_TYPES = { SIMPLE: "simple", DETAILED: "detailed" }
const CARD_THEMES = { DEFAULT: "default", DIGITAL: "digital", NEON: "neon" }
const ASPECT_RATIOS = {
    PORTRAIT: { key: "3:4", width: 3, height: 4 },
    LANDSCAPE: { key: "4:3", width: 4, height: 3 },
    SQUARE: { key: "1:1", width: 1, height: 1 },
}
const RECORD_MODE = { MANUAL: "manual", AI: "ai" }
const STORAGE = {
    apiKey: "ms_key",
    pro: "ms_pro",
    credits: "ms_credits",
    language: "ms_language",
    proCode: "ms_pro_code",
    theme: "ms_theme",
}
const DEFAULT_CREDITS = 10
const LEMON_SQUEEZY_URL =
    "https://your-store.lemonsqueezy.com/checkout/buy/your-product-id"

const detectSystemLanguage = (): string => {
    if (typeof navigator === "undefined") return "en"
    const b = (navigator.language || "en").slice(0, 2).toLowerCase()
    return ["ko", "ja", "en", "zh", "fr", "de"].includes(b) ? b : "en"
}
const validateProCode = (code: string): boolean => {
    const t = code.trim().toUpperCase()
    return (
        /^[A-Z0-9]{8}-[A-Z0-9]{8}-[A-Z0-9]{8}-[A-Z0-9]{8}$/.test(t) ||
        /^MEAL-[A-Z0-9]{4}-[A-Z0-9]{4}$/.test(t)
    )
}

const LANGUAGES = [
    { code: "ko", flag: "🇰🇷", name: "한국어" },
    { code: "ja", flag: "🇯🇵", name: "日本語" },
    { code: "en", flag: "🇺🇸", name: "English" },
    { code: "zh", flag: "🇨🇳", name: "中文" },
    { code: "fr", flag: "🇫🇷", name: "Français" },
    { code: "de", flag: "🇩🇪", name: "Deutsch" },
]

const i18n: Record<string, Record<string, string>> = {
    ko: {
        selectLanguage: "언어를 선택하세요",
        manual: "직접",
        ai: "AI",
        analyzing: "AI 분석 중",
        analyzingDesc: "음식을 인식하고 있어요",
        totalCalories: "총 칼로리",
        foodName: "음식 이름",
        amount: "양 (예: 1인분, 100g)",
        addFood: "음식 추가",
        aiCalcCalories: "AI 칼로리 계산",
        calculating: "계산 중...",
        next: "다음",
        simple: "심플",
        detailed: "상세",
        save: "저장",
        share: "공유",
        saving: "이미지 저장중",
        sharing: "공유 준비중",
        themeDefault: "기본",
        themeDigital: "디지털",
        themeNeon: "네온",
        settings: "설정",
        proActive: "Pro 활성화됨",
        freeUser: "무료 사용자",
        aiUnlimited: "AI 기능 무제한",
        aiCredits: "AI 크레딧",
        proFeatures: "Pro 기능",
        feature1: "AI 음식 자동 인식",
        feature2: "AI 칼로리 자동 계산",
        feature3: "무제한 사용",
        buyPro: "Pro 구매",
        watchAdFree: "광고 보고 무료 저장",
        thankYou: "구매해주셔서 감사합니다 💙",
        language: "언어",
        upgradeToPro: "Pro로 업그레이드",
        upgradeDesc: "AI 음식 인식과 칼로리 계산을\n무제한으로 사용하세요",
        later: "나중에",
        confirm: "확인",
        usingPro: "Pro 사용 중",
        creditsLeft: "무료 체험 {n}회 남았어요\nPro로 업그레이드하면 무제한!",
        unlimitedDesc:
            "AI 음식 인식과 칼로리 계산을\n무제한으로 사용할 수 있어요",
        saved: "저장 완료",
        shared: "공유 완료",
        proActivated: "Pro 활성화",
        searchHint:
            "음식 이름과 양을 입력하고\n돋보기 버튼을 누르면 칼로리를 검색해드려요",
        cameraError:
            "카메라 접근이 거부되었습니다.\n설정에서 권한을 허용해주세요.",
        calorieSearch: "칼로리",
        onlyFiveShown: "상세 카드에는 최근 5개 음식만 표시됩니다",
        enterProCode: "Pro 코드 입력",
        enterProCodeDesc: "구매 후 받은 라이선스 코드를 입력하세요",
        enterCode: "코드 입력하기",
        activate: "활성화",
        invalidCode: "유효하지 않은 코드입니다",
        noProCode: "코드가 없으신가요?",
        purchaseHere: "구매하기",
        cameraPermission: "카메라",
        allow: "허용",
        cameraAllowed: "카메라 권한이 허용되었습니다",
        cameraSettings: "설정에서 카메라 권한을 허용해주세요",
        proRequired: "Pro 기능",
        proRequiredDesc: "상세 카드 저장은 Pro 기능이에요",
        foodContext:
            "Korean food like bibimbap, bulgogi, kimchi. Use Korean portion terms.",
    },
    ja: {
        selectLanguage: "言語を選択してください",
        manual: "手動",
        ai: "AI",
        analyzing: "AI分析中",
        analyzingDesc: "食べ物を認識しています",
        totalCalories: "総カロリー",
        foodName: "食べ物の名前",
        amount: "量（例：1人前、100g）",
        addFood: "食べ物を追加",
        aiCalcCalories: "AIカロリー計算",
        calculating: "計算中...",
        next: "次へ",
        simple: "シンプル",
        detailed: "詳細",
        save: "保存",
        share: "共有",
        saving: "保存中",
        sharing: "共有準備中",
        themeDefault: "デフォルト",
        themeDigital: "デジタル",
        themeNeon: "ネオン",
        settings: "設定",
        proActive: "Pro有効",
        freeUser: "無料ユーザー",
        aiUnlimited: "AI機能無制限",
        aiCredits: "AIクレジット",
        proFeatures: "Pro機能",
        feature1: "AI食べ物自動認識",
        feature2: "AIカロリー自動計算",
        feature3: "無制限使用",
        buyPro: "Pro購入",
        watchAdFree: "広告を見て無料保存",
        thankYou: "ご購入ありがとうございます 💙",
        language: "言語",
        upgradeToPro: "Proにアップグレード",
        upgradeDesc: "AI食べ物認識とカロリー計算を\n無制限で使用できます",
        later: "後で",
        confirm: "確認",
        usingPro: "Pro使用中",
        creditsLeft: "無料体験残り{n}回\nProにアップグレードで無制限！",
        unlimitedDesc: "AI食べ物認識とカロリー計算を\n無制限で使用できます",
        saved: "保存完了",
        shared: "共有完了",
        proActivated: "Pro有効化",
        searchHint:
            "食べ物の名前と量を入力して\n検索ボタンを押すとカロリーを検索します",
        cameraError:
            "カメラへのアクセスが拒否されました。\n設定から許可してください。",
        calorieSearch: "カロリー",
        onlyFiveShown: "詳細カードには最新5品目のみ表示されます",
        enterProCode: "Proコード入力",
        enterProCodeDesc: "購入後に届いたライセンスコードを入力してください",
        enterCode: "コードを入力",
        activate: "有効化",
        invalidCode: "無効なコードです",
        noProCode: "コードをお持ちでないですか？",
        purchaseHere: "購入する",
        cameraPermission: "カメラ",
        allow: "許可",
        cameraAllowed: "カメラの権限が許可されました",
        cameraSettings: "設定からカメラの権限を許可してください",
        proRequired: "Pro機能",
        proRequiredDesc: "詳細カード保存はPro機能です",
        foodContext:
            "Japanese food like sushi, ramen, tempura. Use Japanese portion terms.",
    },
    en: {
        selectLanguage: "Select your language",
        manual: "Manual",
        ai: "AI",
        analyzing: "AI Analyzing",
        analyzingDesc: "Recognizing your food",
        totalCalories: "Total Calories",
        foodName: "Food name",
        amount: "Amount (e.g. 1 serving, 100g)",
        addFood: "Add food",
        aiCalcCalories: "AI Calorie Calc",
        calculating: "Calculating...",
        next: "Next",
        simple: "Simple",
        detailed: "Detailed",
        save: "Save",
        share: "Share",
        saving: "Saving",
        sharing: "Preparing",
        themeDefault: "Default",
        themeDigital: "Digital",
        themeNeon: "Neon",
        settings: "Settings",
        proActive: "Pro Active",
        freeUser: "Free User",
        aiUnlimited: "Unlimited AI",
        aiCredits: "AI Credits",
        proFeatures: "Pro Features",
        feature1: "AI food recognition",
        feature2: "AI calorie calculation",
        feature3: "Unlimited usage",
        buyPro: "Buy Pro",
        watchAdFree: "Watch Ad & Save Free",
        thankYou: "Thank you for your purchase 💙",
        language: "Language",
        upgradeToPro: "Upgrade to Pro",
        upgradeDesc:
            "Use AI food recognition and\ncalorie calculation unlimited",
        later: "Later",
        confirm: "OK",
        usingPro: "Using Pro",
        creditsLeft: "{n} free trials left\nUpgrade to Pro for unlimited!",
        unlimitedDesc:
            "Use AI food recognition and\ncalorie calculation unlimited",
        saved: "Saved",
        shared: "Shared",
        proActivated: "Pro Activated",
        searchHint:
            "Enter food name and amount,\nthen tap search to find calories",
        cameraError: "Camera access denied.\nPlease allow in settings.",
        calorieSearch: "calories",
        onlyFiveShown: "Only the latest 5 items appear on detailed card",
        enterProCode: "Enter Pro Code",
        enterProCodeDesc: "Enter the license code you received after purchase",
        enterCode: "Enter Code",
        activate: "Activate",
        invalidCode: "Invalid code",
        noProCode: "Don't have a code?",
        purchaseHere: "Purchase here",
        cameraPermission: "Camera",
        allow: "Allow",
        cameraAllowed: "Camera permission granted",
        cameraSettings: "Please allow camera access in settings",
        proRequired: "Pro Feature",
        proRequiredDesc: "Saving detailed cards is a Pro feature",
        foodContext:
            "Western food like burgers, pizza, salads. Use standard portions.",
    },
    zh: {
        selectLanguage: "请选择语言",
        manual: "手动",
        ai: "AI",
        analyzing: "AI分析中",
        analyzingDesc: "正在识别食物",
        totalCalories: "总卡路里",
        foodName: "食物名称",
        amount: "份量（例：1份、100克）",
        addFood: "添加食物",
        aiCalcCalories: "AI卡路里计算",
        calculating: "计算中...",
        next: "下一步",
        simple: "简约",
        detailed: "详细",
        save: "保存",
        share: "分享",
        saving: "保存中",
        sharing: "准备中",
        themeDefault: "默认",
        themeDigital: "数字",
        themeNeon: "霓虹",
        settings: "设置",
        proActive: "Pro已激活",
        freeUser: "免费用户",
        aiUnlimited: "AI无限制",
        aiCredits: "AI额度",
        proFeatures: "Pro功能",
        feature1: "AI食物自动识别",
        feature2: "AI卡路里自动计算",
        feature3: "无限使用",
        buyPro: "购买Pro",
        watchAdFree: "看广告免费保存",
        thankYou: "感谢您的购买 💙",
        language: "语言",
        upgradeToPro: "升级到Pro",
        upgradeDesc: "无限使用AI食物识别\n和卡路里计算",
        later: "稍后",
        confirm: "确认",
        usingPro: "正在使用Pro",
        creditsLeft: "免费体验剩余{n}次\n升级Pro享无限次！",
        unlimitedDesc: "无限使用AI食物识别\n和卡路里计算",
        saved: "已保存",
        shared: "已分享",
        proActivated: "Pro已激活",
        searchHint: "输入食物名称和份量\n点击搜索按钮查询卡路里",
        cameraError: "相机访问被拒绝\n请在设置中允许访问",
        calorieSearch: "卡路里",
        onlyFiveShown: "详细卡片仅显示最近5项食物",
        enterProCode: "输入Pro代码",
        enterProCodeDesc: "请输入购买后收到的许可证代码",
        enterCode: "输入代码",
        activate: "激活",
        invalidCode: "无效代码",
        noProCode: "没有代码？",
        purchaseHere: "点击购买",
        cameraPermission: "相机",
        allow: "允许",
        cameraAllowed: "相机权限已允许",
        cameraSettings: "请在设置中允许相机访问",
        proRequired: "Pro功能",
        proRequiredDesc: "保存详细卡片是Pro功能",
        foodContext:
            "Chinese food like dumplings, fried rice. Use Chinese portion terms.",
    },
    fr: {
        selectLanguage: "Choisissez votre langue",
        manual: "Manuel",
        ai: "IA",
        analyzing: "Analyse IA",
        analyzingDesc: "Reconnaissance des aliments",
        totalCalories: "Calories totales",
        foodName: "Nom de l'aliment",
        amount: "Quantité (ex: 1 portion)",
        addFood: "Ajouter",
        aiCalcCalories: "Calcul IA",
        calculating: "Calcul...",
        next: "Suivant",
        simple: "Simple",
        detailed: "Détaillé",
        save: "Enregistrer",
        share: "Partager",
        saving: "Enregistrement",
        sharing: "Préparation",
        themeDefault: "Défaut",
        themeDigital: "Digital",
        themeNeon: "Néon",
        settings: "Paramètres",
        proActive: "Pro Actif",
        freeUser: "Utilisateur gratuit",
        aiUnlimited: "IA illimitée",
        aiCredits: "Crédits IA",
        proFeatures: "Fonctions Pro",
        feature1: "Reconnaissance IA",
        feature2: "Calcul calories IA",
        feature3: "Utilisation illimitée",
        buyPro: "Acheter Pro",
        watchAdFree: "Voir pub & sauver gratuit",
        thankYou: "Merci pour votre achat 💙",
        language: "Langue",
        upgradeToPro: "Passer à Pro",
        upgradeDesc: "Reconnaissance IA et calcul\nde calories sans limite",
        later: "Plus tard",
        confirm: "OK",
        usingPro: "Pro actif",
        creditsLeft:
            "{n} essais gratuits restants\nPassez à Pro pour illimité!",
        unlimitedDesc: "Reconnaissance IA et calcul\nde calories sans limite",
        saved: "Enregistré",
        shared: "Partagé",
        proActivated: "Pro Activé",
        searchHint:
            "Entrez le nom et la quantité,\npuis appuyez sur rechercher",
        cameraError: "Accès caméra refusé.\nAutorisez dans les paramètres.",
        calorieSearch: "calories",
        onlyFiveShown: "Seuls les 5 derniers éléments apparaissent",
        enterProCode: "Entrer le code Pro",
        enterProCodeDesc: "Entrez le code de licence reçu après l'achat",
        enterCode: "Entrer le code",
        activate: "Activer",
        invalidCode: "Code invalide",
        noProCode: "Pas de code ?",
        purchaseHere: "Acheter ici",
        cameraPermission: "Caméra",
        allow: "Autoriser",
        cameraAllowed: "Permission caméra accordée",
        cameraSettings: "Autorisez l'accès caméra dans les paramètres",
        proRequired: "Fonction Pro",
        proRequiredDesc: "La sauvegarde détaillée est une fonction Pro",
        foodContext:
            "French food like croissant, baguette. Use French portion terms.",
    },
    de: {
        selectLanguage: "Sprache wählen",
        manual: "Manuell",
        ai: "KI",
        analyzing: "KI-Analyse",
        analyzingDesc: "Erkennung läuft",
        totalCalories: "Gesamtkalorien",
        foodName: "Lebensmittel",
        amount: "Menge (z.B. 1 Portion)",
        addFood: "Hinzufügen",
        aiCalcCalories: "KI-Berechnung",
        calculating: "Berechnung...",
        next: "Weiter",
        simple: "Einfach",
        detailed: "Detailliert",
        save: "Speichern",
        share: "Teilen",
        saving: "Speichern",
        sharing: "Vorbereiten",
        themeDefault: "Standard",
        themeDigital: "Digital",
        themeNeon: "Neon",
        settings: "Einstellungen",
        proActive: "Pro Aktiv",
        freeUser: "Kostenlos",
        aiUnlimited: "KI unbegrenzt",
        aiCredits: "KI-Guthaben",
        proFeatures: "Pro-Funktionen",
        feature1: "KI-Erkennung",
        feature2: "KI-Kalorienberechnung",
        feature3: "Unbegrenzte Nutzung",
        buyPro: "Pro kaufen",
        watchAdFree: "Werbung sehen & gratis speichern",
        thankYou: "Danke für Ihren Kauf 💙",
        language: "Sprache",
        upgradeToPro: "Auf Pro upgraden",
        upgradeDesc: "KI-Erkennung und Kalorien-\nberechnung unbegrenzt",
        later: "Später",
        confirm: "OK",
        usingPro: "Pro aktiv",
        creditsLeft: "{n} kostenlose Versuche\nUpgrade für unbegrenzt!",
        unlimitedDesc: "KI-Erkennung und Kalorien-\nberechnung unbegrenzt",
        saved: "Gespeichert",
        shared: "Geteilt",
        proActivated: "Pro Aktiviert",
        searchHint: "Name und Menge eingeben,\ndann Suche antippen",
        cameraError:
            "Kamerazugriff verweigert.\nBitte in Einstellungen erlauben.",
        calorieSearch: "Kalorien",
        onlyFiveShown: "Nur die letzten 5 Einträge werden angezeigt",
        enterProCode: "Pro-Code eingeben",
        enterProCodeDesc: "Geben Sie den Lizenzcode ein",
        enterCode: "Code eingeben",
        activate: "Aktivieren",
        invalidCode: "Ungültiger Code",
        noProCode: "Kein Code?",
        purchaseHere: "Hier kaufen",
        cameraPermission: "Kamera",
        allow: "Erlauben",
        cameraAllowed: "Kameraerlaubnis erteilt",
        cameraSettings: "Erlauben Sie den Kamerazugriff in den Einstellungen",
        proRequired: "Pro-Funktion",
        proRequiredDesc: "Detailliertes Speichern ist eine Pro-Funktion",
        foodContext:
            "German food like bratwurst, schnitzel. Use German portion terms.",
    },
}

// ============================================
// Amount Suggestions by Food Category (6 languages)
// ============================================
const AMOUNT_SUGGESTIONS: Record<string, Record<string, string[]>> = {
    ko: {
        rice: ["한공기", "반공기", "100g", "150g"],
        soup: ["1그릇", "한그릇", "200ml", "300ml"],
        drink: ["1잔", "한잔", "200ml", "500ml"],
        meat: ["100g", "150g", "200g", "1인분"],
        bread: ["1개", "한조각", "2조각", "100g"],
        noodle: ["1인분", "한그릇", "150g", "200g"],
        fruit: ["1개", "반개", "100g", "한줌"],
        salad: ["1접시", "한그릇", "100g", "150g"],
        egg: ["1개", "2개", "3개", "100g"],
        sidedish: ["조금", "적당량", "한젓가락", "50g"],
        default: ["1개", "1인분", "100g", "한접시"],
    },
    ja: {
        rice: ["1杯", "半分", "100g", "150g"],
        soup: ["1杯", "1碗", "200ml", "300ml"],
        drink: ["1杯", "200ml", "350ml", "500ml"],
        meat: ["100g", "150g", "200g", "1人前"],
        bread: ["1個", "1枚", "2枚", "100g"],
        noodle: ["1人前", "1杯", "150g", "200g"],
        fruit: ["1個", "半分", "100g", "1カップ"],
        salad: ["1皿", "1人前", "100g", "150g"],
        egg: ["1個", "2個", "3個", "100g"],
        sidedish: ["少々", "適量", "一箸", "50g"],
        default: ["1個", "1人前", "100g", "1皿"],
    },
    en: {
        rice: ["1 bowl", "1/2 bowl", "100g", "1 cup"],
        soup: ["1 bowl", "1 cup", "200ml", "300ml"],
        drink: ["1 glass", "1 cup", "200ml", "500ml"],
        meat: ["100g", "150g", "200g", "1 serving"],
        bread: ["1 slice", "2 slices", "1 piece", "100g"],
        noodle: ["1 serving", "1 bowl", "150g", "200g"],
        fruit: ["1 piece", "1/2", "100g", "1 cup"],
        salad: ["1 plate", "1 bowl", "100g", "150g"],
        egg: ["1 egg", "2 eggs", "3 eggs", "100g"],
        sidedish: ["a little", "some", "1 tbsp", "50g"],
        default: ["1 piece", "1 serving", "100g", "1 plate"],
    },
    zh: {
        rice: ["一碗", "半碗", "100g", "150g"],
        soup: ["一碗", "一杯", "200ml", "300ml"],
        drink: ["一杯", "200ml", "350ml", "500ml"],
        meat: ["100g", "150g", "200g", "一份"],
        bread: ["一个", "一片", "两片", "100g"],
        noodle: ["一份", "一碗", "150g", "200g"],
        fruit: ["一个", "半个", "100g", "一把"],
        salad: ["一盘", "一份", "100g", "150g"],
        egg: ["1个", "2个", "3个", "100g"],
        sidedish: ["少许", "适量", "一筷子", "50g"],
        default: ["一个", "一份", "100g", "一盘"],
    },
    fr: {
        rice: ["1 bol", "1/2 bol", "100g", "150g"],
        soup: ["1 bol", "1 tasse", "200ml", "300ml"],
        drink: ["1 verre", "200ml", "350ml", "500ml"],
        meat: ["100g", "150g", "200g", "1 portion"],
        bread: ["1 tranche", "2 tranches", "1 pièce", "100g"],
        noodle: ["1 portion", "1 assiette", "150g", "200g"],
        fruit: ["1 pièce", "1/2", "100g", "1 poignée"],
        salad: ["1 assiette", "1 bol", "100g", "150g"],
        egg: ["1 œuf", "2 œufs", "3 œufs", "100g"],
        sidedish: ["un peu", "modéré", "1 c.à.s", "50g"],
        default: ["1 pièce", "1 portion", "100g", "1 assiette"],
    },
    de: {
        rice: ["1 Schale", "1/2 Schale", "100g", "150g"],
        soup: ["1 Schale", "1 Tasse", "200ml", "300ml"],
        drink: ["1 Glas", "200ml", "350ml", "500ml"],
        meat: ["100g", "150g", "200g", "1 Portion"],
        bread: ["1 Scheibe", "2 Scheiben", "1 Stück", "100g"],
        noodle: ["1 Portion", "1 Teller", "150g", "200g"],
        fruit: ["1 Stück", "1/2", "100g", "1 Handvoll"],
        salad: ["1 Teller", "1 Schale", "100g", "150g"],
        egg: ["1 Ei", "2 Eier", "3 Eier", "100g"],
        sidedish: ["wenig", "etwas", "1 EL", "50g"],
        default: ["1 Stück", "1 Portion", "100g", "1 Teller"],
    },
}

// Food category detection keywords
const FOOD_CATEGORIES: Record<string, string[]> = {
    rice: ["밥", "rice", "ご飯", "ごはん", "饭", "米饭", "riz", "reis"],
    soup: ["국", "soup", "stew", "찌개", "汁", "スープ", "汤", "soupe", "suppe", "탕"],
    drink: ["juice", "주스", "커피", "coffee", "tea", "차", "우유", "milk", "ジュース", "コーヒー", "牛奶", "咖啡", "jus", "café", "saft", "kaffee", "물", "water", "콜라", "cola", "사이다"],
    meat: ["고기", "meat", "beef", "pork", "chicken", "소고기", "돼지", "닭", "肉", "鷄", "牛", "豚", "鶏", "肉", "牛肉", "viande", "poulet", "fleisch", "huhn", "삼겹살", "갈비"],
    bread: ["빵", "bread", "toast", "パン", "トースト", "面包", "pain", "brot"],
    noodle: ["면", "noodle", "pasta", "라면", "うどん", "ラーメン", "面", "麺", "pâtes", "nudeln", "국수", "스파게티", "spaghetti"],
    fruit: ["사과", "apple", "banana", "바나나", "orange", "오렌지", "りんご", "バナナ", "苹果", "香蕉", "pomme", "banane", "apfel", "과일", "fruit", "포도", "grape", "딸기", "strawberry"],
    salad: ["샐러드", "salad", "サラダ", "沙拉", "salade", "salat"],
    egg: ["계란", "달걀", "egg", "卵", "たまご", "鸡蛋", "蛋", "œuf", "ei", "eier"],
    sidedish: ["볶음", "나물", "무침", "조림", "김치", "젓갈", "장아찌", "전", "튀김", "멸치", "콩자반", "pickled", "kimchi", "漬物", "おかず", "小菜", "泡菜", "banchan"],
}

const getFoodCategory = (foodName: string): string => {
    const lower = foodName.toLowerCase()
    for (const [category, keywords] of Object.entries(FOOD_CATEGORIES)) {
        if (keywords.some(keyword => lower.includes(keyword.toLowerCase()))) {
            return category
        }
    }
    return "default"
}

const getAmountSuggestions = (foodName: string, lang: string): string[] => {
    const category = getFoodCategory(foodName)
    const langSuggestions = AMOUNT_SUGGESTIONS[lang] || AMOUNT_SUGGESTIONS.en
    return langSuggestions[category] || langSuggestions.default
}

// ============================================
// Utility Functions
// ============================================
const formatTimestamp = (
    timestamp: Date | null,
    lang: string,
    isSpecialTheme: boolean
): TimestampFormatted => {
    if (!timestamp) return { date: "", time: "", day: "" }

    const dayNames = isSpecialTheme
        ? ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
        : DAY_NAMES[lang] || DAY_NAMES.en

    const date = isSpecialTheme
        ? `${String(timestamp.getFullYear()).slice(2)}.${String(timestamp.getMonth() + 1).padStart(2, "0")}.${String(timestamp.getDate()).padStart(2, "0")}`
        : `${timestamp.getFullYear()}.${String(timestamp.getMonth() + 1).padStart(2, "0")}.${String(timestamp.getDate()).padStart(2, "0")}`

    return {
        date,
        time: `${String(timestamp.getHours()).padStart(2, "0")}:${String(timestamp.getMinutes()).padStart(2, "0")}`,
        day: dayNames[timestamp.getDay()],
    }
}

const getCardStyles = (theme: string) => {
    const isDigital = theme === CARD_THEMES.DIGITAL
    const isNeon = theme === CARD_THEMES.NEON
    const isSpecialTheme = isDigital || isNeon

    return {
        isDigital,
        isNeon,
        isSpecialTheme,
        fontStyle: isDigital ? DS.font.digital : isNeon ? DS.font.neon : "inherit",
        glowStyle: isNeon ? { textShadow: "0 0 10px rgba(255,255,255,0.8)" } : {},
    }
}

// ============================================
// Common Styles
// ============================================
const commonStyles = {
    sheetTitle: {
        fontSize: DS.fontSize.xl,
        fontWeight: 700,
        marginBottom: 6,
    } as React.CSSProperties,
    sheetDesc: {
        fontSize: DS.fontSize.sm,
        color: DS.colors.gray[600],
        lineHeight: 1.5,
        whiteSpace: "pre-wrap",
    } as React.CSSProperties,
    sheetIcon: {
        width: 52,
        height: 52,
        borderRadius: DS.radius.full,
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        margin: "0 auto 14px",
    } as React.CSSProperties,
    cardOverlay: {
        position: "absolute",
        bottom: -1,
        left: -1,
        right: -1,
        pointerEvents: "none",
    } as React.CSSProperties,
    cardContainer: {
        width: "100%",
        aspectRatio: "1/1",
        overflow: "hidden",
        position: "relative",
        background: "#000",
        fontFamily: DS.font.body,
    } as React.CSSProperties,
}

// ============================================
// Icons
// ============================================
const Icon = {
    Back: () => (
        <svg
            width="24"
            height="24"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
        >
            <path d="M15 18l-6-6 6-6" />
        </svg>
    ),
    X: () => (
        <svg
            width="24"
            height="24"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
        >
            <path d="M18 6L6 18M6 6l12 12" />
        </svg>
    ),
    Settings: () => (
        <svg
            width="22"
            height="22"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="1.5"
        >
            <circle cx="12" cy="12" r="3" />
            <path d="M19.4 15a1.65 1.65 0 00.33 1.82l.06.06a2 2 0 010 2.83 2 2 0 01-2.83 0l-.06-.06a1.65 1.65 0 00-1.82-.33 1.65 1.65 0 00-1 1.51V21a2 2 0 01-4 0v-.09a1.65 1.65 0 00-1-1.51 1.65 1.65 0 00-1.82.33l-.06.06a2 2 0 01-2.83-2.83l.06-.06a1.65 1.65 0 00.33-1.82 1.65 1.65 0 00-1.51-1H3a2 2 0 010-4h.09a1.65 1.65 0 001.51-1 1.65 1.65 0 00-.33-1.82l-.06-.06a2 2 0 012.83-2.83l.06.06a1.65 1.65 0 001.82.33H9a1.65 1.65 0 001-1.51V3a2 2 0 014 0v.09a1.65 1.65 0 001 1.51 1.65 1.65 0 001.82-.33l.06-.06a2 2 0 012.83 2.83l-.06.06a1.65 1.65 0 00-.33 1.82V9a1.65 1.65 0 001.51 1H21a2 2 0 010 4h-.09a1.65 1.65 0 00-1.51 1z" />
        </svg>
    ),
    Gallery: () => (
        <svg
            width="22"
            height="22"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="1.5"
        >
            <rect x="3" y="3" width="18" height="18" rx="3" />
            <circle cx="8.5" cy="8.5" r="1.5" fill="currentColor" />
            <path d="M21 15l-5-5L5 21" />
        </svg>
    ),
    CameraSwitch: () => (
        <svg
            width="22"
            height="22"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="1.5"
        >
            <path d="M23 4v6h-6M1 20v-6h6M3.51 9a9 9 0 0114.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0020.49 15" />
        </svg>
    ),
    Sparkle: ({ size = 14 }: { size?: number }) => (
        <svg width={size} height={size} viewBox="0 0 24 24" fill="currentColor">
            <path d="M12 0L14.59 9.41L24 12L14.59 14.59L12 24L9.41 14.59L0 12L9.41 9.41L12 0Z" />
        </svg>
    ),
    Trash: () => (
        <svg
            width="16"
            height="16"
            viewBox="0 0 24 24"
            fill="none"
            stroke={DS.colors.danger}
            strokeWidth="1.5"
        >
            <path d="M3 6h18M8 6V4a2 2 0 012-2h4a2 2 0 012 2v2M19 6v14a2 2 0 01-2 2H7a2 2 0 01-2-2V6" />
        </svg>
    ),
    Search: () => (
        <svg
            width="16"
            height="16"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="1.5"
        >
            <circle cx="11" cy="11" r="8" />
            <path d="M21 21l-4.35-4.35" />
        </svg>
    ),
    Plus: () => (
        <svg
            width="18"
            height="18"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="1.5"
        >
            <path d="M12 5v14M5 12h14" />
        </svg>
    ),
    Expand: () => (
        <svg
            width="14"
            height="14"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
        >
            <path d="M15 3h6v6M9 21H3v-6M21 3l-7 7M3 21l7-7" />
        </svg>
    ),
    Play: () => (
        <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
            <path d="M8 5v14l11-7z" />
        </svg>
    ),
}

const Button = ({
    children,
    variant = "primary",
    disabled = false,
    onClick,
    style = {},
}: any) => {
    const base: React.CSSProperties = {
        width: "100%",
        padding: "14px 20px",
        fontSize: DS.fontSize.md,
        fontWeight: 600,
        fontFamily: DS.font.body,
        border: "none",
        borderRadius: DS.radius.md,
        cursor: disabled ? "not-allowed" : "pointer",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        gap: 8,
        transition: DS.transition.fast,
        opacity: disabled ? 0.4 : 1,
    }
    const variants: Record<string, React.CSSProperties> = {
        primary: { background: DS.colors.black, color: DS.colors.white },
        secondary: { background: DS.colors.gray[100], color: DS.colors.black },
        ghost: { background: "transparent", color: DS.colors.gray[600] },
    }
    return (
        <button
            onClick={onClick}
            disabled={disabled}
            style={{ ...base, ...variants[variant], ...style }}
        >
            {children}
        </button>
    )
}

const IconButton = ({ onClick, children, color = DS.colors.black }: any) => (
    <button
        onClick={onClick}
        style={{
            width: DS.header.iconSize,
            height: DS.header.iconSize,
            borderRadius: DS.radius.full,
            background: "transparent",
            border: "none",
            cursor: "pointer",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            color,
            transition: DS.transition.fast,
            flexShrink: 0,
        }}
    >
        {children}
    </button>
)

const Header = ({
    left,
    center,
    right,
    background = DS.colors.gray[50],
    color = DS.colors.black,
}: any) => (
    <div
        style={{
            display: "flex",
            alignItems: "center",
            justifyContent: "space-between",
            height: DS.header.height,
            padding: `0 ${DS.header.paddingX}px`,
            paddingTop: "max(8px, env(safe-area-inset-top))",
            background,
            color,
        }}
    >
        <div
            style={{
                width: DS.header.iconSize,
                display: "flex",
                justifyContent: "flex-start",
            }}
        >
            {left}
        </div>
        <div style={{ flex: 1, display: "flex", justifyContent: "center" }}>
            {center}
        </div>
        <div
            style={{
                width: DS.header.iconSize,
                display: "flex",
                justifyContent: "flex-end",
            }}
        >
            {right}
        </div>
    </div>
)

const BottomSheet = ({ show, onClose, children }: BottomSheetProps) => {
    if (!show) return null
    return (
        <div
            onClick={onClose}
            style={{
                position: "fixed",
                inset: 0,
                zIndex: 2000,
                background: "rgba(0,0,0,0.5)",
                display: "flex",
                alignItems: "flex-end",
                justifyContent: "center",
                animation: "fadeIn 0.2s ease-out",
            }}
        >
            <style>{`
                @keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }
                @keyframes slideUpSpring {
                    0% { transform: translateY(100%); }
                    60% { transform: translateY(-3%); }
                    100% { transform: translateY(0); }
                }
            `}</style>
            <div
                onClick={(e) => e.stopPropagation()}
                style={{
                    width: "100%",
                    maxWidth: 480,
                    background: DS.colors.white,
                    borderRadius: `${DS.radius.xl}px ${DS.radius.xl}px 0 0`,
                    padding: `8px ${DS.popup.paddingX}px ${DS.popup.paddingBottom}px`,
                    paddingBottom: `max(${DS.popup.paddingBottom}px, calc(env(safe-area-inset-bottom) + 8px))`,
                    animation: "slideUpSpring 0.35s cubic-bezier(0.34, 1.56, 0.64, 1)",
                    boxShadow: "0 -4px 30px rgba(0,0,0,0.15)",
                }}
            >
                <div
                    style={{
                        width: 36,
                        height: 4,
                        background: DS.colors.gray[300],
                        borderRadius: 2,
                        margin: "8px auto 20px",
                    }}
                />
                {children}
            </div>
        </div>
    )
}

const ImageModal = ({ show, src, onClose }: { show: boolean; src: string | null; onClose: () => void }) => {
    if (!show || !src) return null
    return (
        <>
            <style>{`
                @keyframes modalFadeIn { from { opacity: 0; } to { opacity: 1; } }
                @keyframes modalZoomIn {
                    from { opacity: 0; transform: scale(0.9); }
                    to { opacity: 1; transform: scale(1); }
                }
            `}</style>
            <div
                onClick={onClose}
                style={{
                    position: "fixed",
                    inset: 0,
                    zIndex: 2500,
                    background: "rgba(0,0,0,0.95)",
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    padding: 20,
                    animation: "modalFadeIn 0.2s ease-out",
                }}
            >
                <button
                    onClick={onClose}
                    style={{
                        position: "absolute",
                        top: "max(16px, env(safe-area-inset-top))",
                        right: 16,
                        width: 44,
                        height: 44,
                        borderRadius: DS.radius.full,
                        background: "rgba(255,255,255,0.1)",
                        border: "none",
                        cursor: "pointer",
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                        color: "#fff",
                        transition: DS.transition.fast,
                    }}
                >
                    <Icon.X />
                </button>
                <img
                    src={src}
                    alt=""
                    style={{
                        maxWidth: "100%",
                        maxHeight: "80vh",
                        borderRadius: DS.radius.lg,
                        objectFit: "contain",
                        animation: "modalZoomIn 0.25s cubic-bezier(0.34, 1.56, 0.64, 1)",
                    }}
                />
            </div>
        </>
    )
}

const Toast = ({ show, message }: { show: boolean; message: string }) => {
    if (!show) return null
    return (
        <>
            <style>{`
                @keyframes toastPop {
                    0% { opacity: 0; transform: translate(-50%, -50%) scale(0.8); }
                    50% { transform: translate(-50%, -50%) scale(1.02); }
                    100% { opacity: 1; transform: translate(-50%, -50%) scale(1); }
                }
            `}</style>
            <div
                style={{
                    position: "fixed",
                    top: "50%",
                    left: "50%",
                    transform: "translate(-50%, -50%)",
                    background: DS.colors.black,
                    borderRadius: DS.radius.lg,
                    padding: "18px 22px",
                    display: "flex",
                    flexDirection: "column",
                    alignItems: "center",
                    gap: 8,
                    zIndex: 3000,
                    maxWidth: 260,
                    textAlign: "center",
                    animation: "toastPop 0.25s cubic-bezier(0.34, 1.56, 0.64, 1)",
                    boxShadow: "0 10px 40px rgba(0,0,0,0.3)",
                }}
            >
                <svg
                    width="22"
                    height="22"
                    viewBox="0 0 24 24"
                    fill="none"
                    style={{ stroke: "#fff", strokeWidth: 2.5 }}
                >
                    <polyline points="20 6 9 17 4 12" />
                </svg>
                <span
                    style={{
                        color: DS.colors.white,
                        fontSize: DS.fontSize.sm,
                        fontWeight: 500,
                        lineHeight: 1.5,
                        whiteSpace: "pre-wrap",
                    }}
                >
                    {message}
                </span>
            </div>
        </>
    )
}

const LoadingOverlay = ({
    show,
    message,
}: {
    show: boolean
    message: string
}) => {
    if (!show) return null
    return (
        <div
            style={{
                position: "fixed",
                inset: 0,
                background: "rgba(0,0,0,0.4)",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                zIndex: 3000,
            }}
        >
            <div
                style={{
                    background: DS.colors.white,
                    borderRadius: DS.radius.xl,
                    padding: "32px 40px",
                    display: "flex",
                    flexDirection: "column",
                    alignItems: "center",
                    gap: 14,
                }}
            >
                <style>{`
                    @keyframes bounce {
                        0%, 80%, 100% { transform: scale(0.6); opacity: 0.4; }
                        40% { transform: scale(1); opacity: 1; }
                    }
                    .bounce-dot {
                        width: 10px;
                        height: 10px;
                        background: ${DS.colors.black};
                        border-radius: 50%;
                        animation: bounce 1.4s ease-in-out infinite;
                    }
                    .bounce-dot:nth-child(1) { animation-delay: 0s; }
                    .bounce-dot:nth-child(2) { animation-delay: 0.2s; }
                    .bounce-dot:nth-child(3) { animation-delay: 0.4s; }
                `}</style>
                <div style={{ display: "flex", gap: 8 }}>
                    <div className="bounce-dot" />
                    <div className="bounce-dot" />
                    <div className="bounce-dot" />
                </div>
                <span
                    style={{
                        fontSize: DS.fontSize.sm,
                        fontWeight: 600,
                        color: DS.colors.gray[700],
                    }}
                >
                    {message}
                </span>
            </div>
        </div>
    )
}

const CaptureFlash = ({ show }: any) => {
    if (!show) return null
    return (
        <div
            style={{
                position: "fixed",
                inset: 0,
                background: "rgba(255,255,255,0.25)",
                zIndex: 1500,
            }}
        />
    )
}
const ScanLine = () => (
    <div
        style={{
            position: "absolute",
            inset: 0,
            overflow: "hidden",
            pointerEvents: "none",
        }}
    >
        <style>{`@keyframes scan { 0%, 100% { top: 15%; } 50% { top: 85%; } }`}</style>
        <div
            style={{
                position: "absolute",
                left: "10%",
                right: "10%",
                height: 1,
                background:
                    "linear-gradient(90deg, transparent, #fff, transparent)",
                animation: "scan 2s ease-in-out infinite",
            }}
        />
    </div>
)
const AdBanner = () => (
    <div
        style={{
            width: "100%",
            maxWidth: 320,
            height: 50,
            background: DS.colors.gray[200],
            borderRadius: DS.radius.sm,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            margin: "0 auto",
        }}
    >
        <span
            style={{
                fontSize: DS.fontSize.xs,
                color: DS.colors.gray[400],
                fontWeight: 500,
                letterSpacing: 1,
            }}
        >
            AD
        </span>
    </div>
)

// ============================================
// Sheet Components (extracted from duplicates)
// ============================================
const UpgradeSheet = ({
    show,
    onClose,
    t,
    onBuyPro,
}: SheetProps) => (
    <BottomSheet show={show} onClose={onClose}>
        <div style={{ textAlign: "center", marginBottom: 18 }}>
            <div style={{ ...commonStyles.sheetIcon, background: DS.colors.gray[100] }}>
                <Icon.Sparkle size={22} />
            </div>
            <div style={commonStyles.sheetTitle}>{t("upgradeToPro")}</div>
            <div style={commonStyles.sheetDesc}>{t("upgradeDesc")}</div>
        </div>
        <Button onClick={onBuyPro}>{t("buyPro")} · $2.99</Button>
        <div style={{ height: 8 }} />
        <Button variant="ghost" onClick={onClose}>{t("later")}</Button>
    </BottomSheet>
)

const CreditInfoSheet = ({
    show,
    onClose,
    t,
    isPro = false,
    aiCredits = 0,
    onBuyPro,
}: SheetProps) => (
    <BottomSheet show={show} onClose={onClose}>
        <div style={{ textAlign: "center", marginBottom: 18 }}>
            <div style={{
                ...commonStyles.sheetIcon,
                background: isPro ? DS.colors.black : DS.colors.gray[100],
                color: isPro ? "#fff" : DS.colors.black,
            }}>
                <Icon.Sparkle size={22} />
            </div>
            <div style={commonStyles.sheetTitle}>
                {isPro ? t("usingPro") : t("aiCredits")}
            </div>
            <div style={commonStyles.sheetDesc}>
                {isPro ? t("unlimitedDesc") : t("creditsLeft", { n: aiCredits })}
            </div>
        </div>
        {!isPro && (
            <>
                <Button onClick={onBuyPro}>{t("buyPro")} · $2.99</Button>
                <div style={{ height: 8 }} />
            </>
        )}
        <Button variant={isPro ? "primary" : "ghost"} onClick={onClose}>
            {isPro ? t("confirm") : t("later")}
        </Button>
    </BottomSheet>
)

const LanguageSheet = ({
    show,
    onClose,
    lang,
    onSelectLanguage,
}: {
    show: boolean
    onClose: () => void
    lang: string
    onSelectLanguage: (code: string) => void
}) => (
    <BottomSheet show={show} onClose={onClose}>
        <div style={{ textAlign: "center", marginBottom: 20 }}>
            <div style={{ fontSize: DS.fontSize.lg, fontWeight: 600 }}>
                Select your language
            </div>
        </div>
        <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 10 }}>
            {LANGUAGES.map((l) => (
                <button
                    key={l.code}
                    onClick={() => onSelectLanguage(l.code)}
                    style={{
                        display: "flex",
                        flexDirection: "column",
                        alignItems: "center",
                        gap: 6,
                        padding: "14px 8px",
                        background: lang === l.code ? DS.colors.gray[100] : DS.colors.white,
                        border: lang === l.code
                            ? `1.5px solid ${DS.colors.black}`
                            : `1.5px solid ${DS.colors.gray[200]}`,
                        borderRadius: DS.radius.md,
                        cursor: "pointer",
                    }}
                >
                    <span style={{ fontSize: 26 }}>{l.flag}</span>
                    <span style={{ fontSize: DS.fontSize.xs, fontWeight: 500 }}>{l.name}</span>
                </button>
            ))}
        </div>
    </BottomSheet>
)

const ProCodeSheet = ({
    show,
    onClose,
    t,
    proCodeInput,
    proCodeError,
    onCodeChange,
    onSubmit,
}: {
    show: boolean
    onClose: () => void
    t: (key: string) => string
    proCodeInput: string
    proCodeError: string
    onCodeChange: (value: string) => void
    onSubmit: () => void
}) => (
    <BottomSheet show={show} onClose={onClose}>
        <div style={{ textAlign: "center", marginBottom: 18 }}>
            <div style={{ fontSize: DS.fontSize.lg, fontWeight: 600 }}>{t("enterProCode")}</div>
            <div style={{ fontSize: DS.fontSize.sm, color: DS.colors.gray[500], marginTop: 6 }}>
                {t("enterProCodeDesc")}
            </div>
        </div>
        <input
            type="text"
            value={proCodeInput}
            onChange={(e) => onCodeChange(e.target.value.toUpperCase())}
            placeholder="XXXX-XXXX-XXXX-XXXX"
            style={{
                width: "100%",
                padding: "12px 14px",
                fontSize: 16,
                fontFamily: "monospace",
                textAlign: "center",
                border: `1.5px solid ${proCodeError ? DS.colors.danger : DS.colors.gray[200]}`,
                borderRadius: DS.radius.md,
                marginBottom: 8,
                boxSizing: "border-box",
                outline: "none",
            }}
        />
        {proCodeError && (
            <div style={{ color: DS.colors.danger, fontSize: DS.fontSize.sm, marginBottom: 10, textAlign: "center" }}>
                {proCodeError}
            </div>
        )}
        <Button onClick={onSubmit}>{t("activate")}</Button>
        <div style={{ height: 10 }} />
        <div style={{ textAlign: "center" }}>
            <span style={{ fontSize: DS.fontSize.sm, color: DS.colors.gray[500] }}>
                {t("noProCode")}{" "}
            </span>
            <button
                onClick={() => window.open(LEMON_SQUEEZY_URL, "_blank")}
                style={{
                    fontSize: DS.fontSize.sm,
                    color: DS.colors.black,
                    fontWeight: 600,
                    background: "none",
                    border: "none",
                    cursor: "pointer",
                    textDecoration: "underline",
                }}
            >
                {t("purchaseHere")}
            </button>
        </div>
    </BottomSheet>
)

const ProRequiredSheet = ({
    show,
    onClose,
    t,
    onBuyPro,
    onWatchAd,
}: SheetProps & { onWatchAd?: () => void }) => (
    <BottomSheet show={show} onClose={onClose}>
        <div style={{ textAlign: "center", marginBottom: 18 }}>
            <div style={{ ...commonStyles.sheetIcon, background: DS.colors.black, color: "#fff" }}>
                <Icon.Sparkle size={22} />
            </div>
            <div style={commonStyles.sheetTitle}>{t("proRequired")}</div>
            <div style={{ ...commonStyles.sheetDesc, color: DS.colors.gray[500] }}>
                {t("proRequiredDesc")}
            </div>
        </div>
        <Button onClick={onBuyPro}>{t("buyPro")} · $2.99</Button>
        <div style={{ height: 8 }} />
        <Button variant="secondary" onClick={onWatchAd}>
            <Icon.Play /> {t("watchAdFree")}
        </Button>
        <div style={{ height: 8 }} />
        <Button variant="ghost" onClick={onClose}>{t("later")}</Button>
    </BottomSheet>
)

// ============================================
// Day Names & Card Components
// ============================================
const DAY_NAMES: Record<string, string[]> = {
    ko: ["일", "월", "화", "수", "목", "금", "토"],
    ja: ["日", "月", "火", "水", "木", "金", "土"],
    en: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"],
    zh: ["日", "一", "二", "三", "四", "五", "六"],
    fr: ["Dim", "Lun", "Mar", "Mer", "Jeu", "Ven", "Sam"],
    de: ["So", "Mo", "Di", "Mi", "Do", "Fr", "Sa"],
}

const SimpleCard = ({
    capturedImage,
    timestamp,
    totalCalories,
    cardRef,
    lang = "ko",
    theme = "default",
    aspectRatio = { width: 3, height: 4 },
}: CardProps) => {
    const { isDigital, isNeon, isSpecialTheme, fontStyle, glowStyle } = getCardStyles(theme)
    const ts = formatTimestamp(timestamp, lang, isSpecialTheme)
    const mainFontSize = isDigital ? 38 : isNeon ? 26 : 32
    const subFontSize = isDigital ? 13 : isNeon ? 9 : 11
    const dateDisplay = isSpecialTheme ? `${ts.date} ${ts.day}` : `${ts.date} (${ts.day})`
    const ratioString = `${aspectRatio.width}/${aspectRatio.height}`

    return (
        <div
            ref={cardRef}
            style={{
                width: "100%",
                aspectRatio: ratioString,
                overflow: "hidden",
                position: "relative",
                background: "#000",
                fontFamily: DS.font.body,
            }}
        >
            {capturedImage && (
                <div
                    style={{
                        position: "absolute",
                        top: 0,
                        left: 0,
                        right: 0,
                        bottom: 0,
                        backgroundImage: `url(${capturedImage})`,
                        backgroundSize: "cover",
                        backgroundPosition: "center",
                    }}
                />
            )}
            <div
                style={{
                    position: "absolute",
                    bottom: -1,
                    left: -1,
                    right: -1,
                    height: "52%",
                    background:
                        "linear-gradient(to top, rgba(0,0,0,0.8) 0%, transparent 100%)",
                    pointerEvents: "none",
                }}
            />
            <div
                style={{
                    position: "absolute",
                    bottom: 20,
                    left: 20,
                    right: 20,
                    color: "#fff",
                    display: "flex",
                    justifyContent: "space-between",
                    alignItems: "flex-end",
                }}
            >
                <div>
                    <div
                        style={{
                            fontFamily: fontStyle,
                            fontSize: mainFontSize,
                            fontWeight: 700,
                            letterSpacing: isSpecialTheme ? 1 : -1,
                            lineHeight: 1,
                            ...glowStyle,
                        }}
                    >
                        {ts.time}
                    </div>
                    <div
                        style={{
                            fontFamily: isSpecialTheme ? fontStyle : "inherit",
                            fontSize: subFontSize,
                            opacity: 0.6,
                            marginTop: 4,
                        }}
                    >
                        {dateDisplay}
                    </div>
                </div>
                <div style={{ textAlign: "right" }}>
                    <div
                        style={{
                            fontFamily: fontStyle,
                            fontSize: mainFontSize,
                            fontWeight: 700,
                            letterSpacing: isSpecialTheme ? 1 : -1,
                            lineHeight: 1,
                            ...glowStyle,
                        }}
                    >
                        {totalCalories}
                    </div>
                    <div
                        style={{
                            fontFamily: isSpecialTheme ? fontStyle : "inherit",
                            fontSize: subFontSize,
                            opacity: 0.6,
                            marginTop: 4,
                        }}
                    >
                        KCAL
                    </div>
                </div>
            </div>
        </div>
    )
}

const DetailedCard = ({
    capturedImage,
    timestamp,
    totalCalories,
    foods = [],
    cardRef,
    lang = "ko",
    theme = "default",
    aspectRatio = { width: 3, height: 4 },
}: CardProps) => {
    const { isDigital, isNeon, isSpecialTheme, fontStyle, glowStyle } = getCardStyles(theme)
    const ts = formatTimestamp(timestamp, lang, isSpecialTheme)
    const displayFoods = foods.slice(0, 5)
    const mainFontSize = isDigital ? 30 : isNeon ? 24 : 26
    const subFontSize = isDigital ? 12 : isNeon ? 9 : 10
    const dateDisplay = isSpecialTheme ? `${ts.date} ${ts.day}` : `${ts.date} (${ts.day})`
    const ratioString = `${aspectRatio.width}/${aspectRatio.height}`

    return (
        <div
            ref={cardRef}
            style={{
                width: "100%",
                aspectRatio: ratioString,
                overflow: "hidden",
                position: "relative",
                background: "#000",
                fontFamily: DS.font.body,
            }}
        >
            {capturedImage && (
                <div
                    style={{
                        position: "absolute",
                        top: 0,
                        left: 0,
                        right: 0,
                        bottom: 0,
                        backgroundImage: `url(${capturedImage})`,
                        backgroundSize: "cover",
                        backgroundPosition: "center",
                    }}
                />
            )}
            <div
                style={{
                    position: "absolute",
                    bottom: -1,
                    left: -1,
                    right: -1,
                    height: "72%",
                    background:
                        "linear-gradient(to top, rgba(0,0,0,0.9) 0%, transparent 100%)",
                    pointerEvents: "none",
                }}
            />
            <div
                style={{
                    position: "absolute",
                    bottom: 16,
                    left: 16,
                    right: 16,
                    color: "#fff",
                }}
            >
                <div style={{ marginBottom: 12 }}>
                    {displayFoods.map((food: any, i: number) => (
                        <div
                            key={i}
                            style={{
                                display: "flex",
                                justifyContent: "space-between",
                                padding: "5px 0",
                                fontSize: 13,
                                borderBottom:
                                    i < displayFoods.length - 1
                                        ? "1px solid rgba(255,255,255,0.1)"
                                        : "none",
                            }}
                        >
                            <span style={{ opacity: 0.85 }}>{food.name}</span>
                            <span
                                style={{
                                    fontFamily: isSpecialTheme
                                        ? fontStyle
                                        : "inherit",
                                    fontWeight: 600,
                                }}
                            >
                                {food.calories}
                            </span>
                        </div>
                    ))}
                    {foods.length > 5 && (
                        <div
                            style={{
                                fontSize: 11,
                                opacity: 0.4,
                                textAlign: "center",
                                marginTop: 4,
                            }}
                        >
                            +{foods.length - 5}
                        </div>
                    )}
                </div>
                <div
                    style={{
                        display: "flex",
                        justifyContent: "space-between",
                        alignItems: "flex-end",
                        paddingTop: 10,
                        borderTop: "1px solid rgba(255,255,255,0.15)",
                    }}
                >
                    <div>
                        <div
                            style={{
                                fontFamily: fontStyle,
                                fontSize: mainFontSize,
                                fontWeight: 700,
                                letterSpacing: isSpecialTheme ? 1 : -1,
                                lineHeight: 1,
                                ...glowStyle,
                            }}
                        >
                            {ts.time}
                        </div>
                        <div
                            style={{
                                fontFamily: isSpecialTheme
                                    ? fontStyle
                                    : "inherit",
                                fontSize: subFontSize,
                                opacity: 0.5,
                                marginTop: 3,
                            }}
                        >
                            {dateDisplay}
                        </div>
                    </div>
                    <div style={{ textAlign: "right" }}>
                        <div
                            style={{
                                fontFamily: fontStyle,
                                fontSize: mainFontSize,
                                fontWeight: 700,
                                letterSpacing: isSpecialTheme ? 1 : -1,
                                lineHeight: 1,
                                ...glowStyle,
                            }}
                        >
                            {totalCalories}
                        </div>
                        <div
                            style={{
                                fontFamily: isSpecialTheme
                                    ? fontStyle
                                    : "inherit",
                                fontSize: subFontSize,
                                opacity: 0.5,
                                marginTop: 3,
                            }}
                        >
                            KCAL
                        </div>
                    </div>
                </div>
            </div>
        </div>
    )
}

export default function MealStamp(props: any) {
    const { apiKeyDefault = "" } = props
    const [screen, setScreen] = useState(SCREENS.LANGUAGE)
    const [lang, setLang] = useState("ko")
    const [recordMode, setRecordMode] = useState(RECORD_MODE.AI)
    const [capturedImage, setCapturedImage] = useState<string | null>(null)
    const [foods, setFoods] = useState<any[]>([])
    const [apiKey, setApiKey] = useState(apiKeyDefault)
    const [cameraError, setCameraError] = useState<string | null>(null)
    const [timestamp, setTimestamp] = useState<Date | null>(null)
    const [facingMode, setFacingMode] = useState<"environment" | "user">(
        "environment"
    )
    const [selectedCardType, setSelectedCardType] = useState(CARD_TYPES.SIMPLE)
    const [selectedTheme, setSelectedTheme] = useState(CARD_THEMES.DEFAULT)
    const [selectedAspectRatio, setSelectedAspectRatio] = useState(ASPECT_RATIOS.PORTRAIT)
    const [isCalculating, setIsCalculating] = useState(false)
    const [isFrontCamera, setIsFrontCamera] = useState(false)
    const [showToast, setShowToast] = useState(false)
    const [toastMessage, setToastMessage] = useState("")
    const [isSaving, setIsSaving] = useState(false)
    const [isPro, setIsPro] = useState(false)
    const [aiCredits, setAiCredits] = useState(DEFAULT_CREDITS)
    const [sessionPaid, setSessionPaid] = useState(false)
    const [showUpgrade, setShowUpgrade] = useState(false)
    const [showCreditInfo, setShowCreditInfo] = useState(false)
    const [showFlash, setShowFlash] = useState(false)
    const [showImageModal, setShowImageModal] = useState(false)
    const [showLanguageSheet, setShowLanguageSheet] = useState(false)
    const [showProCodeSheet, setShowProCodeSheet] = useState(false)
    const [proCodeInput, setProCodeInput] = useState("")
    const [proCodeError, setProCodeError] = useState("")
    const [savingType, setSavingType] = useState<"save" | "share" | null>(null)
    const [keyboardHeight, setKeyboardHeight] = useState(0)
    const [focusedFoodIndex, setFocusedFoodIndex] = useState<number | null>(null)

    const videoRef = useRef<HTMLVideoElement>(null)
    const previewVideoRef = useRef<HTMLVideoElement>(null)
    const canvasRef = useRef<HTMLCanvasElement>(null)
    const fileInputRef = useRef<HTMLInputElement>(null)
    const simpleCardRef = useRef<HTMLDivElement>(null)
    const detailedCardRef = useRef<HTMLDivElement>(null)
    const streamRef = useRef<MediaStream | null>(null)
    const foodInputRefs = useRef<(HTMLInputElement | null)[]>([])

    useEffect(() => {
        const k = localStorage.getItem(STORAGE.apiKey)
        if (k) setApiKey(k)
        const savedProCode = localStorage.getItem(STORAGE.proCode)
        const savedPro = localStorage.getItem(STORAGE.pro) === "true"
        setIsPro(
            savedPro || (savedProCode ? validateProCode(savedProCode) : false)
        )
        const c = localStorage.getItem(STORAGE.credits)
        setAiCredits(c ? parseInt(c) : DEFAULT_CREDITS)
        const savedTheme = localStorage.getItem(STORAGE.theme)
        if (savedTheme) setSelectedTheme(savedTheme)
        const savedLang = localStorage.getItem(STORAGE.language)
        if (savedLang) {
            setLang(savedLang)
            setScreen(SCREENS.CAMERA)
        } else {
            setLang(detectSystemLanguage())
        }
    }, [])

    // Keyboard height detection for mobile
    useEffect(() => {
        if (typeof window === "undefined" || !window.visualViewport) return
        const viewport = window.visualViewport
        let initialHeight = viewport.height

        const handleResize = () => {
            // Use initial viewport height as reference for keyboard detection
            if (viewport.height < initialHeight - 50) {
                setKeyboardHeight(initialHeight - viewport.height)
            } else {
                setKeyboardHeight(0)
                initialHeight = viewport.height // Update reference when keyboard is closed
            }
        }
        viewport.addEventListener("resize", handleResize)
        return () => {
            viewport.removeEventListener("resize", handleResize)
        }
    }, [])

    const t = (key: string, params?: Record<string, any>) => {
        let text = i18n[lang]?.[key] || i18n.en[key] || key
        if (params)
            Object.entries(params).forEach(([k, v]) => {
                text = text.replace(`{${k}}`, String(v))
            })
        return text
    }
    const selectLanguage = (code: string) => {
        setLang(code)
        localStorage.setItem(STORAGE.language, code)
        setScreen(SCREENS.CAMERA)
    }
    const updateCredits = (n: number) => {
        setAiCredits(n)
        localStorage.setItem(STORAGE.credits, String(n))
    }
    const toast = (msg: string, duration = 1200) => {
        setToastMessage(msg)
        setShowToast(true)
        setTimeout(() => setShowToast(false), duration)
    }
    const canUseAI = isPro || aiCredits > 0

    const saveState = useCallback(() => {
        if (screen === SCREENS.RESULT || screen === SCREENS.COMPLETE) {
            sessionStorage.setItem(
                "ms_state",
                JSON.stringify({
                    screen,
                    foods,
                    capturedImage,
                    timestamp: timestamp?.toISOString(),
                    selectedCardType,
                })
            )
        }
    }, [screen, foods, capturedImage, timestamp, selectedCardType])
    useEffect(() => {
        const saved = sessionStorage.getItem("ms_state")
        if (saved) {
            try {
                const s = JSON.parse(saved)
                if (s.screen) setScreen(s.screen)
                if (s.foods) setFoods(s.foods)
                if (s.capturedImage) setCapturedImage(s.capturedImage)
                if (s.timestamp) setTimestamp(new Date(s.timestamp))
                if (s.selectedCardType) setSelectedCardType(s.selectedCardType)
            } catch {}
        }
    }, [])
    useEffect(() => {
        const h = () => {
            if (document.visibilityState === "hidden") saveState()
        }
        document.addEventListener("visibilitychange", h)
        window.addEventListener("beforeunload", saveState)
        return () => {
            document.removeEventListener("visibilitychange", h)
            window.removeEventListener("beforeunload", saveState)
        }
    }, [saveState])

    const startCamera = useCallback(async () => {
        try {
            setCameraError(null)
            if (streamRef.current)
                streamRef.current.getTracks().forEach((t) => t.stop())
            const stream = await navigator.mediaDevices.getUserMedia({
                video: {
                    facingMode,
                    width: { ideal: 1920 },
                    height: { ideal: 1920 },
                },
                audio: false,
            })
            streamRef.current = stream
            if (videoRef.current) videoRef.current.srcObject = stream
            if (previewVideoRef.current)
                previewVideoRef.current.srcObject = stream
            setIsFrontCamera(facingMode === "user")
        } catch {
            setCameraError(t("cameraError"))
        }
    }, [facingMode])
    const stopCamera = useCallback(() => {
        if (streamRef.current) {
            streamRef.current.getTracks().forEach((t) => t.stop())
            streamRef.current = null
        }
    }, [])
    useEffect(() => {
        if (screen === SCREENS.CAMERA || screen === SCREENS.LANGUAGE)
            startCamera()
        else stopCamera()
        return stopCamera
    }, [screen, startCamera, stopCamera])
    useEffect(() => {
        if (screen === SCREENS.CAMERA || screen === SCREENS.LANGUAGE)
            startCamera()
    }, [facingMode])

    const capturePhoto = async () => {
        if (!previewVideoRef.current || !canvasRef.current) return
        setShowFlash(true)
        setTimeout(() => setShowFlash(false), 200)
        const video = previewVideoRef.current,
            canvas = canvasRef.current,
            ctx = canvas.getContext("2d")!
        const vw = video.videoWidth,
            vh = video.videoHeight,
            size = Math.min(vw, vh),
            out = Math.min(1024, size)
        canvas.width = out
        canvas.height = out
        if (isFrontCamera) {
            ctx.translate(out, 0)
            ctx.scale(-1, 1)
        }
        ctx.drawImage(
            video,
            (vw - size) / 2,
            (vh - size) / 2,
            size,
            size,
            0,
            0,
            out,
            out
        )
        if (isFrontCamera) ctx.setTransform(1, 0, 0, 1, 0, 0)
        const imageData = canvas.toDataURL("image/jpeg", 0.92)
        setCapturedImage(imageData)
        setTimestamp(new Date())
        setTimeout(() => {
            const useAI = recordMode === RECORD_MODE.AI
            if (!useAI) {
                setFoods([{ name: "", amount: "", calories: "" }])
                setScreen(SCREENS.RESULT)
                return
            }
            if (!canUseAI) {
                setShowUpgrade(true)
                return
            }
            if (!isPro) {
                updateCredits(Math.max(0, aiCredits - 1))
                setSessionPaid(true)
            }
            analyzeImage(imageData)
        }, 150)
    }

    const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0]
        if (!file) return
        const reader = new FileReader()
        reader.onload = (ev) => {
            const img = new Image()
            img.onload = () => {
                const canvas = canvasRef.current!,
                    size = Math.min(img.width, img.height),
                    out = Math.min(1024, size)
                canvas.width = out
                canvas.height = out
                const ctx = canvas.getContext("2d")!
                ctx.drawImage(
                    img,
                    (img.width - size) / 2,
                    (img.height - size) / 2,
                    size,
                    size,
                    0,
                    0,
                    out,
                    out
                )
                const imageData = canvas.toDataURL("image/jpeg", 0.92)
                setCapturedImage(imageData)
                setTimestamp(new Date())
                const useAI = recordMode === RECORD_MODE.AI
                if (!useAI) {
                    setFoods([{ name: "", amount: "", calories: "" }])
                    setScreen(SCREENS.RESULT)
                    return
                }
                if (!canUseAI) {
                    setShowUpgrade(true)
                    return
                }
                if (!isPro) {
                    updateCredits(Math.max(0, aiCredits - 1))
                    setSessionPaid(true)
                }
                analyzeImage(imageData)
            }
            img.src = ev.target?.result as string
        }
        reader.readAsDataURL(file)
    }

    const analyzeImage = async (imageData: string) => {
        setScreen(SCREENS.ANALYZING)
        if (!apiKey) {
            setTimeout(() => {
                setFoods([
                    {
                        name: "API 키를 설정해주세요",
                        amount: "",
                        calories: "",
                    },
                ])
                setScreen(SCREENS.RESULT)
            }, 600)
            return
        }
        const controller = new AbortController(),
            timeout = setTimeout(() => controller.abort(), 30000)
        const foodContext = t("foodContext"),
            langNames: Record<string, string> = {
                ko: "Korean",
                ja: "Japanese",
                en: "English",
                zh: "Chinese",
                fr: "French",
                de: "German",
            },
            outputLang = langNames[lang] || "English"
        try {
            const response = await fetch(
                "https://api.openai.com/v1/chat/completions",
                {
                    method: "POST",
                    headers: {
                        "Content-Type": "application/json",
                        Authorization: `Bearer ${apiKey}`,
                    },
                    signal: controller.signal,
                    body: JSON.stringify({
                        model: "gpt-4o",
                        messages: [
                            {
                                role: "system",
                                content: `You are an expert food recognition assistant specialized in identifying dishes from photos. Your task:
1. Carefully analyze the image and identify ALL visible food items
2. Consider cooking methods, ingredients, and regional variations
3. Be specific with dish names (e.g., "김치찌개" not just "soup", "카르보나라 파스타" not just "pasta")
4. IMPORTANT for portions: Assume standard restaurant/home serving sizes. Use concrete measurements like "1인분", "1공기", "200g", "1개", "1컵". NEVER use vague terms like "소량", "약간", "조금". If it looks like a normal meal portion, say "1인분".
5. ${foodContext}
6. Output food names in ${outputLang}
7. Return ONLY valid JSON: {"foods":[{"name":"specific dish name","amount":"1인분/200g/1개 etc","calories":""}]}`,
                            },
                            {
                                role: "user",
                                content: [
                                    {
                                        type: "text",
                                        text: "Identify all food items in this image. Be specific with dish names and estimate portions accurately. Consider the cultural context and cooking style visible. JSON only.",
                                    },
                                    {
                                        type: "image_url",
                                        image_url: {
                                            url: imageData,
                                            detail: "low",
                                        },
                                    },
                                ],
                            },
                        ],
                        max_tokens: 1000,
                        temperature: 0.1,
                    }),
                }
            )
            clearTimeout(timeout)
            const data = await response.json()
            if (data.error) throw new Error(data.error.message)
            const content = data.choices?.[0]?.message?.content || "{}",
                parsed = JSON.parse(
                    content.replace(/```json\n?|\n?```/g, "").trim()
                )
            const nextFoods =
                parsed.foods || (Array.isArray(parsed) ? parsed : [])
            setFoods(
                (nextFoods.length
                    ? nextFoods
                    : [{ name: "", amount: "", calories: "" }]
                ).map((f: any) => ({
                    name: String(f?.name ?? "").trim(),
                    amount: String(f?.amount ?? "").trim(),
                    calories: "",
                }))
            )
            setScreen(SCREENS.RESULT)
        } catch (e: any) {
            clearTimeout(timeout)
            setFoods([
                {
                    name: e?.name === "AbortError" ? "시간 초과" : "분석 실패",
                    amount: "",
                    calories: "",
                },
            ])
            setScreen(SCREENS.RESULT)
        }
    }

    const calculateCalories = async () => {
        if (!apiKey) return alert("설정에서 API 키를 입력해주세요.")
        if (!isPro && !sessionPaid && aiCredits <= 0) {
            setShowUpgrade(true)
            return
        }
        const toCalc = foods.filter((f) => f.name?.trim() && !f.calories)
        if (!toCalc.length) return alert("계산할 음식이 없습니다.")
        if (!isPro && !sessionPaid) {
            updateCredits(Math.max(0, aiCredits - 1))
            setSessionPaid(true)
        }
        setIsCalculating(true)
        const controller = new AbortController(),
            timeout = setTimeout(() => controller.abort(), 30000)
        try {
            const list = toCalc
                .map(
                    (f, i) =>
                        `${i + 1}. ${f.name}${f.amount ? ` (${f.amount})` : ""}`
                )
                .join("\n")
            const response = await fetch(
                "https://api.openai.com/v1/chat/completions",
                {
                    method: "POST",
                    headers: {
                        "Content-Type": "application/json",
                        Authorization: `Bearer ${apiKey}`,
                    },
                    signal: controller.signal,
                    body: JSON.stringify({
                        model: "gpt-4o",
                        messages: [
                            {
                                role: "system",
                                content:
                                    "Estimate calories for each food item. Return JSON array of integers only. Example: [320, 150]",
                            },
                            { role: "user", content: list },
                        ],
                        max_tokens: 200,
                        temperature: 0.2,
                    }),
                }
            )
            clearTimeout(timeout)
            const data = await response.json()
            if (data.error) throw new Error(data.error.message)
            const cals = JSON.parse(
                (data.choices?.[0]?.message?.content || "[]")
                    .replace(/```json\n?|\n?```/g, "")
                    .trim()
            )
            let idx = 0
            setFoods(
                foods.map((f) => {
                    if (f.name?.trim() && !f.calories && idx < cals.length)
                        return { ...f, calories: String(cals[idx++]) }
                    return f
                })
            )
        } catch (e: any) {
            alert(e?.name === "AbortError" ? "시간 초과" : "계산 실패")
        } finally {
            setIsCalculating(false)
        }
    }

    const totalCalories = foods.reduce(
        (s, f) => s + (parseInt(f.calories) || 0),
        0
    )
    const hasEmptyCalories = foods.some((f) => f.name?.trim() && !f.calories)
    const canComplete =
        foods.length > 0 && foods.every((f) => f.name?.trim() && f.calories)
    const handleFoodChange = (i: number, field: string, val: string) => {
        const updated = [...foods]
        if (field === "calories")
            updated[i] = { ...updated[i], calories: val.replace(/[^0-9]/g, "") }
        else updated[i] = { ...updated[i], [field]: val, calories: "" }
        setFoods(updated)
    }
    const searchCalories = (name: string, amount: string) => {
        if (!name?.trim()) {
            toast(t("searchHint"), 2500)
            return
        }
        const query = `${name} ${amount} ${t("calorieSearch")}`.trim()
        saveState()
        window.open(
            `https://www.google.com/search?q=${encodeURIComponent(query)}`,
            "_blank"
        )
    }
    const resetToCamera = () => {
        sessionStorage.removeItem("ms_state")
        setCapturedImage(null)
        setFoods([])
        setTimestamp(null)
        setSelectedCardType(CARD_TYPES.SIMPLE)
        setSessionPaid(false)
        setScreen(SCREENS.CAMERA)
    }

    const getHtml2Canvas = async () => {
        if (html2canvasModule) return html2canvasModule
        const mod = await import(
            "https://cdnjs.cloudflare.com/ajax/libs/html2canvas/1.4.1/html2canvas.esm.min.js"
        )
        html2canvasModule = mod.default
        return html2canvasModule
    }

    const saveCard = async () => {
        const ref =
            selectedCardType === CARD_TYPES.SIMPLE
                ? simpleCardRef
                : detailedCardRef
        if (!ref.current || isSaving) return
        setSavingType("save")
        setIsSaving(true)
        try {
            const html2canvas = await getHtml2Canvas()
            const canvas = await html2canvas(ref.current, {
                scale: 2,
                useCORS: true,
                allowTaint: true,
                backgroundColor: "#000",
                logging: false,
            })
            const isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent)
            if (isIOS && navigator.share) {
                canvas.toBlob(async (blob: Blob | null) => {
                    if (!blob) return
                    try {
                        await navigator.share({
                            files: [
                                new File([blob], "mealstamp.png", {
                                    type: "image/png",
                                }),
                            ],
                        })
                        toast(t("saved"))
                    } catch {}
                }, "image/png")
            } else {
                const link = document.createElement("a")
                link.download = `mealstamp_${Date.now()}.png`
                link.href = canvas.toDataURL("image/png")
                link.click()
                toast(t("saved"))
            }
        } catch {
            alert("Save failed")
        } finally {
            setIsSaving(false)
            setSavingType(null)
        }
    }

    const shareCard = async () => {
        const ref =
            selectedCardType === CARD_TYPES.SIMPLE
                ? simpleCardRef
                : detailedCardRef
        if (!ref.current || isSaving) return
        setSavingType("share")
        setIsSaving(true)
        try {
            const html2canvas = await getHtml2Canvas()
            const canvas = await html2canvas(ref.current, {
                scale: 2,
                useCORS: true,
                allowTaint: true,
                backgroundColor: "#000",
                logging: false,
            })
            canvas.toBlob(async (blob: Blob | null) => {
                if (!blob) return
                const file = new File([blob], "mealstamp.png", {
                    type: "image/png",
                })
                if (
                    navigator.share &&
                    navigator.canShare?.({ files: [file] })
                ) {
                    try {
                        await navigator.share({ files: [file] })
                        toast(t("shared"))
                    } catch {}
                } else await saveCard()
            }, "image/png")
        } catch {
            alert("Share failed")
        } finally {
            setIsSaving(false)
            setSavingType(null)
        }
    }

    const watchAdAndSave = async () => {
        toast("광고 기능 준비 중", 1500)
    }

    const container: React.CSSProperties = {
        width: "100%",
        height: "100%",
        position: "fixed",
        inset: 0,
        background: DS.colors.gray[50],
        fontFamily: DS.font.body,
        color: DS.colors.black,
        display: "flex",
        flexDirection: "column",
        overflow: "hidden",
        touchAction: "manipulation",
        WebkitTextSizeAdjust: "100%",
    }
    const input: React.CSSProperties = {
        fontSize: 16,
        fontFamily: DS.font.body,
        border: "none",
        outline: "none",
        background: DS.colors.gray[100],
        borderRadius: DS.radius.sm,
        boxSizing: "border-box",
        minWidth: 0,
        touchAction: "manipulation",
    }

    // CAMERA SCREEN
    if (screen === SCREENS.CAMERA || screen === SCREENS.LANGUAGE) {
        const showLangSheet = screen === SCREENS.LANGUAGE || showLanguageSheet
        return (
            <div style={{ ...container, background: "#000" }}>
                <Toast show={showToast} message={toastMessage} />
                <CaptureFlash show={showFlash} />
                <style>{`@keyframes geminiGlow { 0%, 100% { background-position: 0% 50%; box-shadow: 0 0 24px rgba(200,230,255,0.6); } 50% { background-position: 100% 50%; box-shadow: 0 0 24px rgba(255,250,230,0.6); } }`}</style>

                <LanguageSheet
                    show={showLangSheet}
                    onClose={() => {
                        if (localStorage.getItem(STORAGE.language)) {
                            setScreen(SCREENS.CAMERA)
                            setShowLanguageSheet(false)
                        }
                    }}
                    lang={lang}
                    onSelectLanguage={(code) => {
                        selectLanguage(code)
                        setShowLanguageSheet(false)
                    }}
                />

                <UpgradeSheet
                    show={showUpgrade}
                    onClose={() => setShowUpgrade(false)}
                    t={t}
                    onBuyPro={() => {
                        localStorage.setItem(STORAGE.pro, "true")
                        setIsPro(true)
                        setShowUpgrade(false)
                        toast(t("proActivated"))
                    }}
                />

                <CreditInfoSheet
                    show={showCreditInfo}
                    onClose={() => setShowCreditInfo(false)}
                    t={t}
                    isPro={isPro}
                    aiCredits={aiCredits}
                    onBuyPro={() => {
                        localStorage.setItem(STORAGE.pro, "true")
                        setIsPro(true)
                        setShowCreditInfo(false)
                        toast(t("proActivated"))
                    }}
                />

                <div
                    style={{
                        flex: 1,
                        position: "relative",
                        overflow: "hidden",
                    }}
                >
                    {cameraError ? (
                        <div
                            style={{
                                display: "flex",
                                alignItems: "center",
                                justifyContent: "center",
                                height: "100%",
                                padding: 40,
                                textAlign: "center",
                                color: "#fff",
                            }}
                        >
                            <div
                                style={{
                                    fontSize: DS.fontSize.sm,
                                    lineHeight: 1.6,
                                    whiteSpace: "pre-wrap",
                                }}
                            >
                                {t("cameraError")}
                            </div>
                        </div>
                    ) : (
                        <>
                            <video
                                ref={videoRef}
                                autoPlay
                                playsInline
                                muted
                                style={{
                                    position: "absolute",
                                    inset: 0,
                                    width: "100%",
                                    height: "100%",
                                    objectFit: "cover",
                                    transform:
                                        facingMode === "user"
                                            ? "scaleX(-1)"
                                            : "none",
                                    filter: "blur(20px) brightness(0.7)",
                                }}
                            />
                            <div
                                style={{
                                    position: "absolute",
                                    top: "calc(50% - min(calc(50vw - 24px), 170px) - 52px)",
                                    left: "50%",
                                    transform: "translateX(-50%)",
                                    zIndex: 80,
                                }}
                            >
                                <div
                                    style={{
                                        display: "flex",
                                        background: "rgba(0,0,0,0.5)",
                                        borderRadius: DS.radius.full,
                                        padding: 3,
                                        backdropFilter: "blur(10px)",
                                        width: 160,
                                    }}
                                >
                                    {[
                                        {
                                            key: RECORD_MODE.AI,
                                            labelKey: "ai",
                                            isPro: true,
                                        },
                                        {
                                            key: RECORD_MODE.MANUAL,
                                            labelKey: "manual",
                                        },
                                    ].map((item) => {
                                        const active = recordMode === item.key,
                                            isAI = item.key === RECORD_MODE.AI
                                        return (
                                            <button
                                                key={item.key}
                                                onClick={() => {
                                                    if (isAI && !canUseAI) {
                                                        setShowUpgrade(true)
                                                        return
                                                    }
                                                    setRecordMode(
                                                        item.key as any
                                                    )
                                                }}
                                                style={{
                                                    flex: 1,
                                                    border: "none",
                                                    cursor: "pointer",
                                                    borderRadius:
                                                        DS.radius.full,
                                                    padding: "8px 0",
                                                    fontSize: DS.fontSize.sm,
                                                    fontWeight: 600,
                                                    background: active
                                                        ? "#fff"
                                                        : "transparent",
                                                    color: active
                                                        ? "#000"
                                                        : "rgba(255,255,255,0.7)",
                                                    opacity: 1,
                                                    display: "flex",
                                                    alignItems: "center",
                                                    justifyContent: "center",
                                                }}
                                            >
                                                {isAI && (
                                                    <Icon.Sparkle size={10} />
                                                )}
                                                <span
                                                    style={{
                                                        marginLeft: isAI
                                                            ? 4
                                                            : 0,
                                                        marginRight: item.isPro
                                                            ? 4
                                                            : 0,
                                                    }}
                                                >
                                                    {t(item.labelKey)}
                                                </span>
                                                {item.isPro && (
                                                    <span
                                                        style={{
                                                            fontSize: 9,
                                                            opacity: 0.6,
                                                        }}
                                                    >
                                                        Pro
                                                    </span>
                                                )}
                                            </button>
                                        )
                                    })}
                                </div>
                            </div>
                            <div
                                style={{
                                    position: "absolute",
                                    top: "50%",
                                    left: "50%",
                                    transform: "translate(-50%, -50%)",
                                    width: "min(calc(100vw - 48px), 340px)",
                                    height: "min(calc(100vw - 48px), 340px)",
                                    borderRadius: DS.radius.xl,
                                    overflow: "hidden",
                                    border: "2px solid rgba(255,255,255,0.8)",
                                }}
                            >
                                <video
                                    ref={previewVideoRef}
                                    autoPlay
                                    playsInline
                                    muted
                                    style={{
                                        width: "100%",
                                        height: "100%",
                                        objectFit: "cover",
                                        transform:
                                            facingMode === "user"
                                                ? "scaleX(-1)"
                                                : "none",
                                    }}
                                />
                            </div>
                        </>
                    )}
                </div>

                <canvas ref={canvasRef} style={{ display: "none" }} />
                <input
                    ref={fileInputRef}
                    type="file"
                    accept="image/*"
                    style={{ display: "none" }}
                    onChange={handleFileSelect}
                />

                <div
                    style={{
                        position: "absolute",
                        top: 0,
                        left: 0,
                        right: 0,
                        zIndex: 50,
                    }}
                >
                    <Header
                        background="transparent"
                        color="#fff"
                        left={
                            <button
                                onClick={() => setShowCreditInfo(true)}
                                style={{
                                    padding: "6px 12px",
                                    background: "rgba(0,0,0,0.4)",
                                    borderRadius: DS.radius.full,
                                    color: "#fff",
                                    fontSize: DS.fontSize.sm,
                                    fontWeight: 500,
                                    fontFamily: DS.font.system,
                                    backdropFilter: "blur(10px)",
                                    display: "flex",
                                    alignItems: "center",
                                    gap: 6,
                                    border: "none",
                                    cursor: "pointer",
                                }}
                            >
                                <Icon.Sparkle size={11} />
                                {isPro
                                    ? "Pro"
                                    : `${aiCredits}/${DEFAULT_CREDITS}`}
                            </button>
                        }
                        right={
                            <IconButton
                                onClick={() => setScreen(SCREENS.SETTINGS)}
                                color="#fff"
                            >
                                <Icon.Settings />
                            </IconButton>
                        }
                    />
                </div>

                <div
                    style={{
                        position: "absolute",
                        bottom: 0,
                        left: 0,
                        right: 0,
                        padding: 20,
                        paddingBottom: "max(28px, env(safe-area-inset-bottom))",
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "space-between",
                        zIndex: 90,
                    }}
                >
                    <button
                        onClick={() => fileInputRef.current?.click()}
                        style={{
                            width: 48,
                            height: 48,
                            borderRadius: DS.radius.md,
                            background: "rgba(255,255,255,0.15)",
                            border: "none",
                            cursor: "pointer",
                            display: "flex",
                            alignItems: "center",
                            justifyContent: "center",
                            color: "#fff",
                            backdropFilter: "blur(10px)",
                        }}
                    >
                        <Icon.Gallery />
                    </button>
                    <button
                        onClick={capturePhoto}
                        style={{
                            width: 72,
                            height: 72,
                            borderRadius: "50%",
                            background:
                                recordMode === RECORD_MODE.AI
                                    ? "linear-gradient(135deg, #E8F4FC 0%, #FFE8EC 25%, #FFFEF5 50%, #F5E8F5 75%, #E8F4FC 100%)"
                                    : "#fff",
                            backgroundSize:
                                recordMode === RECORD_MODE.AI
                                    ? "300% 300%"
                                    : "100% 100%",
                            animation:
                                recordMode === RECORD_MODE.AI
                                    ? "geminiGlow 4s ease infinite"
                                    : "none",
                            border: "none",
                            cursor: "pointer",
                            display: "flex",
                            alignItems: "center",
                            justifyContent: "center",
                            boxShadow:
                                recordMode === RECORD_MODE.AI
                                    ? undefined
                                    : "0 4px 20px rgba(0,0,0,0.3)",
                            padding: 0,
                        }}
                    >
                        {recordMode === RECORD_MODE.AI ? (
                            <Icon.Sparkle size={20} />
                        ) : (
                            <div
                                style={{
                                    width: 56,
                                    height: 56,
                                    borderRadius: "50%",
                                    background: "#fff",
                                    border: "3px solid #000",
                                }}
                            />
                        )}
                    </button>
                    <button
                        onClick={() =>
                            setFacingMode((p) =>
                                p === "environment" ? "user" : "environment"
                            )
                        }
                        style={{
                            width: 48,
                            height: 48,
                            borderRadius: "50%",
                            background: DS.colors.gray[800],
                            border: "none",
                            cursor: "pointer",
                            display: "flex",
                            alignItems: "center",
                            justifyContent: "center",
                            color: "#fff",
                        }}
                    >
                        <Icon.CameraSwitch />
                    </button>
                </div>
            </div>
        )
    }

    // ANALYZING SCREEN
    if (screen === SCREENS.ANALYZING) {
        return (
            <div style={container}>
                <Header left={<div style={{ width: DS.header.iconSize }} />} />
                <div
                    style={{
                        flex: 1,
                        display: "flex",
                        flexDirection: "column",
                        alignItems: "center",
                        justifyContent: "center",
                        padding: 40,
                    }}
                >
                    <div
                        style={{
                            width: "100%",
                            maxWidth: 240,
                            aspectRatio: "1/1",
                            borderRadius: DS.radius.xl,
                            overflow: "hidden",
                            position: "relative",
                            background: "#000",
                        }}
                    >
                        {capturedImage && (
                            <img
                                src={capturedImage}
                                alt=""
                                style={{
                                    width: "100%",
                                    height: "100%",
                                    objectFit: "cover",
                                }}
                            />
                        )}
                        <ScanLine />
                    </div>
                    <div style={{ marginTop: 28, textAlign: "center" }}>
                        <div
                            style={{
                                display: "flex",
                                alignItems: "center",
                                justifyContent: "center",
                                gap: 8,
                                fontSize: DS.fontSize.lg,
                                fontWeight: 700,
                            }}
                        >
                            <Icon.Sparkle size={16} /> {t("analyzing")}
                        </div>
                        <div
                            style={{
                                marginTop: 6,
                                fontSize: DS.fontSize.sm,
                                color: DS.colors.gray[500],
                            }}
                        >
                            {t("analyzingDesc")}
                        </div>
                    </div>
                </div>
            </div>
        )
    }

    // RESULT SCREEN
    if (screen === SCREENS.RESULT) {
        return (
            <div style={{ ...container, position: "fixed", inset: 0 }}>
                <Toast show={showToast} message={toastMessage} />
                <ImageModal
                    show={showImageModal}
                    src={capturedImage}
                    onClose={() => setShowImageModal(false)}
                />
                <UpgradeSheet
                    show={showUpgrade}
                    onClose={() => setShowUpgrade(false)}
                    t={t}
                    onBuyPro={() => {
                        localStorage.setItem(STORAGE.pro, "true")
                        setIsPro(true)
                        setShowUpgrade(false)
                        toast(t("proActivated"))
                    }}
                />

                <Header
                    left={
                        <IconButton onClick={() => setScreen(SCREENS.CAMERA)}>
                            <Icon.Back />
                        </IconButton>
                    }
                    right={
                        <IconButton onClick={resetToCamera}>
                            <Icon.X />
                        </IconButton>
                    }
                />
                <div
                    style={{
                        padding: `0 ${DS.content.paddingX}px 14px`,
                        display: "flex",
                        alignItems: "center",
                        gap: 12,
                    }}
                >
                    {capturedImage && (
                        <button
                            onClick={() => setShowImageModal(true)}
                            style={{
                                width: 52,
                                height: 52,
                                borderRadius: DS.radius.md,
                                overflow: "hidden",
                                flexShrink: 0,
                                border: "none",
                                padding: 0,
                                cursor: "pointer",
                                position: "relative",
                            }}
                        >
                            <img
                                src={capturedImage}
                                alt=""
                                style={{
                                    width: "100%",
                                    height: "100%",
                                    objectFit: "cover",
                                }}
                            />
                            <div
                                style={{
                                    position: "absolute",
                                    bottom: 3,
                                    right: 3,
                                    width: 18,
                                    height: 18,
                                    borderRadius: 4,
                                    background: "rgba(0,0,0,0.5)",
                                    display: "flex",
                                    alignItems: "center",
                                    justifyContent: "center",
                                    color: "#fff",
                                }}
                            >
                                <Icon.Expand />
                            </div>
                        </button>
                    )}
                    <div>
                        <div
                            style={{
                                fontSize: DS.fontSize.xs,
                                color: DS.colors.gray[500],
                                marginBottom: 2,
                            }}
                        >
                            {t("totalCalories")}
                        </div>
                        <div
                            style={{
                                fontSize: 30,
                                fontWeight: 700,
                                letterSpacing: -1.5,
                                lineHeight: 1,
                            }}
                        >
                            {totalCalories}
                            <span
                                style={{
                                    fontSize: DS.fontSize.sm,
                                    fontWeight: 500,
                                    color: DS.colors.gray[400],
                                    marginLeft: 4,
                                }}
                            >
                                kcal
                            </span>
                        </div>
                        {foods.length > 5 && (
                            <div
                                style={{
                                    fontSize: DS.fontSize.xs,
                                    color: DS.colors.gray[400],
                                    marginTop: 4,
                                }}
                            >
                                {t("onlyFiveShown")}
                            </div>
                        )}
                    </div>
                </div>

                <div
                    style={{
                        flex: 1,
                        overflowY: "auto",
                        overflowX: "hidden",
                        WebkitOverflowScrolling: "touch",
                        padding: `0 ${DS.content.paddingX}px`,
                        paddingBottom: 130 + keyboardHeight,
                        transition: "padding-bottom 0.15s ease-out",
                    }}
                >
                    {foods.map((food, i) => (
                        <div
                            key={i}
                            style={{
                                background: DS.colors.white,
                                borderRadius: DS.radius.sm,
                                padding: "12px 14px",
                                marginBottom: 10,
                                border: `1px solid ${focusedFoodIndex === i ? DS.colors.gray[300] : DS.colors.gray[200]}`,
                                transition: "border-color 0.15s ease",
                            }}
                        >
                            <div
                                style={{
                                    display: "flex",
                                    alignItems: "center",
                                    gap: 6,
                                    marginBottom: 8,
                                }}
                            >
                                <div style={{ flex: 1, position: "relative" }}>
                                    <input
                                        ref={(el) => (foodInputRefs.current[i] = el)}
                                        type="text"
                                        value={food.name}
                                        onChange={(e) =>
                                            handleFoodChange(
                                                i,
                                                "name",
                                                e.target.value
                                            )
                                        }
                                        onFocus={() => setFocusedFoodIndex(i)}
                                        onBlur={() => setTimeout(() => setFocusedFoodIndex(null), 150)}
                                        placeholder={t("foodName")}
                                        style={{
                                            ...input,
                                            width: "100%",
                                            fontSize: 16,
                                            fontWeight: 600,
                                            padding: "9px 28px 9px 12px",
                                        }}
                                    />
                                    {food.name && (
                                        <button
                                            onClick={() =>
                                                handleFoodChange(i, "name", "")
                                            }
                                            style={{
                                                position: "absolute",
                                                right: 8,
                                                top: "50%",
                                                transform: "translateY(-50%)",
                                                background: "none",
                                                border: "none",
                                                cursor: "pointer",
                                                padding: 2,
                                                display: "flex",
                                                alignItems: "center",
                                                justifyContent: "center",
                                            }}
                                        >
                                            <svg
                                                width="11"
                                                height="11"
                                                viewBox="0 0 24 24"
                                                fill="none"
                                                stroke="#E53935"
                                                strokeWidth="2.5"
                                                strokeLinecap="round"
                                            >
                                                <path d="M18 6L6 18M6 6l12 12" />
                                            </svg>
                                        </button>
                                    )}
                                </div>
                                <button
                                    onClick={() =>
                                        searchCalories(food.name, food.amount)
                                    }
                                    style={{
                                        width: 34,
                                        height: 34,
                                        borderRadius: 8,
                                        background: DS.colors.gray[100],
                                        border: "none",
                                        cursor: "pointer",
                                        display: "flex",
                                        alignItems: "center",
                                        justifyContent: "center",
                                        color: DS.colors.gray[600],
                                        flexShrink: 0,
                                    }}
                                >
                                    <Icon.Search />
                                </button>
                                <button
                                    onClick={() =>
                                        setFoods(
                                            foods.filter((_, idx) => idx !== i)
                                        )
                                    }
                                    style={{
                                        width: 34,
                                        height: 34,
                                        borderRadius: 8,
                                        background: "#FEE2E2",
                                        border: "none",
                                        cursor: "pointer",
                                        display: "flex",
                                        alignItems: "center",
                                        justifyContent: "center",
                                        flexShrink: 0,
                                    }}
                                >
                                    <Icon.Trash />
                                </button>
                            </div>
                            <div
                                style={{
                                    display: "flex",
                                    alignItems: "center",
                                    gap: 8,
                                }}
                            >
                                <div style={{ flex: 1, position: "relative" }}>
                                    <input
                                        type="text"
                                        value={food.amount}
                                        onChange={(e) =>
                                            handleFoodChange(
                                                i,
                                                "amount",
                                                e.target.value
                                            )
                                        }
                                        onFocus={() => setFocusedFoodIndex(i)}
                                        onBlur={() => setTimeout(() => setFocusedFoodIndex(null), 150)}
                                        placeholder={t("amount")}
                                        style={{
                                            ...input,
                                            width: "100%",
                                            fontSize: 16,
                                            color: DS.colors.gray[600],
                                            padding: "9px 28px 9px 12px",
                                        }}
                                    />
                                    {food.amount && (
                                        <button
                                            onClick={() =>
                                                handleFoodChange(
                                                    i,
                                                    "amount",
                                                    ""
                                                )
                                            }
                                            style={{
                                                position: "absolute",
                                                right: 8,
                                                top: "50%",
                                                transform: "translateY(-50%)",
                                                background: "none",
                                                border: "none",
                                                cursor: "pointer",
                                                padding: 2,
                                                display: "flex",
                                                alignItems: "center",
                                                justifyContent: "center",
                                            }}
                                        >
                                            <svg
                                                width="11"
                                                height="11"
                                                viewBox="0 0 24 24"
                                                fill="none"
                                                stroke="#E53935"
                                                strokeWidth="2.5"
                                                strokeLinecap="round"
                                            >
                                                <path d="M18 6L6 18M6 6l12 12" />
                                            </svg>
                                        </button>
                                    )}
                                </div>
                                <div
                                    style={{
                                        display: "flex",
                                        alignItems: "center",
                                        background: DS.colors.gray[100],
                                        borderRadius: 8,
                                        padding: "0 10px",
                                        height: 34,
                                    }}
                                >
                                    <input
                                        type="text"
                                        inputMode="numeric"
                                        value={food.calories}
                                        onChange={(e) =>
                                            handleFoodChange(
                                                i,
                                                "calories",
                                                e.target.value
                                            )
                                        }
                                        placeholder="0"
                                        style={{
                                            ...input,
                                            width: 44,
                                            fontSize: 16,
                                            textAlign: "right",
                                            fontWeight: 700,
                                            padding: 0,
                                            background: "transparent",
                                        }}
                                    />
                                    <span
                                        style={{
                                            fontSize: DS.fontSize.xs,
                                            color: DS.colors.gray[500],
                                            marginLeft: 3,
                                        }}
                                    >
                                        kcal
                                    </span>
                                </div>
                            </div>
                            {/* Amount suggestions - always render, animate visibility */}
                            <div
                                style={{
                                    display: "flex",
                                    flexWrap: "wrap",
                                    gap: 6,
                                    marginTop: focusedFoodIndex === i && food.name ? 10 : 0,
                                    maxHeight: focusedFoodIndex === i && food.name ? 80 : 0,
                                    opacity: focusedFoodIndex === i && food.name ? 1 : 0,
                                    overflow: "hidden",
                                    transition: "all 0.2s cubic-bezier(0.4, 0, 0.2, 1)",
                                }}
                            >
                                {getAmountSuggestions(food.name || "", lang).map((suggestion, idx) => (
                                    <button
                                        key={idx}
                                        onClick={() => handleFoodChange(i, "amount", suggestion)}
                                        style={{
                                            padding: "7px 14px",
                                            fontSize: DS.fontSize.xs,
                                            fontWeight: 600,
                                            color: food.amount === suggestion ? DS.colors.white : DS.colors.gray[600],
                                            background: food.amount === suggestion ? DS.colors.black : DS.colors.gray[100],
                                            border: "none",
                                            borderRadius: DS.radius.full,
                                            cursor: "pointer",
                                            transition: DS.transition.fast,
                                            whiteSpace: "nowrap",
                                        }}
                                    >
                                        {suggestion}
                                    </button>
                                ))}
                            </div>
                        </div>
                    ))}
                </div>

                <div
                    style={{
                        position: "fixed",
                        bottom: 0,
                        left: 0,
                        right: 0,
                        transform: `translateY(-${keyboardHeight}px)`,
                        padding: `12px ${DS.content.paddingX}px`,
                        paddingBottom: keyboardHeight > 0 ? 10 : "max(14px, env(safe-area-inset-bottom))",
                        background: keyboardHeight > 0 ? DS.colors.white : DS.colors.gray[50],
                        borderTop: keyboardHeight > 0 ? `1px solid ${DS.colors.gray[200]}` : "none",
                        zIndex: 100,
                        transition: "transform 0.15s ease-out, padding 0.15s ease-out, background 0.15s ease-out",
                        boxShadow: keyboardHeight > 0 ? "0 -4px 20px rgba(0,0,0,0.08)" : "none",
                    }}
                >
                    <button
                        onClick={() => {
                            setFoods([
                                { name: "", amount: "", calories: "" },
                                ...foods,
                            ])
                            // Auto focus on new food input
                            setTimeout(() => {
                                foodInputRefs.current[0]?.focus()
                            }, 50)
                        }}
                        style={{
                            width: "100%",
                            padding: 11,
                            fontSize: DS.fontSize.sm,
                            fontWeight: 600,
                            color: DS.colors.gray[500],
                            background: DS.colors.white,
                            border: `1.5px dashed ${DS.colors.gray[300]}`,
                            borderRadius: DS.radius.sm,
                            cursor: "pointer",
                            marginBottom: 10,
                            display: "flex",
                            alignItems: "center",
                            justifyContent: "center",
                            gap: 6,
                        }}
                    >
                        <Icon.Plus /> {t("addFood")}
                    </button>
                    {hasEmptyCalories ? (
                        <Button
                            onClick={calculateCalories}
                            disabled={isCalculating}
                        >
                            <Icon.Sparkle size={14} />
                            {isCalculating
                                ? t("calculating")
                                : t("aiCalcCalories")}
                            <span
                                style={{
                                    fontSize: DS.fontSize.xs,
                                    opacity: 0.6,
                                    marginLeft: 2,
                                }}
                            >
                                Pro
                            </span>
                        </Button>
                    ) : (
                        <Button
                            onClick={() =>
                                canComplete && setScreen(SCREENS.COMPLETE)
                            }
                            disabled={!canComplete}
                        >
                            {t("next")}
                        </Button>
                    )}
                </div>
            </div>
        )
    }

    // COMPLETE SCREEN
    if (screen === SCREENS.COMPLETE) {
        const isProFeature =
            selectedCardType === CARD_TYPES.DETAILED ||
            (selectedCardType === CARD_TYPES.SIMPLE &&
                selectedTheme !== CARD_THEMES.DEFAULT)
        const handleSave = async () => {
            if (isProFeature && !isPro && !sessionPaid && aiCredits <= 0) {
                setShowUpgrade(true)
                return
            }
            if (isProFeature && !isPro && !sessionPaid) {
                updateCredits(Math.max(0, aiCredits - 1))
                setSessionPaid(true)
            }
            await saveCard()
        }
        const handleShare = async () => {
            if (isProFeature && !isPro && !sessionPaid && aiCredits <= 0) {
                setShowUpgrade(true)
                return
            }
            if (isProFeature && !isPro && !sessionPaid) {
                updateCredits(Math.max(0, aiCredits - 1))
                setSessionPaid(true)
            }
            await shareCard()
        }

        return (
            <div style={container}>
                <Toast show={showToast} message={toastMessage} />
                <LoadingOverlay
                    show={isSaving}
                    message={
                        savingType === "share" ? t("sharing") : t("saving")
                    }
                />
                <ProRequiredSheet
                    show={showUpgrade}
                    onClose={() => setShowUpgrade(false)}
                    t={t}
                    onBuyPro={() => {
                        window.open(LEMON_SQUEEZY_URL, "_blank")
                        setShowUpgrade(false)
                    }}
                    onWatchAd={watchAdAndSave}
                />

                <Header
                    left={
                        <IconButton onClick={() => setScreen(SCREENS.RESULT)}>
                            <Icon.Back />
                        </IconButton>
                    }
                    right={
                        <IconButton onClick={resetToCamera}>
                            <Icon.X />
                        </IconButton>
                    }
                />

                <div
                    style={{
                        flex: 1,
                        display: "flex",
                        flexDirection: "column",
                        overflow: "hidden",
                    }}
                >
                    {/* Card Preview Area - Fixed Height */}
                    <div
                        style={{
                            flex: 1,
                            display: "flex",
                            alignItems: "center",
                            justifyContent: "center",
                            padding: `16px ${DS.content.paddingX}px`,
                            minHeight: 0,
                        }}
                    >
                        <div
                            style={{
                                width: "100%",
                                maxWidth: 220,
                                boxShadow: "0 20px 60px rgba(0,0,0,0.2)",
                                borderRadius: DS.radius.xl,
                                overflow: "hidden",
                            }}
                        >
                            {selectedCardType === CARD_TYPES.SIMPLE ? (
                                <SimpleCard
                                    capturedImage={capturedImage}
                                    timestamp={timestamp}
                                    totalCalories={totalCalories}
                                    cardRef={simpleCardRef}
                                    lang={lang}
                                    theme={selectedTheme}
                                    aspectRatio={selectedAspectRatio}
                                />
                            ) : (
                                <DetailedCard
                                    capturedImage={capturedImage}
                                    timestamp={timestamp}
                                    totalCalories={totalCalories}
                                    foods={foods}
                                    cardRef={detailedCardRef}
                                    lang={lang}
                                    theme={selectedTheme}
                                    aspectRatio={selectedAspectRatio}
                                />
                            )}
                        </div>
                    </div>

                    {/* Options Toolbar - Fixed Position */}
                    <div
                        style={{
                            padding: `16px ${DS.content.paddingX}px`,
                            display: "flex",
                            flexDirection: "column",
                            alignItems: "center",
                            gap: 12,
                            background: DS.colors.gray[50],
                            borderTop: `1px solid ${DS.colors.gray[100]}`,
                        }}
                    >
                        {/* Card Type Toggle - Camera Style */}
                        <div
                            style={{
                                display: "flex",
                                background: DS.colors.gray[800],
                                borderRadius: DS.radius.full,
                                padding: 3,
                                width: 180,
                            }}
                        >
                            {[
                                { key: CARD_TYPES.SIMPLE, labelKey: "simple" },
                                { key: CARD_TYPES.DETAILED, labelKey: "detailed", isPro: true },
                            ].map((item) => {
                                const active = selectedCardType === item.key
                                return (
                                    <button
                                        key={item.key}
                                        onClick={() => setSelectedCardType(item.key as any)}
                                        style={{
                                            flex: 1,
                                            border: "none",
                                            cursor: "pointer",
                                            borderRadius: DS.radius.full,
                                            padding: "8px 0",
                                            fontSize: DS.fontSize.sm,
                                            fontWeight: 600,
                                            background: active ? "#fff" : "transparent",
                                            color: active ? "#000" : "rgba(255,255,255,0.6)",
                                            display: "flex",
                                            alignItems: "center",
                                            justifyContent: "center",
                                            gap: 4,
                                            transition: "all 0.15s ease",
                                        }}
                                    >
                                        {item.isPro && <Icon.Sparkle size={10} />}
                                        {t(item.labelKey)}
                                    </button>
                                )
                            })}
                        </div>

                        {/* Theme & Ratio Row */}
                        <div style={{ display: "flex", gap: 6, flexWrap: "wrap", justifyContent: "center" }}>
                            {/* Theme Selector */}
                            {[
                                { key: CARD_THEMES.DEFAULT, label: t("themeDefault") },
                                { key: CARD_THEMES.DIGITAL, label: t("themeDigital") },
                                { key: CARD_THEMES.NEON, label: t("themeNeon") },
                            ].map((item) => {
                                const isProTheme = selectedCardType === CARD_TYPES.DETAILED || item.key !== CARD_THEMES.DEFAULT
                                const active = selectedTheme === item.key
                                return (
                                    <button
                                        key={item.key}
                                        onClick={() => {
                                            setSelectedTheme(item.key)
                                            localStorage.setItem(STORAGE.theme, item.key)
                                        }}
                                        style={{
                                            padding: "6px 12px",
                                            fontSize: DS.fontSize.xs,
                                            fontWeight: 600,
                                            color: active ? DS.colors.white : DS.colors.gray[500],
                                            background: active ? DS.colors.black : DS.colors.white,
                                            border: `1px solid ${active ? DS.colors.black : DS.colors.gray[200]}`,
                                            borderRadius: DS.radius.full,
                                            cursor: "pointer",
                                            display: "flex",
                                            alignItems: "center",
                                            gap: 3,
                                            transition: "all 0.15s ease",
                                        }}
                                    >
                                        {isProTheme && <Icon.Sparkle size={8} />}
                                        {item.label}
                                    </button>
                                )
                            })}

                            <div style={{ width: 1, height: 24, background: DS.colors.gray[200], margin: "0 2px" }} />

                            {/* Aspect Ratio Selector */}
                            {[ASPECT_RATIOS.PORTRAIT, ASPECT_RATIOS.SQUARE, ASPECT_RATIOS.LANDSCAPE].map((ratio) => {
                                const active = selectedAspectRatio.key === ratio.key
                                return (
                                    <button
                                        key={ratio.key}
                                        onClick={() => setSelectedAspectRatio(ratio)}
                                        style={{
                                            padding: "6px 10px",
                                            fontSize: DS.fontSize.xs,
                                            fontWeight: 600,
                                            color: active ? DS.colors.white : DS.colors.gray[500],
                                            background: active ? DS.colors.gray[700] : DS.colors.white,
                                            border: `1px solid ${active ? DS.colors.gray[700] : DS.colors.gray[200]}`,
                                            borderRadius: DS.radius.full,
                                            cursor: "pointer",
                                            transition: "all 0.15s ease",
                                        }}
                                    >
                                        {ratio.key}
                                    </button>
                                )
                            })}
                        </div>
                    </div>
                </div>

                {/* Bottom Buttons */}
                <div
                    style={{
                        padding: `16px ${DS.content.paddingX}px`,
                        paddingBottom: "max(16px, env(safe-area-inset-bottom))",
                    }}
                >
                    <div style={{ display: "flex", gap: 12 }}>
                        <Button
                            variant="secondary"
                            onClick={handleSave}
                            disabled={isSaving}
                            style={{ flex: 1 }}
                        >
                            {isProFeature && !isPro && !sessionPaid && (
                                <Icon.Sparkle size={12} />
                            )}
                            {isSaving ? "..." : t("save")}
                        </Button>
                        <Button
                            onClick={handleShare}
                            disabled={isSaving}
                            style={{ flex: 1 }}
                        >
                            {isProFeature && !isPro && !sessionPaid && (
                                <Icon.Sparkle size={12} />
                            )}
                            {isSaving ? "..." : t("share")}
                        </Button>
                    </div>
                </div>
            </div>
        )
    }

    // SETTINGS SCREEN
    if (screen === SCREENS.SETTINGS) {
        const currentLang = LANGUAGES.find((l) => l.code === lang)
        const handleProCodeSubmit = () => {
            if (validateProCode(proCodeInput)) {
                localStorage.setItem(
                    STORAGE.proCode,
                    proCodeInput.trim().toUpperCase()
                )
                localStorage.setItem(STORAGE.pro, "true")
                setIsPro(true)
                setShowProCodeSheet(false)
                setProCodeInput("")
                setProCodeError("")
                toast(t("proActivated"))
            } else {
                setProCodeError(t("invalidCode"))
            }
        }

        return (
            <div style={container}>
                <Toast show={showToast} message={toastMessage} />
                <LanguageSheet
                    show={showLanguageSheet}
                    onClose={() => setShowLanguageSheet(false)}
                    lang={lang}
                    onSelectLanguage={(code) => {
                        setLang(code)
                        localStorage.setItem(STORAGE.language, code)
                        setShowLanguageSheet(false)
                    }}
                />
                <ProCodeSheet
                    show={showProCodeSheet}
                    onClose={() => {
                        setShowProCodeSheet(false)
                        setProCodeError("")
                    }}
                    t={t}
                    proCodeInput={proCodeInput}
                    proCodeError={proCodeError}
                    onCodeChange={(value) => {
                        setProCodeInput(value)
                        setProCodeError("")
                    }}
                    onSubmit={handleProCodeSubmit}
                />

                <Header
                    left={
                        <IconButton onClick={() => setScreen(SCREENS.CAMERA)}>
                            <Icon.Back />
                        </IconButton>
                    }
                    center={
                        <span
                            style={{
                                fontSize: DS.fontSize.lg,
                                fontWeight: 700,
                            }}
                        >
                            {t("settings")}
                        </span>
                    }
                />
                <div
                    style={{
                        flex: 1,
                        overflowY: "auto",
                        padding: `14px ${DS.content.paddingX}px 40px`,
                    }}
                >
                    <div
                        style={{
                            background: DS.colors.white,
                            borderRadius: DS.radius.lg,
                            padding: 20,
                            marginBottom: 14,
                        }}
                    >
                        <div
                            style={{
                                display: "flex",
                                alignItems: "center",
                                gap: 12,
                                marginBottom: 14,
                            }}
                        >
                            <div
                                style={{
                                    width: 44,
                                    height: 44,
                                    borderRadius: DS.radius.full,
                                    background: isPro
                                        ? DS.colors.black
                                        : DS.colors.gray[100],
                                    display: "flex",
                                    alignItems: "center",
                                    justifyContent: "center",
                                    color: isPro ? "#fff" : DS.colors.black,
                                }}
                            >
                                <Icon.Sparkle size={18} />
                            </div>
                            <div>
                                <div
                                    style={{
                                        fontSize: DS.fontSize.lg,
                                        fontWeight: 700,
                                    }}
                                >
                                    {isPro ? t("proActive") : t("freeUser")}
                                </div>
                                <div
                                    style={{
                                        fontSize: DS.fontSize.sm,
                                        color: DS.colors.gray[500],
                                        marginTop: 2,
                                    }}
                                >
                                    {isPro
                                        ? t("aiUnlimited")
                                        : `${t("aiCredits")} ${aiCredits}/${DEFAULT_CREDITS}`}
                                </div>
                            </div>
                        </div>
                        <div
                            style={{
                                background: DS.colors.gray[50],
                                borderRadius: DS.radius.md,
                                padding: 14,
                                marginBottom: 14,
                            }}
                        >
                            <div
                                style={{
                                    fontSize: DS.fontSize.sm,
                                    fontWeight: 600,
                                    marginBottom: 10,
                                }}
                            >
                                {t("proFeatures")}
                            </div>
                            {["feature1", "feature2", "feature3"].map(
                                (key, i) => (
                                    <div
                                        key={i}
                                        style={{
                                            display: "flex",
                                            alignItems: "center",
                                            gap: 8,
                                            fontSize: DS.fontSize.sm,
                                            color: DS.colors.gray[600],
                                            marginBottom: i < 2 ? 6 : 0,
                                        }}
                                    >
                                        <div
                                            style={{
                                                width: 4,
                                                height: 4,
                                                borderRadius: 2,
                                                background: DS.colors.gray[400],
                                            }}
                                        />
                                        {t(key)}
                                    </div>
                                )
                            )}
                        </div>
                        {!isPro ? (
                            <>
                                <Button
                                    onClick={() =>
                                        window.open(LEMON_SQUEEZY_URL, "_blank")
                                    }
                                >
                                    {t("buyPro")} · $2.99
                                </Button>
                                <div style={{ height: 8 }} />
                                <Button
                                    variant="secondary"
                                    onClick={() => setShowProCodeSheet(true)}
                                >
                                    {t("enterCode")}
                                </Button>
                            </>
                        ) : (
                            <div
                                style={{
                                    textAlign: "center",
                                    fontSize: DS.fontSize.sm,
                                    color: DS.colors.gray[500],
                                }}
                            >
                                {t("thankYou")}
                            </div>
                        )}
                    </div>
                    <div
                        style={{
                            display: "grid",
                            gridTemplateColumns: "1fr 1fr",
                            gap: 10,
                        }}
                    >
                        <div
                            style={{
                                background: DS.colors.white,
                                borderRadius: DS.radius.lg,
                                padding: 14,
                            }}
                        >
                            <div
                                style={{
                                    fontSize: DS.fontSize.xs,
                                    fontWeight: 600,
                                    color: DS.colors.gray[500],
                                    marginBottom: 8,
                                }}
                            >
                                {t("language")}
                            </div>
                            <button
                                onClick={() => setShowLanguageSheet(true)}
                                style={{
                                    width: "100%",
                                    display: "flex",
                                    alignItems: "center",
                                    justifyContent: "space-between",
                                    padding: "10px 12px",
                                    background: DS.colors.gray[50],
                                    border: "none",
                                    borderRadius: DS.radius.sm,
                                    cursor: "pointer",
                                    fontSize: DS.fontSize.sm,
                                }}
                            >
                                <span style={{ fontWeight: 500 }}>
                                    {currentLang?.name}
                                </span>
                                <span style={{ color: DS.colors.gray[400] }}>
                                    ›
                                </span>
                            </button>
                        </div>
                        <div
                            style={{
                                background: DS.colors.white,
                                borderRadius: DS.radius.lg,
                                padding: 14,
                            }}
                        >
                            <div
                                style={{
                                    fontSize: DS.fontSize.xs,
                                    fontWeight: 600,
                                    color: DS.colors.gray[500],
                                    marginBottom: 8,
                                }}
                            >
                                {t("cameraPermission")}
                            </div>
                            <button
                                onClick={() => {
                                    navigator.mediaDevices
                                        .getUserMedia({ video: true })
                                        .then((s) => {
                                            s.getTracks().forEach((tk) =>
                                                tk.stop()
                                            )
                                            toast(t("cameraAllowed"))
                                        })
                                        .catch(() => {
                                            toast(t("cameraSettings"))
                                        })
                                }}
                                style={{
                                    width: "100%",
                                    display: "flex",
                                    alignItems: "center",
                                    justifyContent: "space-between",
                                    padding: "10px 12px",
                                    background: DS.colors.gray[50],
                                    border: "none",
                                    borderRadius: DS.radius.sm,
                                    cursor: "pointer",
                                    fontSize: DS.fontSize.sm,
                                }}
                            >
                                <span style={{ fontWeight: 500 }}>
                                    {t("allow")}
                                </span>
                                <span style={{ color: DS.colors.gray[400] }}>
                                    ›
                                </span>
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        )
    }

    return null
}

addPropertyControls(MealStamp, {
    appName: {
        type: ControlType.String,
        title: "앱 이름",
        defaultValue: "MealStamp",
    },
    apiKeyDefault: {
        type: ControlType.String,
        title: "기본 API 키",
        defaultValue: "",
    },
})
