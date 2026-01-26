import { addPropertyControls, ControlType } from "framer"
import { useState, useEffect } from "react"

const LANGUAGES = [
    { code: "ko", label: "한국어" },
    { code: "en", label: "English" },
    { code: "ja", label: "日本語" },
    { code: "zh", label: "中文" },
    { code: "fr", label: "Français" },
    { code: "de", label: "Deutsch" },
]

const CONTENT = {
    ko: {
        title: "개인정보처리방침",
        updated: "최종 업데이트: 2025년 1월 26일",
        intro: "educulture(이하 \"회사\")는 MealStamp(이하 \"앱\") 이용자의 개인정보를 중요시하며, 개인정보보호법 등 관련 법령을 준수합니다.",
        sections: [
            {
                title: "1. 수집하는 정보",
                content: "앱은 서비스 제공을 위해 다음 정보를 수집할 수 있습니다:",
                items: [
                    "카메라 접근 — 음식 사진 촬영을 위해 카메라에 접근합니다. 촬영된 사진은 기기에서만 처리되며 서버에 저장되지 않습니다.",
                    "기기 저장 데이터 — 언어 설정, 테마 설정, Pro 구매 상태 등이 기기 내 로컬 저장소에 저장됩니다."
                ]
            },
            {
                title: "2. 정보의 이용 목적",
                items: [
                    "AI 기반 음식 인식 및 칼로리 분석 서비스 제공",
                    "사용자 설정 저장 및 서비스 개선",
                    "Pro 기능 제공 및 구매 상태 관리"
                ]
            },
            {
                title: "3. 제3자 서비스",
                content: "앱은 다음 제3자 서비스를 이용합니다:",
                items: [
                    "OpenAI API — 음식 이미지 분석 및 칼로리 계산. 이미지는 분석 후 즉시 삭제됩니다.",
                    "식품의약품안전처 API — 영양 정보 조회",
                    "Lemon Squeezy — Pro 버전 결제 처리"
                ]
            },
            {
                title: "4. 정보의 보관 및 삭제",
                items: [
                    "사진 데이터 — 서버에 저장되지 않으며, 앱 사용 중에만 임시로 기기 메모리에 존재합니다.",
                    "설정 데이터 — 앱 삭제 시 함께 삭제됩니다.",
                    "사용자는 언제든지 앱을 삭제하여 모든 로컬 데이터를 삭제할 수 있습니다."
                ]
            },
            {
                title: "5. 이용자의 권리",
                items: [
                    "카메라 접근 권한을 기기 설정에서 언제든지 해제할 수 있습니다.",
                    "앱 삭제를 통해 모든 로컬 데이터를 삭제할 수 있습니다.",
                    "개인정보 관련 문의 및 요청을 아래 연락처로 할 수 있습니다."
                ]
            },
            {
                title: "6. 아동의 개인정보",
                content: "앱은 만 14세 미만 아동의 개인정보를 의도적으로 수집하지 않습니다."
            },
            {
                title: "7. 방침의 변경",
                content: "본 개인정보처리방침은 관련 법령 또는 서비스 변경에 따라 수정될 수 있으며, 변경 시 앱 내 또는 웹사이트를 통해 공지합니다."
            }
        ],
        contact: {
            title: "8. 연락처",
            operator: "운영자",
            email: "이메일",
            website: "웹사이트"
        }
    },
    en: {
        title: "Privacy Policy",
        updated: "Last Updated: January 26, 2025",
        intro: "educulture (\"we\", \"us\", or \"our\") operates MealStamp (the \"App\"). This page informs you of our policies regarding the collection, use, and disclosure of personal information.",
        sections: [
            {
                title: "1. Information We Collect",
                content: "The App may collect the following information to provide our services:",
                items: [
                    "Camera Access — We access your camera to take photos of food. Photos are processed locally on your device and are not stored on our servers.",
                    "Local Storage — Settings such as language preference, theme selection, and Pro purchase status are stored locally on your device."
                ]
            },
            {
                title: "2. How We Use Information",
                items: [
                    "To provide AI-powered food recognition and calorie analysis",
                    "To save your preferences and improve the service",
                    "To manage Pro features and purchase status"
                ]
            },
            {
                title: "3. Third-Party Services",
                content: "The App uses the following third-party services:",
                items: [
                    "OpenAI API — For food image analysis and calorie calculation. Images are deleted immediately after analysis.",
                    "Korea FDA API — For nutrition information lookup.",
                    "Lemon Squeezy — For processing Pro version payments."
                ]
            },
            {
                title: "4. Data Retention and Deletion",
                items: [
                    "Photo data — Not stored on servers. Only exists temporarily in device memory during app use.",
                    "Settings data — Deleted when the app is uninstalled.",
                    "You can delete all local data at any time by uninstalling the app."
                ]
            },
            {
                title: "5. Your Rights",
                items: [
                    "Revoke camera access permission at any time through your device settings.",
                    "Delete all local data by uninstalling the app.",
                    "Contact us for any privacy-related inquiries or requests."
                ]
            },
            {
                title: "6. Children's Privacy",
                content: "The App does not intentionally collect personal information from children under 14 years of age."
            },
            {
                title: "7. Changes to This Policy",
                content: "We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy in the App or on our website."
            }
        ],
        contact: {
            title: "8. Contact Us",
            operator: "Operator",
            email: "Email",
            website: "Website"
        }
    },
    ja: {
        title: "プライバシーポリシー",
        updated: "最終更新: 2025年1月26日",
        intro: "educulture（以下「当社」）は、MealStamp（以下「アプリ」）をご利用いただくユーザーの個人情報を重視し、関連法令を遵守します。",
        sections: [
            {
                title: "1. 収集する情報",
                content: "アプリは、サービス提供のために以下の情報を収集する場合があります：",
                items: [
                    "カメラへのアクセス — 食事の写真撮影のためにカメラにアクセスします。撮影した写真はデバイス上でのみ処理され、サーバーには保存されません。",
                    "ローカルストレージ — 言語設定、テーマ設定、Pro購入状態などがデバイス内に保存されます。"
                ]
            },
            {
                title: "2. 情報の利用目的",
                items: [
                    "AIによる食品認識とカロリー分析サービスの提供",
                    "ユーザー設定の保存とサービスの改善",
                    "Pro機能の提供と購入状態の管理"
                ]
            },
            {
                title: "3. 第三者サービス",
                content: "アプリは以下の第三者サービスを利用しています：",
                items: [
                    "OpenAI API — 食品画像分析とカロリー計算。画像は分析後すぐに削除されます。",
                    "韓国食品医薬品安全処API — 栄養情報の照会",
                    "Lemon Squeezy — Pro版の決済処理"
                ]
            },
            {
                title: "4. 情報の保管と削除",
                items: [
                    "写真データ — サーバーに保存されず、アプリ使用中のみデバイスメモリに一時的に存在します。",
                    "設定データ — アプリ削除時に一緒に削除されます。",
                    "ユーザーはいつでもアプリを削除してすべてのローカルデータを削除できます。"
                ]
            },
            {
                title: "5. ユーザーの権利",
                items: [
                    "デバイス設定からいつでもカメラアクセス権限を解除できます。",
                    "アプリを削除することですべてのローカルデータを削除できます。",
                    "個人情報に関するお問い合わせは下記連絡先までご連絡ください。"
                ]
            },
            {
                title: "6. 児童の個人情報",
                content: "アプリは14歳未満の児童の個人情報を意図的に収集しません。"
            },
            {
                title: "7. ポリシーの変更",
                content: "本プライバシーポリシーは、関連法令またはサービスの変更に伴い修正される場合があります。変更時はアプリ内またはウェブサイトでお知らせします。"
            }
        ],
        contact: {
            title: "8. お問い合わせ",
            operator: "運営者",
            email: "メール",
            website: "ウェブサイト"
        }
    },
    zh: {
        title: "隐私政策",
        updated: "最后更新：2025年1月26日",
        intro: "educulture（以下简称\"我们\"）运营MealStamp（以下简称\"应用\"）。本页面向您介绍我们在收集、使用和披露个人信息方面的政策。",
        sections: [
            {
                title: "1. 我们收集的信息",
                content: "为提供服务，应用可能收集以下信息：",
                items: [
                    "相机访问 — 我们访问您的相机以拍摄食物照片。照片仅在您的设备上处理，不会存储在我们的服务器上。",
                    "本地存储 — 语言偏好、主题选择和Pro购买状态等设置存储在您的设备本地。"
                ]
            },
            {
                title: "2. 信息使用目的",
                items: [
                    "提供AI食物识别和卡路里分析服务",
                    "保存用户设置并改进服务",
                    "管理Pro功能和购买状态"
                ]
            },
            {
                title: "3. 第三方服务",
                content: "应用使用以下第三方服务：",
                items: [
                    "OpenAI API — 用于食物图像分析和卡路里计算。图像在分析后立即删除。",
                    "韩国食品药品安全处API — 用于营养信息查询",
                    "Lemon Squeezy — 用于处理Pro版本付款"
                ]
            },
            {
                title: "4. 数据保留和删除",
                items: [
                    "照片数据 — 不存储在服务器上，仅在应用使用期间临时存在于设备内存中。",
                    "设置数据 — 卸载应用时删除。",
                    "您可以随时通过卸载应用删除所有本地数据。"
                ]
            },
            {
                title: "5. 您的权利",
                items: [
                    "随时通过设备设置撤销相机访问权限。",
                    "通过卸载应用删除所有本地数据。",
                    "如有隐私相关问题，请通过以下联系方式联系我们。"
                ]
            },
            {
                title: "6. 儿童隐私",
                content: "应用不会故意收集14岁以下儿童的个人信息。"
            },
            {
                title: "7. 政策变更",
                content: "我们可能会不时更新本隐私政策。任何变更将在应用内或网站上公布。"
            }
        ],
        contact: {
            title: "8. 联系我们",
            operator: "运营者",
            email: "邮箱",
            website: "网站"
        }
    },
    fr: {
        title: "Politique de confidentialité",
        updated: "Dernière mise à jour : 26 janvier 2025",
        intro: "educulture (« nous ») exploite MealStamp (l'« Application »). Cette page vous informe de nos politiques concernant la collecte, l'utilisation et la divulgation des informations personnelles.",
        sections: [
            {
                title: "1. Informations collectées",
                content: "L'Application peut collecter les informations suivantes pour fournir nos services :",
                items: [
                    "Accès à la caméra — Nous accédons à votre caméra pour photographier les aliments. Les photos sont traitées localement sur votre appareil et ne sont pas stockées sur nos serveurs.",
                    "Stockage local — Les paramètres tels que la préférence linguistique, la sélection du thème et l'état d'achat Pro sont stockés localement sur votre appareil."
                ]
            },
            {
                title: "2. Utilisation des informations",
                items: [
                    "Fournir la reconnaissance alimentaire par IA et l'analyse des calories",
                    "Sauvegarder vos préférences et améliorer le service",
                    "Gérer les fonctionnalités Pro et l'état d'achat"
                ]
            },
            {
                title: "3. Services tiers",
                content: "L'Application utilise les services tiers suivants :",
                items: [
                    "API OpenAI — Pour l'analyse d'images alimentaires et le calcul des calories. Les images sont supprimées immédiatement après l'analyse.",
                    "API FDA Corée — Pour la recherche d'informations nutritionnelles",
                    "Lemon Squeezy — Pour le traitement des paiements Pro"
                ]
            },
            {
                title: "4. Conservation et suppression des données",
                items: [
                    "Données photo — Non stockées sur les serveurs. N'existent que temporairement dans la mémoire de l'appareil pendant l'utilisation.",
                    "Données de paramètres — Supprimées lors de la désinstallation de l'application.",
                    "Vous pouvez supprimer toutes les données locales à tout moment en désinstallant l'application."
                ]
            },
            {
                title: "5. Vos droits",
                items: [
                    "Révoquer l'autorisation d'accès à la caméra à tout moment via les paramètres de votre appareil.",
                    "Supprimer toutes les données locales en désinstallant l'application.",
                    "Nous contacter pour toute demande relative à la confidentialité."
                ]
            },
            {
                title: "6. Confidentialité des enfants",
                content: "L'Application ne collecte pas intentionnellement d'informations personnelles auprès d'enfants de moins de 14 ans."
            },
            {
                title: "7. Modifications de cette politique",
                content: "Nous pouvons mettre à jour cette politique de confidentialité de temps à autre. Les modifications seront publiées dans l'Application ou sur notre site web."
            }
        ],
        contact: {
            title: "8. Nous contacter",
            operator: "Opérateur",
            email: "Email",
            website: "Site web"
        }
    },
    de: {
        title: "Datenschutzrichtlinie",
        updated: "Letzte Aktualisierung: 26. Januar 2025",
        intro: "educulture („wir", „uns" oder „unser") betreibt MealStamp (die „App"). Diese Seite informiert Sie über unsere Richtlinien bezüglich der Erfassung, Verwendung und Offenlegung personenbezogener Daten.",
        sections: [
            {
                title: "1. Erfasste Informationen",
                content: "Die App kann zur Bereitstellung unserer Dienste folgende Informationen erfassen:",
                items: [
                    "Kamerazugriff — Wir greifen auf Ihre Kamera zu, um Fotos von Lebensmitteln aufzunehmen. Fotos werden lokal auf Ihrem Gerät verarbeitet und nicht auf unseren Servern gespeichert.",
                    "Lokaler Speicher — Einstellungen wie Sprachpräferenz, Themenauswahl und Pro-Kaufstatus werden lokal auf Ihrem Gerät gespeichert."
                ]
            },
            {
                title: "2. Verwendung der Informationen",
                items: [
                    "Bereitstellung von KI-gestützter Lebensmittelerkennung und Kalorienanalyse",
                    "Speichern Ihrer Präferenzen und Verbesserung des Dienstes",
                    "Verwaltung von Pro-Funktionen und Kaufstatus"
                ]
            },
            {
                title: "3. Drittanbieterdienste",
                content: "Die App nutzt folgende Drittanbieterdienste:",
                items: [
                    "OpenAI API — Für Lebensmittelbildanalyse und Kalorienberechnung. Bilder werden nach der Analyse sofort gelöscht.",
                    "Korea FDA API — Für Ernährungsinformationsabfragen",
                    "Lemon Squeezy — Für die Abwicklung von Pro-Zahlungen"
                ]
            },
            {
                title: "4. Datenspeicherung und -löschung",
                items: [
                    "Fotodaten — Werden nicht auf Servern gespeichert. Existieren nur temporär im Gerätespeicher während der Nutzung.",
                    "Einstellungsdaten — Werden bei Deinstallation der App gelöscht.",
                    "Sie können alle lokalen Daten jederzeit durch Deinstallation der App löschen."
                ]
            },
            {
                title: "5. Ihre Rechte",
                items: [
                    "Widerrufen Sie die Kamerazugriffsberechtigung jederzeit über Ihre Geräteeinstellungen.",
                    "Löschen Sie alle lokalen Daten durch Deinstallation der App.",
                    "Kontaktieren Sie uns bei datenschutzbezogenen Anfragen."
                ]
            },
            {
                title: "6. Datenschutz für Kinder",
                content: "Die App erfasst nicht absichtlich personenbezogene Daten von Kindern unter 14 Jahren."
            },
            {
                title: "7. Änderungen dieser Richtlinie",
                content: "Wir können diese Datenschutzrichtlinie von Zeit zu Zeit aktualisieren. Änderungen werden in der App oder auf unserer Website veröffentlicht."
            }
        ],
        contact: {
            title: "8. Kontakt",
            operator: "Betreiber",
            email: "E-Mail",
            website: "Website"
        }
    }
}

