String getWebHtmlContent() {
  return r'''<!DOCTYPE html>
<html class="dark" lang="tr">
<head>
<meta charset="utf-8"/>
<meta content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover" name="viewport"/>
<meta name="apple-mobile-web-app-capable" content="yes">
<title>Phone Desk</title>
<script src="https://cdn.tailwindcss.com?plugins=forms,container-queries"></script>
<link href="https://fonts.googleapis.com/css2?family=Geist:wght@400;600;700&family=Inter:wght@400&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/icon?family=Material+Icons+Round" rel="stylesheet">
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&display=swap" rel="stylesheet"/>
<script>
tailwind.config = {
  darkMode: "class",
  theme: {
    extend: {
      colors: {
        "surface-container": "#18103A",
        "on-surface-variant": "#AFA7D6",
        "surface": "#070414",
        "surface-variant": "#2C1E5C",
        "on-surface": "#E8E6FC",
        "primary-container": "#00F0FF",
        "primary": "#D0FBFF",
        "secondary-container": "#B517FF",
        "secondary": "#F1D4FF",
        "tertiary-container": "#00FA64",
        "tertiary": "#D4FFEA",
        "error-container": "#7A0019",
        "error": "#FF2A54",
        "background": "#070414",
        "outline": "#6C5A9C",
        "outline-variant": "#3A2D65",
      }
    }
  }
}
</script>
<style>
  body {
      background-color: #070414;
      color: theme('colors.on-surface');
      user-select: none;
      -webkit-user-select: none;
      -webkit-tap-highlight-color: transparent;
      touch-action: pan-x pan-y;
      overscroll-behavior: none;
  }
  .deck-container {
      background-color: #0F0B24;
      border: 1px solid #3A2D65;
  }
  .control-tile {
      background-color: #18103A;
      background-image: linear-gradient(to bottom, rgba(255, 255, 255, 0.05) 0%, rgba(255, 255, 255, 0) 100%);
      border: 1px solid #3A2D65;
      transition: all 150ms ease-in-out;
      position: relative;
      overflow: hidden;
  }
  .fullscreen-override {
      position: fixed !important;
      top: 0 !important;
      left: 0 !important;
      width: 100vw !important;
      height: 100vh !important;
      z-index: 99999 !important;
      margin: 0 !important;
      border-radius: 0 !important;
      border: none !important;
      background-color: black !important;
  }
  .control-tile:active {
      transform: translateY(2px) scale(0.96);
      filter: brightness(0.9);
  }
  .control-tile.active-primary {
      border: 2px solid theme('colors.primary');
      box-shadow: 0px 0px 12px rgba(219, 252, 255, 0.4);
      background-image: linear-gradient(to bottom, rgba(219, 252, 255, 0.1) 0%, rgba(219, 252, 255, 0) 100%);
  }
  .control-tile.active-tertiary {
      border: 2px solid theme('colors.tertiary');
      box-shadow: 0px 0px 12px rgba(219, 255, 215, 0.4);
      background-image: linear-gradient(to bottom, rgba(219, 255, 215, 0.1) 0%, rgba(219, 255, 215, 0) 100%);
  }
  .status-pulse { animation: pulse-red 2s infinite; }
  @keyframes pulse-red {
      0% { transform: scale(0.95); box-shadow: 0 0 0 0 rgba(255, 180, 171, 0.7); }
      70% { transform: scale(1); box-shadow: 0 0 0 6px rgba(255, 180, 171, 0); }
      100% { transform: scale(0.95); box-shadow: 0 0 0 0 rgba(255, 180, 171, 0); }
  }
  .safe-pb { padding-bottom: env(safe-area-inset-bottom, 20px); }

  /* File Manager Styles */
  .file-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(140px, 1fr)); gap: 16px; }
  .file-card {
      background: #18103A; border: 1px solid #3A2D65; border-radius: 12px;
      padding: 16px; display: flex; flex-direction: column; align-items: center; 
      text-decoration: none; cursor: pointer; position: relative; overflow: hidden;
  }
  .file-card:hover { background: #2C1E5C; border-color: theme('colors.primary-container'); }
  .file-icon-large {
      width: 60px; height: 60px; border-radius: 16px; display: flex; align-items: center; justify-content: center;
      margin-bottom: 12px; color: white; font-size: 24px; font-weight: bold;
  }
  .file-name { font-size: 13px; font-weight: 500; text-align: center; color: #e5e2e3; width: 100%; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
  .file-size { font-size: 11px; color: #849495; margin-top: 4px; }
  
  /* Ripple */
  .ripple {
      position: absolute; border-radius: 50%; background: rgba(255,255,255,0.3);
      animation: rippleAnim 0.6s ease-out forwards; pointer-events: none;
  }
  @keyframes rippleAnim {
      from { width: 0; height: 0; opacity: 0.5; }
      to { width: 200px; height: 200px; opacity: 0; margin-left: -100px; margin-top: -100px; }
  }

  /* Deck Status Popup */
  .deck-status {
      position: fixed; top: 20px; left: 50%; transform: translateX(-50%);
      padding: 10px 24px; border-radius: 16px; font-size: 14px; font-weight: 600;
      z-index: 200; animation: slideDown 0.3s ease, fadeOut 0.3s ease 1.5s forwards;
      box-shadow: 0 8px 32px rgba(0,0,0,0.4); backdrop-filter: blur(12px);
  }
  .deck-status.success { background: rgba(34,197,94,0.9); color: white; }
  .deck-status.error { background: rgba(239,68,68,0.9); color: white; }
  @keyframes slideDown { from { transform: translateX(-50%) translateY(-20px); opacity: 0; } to { transform: translateX(-50%) translateY(0); opacity: 1; } }
  @keyframes fadeOut { to { opacity: 0; transform: translateX(-50%) translateY(-10px); } }

  input[type="file"] { display: none; }
</style>
</head>
<body class="flex flex-col h-[100dvh] overflow-hidden bg-background">

<!-- Login View -->
<div id="login-view" class="flex flex-col items-center justify-center h-full px-4 w-full">
    <div class="deck-container p-8 rounded-2xl w-full max-w-sm text-center">
        <span class="material-symbols-outlined text-primary text-5xl mb-4">lock</span>
        <h2 class="text-xl font-bold mb-6 text-on-surface">Güvenlik Parolası</h2>
        <input type="password" id="pwd" placeholder="PC'deki Parolayı Girin" class="w-full bg-surface border border-outline-variant rounded-lg p-3 text-on-surface mb-4 focus:border-primary focus:ring-1 focus:ring-primary outline-none" onkeypress="if(event.key === 'Enter') login()">
        <button onclick="login()" class="w-full bg-primary/10 text-primary border border-primary/30 rounded-lg p-3 font-semibold hover:bg-primary/20 transition-colors">Bağlan</button>
        <div id="login-err" class="text-error text-sm mt-4 hidden">Parola hatalı</div>
    </div>
</div>

<!-- App View -->
<div id="app-view" class="hidden h-full flex-col w-full relative">
    <!-- TopAppBar -->
    <header class="bg-surface border-b border-outline-variant flex justify-between items-center px-4 h-16 shrink-0 z-10">
        <div class="font-bold text-primary tracking-tighter text-lg">PHONE DESK</div>
        <div class="flex items-center gap-3">
            <div class="w-2 h-2 rounded-full bg-error status-pulse"></div>
            <span id="subtitle" class="text-xs text-error font-bold tracking-widest">LIVE</span>
        </div>
    </header>

    <main class="flex-1 overflow-y-auto relative pb-28 p-4 w-full h-full">
        <div class="max-w-4xl mx-auto w-full h-full">
            <!-- FILES SECTION -->
            <div id="files-section" class="hidden w-full">
                <div class="deck-container p-4 rounded-xl mb-6 text-center">
                    <label class="bg-primary/10 text-primary border border-primary/30 rounded-lg p-3 font-semibold hover:bg-primary/20 transition-colors inline-flex items-center gap-2 cursor-pointer">
                        <span class="material-symbols-outlined">upload</span>
                        Şu Anki Klasöre Gönder
                        <input type="file" id="filePicker" multiple>
                    </label>
                    <div id="upload-status" class="text-outline text-sm mt-3 h-5"></div>
                </div>
                
                <div class="deck-container p-4 rounded-xl">
                    <div id="pathBar" class="flex items-center gap-2 mb-4 overflow-x-auto text-sm text-on-surface-variant pb-2 border-b border-outline-variant whitespace-nowrap"></div>
                    <div id="fileList" class="file-grid"></div>
                </div>
            </div>

            <!-- DECK SECTION -->
            <div id="deck-section" class="block w-full">
                <!-- Profile Selector -->
                <div id="deckProfiles" class="flex gap-2 overflow-x-auto pb-4 mb-4" style="scrollbar-width: none;"></div>
                
                <!-- Deck Grid Container -->
                <div class="deck-container p-4 rounded-xl shadow-2xl flex flex-col items-center justify-center min-h-[250px] w-full">
                    <div id="deckGrid" class="grid grid-cols-3 sm:grid-cols-4 md:grid-cols-5 gap-3 w-full"></div>
                </div>
            </div>

            <!-- TOUCHPAD SECTION -->
            <div id="touchpad-section" class="hidden w-full h-full flex-col landscape:flex-row landscape:gap-4">
                <div id="touchpad-area" class="flex-1 rounded-2xl mb-4 landscape:mb-2 border-2 border-outline-variant bg-surface-container-lowest relative overflow-hidden flex flex-col items-center justify-center touch-none shadow-inner" style="box-shadow: inset 0 0 20px rgba(0,0,0,0.5);">
                    <span class="material-symbols-outlined text-outline-variant text-6xl opacity-20 pointer-events-none mb-2">touchpad_mouse</span>
                    <span class="text-outline-variant opacity-30 text-xs font-semibold uppercase tracking-wider">Fare Kontrolü</span>
                </div>
                
                <div class="flex flex-col gap-4 mb-2 landscape:mb-2 landscape:w-[320px] landscape:justify-end">
                    <div class="flex gap-4 h-14 shrink-0">
                        <button id="tp-left" class="flex-1 bg-surface-container rounded-xl border border-outline-variant active:bg-primary/20 active:border-primary text-on-surface-variant font-bold text-sm shadow-lg flex items-center justify-center">SOL TIK</button>
                        <button id="tp-right" class="flex-1 bg-surface-container rounded-xl border border-outline-variant active:bg-primary/20 active:border-primary text-on-surface-variant font-bold text-sm shadow-lg flex items-center justify-center">SAĞ TIK</button>
                    </div>
                    
                    <!-- Klavye Alanı -->
                    <div class="flex gap-2 h-14 shrink-0">
                        <input type="text" id="kb-input" placeholder="PC'ye metin gönder..." class="flex-1 min-w-0 bg-surface-container rounded-xl border border-outline-variant px-4 text-sm text-on-surface focus:outline-none focus:border-primary">
                        <button id="kb-send" class="bg-primary text-background px-4 rounded-xl flex items-center justify-center shadow-lg active:scale-95 transition-transform"><span class="material-symbols-outlined">send</span></button>
                        <button id="kb-enter" class="bg-surface-container border border-outline-variant text-on-surface px-4 rounded-xl flex items-center justify-center active:bg-white/10 transition-colors"><span class="material-symbols-outlined">keyboard_return</span></button>
                    </div>
                </div>
            </div>

            <!-- SCREEN SECTION -->
            <div id="screen-section" class="hidden w-full h-full flex-col">
                <div class="flex justify-between items-center mb-2 shrink-0">
                    <span class="text-on-surface font-bold text-sm">Akıcılık (FPS)</span>
                    <div class="flex gap-1 bg-surface-container rounded-lg p-1 items-center">
                        <button onclick="setFps(15)" id="fps-15" class="fps-btn px-3 py-1 rounded-md text-xs font-bold bg-primary text-background">15</button>
                        <button onclick="setFps(30)" id="fps-30" class="fps-btn px-3 py-1 rounded-md text-xs font-bold text-on-surface-variant hover:text-on-surface bg-transparent">30</button>
                        <button onclick="setFps(45)" id="fps-45" class="fps-btn px-3 py-1 rounded-md text-xs font-bold text-on-surface-variant hover:text-on-surface bg-transparent">45</button>
                        <button onclick="setFps(60)" id="fps-60" class="fps-btn px-3 py-1 rounded-md text-xs font-bold text-on-surface-variant hover:text-on-surface bg-transparent">60</button>
                    </div>
                </div>
                <div class="flex justify-between items-center mb-4 shrink-0">
                    <span class="text-on-surface font-bold text-sm">Kalite (Res)</span>
                    <div class="flex gap-1 bg-surface-container rounded-lg p-1 items-center">
                        <button onclick="setRes(480)" id="res-480" class="res-btn px-2 py-1 rounded-md text-xs font-bold text-on-surface-variant hover:text-on-surface bg-transparent">480p</button>
                        <button onclick="setRes(720)" id="res-720" class="res-btn px-2 py-1 rounded-md text-xs font-bold text-on-surface-variant hover:text-on-surface bg-transparent">720p</button>
                        <button onclick="setRes(1080)" id="res-1080" class="res-btn px-2 py-1 rounded-md text-xs font-bold bg-primary text-background">1080p</button>
                        <div class="w-px h-4 bg-outline-variant mx-1"></div>
                        <button onclick="toggleFullscreen()" class="p-1 rounded-md text-on-surface-variant hover:text-on-surface hover:bg-white/5 flex items-center justify-center">
                            <span class="material-symbols-outlined text-[20px]">fullscreen</span>
                        </button>
                    </div>
                </div>
                <div id="screen-container" class="flex-1 bg-black rounded-2xl overflow-hidden relative border-2 border-outline-variant flex items-center justify-center mb-2">
                    <img id="screen-img" src="" class="w-full h-full object-contain pointer-events-none" />
                    <div id="screen-overlay" class="absolute inset-0 z-10 w-full h-full touch-none"></div>
                    <button id="exit-fs-btn" onclick="toggleFullscreen()" class="hidden absolute top-4 right-4 z-50 bg-black/50 text-white rounded-full p-2 border border-white/20 backdrop-blur-md shadow-lg">
                        <span class="material-symbols-outlined">fullscreen_exit</span>
                    </button>
                </div>
            </div>
        </div>
    </main>

    <!-- BottomNavBar -->
    <nav class="bg-surface-container-lowest absolute bottom-0 w-full z-50 flex justify-around items-center h-20 safe-pb px-2 border-t border-outline-variant shadow-[0_-4px_16px_rgba(0,0,0,0.5)]">
        <button onclick="switchTab('files')" id="tab-files" class="flex flex-col items-center justify-center text-on-surface-variant w-1/4">
            <span class="material-symbols-outlined mb-1 text-2xl">folder</span>
            <span class="text-[10px]">Dosyalar</span>
        </button>
        <button onclick="switchTab('touchpad')" id="tab-touchpad" class="flex flex-col items-center justify-center text-on-surface-variant w-1/4">
            <span class="material-symbols-outlined mb-1 text-2xl">touchpad_mouse</span>
            <span class="text-[10px]">Touchpad</span>
        </button>
        <button onclick="switchTab('screen')" id="tab-screen" class="flex flex-col items-center justify-center text-on-surface-variant w-1/4">
            <span class="material-symbols-outlined mb-1 text-2xl">desktop_windows</span>
            <span class="text-[10px]">Ekran</span>
        </button>
        <button onclick="switchTab('deck')" id="tab-deck" class="flex flex-col items-center justify-center text-primary bg-secondary-container/20 border border-primary/30 rounded-full py-1 w-1/4">
            <span class="material-symbols-outlined mb-1 text-2xl" style="font-variation-settings: 'FILL' 1;">grid_view</span>
            <span class="text-[10px] font-bold">Deck</span>
        </button>
    </nav>
</div>

<script>
  let password = localStorage.getItem('pl_pwd') || '';
  let currentDir = '';
  let currentAppTab = 'deck';
  let deckProfiles = [];
  let deckButtons = [];
  let activeDeckProfile = '';

  const iconMap = {
    'touch_app':'touch_app','keyboard':'keyboard','launch':'launch','play_circle':'play_circle',
    'volume_up':'volume_up','volume_down':'volume_down','volume_off':'volume_off',
    'terminal':'terminal','folder_open':'folder_open','text_fields':'text_fields',
    'link':'link','music_note':'music_note','videocam':'videocam','mic':'mic',
    'screenshot':'screenshot','screen_share':'screen_share','cast':'cast',
    'gamepad':'gamepad','sports_esports':'sports_esports','headset':'headset',
    'speaker':'speaker','camera':'camera','brush':'brush','code':'code',
    'bug_report':'bug_report','build':'build','settings':'settings',
    'power_settings_new':'power_settings_new','lock':'lock','brightness_6':'brightness_6',
    'wifi':'wifi','bluetooth':'bluetooth','notifications':'notifications',
    'email':'email','chat':'chat','call':'call','sms':'sms',
    'shopping_cart':'shopping_cart','favorite':'favorite','star':'star',
    'bookmark':'bookmark','flag':'flag','home':'home','search':'search',
    'add':'add','remove':'remove','delete':'delete','save':'save',
    'share':'share','download':'download','upload':'upload','cloud':'cloud',
    'monitor':'monitor','desktop_windows':'desktop_windows','web':'web','refresh':'refresh',
    'content_copy':'content_copy','content_paste':'content_paste',
    'undo':'undo','redo':'redo','skip_next':'skip_next','skip_previous':'skip_previous',
    'dashboard':'dashboard','work':'work','fullscreen':'fullscreen',
    'select_all':'select_all','print':'print','swap_horiz':'swap_horiz',
    'stop':'stop','pause':'pause','fast_forward':'fast_forward','fast_rewind':'fast_rewind'
  };

  function getMaterialIcon(name) { return iconMap[name] || 'touch_app'; }

  function switchTab(tab) {
    currentAppTab = tab;
    ['files', 'deck', 'touchpad', 'screen'].forEach(t => {
      document.getElementById(`${t}-section`).classList.add('hidden');
      document.getElementById(`${t}-section`).classList.remove('block', 'flex');
      document.getElementById(`tab-${t}`).classList.remove('text-primary', 'bg-secondary-container/20', 'border', 'border-primary/30', 'rounded-full', 'py-1', 'font-bold');
      document.getElementById(`tab-${t}`).classList.add('text-on-surface-variant');
      document.getElementById(`tab-${t}`).querySelector('span:first-child').style.fontVariationSettings = "'FILL' 0";
      document.getElementById(`tab-${t}`).querySelector('span:last-child').classList.remove('font-bold');
    });
    
    const activeSec = document.getElementById(`${tab}-section`);
    activeSec.classList.remove('hidden');
    activeSec.classList.add((tab === 'touchpad' || tab === 'screen') ? 'flex' : 'block');
    
    const activeBtn = document.getElementById('tab-' + tab);
    activeBtn.classList.remove('text-on-surface-variant');
    activeBtn.classList.add('text-primary', 'bg-secondary-container/20', 'border', 'border-primary/30', 'rounded-full', 'py-1');
    activeBtn.querySelector('span:first-child').style.fontVariationSettings = "'FILL' 1";
    activeBtn.querySelector('span:last-child').classList.add('font-bold');

    if (tab === 'files') loadDirectory();
    if (tab === 'deck') loadDeck();
    if (tab === 'screen') startStream(); else stopStream();
  }

  // --- Deck Functions ---
  async function loadDeck() {
    try {
      const res = await api('/deck/profiles');
      const data = await res.json();
      deckProfiles = data.profiles || [];
      activeDeckProfile = data.activeProfileId || '';
      renderDeckProfiles();
      await loadDeckButtons(activeDeckProfile);
    } catch(e) {}
  }

  function renderDeckProfiles() {
    const container = document.getElementById('deckProfiles');
    if (!deckProfiles.length) { container.innerHTML = ''; return; }
    
    container.innerHTML = deckProfiles.map(p => {
      const isActive = p.id === activeDeckProfile;
      const cClass = isActive 
        ? 'bg-primary/20 text-primary border-primary/50 font-bold shadow-[0_0_10px_rgba(0,240,255,0.2)]' 
        : 'bg-surface-container text-outline border-outline-variant hover:text-on-surface';
      return `
        <button class="flex items-center gap-2 px-4 py-2 rounded-full border ${cClass} whitespace-nowrap transition-all" onclick="selectProfile('${p.id}')">
          <span class="material-symbols-outlined text-sm">${getMaterialIcon(p.iconName)}</span>
          <span class="text-sm">${p.name}</span>
        </button>
      `;
    }).join('');
  }

  async function selectProfile(profileId) {
    activeDeckProfile = profileId;
    try {
      await api('/deck/set-profile', { method: 'POST', headers: {'Content-Type': 'application/json'}, body: JSON.stringify({profileId}) });
    } catch(e) {}
    renderDeckProfiles();
    await loadDeckButtons(profileId);
  }

  async function loadDeckButtons(profileId) {
    try {
      const res = await api(`/deck/buttons?profile=${encodeURIComponent(profileId)}`);
      deckButtons = await res.json();
      renderDeckButtons();
    } catch(e) {}
  }

  function renderDeckButtons() {
    const grid = document.getElementById('deckGrid');
    if (!deckButtons.length) {
      grid.innerHTML = `<div class="col-span-full text-center py-10 text-outline"><span class="material-symbols-outlined text-4xl mb-2">dashboard_customize</span><p>Henüz buton yok</p></div>`;
      return;
    }

    grid.innerHTML = deckButtons.map((btn, i) => {
      const hexColor = btn.color ? (btn.color.startsWith('#') ? btn.color : '#' + btn.color) : '#E8E6FC';
      return `
        <button class="control-tile rounded-lg aspect-square flex flex-col items-center justify-center gap-1.5 sm:gap-2 relative" 
                style="border-color: ${hexColor}40; box-shadow: 0 4px 12px ${hexColor}15; background-image: linear-gradient(to bottom, ${hexColor}10 0%, transparent 100%);"
                onclick="executeDeckBtn(${i}, event)">
          <span class="material-symbols-outlined text-3xl sm:text-4xl" style="color: ${hexColor}; text-shadow: 0 0 10px ${hexColor}50;">${getMaterialIcon(btn.iconName)}</span>
          <span class="text-[9px] sm:text-[10px] font-bold leading-tight text-center px-1 break-words line-clamp-2 w-full" style="color: ${hexColor};">${btn.label.toUpperCase()}</span>
        </button>
      `;
    }).join('');
  }

  async function executeDeckBtn(index, event) {
    const btn = deckButtons[index];
    if (!btn) return;
    
    const target = event.currentTarget;
    const rect = target.getBoundingClientRect();
    const ripple = document.createElement('div');
    ripple.className = 'ripple';
    ripple.style.left = (event.clientX || event.touches?.[0]?.clientX || rect.width/2) - rect.left + 'px';
    ripple.style.top = (event.clientY || event.touches?.[0]?.clientY || rect.height/2) - rect.top + 'px';
    target.appendChild(ripple);
    setTimeout(() => ripple.remove(), 600);

    if (navigator.vibrate) navigator.vibrate(30);

    try {
      const res = await api('/deck/execute', { method: 'POST', headers: {'Content-Type': 'application/json'}, body: JSON.stringify(btn) });
      showDeckStatus(res.ok ? `${btn.label} ✓` : `${btn.label} başarısız`, res.ok);
    } catch(e) { showDeckStatus(`${btn.label} hata!`, false); }
  }

  function showDeckStatus(msg, success) {
    const el = document.createElement('div');
    el.className = `deck-status ${success ? 'success' : 'error'}`;
    el.textContent = msg;
    document.body.appendChild(el);
    setTimeout(() => el.remove(), 2000);
  }

  // --- API & Auth ---
  async function api(path, options = {}) {
    const url = new URL(path, window.location.origin);
    url.searchParams.append('pwd', password);
    const res = await fetch(url, options);
    if (res.status === 401) {
      document.getElementById('app-view').classList.add('hidden');
      document.getElementById('app-view').classList.remove('flex');
      document.getElementById('login-view').classList.remove('hidden');
      document.getElementById('login-view').classList.add('flex');
      throw new Error('Unauthorized');
    }
    return res;
  }

  function showApp() {
    document.getElementById('login-view').classList.add('hidden');
    document.getElementById('login-view').classList.remove('flex');
    document.getElementById('app-view').classList.remove('hidden');
    document.getElementById('app-view').classList.add('flex');
    reportDevice();
    loadDirectory();
    if(currentAppTab === 'deck') loadDeck();
  }

  async function login() {
    password = document.getElementById('pwd').value;
    try {
      await api('/directories');
      localStorage.setItem('pl_pwd', password);
      document.getElementById('login-err').classList.add('hidden');
      showApp();
    } catch (e) {
      document.getElementById('login-err').classList.remove('hidden');
    }
  }
  
  function reportDevice() { api('/connect', { method: 'POST', body: JSON.stringify({ device: 'Mobile', battery: '100%', os: 'Web' }) }).catch(()=>{}); }

  api('/directories').then(() => showApp()).catch(() => {});

  // --- Files Logic ---
  document.getElementById('filePicker').addEventListener('change', async (e) => {
    const files = e.target.files;
    if (files.length === 0) return;
    if (currentDir === '') { alert('Lütfen klasör seçin'); return; }
    const status = document.getElementById('upload-status');
    let successCount = 0;
    
    for (let i=0; i<files.length; i++) {
      status.innerText = `Yükleniyor: ${files[i].name}`;
      try {
        const res = await api(`/upload?dir=${encodeURIComponent(currentDir)}&name=${encodeURIComponent(files[i].name)}`, { method: 'POST', body: files[i] });
        if (res.ok) successCount++;
      } catch(err) {}
    }
    status.innerText = successCount > 0 ? `${successCount} dosya aktarıldı!` : 'Aktarım başarısız.';
    document.getElementById('filePicker').value = '';
    setTimeout(() => { status.innerText = ''; }, 3000);
    loadDirectory();
  });

  function renderPathBar() {
    const bar = document.getElementById('pathBar');
    if (currentDir === '') {
      bar.innerHTML = `<span class="font-bold text-primary cursor-pointer">🏠 PC Klasörleri</span>`;
      return;
    }
    let parts = currentDir.split('/');
    let html = `<span class="cursor-pointer hover:text-primary" onclick="navTo('')">🏠</span>`;
    let currentPath = '';
    for (let i = 0; i < parts.length; i++) {
       html += ` <span class="text-outline">/</span> `;
       currentPath += (i === 0 ? '' : '/') + parts[i];
       const isLast = i === parts.length - 1;
       if (isLast) html += `<span class="text-primary font-bold">${parts[i]}</span>`;
       else html += `<span class="cursor-pointer hover:text-primary" onclick="navTo('${currentPath}')">${parts[i]}</span>`;
    }
    bar.innerHTML = html;
  }

  function navTo(path) { currentDir = path; loadDirectory(); }
  function upDir() { if (currentDir === '') return; let parts = currentDir.split('/'); parts.pop(); currentDir = parts.join('/'); loadDirectory(); }
  
  function getFileIcon(filename) {
    const ext = filename.split('.').pop().toLowerCase();
    if(['exe', 'msi'].includes(ext)) return { bg: 'bg-error/20 text-error', icon: 'EXE' };
    if(['apk'].includes(ext)) return { bg: 'bg-tertiary/20 text-tertiary', icon: 'APK' };
    if(['jpg','jpeg','png','gif','webp'].includes(ext)) return { bg: 'bg-secondary/20 text-secondary', icon: 'IMG' };
    if(['mp4','mov','avi','mkv'].includes(ext)) return { bg: 'bg-secondary-container/20 text-secondary-container', icon: 'VID' };
    if(['mp3','wav','ogg'].includes(ext)) return { bg: 'bg-tertiary-container/20 text-tertiary-container', icon: 'MUS' };
    if(['zip','rar','7z'].includes(ext)) return { bg: 'bg-outline/20 text-outline', icon: 'ZIP' };
    return { bg: 'bg-primary/20 text-primary', icon: 'FILE' };
  }
  function formatSize(bytes) {
    if(!bytes) return '';
    const k = 1024, sizes = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
  }

  async function loadDirectory() {
    renderPathBar();
    try {
      const url = currentDir === '' ? '/directories' : `/files?dir=${encodeURIComponent(currentDir)}`;
      const res = await api(url);
      const items = await res.json();
      
      const list = document.getElementById('fileList');
      if (items.length === 0) { 
        list.innerHTML = `<div class="col-span-full text-center text-outline py-8">Klasör boş</div>`; 
      } else {
        let html = '';
        if (currentDir !== '') {
           html += `<div class="file-card" onclick="upDir()"><div class="file-icon-large bg-surface-container text-outline">↰</div><div class="file-name">Geri</div></div>`;
        }
        items.forEach(f => {
          if (currentDir === '') {
            html += `<div class="file-card" onclick="navTo('${f.name}')"><div class="file-icon-large bg-tertiary/20 text-tertiary text-4xl">📁</div><div class="file-name">${f.name}</div></div>`;
          } else {
            if (f.isDir) {
               html += `<div class="file-card" onclick="navTo('${currentDir}/${f.name}')"><div class="file-icon-large bg-tertiary/20 text-tertiary text-4xl">📁</div><div class="file-name">${f.name}</div></div>`;
            } else {
               const isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp'].includes(f.name.split('.').pop().toLowerCase());
               const style = getFileIcon(f.name);
               const fileUrl = `/download/${encodeURIComponent(f.name)}?pwd=${encodeURIComponent(password)}&dir=${encodeURIComponent(currentDir)}`;
               const preview = isImage ? `<img src="${fileUrl}" class="w-full h-full object-cover rounded-xl">` : `<span class="text-sm font-bold">${style.icon}</span>`;
      
               html += `
               <a class="file-card" href="${fileUrl}" download>
                 <div class="file-icon-large ${style.bg}">${preview}</div>
                 <div class="file-name">${f.name}</div>
                 <div class="file-size">${formatSize(f.size)}</div>
               </a>
               `;
            }
          }
        });
        list.innerHTML = html;
      }
    } catch(e) {}
  }
  
  setInterval(() => {
    if(document.getElementById('app-view').classList.contains('flex') && currentAppTab === 'files') loadDirectory();
  }, 3500);

  // --- Zoom Prevention ---
  document.addEventListener('gesturestart', function(e) { e.preventDefault(); });
  document.addEventListener('dblclick', function(e) { e.preventDefault(); }, { passive: false });

  // --- Touchpad Logic ---
  const tpArea = document.getElementById('touchpad-area');
  let lastX = 0, lastY = 0, isDragging = false, touchStartTime = 0, hasMoved = false;

  tpArea.addEventListener('touchstart', (e) => {
    e.preventDefault();
    if(e.touches.length === 1) {
      lastX = e.touches[0].clientX;
      lastY = e.touches[0].clientY;
      isDragging = true;
      hasMoved = false;
      touchStartTime = Date.now();
    } else if (e.touches.length === 2) {
      lastY = e.touches[0].clientY;
      isDragging = false;
      hasMoved = true;
    }
  }, {passive: false});

  tpArea.addEventListener('touchmove', (e) => {
    e.preventDefault();
    if(e.touches.length === 1 && isDragging) {
      const currentX = e.touches[0].clientX;
      const currentY = e.touches[0].clientY;
      const dx = Math.round((currentX - lastX) * 1.5); // 1.5x sensitivity
      const dy = Math.round((currentY - lastY) * 1.5);
      
      if(Math.abs(dx) > 0 || Math.abs(dy) > 0) {
        hasMoved = true;
        api('/mouse', { method: 'POST', body: JSON.stringify({ action: 'move', dx: dx, dy: dy }) }).catch(()=>{});
        lastX = currentX;
        lastY = currentY;
      }
    } else if(e.touches.length === 2) {
      const currentY = e.touches[0].clientY;
      const dy = Math.round(currentY - lastY);
      if(Math.abs(dy) > 0) {
        api('/mouse', { method: 'POST', body: JSON.stringify({ action: 'scroll', dy: dy * 2 }) }).catch(()=>{});
        lastY = currentY;
      }
    }
  }, {passive: false});

  tpArea.addEventListener('touchend', (e) => {
    e.preventDefault();
    isDragging = false;
    if(!hasMoved && (Date.now() - touchStartTime < 250)) {
      api('/mouse', { method: 'POST', body: JSON.stringify({ action: 'left_click' }) }).catch(()=>{});
    }
  });

  document.getElementById('tp-left').addEventListener('click', () => {
    api('/mouse', { method: 'POST', body: JSON.stringify({ action: 'left_click' }) }).catch(()=>{});
    if (navigator.vibrate) navigator.vibrate(20);
  });
  
  document.getElementById('tp-right').addEventListener('click', () => {
    api('/mouse', { method: 'POST', body: JSON.stringify({ action: 'right_click' }) }).catch(()=>{});
    if (navigator.vibrate) navigator.vibrate(30);
  });

  // --- Keyboard Logic ---
  function sendToPC(actionType, actionData) {
    const payload = { id: 'temp', label: 'temp', iconName: 'touch_app', color: '000000', actionType: actionType, actionData: actionData };
    api('/deck/execute', { method: 'POST', headers: {'Content-Type': 'application/json'}, body: JSON.stringify(payload) }).catch(()=>{});
    if (navigator.vibrate) navigator.vibrate(20);
  }

  document.getElementById('kb-send').addEventListener('click', () => {
    const input = document.getElementById('kb-input');
    if (input.value.trim() !== '') {
      sendToPC('text', input.value);
      input.value = '';
    }
  });

  document.getElementById('kb-enter').addEventListener('click', () => {
    sendToPC('hotkey', 'enter');
  });

  document.getElementById('kb-input').addEventListener('keypress', (e) => {
    if (e.key === 'Enter') {
      e.preventDefault();
      document.getElementById('kb-send').click();
      setTimeout(() => sendToPC('hotkey', 'enter'), 150); // Optional: also press enter on PC
    }
  });

  // --- Screen Stream Logic ---
  let streamFps = 15;
  let streamRes = 1080;
  let isStreaming = false;

  function setFps(fps) {
    streamFps = fps;
    document.querySelectorAll('.fps-btn').forEach(btn => {
      btn.classList.replace('bg-primary', 'bg-transparent');
      btn.classList.replace('text-background', 'text-on-surface-variant');
      btn.classList.add('hover:text-on-surface');
    });
    const active = document.getElementById('fps-'+fps);
    active.classList.remove('hover:text-on-surface');
    active.classList.replace('bg-transparent', 'bg-primary');
    active.classList.replace('text-on-surface-variant', 'text-background');
    if (isStreaming) {
       startStream();
    }
  }

  function setRes(res) {
    streamRes = res;
    document.querySelectorAll('.res-btn').forEach(btn => {
      btn.classList.replace('bg-primary', 'bg-transparent');
      btn.classList.replace('text-background', 'text-on-surface-variant');
      btn.classList.add('hover:text-on-surface');
    });
    const active = document.getElementById('res-'+res);
    active.classList.remove('hover:text-on-surface');
    active.classList.replace('bg-transparent', 'bg-primary');
    active.classList.replace('text-on-surface-variant', 'text-background');
    if (isStreaming) {
       startStream();
    }
  }

  function startStream() {
    isStreaming = true;
    const img = document.getElementById('screen-img');
    // For MJPEG, we only need to set the source once! The browser handles the rest.
    img.src = '/screen/frame?fps=' + streamFps + '&res=' + streamRes + '&pwd=' + encodeURIComponent(password) + '&t=' + new Date().getTime();
    
    // If the connection drops or fails initially, retry after 2 seconds
    img.onerror = () => {
        if (isStreaming) {
            setTimeout(startStream, 2000);
        }
    };
  }

  function stopStream() {
    isStreaming = false;
    api('/screen/stop', { method: 'POST' }).catch(()=>{});
  }

  function toggleFullscreen() {
    const container = document.getElementById('screen-container');
    const exitBtn = document.getElementById('exit-fs-btn');
    
    // Check if we are using the Native Fullscreen API
    if (document.fullscreenElement || document.webkitFullscreenElement || document.mozFullScreenElement || document.msFullscreenElement) {
        if (document.exitFullscreen) {
            document.exitFullscreen();
        } else if (document.webkitExitFullscreen) {
            document.webkitExitFullscreen();
        } else if (document.mozCancelFullScreen) {
            document.mozCancelFullScreen();
        } else if (document.msExitFullscreen) {
            document.msExitFullscreen();
        }
        container.classList.remove('fullscreen-override');
        exitBtn.classList.add('hidden');
    } else if (container.classList.contains('fullscreen-override')) {
        // We were using CSS override, disable it
        container.classList.remove('fullscreen-override');
        exitBtn.classList.add('hidden');
    } else {
        // Attempt Native Fullscreen
        if (container.requestFullscreen) {
            container.requestFullscreen().catch(err => {
                // Fallback to CSS fullscreen
                container.classList.add('fullscreen-override');
                exitBtn.classList.remove('hidden');
            });
        } else if (container.webkitRequestFullscreen) {
            container.webkitRequestFullscreen();
        } else if (container.msRequestFullscreen) {
            container.msRequestFullscreen();
        } else {
            // Fallback to CSS fullscreen
            container.classList.add('fullscreen-override');
            exitBtn.classList.remove('hidden');
        }
        
        // Show exit button immediately if we are relying on fallback or just to be safe
        exitBtn.classList.remove('hidden');
    }
  }

  // Handle ESC key or native exit to hide the exit button
  document.addEventListener('fullscreenchange', () => {
      if (!document.fullscreenElement) {
          document.getElementById('screen-container').classList.remove('fullscreen-override');
          document.getElementById('exit-fs-btn').classList.add('hidden');
      }
  });

  // Absolute coordinate touch on screen
  const screenOverlay = document.getElementById('screen-overlay');
  screenOverlay.addEventListener('click', (e) => {
    const img = document.getElementById('screen-img');
    const rect = img.getBoundingClientRect();
    const nw = img.naturalWidth;
    const nh = img.naturalHeight;
    if (!nw || !nh) return;
    
    const scale = Math.min(rect.width / nw, rect.height / nh);
    const renderW = nw * scale;
    const renderH = nh * scale;
    
    const offsetX = (rect.width - renderW) / 2;
    const offsetY = (rect.height - renderH) / 2;
    
    const x = e.clientX - rect.left - offsetX;
    const y = e.clientY - rect.top - offsetY;
    
    if (x < 0 || x > renderW || y < 0 || y > renderH) return;
    
    const xPct = x / renderW;
    const yPct = y / renderH;
    
    api('/mouse', { 
        method: 'POST', 
        body: JSON.stringify({ action: 'absolute', x: xPct, y: yPct, click: true }) 
    }).catch(()=>{});
    
    // Show visual indicator at tap location
    const indicator = document.createElement('div');
    indicator.className = 'absolute w-6 h-6 rounded-full border-2 border-primary/80 bg-primary/20 pointer-events-none transform -translate-x-1/2 -translate-y-1/2 animate-ping';
    indicator.style.left = `${e.clientX - rect.left}px`;
    indicator.style.top = `${e.clientY - rect.top}px`;
    screenOverlay.appendChild(indicator);
    setTimeout(() => indicator.remove(), 500);
    
    if (navigator.vibrate) navigator.vibrate(15);
  });
</script>
</body>
</html>''';
}
