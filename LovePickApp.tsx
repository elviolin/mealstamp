import React, { useState, useEffect, useRef, useCallback } from "react"
import { addPropertyControls, ControlType } from "framer"

// ─── TYPES ───────────────────────────────────────────────
type Screen =
    | "splash"
    | "gender"
    | "phone"
    | "otp"
    | "nickname"
    | "home"
    | "compose"
    | "reveal"

type Gender = "female" | "male"

interface PickItem {
    id: string
    maskedPhone: string
    word: string
    aiText: string
    date: string
    status: "scheduled" | "sent"
}

interface ReceivedItem {
    id: string
    word: string
    aiText: string
    date: string
    gender: Gender
}

// ─── DESIGN TOKENS ───────────────────────────────────────
const T = {
    bg: "#0c0b0f",
    bg2: "#13111a",
    surface: "#181525",
    surface2: "#1f1b2e",
    border: "rgba(255,255,255,0.07)",
    borderRose: "rgba(220,150,150,0.2)",
    text: "#f0eae8",
    textDim: "rgba(240,234,232,0.6)",
    textMuted: "rgba(240,234,232,0.35)",
    rose: "#dfa0a0",
    roseSoft: "rgba(223,160,160,0.12)",
    roseGlow: "rgba(223,160,160,0.07)",
    gold: "#c9a96e",
    goldSoft: "rgba(201,169,110,0.1)",
    font: "'Noto Serif KR', serif",
    fontSerif: "'Gowun Batang', serif",
}

// ─── MOCK DATA ───────────────────────────────────────────
const RECEIVED_PICKS: ReceivedItem[] = [
    {
        id: "1",
        word: "따뜻한",
        aiText: "겨울날 햇살처럼,\n곁에 있으면 모든 게\n괜찮아지는 사람",
        date: "2025년 2월 24일",
        gender: "male",
    },
    {
        id: "2",
        word: "눈부신",
        aiText: "아무 말 없이 있어도\n함께라면 빛이 나는,\n그런 존재예요",
        date: "2025년 2월 20일",
        gender: "female",
    },
    {
        id: "3",
        word: "조용한",
        aiText: "소란스럽지 않아도\n오래 기억에 남는,\n잔잔한 여운 같은 사람",
        date: "2025년 2월 14일",
        gender: "male",
    },
]

const SENT_PICKS: PickItem[] = [
    {
        id: "1",
        maskedPhone: "010 •••• 2341",
        word: "눈부신",
        aiText: "",
        date: "2.24",
        status: "sent",
    },
    {
        id: "2",
        maskedPhone: "010 •••• 8827",
        word: "따뜻한",
        aiText: "",
        date: "2.26",
        status: "scheduled",
    },
]

// ─── FONTS ───────────────────────────────────────────────
function FontLoader() {
    return (
        <style>{`
            @import url('https://fonts.googleapis.com/css2?family=Noto+Serif+KR:wght@300;400;600&family=Gowun+Batang:wght@400;700&display=swap');
            @keyframes heartbeat {
                0%, 100% { transform: scale(1); }
                50% { transform: scale(1.07); }
            }
            @keyframes pulse {
                0%, 100% { opacity: 1; transform: scale(1); }
                50% { opacity: 0.5; transform: scale(0.8); }
            }
            @keyframes fadeUp {
                from { opacity: 0; transform: translateY(16px); }
                to { opacity: 1; transform: translateY(0); }
            }
        `}</style>
    )
}

// ─── STAR CANVAS ─────────────────────────────────────────
function StarCanvas({ height }: { height: number }) {
    const ref = useRef<HTMLCanvasElement>(null)

    useEffect(() => {
        const cvs = ref.current
        if (!cvs) return
        const ctx = cvs.getContext("2d")
        if (!ctx) return
        cvs.width = 390
        cvs.height = height || 800

        const stars = Array.from({ length: 70 }, () => ({
            x: Math.random() * 390,
            y: Math.random() * (height || 800),
            r: Math.random() * 1.1 + 0.2,
            o: Math.random() * 0.35 + 0.08,
            sp: Math.random() * 0.002 + 0.001,
            ph: Math.random() * Math.PI * 2,
        }))

        let raf: number
        const draw = (t: number) => {
            ctx.clearRect(0, 0, 390, height || 800)
            stars.forEach((s) => {
                const op = s.o * (0.55 + 0.45 * Math.sin(t * s.sp * 800 + s.ph))
                ctx.beginPath()
                ctx.arc(s.x, s.y, s.r, 0, Math.PI * 2)
                ctx.fillStyle = `rgba(240,234,232,${op})`
                ctx.fill()
            })
            raf = requestAnimationFrame(draw)
        }
        raf = requestAnimationFrame(draw)
        return () => cancelAnimationFrame(raf)
    }, [height])

    return (
        <canvas
            ref={ref}
            style={{
                position: "absolute",
                inset: 0,
                width: "100%",
                height: "100%",
                pointerEvents: "none",
                zIndex: 0,
            }}
        />
    )
}

// ─── ANIMATED WRAPPER ────────────────────────────────────
function Anim({
    children,
    delay = 0,
    active,
    style: s,
}: {
    children: React.ReactNode
    delay?: number
    active: boolean
    style?: React.CSSProperties
}) {
    return (
        <div
            style={{
                opacity: active ? 1 : 0,
                transform: active ? "translateY(0)" : "translateY(16px)",
                transition: `opacity 0.45s ${delay}s ease, transform 0.45s ${delay}s ease`,
                ...s,
            }}
        >
            {children}
        </div>
    )
}

// ─── SCREEN WRAPPER ──────────────────────────────────────
function ScreenWrap({
    active,
    direction,
    children,
    style: s,
}: {
    active: boolean
    direction: "enter" | "exit" | "idle"
    children: React.ReactNode
    style?: React.CSSProperties
}) {
    const transform = active
        ? "translateX(0)"
        : direction === "exit"
          ? "translateX(-40px)"
          : "translateX(100%)"

    return (
        <div
            style={{
                position: "absolute",
                inset: 0,
                zIndex: active ? 2 : 1,
                display: "flex",
                flexDirection: "column",
                padding: "0 28px",
                overflowY: active ? "auto" : "hidden",
                transform,
                opacity: active ? 1 : 0,
                transition:
                    "transform 0.38s cubic-bezier(0.4,0,0.2,1), opacity 0.38s ease",
                pointerEvents: active ? "all" : "none",
                ...s,
            }}
        >
            {children}
        </div>
    )
}

