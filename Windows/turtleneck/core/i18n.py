"""Localization — 8 languages."""

LANGUAGES = {
    "en": "English", "ko": "한국어", "ja": "日本語", "zh": "中文",
    "es": "Español", "de": "Deutsch", "fr": "Français", "pt": "Português",
}

_S = {
    "posture": {"en":"Posture","ko":"자세","ja":"姿勢","zh":"姿势","es":"Postura","de":"Haltung","fr":"Posture","pt":"Postura"},
    "good": {"en":"Good","ko":"좋음","ja":"良好","zh":"良好","es":"Buena","de":"Gut","fr":"Bonne","pt":"Boa"},
    "warning": {"en":"Warning","ko":"주의","ja":"注意","zh":"注意","es":"Alerta","de":"Warnung","fr":"Attention","pt":"Alerta"},
    "bad": {"en":"Bad","ko":"나쁨","ja":"悪い","zh":"差","es":"Mala","de":"Schlecht","fr":"Mauvaise","pt":"Ruim"},
    "calibration": {"en":"Calibration","ko":"캘리브레이션","ja":"キャリブレーション","zh":"校准","es":"Calibración","de":"Kalibrierung","fr":"Calibration","pt":"Calibração"},
    "stats": {"en":"Stats","ko":"통계","ja":"統計","zh":"统计","es":"Estadísticas","de":"Statistiken","fr":"Statistiques","pt":"Estatísticas"},
    "settings": {"en":"Settings","ko":"설정","ja":"設定","zh":"设置","es":"Ajustes","de":"Einstellungen","fr":"Paramètres","pt":"Configurações"},
    "customize": {"en":"Customize","ko":"커스터마이즈","ja":"カスタマイズ","zh":"自定义","es":"Personalizar","de":"Anpassen","fr":"Personnaliser","pt":"Personalizar"},
    "pause": {"en":"Pause","ko":"일시정지","ja":"一時停止","zh":"暂停","es":"Pausar","de":"Pause","fr":"Pause","pt":"Pausar"},
    "resume": {"en":"Resume","ko":"재개","ja":"再開","zh":"继续","es":"Reanudar","de":"Fortsetzen","fr":"Reprendre","pt":"Retomar"},
    "quit": {"en":"Quit","ko":"종료","ja":"終了","zh":"退出","es":"Salir","de":"Beenden","fr":"Quitter","pt":"Sair"},
    "start": {"en":"Start","ko":"시작","ja":"開始","zh":"开始","es":"Iniciar","de":"Starten","fr":"Démarrer","pt":"Iniciar"},
    "sit_straight": {"en":"Sit up straight and look at the camera","ko":"바른 자세로 카메라를 바라봐주세요","ja":"正しい姿勢でカメラを見てください","zh":"坐直并看着摄像头","es":"Siéntate derecho y mira a la cámara","de":"Sitz gerade und schau in die Kamera","fr":"Asseyez-vous droit et regardez la caméra","pt":"Sente-se ereto e olhe para a câmera"},
    "hold_posture": {"en":"Hold your good posture!","ko":"바른 자세를 유지해주세요!","ja":"良い姿勢を保ってください！","zh":"保持良好姿势！","es":"¡Mantén tu buena postura!","de":"Halte deine gute Haltung!","fr":"Gardez votre bonne posture !","pt":"Mantenha sua boa postura!"},
    "calibration_done": {"en":"Calibration Complete!","ko":"캘리브레이션 완료!","ja":"キャリブレーション完了！","zh":"校准完成！","es":"¡Calibración completada!","de":"Kalibrierung abgeschlossen!","fr":"Calibration terminée !","pt":"Calibração concluída!"},
    "turtle_watching": {"en":"The turtle is now watching your posture...","ko":"거북이가 자세를 감시합니다...","ja":"カメが姿勢を監視しています...","zh":"乌龟正在监视你的姿势...","es":"La tortuga ahora vigila tu postura...","de":"Die Schildkröte überwacht jetzt deine Haltung...","fr":"La tortue surveille maintenant votre posture...","pt":"A tartaruga agora está vigiando sua postura..."},
    "face_not_detected": {"en":"Face not detected. Make sure your face is visible.","ko":"얼굴이 감지되지 않았습니다. 얼굴이 잘 보이는지 확인해주세요.","ja":"顔が検出されませんでした。","zh":"未检测到面部。","es":"Rostro no detectado.","de":"Gesicht nicht erkannt.","fr":"Visage non détecté.","pt":"Rosto não detectado."},
    "camera_local": {"en":"📷 Camera is processed locally. No video is stored.","ko":"📷 카메라는 로컬에서만 처리됩니다.","ja":"📷 カメラはローカルで処理されます。","zh":"📷 摄像头仅在本地处理。","es":"📷 La cámara se procesa localmente.","de":"📷 Kamera wird lokal verarbeitet.","fr":"📷 La caméra est traitée localement.","pt":"📷 A câmera é processada localmente."},
    "today": {"en":"Today","ko":"오늘","ja":"今日","zh":"今天","es":"Hoy","de":"Heute","fr":"Aujourd'hui","pt":"Hoje"},
    "weekly": {"en":"Weekly","ko":"주간","ja":"週間","zh":"每周","es":"Semanal","de":"Wöchentlich","fr":"Hebdomadaire","pt":"Semanal"},
    "year": {"en":"Year","ko":"연간","ja":"年間","zh":"年度","es":"Anual","de":"Jährlich","fr":"Annuel","pt":"Anual"},
    "score": {"en":"Score","ko":"점수","ja":"スコア","zh":"分数","es":"Puntuación","de":"Punktzahl","fr":"Score","pt":"Pontuação"},
    "turtle_visits": {"en":"Turtle Visits","ko":"거북이 등장","ja":"カメの訪問","zh":"乌龟出现","es":"Visitas tortuga","de":"Schildkröten-Besuche","fr":"Visites tortue","pt":"Visitas tartaruga"},
    "bad_posture": {"en":"Bad Posture","ko":"나쁜 자세","ja":"悪い姿勢","zh":"不良姿势","es":"Mala postura","de":"Schlechte Haltung","fr":"Mauvaise posture","pt":"Má postura"},
    "sensitivity": {"en":"Sensitivity","ko":"민감도","ja":"感度","zh":"灵敏度","es":"Sensibilidad","de":"Empfindlichkeit","fr":"Sensibilité","pt":"Sensibilidade"},
    "schedule": {"en":"Schedule","ko":"스케줄","ja":"スケジュール","zh":"时间表","es":"Horario","de":"Zeitplan","fr":"Horaire","pt":"Horário"},
    "language": {"en":"Language","ko":"언어","ja":"言語","zh":"语言","es":"Idioma","de":"Sprache","fr":"Langue","pt":"Idioma"},
    "general": {"en":"General","ko":"일반","ja":"一般","zh":"通用","es":"General","de":"Allgemein","fr":"Général","pt":"Geral"},
    "privacy": {"en":"Privacy","ko":"개인정보","ja":"プライバシー","zh":"隐私","es":"Privacidad","de":"Datenschutz","fr":"Confidentialité","pt":"Privacidade"},
    "support": {"en":"Support","ko":"후원","ja":"サポート","zh":"支持","es":"Apoyar","de":"Unterstützen","fr":"Soutenir","pt":"Apoiar"},
    "buy_coffee": {"en":"Buy the developer a coffee ☕","ko":"개발자에게 커피 한 잔 사주세요 ☕","ja":"開発者にコーヒーをおごる ☕","zh":"请开发者喝杯咖啡 ☕","es":"Invita al desarrollador a un café ☕","de":"Kauf dem Entwickler einen Kaffee ☕","fr":"Offrez un café au développeur ☕","pt":"Pague um café para o desenvolvedor ☕"},
    "break_reminder": {"en":"Break Reminder","ko":"휴식 알림","ja":"休憩リマインダー","zh":"休息提醒","es":"Recordatorio de descanso","de":"Pausenerinnerung","fr":"Rappel de pause","pt":"Lembrete de pausa"},
    "welcome": {"en":"Welcome to TurtleNeck","ko":"TurtleNeck에 오신 것을 환영합니다","ja":"TurtleNeckへようこそ","zh":"欢迎使用TurtleNeck","es":"Bienvenido a TurtleNeck","de":"Willkommen bei TurtleNeck","fr":"Bienvenue sur TurtleNeck","pt":"Bem-vindo ao TurtleNeck"},
    "next": {"en":"Next","ko":"다음","ja":"次へ","zh":"下一步","es":"Siguiente","de":"Weiter","fr":"Suivant","pt":"Próximo"},
    "back": {"en":"Back","ko":"뒤로","ja":"戻る","zh":"返回","es":"Atrás","de":"Zurück","fr":"Retour","pt":"Voltar"},
    "get_started": {"en":"Get Started","ko":"시작하기","ja":"始める","zh":"开始使用","es":"Comenzar","de":"Los geht's","fr":"Commencer","pt":"Começar"},
}

_current_lang = "en"

def set_language(lang: str):
    global _current_lang
    _current_lang = lang if lang in LANGUAGES else "en"

def t(key: str) -> str:
    return _S.get(key, {}).get(_current_lang, _S.get(key, {}).get("en", key))
