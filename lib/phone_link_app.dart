import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'theme.dart';
import 'deck_manager.dart';
import 'deck_panel.dart';
import 'web_ui.dart';
import 'screen_streamer.dart';

class PhoneLinkApp extends StatefulWidget {
  const PhoneLinkApp({super.key});

  @override
  State<PhoneLinkApp> createState() => _PhoneLinkAppState();
}

class _PhoneLinkAppState extends State<PhoneLinkApp> {
  HttpServer? _server;
  String? _ipAddress;
  int _port = 8080;
  bool _isRunning = false;
  String _statusMessage = 'Sunucu başlatılıyor...';
  
  bool _isDragging = false;
  bool _isCompact = false;
  bool _isTopup = false;
  
  final TextEditingController _pwdController = TextEditingController();
  String _savedPassword = '';
  
  Map<String, dynamic>? _connectedDevice;
  List<File> _sharedFiles = [];
  Map<String, String> _fileOrigins = {};
  Timer? _fileWatcher;

  int _currentTab = 0; // 0: Dosyalar, 1: Galeri, 2: Deck
  final DeckManager _deckManager = DeckManager();
  final ScreenStreamer _screenStreamer = ScreenStreamer();

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _initSharedFolder();
    _startServer();
    _deckManager.load().then((_) { if (mounted) setState(() {}); });
    
