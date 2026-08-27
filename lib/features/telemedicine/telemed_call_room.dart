// lib/features/telemedicine/telemedicine_room_screen.dart

import 'package:bmc_app/core/network/models/widget.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:permission_handler/permission_handler.dart';

class TelemedicineRoomScreen extends StatefulWidget {
  final String joinLink;
  final QryBookingVisits visits;

  const TelemedicineRoomScreen({super.key, required this.joinLink, required this.visits});

  @override
  State<TelemedicineRoomScreen> createState() => _TelemedicineRoomScreenState();
}

class _TelemedicineRoomScreenState extends State<TelemedicineRoomScreen> {
  WebViewController? _controller; // nullable now — built async in _setupWebView
  bool _isLoading = true;

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consultation Room'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: _controller == null
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Stack(
              children: [
                WebViewWidget(controller: _controller!),
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
              ],
            ),
    );
  }
}
