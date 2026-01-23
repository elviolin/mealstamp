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
    totalCarbs?: number
    totalProtein?: number
    totalFat?: number
    totalFiber?: number
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
        digital: "'DS-Digital-Latin', 'DS-Digital', 'Pretendard', system-ui, sans-serif",
        neon: "'Orbitron-Latin', 'Orbitron', 'Pretendard', system-ui, sans-serif",
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
            @font-face {
                font-family: 'Orbitron-Latin';
                src: local('Orbitron');
                unicode-range: U+0020-007F, U+2000-206F;
            }
            @font-face {
                font-family: 'DS-Digital-Latin';
                src: local('DS-Digital');
                unicode-range: U+0020-007F, U+2000-206F;
            }
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
const CARD_TYPES = { SIMPLE: "simple", DETAILED: "detailed", HEALTH: "health" }
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
        health: "건강",
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
        saveAndShare: "저장하기",
        cancel: "취소",
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
        health: "健康",
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
        saveAndShare: "保存する",
        cancel: "キャンセル",
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
        health: "Health",
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
        saveAndShare: "Save",
        cancel: "Cancel",
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
        health: "健康",
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
        saveAndShare: "保存",
        cancel: "取消",
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
        health: "Santé",
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
        saveAndShare: "Enregistrer",
        cancel: "Annuler",
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
        health: "Gesund",
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
        saveAndShare: "Speichern",
        cancel: "Abbrechen",
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
        soup: ["1그릇", "한그릇", "200ml", "1인분"],
        drink: ["1잔", "한잔", "200ml", "500ml"],
        meat: ["100g", "150g", "200g", "1인분"],
        bread: ["1개", "한조각", "2조각", "100g"],
        noodle: ["1인분", "한그릇", "150g", "200g"],
        fruit: ["1개", "반개", "100g", "한줌"],
        salad: ["1접시", "한그릇", "100g", "150g"],
        egg: ["1개", "2개", "3개", "계란후라이 1개"],
        sidedish: ["조금", "적당량", "한젓가락", "50g"],
        cake: ["한조각", "1조각", "2조각", "1/8개"],
        pizza: ["1조각", "2조각", "반판", "1판"],
        sandwich: ["1개", "반개", "1인분", "150g"],
        burger: ["1개", "세트", "단품", "200g"],
        snack: ["한봉지", "반봉지", "50g", "100g"],
        icecream: ["1개", "1스쿱", "2스쿱", "1컵"],
        sushi: ["1개", "2개", "1접시", "1인분"],
        dumpling: ["1개", "3개", "5개", "1인분"],
        cookie: ["1개", "2개", "3개", "50g"],
        chocolate: ["1개", "1조각", "반개", "30g"],
        yogurt: ["1개", "1컵", "100g", "200g"],
        cheese: ["1장", "2장", "30g", "50g"],
        fish: ["1토막", "반마리", "100g", "1인분"],
        seafood: ["100g", "150g", "1인분", "한접시"],
        tofu: ["반모", "1/4모", "100g", "150g"],
        vegetable: ["한줌", "1접시", "100g", "50g"],
        nut: ["한줌", "10알", "20알", "30g"],
        ricecake: ["1개", "2개", "3개", "100g"],
        porridge: ["한그릇", "반그릇", "200g", "300g"],
        curry: ["1인분", "한그릇", "200g", "300g"],
        friedfood: ["1개", "2개", "3개", "100g"],
        chicken: ["1조각", "2조각", "반마리", "1인분"],
        taco: ["1개", "2개", "3개", "1인분"],
        wrap: ["1개", "반개", "1인분", "200g"],
        pancake: ["1장", "2장", "3장", "1인분"],
        waffle: ["1개", "반개", "1인분", "150g"],
        donut: ["1개", "반개", "2개", "100g"],
        croissant: ["1개", "반개", "2개", "80g"],
        bagel: ["1개", "반개", "2개", "100g"],
        muffin: ["1개", "반개", "2개", "100g"],
        pie: ["1조각", "2조각", "1/6개", "150g"],
        pudding: ["1개", "1컵", "100g", "150g"],
        jelly: ["1개", "2개", "100g", "1컵"],
        cereal: ["한그릇", "1컵", "40g", "60g"],
        oatmeal: ["한그릇", "1컵", "40g", "60g"],
        granola: ["한줌", "50g", "100g", "1컵"],
        smoothie: ["1잔", "1컵", "300ml", "500ml"],
        milkshake: ["1잔", "1컵", "300ml", "500ml"],
        latte: ["1잔", "톨", "그란데", "벤티"],
        wine: ["1잔", "반잔", "150ml", "1병"],
        beer: ["1캔", "1잔", "500ml", "1병"],
        soju: ["1잔", "반병", "1병", "소주잔"],
        cocktail: ["1잔", "반잔", "200ml", "300ml"],
        default: ["1개", "1인분", "100g", "한접시"],
    },
    ja: {
        rice: ["1杯", "半分", "100g", "150g"],
        soup: ["1杯", "1碗", "200ml", "1人前"],
        drink: ["1杯", "200ml", "350ml", "500ml"],
        meat: ["100g", "150g", "200g", "1人前"],
        bread: ["1個", "1枚", "2枚", "100g"],
        noodle: ["1人前", "1杯", "150g", "200g"],
        fruit: ["1個", "半分", "100g", "1カップ"],
        salad: ["1皿", "1人前", "100g", "150g"],
        egg: ["1個", "2個", "3個", "目玉焼き1個"],
        sidedish: ["少々", "適量", "一箸", "50g"],
        cake: ["1切れ", "2切れ", "1/8個", "1ピース"],
        pizza: ["1切れ", "2切れ", "半分", "1枚"],
        sandwich: ["1個", "半分", "1人前", "150g"],
        burger: ["1個", "セット", "単品", "200g"],
        snack: ["1袋", "半袋", "50g", "100g"],
        icecream: ["1個", "1スクープ", "2スクープ", "1カップ"],
        sushi: ["1貫", "2貫", "1皿", "1人前"],
        dumpling: ["1個", "3個", "5個", "1人前"],
        cookie: ["1枚", "2枚", "3枚", "50g"],
        chocolate: ["1個", "1かけ", "半分", "30g"],
        yogurt: ["1個", "1カップ", "100g", "200g"],
        cheese: ["1枚", "2枚", "30g", "50g"],
        fish: ["1切れ", "半身", "100g", "1人前"],
        seafood: ["100g", "150g", "1人前", "1皿"],
        tofu: ["半丁", "1/4丁", "100g", "150g"],
        vegetable: ["一握り", "1皿", "100g", "50g"],
        nut: ["一握り", "10粒", "20粒", "30g"],
        ricecake: ["1個", "2個", "3個", "100g"],
        porridge: ["1杯", "半分", "200g", "300g"],
        curry: ["1人前", "1皿", "200g", "300g"],
        friedfood: ["1個", "2個", "3個", "100g"],
        chicken: ["1ピース", "2ピース", "半羽", "1人前"],
        taco: ["1個", "2個", "3個", "1人前"],
        wrap: ["1個", "半分", "1人前", "200g"],
        pancake: ["1枚", "2枚", "3枚", "1人前"],
        waffle: ["1枚", "半分", "1人前", "150g"],
        donut: ["1個", "半分", "2個", "100g"],
        croissant: ["1個", "半分", "2個", "80g"],
        bagel: ["1個", "半分", "2個", "100g"],
        muffin: ["1個", "半分", "2個", "100g"],
        pie: ["1切れ", "2切れ", "1/6個", "150g"],
        pudding: ["1個", "1カップ", "100g", "150g"],
        jelly: ["1個", "2個", "100g", "1カップ"],
        cereal: ["1杯", "1カップ", "40g", "60g"],
        oatmeal: ["1杯", "1カップ", "40g", "60g"],
        granola: ["一握り", "50g", "100g", "1カップ"],
        smoothie: ["1杯", "1カップ", "300ml", "500ml"],
        milkshake: ["1杯", "1カップ", "300ml", "500ml"],
        latte: ["1杯", "トール", "グランデ", "ベンティ"],
        wine: ["1杯", "半杯", "150ml", "1本"],
        beer: ["1缶", "1杯", "500ml", "1本"],
        soju: ["1杯", "半本", "1本", "小グラス"],
        cocktail: ["1杯", "半杯", "200ml", "300ml"],
        default: ["1個", "1人前", "100g", "1皿"],
    },
    en: {
        rice: ["1 bowl", "1/2 bowl", "100g", "1 cup"],
        soup: ["1 bowl", "1 cup", "200ml", "1 serving"],
        drink: ["1 glass", "1 cup", "200ml", "500ml"],
        meat: ["100g", "150g", "200g", "1 serving"],
        bread: ["1 slice", "2 slices", "1 piece", "100g"],
        noodle: ["1 serving", "1 bowl", "150g", "200g"],
        fruit: ["1 piece", "1/2", "100g", "1 cup"],
        salad: ["1 plate", "1 bowl", "100g", "150g"],
        egg: ["1 egg", "2 eggs", "3 eggs", "fried egg"],
        sidedish: ["a little", "some", "1 tbsp", "50g"],
        cake: ["1 slice", "2 slices", "1/8", "1 piece"],
        pizza: ["1 slice", "2 slices", "half", "whole"],
        sandwich: ["1 whole", "half", "1 serving", "150g"],
        burger: ["1 burger", "combo", "single", "200g"],
        snack: ["1 bag", "half bag", "50g", "100g"],
        icecream: ["1 cone", "1 scoop", "2 scoops", "1 cup"],
        sushi: ["1 piece", "2 pieces", "1 plate", "1 serving"],
        dumpling: ["1 piece", "3 pieces", "5 pieces", "1 serving"],
        cookie: ["1 cookie", "2 cookies", "3 cookies", "50g"],
        chocolate: ["1 piece", "1 square", "half", "30g"],
        yogurt: ["1 cup", "1 container", "100g", "200g"],
        cheese: ["1 slice", "2 slices", "30g", "50g"],
        fish: ["1 fillet", "half", "100g", "1 serving"],
        seafood: ["100g", "150g", "1 serving", "1 plate"],
        tofu: ["half block", "1/4 block", "100g", "150g"],
        vegetable: ["handful", "1 plate", "100g", "50g"],
        nut: ["handful", "10 pcs", "20 pcs", "30g"],
        ricecake: ["1 piece", "2 pieces", "3 pieces", "100g"],
        porridge: ["1 bowl", "half bowl", "200g", "300g"],
        curry: ["1 serving", "1 bowl", "200g", "300g"],
        friedfood: ["1 piece", "2 pieces", "3 pieces", "100g"],
        chicken: ["1 piece", "2 pieces", "half", "1 serving"],
        taco: ["1 taco", "2 tacos", "3 tacos", "1 serving"],
        wrap: ["1 wrap", "half", "1 serving", "200g"],
        pancake: ["1 pancake", "2 pancakes", "3 pancakes", "1 serving"],
        waffle: ["1 waffle", "half", "1 serving", "150g"],
        donut: ["1 donut", "half", "2 donuts", "100g"],
        croissant: ["1 croissant", "half", "2 croissants", "80g"],
        bagel: ["1 bagel", "half", "2 bagels", "100g"],
        muffin: ["1 muffin", "half", "2 muffins", "100g"],
        pie: ["1 slice", "2 slices", "1/6", "150g"],
        pudding: ["1 cup", "1 container", "100g", "150g"],
        jelly: ["1 cup", "2 cups", "100g", "1 serving"],
        cereal: ["1 bowl", "1 cup", "40g", "60g"],
        oatmeal: ["1 bowl", "1 cup", "40g", "60g"],
        granola: ["handful", "50g", "100g", "1 cup"],
        smoothie: ["1 glass", "1 cup", "300ml", "500ml"],
        milkshake: ["1 glass", "1 cup", "300ml", "500ml"],
        latte: ["1 cup", "tall", "grande", "venti"],
        wine: ["1 glass", "half glass", "150ml", "1 bottle"],
        beer: ["1 can", "1 glass", "500ml", "1 bottle"],
        soju: ["1 shot", "half bottle", "1 bottle", "small glass"],
        cocktail: ["1 glass", "half glass", "200ml", "300ml"],
        default: ["1 piece", "1 serving", "100g", "1 plate"],
    },
    zh: {
        rice: ["一碗", "半碗", "100g", "150g"],
        soup: ["一碗", "一杯", "200ml", "一份"],
        drink: ["一杯", "200ml", "350ml", "500ml"],
        meat: ["100g", "150g", "200g", "一份"],
        bread: ["一个", "一片", "两片", "100g"],
        noodle: ["一份", "一碗", "150g", "200g"],
        fruit: ["一个", "半个", "100g", "一把"],
        salad: ["一盘", "一份", "100g", "150g"],
        egg: ["1个", "2个", "3个", "煎蛋1个"],
        sidedish: ["少许", "适量", "一筷子", "50g"],
        cake: ["一块", "两块", "1/8个", "一片"],
        pizza: ["一块", "两块", "半个", "一个"],
        sandwich: ["一个", "半个", "一份", "150g"],
        burger: ["一个", "套餐", "单点", "200g"],
        snack: ["一包", "半包", "50g", "100g"],
        icecream: ["一个", "一球", "两球", "一杯"],
        sushi: ["一个", "两个", "一盘", "一份"],
        dumpling: ["一个", "3个", "5个", "一份"],
        cookie: ["一块", "两块", "三块", "50g"],
        chocolate: ["一块", "一小块", "半块", "30g"],
        yogurt: ["一杯", "一盒", "100g", "200g"],
        cheese: ["一片", "两片", "30g", "50g"],
        fish: ["一块", "半条", "100g", "一份"],
        seafood: ["100g", "150g", "一份", "一盘"],
        tofu: ["半块", "1/4块", "100g", "150g"],
        vegetable: ["一把", "一盘", "100g", "50g"],
        nut: ["一把", "10颗", "20颗", "30g"],
        ricecake: ["一个", "两个", "三个", "100g"],
        porridge: ["一碗", "半碗", "200g", "300g"],
        curry: ["一份", "一碗", "200g", "300g"],
        friedfood: ["一个", "两个", "三个", "100g"],
        chicken: ["一块", "两块", "半只", "一份"],
        taco: ["一个", "两个", "三个", "一份"],
        wrap: ["一个", "半个", "一份", "200g"],
        pancake: ["一张", "两张", "三张", "一份"],
        waffle: ["一个", "半个", "一份", "150g"],
        donut: ["一个", "半个", "两个", "100g"],
        croissant: ["一个", "半个", "两个", "80g"],
        bagel: ["一个", "半个", "两个", "100g"],
        muffin: ["一个", "半个", "两个", "100g"],
        pie: ["一块", "两块", "1/6个", "150g"],
        pudding: ["一杯", "一盒", "100g", "150g"],
        jelly: ["一杯", "两杯", "100g", "一份"],
        cereal: ["一碗", "一杯", "40g", "60g"],
        oatmeal: ["一碗", "一杯", "40g", "60g"],
        granola: ["一把", "50g", "100g", "一杯"],
        smoothie: ["一杯", "一份", "300ml", "500ml"],
        milkshake: ["一杯", "一份", "300ml", "500ml"],
        latte: ["一杯", "中杯", "大杯", "超大杯"],
        wine: ["一杯", "半杯", "150ml", "一瓶"],
        beer: ["一罐", "一杯", "500ml", "一瓶"],
        soju: ["一杯", "半瓶", "一瓶", "小杯"],
        cocktail: ["一杯", "半杯", "200ml", "300ml"],
        default: ["一个", "一份", "100g", "一盘"],
    },
    fr: {
        rice: ["1 bol", "1/2 bol", "100g", "150g"],
        soup: ["1 bol", "1 tasse", "200ml", "1 portion"],
        drink: ["1 verre", "200ml", "350ml", "500ml"],
        meat: ["100g", "150g", "200g", "1 portion"],
        bread: ["1 tranche", "2 tranches", "1 pièce", "100g"],
        noodle: ["1 portion", "1 assiette", "150g", "200g"],
        fruit: ["1 pièce", "1/2", "100g", "1 poignée"],
        salad: ["1 assiette", "1 bol", "100g", "150g"],
        egg: ["1 œuf", "2 œufs", "3 œufs", "œuf au plat"],
        sidedish: ["un peu", "modéré", "1 c.à.s", "50g"],
        cake: ["1 part", "2 parts", "1/8", "1 tranche"],
        pizza: ["1 part", "2 parts", "1/2", "entière"],
        sandwich: ["1 entier", "1/2", "1 portion", "150g"],
        burger: ["1 burger", "menu", "simple", "200g"],
        snack: ["1 sachet", "1/2 sachet", "50g", "100g"],
        icecream: ["1 cornet", "1 boule", "2 boules", "1 coupe"],
        sushi: ["1 pièce", "2 pièces", "1 assiette", "1 portion"],
        dumpling: ["1 pièce", "3 pièces", "5 pièces", "1 portion"],
        cookie: ["1 cookie", "2 cookies", "3 cookies", "50g"],
        chocolate: ["1 pièce", "1 carré", "1/2", "30g"],
        yogurt: ["1 pot", "1 tasse", "100g", "200g"],
        cheese: ["1 tranche", "2 tranches", "30g", "50g"],
        fish: ["1 filet", "1/2", "100g", "1 portion"],
        seafood: ["100g", "150g", "1 portion", "1 assiette"],
        tofu: ["1/2 bloc", "1/4 bloc", "100g", "150g"],
        vegetable: ["1 poignée", "1 assiette", "100g", "50g"],
        nut: ["1 poignée", "10 pcs", "20 pcs", "30g"],
        ricecake: ["1 pièce", "2 pièces", "3 pièces", "100g"],
        porridge: ["1 bol", "1/2 bol", "200g", "300g"],
        curry: ["1 portion", "1 bol", "200g", "300g"],
        friedfood: ["1 pièce", "2 pièces", "3 pièces", "100g"],
        chicken: ["1 morceau", "2 morceaux", "1/2", "1 portion"],
        taco: ["1 taco", "2 tacos", "3 tacos", "1 portion"],
        wrap: ["1 wrap", "1/2", "1 portion", "200g"],
        pancake: ["1 crêpe", "2 crêpes", "3 crêpes", "1 portion"],
        waffle: ["1 gaufre", "1/2", "1 portion", "150g"],
        donut: ["1 donut", "1/2", "2 donuts", "100g"],
        croissant: ["1 croissant", "1/2", "2 croissants", "80g"],
        bagel: ["1 bagel", "1/2", "2 bagels", "100g"],
        muffin: ["1 muffin", "1/2", "2 muffins", "100g"],
        pie: ["1 part", "2 parts", "1/6", "150g"],
        pudding: ["1 pot", "1 tasse", "100g", "150g"],
        jelly: ["1 pot", "2 pots", "100g", "1 portion"],
        cereal: ["1 bol", "1 tasse", "40g", "60g"],
        oatmeal: ["1 bol", "1 tasse", "40g", "60g"],
        granola: ["1 poignée", "50g", "100g", "1 tasse"],
        smoothie: ["1 verre", "1 tasse", "300ml", "500ml"],
        milkshake: ["1 verre", "1 tasse", "300ml", "500ml"],
        latte: ["1 tasse", "petit", "moyen", "grand"],
        wine: ["1 verre", "1/2 verre", "150ml", "1 bouteille"],
        beer: ["1 canette", "1 verre", "500ml", "1 bouteille"],
        soju: ["1 verre", "1/2 bout.", "1 bouteille", "petit verre"],
        cocktail: ["1 verre", "1/2 verre", "200ml", "300ml"],
        default: ["1 pièce", "1 portion", "100g", "1 assiette"],
    },
    de: {
        rice: ["1 Schale", "1/2 Schale", "100g", "150g"],
        soup: ["1 Schale", "1 Tasse", "200ml", "1 Portion"],
        drink: ["1 Glas", "200ml", "350ml", "500ml"],
        meat: ["100g", "150g", "200g", "1 Portion"],
        bread: ["1 Scheibe", "2 Scheiben", "1 Stück", "100g"],
        noodle: ["1 Portion", "1 Teller", "150g", "200g"],
        fruit: ["1 Stück", "1/2", "100g", "1 Handvoll"],
        salad: ["1 Teller", "1 Schale", "100g", "150g"],
        egg: ["1 Ei", "2 Eier", "3 Eier", "Spiegelei"],
        sidedish: ["wenig", "etwas", "1 EL", "50g"],
        cake: ["1 Stück", "2 Stücke", "1/8", "1 Scheibe"],
        pizza: ["1 Stück", "2 Stücke", "1/2", "ganze"],
        sandwich: ["1 Stück", "1/2", "1 Portion", "150g"],
        burger: ["1 Burger", "Menü", "einzeln", "200g"],
        snack: ["1 Tüte", "1/2 Tüte", "50g", "100g"],
        icecream: ["1 Kugel", "2 Kugeln", "1 Becher", "1 Waffel"],
        sushi: ["1 Stück", "2 Stück", "1 Teller", "1 Portion"],
        dumpling: ["1 Stück", "3 Stück", "5 Stück", "1 Portion"],
        cookie: ["1 Keks", "2 Kekse", "3 Kekse", "50g"],
        chocolate: ["1 Stück", "1 Riegel", "1/2", "30g"],
        yogurt: ["1 Becher", "1 Tasse", "100g", "200g"],
        cheese: ["1 Scheibe", "2 Scheiben", "30g", "50g"],
        fish: ["1 Filet", "1/2", "100g", "1 Portion"],
        seafood: ["100g", "150g", "1 Portion", "1 Teller"],
        tofu: ["1/2 Block", "1/4 Block", "100g", "150g"],
        vegetable: ["1 Handvoll", "1 Teller", "100g", "50g"],
        nut: ["1 Handvoll", "10 Stk", "20 Stk", "30g"],
        ricecake: ["1 Stück", "2 Stück", "3 Stück", "100g"],
        porridge: ["1 Schale", "1/2 Schale", "200g", "300g"],
        curry: ["1 Portion", "1 Teller", "200g", "300g"],
        friedfood: ["1 Stück", "2 Stück", "3 Stück", "100g"],
        chicken: ["1 Stück", "2 Stück", "1/2", "1 Portion"],
        taco: ["1 Taco", "2 Tacos", "3 Tacos", "1 Portion"],
        wrap: ["1 Wrap", "1/2", "1 Portion", "200g"],
        pancake: ["1 Pfannkuchen", "2 Pfannkuchen", "3 Pfannkuchen", "1 Portion"],
        waffle: ["1 Waffel", "1/2", "1 Portion", "150g"],
        donut: ["1 Donut", "1/2", "2 Donuts", "100g"],
        croissant: ["1 Croissant", "1/2", "2 Croissants", "80g"],
        bagel: ["1 Bagel", "1/2", "2 Bagels", "100g"],
        muffin: ["1 Muffin", "1/2", "2 Muffins", "100g"],
        pie: ["1 Stück", "2 Stücke", "1/6", "150g"],
        pudding: ["1 Becher", "1 Tasse", "100g", "150g"],
        jelly: ["1 Becher", "2 Becher", "100g", "1 Portion"],
        cereal: ["1 Schale", "1 Tasse", "40g", "60g"],
        oatmeal: ["1 Schale", "1 Tasse", "40g", "60g"],
        granola: ["1 Handvoll", "50g", "100g", "1 Tasse"],
        smoothie: ["1 Glas", "1 Tasse", "300ml", "500ml"],
        milkshake: ["1 Glas", "1 Tasse", "300ml", "500ml"],
        latte: ["1 Tasse", "klein", "mittel", "groß"],
        wine: ["1 Glas", "1/2 Glas", "150ml", "1 Flasche"],
        beer: ["1 Dose", "1 Glas", "500ml", "1 Flasche"],
        soju: ["1 Glas", "1/2 Fl.", "1 Flasche", "Schnapsglas"],
        cocktail: ["1 Glas", "1/2 Glas", "200ml", "300ml"],
        default: ["1 Stück", "1 Portion", "100g", "1 Teller"],
    },
}

