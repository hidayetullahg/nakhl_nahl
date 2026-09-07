// NAKHL & NAHL — Error Diagnostic & Corrective Action Banner
// Complies with Master Directive Section 27

import 'package:flutter/material.dart';
import '../../models/integration_models.dart';

class ErrorHelpBanner extends StatelessWidget {
  final IntegrationErrorCode errorCode;
  final String? customMessage;
  final String? technicalError;
  final VoidCallback? onFixAction;
  final String fixButtonLabel;

  const ErrorHelpBanner({
    super.key,
    required this.errorCode,
    this.customMessage,
    this.technicalError,
    this.onFixAction,
    this.fixButtonLabel = 'Şimdi Düzelt',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  errorCode.userFriendlyTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF991B1B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            customMessage ?? errorCode.suggestedResolution,
            style: const TextStyle(fontSize: 13, color: Color(0xFF7F1D1D), height: 1.4),
          ),
          if (technicalError != null && technicalError!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                title: const Text(
                  'Teknik Ayrıntılar',
                  style: TextStyle(fontSize: 12, color: Color(0xFF991B1B), fontWeight: FontWeight.w600),
                ),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF450A0A),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: SelectableText(
                      technicalError!,
                      style: const TextStyle(
                        color: Color(0xFFFCA5A5),
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (onFixAction != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                icon: const Icon(Icons.build_rounded, size: 16),
                label: Text(fixButtonLabel),
                onPressed: onFixAction,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