// ─── BACK BUTTON ─────────────────────────────────────────
function BackBtn({ onClick }: { onClick: () => void }) {
    return (
        <button
            onClick={onClick}
            style={{
                display: "flex",
                alignItems: "center",
                gap: 8,
                background: "none",
                border: "none",
                color: T.textMuted,
                fontFamily: T.font,
                fontSize: 13,
                letterSpacing: "0.05em",
                cursor: "pointer",
                padding: 0,
                marginBottom: 36,
                marginTop: 4,
            }}
        >
            <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
                <path
                    d="M10 3L5 8L10 13"
                    stroke="currentColor"
                    strokeWidth="1.5"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                />
            </svg>
            돌아가기
        </button>
    )
}

// ─── BUTTONS ─────────────────────────────────────────────
function Btn({
    children,
    variant = "rose",
    onClick,
    style: s,
}: {
    children: React.ReactNode
    variant?: "rose" | "ghost" | "text"
    onClick?: () => void
    style?: React.CSSProperties
}) {
    const [pressed, setPressed] = useState(false)

    const base: React.CSSProperties =
        variant === "rose"
            ? {
                  background: "rgba(223,160,160,0.13)",
                  border: "1px solid rgba(223,160,160,0.3)",
                  color: T.rose,
              }
            : variant === "ghost"
              ? {
                    background: "transparent",
                    border: `1px solid ${T.border}`,
                    color: T.textMuted,
                }
              : {
                    background: "none",
                    border: "none",
                    color: T.textMuted,
                    fontSize: 13,
                    letterSpacing: "0.04em",
                    padding: 14,
                }

    const pressedStyle: React.CSSProperties = pressed
        ? variant === "rose"
            ? { background: "rgba(223,160,160,0.22)", transform: "scale(0.98)" }
            : variant === "ghost"
              ? { background: "rgba(255,255,255,0.03)" }
              : {}
        : {}

    return (
        <button
            onClick={onClick}
            onPointerDown={() => setPressed(true)}
            onPointerUp={() => setPressed(false)}
            onPointerLeave={() => setPressed(false)}
            style={{
                width: "100%",
                padding: 18,
                borderRadius: 16,
                fontFamily: T.font,
                fontSize: 15,
                letterSpacing: "0.07em",
                cursor: "pointer",
                transition: "all 0.25s",
                position: "relative",
                overflow: "hidden",
                ...base,
                ...pressedStyle,
                ...s,
            }}
        >
            {children}
        </button>
    )
}

// ─── LABEL ───────────────────────────────────────────────
function Label({ children }: { children: React.ReactNode }) {
    return (
        <div
            style={{
                fontSize: 10,
                letterSpacing: "0.22em",
                color: T.textMuted,
                textTransform: "uppercase",
                marginBottom: 14,
            }}
        >
            {children}
        </div>
    )
}

// ─── NOTICE ──────────────────────────────────────────────
function Notice({
    icon,
    children,
    variant = "gold",
}: {
    icon: string
    children: React.ReactNode
    variant?: "gold" | "rose"
}) {
    const bg = variant === "gold" ? T.goldSoft : T.roseGlow
    const border =
        variant === "gold"
            ? "1px solid rgba(201,169,110,0.15)"
            : "1px solid rgba(223,160,160,0.12)"
    const color =
        variant === "gold" ? "rgba(201,169,110,0.85)" : T.textDim

    return (
        <div
            style={{
                display: "flex",
                gap: 12,
                alignItems: "flex-start",
                padding: "16px 18px",
                borderRadius: 14,
                background: bg,
                border,
            }}
        >
            <span style={{ fontSize: 15, flexShrink: 0, marginTop: 1 }}>
                {icon}
            </span>
            <span
                style={{
                    fontSize: 12,
                    lineHeight: 1.8,
                    letterSpacing: "0.03em",
                    color,
                }}
            >
                {children}
            </span>
        </div>
    )
}

// ─── TITLE ───────────────────────────────────────────────
function Title({ children }: { children: React.ReactNode }) {
    return (
        <div
            style={{
                fontFamily: T.fontSerif,
                fontSize: 26,
                fontWeight: 700,
                lineHeight: 1.55,
                color: T.text,
            }}
        >
            {children}
        </div>
    )
}

function Subtitle({ children }: { children: React.ReactNode }) {
    return (
        <div
            style={{
                fontSize: 13,
                color: T.textDim,
                lineHeight: 1.85,
                letterSpacing: "0.03em",
                marginTop: 10,
            }}
        >
            {children}
        </div>
    )
}

// ═══════════════════════════════════════════════════════════
// SCREEN 1 — SPLASH
// ═══════════════════════════════════════════════════════════
function SplashScreen({
    go,
    active,
}: {
    go: (s: Screen) => void
    active: boolean
}) {
    return (
        <>
            <div style={{ flex: 1 }} />
            <div
                style={{
                    display: "flex",
                    flexDirection: "column",
                    alignItems: "center",
                    textAlign: "center",
                }}
            >
                <Anim active={active} delay={0.05}>
                    <div
                        style={{
                            width: 64,
                            height: 64,
                            marginBottom: 28,
                            animation: "heartbeat 3s ease-in-out infinite",
                        }}
                    >
                        <svg
                            viewBox="0 0 64 64"
                            fill="none"
                            style={{
                                width: "100%",
                                height: "100%",
                                filter: "drop-shadow(0 0 18px rgba(223,160,160,0.45))",
                            }}
                        >
                            <path
                                d="M32 54S8 39 8 22C8 14.8 13.8 9 21 9C25.2 9 29 11.1 32 14.5C35 11.1 38.8 9 43 9C50.2 9 56 14.8 56 22C56 39 32 54 32 54Z"
                                fill="rgba(223,160,160,0.12)"
                                stroke="rgba(223,160,160,0.55)"
                                strokeWidth="1.5"
                                strokeLinejoin="round"
                            />
                            <path
                                d="M32 54S8 39 8 22C8 14.8 13.8 9 21 9C25.2 9 29 11.1 32 14.5"
                                stroke="rgba(223,160,160,0.2)"
                                strokeWidth="0.8"
                                strokeLinecap="round"
                            />
                        </svg>
                    </div>
                </Anim>
                <Anim active={active} delay={0.13}>
                    <div
                        style={{
                            fontFamily: T.fontSerif,
                            fontSize: 28,
                            fontWeight: 700,
                            letterSpacing: "0.1em",
                            marginBottom: 14,
                        }}
                    >
                        나 너 좋아했어
                    </div>
                    <div
                        style={{
                            fontSize: 13,
                            color: T.textMuted,
                            lineHeight: 2,
                            letterSpacing: "0.05em",
                            marginBottom: 56,
                        }}
                    >
                        소중한 사람에게
                        <br />
                        단 한 단어로 마음을 전해요
                        <br />
                        <br />
                        평생 딱 다섯 번
                    </div>
                </Anim>
            </div>
            <div style={{ flex: 1 }} />
            <Anim active={active} delay={0.21}>
                <Btn onClick={() => go("gender")}>시작하기</Btn>
                <div style={{ height: 12 }} />
                <Btn variant="ghost" onClick={() => go("home")}>
                    받은 마음 확인하기
                </Btn>
                <p
                    style={{
                        fontSize: 11,
                        color: T.textMuted,
                        textAlign: "center",
                        marginTop: 18,
                        letterSpacing: "0.08em",
                        opacity: 0.7,
                    }}
                >
                    전화번호로 간편하게 로그인해요
                </p>
            </Anim>
            <div style={{ height: 64 }} />
        </>
    )
}

