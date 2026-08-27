// lib/features/telemedicine/telemedicine_room_screen.dart

import 'package:bmc_app/core/network/models/widget.dart';
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

  static const String _webrtcMonitorScript = '''
    (function() {
      if (window.__webrtcMonitorInstalled) return;
      window.__webrtcMonitorInstalled = true;
      var OriginalRTCPeerConnection = window.RTCPeerConnection;
      if (!OriginalRTCPeerConnection) return;

      window.RTCPeerConnection = function(...args) {
        var pc = new OriginalRTCPeerConnection(...args);
        pc.addEventListener('connectionstatechange', function() {
          if (window.LiveStatus) {
            window.LiveStatus.postMessage(pc.connectionState);
          }
        });
        return pc;
      };
      window.RTCPeerConnection.prototype = OriginalRTCPeerConnection.prototype;
    })();
  ''';

  @override
  void initState() {
    super.initState();
    _setupWebView();
  }

  Future<void> _setupWebView() async {
    await [Permission.camera, Permission.microphone].request();
    final camStatus = await Permission.camera.status;
    final micStatus = await Permission.microphone.status;
    debugPrint('camera: $camStatus, mic: $micStatus');

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
              setState(() => _isLive = message.message == 'connected');
            },
          )
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageFinished: (String url) {
                if (mounted) setState(() => _isLoading = false);
              },
            ),
          )
          ..loadRequest(Uri.parse(widget.joinLink));

    if (mounted) setState(() => _controller = controller);
  }

  @override
  Widget build(BuildContext context) {
    final age = _calculateAge(widget.visits.dob);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          color: const Color(0xFF1B5E3C),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
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
                          'MRN: ${widget.visits.medrecnum ?? ''}  |  '
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
                                color: _isLive ? Colors.greenAccent : Colors.orangeAccent,
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
      body: _controller == null
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