const styles = {
    container: {
        width: "100%",
        minHeight: "100%",
        background: "#fff",
        fontFamily: "-apple-system, BlinkMacSystemFont, 'Pretendard', sans-serif",
        color: "#000",
        padding: "40px 24px 60px",
        boxSizing: "border-box" as const,
        overflowY: "auto" as const,
    },
    inner: {
        maxWidth: 640,
        margin: "0 auto",
    },
    langSwitcher: {
        display: "flex",
        gap: 6,
        marginBottom: 40,
        flexWrap: "wrap" as const,
    },
    langBtn: {
        padding: "8px 14px",
        fontSize: 13,
        fontWeight: 600,
        border: "1.5px solid #e0e0e0",
        background: "#fff",
        color: "#666",
        borderRadius: 100,
        cursor: "pointer",
        transition: "all 0.2s ease",
    },
    langBtnActive: {
        background: "#000",
        borderColor: "#000",
        color: "#fff",
    },
    logo: {
        fontSize: 14,
        fontWeight: 600,
        letterSpacing: -0.3,
        marginBottom: 20,
    },
    title: {
        fontSize: 28,
        fontWeight: 700,
        letterSpacing: -0.5,
        lineHeight: 1.2,
        marginBottom: 8,
    },
    updated: {
        fontSize: 14,
        color: "#888",
        marginBottom: 40,
    },
    intro: {
        fontSize: 15,
        lineHeight: 1.8,
        color: "#444",
        marginBottom: 32,
    },
    sectionTitle: {
        fontSize: 17,
        fontWeight: 700,
        marginTop: 32,
        marginBottom: 14,
        paddingBottom: 10,
        borderBottom: "1px solid #f0f0f0",
    },
    sectionContent: {
        fontSize: 15,
        lineHeight: 1.8,
        color: "#444",
        marginBottom: 12,
    },
    list: {
        listStyle: "none",
        padding: 0,
        margin: 0,
    },
    listItem: {
        fontSize: 15,
        lineHeight: 1.8,
        color: "#444",
        paddingLeft: 16,
        position: "relative" as const,
        marginBottom: 10,
    },
    bullet: {
        position: "absolute" as const,
        left: 0,
        top: 10,
        width: 5,
        height: 5,
        background: "#000",
        borderRadius: "50%",
    },
    contactBox: {
        marginTop: 40,
        padding: 20,
        background: "#fafafa",
        borderRadius: 14,
        border: "1px solid #f0f0f0",
    },
    contactTitle: {
        fontSize: 17,
        fontWeight: 700,
        marginBottom: 14,
    },
    contactItem: {
        fontSize: 15,
        color: "#444",
        marginBottom: 4,
    },
    link: {
        color: "#000",
        textDecoration: "none",
        borderBottom: "1px solid #ccc",
    },
    footer: {
        marginTop: 48,
        paddingTop: 20,
        borderTop: "1px solid #f0f0f0",
        textAlign: "center" as const,
        fontSize: 13,
        color: "#999",
    },
}