// ═══════════════════════════════════════════════════════════
// SCREEN 2 — GENDER
// ═══════════════════════════════════════════════════════════
function GenderScreen({
    go,
    active,
    setGender,
}: {
    go: (s: Screen) => void
    active: boolean
    setGender: (g: Gender) => void
}) {
    const [selected, setSelected] = useState<Gender | null>(null)

    const options: { value: Gender; emoji: string; label: string }[] = [
        { value: "female", emoji: "👩", label: "여자" },
        { value: "male", emoji: "👨", label: "남자" },
    ]

    return (
        <>
            <div style={{ flex: 1 }} />
            <div style={{ textAlign: "center" }}>
                <Anim active={active} delay={0.05}>
                    <Label>기본 정보</Label>
                    <Title>성별을 알려주세요</Title>
                    <Subtitle>상대방에게 성별 힌트로 전달돼요</Subtitle>
                </Anim>
                <div style={{ height: 40 }} />
                <Anim active={active} delay={0.13}>
                    <div style={{ display: "flex", gap: 14, justifyContent: "center" }}>
                        {options.map((opt) => {
                            const isSelected = selected === opt.value
                            return (
                                <div
                                    key={opt.value}
                                    onClick={() => setSelected(opt.value)}
                                    style={{
                                        width: 140,
                                        padding: "32px 20px 28px",
                                        borderRadius: 22,
                                        background: isSelected ? T.roseSoft : T.surface,
                                        border: isSelected
                                            ? `1px solid ${T.borderRose}`
                                            : `1px solid ${T.border}`,
                                        cursor: "pointer",
                                        transition: "all 0.25s",
                                        transform: isSelected ? "scale(1.03)" : "scale(1)",
                                    }}
                                >
                                    <div style={{ fontSize: 40, marginBottom: 14 }}>{opt.emoji}</div>
                                    <div
                                        style={{
                                            fontFamily: T.fontSerif,
                                            fontSize: 17,
                                            color: isSelected ? T.rose : T.textDim,
                                            letterSpacing: "0.08em",
                                            fontWeight: isSelected ? 700 : 400,
                                        }}
                                    >
                                        {opt.label}
                                    </div>
                                </div>
                            )
                        })}
                    </div>
                </Anim>
            </div>
            <div style={{ flex: 1 }} />
            <Anim active={active} delay={0.21}>
                <Btn
                    onClick={() => {
                        if (selected) {
                            setGender(selected)
                            go("phone")
                        }
                    }}
                    style={{ opacity: selected ? 1 : 0.35, pointerEvents: selected ? "auto" : "none" }}
                >
                    다음
                </Btn>
                <div style={{ height: 64 }} />
            </Anim>
        </>
    )
}

// ═══════════════════════════════════════════════════════════
// SCREEN 3 — PHONE
// ═══════════════════════════════════════════════════════════
function PhoneScreen({
    go,
    active,
}: {
    go: (s: Screen) => void
    active: boolean
}) {
    const [phone, setPhone] = useState("")

    const fmt = (v: string) => {
        const d = v.replace(/\D/g, "")
        if (d.length > 7)
            return d.slice(0, 3) + " " + d.slice(3, 7) + " " + d.slice(7, 11)
        if (d.length > 3) return d.slice(0, 3) + " " + d.slice(3)
        return d
    }

    return (
        <>
            <div style={{ height: 72 }} />
            <Anim active={active} delay={0.05}>
                <BackBtn onClick={() => go("splash")} />
            </Anim>
            <Anim active={active} delay={0.13}>
                <div style={{ marginBottom: 40 }}>
                    <Label>본인 인증</Label>
                    <Title>
                        전화번호를
                        <br />
                        입력해주세요
                    </Title>
                    <Subtitle>인증 문자가 발송돼요</Subtitle>
                </div>
            </Anim>
            <Anim active={active} delay={0.21}>
                <div
                    style={{
                        display: "flex",
                        alignItems: "center",
                        gap: 0,
                        paddingLeft: 16,
                        background: T.surface2,
                        border: `1px solid ${T.border}`,
                        borderRadius: 16,
                        overflow: "hidden",
                    }}
                >
                    <span
                        style={{
                            fontSize: 15,
                            color: T.textDim,
                            letterSpacing: "0.05em",
                            flexShrink: 0,
                            padding: "19px 0",
                        }}
                    >
                        🇰🇷 +82
                    </span>
                    <div
                        style={{
                            width: 1,
                            height: 24,
                            background: T.border,
                            margin: "0 8px",
                        }}
                    />
                    <input
                        style={{
                            flex: 1,
                            background: "transparent",
                            border: "none",
                            padding: "19px 16px 19px 8px",
                            color: T.text,
                            fontFamily: T.font,
                            fontSize: 16,
                            letterSpacing: "0.08em",
                            outline: "none",
                            WebkitAppearance: "none",
                        }}
                        type="tel"
                        placeholder="010 1234 5678"
                        value={phone}
                        onChange={(e) => setPhone(fmt(e.target.value))}
                        maxLength={13}
                    />
                </div>
                <p
                    style={{
                        fontSize: 11.5,
                        color: T.textMuted,
                        letterSpacing: "0.04em",
                        lineHeight: 1.75,
                        marginTop: 12,
                        paddingLeft: 4,
                    }}
                >
                    번호는 암호화되어 저장되며 외부에 공개되지 않아요
                </p>
            </Anim>
            <div style={{ flex: 1 }} />
            <Anim active={active} delay={0.29}>
                <Btn onClick={() => go("otp")}>인증 문자 받기</Btn>
            </Anim>
            <div style={{ height: 64 }} />
        </>
    )
}

