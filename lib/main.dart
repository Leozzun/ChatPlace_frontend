import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_place/src/providers/auth_provider.dart';
import 'package:the_place/src/providers/bookmark_provider.dart';
import 'package:the_place/src/providers/location_provider.dart';
import 'package:the_place/src/providers/recommend_provider.dart';
import 'package:the_place/src/screens/login_screen.dart';
import 'package:the_place/src/screens/chat_screen.dart';
import 'package:the_place/src/screens/explore_screen.dart';
import 'package:the_place/src/screens/my_screen.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await checkServerConnection('http://192.0.0.2:3000');

  final authProvider = AuthProvider();
  await authProvider.loadUser();

  KakaoSdk.init(
    nativeAppKey: '59ce19da367d6815dd8aa569f83df24d',
  );

  final bookmarkProvider = BookmarkProvider();
  final user = authProvider.user;
  debugPrint('auth user in main: $user');
  if (user != null) {
    await bookmarkProvider.loadBookmarks(user.id);
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => authProvider),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => bookmarkProvider),
        ChangeNotifierProvider(create: (_) => RecommendProvider()),
      ],
      child: const PlacelistApp(),
    ),
  );
}

// 서버 연결 체크 (옵션)
Future<void> checkServerConnection(String url) async {
  try {
    final uri = Uri.parse(url);
    final socket = await Socket.connect(
      uri.host,
      uri.port,
      timeout: const Duration(seconds: 3),
    );
    print('Connected to server at $url');
    socket.destroy();
  } catch (e) {
    print('Failed to connect to server at $url: $e');
  }
}

class PlacelistApp extends StatelessWidget {
  const PlacelistApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = context.watch<AuthProvider>().isLoggedIn;
    return MaterialApp(
      title: 'Placelist',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Noto Sans',
        colorScheme:
        ColorScheme.fromSeed(seedColor: const Color(0xFF5B6CFF)),
        useMaterial3: true,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
      ),
      home: isLoggedIn ? const MainScreen() : LoginScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;

  // MyScreen 상태에 접근하기 위한 GlobalKey
  final GlobalKey<MyScreenState> _myKey = GlobalKey<MyScreenState>();

  // 탭 위젯들을 한 번만 생성해서 상태 유지
  late final List<Widget> _pages = [
    const ChatScreen(),           // 홈
    ExploreScreen(),              // 탐색
    MyScreen(key: _myKey),        // 마이
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: _pages,
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          splashFactory: NoSplash.splashFactory,
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          iconSize: 32,
          selectedItemColor: const Color(0xFF000000),
          unselectedItemColor: const Color(0xFFA8A8AE),
          onTap: (idx) async {
            setState(() => _index = idx);

            // My 탭(인덱스 2)에 들어올 때마다 한 번씩 새로 로드
            if (idx == 2) {
              await _myKey.currentState?.refreshAll();
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: '홈',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.location_on_outlined),
              label: '탐색',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: '마이',
            ),
          ],
          selectedLabelStyle: const TextStyle(
            fontFamily: 'Noto Sans',
            fontWeight: FontWeight.w400,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'Noto Sans',
            fontWeight: FontWeight.w400,
            fontSize: 12,
          ),
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
        ),
      ),
    );
  }
}
