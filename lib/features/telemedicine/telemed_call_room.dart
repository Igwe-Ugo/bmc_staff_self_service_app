// lib/features/telemedicine/telemedicine_room_screen.dart

import 'dart:async';

import 'package:bmc_app/core/network/models/widget.dart';
import 'package:bmc_app/features/common/show_message.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:permission_handler/permission_handler.dart';

class TelemedicineRoomScreen extends StatefulWidget {
  final String joinLink;
  final QryBookingVisits visits;

  const TelemedicineRoomScreen({
    super.key,
    required this.joinLink,
    required this.visits,
  });

  @override
  State<TelemedicineRoomScreen> createState() => _TelemedicineRoomScreenState();
}

class _TelemedicineRoomScreenState extends State<TelemedicineRoomScreen> {
  WebViewController? _controller; // nullable now — built async in _setupWebView
  bool _isLoading = true;
  bool _isLive = false;

  // set when camera or microphone was refused at the OS level. The WebView can
  // only pass on a permission the app itself holds, so loading the call page
  //without these produces a room with no devices and no explanation.
  String? _permissionError;
  bool _permanentlyDenied = false;
  Timer? _joinTimeoutTimer;

  @override
  void initState() {
    super.initState();
    _setupWebView();
  }

  @override
  void dispose() {
    _joinTimeoutTimer?.cancel();
    super.dispose();
  }

