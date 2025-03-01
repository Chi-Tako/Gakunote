// lib/features/shared/widgets/app_drawer.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/services/subscription_service.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final subscriptionService = Provider.of<SubscriptionService>(context);
    final isPremium = subscriptionService.currentTier == SubscriptionTier.premium;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF1A73E8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gakunote',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      'マイノート',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isPremium)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'PREMIUM',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('ホーム'),
            onTap: () {
              context.go('/notes');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.star),
            title: const Text('お気に入り'),
            onTap: () {
              // お気に入りノート一覧画面に遷移（後で実装）
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.label),
            title: const Text('タグ'),
            onTap: () {
              // タグ一覧画面に遷移（後で実装）
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('設定'),
            onTap: () {
              context.go('/settings');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('ヘルプ'),
            onTap: () {
              // ヘルプ画面に遷移（後で実装）
              Navigator.pop(context);
            },
          ),
          if (!isPremium) ...[
            const Divider(),
            ListTile(
              leading: const Icon(
                Icons.star,
                color: Color(0xFFF57C00),
              ),
              title: const Text(
                'プレミアムにアップグレード',
                style: TextStyle(
                  color: Color(0xFFF57C00),
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                context.go('/settings');
              },
            ),
          ],
        ],
      ),
    );
  }
}