import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/enterprise_ui_components.dart';

/// NAKHL&NAHL ERP — "Bugün Ne Yapmalıyım?" Görev Merkezi Kartı
/// 
/// Tahsilat, tedarikçi ödemesi, stok sayımı, fatura onayı ve sevkiyat gibi
/// günlük görevleri öncelik rozetleri ve tamamlama onay kutularıyla yönetir.
class TaskCenterCard extends StatefulWidget {
  const TaskCenterCard({super.key});

  @override
  State<TaskCenterCard> createState() => _TaskCenterCardState();
}

class _TaskCenterCardState extends State<TaskCenterCard> {
  final List<_TaskItem> _tasks = [
    _TaskItem(
      id: '1',
      title: 'El-Medine Hurma Ltd. Tahsilatı',
      description: '₺125.000 tutarındaki vadesi gelen fatura tahsilatı',
      module: 'Finans',
      time: '11:00',
      priority: 'high',
      isCompleted: false,
    ),
    _TaskItem(
      id: '2',
      title: 'Tedarikçi Ödemesi (Cidde Ambalaj)',
      description: '₺45.200 hammadde sevkiyat ödemesi banka transferi',
      module: 'Ödemeler',
      time: '14:30',
      priority: 'high',
      isCompleted: false,
    ),
    _TaskItem(
      id: '3',
      title: 'Dammam Depo Sukari Lot Sayımı',
      description: 'Parti No: L-2026-09 palet ve nem kontrol sayımı',
      module: 'Depo',
      time: '16:00',
      priority: 'medium',
      isCompleted: false,
    ),
    _TaskItem(
      id: '4',
      title: '3 Adet Bekleyen Satış Faturası Onayı',
      description: 'İhracat biriminden gelen ZATCA uyumlu taslaklar',
      module: 'Onaylar',
      time: '17:15',
      priority: 'medium',
      isCompleted: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return EnterpriseCard(
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
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.task_alt_rounded, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bugün Ne Yapmalıyım?',
                        style: AppTypography.cardTitle(),
                      ),
                      Text(
                        'Öncelikli operasyonel ve finansal görev listesi',
                        style: AppTypography.caption(),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                '${_tasks.where((t) => t.isCompleted).length} / ${_tasks.length} Tamamlandı',
                style: AppTypography.caption(color: AppColors.secondary).copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Görev Listesi
          ..._tasks.map((task) => _buildTaskTile(task)),
        ],
      ),
    );
  }

  Widget _buildTaskTile(_TaskItem task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: task.isCompleted ? AppColors.surfaceVariant.withOpacity(0.5) : AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Checkbox(
            value: task.isCompleted,
            activeColor: AppColors.secondary,
            onChanged: (val) {
              setState(() {
                task.isCompleted = val ?? false;
              });
            },
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      task.title,
                      style: AppTypography.caption(color: AppColors.textPrimary).copyWith(
                        fontWeight: FontWeight.w700,
                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        task.module,
                        style: AppTypography.caption(color: AppColors.primary).copyWith(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  task.description,
                  style: AppTypography.caption(
                    color: task.isCompleted ? AppColors.textMuted : AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                task.time,
                style: AppTypography.caption(color: AppColors.textSecondary).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              if (task.priority == 'high')
                StatusBadge.danger(label: 'Öncelikli', isSmall: true)
              else
                StatusBadge.info(label: 'Normal', isSmall: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _TaskItem {
  final String id;
  final String title;
  final String description;
  final String module;
  final String time;
  final String priority;
  bool isCompleted;

  _TaskItem({
    required this.id,
    required this.title,
    required this.description,
    required this.module,
    required this.time,
    required this.priority,
    required this.isCompleted,
  });
}