  Future<void> _setupWebView() async {
    final statuses = await [Permission.camera, Permission.microphone].request();
    final camStatus = statuses[Permission.camera] ?? PermissionStatus.denied;
    final micStatus =
        statuses[Permission.microphone] ?? PermissionStatus.denied;
    debugPrint('camera: $camStatus, mic: $micStatus');

    if (!camStatus.isGranted || !micStatus.isGranted) {
      final missing = [
        if (!camStatus.isGranted) 'Camera',
        if (!micStatus.isGranted) 'Microphone',
      ].join(' and ');
      final message =
          'BMC needs access to your $missing to join a video consultation.';
      if (mounted) {
        setState(() {
          _permissionError = message;
          _permanentlyDenied =
              camStatus.isPermanentlyDenied || micStatus.isPermanentlyDenied;
        });
      }
      showMessage(message, context, status: MessageStatus.error);
      return;
    }

    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final controller =
        WebViewController.fromPlatformCreationParams(
            params,
            onPermissionRequest: (WebViewPermissionRequest request) {
              // Fires when the page calls getUserMedia. If this line never
              // appears in logcat, the page never asked — the problem is on the
              // web side, not here.
              debugPrint('WebView permission request: ${request.types}');
              request.grant();
            },
          )
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(Colors.black)
          ..addJavaScriptChannel(
            'LiveStatus',
            onMessageReceived: (JavaScriptMessage message) {
              debugPrint('WebRTC connectionState: ${message.message}');
              if (!mounted) return;
              _handleConnectionState(message.message);
            },
          )
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageFinished: (String url) {
                if (mounted) setState(() => _isLoading = false);
              },
              onWebResourceError: (WebResourceError error) {
                debugPrint(
                  'WebView Error ${error.errorCode}: ${error.description}\n${error.url}',
                );
                showMessage(
                  'Something went wrong laoding the room. (${error.errorCode})',
                  context,
                  status: MessageStatus.error,
                );
              },
            ),
          );
    // Android-specific configuration must be applied before the page loads
    // This is in order to leave video false, because it defaults as true.
    if (controller.platform is AndroidWebViewController) {
      final android = controller.platform as AndroidWebViewController;
      await android.setMediaPlaybackRequiresUserGesture(false);
      // attaches the chrome inspect to the WebView to read the real JS error.
      if (kDebugMode) AndroidWebViewController.enableDebugging(true);
    }
    await controller.loadRequest(
      Uri.parse(widget.joinLink),
      headers: const {'ngrok-skip-browser-warning': 'true'},
    );
    if (mounted) setState(() => _controller = controller);
  }

  @override
  Widget build(BuildContext context) {
    final age = _calculateAge(widget.visits.dob);
    final mrnStr = widget.visits.medrecnum?.toString() ?? '';
    final mrnTail = mrnStr.length > 6 ? mrnStr.substring(6) : mrnStr;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: Container(
          color: const Color(0xFF1B5E3C),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      showMessage(
                        'Leaving the Consulting Room...',
                        context,
                        status: MessageStatus.info,
                      );
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                    ),
                    icon: const Icon(Icons.arrow_back, size: 14),
                    label: const Text(
                      'BACK',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${widget.visits.fullname ?? ''} | Telemed Clinic - ${widget.visits.specialistClinicType ?? ''} - ${widget.visits.telemedProviderName ?? ''}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Lexend',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'MRN: ...$mrnTail  |  '
                          '${widget.visits.gender ?? ''}  |  '
                          '${age != null ? '$age years' : ''}   '
                          'Telemedicine Clinic  |  ${widget.visits.telemedProviderName ?? ''}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontFamily: 'Lexend',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.circle,
                                size: 8,
                                color: _isLive
                                    ? Colors.greenAccent
                                    : Colors.orangeAccent,
                              ),
                              SizedBox(width: 4),
                              Text(
                                _isLive ? 'Live Session' : 'Connecting...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _permissionError != null
          ? _PermissionNotice(
              message: _permissionError!,
              showSettings: _permanentlyDenied,
            )
          : _controller == null
          ? Center(
              child: LoadingAnimationWidget.staggeredDotsWave(
                color: Colors.white,
                size: 35,
              ),
            )
          : Stack(
              children: [
                _buildWebView(),
                if (_isLoading)
                  Center(
                    child: LoadingAnimationWidget.staggeredDotsWave(
                      color: Colors.white,
                      size: 35,
                    ),
                  ),
              ],
            ),
    );
  }

  int? _calculateAge(DateTime? dob) {
    if (dob == null) return null;
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  // Reacts to every RTCPeerConnection.connectionState value, not just 'connected',
  // and starts a timeout the first time a connection attempt is detected — since
  // that's our best proxy for "the join button was pressed."
  void _handleConnectionState(String state) {
    switch (state) {
      case 'new':
      case 'connecting':
        setState(() => _isLive = false);
        _joinTimeoutTimer ??= Timer(const Duration(seconds: 20), () {
          if (!mounted || _isLive) return;
          showMessage(
            'Still waiting for the other party to join. You will connect automatically once they do.',
            context,
            status: MessageStatus.info,
          );
        });
        break;
      case 'connected':
        _joinTimeoutTimer?.cancel();
        _joinTimeoutTimer = null;
        setState(() => _isLive = true);
        showMessage('You are live', context, status: MessageStatus.success);
      case 'disconnected':
        setState(() => _isLive = false);
        showMessage(
          'Connection lost - attempting to reconnect...',
          context,
          status: MessageStatus.error,
        );
        break;
      case 'failed':
        _joinTimeoutTimer?.cancel();
        _joinTimeoutTimer = null;
        setState(() => _isLive = false);
        showMessage(
          'The call failed to connect. Please try again.',
          context,
          status: MessageStatus.error,
        );
        break;
      case 'closed':
        _joinTimeoutTimer?.cancel();
        _joinTimeoutTimer = null;
        setState(() => _isLive = false);
        showMessage('The call has ended.', context, status: MessageStatus.info);
        break;
    }
  }

  Widget _buildWebView() {
    final params = PlatformWebViewWidgetCreationParams(
      controller: _controller!.platform,
    );
    if (WebViewPlatform.instance is AndroidWebViewPlatform) {
      return AndroidWebViewWidget(
        AndroidWebViewWidgetCreationParams.fromPlatformWebViewWidgetCreationParams(
          params,
          displayWithHybridComposition: true,
        ),
      ).build(context);
    }
    return WebViewWidget(controller: _controller!);
  }
}

class _PermissionNotice extends StatelessWidget {
  final String message;
  final bool showSettings;

  const _PermissionNotice({required this.message, required this.showSettings});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.videocam_off,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white70
                  : Colors.black54,
              size: 44,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : Colors.black54,
                fontSize: 14,
                fontFamily: 'Lexend',
              ),
            ),
            if (showSettings) ...[
              const SizedBox(height: 20),
              // once permanently denied, the OS will not prompt again - the only route back is app settings
              FilledButton(
                onPressed: openAppSettings,
                child: const Text('Open Settings'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
