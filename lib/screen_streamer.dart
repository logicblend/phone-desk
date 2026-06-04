import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
import 'package:image/image.dart' as img;

class ScreenStreamer {
  bool _isStreaming = false;
  Uint8List? _latestFrame;
  int _targetFps = 15;
  Timer? _timer;
  bool _isEncoding = false;
  int _targetWidth = 1920;
  int _jpegQuality = 65;

  final _frameController = StreamController<Uint8List>.broadcast();

  int get targetFps => _targetFps;
  Uint8List? get latestFrame => _latestFrame;
  Stream<Uint8List> get frameStream => _frameController.stream;

  void setFps(int fps) {
    _targetFps = fps;
    if (_isStreaming) {
      stop();
      start();
    }
  }

  void setResolution(int heightMode) {
    if (heightMode <= 480) {
      _targetWidth = 854;
      _jpegQuality = 40;
    } else if (heightMode <= 720) {
      _targetWidth = 1280;
      _jpegQuality = 50;
    } else {
      _targetWidth = 1920;
      _jpegQuality = 65;
    }
  }

  void log(String message) {
    final msg = '[${DateTime.now().toIso8601String()}] ScreenStreamer: $message';
    print(msg);
    try {
      File('phone_desk_screen.log').writeAsStringSync('$msg\n', mode: FileMode.append);
    } catch (_) {}
  }

  void start() {
    if (_isStreaming) return;
    log('Stream starting, target FPS: $_targetFps, Res: $_targetWidth');
    _isStreaming = true;
    _captureFrame();
    _timer = Timer.periodic(Duration(milliseconds: 1000 ~/ _targetFps), (timer) {
      _captureFrame();
    });
  }

  void stop() {
    log('Stream stopping');
    _isStreaming = false;
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _captureFrame() async {
    if (_isEncoding) return; // Skip if previous frame is still encoding
    _isEncoding = true;

    try {
      final watch = Stopwatch()..start();
      
      int hwnd = GetDesktopWindow();
      int hdcScreen = GetDC(hwnd);
      
      int width = GetSystemMetrics(SM_CXSCREEN);
      int height = GetSystemMetrics(SM_CYSCREEN);
      
      if (width == 0 || height == 0) {
         log('Error: Invalid screen dimensions $width x $height');
         return;
      }

      int hdcMem = CreateCompatibleDC(hdcScreen);
      int hbm = CreateCompatibleBitmap(hdcScreen, width, height);
      int hOld = SelectObject(hdcMem, hbm);
      
      BitBlt(hdcMem, 0, 0, width, height, hdcScreen, 0, 0, SRCCOPY);
      
      final bmi = calloc<BITMAPINFO>();
      bmi.ref.bmiHeader.biSize = sizeOf<BITMAPINFOHEADER>();
      bmi.ref.bmiHeader.biWidth = width;
      bmi.ref.bmiHeader.biHeight = -height; // Top-down
      bmi.ref.bmiHeader.biPlanes = 1;
      bmi.ref.bmiHeader.biBitCount = 32;
      bmi.ref.bmiHeader.biCompression = BI_RGB;
      
      final pixels = calloc<Uint32>(width * height);
      int res = GetDIBits(hdcScreen, hbm, 0, height, pixels, bmi, DIB_RGB_COLORS);
      
      if (res == 0) {
         log('Error: GetDIBits failed');
      }

      // Copy pixels to a Dart typed list so we can free the C memory safely
      final pixelList = Uint8List.fromList(pixels.cast<Uint8>().asTypedList(width * height * 4));

      SelectObject(hdcMem, hOld);
      DeleteObject(hbm);
      DeleteDC(hdcMem);
      ReleaseDC(hwnd, hdcScreen);
      free(bmi);
      free(pixels);

      final w = _targetWidth;
      final q = _jpegQuality;

      // Run image encoding in a separate isolate to avoid blocking main thread
      _latestFrame = await Isolate.run(() => _encodeImage(pixelList, width, height, w, q));
      
      if (_latestFrame != null) {
          _frameController.add(_latestFrame!);
          // Un-comment to trace every frame if needed: log('Frame captured & encoded. Size: ${_latestFrame!.length} bytes in ${watch.elapsedMilliseconds}ms');
      } else {
          log('Error: Frame encoding returned null');
      }

    } catch (e, stack) {
      log('Screen capture exception: $e\n$stack');
    } finally {
      _isEncoding = false;
    }
  }

  static Uint8List _encodeImage(Uint8List pixelList, int width, int height, int targetWidth, int jpegQuality) {
    final image = img.Image.fromBytes(
      width: width,
      height: height,
      bytes: pixelList.buffer,
      order: img.ChannelOrder.bgra,
    );
    
    img.Image toEncode = image;
    if (width > targetWidth) {
      // Use nearest interpolation for maximum performance to prevent latency
      toEncode = img.copyResize(image, width: targetWidth, interpolation: img.Interpolation.nearest);
    }

    final jpg = img.encodeJpg(toEncode, quality: jpegQuality);
    return Uint8List.fromList(jpg);
  }
}