// Food category detection keywords (comprehensive multilingual database)
const FOOD_CATEGORIES: Record<string, string[]> = {
    // Grains & Rice
    rice: ["밥", "rice", "ご飯", "ごはん", "饭", "米饭", "riz", "reis", "공기밥", "볶음밥", "fried rice", "炒飯", "チャーハン", "비빔밥", "덮밥"],
    // Soups & Stews
    soup: ["국", "soup", "stew", "찌개", "汁", "スープ", "汤", "soupe", "suppe", "탕", "전골", "곰탕", "설렁탕", "미소시루", "味噌汁", "pot-au-feu"],
    // Beverages
    drink: ["juice", "주스", "커피", "coffee", "tea", "차", "우유", "milk", "ジュース", "コーヒー", "牛奶", "咖啡", "jus", "café", "saft", "kaffee", "물", "water", "콜라", "cola", "사이다", "sprite", "에이드", "ade", "음료"],
    // Meat dishes
    meat: ["고기", "meat", "beef", "pork", "소고기", "돼지", "肉", "牛", "豚", "牛肉", "viande", "fleisch", "삼겹살", "갈비", "불고기", "bulgogi", "스테이크", "steak", "ステーキ", "로스", "안심", "등심"],
    // Bread & Bakery
    bread: ["빵", "bread", "toast", "パン", "トースト", "面包", "pain", "brot", "식빵", "바게트", "baguette", "모닝빵", "롤빵"],
    // Noodles & Pasta
    noodle: ["면", "noodle", "pasta", "라면", "うどん", "ラーメン", "面", "麺", "pâtes", "nudeln", "국수", "스파게티", "spaghetti", "짜장면", "짬뽕", "칼국수", "냉면", "소바", "蕎麦", "pho", "쌀국수"],
    // Fruits
    fruit: ["사과", "apple", "banana", "바나나", "orange", "오렌지", "りんご", "バナナ", "苹果", "香蕉", "pomme", "banane", "apfel", "과일", "fruit", "포도", "grape", "딸기", "strawberry", "수박", "watermelon", "참외", "melon", "복숭아", "peach", "배", "pear", "귤", "tangerine", "키위", "kiwi", "망고", "mango", "파인애플", "pineapple", "블루베리", "blueberry", "체리", "cherry"],
    // Salad & Vegetables
    salad: ["샐러드", "salad", "サラダ", "沙拉", "salade", "salat", "야채샐러드", "과일샐러드"],
    vegetable: ["야채", "채소", "vegetable", "野菜", "蔬菜", "légume", "gemüse", "브로콜리", "broccoli", "당근", "carrot", "시금치", "spinach", "양배추", "cabbage", "오이", "cucumber", "토마토", "tomato", "파프리카", "pepper", "양파", "onion"],
    // Eggs
    egg: ["계란", "달걀", "egg", "卵", "たまご", "鸡蛋", "蛋", "œuf", "ei", "eier", "계란후라이", "스크램블", "scramble", "오믈렛", "omelette"],
    // Korean side dishes
    sidedish: ["볶음", "나물", "무침", "조림", "김치", "젓갈", "장아찌", "전", "멸치", "콩자반", "pickled", "kimchi", "漬物", "おかず", "小菜", "泡菜", "banchan", "깍두기", "반찬"],
    // Cakes & Desserts
    cake: ["케이크", "cake", "ケーキ", "蛋糕", "gâteau", "kuchen", "치즈케이크", "cheesecake", "티라미수", "tiramisu", "롤케이크", "roll cake", "생크림케이크", "무스케이크", "mousse"],
    // Pizza
    pizza: ["피자", "pizza", "ピザ", "披萨", "피자빵"],
    // Sandwiches
    sandwich: ["샌드위치", "sandwich", "サンドイッチ", "三明治", "클럽샌드위치", "에그샌드위치", "BLT", "토스트", "핫도그", "hotdog", "hot dog"],
    // Burgers
    burger: ["버거", "burger", "햄버거", "hamburger", "ハンバーガー", "汉堡", "치즈버거", "cheeseburger", "불고기버거", "새우버거"],
    // Snacks & Chips
    snack: ["과자", "snack", "chip", "chips", "칩", "お菓子", "零食", "프링글스", "pringles", "나쵸", "nacho", "팝콘", "popcorn", "크래커", "cracker", "비스킷", "biscuit"],
    // Ice cream
    icecream: ["아이스크림", "ice cream", "icecream", "アイス", "冰淇淋", "glace", "eis", "젤라또", "gelato", "소프트아이스크림", "soft serve", "빙수", "bingsu", "팥빙수", "sorbet", "셔벗"],
    // Sushi & Japanese
    sushi: ["초밥", "스시", "sushi", "寿司", "すし", "롤", "roll", "연어초밥", "참치초밥", "사시미", "sashimi", "회", "刺身"],
    // Dumplings
    dumpling: ["만두", "교자", "dumpling", "餃子", "ぎょうざ", "饺子", "군만두", "찐만두", "물만두", "dim sum", "딤섬", "샤오롱바오", "소룡포"],
    // Cookies
    cookie: ["쿠키", "cookie", "クッキー", "饼干", "biscuit", "마카롱", "macaron", "마들렌", "madeleine"],
    // Chocolate & Candy
    chocolate: ["초콜릿", "chocolate", "チョコ", "巧克力", "chocolat", "schokolade", "사탕", "candy", "캔디", "젤리", "gummy", "캐러멜", "caramel"],
    // Yogurt
    yogurt: ["요거트", "요구르트", "yogurt", "ヨーグルト", "酸奶", "yaourt", "joghurt", "그릭요거트", "greek yogurt"],
    // Cheese
    cheese: ["치즈", "cheese", "チーズ", "奶酪", "fromage", "käse", "모짜렐라", "mozzarella", "체다", "cheddar", "크림치즈", "cream cheese"],
    // Fish
    fish: ["생선", "fish", "魚", "さかな", "鱼", "poisson", "fisch", "연어", "salmon", "참치", "tuna", "고등어", "mackerel", "광어", "우럭", "조기"],
    // Seafood
    seafood: ["해산물", "seafood", "海鮮", "シーフード", "海鲜", "fruits de mer", "meeresfrüchte", "새우", "shrimp", "오징어", "squid", "문어", "octopus", "조개", "clam", "굴", "oyster", "게", "crab", "랍스터", "lobster"],
    // Tofu
    tofu: ["두부", "tofu", "豆腐", "とうふ", "순두부", "soft tofu", "연두부", "두부조림", "마파두부"],
    // Nuts
    nut: ["견과류", "nut", "nuts", "ナッツ", "坚果", "noix", "nüsse", "아몬드", "almond", "호두", "walnut", "땅콩", "peanut", "캐슈넛", "cashew", "피스타치오", "pistachio", "마카다미아", "macadamia"],
    // Rice cakes
    ricecake: ["떡", "rice cake", "餅", "もち", "年糕", "가래떡", "인절미", "송편", "떡볶이", "tteokbokki"],
    // Porridge
    porridge: ["죽", "porridge", "お粥", "粥", "bouillie", "brei", "전복죽", "호박죽", "팥죽", "오트밀", "oatmeal"],
    // Curry
    curry: ["카레", "curry", "カレー", "咖喱", "커리", "일본카레", "인도카레", "태국카레", "그린커리", "레드커리"],
    // Fried food
    friedfood: ["튀김", "fried", "fry", "揚げ物", "油炸", "friture", "frittiert", "돈까스", "돈카츠", "tonkatsu", "가츠동", "텐푸라", "tempura", "고로케", "croquette", "치킨까스"],
    // Chicken
    chicken: ["치킨", "chicken", "チキン", "鸡肉", "poulet", "hähnchen", "후라이드", "fried chicken", "양념치킨", "닭강정", "닭꼬치", "치킨너겟", "nugget", "윙", "wing"],
    // Mexican
    taco: ["타코", "taco", "タコス", "墨西哥卷", "부리또", "burrito", "퀘사디아", "quesadilla", "나쵸", "엔칠라다", "enchilada"],
    // Wraps
    wrap: ["랩", "wrap", "ラップ", "卷饼", "또띠아", "tortilla", "월남쌈", "spring roll", "스프링롤"],
    // Pancakes
    pancake: ["팬케이크", "pancake", "パンケーキ", "煎饼", "crêpe", "pfannkuchen", "핫케이크", "hotcake", "크레페", "crepe", "전병"],
    // Waffles
    waffle: ["와플", "waffle", "ワッフル", "华夫饼", "gaufre", "waffel", "벨기에와플", "크로플", "croffle"],
    // Donuts
    donut: ["도넛", "도너츠", "donut", "doughnut", "ドーナツ", "甜甜圈", "beignet", "churro", "츄러스"],
    // Croissants
    croissant: ["크루아상", "croissant", "クロワッサン", "可颂", "hörnchen", "페이스트리", "pastry", "파이", "빵"],
    // Bagels
    bagel: ["베이글", "bagel", "ベーグル", "贝果", "플레인베이글", "크림치즈베이글"],
    // Muffins
    muffin: ["머핀", "muffin", "マフィン", "玛芬", "블루베리머핀", "초코머핀", "컵케이크", "cupcake"],
    // Pies
    pie: ["파이", "pie", "パイ", "派", "tarte", "애플파이", "apple pie", "호박파이", "pumpkin pie", "치즈타르트", "에그타르트", "egg tart"],
    // Pudding
    pudding: ["푸딩", "pudding", "プリン", "布丁", "flan", "커스터드", "custard", "판나코타", "panna cotta"],
    // Jelly
    jelly: ["젤리", "jelly", "ゼリー", "果冻", "gelée", "wackelpudding", "곤약젤리", "konjac"],
    // Cereal
    cereal: ["시리얼", "cereal", "シリアル", "麦片", "céréales", "müsli", "콘플레이크", "cornflakes", "그래놀라", "granola", "오트밀"],
    // Smoothies
    smoothie: ["스무디", "smoothie", "スムージー", "冰沙", "아사이볼", "acai bowl", "프로틴쉐이크", "protein shake"],
    // Coffee drinks
    latte: ["라떼", "latte", "ラテ", "拿铁", "카페라떼", "cafe latte", "바닐라라떼", "카라멜마끼아또", "caramel macchiato", "아메리카노", "americano", "에스프레소", "espresso", "카푸치노", "cappuccino", "모카", "mocha"],
    // Alcohol
    wine: ["와인", "wine", "ワイン", "葡萄酒", "vin", "wein", "레드와인", "화이트와인", "로제", "샴페인", "champagne", "스파클링"],
    beer: ["맥주", "beer", "ビール", "啤酒", "bière", "bier", "생맥주", "draft", "에일", "ale", "라거", "lager", "IPA"],
    soju: ["소주", "soju", "焼酎", "烧酒", "sake", "사케", "청주", "막걸리", "makgeolli", "동동주", "백세주"],
    cocktail: ["칵테일", "cocktail", "カクテル", "鸡尾酒", "하이볼", "highball", "모히또", "mojito", "마가리타", "margarita", "상그리아", "sangria"],
}

