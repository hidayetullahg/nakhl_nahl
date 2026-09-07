// NAKHL & NAHL — Form Field Help Icon (Contextual Inline Guidance)
// Complies with Master Directive Section 28

import 'package:flutter/material.dart';

class FormFieldHelpIcon extends StatelessWidget {
  final String label;
  final String helpText;

  const FormFieldHelpIcon({
    super.key,
    required this.label,
    required this.helpText,
  });

  /// Factory helper for VKN (Vergi Kimlik Numarası)
  factory FormFieldHelpIcon.vkn() => const FormFieldHelpIcon(
        label: 'VKN',
        helpText: 'Türkiye\'de tüzel kişi kurumlar için 10 haneli Vergi Kimlik Numarası.',
      );

  /// Factory helper for TCKN (T.C. Kimlik Numarası)
  factory FormFieldHelpIcon.tckn() => const FormFieldHelpIcon(
        label: 'TCKN',
        helpText: 'Gerçek kişi müşteriler için 11 haneli T.C. Kimlik Numarası.',
      );

  /// Factory helper for CSID (ZATCA Cryptographic Stamp Identifier)
  factory FormFieldHelpIcon.csid() => const FormFieldHelpIcon(
        label: 'CSID',
        helpText: 'ZATCA Phase 2 Fatoora üretim ortamında kullanılan Kriptografik Damga Kimliğidir (Asla paylaşılmamalıdır).',
      );

  /// Factory helper for VAT (KDV / Katma Değer Vergisi)
  factory FormFieldHelpIcon.vat() => const FormFieldHelpIcon(
        label: 'KDV',
        helpText: 'Mevzuata uygun KDV oranı (%1, %10, %20). Fatura resmiyet kazandıktan sonra değiştirilemez.',
      );

  /// Factory helper for IBAN
  factory FormFieldHelpIcon.iban() => const FormFieldHelpIcon(
        label: 'IBAN',
        helpText: 'Tedarikçi veya şirket banka hesabının 26 haneli uluslararası hesap numarası (TR ile başlar).',
      );

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: helpText,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      child: Container(
        margin: const EdgeInsets.only(left: 6),
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.info_outline_rounded,
          size: 14,
          color: Color(0xFF475569),
        ),
      ),
    );
  }
}
