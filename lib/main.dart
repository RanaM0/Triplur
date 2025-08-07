import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Triplur',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF68BDA7)),
        appBarTheme: const AppBarTheme(
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _controller = VideoPlayerController.asset('assets/triplur_splash.mp4')
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
        _controller.setLooping(false);

        final duration = _controller.value.duration;
        Future.delayed(
          duration > const Duration(seconds: 0)
              ? duration
              : const Duration(seconds: 9),
              () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MainScreen()),
            );
          },
        );
      });
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        child: _controller.value.isInitialized
            ? FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _controller.value.size.width,
            height: _controller.value.size.height,
            child: VideoPlayer(_controller),
          ),
        )
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<GlobalKey<_WebViewWithLoaderState>> _webViewKeys = List.generate(
    5,
        (_) => GlobalKey<_WebViewWithLoaderState>(),
  );

  final List<String> _titles = [
    'Home',
    'Tours',
    'Contact Us',
    // 'Pilgrimage',
    'About',
  ];

  final List<String> _urls = [
    'https://www.triplur.co.uk',
    'https://www.triplur.co.uk/tour-packages/',
    'https://triplur.co.uk/about-us/',
    // 'https://triplur.co.uk/umrah-packages/',
    'https://triplur.co.uk/contact-us/',
  ];

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_titles[_currentIndex]),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                _webViewKeys[_currentIndex].currentState?.reloadWebView();
              },
            ),
          ],
        ),
        body: WebViewWithLoader(
          key: _webViewKeys[_currentIndex],
          url: _urls[_currentIndex],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.airplane_ticket),
              label: 'Tours',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.account_circle),
              label: 'About',
            ),
            // BottomNavigationBarItem(
            //   icon: SvgPicture.asset(
            //     'assets/kaaba.svg',
            //     height: 24,
            //     width: 24,
            //     colorFilter: _currentIndex == 3
            //         ? const ColorFilter.mode(Color(0xFF006b4f), BlendMode.srcIn)
            //         : const ColorFilter.mode(Color(0xFF5F6368), BlendMode.srcIn),
            //   ),
            //   label: 'Pilgrimage',
            // ),
            BottomNavigationBarItem(
              icon: Icon(Icons.mark_unread_chat_alt_rounded),
              label: 'Contact',
            ),
          ],
        ),
      ),
    );
  }
}

class WebViewWithLoader extends StatefulWidget {
  final String url;

  const WebViewWithLoader({super.key, required this.url});

  @override
  State<WebViewWithLoader> createState() => _WebViewWithLoaderState();
}

class _WebViewWithLoaderState extends State<WebViewWithLoader> {
  bool _isLoading = true;
  late final WebViewController _controller;
  DateTime? _lastPressedAt;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) async {
            final url = request.url;

            Future<void> _launchDialer(String number) async {
              const platform = MethodChannel('com.triplur/dialer');
              try {
                await platform.invokeMethod('openDialer', {'number': number});
              } on PlatformException catch (e) {
                debugPrint("Failed to open dialer: '${e.message}'.");
              }
            }

            if (url.startsWith("whatsapp://") || url.contains("wa.me") || url.contains("web.whatsapp.com")) {
              if (await canLaunchUrl(Uri.parse(url))) {
                await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              }
              else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Could not open WhatsApp.")),
                );
              }
              return NavigationDecision.prevent;
            }



            else if (url.startsWith("tel:")) {
              final number = url.replaceFirst('tel:', '');
              await _launchDialer(number);
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
          onPageStarted: (_) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (_) async {
            setState(() => _isLoading = false);
            await _controller.runJavaScript('''
              document.querySelector('header')?.style.display = 'none';
              document.querySelector('footer')?.style.display = 'none';
              document.querySelector('.site-header')?.style.display = 'none';
              document.querySelector('.site-footer')?.style.display = 'none';
            ''');
          },
          onWebResourceError: (_) {
            setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  void reloadWebView() {
    _controller.reload();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (await _controller.canGoBack()) {
          _controller.goBack();
          return false;
        } else {
          final now = DateTime.now();
          if (_lastPressedAt == null ||
              now.difference(_lastPressedAt!) > const Duration(seconds: 2)) {
            _lastPressedAt = now;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Press back again to exit')),
            );
            return false;
          }
          return true;
        }
      },
      child: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
