import 'package:flutter/material.dart';
import '../../core/theme/app_theme_tokens.dart';

/// Form alanları için zengin metadata ve AI rehberlik modeli
class FormFieldMetadata {
  final String fieldId;
  final String label;
  final String description;
  final bool isRequired;
  final String dataType;
  final String? example;
  final String? legalRequirement;
  final String? accountingEffect;
  final String? aiHelpPrompt;

  const FormFieldMetadata({
    required this.fieldId,
    required this.label,
    required this.description,
    this.isRequired = false,
    required this.dataType,
    this.example,
    this.legalRequirement,
    this.accountingEffect,
    this.aiHelpPrompt,
  });
}

/// Form alanlarının yanına yerleştirilen interaktif AI / Yardım ikonu
class FieldHelpIcon extends StatelessWidget {
  final FormFieldMetadata metadata;

  const FieldHelpIcon({
    super.key,
    required this.metadata,
  });

  void _showFieldHelpDialog(BuildContext context) {
    final tokens = AppThemeManager.instance.tokens;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: tokens.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.help_outline, size: 18, color: tokens.primary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${metadata.label} — Alan Kılavuzu',
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    metadata.description,
                    style: TextStyle(fontSize: 13, color: tokens.textPrimary),
                  ),
                  const SizedBox(height: 14),
                  _infoRow('Zorunluluk Durumu:',
                      metadata.isRequired ? 'Zorunlu Alan (*)' : 'Opsiyonel / İsteğe Bağlı', tokens),
                  _infoRow('Veri Tipi:', metadata.dataType, tokens),
                  if (metadata.example != null)
                    _infoRow('Örnek Giriş:', metadata.example!, tokens),
                  if (metadata.legalRequirement != null)
                    _infoRow('Mevzuat Dayanağı:', metadata.legalRequirement!, tokens),
                  if (metadata.accountingEffect != null)
                    _infoRow('Muhasebe Etkisi:', metadata.accountingEffect!, tokens),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Anladım'),
            ),
          ],
        );
      },
    );
  }

  Widget _infoRow(String label, String value, AppThemeTokens tokens) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: tokens.textMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: tokens.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.help_outline, size: 16),
      color: const Color(0xFF9CA3AF),
      tooltip: '${metadata.label} hakkında bilgi al',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
      onPressed: () => _showFieldHelpDialog(context),
    );
  }
}