export default function PrivacyPolicy(props: any) {
    const [lang, setLang] = useState("ko")
    const content = CONTENT[lang as keyof typeof CONTENT]

    useEffect(() => {
        // Check URL parameter for language
        if (typeof window !== "undefined") {
            const params = new URLSearchParams(window.location.search)
            const langParam = params.get("lang")
            if (langParam && CONTENT[langParam as keyof typeof CONTENT]) {
                setLang(langParam)
            }
        }
    }, [])

    return (
        <div style={styles.container}>
            <div style={styles.inner}>
                {/* Language Switcher */}
                <div style={styles.langSwitcher}>
                    {LANGUAGES.map((l) => (
                        <button
                            key={l.code}
                            onClick={() => setLang(l.code)}
                            style={{
                                ...styles.langBtn,
                                ...(lang === l.code ? styles.langBtnActive : {}),
                            }}
                        >
                            {l.label}
                        </button>
                    ))}
                </div>

                {/* Header */}
                <div style={styles.logo}>MealStamp</div>
                <h1 style={styles.title}>{content.title}</h1>
                <p style={styles.updated}>{content.updated}</p>
                <p style={styles.intro}>{content.intro}</p>

                {/* Sections */}
                {content.sections.map((section, idx) => (
                    <div key={idx}>
                        <h2 style={styles.sectionTitle}>{section.title}</h2>
                        {section.content && (
                            <p style={styles.sectionContent}>{section.content}</p>
                        )}
                        {section.items && (
                            <ul style={styles.list}>
                                {section.items.map((item, i) => (
                                    <li key={i} style={styles.listItem}>
                                        <span style={styles.bullet} />
                                        {item}
                                    </li>
                                ))}
                            </ul>
                        )}
                    </div>
                ))}

                {/* Contact Box */}
                <div style={styles.contactBox}>
                    <h2 style={styles.contactTitle}>{content.contact.title}</h2>
                    <p style={styles.contactItem}>
                        <strong>{content.contact.operator}</strong>: educulture
                    </p>
                    <p style={styles.contactItem}>
                        <strong>{content.contact.email}</strong>:{" "}
                        <a href="mailto:support@mealstamp.app" style={styles.link}>
                            support@mealstamp.app
                        </a>
                    </p>
                    <p style={styles.contactItem}>
                        <strong>{content.contact.website}</strong>:{" "}
                        <a href="https://mealstamp.app" style={styles.link}>
                            mealstamp.app
                        </a>
                    </p>
                </div>

                {/* Footer */}
                <div style={styles.footer}>
                    © 2025 MealStamp by educulture
                </div>
            </div>
        </div>
    )
}

addPropertyControls(PrivacyPolicy, {
    defaultLang: {
        type: ControlType.Enum,
        title: "기본 언어",
        options: ["ko", "en", "ja", "zh", "fr", "de"],
        optionTitles: ["한국어", "English", "日本語", "中文", "Français", "Deutsch"],
        defaultValue: "ko",
    },
})
