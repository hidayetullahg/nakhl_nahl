// NAKHL & NAHL — Help Content Administration Screen
// Complies with Master Directive Section 33

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/help_models.dart';
import '../../services/help/help_registry.dart';

class HelpAdminScreen extends StatefulWidget {
  const HelpAdminScreen({super.key});

  @override
  State<HelpAdminScreen> createState() => _HelpAdminScreenState();
}

class _HelpAdminScreenState extends State<HelpAdminScreen> {
  List<HelpContent> _contents = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadContents();
  }

  Future<void> _loadContents() async {
    setState(() => _isLoading = true);
    try {
      final client = Supabase.instance.client;
      final res = await client.from('help_contents').select();
      if (res.isNotEmpty) {
        setState(() {
          _contents = (res as List).map((e) => HelpContent.fromJson(e)).toList();
        });
      } else {
        setState(() {
          _contents = List.from(HelpRegistry.defaultContents);
        });
      }
    } catch (_) {
      setState(() {
        _contents = List.from(HelpRegistry.defaultContents);
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _openEditorModal({HelpContent? existing}) {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final shortDescController = TextEditingController(text: existing?.shortDescription ?? '');
    final longDescController = TextEditingController(text: existing?.longDescription ?? '');
    final routeController = TextEditingController(text: existing?.route ?? '/');
    String role = existing?.role ?? 'all';
    String language = existing?.language ?? 'tr';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(existing == null ? 'Yeni Yardım Konusu Ekle' : 'Yardım Konusunu Düzenle'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Başlık', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: routeController,
                    decoration: const InputDecoration(labelText: 'Uygulama Rotası (örn: /sales/invoices)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: shortDescController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Kısa Açıklama (Tooltip)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: longDescController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Detaylı Açıklama (Drawer)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: role,
                          decoration: const InputDecoration(labelText: 'Kullanıcı Rolü', border: OutlineInputBorder()),
                          items: const [
                            DropdownMenuItem(value: 'all', child: Text('Tümü (All)')),
                            DropdownMenuItem(value: 'admin', child: Text('Yönetici (Admin)')),
                            DropdownMenuItem(value: 'accountant', child: Text('Muhasebeci')),
                            DropdownMenuItem(value: 'warehouse', child: Text('Depo')),
                            DropdownMenuItem(value: 'sales', child: Text('Satış')),
                            DropdownMenuItem(value: 'pos', child: Text('Kasiyer/POS')),
                          ],
                          onChanged: (v) => setModalState(() => role = v ?? 'all'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: language,
                          decoration: const InputDecoration(labelText: 'Dil', border: OutlineInputBorder()),
                          items: const [
                            DropdownMenuItem(value: 'tr', child: Text('Türkçe (TR)')),
                            DropdownMenuItem(value: 'en', child: Text('English (EN)')),
                            DropdownMenuItem(value: 'ar', child: Text('العربية (AR)')),
                          ],
                          onChanged: (v) => setModalState(() => language = v ?? 'tr'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('İptal'),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
              ),
              child: const Text('Kaydet'),
              onPressed: () async {
                final id = existing?.id ?? 'help_${DateTime.now().millisecondsSinceEpoch}';
                final updated = HelpContent(
                  id: id,
                  route: routeController.text.trim(),
                  menuKey: id,
                  title: titleController.text.trim(),
                  shortDescription: shortDescController.text.trim(),
                  longDescription: longDescController.text.trim(),
                  searchableText: '${titleController.text} ${shortDescController.text}',
                  role: role,
                  language: language,
                );

                try {
                  final client = Supabase.instance.client;
                  final tenantId = client.auth.currentUser?.userMetadata?['tenant_id'] ?? '11111111-1111-1111-1111-111111111111';
                  await client.from('help_contents').upsert({
                    'id': updated.id,
                    'tenant_id': tenantId,
                    'route': updated.route,
                    'menu_key': updated.menuKey,
                    'title': updated.title,
                    'short_description': updated.shortDescription,
                    'long_description': updated.longDescription,
                    'searchable_text': updated.searchableText,
                    'role': updated.role,
                    'language': updated.language,
                    'updated_at': DateTime.now().toIso8601String(),
                  });
                } catch (_) {}

                if (!mounted) return;
                setState(() {
                  final idx = _contents.indexWhere((c) => c.id == updated.id);
                  if (idx >= 0) {
                    _contents[idx] = updated;
                  } else {
                    _contents.add(updated);
                  }
                });

                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Yardım İçerik Yönetim Paneli'),
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Yeni Yardım Konusu'),
            onPressed: () => _openEditorModal(),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: _contents.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, idx) {
                final c = _contents[idx];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFF0F172A).withOpacity(0.06),
                        child: const Icon(Icons.article_outlined, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  c.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    c.route,
                                    style: TextStyle(fontSize: 11, color: Colors.blue.shade800, fontFamily: 'monospace'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              c.shortDescription,
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _openEditorModal(existing: c),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