// ═══════════════════════════════════════════════════════════
// SCREEN 3 — OTP
// ═══════════════════════════════════════════════════════════
function OTPScreen({
    go,
    active,
}: {
    go: (s: Screen) => void
    active: boolean
}) {
    const [otp, setOtp] = useState(["", "", "", "", "", ""])
    const [sec, setSec] = useState(299)
    const refs = useRef<(HTMLInputElement | null)[]>([])

    useEffect(() => {
        if (!active) return
        if (sec <= 0) return
        const t = setTimeout(() => setSec((s) => s - 1), 1000)
        return () => clearTimeout(t)
    }, [sec, active])

    const timerStr = `0${Math.floor(sec / 60)}:${(sec % 60)
        .toString()
        .padStart(2, "0")}`

    const handleOtp = (val: string, i: number) => {
        const v = val.replace(/\D/g, "").slice(-1)
        const next = [...otp]
        next[i] = v
        setOtp(next)
        if (v && i < 5) refs.current[i + 1]?.focus()
        if (next.every((c) => c !== "")) setTimeout(() => go("nickname"), 300)
    }

    return (
        <>
            <div style={{ height: 72 }} />
            <Anim active={active} delay={0.05}>
                <BackBtn onClick={() => go("phone")} />
            </Anim>
            <Anim active={active} delay={0.13}>
                <div style={{ marginBottom: 36 }}>
                    <Label>인증 코드</Label>
                    <Title>
                        문자로 받은
                        <br />
                        코드를 입력해요
                    </Title>
                </div>
            </Anim>
            <Anim active={active} delay={0.21}>
                <div
                    style={{
                        fontSize: 13,
                        color: T.rose,
                        letterSpacing: "0.04em",
                        marginBottom: 32,
                        padding: "14px 18px",
                        background: T.roseGlow,
                        border: `1px solid ${T.borderRose}`,
                        borderRadius: 12,
                    }}
                >
                    010 •••• 5678 로 발송됐어요
                </div>
                <div
                    style={{
                        display: "flex",
                        gap: 10,
                        justifyContent: "center",
                        margin: "8px 0",
                    }}
                >
                    {otp.map((v, i) => (
                        <input
                            key={i}
                            ref={(el) => {
                                refs.current[i] = el
                            }}
                            style={{
                                width: 52,
                                height: 64,
                                background: T.surface,
                                border: `1px solid ${T.border}`,
                                borderRadius: 14,
                                color: T.text,
                                fontFamily: T.fontSerif,
                                fontSize: 26,
                                textAlign: "center",
                                outline: "none",
                                caretColor: T.rose,
                                WebkitAppearance: "none",
                            }}
                            type="tel"
                            maxLength={1}
                            value={v}
                            onChange={(e) => handleOtp(e.target.value, i)}
                        />
                    ))}
                </div>
                <p
                    style={{
                        fontSize: 12,
                        color: T.textMuted,
                        textAlign: "center",
                        letterSpacing: "0.08em",
                        marginTop: 16,
                    }}
                >
                    유효시간{" "}
                    <span style={{ color: T.rose }}>{timerStr}</span>
                </p>
                <button
                    style={{
                        background: "none",
                        border: "none",
                        color: T.textMuted,
                        fontFamily: T.font,
                        fontSize: 12,
                        cursor: "pointer",
                        letterSpacing: "0.06em",
                        textDecoration: "underline",
                        textUnderlineOffset: 3,
                        marginTop: 10,
                        display: "block",
                        textAlign: "center",
                        width: "100%",
                    }}
                >
                    문자 재발송
                </button>
            </Anim>
            <div style={{ flex: 1 }} />
            <Anim active={active} delay={0.29}>
                <Btn onClick={() => go("nickname")}>확인</Btn>
            </Anim>
            <div style={{ height: 64 }} />
        </>
    )
}

// ═══════════════════════════════════════════════════════════
// SCREEN 4 — NICKNAME
// ═══════════════════════════════════════════════════════════
function NicknameScreen({
    go,
    active,
    setNick,
}: {
    go: (s: Screen) => void
    active: boolean
    setNick: (n: string) => void
}) {
    const [val, setVal] = useState("")

    return (
        <>
            <div style={{ height: 72 }} />
            <Anim active={active} delay={0.05}>
                <div
                    style={{
                        height: 40,
                        display: "flex",
                        alignItems: "flex-start",
                        paddingTop: 16,
                    }}
                >
                    <Label>프로필 설정</Label>
                </div>
            </Anim>
            <Anim active={active} delay={0.13}>
                <div style={{ marginBottom: 40 }}>
                    <Title>
                        어떻게
                        <br />
                        불러드릴까요
                        <span style={{ color: T.rose }}>?</span>
                    </Title>
                    <Subtitle>나중에 바꿀 수 있어요</Subtitle>
                </div>
            </Anim>
            <Anim active={active} delay={0.21}>
                <input
                    style={{
                        width: "100%",
                        padding: "19px 20px",
                        background: T.surface,
                        border: `1px solid ${T.border}`,
                        borderRadius: 16,
                        color: T.text,
                        fontFamily: T.font,
                        fontSize: 16,
                        letterSpacing: "0.06em",
                        outline: "none",
                        WebkitAppearance: "none",
                    }}
                    type="text"
                    placeholder="닉네임 입력"
                    maxLength={10}
                    value={val}
                    onChange={(e) => setVal(e.target.value)}
                />
                <div
                    style={{
                        textAlign: "right",
                        fontSize: 11,
                        color: T.textMuted,
                        letterSpacing: "0.05em",
                        marginTop: 8,
                        paddingRight: 4,
                    }}
                >
                    {val.length} / 10
                </div>
            </Anim>
            <div style={{ height: 20 }} />
            <Anim active={active} delay={0.29}>
                <div
                    style={{
                        fontFamily: T.fontSerif,
                        fontSize: 15,
                        color: T.textDim,
                        textAlign: "center",
                        padding: 24,
                        background: T.surface,
                        border: `1px solid ${T.border}`,
                        borderRadius: 18,
                        marginBottom: 20,
                        letterSpacing: "0.06em",
                        lineHeight: 1.8,
                        minHeight: 80,
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                    }}
                >
                    <span>
                        반가워요,{" "}
                        <span style={{ color: T.rose, fontStyle: "normal" }}>
                            {val || "닉네임"}
                        </span>{" "}
                        님 🤍
                    </span>
                </div>
            </Anim>
            <div style={{ flex: 1 }} />
            <Anim active={active} delay={0.37}>
                <Btn
                    onClick={() => {
                        setNick(val || "달빛")
                        go("home")
                    }}
                >
                    시작하기
                </Btn>
            </Anim>
            <div style={{ height: 64 }} />
        </>
    )
}

