import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/enterprise_ui_components.dart';

/// NAKHL&NAHL ERP — Onay Merkezi Ekranı (Approval Center)
/// 
/// Fatura onayı, satınalma onayı, ödeme onayı, iskonto onayı ve stok düzeltme onaylarını
/// talep eden, tutar, tarih, gerekçe ve [Onayla] / [Reddet] eylemleriyle yönetir.
class ApprovalCenterScreen extends StatefulWidget {
  const ApprovalCenterScreen({super.key});

  @override
  State<ApprovalCenterScreen> createState() => _ApprovalCenterScreenState();
}

class _ApprovalCenterScreenState extends State<ApprovalCenterScreen> {
  final List<_ApprovalItem> _pendingApprovals = [
    _ApprovalItem(
      id: 'APP-101',
      title: 'İhracat Faturası Onayı (INV-2026-88)',
      type: 'Satış & İhracat',
      requester: 'Ahmet Yılmaz (Satış Temsilcisi)',
      amount: '₺248.500',
      date: '08.09.2026 10:15',
      reason: 'Cidde limanı gümrükleme öncesi e-fatura taslağı kontrolü',
      status: 'PENDING',
    ),
    _ApprovalItem(
      id: 'APP-102',
      title: 'Hammadde Satınalma Siparişi (PO-2026-42)',
      type: 'Satın Alma',
      requester: 'Mehmet Demir (Satınalma Müdürü)',
      amount: '₺94.300',
      date: '08.09.2026 09:30',
      reason: 'Medjool 1. kalite hurma kutu ambalaj siparişi avansı',
      status: 'PENDING',
    ),
    _ApprovalItem(
      id: 'APP-103',
      title: 'Müşteri Özel İskonto Talebi (%8.5)',
      type: 'İskonto Onayı',
      requester: 'Zeynep Kaya (Bölge Satış)',
      amount: '₺18.200 İskonto',
      date: '07.09.2026 16:45',
      reason: 'Yıllık 100 ton taahhütlü kurumsal müşteri anlaşması',
      status: 'PENDING',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.fact_check_rounded, color: Colors.black, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Onay Merkezi', style: AppTypography.cardTitle(color: Colors.white)),
                Text('${_pendingApprovals.length} bekleyen onay talebi', style: AppTypography.caption(color: Colors.white70)),
              ],
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Bekleyen Onay İstekleri', style: AppTypography.sectionTitle()),
              StatusBadge.warning(label: '${_pendingApprovals.length} Aksiyon Bekliyor'),
            ],
          ),
          const SizedBox(height: 16),
          ..._pendingApprovals.map((item) => _buildApprovalCard(item)),
        ],
      ),
    );
  }

  Widget _buildApprovalCard(_ApprovalItem item) {
    return EnterpriseCard(
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.assignment_turned_in_rounded, size: 18, color: AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: AppTypography.cardTitle()),
                      Text('Talep Eden: ${item.requester} • ${item.date}', style: AppTypography.caption()),
                    ],
                  ),
                ],
              ),
              Text(item.amount, style: AppTypography.kpiNumberSm(color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Gerekçe: ${item.reason}',
                    style: AppTypography.secondary(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  setState(() => _pendingApprovals.remove(item));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${item.id} revizyon talebi gönderildi.')),
                  );
                },
                icon: const Icon(Icons.history_rounded, size: 16, color: AppColors.textSecondary),
                label: const Text('Revizyon İste', style: TextStyle(color: AppColors.textSecondary)),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() => _pendingApprovals.remove(item));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${item.id} talebi reddedildi.')),
                  );
                },
                icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.danger),
                label: const Text('Reddet', style: TextStyle(color: AppColors.danger)),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() => _pendingApprovals.remove(item));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${item.id} başarıyla onaylandı ve ilgili modüle iletildi.')),
                  );
                },
                icon: const Icon(Icons.check_rounded, size: 16),
                label: const Text('Onayla'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ApprovalItem {
  final String id;
  final String title;
  final String type;
  final String requester;
  final String amount;
  final String date;
  final String reason;
  String status;

  _ApprovalItem({
    required this.id,
    required this.title,
    required this.type,
    required this.requester,
    required this.amount,
    required this.date,
    required this.reason,
    required this.status,
  });
}
