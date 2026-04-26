import Foundation

enum AppLanguage: String, CaseIterable, Codable {
    case en = "English"
    case ko = "한국어"
    case ja = "日本語"
    case zh = "中文"
    case es = "Español"
    case de = "Deutsch"
    case fr = "Français"
    case pt = "Português"
}

class L10n: ObservableObject {
    static let shared = L10n()
    @Published var lang: AppLanguage

    init() {
        if let saved = UserDefaults.standard.string(forKey: "appLanguage"),
           let l = AppLanguage(rawValue: saved) {
            lang = l
        } else {
            lang = .en
        }
    }

    func set(_ language: AppLanguage) {
        lang = language
        UserDefaults.standard.set(language.rawValue, forKey: "appLanguage")
    }

    // MARK: - Translations
    subscript(_ key: String) -> String {
        Self.strings[key]?[lang] ?? Self.strings[key]?[.en] ?? key
    }

    static let strings: [String: [AppLanguage: String]] = [
        // Menu
        "posture": [.en: "Posture", .ko: "자세", .ja: "姿勢", .zh: "姿势", .es: "Postura", .de: "Haltung", .fr: "Posture", .pt: "Postura"],
        "good": [.en: "Good", .ko: "좋음", .ja: "良好", .zh: "良好", .es: "Buena", .de: "Gut", .fr: "Bonne", .pt: "Boa"],
        "warning": [.en: "Warning", .ko: "주의", .ja: "注意", .zh: "注意", .es: "Alerta", .de: "Warnung", .fr: "Attention", .pt: "Alerta"],
        "bad": [.en: "Bad", .ko: "나쁨", .ja: "悪い", .zh: "差", .es: "Mala", .de: "Schlecht", .fr: "Mauvaise", .pt: "Ruim"],
        "calibration": [.en: "Calibration", .ko: "캘리브레이션", .ja: "キャリブレーション", .zh: "校准", .es: "Calibración", .de: "Kalibrierung", .fr: "Calibration", .pt: "Calibração"],
        "stats": [.en: "Stats", .ko: "통계", .ja: "統計", .zh: "统计", .es: "Estadísticas", .de: "Statistiken", .fr: "Statistiques", .pt: "Estatísticas"],
        "settings": [.en: "Settings", .ko: "설정", .ja: "設定", .zh: "设置", .es: "Ajustes", .de: "Einstellungen", .fr: "Paramètres", .pt: "Configurações"],
        "customize": [.en: "Customize", .ko: "커스터마이즈", .ja: "カスタマイズ", .zh: "自定义", .es: "Personalizar", .de: "Anpassen", .fr: "Personnaliser", .pt: "Personalizar"],
        "pause": [.en: "Pause", .ko: "일시정지", .ja: "一時停止", .zh: "暂停", .es: "Pausar", .de: "Pause", .fr: "Pause", .pt: "Pausar"],
        "resume": [.en: "Resume", .ko: "재개", .ja: "再開", .zh: "继续", .es: "Reanudar", .de: "Fortsetzen", .fr: "Reprendre", .pt: "Retomar"],
        "quit": [.en: "Quit", .ko: "종료", .ja: "終了", .zh: "退出", .es: "Salir", .de: "Beenden", .fr: "Quitter", .pt: "Sair"],

        // Calibration
        "calibration_title": [.en: "Calibration", .ko: "캘리브레이션", .ja: "キャリブレーション", .zh: "校准", .es: "Calibración", .de: "Kalibrierung", .fr: "Calibration", .pt: "Calibração"],
        "sit_straight": [.en: "Sit up straight and look at the camera", .ko: "바른 자세로 카메라를 바라봐주세요", .ja: "正しい姿勢でカメラを見てください", .zh: "坐直并看着摄像头", .es: "Siéntate derecho y mira a la cámara", .de: "Sitz gerade und schau in die Kamera", .fr: "Asseyez-vous droit et regardez la caméra", .pt: "Sente-se ereto e olhe para a câmera"],
        "hold_posture": [.en: "Hold your good posture!", .ko: "바른 자세를 유지해주세요!", .ja: "良い姿勢を保ってください！", .zh: "保持良好姿势！", .es: "¡Mantén tu buena postura!", .de: "Halte deine gute Haltung!", .fr: "Gardez votre bonne posture !", .pt: "Mantenha sua boa postura!"],
        "calibration_done": [.en: "Calibration Complete!", .ko: "캘리브레이션 완료!", .ja: "キャリブレーション完了！", .zh: "校准完成！", .es: "¡Calibración completada!", .de: "Kalibrierung abgeschlossen!", .fr: "Calibration terminée !", .pt: "Calibração concluída!"],
        "turtle_watching": [.en: "The turtle is now watching your posture...", .ko: "거북이가 자세를 감시합니다...", .ja: "カメが姿勢を監視しています...", .zh: "乌龟正在监视你的姿势...", .es: "La tortuga ahora vigila tu postura...", .de: "Die Schildkröte überwacht jetzt deine Haltung...", .fr: "La tortue surveille maintenant votre posture...", .pt: "A tartaruga agora está vigiando sua postura..."],
        "start": [.en: "Start", .ko: "시작", .ja: "開始", .zh: "开始", .es: "Iniciar", .de: "Starten", .fr: "Démarrer", .pt: "Iniciar"],
        "start_calibration": [.en: "Start Calibration", .ko: "캘리브레이션 시작", .ja: "キャリブレーション開始", .zh: "开始校准", .es: "Iniciar calibración", .de: "Kalibrierung starten", .fr: "Démarrer la calibration", .pt: "Iniciar calibração"],
        "face_not_detected": [.en: "Face not detected. Make sure your face is visible and well-lit.", .ko: "얼굴이 감지되지 않았습니다. 얼굴이 잘 보이는지 확인해주세요.", .ja: "顔が検出されませんでした。顔が見えることを確認してください。", .zh: "未检测到面部。请确保面部可见且光线充足。", .es: "Rostro no detectado. Asegúrate de que tu rostro sea visible.", .de: "Gesicht nicht erkannt. Stelle sicher, dass dein Gesicht sichtbar ist.", .fr: "Visage non détecté. Assurez-vous que votre visage est visible.", .pt: "Rosto não detectado. Certifique-se de que seu rosto esteja visível."],
        "camera_local": [.en: "📷 Camera is processed locally. No video is stored.", .ko: "📷 카메라는 로컬에서만 처리됩니다. 영상은 저장되지 않습니다.", .ja: "📷 カメラはローカルで処理されます。映像は保存されません。", .zh: "📷 摄像头仅在本地处理。不存储视频。", .es: "📷 La cámara se procesa localmente. No se almacena video.", .de: "📷 Kamera wird lokal verarbeitet. Kein Video wird gespeichert.", .fr: "📷 La caméra est traitée localement. Aucune vidéo n'est stockée.", .pt: "📷 A câmera é processada localmente. Nenhum vídeo é armazenado."],

        // Stats
        "today": [.en: "Today", .ko: "오늘", .ja: "今日", .zh: "今天", .es: "Hoy", .de: "Heute", .fr: "Aujourd'hui", .pt: "Hoje"],
        "weekly": [.en: "Weekly", .ko: "주간", .ja: "週間", .zh: "每周", .es: "Semanal", .de: "Wöchentlich", .fr: "Hebdomadaire", .pt: "Semanal"],
        "year": [.en: "Year", .ko: "연간", .ja: "年間", .zh: "年度", .es: "Anual", .de: "Jährlich", .fr: "Annuel", .pt: "Anual"],
        "score": [.en: "Score", .ko: "점수", .ja: "スコア", .zh: "分数", .es: "Puntuación", .de: "Punktzahl", .fr: "Score", .pt: "Pontuação"],
        "turtle_visits": [.en: "Turtle Visits", .ko: "거북이 등장", .ja: "カメの訪問", .zh: "乌龟出现", .es: "Visitas tortuga", .de: "Schildkröten-Besuche", .fr: "Visites tortue", .pt: "Visitas tartaruga"],
        "bad_posture": [.en: "Bad Posture", .ko: "나쁜 자세", .ja: "悪い姿勢", .zh: "不良姿势", .es: "Mala postura", .de: "Schlechte Haltung", .fr: "Mauvaise posture", .pt: "Má postura"],
        "day_streak": [.en: "day streak", .ko: "일 연속", .ja: "日連続", .zh: "天连续", .es: "días seguidos", .de: "Tage Serie", .fr: "jours consécutifs", .pt: "dias seguidos"],

        // Settings
        "detection": [.en: "Detection", .ko: "감지", .ja: "検出", .zh: "检测", .es: "Detección", .de: "Erkennung", .fr: "Détection", .pt: "Detecção"],
        "sensitivity": [.en: "Sensitivity", .ko: "민감도", .ja: "感度", .zh: "灵敏度", .es: "Sensibilidad", .de: "Empfindlichkeit", .fr: "Sensibilité", .pt: "Sensibilidade"],
        "schedule": [.en: "Schedule", .ko: "스케줄", .ja: "スケジュール", .zh: "时间表", .es: "Horario", .de: "Zeitplan", .fr: "Horaire", .pt: "Horário"],
        "language": [.en: "Language", .ko: "언어", .ja: "言語", .zh: "语言", .es: "Idioma", .de: "Sprache", .fr: "Langue", .pt: "Idioma"],
        "general": [.en: "General", .ko: "일반", .ja: "一般", .zh: "通用", .es: "General", .de: "Allgemein", .fr: "Général", .pt: "Geral"],
        "privacy": [.en: "Privacy", .ko: "개인정보", .ja: "プライバシー", .zh: "隐私", .es: "Privacidad", .de: "Datenschutz", .fr: "Confidentialité", .pt: "Privacidade"],
        "launch_at_login": [.en: "Launch at login", .ko: "로그인 시 자동 실행", .ja: "ログイン時に起動", .zh: "登录时启动", .es: "Iniciar al arrancar", .de: "Bei Anmeldung starten", .fr: "Lancer au démarrage", .pt: "Iniciar no login"],
        "focus_mode": [.en: "Pause during Focus Mode", .ko: "집중 모드 시 일시정지", .ja: "集中モード中は一時停止", .zh: "专注模式时暂停", .es: "Pausar en modo Enfoque", .de: "Während Fokus-Modus pausieren", .fr: "Pause pendant le mode Concentration", .pt: "Pausar durante o modo Foco"],
        "unlock_full": [.en: "🐢 Unlock Full Version", .ko: "🐢 전체 버전 잠금 해제", .ja: "🐢 フルバージョンを解除", .zh: "🐢 解锁完整版", .es: "🐢 Desbloquear versión completa", .de: "🐢 Vollversion freischalten", .fr: "🐢 Débloquer la version complète", .pt: "🐢 Desbloquear versão completa"],

        // Onboarding
        "welcome": [.en: "Welcome to TurtleNeck", .ko: "TurtleNeck에 오신 것을 환영합니다", .ja: "TurtleNeckへようこそ", .zh: "欢迎使用TurtleNeck", .es: "Bienvenido a TurtleNeck", .de: "Willkommen bei TurtleNeck", .fr: "Bienvenue sur TurtleNeck", .pt: "Bem-vindo ao TurtleNeck"],
        "welcome_desc": [.en: "Your friendly posture guardian that\nkeeps your neck in check.", .ko: "당신의 자세를 지켜주는\n친절한 거북이 가디언.", .ja: "あなたの姿勢を見守る\nフレンドリーなカメのガーディアン。", .zh: "守护你姿势的\n友好乌龟守卫。", .es: "Tu amigable guardián de postura\nque cuida tu cuello.", .de: "Dein freundlicher Haltungswächter,\nder deinen Nacken im Blick behält.", .fr: "Votre gardien de posture amical\nqui surveille votre cou.", .pt: "Seu guardião de postura amigável\nque cuida do seu pescoço."],
        "how_it_works": [.en: "How It Works", .ko: "작동 방식", .ja: "使い方", .zh: "工作原理", .es: "Cómo funciona", .de: "So funktioniert's", .fr: "Comment ça marche", .pt: "Como funciona"],
        "privacy_matters": [.en: "Your Privacy Matters", .ko: "개인정보를 중요하게 생각합니다", .ja: "プライバシーを大切にします", .zh: "您的隐私很重要", .es: "Tu privacidad importa", .de: "Deine Privatsphäre ist wichtig", .fr: "Votre vie privée compte", .pt: "Sua privacidade importa"],
        "get_started": [.en: "Get Started", .ko: "시작하기", .ja: "始める", .zh: "开始使用", .es: "Comenzar", .de: "Los geht's", .fr: "Commencer", .pt: "Começar"],
        "next": [.en: "Next", .ko: "다음", .ja: "次へ", .zh: "下一步", .es: "Siguiente", .de: "Weiter", .fr: "Suivant", .pt: "Próximo"],
        "back": [.en: "Back", .ko: "뒤로", .ja: "戻る", .zh: "返回", .es: "Atrás", .de: "Zurück", .fr: "Retour", .pt: "Voltar"],

        // Settings extras
        "cooldown": [.en: "Cooldown", .ko: "쿨다운", .ja: "クールダウン", .zh: "冷却时间", .es: "Enfriamiento", .de: "Abklingzeit", .fr: "Temps de recharge", .pt: "Tempo de espera"],
        "active_work_hours": [.en: "Active during work hours only", .ko: "업무 시간에만 활성화", .ja: "勤務時間中のみ有効", .zh: "仅在工作时间内激活", .es: "Activo solo en horario laboral", .de: "Nur während der Arbeitszeit aktiv", .fr: "Actif uniquement pendant les heures de travail", .pt: "Ativo apenas durante o horário de trabalho"],
        "schedule_desc": [.en: "Only monitor your posture during set hours. Outside these hours, TurtleNeck stays quiet.", .ko: "설정한 시간에만 자세를 감시합니다. 그 외 시간에는 조용히 쉽니다.", .ja: "設定した時間帯のみ姿勢を監視します。それ以外の時間は静かにしています。", .zh: "仅在设定的时间段内监测姿势。其他时间保持安静。", .es: "Solo monitorea tu postura durante las horas establecidas.", .de: "Überwacht deine Haltung nur während der eingestellten Zeiten.", .fr: "Surveille votre posture uniquement pendant les heures définies.", .pt: "Monitora sua postura apenas durante os horários definidos."],
        "disable_per_app": [.en: "Disable per App", .ko: "앱별 비활성화", .ja: "アプリごとに無効化", .zh: "按应用禁用", .es: "Desactivar por app", .de: "Pro App deaktivieren", .fr: "Désactiver par app", .pt: "Desativar por app"],
        "disable_per_app_desc": [.en: "Detection pauses while these apps are running", .ko: "이 앱이 실행 중이면 감지를 중지합니다", .ja: "これらのアプリ実行中は検出を一時停止します", .zh: "这些应用运行时暂停检测", .es: "La detección se pausa mientras estas apps están abiertas", .de: "Erkennung pausiert, während diese Apps laufen", .fr: "La détection se met en pause pendant l'exécution de ces apps", .pt: "A detecção pausa enquanto esses apps estão abertos"],
        "add_app": [.en: "Add app:", .ko: "앱 추가:", .ja: "アプリ追加:", .zh: "添加应用:", .es: "Añadir app:", .de: "App hinzufügen:", .fr: "Ajouter une app :", .pt: "Adicionar app:"],
        "add": [.en: "Add", .ko: "추가", .ja: "追加", .zh: "添加", .es: "Añadir", .de: "Hinzufügen", .fr: "Ajouter", .pt: "Adicionar"],
        "remove": [.en: "Remove", .ko: "삭제", .ja: "削除", .zh: "删除", .es: "Eliminar", .de: "Entfernen", .fr: "Supprimer", .pt: "Remover"],
        "focus_mode_desc": [.en: "Automatically pauses while macOS Focus / Do Not Disturb is active. Set up Focus in System Settings → Focus.", .ko: "macOS 집중 모드/방해 금지가 활성화되면 자동으로 일시정지합니다. 시스템 설정 → 집중 모드에서 설정하세요.", .ja: "macOSの集中モード/おやすみモードが有効な間、自動的に一時停止します。", .zh: "当macOS专注模式/勿扰模式激活时自动暂停。", .es: "Se pausa automáticamente cuando el modo Enfoque de macOS está activo.", .de: "Pausiert automatisch, wenn der macOS-Fokus-Modus aktiv ist.", .fr: "Se met automatiquement en pause lorsque le mode Concentration de macOS est actif.", .pt: "Pausa automaticamente quando o modo Foco do macOS está ativo."],

        // Break Reminder
        "break_reminder": [.en: "Break Reminder", .ko: "휴식 알림", .ja: "休憩リマインダー", .zh: "休息提醒", .es: "Recordatorio de descanso", .de: "Pausenerinnerung", .fr: "Rappel de pause", .pt: "Lembrete de pausa"],
        "break_enable": [.en: "Enable (Pomodoro style)", .ko: "활성화 (뽀모도로 스타일)", .ja: "有効化（ポモドーロスタイル）", .zh: "启用（番茄钟风格）", .es: "Activar (estilo Pomodoro)", .de: "Aktivieren (Pomodoro-Stil)", .fr: "Activer (style Pomodoro)", .pt: "Ativar (estilo Pomodoro)"],
        "break_desc": [.en: "Work for a set period, then get a reminder to stand up, stretch, and rest your eyes.", .ko: "설정한 시간 동안 작업 후, 일어나서 스트레칭하라는 알림을 받습니다.", .ja: "設定した時間作業した後、立ち上がってストレッチするリマインダーが届きます。", .zh: "工作一段时间后，会提醒你站起来伸展和休息眼睛。", .es: "Trabaja durante un período y recibe un recordatorio para estirarte.", .de: "Arbeite eine festgelegte Zeit, dann wirst du ans Aufstehen und Dehnen erinnert.", .fr: "Travaillez pendant une période définie, puis recevez un rappel pour vous étirer.", .pt: "Trabalhe por um período definido e receba um lembrete para se alongar."],
        "work": [.en: "Work", .ko: "작업", .ja: "作業", .zh: "工作", .es: "Trabajo", .de: "Arbeit", .fr: "Travail", .pt: "Trabalho"],
        "break": [.en: "Break", .ko: "휴식", .ja: "休憩", .zh: "休息", .es: "Descanso", .de: "Pause", .fr: "Pause", .pt: "Pausa"],

        // Privacy
        "camera_local_only": [.en: "Camera is processed locally only", .ko: "카메라는 로컬에서만 처리됩니다", .ja: "カメラはローカルでのみ処理されます", .zh: "摄像头仅在本地处理", .es: "La cámara se procesa solo localmente", .de: "Kamera wird nur lokal verarbeitet", .fr: "La caméra est traitée localement uniquement", .pt: "A câmera é processada apenas localmente"],
        "no_video_stored": [.en: "No video is stored or transmitted", .ko: "영상은 저장되거나 전송되지 않습니다", .ja: "映像は保存・送信されません", .zh: "不存储或传输视频", .es: "No se almacena ni transmite video", .de: "Kein Video wird gespeichert oder übertragen", .fr: "Aucune vidéo n'est stockée ou transmise", .pt: "Nenhum vídeo é armazenado ou transmitido"],
        "privacy_policy": [.en: "Privacy Policy", .ko: "개인정보 처리방침", .ja: "プライバシーポリシー", .zh: "隐私政策", .es: "Política de privacidad", .de: "Datenschutzrichtlinie", .fr: "Politique de confidentialité", .pt: "Política de privacidade"],

        // Support
        "support": [.en: "Support", .ko: "후원", .ja: "サポート", .zh: "支持", .es: "Apoyar", .de: "Unterstützen", .fr: "Soutenir", .pt: "Apoiar"],
        "buy_coffee": [.en: "Buy the developer a coffee ☕", .ko: "개발자에게 커피 한 잔 사주세요 ☕", .ja: "開発者にコーヒーをおごる ☕", .zh: "请开发者喝杯咖啡 ☕", .es: "Invita al desarrollador a un café ☕", .de: "Kauf dem Entwickler einen Kaffee ☕", .fr: "Offrez un café au développeur ☕", .pt: "Pague um café para o desenvolvedor ☕"],
        "support_desc": [.en: "TurtleNeck is free and open source. If it helped your posture, consider supporting!", .ko: "TurtleNeck은 무료 오픈소스입니다. 자세 교정에 도움이 되었다면 후원을 고려해주세요!", .ja: "TurtleNeckは無料のオープンソースです。姿勢改善に役立ったら、サポートをご検討ください！", .zh: "TurtleNeck是免费开源的。如果它帮助了你的姿势，请考虑支持！", .es: "TurtleNeck es gratis y de código abierto. ¡Si te ayudó, considera apoyar!", .de: "TurtleNeck ist kostenlos und Open Source. Wenn es dir geholfen hat, unterstütze uns!", .fr: "TurtleNeck est gratuit et open source. S'il vous a aidé, pensez à nous soutenir !", .pt: "TurtleNeck é gratuito e open source. Se ajudou sua postura, considere apoiar!"],
        "support_kofi": [.en: "Support on Ko-fi", .ko: "Ko-fi에서 후원하기", .ja: "Ko-fiでサポート", .zh: "在Ko-fi上支持", .es: "Apoyar en Ko-fi", .de: "Auf Ko-fi unterstützen", .fr: "Soutenir sur Ko-fi", .pt: "Apoiar no Ko-fi"],

        // Customize
        "character": [.en: "Character", .ko: "캐릭터", .ja: "キャラクター", .zh: "角色", .es: "Personaje", .de: "Charakter", .fr: "Personnage", .pt: "Personagem"],
        "choose_who": [.en: "Choose who roasts you", .ko: "누가 잔소리할지 선택하세요", .ja: "誰に叱られるか選んでください", .zh: "选择谁来吐槽你", .es: "Elige quién te regaña", .de: "Wähle, wer dich ermahnt", .fr: "Choisissez qui vous gronde", .pt: "Escolha quem te repreende"],
        "custom_messages": [.en: "Custom Messages", .ko: "커스텀 메시지", .ja: "カスタムメッセージ", .zh: "自定义消息", .es: "Mensajes personalizados", .de: "Eigene Nachrichten", .fr: "Messages personnalisés", .pt: "Mensagens personalizadas"],
        "preview": [.en: "Preview", .ko: "미리보기", .ja: "プレビュー", .zh: "预览", .es: "Vista previa", .de: "Vorschau", .fr: "Aperçu", .pt: "Pré-visualização"],
        "type_message": [.en: "Type a message...", .ko: "메시지를 입력하세요...", .ja: "メッセージを入力...", .zh: "输入消息...", .es: "Escribe un mensaje...", .de: "Nachricht eingeben...", .fr: "Tapez un message...", .pt: "Digite uma mensagem..."],
        "use_custom_image": [.en: "Use Custom Image...", .ko: "커스텀 이미지 사용...", .ja: "カスタム画像を使用...", .zh: "使用自定义图片...", .es: "Usar imagen personalizada...", .de: "Eigenes Bild verwenden...", .fr: "Utiliser une image personnalisée...", .pt: "Usar imagem personalizada..."],

        // Stats extras
        "best": [.en: "Best", .ko: "최고", .ja: "最高", .zh: "最佳", .es: "Mejor", .de: "Beste", .fr: "Meilleur", .pt: "Melhor"],
        "days": [.en: "days", .ko: "일", .ja: "日", .zh: "天", .es: "días", .de: "Tage", .fr: "jours", .pt: "dias"],
        "year_overview": [.en: "Year Overview", .ko: "연간 개요", .ja: "年間概要", .zh: "年度概览", .es: "Resumen anual", .de: "Jahresübersicht", .fr: "Aperçu annuel", .pt: "Visão anual"],

        // Calibration extras
        "recalibrate": [.en: "Recalibrate", .ko: "재설정", .ja: "再キャリブレーション", .zh: "重新校准", .es: "Recalibrar", .de: "Neu kalibrieren", .fr: "Recalibrer", .pt: "Recalibrar"],
        "reset_confirm": [.en: "Reset Calibration?", .ko: "캘리브레이션을 초기화할까요?", .ja: "キャリブレーションをリセットしますか？", .zh: "重置校准？", .es: "¿Restablecer calibración?", .de: "Kalibrierung zurücksetzen?", .fr: "Réinitialiser la calibration ?", .pt: "Redefinir calibração?"],
        "reset_confirm_msg": [.en: "This will replace your current posture baseline.", .ko: "현재 자세 기준점이 교체됩니다.", .ja: "現在の姿勢基準が置き換えられます。", .zh: "这将替换您当前的姿势基准。", .es: "Esto reemplazará tu línea base de postura actual.", .de: "Dies ersetzt deine aktuelle Haltungsbasislinie.", .fr: "Cela remplacera votre référence de posture actuelle.", .pt: "Isso substituirá sua linha de base de postura atual."],
        "cancel": [.en: "Cancel", .ko: "취소", .ja: "キャンセル", .zh: "取消", .es: "Cancelar", .de: "Abbrechen", .fr: "Annuler", .pt: "Cancelar"],
    ]
}