// ═══════════════════════════════════════════════════════════
// SCREEN 5 — HOME
// ═══════════════════════════════════════════════════════════
// ─── DELETE CONFIRM MODAL ─────────────────────────────────
function DeleteModal({
    pick,
    onConfirm,
    onCancel,
}: {
    pick: PickItem
    onConfirm: () => void
    onCancel: () => void
}) {
    return (
        <div
            onClick={onCancel}
            style={{
                position: "fixed",
                inset: 0,
                zIndex: 9999,
                background: "rgba(0,0,0,0.65)",
                backdropFilter: "blur(8px)",
                WebkitBackdropFilter: "blur(8px)",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                padding: 28,
            }}
        >
            <div
                onClick={(e) => e.stopPropagation()}
                style={{
                    width: "100%",
                    maxWidth: 320,
                    background: T.surface,
                    border: `1px solid ${T.borderRose}`,
                    borderRadius: 24,
                    padding: "36px 28px 28px",
                    textAlign: "center",
                    position: "relative",
                    overflow: "hidden",
                }}
            >
                <div
                    style={{
                        position: "absolute",
                        top: -40,
                        left: "50%",
                        transform: "translateX(-50%)",
                        width: 180,
                        height: 180,
                        background:
                            "radial-gradient(circle, rgba(223,160,160,0.08) 0%, transparent 60%)",
                        pointerEvents: "none",
                    }}
                />
                <div style={{ fontSize: 32, marginBottom: 16 }}>💔</div>
                <div
                    style={{
                        fontFamily: T.fontSerif,
                        fontSize: 18,
                        fontWeight: 700,
                        color: T.text,
                        marginBottom: 8,
                        letterSpacing: "0.04em",
                    }}
                >
                    마음을 비울까요?
                </div>
                <div
                    style={{
                        fontSize: 13,
                        color: T.textDim,
                        lineHeight: 1.8,
                        marginBottom: 20,
                        letterSpacing: "0.03em",
                    }}
                >
                    <span style={{ fontFamily: T.fontSerif, fontSize: 22, color: T.rose, display: "block", marginBottom: 8 }}>
                        "{pick.word}"
                    </span>
                    이라고 표현한 마음이에요
                </div>
                <div
                    style={{
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                        gap: 8,
                        fontSize: 12,
                        color: T.textMuted,
                        marginBottom: 28,
                        padding: "10px 16px",
                        background: "rgba(255,255,255,0.03)",
                        borderRadius: 10,
                        letterSpacing: "0.04em",
                    }}
                >
                    <span>{pick.maskedPhone}</span>
                    <span style={{ opacity: 0.3 }}>|</span>
                    <span>{pick.date}</span>
                </div>
                <button
                    onClick={onConfirm}
                    style={{
                        width: "100%",
                        padding: 16,
                        borderRadius: 14,
                        background: "rgba(223,120,120,0.15)",
                        border: "1px solid rgba(223,120,120,0.3)",
                        color: "#e08080",
                        fontFamily: T.font,
                        fontSize: 14,
                        letterSpacing: "0.06em",
                        cursor: "pointer",
                        marginBottom: 10,
                    }}
                >
                    마음 비우기
                </button>
                <button
                    onClick={onCancel}
                    style={{
                        width: "100%",
                        padding: 14,
                        borderRadius: 14,
                        background: "transparent",
                        border: `1px solid ${T.border}`,
                        color: T.textMuted,
                        fontFamily: T.font,
                        fontSize: 13,
                        letterSpacing: "0.06em",
                        cursor: "pointer",
                    }}
                >
                    돌아가기
                </button>
            </div>
        </div>
    )
}