// ============================================
// Local Nutrition Database (per standard serving)
// Sources: 식약처, USDA, 日本食品標準成分表
// ============================================
const NUTRITION_DB: Record<string, { cal: number; carb: number; prot: number; fat: number; sugar: number; fiber: number; serving: string }> = {
    // 한국 밥류
    "흰밥": { cal: 313, carb: 68, prot: 6, fat: 1, sugar: 0, fiber: 1, serving: "1공기(210g)" },
    "현미밥": { cal: 340, carb: 72, prot: 7, fat: 2, sugar: 0, fiber: 3, serving: "1공기(210g)" },
    "잡곡밥": { cal: 320, carb: 67, prot: 7, fat: 2, sugar: 1, fiber: 4, serving: "1공기(210g)" },
    "볶음밥": { cal: 450, carb: 65, prot: 12, fat: 15, sugar: 3, fiber: 2, serving: "1인분(300g)" },
    "비빔밥": { cal: 550, carb: 75, prot: 18, fat: 18, sugar: 5, fiber: 5, serving: "1인분(450g)" },
    "김밥": { cal: 480, carb: 70, prot: 12, fat: 15, sugar: 4, fiber: 3, serving: "1줄(250g)" },
    "카레라이스": { cal: 520, carb: 78, prot: 14, fat: 16, sugar: 8, fiber: 3, serving: "1인분(400g)" },
    // 한국 면류
    "라면": { cal: 500, carb: 75, prot: 10, fat: 18, sugar: 4, fiber: 2, serving: "1봉지" },
    "짜장면": { cal: 650, carb: 95, prot: 15, fat: 22, sugar: 8, fiber: 3, serving: "1인분" },
    "짬뽕": { cal: 520, carb: 70, prot: 20, fat: 18, sugar: 5, fiber: 4, serving: "1인분" },
    "칼국수": { cal: 450, carb: 72, prot: 15, fat: 10, sugar: 3, fiber: 3, serving: "1인분" },
    "냉면": { cal: 480, carb: 90, prot: 12, fat: 5, sugar: 15, fiber: 3, serving: "1인분" },
    "비빔냉면": { cal: 550, carb: 88, prot: 14, fat: 12, sugar: 18, fiber: 4, serving: "1인분" },
    // 한국 국/찌개
    "김치찌개": { cal: 180, carb: 10, prot: 15, fat: 10, sugar: 3, fiber: 2, serving: "1인분(300g)" },
    "된장찌개": { cal: 150, carb: 12, prot: 10, fat: 8, sugar: 2, fiber: 3, serving: "1인분(300g)" },
    "순두부찌개": { cal: 200, carb: 8, prot: 14, fat: 12, sugar: 2, fiber: 1, serving: "1인분(350g)" },
    "미역국": { cal: 80, carb: 5, prot: 8, fat: 3, sugar: 1, fiber: 2, serving: "1그릇(300ml)" },
    "삼계탕": { cal: 650, carb: 35, prot: 45, fat: 35, sugar: 2, fiber: 2, serving: "1인분" },
    // 한국 고기류
    "삼겹살": { cal: 520, carb: 0, prot: 25, fat: 45, sugar: 0, fiber: 0, serving: "1인분(200g)" },
    "불고기": { cal: 350, carb: 15, prot: 28, fat: 20, sugar: 10, fiber: 1, serving: "1인분(150g)" },
    "갈비": { cal: 480, carb: 12, prot: 30, fat: 35, sugar: 8, fiber: 0, serving: "1인분(200g)" },
    "치킨": { cal: 550, carb: 20, prot: 35, fat: 38, sugar: 3, fiber: 1, serving: "반마리(350g)" },
    "제육볶음": { cal: 400, carb: 18, prot: 25, fat: 26, sugar: 8, fiber: 2, serving: "1인분(200g)" },
    // 한국 반찬류
    "김치": { cal: 20, carb: 4, prot: 1, fat: 0, sugar: 2, fiber: 2, serving: "1접시(50g)" },
    "계란후라이": { cal: 90, carb: 1, prot: 6, fat: 7, sugar: 0, fiber: 0, serving: "1개" },
    "계란찜": { cal: 120, carb: 3, prot: 10, fat: 8, sugar: 1, fiber: 0, serving: "1인분(150g)" },
    "두부": { cal: 80, carb: 2, prot: 8, fat: 5, sugar: 0, fiber: 1, serving: "1/4모(100g)" },
    // 미국/양식
    "햄버거": { cal: 540, carb: 45, prot: 25, fat: 30, sugar: 8, fiber: 2, serving: "1개" },
    "치즈버거": { cal: 620, carb: 48, prot: 30, fat: 35, sugar: 9, fiber: 2, serving: "1개" },
    "감자튀김": { cal: 320, carb: 42, prot: 4, fat: 15, sugar: 1, fiber: 4, serving: "중(130g)" },
    "피자": { cal: 270, carb: 33, prot: 12, fat: 10, sugar: 4, fiber: 2, serving: "1조각(100g)" },
    "스테이크": { cal: 400, carb: 0, prot: 45, fat: 24, sugar: 0, fiber: 0, serving: "1인분(200g)" },
    "샐러드": { cal: 150, carb: 12, prot: 5, fat: 10, sugar: 5, fiber: 4, serving: "1접시(200g)" },
    "시저샐러드": { cal: 280, carb: 15, prot: 12, fat: 20, sugar: 3, fiber: 3, serving: "1접시(250g)" },
    "파스타": { cal: 450, carb: 65, prot: 15, fat: 14, sugar: 5, fiber: 3, serving: "1인분(300g)" },
    "까르보나라": { cal: 550, carb: 60, prot: 18, fat: 28, sugar: 3, fiber: 2, serving: "1인분(350g)" },
    "샌드위치": { cal: 350, carb: 38, prot: 18, fat: 14, sugar: 5, fiber: 3, serving: "1개" },
    // 일본식
    "초밥": { cal: 45, carb: 8, prot: 3, fat: 1, sugar: 2, fiber: 0, serving: "1개" },
    "라멘": { cal: 480, carb: 65, prot: 18, fat: 16, sugar: 3, fiber: 2, serving: "1그릇" },
    "돈카츠": { cal: 550, carb: 35, prot: 28, fat: 35, sugar: 5, fiber: 2, serving: "1인분" },
    "우동": { cal: 380, carb: 70, prot: 12, fat: 5, sugar: 8, fiber: 2, serving: "1그릇" },
    "규동": { cal: 650, carb: 85, prot: 22, fat: 22, sugar: 12, fiber: 2, serving: "1그릇" },
    "오니기리": { cal: 180, carb: 38, prot: 4, fat: 1, sugar: 1, fiber: 1, serving: "1개" },
    // 중식
    "짜장밥": { cal: 580, carb: 90, prot: 14, fat: 18, sugar: 8, fiber: 3, serving: "1인분" },
    "탕수육": { cal: 450, carb: 40, prot: 20, fat: 24, sugar: 18, fiber: 1, serving: "1인분(200g)" },
    "깐풍기": { cal: 480, carb: 25, prot: 28, fat: 32, sugar: 12, fiber: 2, serving: "1인분(250g)" },
    "마파두부": { cal: 280, carb: 12, prot: 16, fat: 20, sugar: 3, fiber: 2, serving: "1인분(250g)" },
    // 음료
    "아메리카노": { cal: 5, carb: 1, prot: 0, fat: 0, sugar: 0, fiber: 0, serving: "1잔(355ml)" },
    "카페라떼": { cal: 150, carb: 12, prot: 8, fat: 8, sugar: 10, fiber: 0, serving: "1잔(355ml)" },
    "콜라": { cal: 140, carb: 39, prot: 0, fat: 0, sugar: 39, fiber: 0, serving: "1캔(355ml)" },
    "맥주": { cal: 150, carb: 13, prot: 1, fat: 0, sugar: 0, fiber: 0, serving: "1캔(355ml)" },
    "소주": { cal: 65, carb: 0, prot: 0, fat: 0, sugar: 0, fiber: 0, serving: "1잔(50ml)" },
    // 빵/디저트
    "식빵": { cal: 80, carb: 15, prot: 3, fat: 1, sugar: 2, fiber: 1, serving: "1장" },
    "크로아상": { cal: 230, carb: 26, prot: 5, fat: 12, sugar: 6, fiber: 1, serving: "1개" },
    "도넛": { cal: 250, carb: 30, prot: 4, fat: 14, sugar: 15, fiber: 1, serving: "1개" },
    "케이크": { cal: 350, carb: 45, prot: 5, fat: 18, sugar: 30, fiber: 1, serving: "1조각" },
    "아이스크림": { cal: 200, carb: 25, prot: 4, fat: 10, sugar: 20, fiber: 0, serving: "1스쿱(100g)" },
    // 과일
    "사과": { cal: 95, carb: 25, prot: 0, fat: 0, sugar: 19, fiber: 4, serving: "1개(200g)" },
    "바나나": { cal: 105, carb: 27, prot: 1, fat: 0, sugar: 14, fiber: 3, serving: "1개(120g)" },
    "오렌지": { cal: 62, carb: 15, prot: 1, fat: 0, sugar: 12, fiber: 3, serving: "1개(130g)" },
    "딸기": { cal: 50, carb: 12, prot: 1, fat: 0, sugar: 7, fiber: 3, serving: "10개(150g)" },
    "포도": { cal: 70, carb: 18, prot: 1, fat: 0, sugar: 16, fiber: 1, serving: "1송이(100g)" },
}