    // Watch folder for changes to update UI
    _fileWatcher = Timer.periodic(const Duration(seconds: 2), (_) {
      _loadSharedFiles();
    });
  }

  void _initSharedFolder() {
    final dir = Directory(_phoneLinkDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    _loadMetadata();
    _loadSharedFiles();
  }

  void _loadMetadata() {
    final file = File('$_phoneLinkDir${Platform.pathSeparator}.metadata.json');
    if (file.existsSync()) {
      try {
        final content = file.readAsStringSync();
        _fileOrigins = Map<String, String>.from(jsonDecode(content));
      } catch (_) {}
    }
  }

  void _saveMetadata() {
    final file = File('$_phoneLinkDir${Platform.pathSeparator}.metadata.json');
    file.writeAsStringSync(jsonEncode(_fileOrigins));
  }

  void _loadSharedFiles() {
    final dir = Directory(_phoneLinkDir);
    if (dir.existsSync()) {
      final files = dir.listSync().whereType<File>().toList()
        ..sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      
      if (!mounted) return;
      setState(() {
        _sharedFiles = files;
      });
    }
  }

  void _openFile(String path) {
    if (Platform.isWindows) {
      Process.run('explorer', [path]);
    } else if (Platform.isMacOS) {
      Process.run('open', [path]);
    } else if (Platform.isLinux) {
      Process.run('xdg-open', [path]);
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedPassword = prefs.getString('web_password') ?? '';
      _pwdController.text = _savedPassword;
    });
  }


  @override
  void dispose() {
    _fileWatcher?.cancel();
    _server?.close(force: true);
    _screenStreamer.stop();
    _pwdController.dispose();
    super.dispose();
  }

  Future<void> _startServer() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      
      String? ip;
      final validInterfaces = interfaces.where((i) {
        final name = i.name.toLowerCase();
        return !name.contains('veth') && 
               !name.contains('vpn') && 
               !name.contains('virtual') && 
               !name.contains('wsl') &&
               !name.contains('vmware') &&
               !name.contains('hyper-v') &&
               !name.contains('loopback') &&
               !name.contains('tailscale') &&
               !name.contains('zerotier') &&
               !name.contains('hamachi') &&
               !name.contains('openvpn') &&
               !name.contains('wireguard') &&
               !name.contains('tun') &&
               !name.contains('tap') &&
               !name.contains('warp') &&
               !name.contains('radmin') &&
               !name.contains('tunnel');
      }).toList();

      for (var interface in validInterfaces) {
        for (var addr in interface.addresses) {
          if (addr.address.startsWith('192.168.')) {
            ip = addr.address;
            break;
          }
        }
        if (ip != null) break;
      }

      if (ip == null) {
        for (var interface in validInterfaces) {
          for (var addr in interface.addresses) {
            if (addr.address.startsWith('10.') || 
                addr.address.startsWith('172.')) {
              ip = addr.address;
              break;
            }
          }
          if (ip != null) break;
        }
      }
      
      if (ip == null && validInterfaces.isNotEmpty) {
        ip = validInterfaces.first.addresses.first.address;
      }
      
      if (ip == null && interfaces.isNotEmpty) {
         for (var interface in interfaces) {
           for (var addr in interface.addresses) {
             if (!addr.isLoopback) {
               ip = addr.address;
               break;
             }
           }
           if (ip != null) break;
         }
      }

      if (ip == null) {
        setState(() {
          _statusMessage = 'Ağ bağlantısı bulunamadı.\nLütfen ağa bağlanın.';
        });
        return;
      }

      try {
        _server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
      } catch (e) {
        _server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
      }
      
      _port = _server!.port;
      _ipAddress = ip;
      _isRunning = true;
      _statusMessage = 'Sunucu aktif. Telefonunuzdan bağlanabilirsiniz.';
      setState(() {});

      _listenToRequests();
    } catch (e) {
      setState(() {
        _statusMessage = 'Sunucu başlatılamadı: $e';
      });
    }
  }

  String get _home {
    if (Platform.isWindows) return Platform.environment['USERPROFILE'] ?? Directory.current.path;
    return Platform.environment['HOME'] ?? Directory.current.path;
  }

  Map<String, String> get _rootDirs {
    final sep = Platform.pathSeparator;
    return {
      'PhoneLink': '$_home${sep}Downloads${sep}PhoneLink',
      'İndirilenler': '$_home${sep}Downloads',
      'Masaüstü': '$_home${sep}Desktop',
      'Belgeler': '$_home${sep}Documents',
      'Resimler': '$_home${sep}Pictures',
      'Videolar': '$_home${sep}Videos',
    };
  }
  
  String get _phoneLinkDir => _rootDirs['PhoneLink']!;

  String _getRealPath(String virtualPath) {
    if (virtualPath.isEmpty) return '';
    final parts = virtualPath.split('/');
    final rootName = Uri.decodeComponent(parts.first);
    if (!_rootDirs.containsKey(rootName)) return '';
    
    var realPath = _rootDirs[rootName]!;
    if (parts.length > 1) {
      for (int i = 1; i < parts.length; i++) {
         final p = Uri.decodeComponent(parts[i]);
         if (p == '..' || p == '.') continue;
         realPath += '${Platform.pathSeparator}$p';
      }
    }
    return realPath;
  }

  String _sanitizeFileName(String name) {
    return name.split('/').last.split('\\').last;
  }

  bool _isAuthenticated(HttpRequest request) {
    if (_savedPassword.isEmpty) return true;
    final authHeader = request.headers.value('authorization') ?? '';
    final pwd = request.uri.queryParameters['pwd'] ?? '';
    return authHeader == _savedPassword || pwd == _savedPassword;
  }

  Future<void> _listenToRequests() async {
    if (_server == null) return;

    await for (HttpRequest request in _server!) {
      final path = request.uri.path;
      final response = request.response;

      try {
        response.headers.add('Access-Control-Allow-Origin', '*');
        response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
        response.headers.add('Access-Control-Allow-Headers', 'Origin, Content-Type, Accept');

        if (request.method == 'OPTIONS') {
          response.statusCode = 200;
          await response.close();
          continue;
        }

        if (request.method == 'GET' && path == '/') {
          response.headers.contentType = ContentType.html;
          response.write(_getHtmlContent());
          await response.close();
          continue;
        }
        
        if (request.method == 'GET' && path == '/manifest.json') {
          response.headers.contentType = ContentType.json;
          response.write('''{
            "name": "Phone Link",
            "short_name": "PhoneLink",
            "start_url": "/",
            "display": "standalone",
            "background_color": "#0f172a",
            "theme_color": "#0f172a",
            "icons": [{
              "src": "/icon.svg",
              "sizes": "512x512",
              "type": "image/svg+xml",
              "purpose": "any maskable"
            }]
          }''');
          await response.close();
          continue;
        }

        if (request.method == 'GET' && path == '/sw.js') {
          response.headers.contentType = ContentType('application', 'javascript');
          response.write("self.addEventListener('fetch', function(e) {});");
          await response.close();
          continue;
        }

        if (request.method == 'GET' && path == '/icon.svg') {
          response.headers.contentType = ContentType('image', 'svg+xml');
          response.write('''<svg width="512" height="512" viewBox="0 0 512 512" xmlns="http://www.w3.org/2000/svg">
            <rect width="512" height="512" rx="112" fill="#1e1b4b"/>
            <rect x="128" y="80" width="256" height="352" rx="32" fill="#3b82f6"/>
            <rect x="160" y="112" width="192" height="288" fill="#0f172a"/>
          </svg>''');
          await response.close();
          continue;
        }
        
        // Authentication guard
        if (!_isAuthenticated(request)) {
          response.statusCode = 401;
          response.write('Unauthorized');
          await response.close();
          continue;
        }
        
        if (request.method == 'POST' && path == '/connect') {
          final content = await utf8.decoder.bind(request).join();
          try {
            final data = jsonDecode(content);
            setState(() {
              _connectedDevice = data;
            });
            response.statusCode = 200;
            response.write('OK');
          } catch(e) {
            response.statusCode = 400;
          }
          await response.close();
          continue;
        }

        if (request.method == 'GET' && path == '/directories') {
          final dirs = _rootDirs.keys.map((k) => {'name': k, 'path': k}).toList();
          response.headers.contentType = ContentType.json;
          response.write(jsonEncode(dirs));
          await response.close();
          continue;
        }
        if (request.method == 'GET' && path == '/files') {
          final reqDir = request.uri.queryParameters['dir'] ?? 'PhoneLink';
          final realPath = _getRealPath(reqDir);
          
          if (realPath.isEmpty) {
            response.statusCode = 400;
            response.write('[]');
            await response.close();
            continue;
          }
          
          final dir = Directory(realPath);
          if (!await dir.exists()) {
             if (reqDir == 'PhoneLink') {
               await dir.create(recursive: true);
             } else { 
               response.statusCode = 404; 
               await response.close(); 
               continue; 
             }
          }
          
          final list = <Map<String, dynamic>>[];
          try {
            final entities = dir.listSync();
            for (var e in entities) {
              final name = e.path.split(Platform.pathSeparator).last;
              if (name == '.metadata.json' || name.startsWith('.')) continue;
              final stat = e.statSync();
              list.add({
                'name': name,
                'isDir': stat.type == FileSystemEntityType.directory,
                'size': stat.size,
                'origin': (reqDir == 'PhoneLink') ? (_fileOrigins[name] ?? 'PC') : 'PC',
              });
            }
          } catch(err) {
            debugPrint('Directory read error: $err');
          }
            
          response.headers.contentType = ContentType.json;
          response.write(jsonEncode(list));
          await response.close();
        }
        else if (request.method == 'GET' && path.startsWith('/download/')) {
          final rawFileName = Uri.decodeComponent(path.substring('/download/'.length));
          final reqDir = request.uri.queryParameters['dir'] ?? 'PhoneLink';
          final realPath = _getRealPath(reqDir);
          final safeFileName = _sanitizeFileName(rawFileName);
          
          if (realPath.isEmpty) { response.statusCode = 404; await response.close(); continue; }
          
          final file = File('$realPath${Platform.pathSeparator}$safeFileName');
          if (await file.exists()) {
            response.headers.contentType = ContentType.binary;
            response.headers.add('Content-Disposition', 'attachment; filename="$safeFileName"');
            await response.addStream(file.openRead());
          } else {
            response.statusCode = 404;
            response.write('Dosya bulunamadı');
          }
          await response.close();
        }
        else if (request.method == 'POST' && path == '/upload') {
          final rawFileName = Uri.decodeComponent(request.uri.queryParameters['name'] ?? 'unknown_file');
          final reqDir = request.uri.queryParameters['dir'] ?? 'PhoneLink';
          final realPath = _getRealPath(reqDir);
          final safeFileName = _sanitizeFileName(rawFileName);
          
          if (realPath.isEmpty) { response.statusCode = 400; await response.close(); continue; }
          
          final dir = Directory(realPath);
          if (!await dir.exists()) await dir.create(recursive: true);
          
          final file = File('$realPath${Platform.pathSeparator}$safeFileName');
          final sink = file.openWrite();
          await sink.addStream(request);
          await sink.flush();
          await sink.close();
          
          if (reqDir == 'PhoneLink') {
            _fileOrigins[safeFileName] = 'Phone';
            _saveMetadata();
            _loadSharedFiles();
          }
          response.statusCode = 200;
          response.write('OK');
          await response.close();
        }
        // Screen API endpoints
        else if (request.method == 'GET' && path == '/screen/frame') {
          final resStr = request.uri.queryParameters['res'];
          if (resStr != null) {
             final resMode = int.tryParse(resStr) ?? 1080;
             _screenStreamer.setResolution(resMode);
          }

          final fpsStr = request.uri.queryParameters['fps'];
          if (fpsStr != null) {
            final fps = int.tryParse(fpsStr) ?? 15;
            if (fps > 0) {
              _screenStreamer.setFps(fps);
              _screenStreamer.start();
            } else {
              _screenStreamer.stop();
            }
          } else {
            _screenStreamer.start();
          }
          
          int retries = 0;
          while (_screenStreamer.latestFrame == null && retries < 40) {
            await Future.delayed(const Duration(milliseconds: 50));
            retries++;
          }

          final initialFrame = _screenStreamer.latestFrame;
          if (initialFrame == null) {
            response.statusCode = 404;
            response.write('No frame yet');
            await response.close();
            continue;
          }

          response.headers.contentType = ContentType.parse('multipart/x-mixed-replace; boundary=--myboundary');
          
          void sendFrame(Uint8List frame) {
            try {
              response.write('--myboundary\r\n');
              response.write('Content-Type: image/jpeg\r\n');
              response.write('Content-Length: ${frame.length}\r\n\r\n');
              response.add(frame);
              response.write('\r\n');
            } catch (e) {
              // Socket might be closed
            }
          }
          
          sendFrame(initialFrame);
          
          final sub = _screenStreamer.frameStream.listen((frame) {
            sendFrame(frame);
          });

          await request.response.done.catchError((_) {}).whenComplete(() {
            sub.cancel();
          });
        }
        else if (request.method == 'POST' && path == '/screen/stop') {
          _screenStreamer.stop();
          response.statusCode = 200;
          response.write('OK');
          await response.close();
        }
        // Deck API endpoints
        else if (request.method == 'GET' && path == '/deck/profiles') {
          response.headers.contentType = ContentType.json;
          response.write(_deckManager.toApiJson());
          await response.close();
        }
        else if (request.method == 'GET' && path == '/deck/buttons') {
          final profileId = request.uri.queryParameters['profile'] ?? _deckManager.activeProfileId;
          response.headers.contentType = ContentType.json;
          response.write(_deckManager.buttonsToApiJson(profileId));
          await response.close();
        }
        else if (request.method == 'POST' && path == '/deck/execute') {
          final content = await utf8.decoder.bind(request).join();
          try {
            final data = jsonDecode(content);
            final button = DeckButton.fromJson(data);
            final success = await _deckManager.executeAction(button);
            response.statusCode = success ? 200 : 500;
            response.write(success ? 'OK' : 'Failed');
          } catch(e) {
            response.statusCode = 400;
            response.write('Bad request: $e');
          }
          await response.close();
        }
        else if (request.method == 'POST' && path == '/deck/set-profile') {
          final content = await utf8.decoder.bind(request).join();
          try {
            final data = jsonDecode(content);
            _deckManager.activeProfileId = data['profileId'] ?? '';
            await _deckManager.save();
            if (mounted) setState(() {});
            response.statusCode = 200;
            response.write('OK');
          } catch(e) {
            response.statusCode = 400;
          }
          await response.close();
        }
        else if (request.method == 'POST' && path == '/mouse') {
          final content = await utf8.decoder.bind(request).join();
          try {
            final data = jsonDecode(content);
            final action = data['action'];
            if (action == 'absolute') {
              final xPct = (data['x'] as num?)?.toDouble();
              final yPct = (data['y'] as num?)?.toDouble();
              final isClick = data['click'] == true;
              if (xPct != null && yPct != null) {
                _deckManager.keySimulator.simulateMouseAbsolute(xPct, yPct, click: isClick);
              }
            } else {
              final dx = data['dx'] as int?;
              final dy = data['dy'] as int?;
              _deckManager.keySimulator.simulateMouse(action, dx: dx, dy: dy);
            }
            response.statusCode = 200;
            response.write('OK');
          } catch (e) {
            response.statusCode = 400;
            response.write('Error: $e');
          }
          await response.close();
        }
        else {
          response.statusCode = 404;
          response.write('Not found');
          await response.close();
        }
      } catch (e) {
        debugPrint('Server error: $e');
        try {
          response.statusCode = 500;
          response.write(e.toString());
          await response.close();
        } catch (_) {}
      }
    }
  }

  String _getHtmlContent() {
    return getWebHtmlContent();
  }

  Widget _buildTitleBar() {
    return DragToMoveArea(
      child: Container(
        height: 64,
        color: context.theme.surface,
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Row(
          children: [
            Icon(Icons.settings_remote, color: context.theme.primaryContainer, size: 24),
            const SizedBox(width: 16),
            Text('PHONE DESK', style: TextStyle(color: context.theme.primaryContainer, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -1)),
            const Spacer(),
            
            // Topup Mode
            Tooltip(
              message: _isTopup ? 'Her Zaman Üstte: Açık' : 'Her Zaman Üstte: Kapalı',
              child: InkWell(
                onTap: () async {
                  setState(() => _isTopup = !_isTopup);
                  await windowManager.setAlwaysOnTop(_isTopup);
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(
                    _isTopup ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                    color: _isTopup ? context.theme.primaryContainer : context.theme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
              ),
            ),
            
            // Compact Mode
            Tooltip(
              message: _isCompact ? 'Tam Görünüm' : 'Kompakt Mod',
              child: InkWell(
                onTap: () async {
                  setState(() => _isCompact = !_isCompact);
                  if (_isCompact) {
                    await windowManager.setSize(const Size(400, 520));
                  } else {
                    await windowManager.setSize(const Size(850, 600));
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(
                    _isCompact ? Icons.fullscreen_rounded : Icons.fullscreen_exit_rounded,
                    color: _isCompact ? context.theme.primaryContainer : context.theme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
              ),
            ),
            
            // Minimize
            InkWell(
              onTap: () async => await windowManager.minimize(),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(Icons.minimize_rounded, color: context.theme.onSurfaceVariant, size: 20),
              ),
            ),
            
            // Maximize / Restore
            InkWell(
              onTap: () async {
                if (await windowManager.isMaximized()) {
                  await windowManager.unmaximize();
                } else {
                  await windowManager.maximize();
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(Icons.crop_square_rounded, color: context.theme.onSurfaceVariant, size: 18),
              ),
            ),
            
            // Close
            InkWell(
              onTap: () async => await windowManager.hide(),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(Icons.close_rounded, color: context.theme.onSurfaceVariant, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getFileIcon(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    IconData icon;
    Color color;
    
    switch (ext) {
      case 'exe':
      case 'msi':
        icon = Icons.settings_applications; color = context.theme.accentRed; break;
      case 'apk':
        icon = Icons.android; color = context.theme.tertiaryContainer; break;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        icon = Icons.image; color = context.theme.secondary; break;
      case 'mp4':
      case 'mkv':
      case 'avi':
        icon = Icons.video_file; color = context.theme.secondaryContainer; break;
      case 'mp3':
      case 'wav':
        icon = Icons.audio_file; color = context.theme.tertiaryContainer; break;
      case 'pdf':
        icon = Icons.picture_as_pdf; color = context.theme.accentRed; break;
      case 'zip':
      case 'rar':
      case '7z':
        icon = Icons.folder_zip; color = context.theme.outline; break;
      default:
        icon = Icons.insert_drive_file; color = context.theme.primary; break;
    }
    
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
  
  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (bytes > 0) ? (bytes.toDouble().abs().toString().length / 3).floor() : 0;
    if (i >= suffixes.length) i = suffixes.length - 1;
    return '${(bytes / [1, 1024, 1048576, 1073741824, 1099511627776][i]).toStringAsFixed(1)} ${suffixes[i]}';
  }

  Widget _buildGalleryView() {
    final mediaFiles = _sharedFiles.where((f) {
      final name = f.path.split(Platform.pathSeparator).last;
      if (name == '.metadata.json') return false;
      final origin = _fileOrigins[name] ?? 'PC';
      final ext = name.split('.').last.toLowerCase();
      return origin == 'Phone' && ['jpg','jpeg','png','gif','webp','mp4','mov'].contains(ext);
    }).toList();

    if (mediaFiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.photo_library_outlined, size: 64, color: context.theme.outline.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text('Telefondan henüz fotoğraf\ngönderilmedi.', textAlign: TextAlign.center, style: TextStyle(color: context.theme.outline, height: 1.5)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: mediaFiles.length,
      itemBuilder: (context, index) {
        final file = mediaFiles[index];
        final fileName = file.path.split(Platform.pathSeparator).last;
        final isVideo = ['mp4', 'mov'].contains(fileName.split('.').last.toLowerCase());

        return InkWell(
          onTap: () => _openFile(file.path),
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: isVideo
                    ? Container(
                        color: Colors.black12,
                        child: const Icon(Icons.videocam_rounded, color: Colors.white54, size: 32),
                      )
                    : Image.file(file, fit: BoxFit.cover, filterQuality: FilterQuality.low),
              ),
              if (isVideo)
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('VIDEO', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSidebarButton(IconData icon, String label, int tabIndex) {
    final isActive = _currentTab == tabIndex;
    return InkWell(
      onTap: () => setState(() => _currentTab = tabIndex),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? context.theme.surfaceContainerHighest.withOpacity(0.5) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: isActive ? context.theme.primary : context.theme.onSurfaceVariant),
            const SizedBox(width: 16),
            Text(label, style: TextStyle(color: isActive ? context.theme.onSurface : context.theme.onSurfaceVariant, fontWeight: FontWeight.w500)),
          ]
        )
      )
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 250,
      color: context.theme.surfaceContainerLow,
      child: Column(
        children: [
          const SizedBox(height: 16),
          _buildSidebarButton(Icons.sensors, 'Bağlantı', 3), // 3 for Connection
          _buildSidebarButton(Icons.grid_view, 'Decks', 2),
          _buildSidebarButton(Icons.layers, 'Dosyalar', 0),
          _buildSidebarButton(Icons.graphic_eq, 'Galeri', 1),
          
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('v2.4.0', style: TextStyle(color: context.theme.outline, fontSize: 10)),
                Container(width: 8, height: 8, decoration: BoxDecoration(color: context.theme.tertiaryContainer, shape: BoxShape.circle, boxShadow: [BoxShadow(color: context.theme.tertiaryContainer.withOpacity(0.6), blurRadius: 8)])),
              ]
            )
          )
        ]
      )
    );
  }

  Widget _buildConnectionView() {
    final url = _isRunning && _ipAddress != null ? 'http://$_ipAddress:$_port' : null;

    if (url == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(_statusMessage, textAlign: TextAlign.center, style: TextStyle(color: context.theme.accentRed)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _startServer,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.theme.primaryContainer,
                foregroundColor: context.theme.background,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
              child: const Text('Yeniden Dene'),
            ),
          ],
        )
      );
    }

    return SingleChildScrollView(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Telefon Bağlantısı', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: context.theme.onSurface, letterSpacing: -1)),
              const SizedBox(height: 8),
              Text('Sürükle bırak ile anında dosya paylaşın. Cihazınızı komuta merkezine entegre etmek için eşleştirin.', 
                   style: TextStyle(fontSize: 16, color: context.theme.onSurfaceVariant), textAlign: TextAlign.center),
              const SizedBox(height: 48),
              
              SizedBox(
                height: 400, // Fixed height to prevent layout crashes with stretch and LayoutBuilders
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // QR Panel
                    Expanded(
                      flex: 3,
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: context.theme.surfaceContainer.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: context.theme.outlineVariant.withOpacity(0.5)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: context.theme.primary.withOpacity(0.2), width: 4)),
                              child: QrImageView(
                                data: url,
                                version: QrVersions.auto,
                                size: 180.0,
                                backgroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 32),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                color: context.theme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(32),
                                border: Border.all(color: context.theme.outlineVariant.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.qr_code_scanner, color: context.theme.primary),
                                  const SizedBox(width: 12),
                                  Flexible(child: Text('Telefon kameranızdan QR kodu okutun', style: TextStyle(color: context.theme.onSurfaceVariant, fontSize: 14))),
                                ]
                              )
                            )
                          ]
                        )
                      )
                    ),
                    const SizedBox(width: 12),
                    // Side Controls
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          // Status Card
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: context.theme.surfaceLow,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: context.theme.surfaceContainerHighest),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('STATUS', style: TextStyle(color: context.theme.outline, fontSize: 12, letterSpacing: 2)),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: context.theme.surfaceContainerHighest,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: context.theme.outlineVariant.withOpacity(0.5)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(width: 8, height: 8, decoration: BoxDecoration(color: _connectedDevice != null ? context.theme.tertiaryContainer : context.theme.outline, shape: BoxShape.circle)),
                                            const SizedBox(width: 8),
                                            Text(_connectedDevice != null ? 'Connected' : 'Waiting', style: TextStyle(color: context.theme.onSurfaceVariant, fontSize: 10)),
                                          ]
                                        )
                                      )
                                    ]
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    children: [
                                      Container(
                                        width: 48, height: 48,
                                        decoration: BoxDecoration(color: context.theme.surfaceContainer, borderRadius: BorderRadius.circular(24), border: Border.all(color: context.theme.outlineVariant.withOpacity(0.3))),
                                        child: Icon(Icons.smartphone, color: _connectedDevice != null ? context.theme.tertiaryContainer : context.theme.outline),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(_connectedDevice != null ? '${_connectedDevice!['device']}' : 'No Device', style: TextStyle(color: context.theme.onSurface, fontSize: 20, fontWeight: FontWeight.bold)),
                                            Text(_connectedDevice != null ? 'Battery: ${_connectedDevice!['battery']}' : 'Awaiting pair request...', style: TextStyle(color: context.theme.outline, fontSize: 14)),
                                          ]
                                        ),
                                      )
                                    ]
                                  )
                                ]
                              )
                            )
                          ),
                          const SizedBox(height: 12),
                          // Manual IP Card
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: context.theme.surfaceLow,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: context.theme.surfaceContainerHighest),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('MANUAL OVERRIDE', style: TextStyle(color: context.theme.outline, fontSize: 12, letterSpacing: 2)),
                                  const SizedBox(height: 16),
                                  Text('Local IP Address', style: TextStyle(color: context.theme.onSurfaceVariant, fontSize: 14)),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    decoration: BoxDecoration(
                                      border: Border(bottom: BorderSide(color: context.theme.outlineVariant)),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.wifi_tethering, color: context.theme.outline),
                                        const SizedBox(width: 12),
                                        Expanded(child: SelectableText(url, style: TextStyle(color: context.theme.primary, fontSize: 16, fontWeight: FontWeight.bold))),
                                      ]
                                    )
                                  ),
                                ]
                              )
                            )
                          ),
                        ]
                      )
                    )
                  ]
                )
              )
            ]
          )
        )
      )
    );
  }

  Widget _buildFilesView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Paylaşılan Dosyalar', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: context.theme.onSurface)),
              Text('${_sharedFiles.length} öğe', style: TextStyle(color: context.theme.onSurfaceVariant, fontSize: 14)),
            ],
          ),
        ),
        Expanded(
          child: _sharedFiles.where((f) => f.path.split(Platform.pathSeparator).last != '.metadata.json').isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.upload_file_rounded, size: 64, color: context.theme.outline.withOpacity(0.3)),
                    const SizedBox(height: 16),
                    Text('Dosyaları eklemek için\nburaya sürükleyin', textAlign: TextAlign.center, style: TextStyle(color: context.theme.outline, height: 1.5)),
                  ],
                ),
              )
            : Builder(
                builder: (context) {
                  final visibleFiles = _sharedFiles.where((f) => f.path.split(Platform.pathSeparator).last != '.metadata.json').toList();
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: visibleFiles.length,
                    itemBuilder: (context, index) {
                      final file = visibleFiles[index];
                      final fileName = file.path.split(Platform.pathSeparator).last;
                      
                      final origin = _fileOrigins[fileName] ?? 'PC';
                  final isFromPhone = origin == 'Phone';
                  
                  final ext = fileName.split('.').last.toLowerCase();
                  final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext);

                  return InkWell(
                    onTap: () => _openFile(file.path),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.theme.surfaceLow,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                isImage
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: SizedBox(
                                          width: 48,
                                          height: 48,
                                          child: Image.file(file, fit: BoxFit.cover, filterQuality: FilterQuality.low),
                                        ),
                                      )
                                    : _getFileIcon(fileName),
                                const SizedBox(height: 12),
                                Text(
                                  fileName,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatBytes(file.lengthSync()),
                                  style: TextStyle(fontSize: 11, color: context.theme.onSurfaceVariant),
                                ),
                              ],
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: (isFromPhone ? context.theme.accentGreen : context.theme.primaryContainer).withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isFromPhone ? Icons.download_rounded : Icons.upload_rounded,
                              color: isFromPhone ? context.theme.accentGreen : context.theme.primaryContainer,
                              size: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    ]);
  }

  Widget _buildMainContent() {
    if (_currentTab == 2) {
      return DeckPanel(
        deckManager: _deckManager,
        onChanged: () => setState(() {}),
      );
    } else if (_currentTab == 1) {
      return _buildGalleryView();
    } else if (_currentTab == 0) {
      return _buildFilesView();
    } else {
      return _buildConnectionView(); // Tab 3 is Connection
    }
  }

  @override
  Widget build(BuildContext context) {
    // Override _currentTab to 3 (Connection) if it's currently something invalid
    // We added tab 3. Ensure it starts at 3 if we haven't selected anything else maybe?
    // Let's just build the structure.

    return Column(
      children: [
        _buildTitleBar(),
        Expanded(
          child: DropTarget(
            onDragEntered: (details) => setState(() => _isDragging = true),
            onDragExited: (details) => setState(() => _isDragging = false),
            onDragDone: (details) async {
              setState(() => _isDragging = false);
              for (var file in details.files) {
                final dest = '$_phoneLinkDir${Platform.pathSeparator}${file.name}';
                await file.saveTo(dest);
                _fileOrigins[file.name] = 'PC';
              }
              _saveMetadata();
              _loadSharedFiles();
              setState(() => _currentTab = 0); // Switch to files tab on drop
            },
            child: Stack(
              children: [
                Container(
                  color: context.theme.background,
                  child: Row(
                    children: [
                      if (!_isCompact) _buildSidebar(),
                      Expanded(
                        child: _buildMainContent(),
                      ),
                    ],
                  ),
                ),
                
                // Drag & Drop Overlay
                if (_isDragging)
                  Container(
                    color: context.theme.primaryContainer.withOpacity(0.9),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.file_upload_outlined, size: 100, color: Colors.black87),
                          const SizedBox(height: 24),
                          const Text('Dosyaları Paylaşıma Eklemek İçin\nBuraya Bırakın', textAlign: TextAlign.center, style: TextStyle(fontSize: 32, color: Colors.black87, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