function HomeScreen({
    go,
    active,
    nick,
    sentPicks,
    onDeletePick,
}: {
    go: (s: Screen) => void
    active: boolean
    nick: string
    sentPicks: PickItem[]
    onDeletePick: (id: string) => void
}) {
    const [deleteTarget, setDeleteTarget] = useState<PickItem | null>(null)
    const usedCount = sentPicks.length
    const slots = Array.from({ length: 5 }, (_, i) => i < usedCount)

    return (
        <>
            <div style={{ height: 56 }} />
            <Anim active={active} delay={0.05}>
                <div
                    style={{
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "space-between",
                        marginBottom: 32,
                    }}
                >
                    <div
                        style={{
                            fontFamily: T.fontSerif,
                            fontSize: 20,
                            color: T.text,
                            letterSpacing: "0.04em",
                        }}
                    >
                        반가워요,{" "}
                        <span style={{ color: T.rose }}>{nick}</span> 님
                    </div>
                    <div
                        style={{
                            width: 8,
                            height: 8,
                            background: T.rose,
                            borderRadius: "50%",
                            boxShadow: "0 0 10px rgba(223,160,160,0.7)",
                            animation: "pulse 2.2s ease-in-out infinite",
                        }}
                    />
                </div>
            </Anim>

            {/* received card */}
            <Anim active={active} delay={0.13}>
                <div
                    style={{
                        background: T.surface,
                        border: `1px solid ${T.border}`,
                        borderRadius: 24,
                        padding: "28px 24px 24px",
                        marginBottom: 20,
                        position: "relative",
                        overflow: "hidden",
                    }}
                >
                    <div
                        style={{
                            position: "absolute",
                            top: -40,
                            right: -40,
                            width: 130,
                            height: 130,
                            background:
                                "radial-gradient(circle, rgba(223,160,160,0.1) 0%, transparent 70%)",
                            pointerEvents: "none",
                        }}
                    />
                    <div
                        style={{
                            fontSize: 10,
                            letterSpacing: "0.2em",
                            color: T.textMuted,
                            textTransform: "uppercase",
                            marginBottom: 18,
                        }}
                    >
                        받은 마음
                    </div>
                    <div
                        style={{
                            display: "flex",
                            alignItems: "baseline",
                            gap: 10,
                            marginBottom: 6,
                        }}
                    >
                        <span
                            style={{
                                fontFamily: T.fontSerif,
                                fontSize: 52,
                                color: T.rose,
                                lineHeight: 1,
                                textShadow:
                                    "0 0 30px rgba(223,160,160,0.3)",
                            }}
                        >
                            3
                        </span>
                        <span
                            style={{
                                fontSize: 14,
                                color: T.textDim,
                                letterSpacing: "0.04em",
                            }}
                        >
                            명
                        </span>
                    </div>
                    <div
                        style={{
                            fontSize: 12.5,
                            color: T.textMuted,
                            letterSpacing: "0.03em",
                            lineHeight: 1.7,
                            marginBottom: 20,
                        }}
                    >
                        당신에게 도착한 카드를
                        <br />
                        확인해보세요
                    </div>
                    <div
                        onClick={() => go("reveal")}
                        style={{
                            display: "flex",
                            alignItems: "center",
                            justifyContent: "space-between",
                            padding: "14px 18px",
                            background: "rgba(223,160,160,0.07)",
                            border: "1px solid rgba(223,160,160,0.15)",
                            borderRadius: 14,
                            cursor: "pointer",
                        }}
                    >
                        <span
                            style={{
                                fontSize: 13,
                                color: T.rose,
                                letterSpacing: "0.05em",
                            }}
                        >
                            카드함 확인하기
                        </span>
                        <span
                            style={{
                                fontSize: 10,
                                color: T.textMuted,
                                background: "rgba(255,255,255,0.05)",
                                padding: "4px 10px",
                                borderRadius: 20,
                                letterSpacing: "0.1em",
                            }}
                        >
                            AD
                        </span>
                    </div>
                </div>
            </Anim>

            {/* slots */}
            <Anim active={active} delay={0.21}>
                <div
                    style={{
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "space-between",
                        marginBottom: 14,
                        marginTop: 28,
                    }}
                >
                    <span
                        style={{
                            fontSize: 10,
                            letterSpacing: "0.2em",
                            color: T.textMuted,
                            textTransform: "uppercase",
                        }}
                    >
                        보낸 마음
                    </span>
                    <span
                        style={{
                            fontSize: 12,
                            color: T.textDim,
                            letterSpacing: "0.05em",
                        }}
                    >
                        {usedCount} / 5
                    </span>
                </div>
                <div style={{ display: "flex", gap: 8 }}>
                    {slots.map((used, i) => {
                        const isNext =
                            !used && slots.slice(0, i).every(Boolean)
                        const pickForSlot = used ? sentPicks[i] : null
                        return (
                            <div
                                key={i}
                                onClick={
                                    used && pickForSlot
                                        ? () => setDeleteTarget(pickForSlot)
                                        : isNext
                                          ? () => go("compose")
                                          : undefined
                                }
                                style={{
                                    flex: 1,
                                    aspectRatio: "1",
                                    borderRadius: 16,
                                    display: "flex",
                                    alignItems: "center",
                                    justifyContent: "center",
                                    fontSize: 18,
                                    cursor: used || isNext ? "pointer" : "default",
                                    transition: "all 0.2s",
                                    ...(used
                                        ? {
                                              background:
                                                  "rgba(223,160,160,0.07)",
                                              border: "1px solid rgba(223,160,160,0.18)",
                                          }
                                        : isNext
                                          ? {
                                                background:
                                                    "rgba(223,160,160,0.05)",
                                                border: "1px dashed rgba(223,160,160,0.3)",
                                            }
                                          : {
                                                background: T.surface,
                                                border: `1px dashed ${T.border}`,
                                            }),
                                }}
                            >
                                {used ? (
                                    "🤍"
                                ) : isNext ? (
                                    <span
                                        style={{
                                            fontSize: 22,
                                            color: T.rose,
                                        }}
                                    >
                                        +
                                    </span>
                                ) : (
                                    <span
                                        style={{
                                            fontSize: 22,
                                            color: "rgba(255,255,255,0.1)",
                                        }}
                                    >
                                        +
                                    </span>
                                )}
                            </div>
                        )
                    })}
                </div>
            </Anim>

            {/* history */}
            <Anim active={active} delay={0.29}>
                <div
                    style={{
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "space-between",
                        marginBottom: 14,
                        marginTop: 28,
                    }}
                >
                    <span
                        style={{
                            fontSize: 10,
                            letterSpacing: "0.2em",
                            color: T.textMuted,
                            textTransform: "uppercase",
                        }}
                    >
                        보낸 기록
                    </span>
                </div>
                {sentPicks.map((p) => (
                    <div
                        key={p.id}
                        style={{
                            display: "flex",
                            alignItems: "center",
                            gap: 14,
                            padding: "16px 0",
                            borderBottom: `1px solid ${T.border}`,
                        }}
                    >
                        <div
                            style={{
                                width: 36,
                                height: 36,
                                background: T.roseSoft,
                                borderRadius: "50%",
                                display: "flex",
                                alignItems: "center",
                                justifyContent: "center",
                                fontSize: 15,
                                flexShrink: 0,
                            }}
                        >
                            🤍
                        </div>
                        <div style={{ flex: 1 }}>
                            <div
                                style={{
                                    fontSize: 14,
                                    color: T.textDim,
                                    letterSpacing: "0.04em",
                                    marginBottom: 4,
                                }}
                            >
                                {p.maskedPhone}
                            </div>
                            <div
                                style={{
                                    fontFamily: T.fontSerif,
                                    fontSize: 16,
                                    color: T.rose,
                                    letterSpacing: "0.05em",
                                }}
                            >
                                {p.word}
                            </div>
                        </div>
                        <div style={{ textAlign: "right" }}>
                            <div
                                style={{
                                    fontSize: 11,
                                    color: T.textMuted,
                                    letterSpacing: "0.05em",
                                    marginBottom: 4,
                                }}
                            >
                                {p.date}
                            </div>
                            <div
                                style={{
                                    display: "flex",
                                    alignItems: "center",
                                    gap: 4,
                                    fontSize: 11,
                                    color: T.textMuted,
                                    justifyContent: "flex-end",
                                }}
                            >
                                <div
                                    style={{
                                        width: 5,
                                        height: 5,
                                        borderRadius: "50%",
                                        background:
                                            p.status === "sent"
                                                ? "#7ec8a0"
                                                : T.gold,
                                    }}
                                />
                                {p.status === "sent"
                                    ? "전달됨"
                                    : "내일 10시"}
                            </div>
                        </div>
                    </div>
                ))}
            </Anim>

            <div style={{ height: 80 }} />

            {deleteTarget && (
                <DeleteModal
                    pick={deleteTarget}
                    onConfirm={() => {
                        onDeletePick(deleteTarget.id)
                        setDeleteTarget(null)
                    }}
                    onCancel={() => setDeleteTarget(null)}
                />
            )}
        </>
    )
}

