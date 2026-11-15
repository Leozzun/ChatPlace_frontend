import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/conversation.dart';
import '../providers/auth_provider.dart';
import '../services/api_client.dart';

class MenuScreen extends StatefulWidget {
  final void Function(Conversation) onConversationSelected;

  const MenuScreen({
    super.key,
    required this.onConversationSelected,
  });

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  List<Conversation> _convs = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    loadConversations();
  }

  Future<void> loadConversations() async {
    final auth = context.read<AuthProvider>();
    final userId = (context.read<AuthProvider>().user?.id ?? 0);

    setState(() => _loading = true);
    try {
      final api = ApiClient();
      final list = await api.loadConversations(userId);
      setState(() => _convs = list);
    } catch (e) {
      print('대화 목록 로드 실패: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final nickname = user != null ? '${user.nickname}님' : '';

    return Column(
      children: [
        SizedBox(
          width: 315,
          height: 762,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                child: Container(
                  width: 315,
                  height: 762,
                  color: Colors.white,
                ),
              ),
              // 상단 Chatplace + 닉네임
              Positioned(
                left: 22,
                top: 25,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chatplace',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 22,
                        fontFamily: 'Noto Sans',
                        fontWeight: FontWeight.w700,
                        height: 1.18,
                        letterSpacing: -0.88,
                      ),
                    ),
                    if (nickname.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            nickname,
                            style: const TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 16,
                              fontFamily: 'Noto Sans',
                              fontWeight: FontWeight.w500,
                              height: 1.18,
                            ),
                          ),
                        ],
                      )
                    ],
                  ],
                ),
              ),
              // 새 채팅 / 마이 리스트 (UI 유지)
              // 대화 목록
              Positioned(
                left: 22,
                top: 80,
                right: 10,
                bottom: 10,
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _convs.isEmpty
                    ? const Text(
                  '최근 대화가 없습니다.',
                  style: TextStyle(
                    color: Color(0xFF595959),
                    fontSize: 14,
                  ),
                )
                    : ListView.separated(
                  itemCount: _convs.length+1,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Text(
                          '내 채팅',
                          style: TextStyle(
                            color: Color(0xFF98989A),
                            fontSize: 17,
                            fontFamily: 'Noto Sans',
                            fontWeight: FontWeight.w700,
                            height: 1.4,
                            letterSpacing: -0.5,
                          ),
                        ),
                      );
                    }
                    final c = _convs[index-1];
                    return GestureDetector(
                      onTap: () {
                        widget.onConversationSelected(c);
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          c.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontFamily: 'Noto Sans',
                            fontWeight: FontWeight.w400,
                            height: 1.50,
                            letterSpacing: -0.64,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