// Nutrition lookup function
const lookupNutrition = (foodName: string): { calories: number; carbs: number; protein: number; fat: number; sugar: number; fiber: number } | null => {
    const name = foodName.trim().toLowerCase()
    for (const [key, value] of Object.entries(NUTRITION_DB)) {
        if (name.includes(key.toLowerCase()) || key.toLowerCase().includes(name)) {
            return { calories: value.cal, carbs: value.carb, protein: value.prot, fat: value.fat, sugar: value.sugar, fiber: value.fiber }
        }
    }
    return null
}

// Common food names for autocomplete (by language)
const FOOD_NAMES: Record<string, string[]> = {
    ko: [
        // 밥/면류
        "흰밥", "현미밥", "잡곡밥", "볶음밥", "비빔밥", "김밥", "덮밥", "카레라이스",
        "라면", "짜장면", "짬뽕", "칼국수", "냉면", "비빔냉면", "쫄면", "잔치국수", "우동", "소바", "파스타", "스파게티", "까르보나라",
        // 국/찌개
        "된장찌개", "김치찌개", "순두부찌개", "부대찌개", "감자탕", "삼계탕", "설렁탕", "곰탕", "육개장", "미역국", "콩나물국", "떡국", "만둣국",
        // 고기
        "삼겹살", "목살", "갈비", "불고기", "제육볶음", "닭갈비", "닭볶음탕", "족발", "보쌈", "수육",
        "스테이크", "소고기", "돼지고기", "닭고기", "오리고기", "양고기",
        // 치킨/튀김
        "후라이드치킨", "양념치킨", "간장치킨", "치킨너겟", "치킨텐더", "닭강정",
        "돈까스", "치킨까스", "생선까스", "새우튀김", "오징어튀김", "고구마튀김", "김말이",
        // 해산물
        "생선구이", "고등어구이", "갈치구이", "삼치구이", "연어", "참치", "광어", "우럭",
        "새우", "오징어", "문어", "조개", "홍합", "굴", "게", "랍스터",
        "회", "초밥", "연어초밥", "참치초밥", "광어회",
        // 반찬
        "김치", "깍두기", "동치미", "열무김치", "파김치",
        "멸치볶음", "어묵볶음", "감자볶음", "버섯볶음", "호박볶음",
        "시금치나물", "콩나물", "숙주나물", "고사리나물", "도라지무침",
        "계란말이", "계란후라이", "스크램블에그", "삶은계란",
        "두부조림", "연두부", "순두부",
        // 분식
        "떡볶이", "순대", "튀김", "김밥", "라볶이", "쫄면",
        "만두", "군만두", "찐만두", "물만두", "만두국",
        // 빵/디저트
        "식빵", "토스트", "크루아상", "베이글", "바게트", "모닝빵",
        "케이크", "치즈케이크", "초코케이크", "딸기케이크", "티라미수", "롤케이크",
        "도넛", "머핀", "스콘", "마카롱", "쿠키", "브라우니",
        "와플", "팬케이크", "크레페", "호떡", "붕어빵", "타코야키",
        "아이스크림", "젤라또", "빙수", "팥빙수",
        // 과일
        "사과", "배", "귤", "오렌지", "바나나", "포도", "수박", "참외", "멜론",
        "딸기", "블루베리", "체리", "복숭아", "자두", "망고", "파인애플", "키위",
        // 음료
        "물", "탄산수", "콜라", "사이다", "주스", "오렌지주스", "사과주스",
        "커피", "아메리카노", "라떼", "카푸치노", "모카", "에스프레소",
        "녹차", "홍차", "우유", "두유", "요거트",
        "맥주", "소주", "막걸리", "와인", "샴페인",
        // 패스트푸드
        "햄버거", "치즈버거", "불고기버거", "새우버거",
        "피자", "페퍼로니피자", "치즈피자", "콤비네이션피자",
        "샌드위치", "클럽샌드위치", "에그샌드위치", "BLT샌드위치",
        "핫도그", "감자튀김", "어니언링", "치즈스틱",
        // 샐러드/건강식
        "샐러드", "시저샐러드", "과일샐러드", "닭가슴살샐러드",
        "닭가슴살", "고구마", "단호박", "브로콜리", "아보카도",
        "오트밀", "그래놀라", "시리얼", "프로틴쉐이크",
    ],
    en: [
        // Rice/Noodles
        "white rice", "brown rice", "fried rice", "bibimbap", "curry rice",
        "ramen", "udon", "soba", "pasta", "spaghetti", "carbonara", "alfredo", "pho",
        // Soups
        "chicken soup", "tomato soup", "mushroom soup", "clam chowder", "miso soup",
        // Meat
        "steak", "beef", "pork", "chicken", "lamb", "turkey", "bacon", "ham", "sausage",
        "grilled chicken", "roast beef", "pork chop", "lamb chop", "meatball",
        // Fried
        "fried chicken", "chicken nuggets", "chicken wings", "chicken tenders",
        "fish and chips", "onion rings", "french fries", "mozzarella sticks",
        // Seafood
        "salmon", "tuna", "cod", "shrimp", "lobster", "crab", "oyster", "clam", "mussel",
        "sushi", "sashimi", "fish fillet", "grilled fish",
        // Fast food
        "hamburger", "cheeseburger", "big mac", "whopper",
        "pizza", "pepperoni pizza", "cheese pizza", "margherita",
        "sandwich", "club sandwich", "BLT", "grilled cheese",
        "hot dog", "taco", "burrito", "quesadilla", "nachos",
        // Breakfast
        "pancakes", "waffles", "french toast", "eggs benedict", "omelette",
        "scrambled eggs", "fried egg", "boiled egg", "bacon and eggs",
        "cereal", "oatmeal", "granola", "yogurt parfait",
        // Bread/Pastry
        "bread", "toast", "croissant", "bagel", "muffin", "donut", "scone",
        // Dessert
        "cake", "cheesecake", "chocolate cake", "carrot cake", "tiramisu",
        "ice cream", "gelato", "sundae", "brownie", "cookie", "macaron",
        "pie", "apple pie", "pumpkin pie", "pudding", "creme brulee",
        // Fruits
        "apple", "banana", "orange", "grape", "strawberry", "blueberry", "watermelon",
        "mango", "pineapple", "peach", "cherry", "kiwi", "avocado",
        // Vegetables/Salad
        "salad", "caesar salad", "greek salad", "garden salad",
        "broccoli", "spinach", "carrot", "tomato", "cucumber", "lettuce",
        // Drinks
        "water", "coffee", "latte", "cappuccino", "espresso", "americano",
        "tea", "green tea", "milk", "juice", "orange juice", "smoothie",
        "beer", "wine", "cocktail", "soda", "cola",
    ],
    ja: [
        // ご飯/麺
        "白米", "玄米", "炒飯", "チャーハン", "カレーライス", "牛丼", "親子丼", "カツ丼",
        "ラーメン", "味噌ラーメン", "塩ラーメン", "醤油ラーメン", "うどん", "そば", "焼きそば", "パスタ",
        // 汁物
        "味噌汁", "豚汁", "けんちん汁", "お吸い物",
        // 肉
        "焼肉", "ステーキ", "牛肉", "豚肉", "鶏肉", "ハンバーグ", "生姜焼き", "唐揚げ",
        "とんかつ", "チキンカツ", "コロッケ", "メンチカツ",
        // 魚介
        "刺身", "寿司", "マグロ", "サーモン", "エビ", "イカ", "タコ", "貝",
        "焼き魚", "サバ", "サンマ", "アジ", "鮭",
        // ファストフード
        "ハンバーガー", "チーズバーガー", "ピザ", "サンドイッチ", "ホットドッグ",
        // 朝食
        "トースト", "パンケーキ", "ワッフル", "オムレツ", "目玉焼き", "スクランブルエッグ",
        // パン/デザート
        "パン", "クロワッサン", "ベーグル", "マフィン", "ドーナツ",
        "ケーキ", "チーズケーキ", "ティラミス", "アイスクリーム", "プリン",
        // 果物
        "りんご", "バナナ", "オレンジ", "ぶどう", "いちご", "メロン", "スイカ",
        // 飲み物
        "水", "コーヒー", "紅茶", "緑茶", "牛乳", "ジュース", "ビール", "ワイン",
    ],
    zh: [
        // 饭/面
        "白饭", "炒饭", "盖饭", "咖喱饭", "炒面", "拉面", "担担面", "意大利面",
        // 汤
        "蛋花汤", "紫菜汤", "酸辣汤", "味噌汤",
        // 肉
        "牛肉", "猪肉", "鸡肉", "羊肉", "红烧肉", "糖醋排骨", "宫保鸡丁", "麻婆豆腐",
        "炸鸡", "鸡块", "烤肉", "牛排",
        // 海鲜
        "鱼", "虾", "蟹", "鱿鱼", "三文鱼", "金枪鱼", "寿司", "刺身",
        // 快餐
        "汉堡", "披萨", "三明治", "热狗", "薯条",
        // 早餐
        "面包", "吐司", "煎蛋", "炒蛋", "煮蛋", "粥", "豆浆", "油条",
        // 甜点
        "蛋糕", "芝士蛋糕", "冰淇淋", "布丁", "饼干", "马卡龙",
        // 水果
        "苹果", "香蕉", "橙子", "葡萄", "草莓", "西瓜", "芒果",
        // 饮料
        "水", "咖啡", "茶", "牛奶", "果汁", "可乐", "啤酒", "葡萄酒",
    ],
    fr: [
        // Plats
        "riz", "pâtes", "pizza", "hamburger", "sandwich", "salade",
        "steak", "poulet", "porc", "agneau", "poisson", "saumon", "thon",
        "omelette", "crêpe", "quiche", "soupe", "potage",
        // Petit-déjeuner
        "croissant", "pain", "baguette", "toast", "œuf", "bacon",
        // Desserts
        "gâteau", "tarte", "crème brûlée", "mousse au chocolat", "macaron",
        "glace", "sorbet", "profiterole", "éclair",
        // Fruits
        "pomme", "banane", "orange", "fraise", "raisin", "pêche",
        // Boissons
        "eau", "café", "thé", "lait", "jus", "vin", "bière", "champagne",
    ],
    de: [
        // Hauptgerichte
        "Reis", "Nudeln", "Pizza", "Hamburger", "Sandwich", "Salat",
        "Steak", "Hähnchen", "Schweinefleisch", "Rindfleisch", "Fisch", "Lachs",
        "Schnitzel", "Bratwurst", "Currywurst", "Döner",
        // Frühstück
        "Brot", "Brötchen", "Croissant", "Toast", "Ei", "Speck", "Müsli",
        // Desserts
        "Kuchen", "Torte", "Eis", "Pudding", "Keks", "Schokolade",
        // Obst
        "Apfel", "Banane", "Orange", "Erdbeere", "Traube", "Wassermelone",
        // Getränke
        "Wasser", "Kaffee", "Tee", "Milch", "Saft", "Bier", "Wein",
    ],
}