// ═══════════════════════════════════════════════════════════
// SCREEN 6 — COMPOSE
// ═══════════════════════════════════════════════════════════
function ComposeScreen({
    go,
    active,
}: {
    go: (s: Screen) => void
    active: boolean
}) {
    const [phone, setPhone] = useState("")
    const [word, setWord] = useState("")

    return (
        <>
            <div style={{ height: 64 }} />
            <Anim active={active} delay={0.05}>
                <BackBtn onClick={() => go("home")} />
            </Anim>
            <Anim active={active} delay={0.13}>
                <Label>마음 전하기</Label>
                <Title>
                    그 사람은 어떤
                    <br />
                    사람인가요
                    <span style={{ color: T.rose }}>?</span>
                </Title>
            </Anim>
            <div style={{ height: 32 }} />
            <Anim active={active} delay={0.21}>
                <input
                    style={{
                        width: "100%",
                        padding: "19px 20px",
                        background: T.surface,
                        border: `1px solid ${T.border}`,
                        borderRadius: 16,
                        color: T.text,
                        fontFamily: T.font,
                        fontSize: 16,
                        letterSpacing: "0.08em",
                        outline: "none",
                        WebkitAppearance: "none",
                    }}
                    type="tel"
                    placeholder="받는 사람 번호"
                    value={phone}
                    onChange={(e) => setPhone(e.target.value)}
                />

                {/* preview card */}
                <div
                    style={{
                        background: T.surface,
                        border: `1px solid ${T.border}`,
                        borderRadius: 24,
                        padding: "40px 24px",
                        textAlign: "center",
                        margin: "24px 0",
                        position: "relative",
                        overflow: "hidden",
                        minHeight: 160,
                        display: "flex",
                        flexDirection: "column",
                        alignItems: "center",
                        justifyContent: "center",
                    }}
                >
                    <div
                        style={{
                            position: "absolute",
                            inset: 0,
                            background:
                                "radial-gradient(ellipse at 50% 40%, rgba(223,160,160,0.07) 0%, transparent 65%)",
                            pointerEvents: "none",
                        }}
                    />
                    <div
                        style={{
                            fontFamily: T.fontSerif,
                            fontSize: 19,
                            color: T.text,
                            letterSpacing: "0.07em",
                            lineHeight: 2,
                            position: "relative",
                            zIndex: 1,
                        }}
                    >
                        당신은&nbsp;
                        <span
                            style={{
                                color: T.rose,
                                fontStyle: "normal",
                                borderBottom:
                                    "1px solid rgba(223,160,160,0.35)",
                                paddingBottom: 1,
                            }}
                        >
                            {word || "따뜻한"}
                        </span>
                        &nbsp;사람이에요
                    </div>
                    <div
                        style={{
                            fontSize: 11,
                            color: T.textMuted,
                            marginTop: 12,
                            letterSpacing: "0.06em",
                            position: "relative",
                            zIndex: 1,
                        }}
                    >
                        받는 분께 이렇게 전달돼요
                    </div>
                </div>
            </Anim>

            <Anim active={active} delay={0.29}>
                <Label>한 단어로 표현해요</Label>
                <input
                    style={{
                        width: "100%",
                        padding: 20,
                        background: T.surface,
                        border: "1px solid rgba(223,160,160,0.25)",
                        borderRadius: 16,
                        color: T.rose,
                        fontFamily: T.fontSerif,
                        fontSize: 22,
                        textAlign: "center",
                        letterSpacing: "0.1em",
                        outline: "none",
                        WebkitAppearance: "none",
                    }}
                    type="text"
                    placeholder="따뜻한"
                    maxLength={10}
                    value={word}
                    onChange={(e) => setWord(e.target.value)}
                />
            </Anim>
            <div style={{ height: 20 }} />
            <Anim active={active} delay={0.37}>
                <Notice icon="🌙" variant="gold">
                    내일 오전 10시에 전달돼요
                    <br />
                    <span style={{ opacity: 0.65 }}>
                        누가 보냈는지는 절대 알 수 없어요
                    </span>
                </Notice>
            </Anim>
            <div style={{ flex: 1, minHeight: 20 }} />
            <Anim active={active} delay={0.45}>
                <Btn onClick={() => go("home")}>마음 담아두기</Btn>
                <div style={{ height: 12 }} />
                <Notice icon="🔒" variant="rose">
                    한 번 보내면 취소나 삭제가 불가해요
                    <br />
                    신중하게 전해주세요
                </Notice>
            </Anim>
            <div style={{ height: 80 }} />
        </>
    )
}

// ═══════════════════════════════════════════════════════════
// SCREEN 7 — REVEAL
// ═══════════════════════════════════════════════════════════
function RevealScreen({
    go,
    active,
}: {
    go: (s: Screen) => void
    active: boolean
}) {
    const [unlockedIds, setUnlockedIds] = useState<string[]>([])

    const handleUnlock = (id: string) => {
        // 실제로는 광고 시청 후 콜백에서 호출
        setUnlockedIds((prev) => [...prev, id])
    }

    return (
        <>
            <div style={{ height: 64 }} />
            <Anim active={active} delay={0.05}>
                <BackBtn onClick={() => go("home")} />
            </Anim>
            <Anim active={active} delay={0.13}>
                <Label>받은 마음 · {RECEIVED_PICKS.length}</Label>
                <Title>
                    누군가 당신을
                    <br />
                    이렇게 표현했어요
                </Title>
            </Anim>
            <div style={{ height: 24 }} />
            <Anim active={active} delay={0.21}>
                <div
                    style={{
                        width: "100%",
                        display: "flex",
                        flexDirection: "column",
                        gap: 16,
                    }}
                >
                    {RECEIVED_PICKS.map((p) => {
                        const isUnlocked = unlockedIds.includes(p.id)
                        return (
                            <div
                                key={p.id}
                                style={{
                                    background: T.surface,
                                    border: "1px solid rgba(223,160,160,0.12)",
                                    borderRadius: 28,
                                    padding: "44px 32px",
                                    textAlign: "center",
                                    position: "relative",
                                    overflow: "hidden",
                                }}
                            >
                                <div
                                    style={{
                                        position: "absolute",
                                        top: -60,
                                        left: "50%",
                                        transform: "translateX(-50%)",
                                        width: 220,
                                        height: 220,
                                        background:
                                            "radial-gradient(circle, rgba(223,160,160,0.1) 0%, transparent 60%)",
                                        pointerEvents: "none",
                                    }}
                                />
                                {/* gender badge */}
                                <div
                                    style={{
                                        display: "inline-flex",
                                        alignItems: "center",
                                        gap: 6,
                                        padding: "6px 14px",
                                        borderRadius: 20,
                                        background: isUnlocked
                                            ? T.roseSoft
                                            : "rgba(255,255,255,0.04)",
                                        border: isUnlocked
                                            ? `1px solid ${T.borderRose}`
                                            : `1px solid ${T.border}`,
                                        marginBottom: 24,
                                        cursor: isUnlocked ? "default" : "pointer",
                                        transition: "all 0.3s",
                                    }}
                                    onClick={!isUnlocked ? () => handleUnlock(p.id) : undefined}
                                >
                                    {isUnlocked ? (
                                        <>
                                            <span style={{ fontSize: 14 }}>
                                                {p.gender === "female" ? "👩" : "👨"}
                                            </span>
                                            <span
                                                style={{
                                                    fontSize: 11,
                                                    color: T.rose,
                                                    letterSpacing: "0.06em",
                                                }}
                                            >
                                                {p.gender === "female" ? "여자" : "남자"}
                                            </span>
                                        </>
                                    ) : (
                                        <>
                                            <span style={{ fontSize: 12 }}>🔒</span>
                                            <span
                                                style={{
                                                    fontSize: 10,
                                                    color: T.textMuted,
                                                    letterSpacing: "0.06em",
                                                }}
                                            >
                                                광고 보고 성별 확인
                                            </span>
                                        </>
                                    )}
                                </div>
                                <div
                                    style={{
                                        fontSize: 10,
                                        letterSpacing: "0.22em",
                                        color: T.textMuted,
                                        textTransform: "uppercase",
                                        marginBottom: 32,
                                    }}
                                >
                                    누군가의 마음
                                </div>
                                <div
                                    style={{
                                        fontFamily: T.fontSerif,
                                        fontSize: 13,
                                        color: T.textMuted,
                                        letterSpacing: "0.1em",
                                        marginBottom: 10,
                                    }}
                                >
                                    당신은
                                </div>
                                <div
                                    style={{
                                        fontFamily: T.fontSerif,
                                        fontSize: 46,
                                        fontWeight: 700,
                                        color: T.rose,
                                        textShadow:
                                            "0 0 40px rgba(223,160,160,0.35)",
                                        letterSpacing: "0.06em",
                                        lineHeight: 1.1,
                                        marginBottom: 10,
                                    }}
                                >
                                    {p.word}
                                </div>
                                <div
                                    style={{
                                        fontFamily: T.fontSerif,
                                        fontSize: 13,
                                        color: T.textMuted,
                                        letterSpacing: "0.1em",
                                        marginBottom: 28,
                                    }}
                                >
                                    사람이에요
                                </div>
                                <div
                                    style={{
                                        width: 40,
                                        height: 1,
                                        background: T.border,
                                        margin: "0 auto 24px",
                                    }}
                                />
                                <div
                                    style={{
                                        fontSize: 13.5,
                                        color: T.textDim,
                                        lineHeight: 2,
                                        letterSpacing: "0.04em",
                                        fontStyle: "italic",
                                    }}
                                >
                                    {p.aiText.split("\n").map((line, i) => (
                                        <span key={i}>
                                            {line}
                                            <br />
                                        </span>
                                    ))}
                                </div>
                                <div
                                    style={{
                                        fontSize: 11,
                                        color: T.textMuted,
                                        letterSpacing: "0.1em",
                                        marginTop: 24,
                                    }}
                                >
                                    {p.date}
                                </div>
                            </div>
                        )
                    })}
                </div>
            </Anim>
            <div style={{ height: 80 }} />
        </>
    )
}

