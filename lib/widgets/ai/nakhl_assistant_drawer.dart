import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme_tokens.dart';
import '../../core/i18n/locale_script_manager.dart';
import '../../features/ai/prompt_library.dart';
import '../../features/ai/guidance/five_w_one_h_guidance.dart';
import '../../features/ai/ai_gateway.dart';
import '../../core/tenant/tenant_context.dart';

class NakhlAssistantDrawer extends StatefulWidget {
  final String moduleName;
  final String screenName;

  const NakhlAssistantDrawer({
    super.key,
    required this.moduleName,
    required this.screenName,
  });

  @override
  State<NakhlAssistantDrawer> createState() => _NakhlAssistantDrawerState();
}

class _NakhlAssistantDrawerState extends State<NakhlAssistantDrawer> {
  final TextEditingController _questionController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Karşılama mesajı
    _messages.add({
      'sender': 'AI',
      'text':
          'Merhaba! Ben NAKHL & NAHL Kurumsal Asistanınızım. Şu anda "${widget.moduleName} > ${widget.screenName}" ekranındasınız. Size nasıl yardımcı olabilirim?',
    });
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  void _copyContextPrompt() {
    final prompt = PromptLibrary.generateCopyableContextPrompt(
      country: 'Suudi Arabistan / Türkiye',
      companyName: 'NAKHL & NAHL Trading Co.',
      branchName: 'Riyadh HQ / Istanbul Office',
      moduleName: widget.moduleName,
      screenName: widget.screenName,
      specificQuestion: _questionController.text.trim(),
    );

    Clipboard.setData(ClipboardData(text: prompt));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ Tam ERP bağlamı panoya kopyalandı. Harici AI\'ya yapıştırabilirsiniz.'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  Future<void> _sendQuestion([String? preset]) async {
    final text = preset ?? _questionController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'sender': 'USER', 'text': text});
      _isLoading = true;
    });
    _questionController.clear();

    // Önceden hazırlanmış 5N1K cevapları
    if (text.contains('5N1K') || text.contains('rehber')) {
      final guidance = widget.moduleName.toLowerCase().contains('satış') ||
              widget.screenName.toLowerCase().contains('fatura')
          ? FiveWOneHGuidance.exportInvoiceGuidance
          : FiveWOneHGuidance.cariCreateGuidance;

      setState(() {
        _messages.add({'sender': 'AI', 'text': guidance.toFormattedMarkdown()});
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await AIGateway.instance.executeRequest(
        tenantId: TenantContext.instance.activeTenantId ?? 'tenant_default',
        userId: 'user_active',
        prompt: text,
        taskType: 'USER_GUIDANCE',
        contextMetadata: {
          'module': widget.moduleName,
          'screen': widget.screenName,
        },
      );

      setState(() {
        _messages.add({'sender': 'AI', 'text': response.text});
      });
    } catch (e) {
      setState(() {
        _messages.add({
          'sender': 'AI',
          'text': 'Talebiniz işlenirken bir sorun oluştu: $e',
        });
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeManager.instance.tokens;
    final locManager = LocaleScriptManager.instance;

    return Drawer(
      backgroundColor: tokens.surface,
      width: 420,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: tokens.surfaceVariant,
                border: Border(bottom: BorderSide(color: tokens.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: tokens.primaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(Icons.smart_toy_outlined,
                            size: 18, color: tokens.primary),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          locManager.translate(
                            'nakhl_assistant_title',
                            defaultValue: 'NAKHL & NAHL Asistanı',
                          ),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: tokens.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_all, size: 18),
                        tooltip: 'Bağlam Promptunu Kopyala (Harici AI İçin)',
                        onPressed: _copyContextPrompt,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: tokens.border.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Bağlam: ${widget.moduleName} > ${widget.screenName}',
                      style: TextStyle(fontSize: 10, color: tokens.textSecondary),
                    ),
                  ),
                ],
              ),
            ),

            // Hızlı Soru Butonları
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  ActionChip(
                    label: const Text('Bu ekrana ne girmeliyim?',
                        style: TextStyle(fontSize: 11)),
                    onPressed: () => _sendQuestion('Bu ekrana ne girmeliyim?'),
                  ),
                  const SizedBox(width: 6),
                  ActionChip(
                    label: const Text('5N1K Rehberi',
                        style: TextStyle(fontSize: 11)),
                    onPressed: () => _sendQuestion('5N1K rehberini göster'),
                  ),
                  const SizedBox(width: 6),
                  ActionChip(
                    label: const Text('Sonraki adım nedir?',
                        style: TextStyle(fontSize: 11)),
                    onPressed: () => _sendQuestion('Bu işlemden sonraki adım nedir?'),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Mesaj Listesi
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isUser = msg['sender'] == 'USER';

                  return Align(
                    alignment:
                        isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      constraints: const BoxConstraints(maxWidth: 340),
                      decoration: BoxDecoration(
                        color: isUser
                            ? tokens.primaryContainer
                            : tokens.surfaceVariant,
                        borderRadius: BorderRadius.circular(tokens.borderRadius),
                        border: Border.all(
                          color: isUser ? tokens.primary : tokens.border,
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        msg['text'] ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: isUser ? tokens.primary : tokens.textPrimary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),

            // Soru Sorma Kutusu
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: tokens.surface,
                border: Border(top: BorderSide(color: tokens.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _questionController,
                      decoration: const InputDecoration(
                        hintText: 'Bir soru sorun veya işlem danışın...',
                        isDense: true,
                      ),
                      onSubmitted: (_) => _sendQuestion(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.send, color: tokens.primary),
                    onPressed: () => _sendQuestion(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