// Get food name suggestions based on input
const getFoodNameSuggestions = (input: string, lang: string, limit: number = 5): string[] => {
    if (!input || input.length < 1) return []
    const lower = input.toLowerCase()
    const foods = FOOD_NAMES[lang] || FOOD_NAMES.en
    return foods
        .filter(food => food.toLowerCase().includes(lower))
        .slice(0, limit)
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
    totalCarbs = 0,
    totalProtein = 0,
    totalFiber = 0,
    foods = [],
    cardRef,
    lang = "ko",
    theme = "default",
    aspectRatio = { width: 3, height: 4 },
}: CardProps) => {
    const { isDigital, isNeon, isSpecialTheme, fontStyle, glowStyle } = getCardStyles(theme)
    const ts = formatTimestamp(timestamp, lang, isSpecialTheme)
    const isPortrait = aspectRatio.height > aspectRatio.width
    const maxFoods = isPortrait ? 7 : 4
    const displayFoods = foods.slice(0, maxFoods)
    const mainFontSize = isDigital ? 34 : isNeon ? 24 : 26
    const subFontSize = isDigital ? 14 : isNeon ? 9 : 10
    const foodFontSize = isDigital ? 14 : 13
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
                <div style={{ marginBottom: 6 }}>
                    {displayFoods.map((food: any, i: number) => (
                        <div
                            key={i}
                            style={{
                                display: "flex",
                                justifyContent: "space-between",
                                padding: "4px 0",
                                fontSize: foodFontSize,
                                borderBottom:
                                    i < displayFoods.length - 1
                                        ? "1px solid rgba(255,255,255,0.1)"
                                        : "none",
                            }}
                        >
                            <span style={{ opacity: 0.85 }}>{food.name}</span>
                            <span style={{ fontWeight: 600 }}>
                                {food.calories} <span style={{ fontWeight: 400, fontSize: foodFontSize * 0.85, opacity: 0.7 }}>kcal</span>
                            </span>
                        </div>
                    ))}
                    {foods.length > maxFoods && (
                        <div
                            style={{
                                fontSize: 11,
                                opacity: 0.4,
                                textAlign: "center",
                                marginTop: 4,
                            }}
                        >
                            +{foods.length - maxFoods}
                        </div>
                    )}
                </div>
                <div
                    style={{
                        display: "flex",
                        justifyContent: "space-between",
                        alignItems: "flex-end",
                        paddingTop: 8,
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

const HealthCard = ({
    capturedImage,
    timestamp,
    totalCalories,
    totalCarbs = 0,
    totalProtein = 0,
    totalFat = 0,
    totalSugar = 0,
    totalFiber = 0,
    foods = [],
    cardRef,
    lang = "ko",
    theme = "default",
    aspectRatio = { width: 3, height: 4 },
}: CardProps & { totalSugar?: number }) => {
    const { isDigital, isNeon, isSpecialTheme, fontStyle, glowStyle } = getCardStyles(theme)
    const ts = formatTimestamp(timestamp, lang, isSpecialTheme)
    const isPortrait = aspectRatio.height > aspectRatio.width
    const maxFoods = isPortrait ? 6 : 3
    const displayFoods = foods.slice(0, maxFoods)
    const mainFontSize = isDigital ? 28 : 22
    const macroBarFontSize = isDigital ? 18 : 14
    const subFontSize = isDigital ? 14 : isNeon ? 9 : 10
    const dateDisplay = isSpecialTheme ? `${ts.date} ${ts.day}` : `${ts.date} (${ts.day})`
    const ratioString = `${aspectRatio.width}/${aspectRatio.height}`

    // Macro labels by language
    const macroLabels = {
        ko: { carbs: "탄", protein: "단", fat: "지", sugar: "당", fiber: "섬" },
        en: { carbs: "C", protein: "P", fat: "F", sugar: "S", fiber: "Fi" },
        ja: { carbs: "炭", protein: "蛋", fat: "脂", sugar: "糖", fiber: "繊" },
        zh: { carbs: "碳", protein: "蛋", fat: "脂", sugar: "糖", fiber: "纤" },
        fr: { carbs: "G", protein: "P", fat: "L", sugar: "S", fiber: "F" },
        de: { carbs: "K", protein: "E", fat: "F", sugar: "Z", fiber: "B" },
    }[lang] || { carbs: "C", protein: "P", fat: "F", sugar: "S", fiber: "Fi" }

    const macroFullLabels = {
        ko: { carbs: "탄수화물", protein: "단백질", fat: "지방", sugar: "당류", fiber: "식이섬유" },
        en: { carbs: "Carbs", protein: "Protein", fat: "Fat", sugar: "Sugar", fiber: "Fiber" },
        ja: { carbs: "炭水化物", protein: "タンパク質", fat: "脂質", sugar: "糖質", fiber: "食物繊維" },
        zh: { carbs: "碳水", protein: "蛋白质", fat: "脂肪", sugar: "糖", fiber: "纤维" },
        fr: { carbs: "Glucides", protein: "Protéines", fat: "Lipides", sugar: "Sucres", fiber: "Fibres" },
        de: { carbs: "Kohlenh.", protein: "Eiweiß", fat: "Fett", sugar: "Zucker", fiber: "Ballast." },
    }[lang] || { carbs: "Carbs", protein: "Protein", fat: "Fat", sugar: "Sugar", fiber: "Fiber" }

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
                    height: "75%",
                    background:
                        "linear-gradient(to top, rgba(0,0,0,0.92) 0%, transparent 100%)",
                    pointerEvents: "none",
                }}
            />
            <div
                style={{
                    position: "absolute",
                    bottom: 14,
                    left: 14,
                    right: 14,
                    color: "#fff",
                }}
            >
                {/* Food items with calories and macros */}
                <div style={{ marginBottom: 8 }}>
                    {displayFoods.map((food: any, i: number) => (
                        <div
                            key={i}
                            style={{
                                display: "flex",
                                justifyContent: "space-between",
                                alignItems: "center",
                                padding: "4px 0",
                                fontSize: 12,
                                borderBottom:
                                    i < displayFoods.length - 1
                                        ? "1px solid rgba(255,255,255,0.08)"
                                        : "none",
                            }}
                        >
                            <span style={{ opacity: 0.9, flex: 1 }}>{food.name}</span>
                            <div style={{ display: "flex", gap: 6, fontSize: 10, alignItems: "center" }}>
                                <span style={{ opacity: 0.55 }}>{macroLabels.carbs}{food.carbs || 0}</span>
                                <span style={{ opacity: 0.55 }}>{macroLabels.protein}{food.protein || 0}</span>
                                <span style={{ opacity: 0.55 }}>{macroLabels.fat}{food.fat || 0}</span>
                                <span style={{ opacity: 0.55 }}>{macroLabels.sugar}{food.sugar || 0}</span>
                                <span style={{ opacity: 0.55 }}>{macroLabels.fiber}{food.fiber || 0}</span>
                                <span style={{ opacity: 0.9, fontWeight: 600, marginLeft: 2 }}>{food.calories || 0}kcal</span>
                            </div>
                        </div>
                    ))}
                    {foods.length > maxFoods && (
                        <div style={{ fontSize: 10, opacity: 0.4, textAlign: "center", marginTop: 2 }}>
                            +{foods.length - maxFoods}
                        </div>
                    )}
                </div>

                {/* Time & Calories */}
                <div
                    style={{
                        display: "flex",
                        justifyContent: "space-between",
                        alignItems: "flex-end",
                        marginBottom: 8,
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
                                opacity: 0.5,
                                marginTop: 2,
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
                                opacity: 0.5,
                                marginTop: 2,
                            }}
                        >
                            KCAL
                        </div>
                    </div>
                </div>

                {/* Total Macros Bar - below time/date */}
                <div
                    style={{
                        display: "flex",
                        justifyContent: "space-between",
                        padding: "10px 8px",
                        background: "rgba(255,255,255,0.1)",
                        borderRadius: 8,
                    }}
                >
                    <div style={{ textAlign: "center", flex: 1 }}>
                        <div style={{ fontSize: macroBarFontSize, fontWeight: 700, fontFamily: fontStyle, ...glowStyle }}>{totalCarbs}</div>
                        <div style={{ fontSize: 8, opacity: 0.6 }}>{macroFullLabels.carbs}</div>
                    </div>
                    <div style={{ width: 1, background: "rgba(255,255,255,0.15)" }} />
                    <div style={{ textAlign: "center", flex: 1 }}>
                        <div style={{ fontSize: macroBarFontSize, fontWeight: 700, fontFamily: fontStyle, ...glowStyle }}>{totalProtein}</div>
                        <div style={{ fontSize: 8, opacity: 0.6 }}>{macroFullLabels.protein}</div>
                    </div>
                    <div style={{ width: 1, background: "rgba(255,255,255,0.15)" }} />
                    <div style={{ textAlign: "center", flex: 1 }}>
                        <div style={{ fontSize: macroBarFontSize, fontWeight: 700, fontFamily: fontStyle, ...glowStyle }}>{totalFat}</div>
                        <div style={{ fontSize: 8, opacity: 0.6 }}>{macroFullLabels.fat}</div>
                    </div>
                    <div style={{ width: 1, background: "rgba(255,255,255,0.15)" }} />
                    <div style={{ textAlign: "center", flex: 1 }}>
                        <div style={{ fontSize: macroBarFontSize, fontWeight: 700, fontFamily: fontStyle, ...glowStyle }}>{totalSugar}</div>
                        <div style={{ fontSize: 8, opacity: 0.6 }}>{macroFullLabels.sugar}</div>
                    </div>
                    <div style={{ width: 1, background: "rgba(255,255,255,0.15)" }} />
                    <div style={{ textAlign: "center", flex: 1 }}>
                        <div style={{ fontSize: macroBarFontSize, fontWeight: 700, fontFamily: fontStyle, ...glowStyle }}>{totalFiber}</div>
                        <div style={{ fontSize: 8, opacity: 0.6 }}>{macroFullLabels.fiber}</div>
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
    const [nameSuggestionsIndex, setNameSuggestionsIndex] = useState<number | null>(null)
    const [zoomLevel, setZoomLevel] = useState(1)
    const lastPinchDistance = useRef<number | null>(null)
    const blurTimeoutRef = useRef<NodeJS.Timeout | null>(null)

    const videoRef = useRef<HTMLVideoElement>(null)
    const previewVideoRef = useRef<HTMLVideoElement>(null)
    const canvasRef = useRef<HTMLCanvasElement>(null)
    const fileInputRef = useRef<HTMLInputElement>(null)
    const simpleCardRef = useRef<HTMLDivElement>(null)
    const detailedCardRef = useRef<HTMLDivElement>(null)
    const healthCardRef = useRef<HTMLDivElement>(null)
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
        if (typeof window === "undefined") return

        const handleResize = () => {
            if (window.visualViewport) {
                const viewportHeight = window.visualViewport.height
                const windowHeight = window.innerHeight
                const diff = windowHeight - viewportHeight
                setKeyboardHeight(diff > 100 ? diff : 0)
            }
        }

        if (window.visualViewport) {
            window.visualViewport.addEventListener("resize", handleResize)
            window.visualViewport.addEventListener("scroll", handleResize)
        }

        return () => {
            if (window.visualViewport) {
                window.visualViewport.removeEventListener("resize", handleResize)
                window.visualViewport.removeEventListener("scroll", handleResize)
            }
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

    // Reset zoom when switching cameras or screens
    useEffect(() => {
        setZoomLevel(1)
        lastPinchDistance.current = null
    }, [facingMode, screen])

    // Pinch zoom handlers
    const handleTouchStart = useCallback((e: React.TouchEvent) => {
        if (e.touches.length === 2) {
            const dx = e.touches[0].clientX - e.touches[1].clientX
            const dy = e.touches[0].clientY - e.touches[1].clientY
            lastPinchDistance.current = Math.hypot(dx, dy)
        }
    }, [])

    const handleTouchMove = useCallback((e: React.TouchEvent) => {
        if (e.touches.length === 2 && lastPinchDistance.current !== null) {
            const dx = e.touches[0].clientX - e.touches[1].clientX
            const dy = e.touches[0].clientY - e.touches[1].clientY
            const distance = Math.hypot(dx, dy)
            const scale = distance / lastPinchDistance.current
            setZoomLevel((prev) => Math.min(Math.max(prev * scale, 1), 4))
            lastPinchDistance.current = distance
        }
    }, [])

    const handleTouchEnd = useCallback(() => {
        lastPinchDistance.current = null
    }, [])

    const capturePhoto = async () => {
        if (!previewVideoRef.current || !canvasRef.current) return
        setShowFlash(true)
        setTimeout(() => setShowFlash(false), 200)
        const video = previewVideoRef.current,
            canvas = canvasRef.current,
            ctx = canvas.getContext("2d")!
        const vw = video.videoWidth,
            vh = video.videoHeight,
            baseSize = Math.min(vw, vh),
            // Apply zoom: smaller source area = more zoom
            size = baseSize / zoomLevel,
            out = Math.min(1024, baseSize)
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
        if (!isPro && !sessionPaid && aiCredits <= 0) {
            setShowUpgrade(true)
            return
        }
        const toCalc = foods.filter((f) => f.name?.trim() && !f.calories)
        if (!toCalc.length) return alert("계산할 음식이 없습니다.")

        setIsCalculating(true)

        // Step 1: Try local DB first
        const localResults: (typeof NUTRITION_DB[string] | null)[] = []
        const needsApi: typeof toCalc = []

        toCalc.forEach((f) => {
            const local = lookupNutrition(f.name)
            if (local) {
                localResults.push({ cal: local.calories, carb: local.carbs, prot: local.protein, fat: local.fat, sugar: local.sugar, fiber: local.fiber, serving: "" })
            } else {
                localResults.push(null)
                needsApi.push(f)
            }
        })

        // If all found in local DB, skip API
        if (needsApi.length === 0) {
            let idx = 0
            setFoods(foods.map((f) => {
                if (f.name?.trim() && !f.calories && idx < localResults.length) {
                    const n = localResults[idx++]
                    if (n) {
                        return { ...f, calories: String(n.cal), carbs: String(n.carb), protein: String(n.prot), fat: String(n.fat), sugar: String(n.sugar), fiber: String(n.fiber) }
                    }
                }
                return f
            }))
            setIsCalculating(false)
            return
        }

        // Step 2: Call API for remaining items
        if (!apiKey) {
            // Use local results only
            let idx = 0
            setFoods(foods.map((f) => {
                if (f.name?.trim() && !f.calories && idx < localResults.length) {
                    const n = localResults[idx++]
                    if (n) {
                        return { ...f, calories: String(n.cal), carbs: String(n.carb), protein: String(n.prot), fat: String(n.fat), sugar: String(n.sugar), fiber: String(n.fiber) }
                    }
                }
                return f
            }))
            setIsCalculating(false)
            return alert("로컬 DB에 없는 음식이 있습니다. API 키가 필요합니다.")
        }

        if (!isPro && !sessionPaid) {
            updateCredits(Math.max(0, aiCredits - 1))
            setSessionPaid(true)
        }

        const controller = new AbortController(),
            timeout = setTimeout(() => controller.abort(), 30000)
        try {
            const list = needsApi
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
                                content: `You are a professional nutritionist with access to official food databases:
- Korea: 식품의약품안전처 영양성분 DB
- USA: USDA FoodData Central
- Japan: 日本食品標準成分表
- International: FAO/WHO nutrition data

INSTRUCTIONS:
1. Identify each food item's origin/cuisine type
2. Use the appropriate regional database for accuracy
3. Consider the specified portion size carefully
4. If portion is vague (e.g., "1인분", "한 그릇"), use standard serving sizes:
   - Rice bowl (공기밥): 210g
   - Soup bowl: 300-400ml
   - Side dish (반찬): 50-80g
   - Meat portion: 100-150g

Return ONLY a JSON array with objects containing:
- calories (kcal, integer)
- carbs (g, integer)
- protein (g, integer)
- fat (g, integer)
- sugar (g, integer)
- fiber (g, integer)

Be precise. No explanations, just the JSON array.
Example: [{"calories":320,"carbs":45,"protein":12,"fat":8,"sugar":5,"fiber":3}]`,
                            },
                            { role: "user", content: list },
                        ],
                        max_tokens: 500,
                        temperature: 0.1,
                    }),
                }
            )
            clearTimeout(timeout)
            const data = await response.json()
            if (data.error) throw new Error(data.error.message)
            const apiNutrition = JSON.parse(
                (data.choices?.[0]?.message?.content || "[]")
                    .replace(/```json\n?|\n?```/g, "")
                    .trim()
            )

            // Merge local + API results
            let localIdx = 0
            let apiIdx = 0
            setFoods(
                foods.map((f) => {
                    if (f.name?.trim() && !f.calories && localIdx < localResults.length) {
                        const localN = localResults[localIdx++]
                        if (localN) {
                            return { ...f, calories: String(localN.cal), carbs: String(localN.carb), protein: String(localN.prot), fat: String(localN.fat), sugar: String(localN.sugar), fiber: String(localN.fiber) }
                        } else if (apiIdx < apiNutrition.length) {
                            const n = apiNutrition[apiIdx++]
                            return { ...f, calories: String(n?.calories ?? 0), carbs: String(n?.carbs ?? 0), protein: String(n?.protein ?? 0), fat: String(n?.fat ?? 0), sugar: String(n?.sugar ?? 0), fiber: String(n?.fiber ?? 0) }
                        }
                    }
                    return f
                })
            )
        } catch (e: any) {
            // On API error, still apply local results
            let idx = 0
            setFoods(foods.map((f) => {
                if (f.name?.trim() && !f.calories && idx < localResults.length) {
                    const n = localResults[idx++]
                    if (n) {
                        return { ...f, calories: String(n.cal), carbs: String(n.carb), protein: String(n.prot), fat: String(n.fat), sugar: String(n.sugar), fiber: String(n.fiber) }
                    }
                }
                return f
            }))
            alert(e?.name === "AbortError" ? "시간 초과 (로컬 DB 결과만 적용)" : "API 오류 (로컬 DB 결과만 적용)")
        } finally {
            setIsCalculating(false)
        }
    }

    const totalCalories = foods.reduce(
        (s, f) => s + (parseInt(f.calories) || 0),
        0
    )
    const totalCarbs = foods.reduce(
        (s, f) => s + (parseInt(f.carbs) || 0),
        0
    )
    const totalProtein = foods.reduce(
        (s, f) => s + (parseInt(f.protein) || 0),
        0
    )
    const totalFat = foods.reduce(
        (s, f) => s + (parseInt(f.fat) || 0),
        0
    )
    const totalSugar = foods.reduce(
        (s, f) => s + (parseInt(f.sugar) || 0),
        0
    )
    const totalFiber = foods.reduce(
        (s, f) => s + (parseInt(f.fiber) || 0),
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
                : selectedCardType === CARD_TYPES.DETAILED
                ? detailedCardRef
                : healthCardRef
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
            // iOS: 새 탭에서 이미지 열기 → 길게 눌러 저장
            canvas.toBlob(async (blob: Blob | null) => {
                if (!blob) return
                const blobUrl = URL.createObjectURL(blob)
                window.open(blobUrl, "_blank")
                toast(t("saveHint"), 2500)
                setTimeout(() => URL.revokeObjectURL(blobUrl), 60000)
            }, "image/png")
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
                : selectedCardType === CARD_TYPES.DETAILED
                ? detailedCardRef
                : healthCardRef
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
                                onTouchStart={handleTouchStart}
                                onTouchMove={handleTouchMove}
                                onTouchEnd={handleTouchEnd}
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
                                        transform: `${facingMode === "user" ? "scaleX(-1) " : ""}scale(${zoomLevel})`,
                                        transition: "transform 0.1s ease-out",
                                    }}
                                />
                                {/* Corner Guidelines */}
                                <div style={{ position: "absolute", top: 12, left: 12, width: 24, height: 24, borderTop: "2px solid rgba(255,255,255,0.6)", borderLeft: "2px solid rgba(255,255,255,0.6)", borderRadius: "4px 0 0 0" }} />
                                <div style={{ position: "absolute", top: 12, right: 12, width: 24, height: 24, borderTop: "2px solid rgba(255,255,255,0.6)", borderRight: "2px solid rgba(255,255,255,0.6)", borderRadius: "0 4px 0 0" }} />
                                <div style={{ position: "absolute", bottom: 12, left: 12, width: 24, height: 24, borderBottom: "2px solid rgba(255,255,255,0.6)", borderLeft: "2px solid rgba(255,255,255,0.6)", borderRadius: "0 0 0 4px" }} />
                                <div style={{ position: "absolute", bottom: 12, right: 12, width: 24, height: 24, borderBottom: "2px solid rgba(255,255,255,0.6)", borderRight: "2px solid rgba(255,255,255,0.6)", borderRadius: "0 0 4px 0" }} />

                                {/* Zoom Controls */}
                                <div
                                    style={{
                                        position: "absolute",
                                        bottom: 12,
                                        left: "50%",
                                        transform: "translateX(-50%)",
                                        display: "flex",
                                        alignItems: "center",
                                        gap: 8,
                                        background: "rgba(0,0,0,0.5)",
                                        borderRadius: DS.radius.full,
                                        padding: "4px 8px",
                                    }}
                                >
                                    <button
                                        onClick={() => setZoomLevel(prev => Math.max(1, prev - 0.5))}
                                        style={{
                                            width: 24,
                                            height: 24,
                                            borderRadius: "50%",
                                            background: "rgba(255,255,255,0.2)",
                                            border: "none",
                                            color: "#fff",
                                            fontSize: 16,
                                            fontWeight: 700,
                                            cursor: "pointer",
                                            display: "flex",
                                            alignItems: "center",
                                            justifyContent: "center",
                                        }}
                                    >
                                        -
                                    </button>
                                    <span style={{ color: "#fff", fontSize: 11, fontWeight: 600, minWidth: 32, textAlign: "center" }}>
                                        {zoomLevel.toFixed(1)}x
                                    </span>
                                    <button
                                        onClick={() => setZoomLevel(prev => Math.min(4, prev + 0.5))}
                                        style={{
                                            width: 24,
                                            height: 24,
                                            borderRadius: "50%",
                                            background: "rgba(255,255,255,0.2)",
                                            border: "none",
                                            color: "#fff",
                                            fontSize: 16,
                                            fontWeight: 700,
                                            cursor: "pointer",
                                            display: "flex",
                                            alignItems: "center",
                                            justifyContent: "center",
                                        }}
                                    >
                                        +
                                    </button>
                                </div>
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
                        <button
                            onClick={resetToCamera}
                            style={{
                                marginTop: 24,
                                padding: "10px 24px",
                                fontSize: DS.fontSize.sm,
                                fontWeight: 600,
                                color: DS.colors.gray[500],
                                background: DS.colors.gray[100],
                                border: "none",
                                borderRadius: DS.radius.full,
                                cursor: "pointer",
                            }}
                        >
                            {t("cancel")}
                        </button>
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
                                        onFocus={() => {
                                            if (blurTimeoutRef.current) clearTimeout(blurTimeoutRef.current)
                                            setFocusedFoodIndex(i)
                                            setNameSuggestionsIndex(i)
                                        }}
                                        onBlur={() => {
                                            blurTimeoutRef.current = setTimeout(() => {
                                                setFocusedFoodIndex(null)
                                                setNameSuggestionsIndex(null)
                                            }, 200)
                                        }}
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
                                    {/* Food name autocomplete dropdown */}
                                    {nameSuggestionsIndex === i && food.name.length >= 1 && (
                                        (() => {
                                            const suggestions = getFoodNameSuggestions(food.name, lang, 5)
                                            if (suggestions.length === 0) return null
                                            return (
                                                <div
                                                    style={{
                                                        position: "absolute",
                                                        top: "100%",
                                                        left: 0,
                                                        right: 0,
                                                        marginTop: 4,
                                                        background: DS.colors.white,
                                                        border: `1px solid ${DS.colors.gray[200]}`,
                                                        borderRadius: DS.radius.sm,
                                                        boxShadow: "0 4px 12px rgba(0,0,0,0.1)",
                                                        zIndex: 100,
                                                        overflow: "hidden",
                                                    }}
                                                >
                                                    {suggestions.map((suggestion, idx) => (
                                                        <button
                                                            key={idx}
                                                            onMouseDown={(e) => {
                                                                e.preventDefault()
                                                                handleFoodChange(i, "name", suggestion)
                                                                setNameSuggestionsIndex(null)
                                                            }}
                                                            style={{
                                                                width: "100%",
                                                                padding: "10px 12px",
                                                                background: "transparent",
                                                                border: "none",
                                                                borderBottom: idx < suggestions.length - 1 ? `1px solid ${DS.colors.gray[100]}` : "none",
                                                                cursor: "pointer",
                                                                textAlign: "left",
                                                                fontSize: 14,
                                                                color: DS.colors.gray[700],
                                                                transition: "background 0.1s",
                                                            }}
                                                            onMouseEnter={(e) => {
                                                                e.currentTarget.style.background = DS.colors.gray[50]
                                                            }}
                                                            onMouseLeave={(e) => {
                                                                e.currentTarget.style.background = "transparent"
                                                            }}
                                                        >
                                                            {suggestion}
                                                        </button>
                                                    ))}
                                                </div>
                                            )
                                        })()
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
                                        onFocus={() => {
                                            if (blurTimeoutRef.current) clearTimeout(blurTimeoutRef.current)
                                            setFocusedFoodIndex(i)
                                        }}
                                        onBlur={() => {
                                            blurTimeoutRef.current = setTimeout(() => setFocusedFoodIndex(null), 200)
                                        }}
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
                        bottom: keyboardHeight,
                        left: 0,
                        right: 0,
                        padding: `12px ${DS.content.paddingX}px`,
                        paddingBottom: keyboardHeight > 0 ? 10 : "max(14px, env(safe-area-inset-bottom))",
                        background: DS.colors.white,
                        borderTop: `1px solid ${DS.colors.gray[200]}`,
                        zIndex: 100,
                        transition: "bottom 0.15s ease-out",
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
        const hasMacrosData = foods.some(f => f.carbs !== undefined || f.protein !== undefined || f.fat !== undefined || f.fiber !== undefined)
        const isProFeature =
            selectedCardType === CARD_TYPES.DETAILED ||
            selectedCardType === CARD_TYPES.HEALTH ||
            (selectedCardType === CARD_TYPES.SIMPLE &&
                selectedTheme !== CARD_THEMES.DEFAULT)

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

                {/* Card Preview Area - Full Dark Background */}
                <div
                    style={{
                        flex: 1,
                        display: "flex",
                        flexDirection: "column",
                        alignItems: "center",
                        justifyContent: "center",
                        padding: `20px ${DS.content.paddingX}px`,
                        minHeight: 0,
                        background: "#1a1a1a",
                        position: "relative",
                    }}
                >
                    {/* Design Options Overlay */}
                    <div
                        style={{
                            position: "absolute",
                            top: 0,
                            left: 0,
                            right: 0,
                            padding: `12px ${DS.content.paddingX}px`,
                            display: "flex",
                            flexDirection: "column",
                            alignItems: "center",
                            gap: 8,
                            background: "linear-gradient(to bottom, rgba(0,0,0,0.6) 0%, transparent 100%)",
                            paddingBottom: 40,
                        }}
                    >
                        {/* Card Type Toggle */}
                        <div
                            style={{
                                display: "flex",
                                background: "rgba(255,255,255,0.15)",
                                borderRadius: DS.radius.full,
                                padding: 3,
                                backdropFilter: "blur(10px)",
                            }}
                        >
                            {[
                                { key: CARD_TYPES.SIMPLE, label: t("simple") },
                                { key: CARD_TYPES.DETAILED, label: t("detailed"), isPro: true },
                                { key: CARD_TYPES.HEALTH, label: t("health") || "건강", isPro: true, needsMacros: true },
                            ].map((item) => {
                                const active = selectedCardType === item.key
                                const disabled = item.needsMacros && !hasMacrosData
                                return (
                                    <button
                                        key={item.key}
                                        onClick={() => !disabled && setSelectedCardType(item.key as any)}
                                        style={{
                                            border: "none",
                                            cursor: disabled ? "not-allowed" : "pointer",
                                            borderRadius: DS.radius.full,
                                            padding: "7px 12px",
                                            fontSize: 12,
                                            fontWeight: 600,
                                            background: active ? "rgba(255,255,255,0.95)" : "transparent",
                                            color: disabled ? "rgba(255,255,255,0.3)" : active ? "#000" : "rgba(255,255,255,0.7)",
                                            display: "flex",
                                            alignItems: "center",
                                            justifyContent: "center",
                                            gap: 3,
                                            transition: "all 0.15s ease",
                                            opacity: disabled ? 0.5 : 1,
                                        }}
                                    >
                                        {item.isPro && <Icon.Sparkle size={8} />}
                                        {item.label}
                                    </button>
                                )
                            })}
                        </div>

                        {/* Theme & Ratio Row */}
                        <div style={{ display: "flex", gap: 6, flexWrap: "wrap", justifyContent: "center" }}>
                            {[
                                { key: CARD_THEMES.DEFAULT, label: t("themeDefault") },
                                { key: CARD_THEMES.DIGITAL, label: t("themeDigital") },
                                { key: CARD_THEMES.NEON, label: t("themeNeon") },
                            ].map((item) => {
                                const isProTheme = selectedCardType === CARD_TYPES.DETAILED || selectedCardType === CARD_TYPES.HEALTH || item.key !== CARD_THEMES.DEFAULT
                                const active = selectedTheme === item.key
                                return (
                                    <button
                                        key={item.key}
                                        onClick={() => {
                                            setSelectedTheme(item.key)
                                            localStorage.setItem(STORAGE.theme, item.key)
                                        }}
                                        style={{
                                            padding: "5px 10px",
                                            fontSize: 11,
                                            fontWeight: 600,
                                            color: active ? "#000" : "rgba(255,255,255,0.6)",
                                            background: active ? "rgba(255,255,255,0.9)" : "rgba(255,255,255,0.1)",
                                            border: "none",
                                            borderRadius: DS.radius.full,
                                            cursor: "pointer",
                                            display: "flex",
                                            alignItems: "center",
                                            gap: 3,
                                            transition: "all 0.15s ease",
                                        }}
                                    >
                                        {isProTheme && <Icon.Sparkle size={7} />}
                                        {item.label}
                                    </button>
                                )
                            })}

                            <div style={{ width: 1, height: 20, background: "rgba(255,255,255,0.2)", margin: "0 2px" }} />

                            {[ASPECT_RATIOS.PORTRAIT, ASPECT_RATIOS.SQUARE].map((ratio) => {
                                const active = selectedAspectRatio.key === ratio.key
                                return (
                                    <button
                                        key={ratio.key}
                                        onClick={() => setSelectedAspectRatio(ratio)}
                                        style={{
                                            padding: "5px 8px",
                                            fontSize: 11,
                                            fontWeight: 600,
                                            color: active ? "#000" : "rgba(255,255,255,0.6)",
                                            background: active ? "rgba(255,255,255,0.9)" : "rgba(255,255,255,0.1)",
                                            border: "none",
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
                    <div
                        style={{
                            width: "100%",
                            maxWidth: 260,
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
                        ) : selectedCardType === CARD_TYPES.DETAILED ? (
                            <DetailedCard
                                capturedImage={capturedImage}
                                timestamp={timestamp}
                                totalCalories={totalCalories}
                                totalCarbs={totalCarbs}
                                totalProtein={totalProtein}
                                totalFiber={totalFiber}
                                foods={foods}
                                cardRef={detailedCardRef}
                                lang={lang}
                                theme={selectedTheme}
                                aspectRatio={selectedAspectRatio}
                            />
                        ) : (
                            <HealthCard
                                capturedImage={capturedImage}
                                timestamp={timestamp}
                                totalCalories={totalCalories}
                                totalCarbs={totalCarbs}
                                totalProtein={totalProtein}
                                totalFat={totalFat}
                                totalSugar={totalSugar}
                                totalFiber={totalFiber}
                                foods={foods}
                                cardRef={healthCardRef}
                                lang={lang}
                                theme={selectedTheme}
                                aspectRatio={selectedAspectRatio}
                            />
                        )}
                    </div>
                </div>

                {/* Save Button - Bottom with gradient */}
                <div
                    style={{
                        position: "absolute",
                        bottom: 0,
                        left: 0,
                        right: 0,
                        padding: `40px ${DS.content.paddingX}px 0`,
                        paddingBottom: `max(20px, env(safe-area-inset-bottom))`,
                        background: "linear-gradient(to top, rgba(0,0,0,0.9) 0%, transparent 100%)",
                    }}
                >
                    <button
                        onClick={handleShare}
                        disabled={isSaving}
                        style={{
                            width: "100%",
                            padding: "14px 20px",
                            fontSize: 15,
                            fontWeight: 700,
                            color: "#000",
                            background: "#fff",
                            border: "none",
                            borderRadius: DS.radius.full,
                            cursor: "pointer",
                            display: "flex",
                            alignItems: "center",
                            justifyContent: "center",
                            gap: 6,
                        }}
                    >
                        {isProFeature && !isPro && !sessionPaid && <Icon.Sparkle size={12} />}
                        {isSaving ? "..." : t("saveAndShare")}
                    </button>
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