// ═══════════════════════════════════════════════════════════
// MAIN APP
// ═══════════════════════════════════════════════════════════
export default function LovePickApp(props: {
    initialScreen?: Screen
}) {
    const { initialScreen = "splash" } = props
    const [screen, setScreen] = useState<Screen>(initialScreen)
    const [prevScreen, setPrevScreen] = useState<Screen | null>(null)
    const [nick, setNick] = useState("달빛")
    const [gender, setGender] = useState<Gender>("female")
    const [sentPicks, setSentPicks] = useState<PickItem[]>([...SENT_PICKS])
    const containerRef = useRef<HTMLDivElement>(null)
    const [containerH, setContainerH] = useState(800)

    useEffect(() => {
        if (containerRef.current) {
            setContainerH(containerRef.current.offsetHeight)
        }
    }, [])

    const go = useCallback(
        (s: Screen) => {
            setPrevScreen(screen)
            setScreen(s)
        },
        [screen]
    )

    const getDirection = (id: Screen): "enter" | "exit" | "idle" => {
        if (id === screen) return "enter"
        if (id === prevScreen) return "exit"
        return "idle"
    }

    return (
        <div
            ref={containerRef}
            style={{
                width: 390,
                height: "100%",
                margin: "0 auto",
                position: "relative",
                overflow: "hidden",
                background: T.bg,
                fontFamily: T.font,
                color: T.text,
                WebkitFontSmoothing: "antialiased",
            }}
        >
            <FontLoader />
            <StarCanvas height={containerH} />

            {/* screens */}
            <ScreenWrap
                active={screen === "splash"}
                direction={getDirection("splash")}
                style={{
                    alignItems: "center",
                    justifyContent: "center",
                    textAlign: "center",
                    paddingTop: 0,
                }}
            >
                <SplashScreen go={go} active={screen === "splash"} />
            </ScreenWrap>

            <ScreenWrap
                active={screen === "gender"}
                direction={getDirection("gender")}
                style={{
                    alignItems: "center",
                    justifyContent: "center",
                    textAlign: "center",
                }}
            >
                <GenderScreen go={go} active={screen === "gender"} setGender={setGender} />
            </ScreenWrap>

            <ScreenWrap
                active={screen === "phone"}
                direction={getDirection("phone")}
            >
                <PhoneScreen go={go} active={screen === "phone"} />
            </ScreenWrap>

            <ScreenWrap
                active={screen === "otp"}
                direction={getDirection("otp")}
            >
                <OTPScreen go={go} active={screen === "otp"} />
            </ScreenWrap>

            <ScreenWrap
                active={screen === "nickname"}
                direction={getDirection("nickname")}
            >
                <NicknameScreen
                    go={go}
                    active={screen === "nickname"}
                    setNick={setNick}
                />
            </ScreenWrap>

            <ScreenWrap
                active={screen === "home"}
                direction={getDirection("home")}
                style={{ overflowY: screen === "home" ? "auto" : "hidden" }}
            >
                <HomeScreen
                    go={go}
                    active={screen === "home"}
                    nick={nick}
                    sentPicks={sentPicks}
                    onDeletePick={(id) => setSentPicks((prev) => prev.filter((p) => p.id !== id))}
                />
            </ScreenWrap>

            <ScreenWrap
                active={screen === "compose"}
                direction={getDirection("compose")}
                style={{
                    overflowY: screen === "compose" ? "auto" : "hidden",
                }}
            >
                <ComposeScreen go={go} active={screen === "compose"} />
            </ScreenWrap>

            <ScreenWrap
                active={screen === "reveal"}
                direction={getDirection("reveal")}
                style={{
                    overflowY: screen === "reveal" ? "auto" : "hidden",
                }}
            >
                <RevealScreen go={go} active={screen === "reveal"} />
            </ScreenWrap>

        </div>
    )
}

addPropertyControls(LovePickApp, {
    initialScreen: {
        type: ControlType.Enum,
        title: "시작 화면",
        options: [
            "splash",
            "gender",
            "phone",
            "otp",
            "nickname",
            "home",
            "compose",
            "reveal",
        ],
        optionTitles: [
            "스플래시",
            "성별",
            "전화번호",
            "OTP",
            "닉네임",
            "홈",
            "보내기",
            "확인하기",
        ],
        defaultValue: "splash",
    },
})
