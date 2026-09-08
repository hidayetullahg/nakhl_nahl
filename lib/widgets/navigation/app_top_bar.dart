import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../services/auth_service.dart';
import '../../core/tenant/tenant_context.dart';
import '../../core/i18n/locale_script_manager.dart';

/// NAKHL&NAHL ERP — Üst Gezinme Çubuğu (Enterprise TopBar)
/// 
/// 64–72px yükseklik; Şirket seçici, Küresel Arama (CMD+K),
/// Dil değiştirici, Bildirimler, AI Asistan butonu ve Kullanıcı Profili barındırır.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onOpenSearch;
  final VoidCallback onOpenAssistant;
  final VoidCallback onOpenNotifications;
  final VoidCallback? onOpenSidebarMobile;

  const AppTopBar({
    super.key,
    required this.onOpenSearch,
    required this.onOpenAssistant,
    required this.onOpenNotifications,
    this.onOpenSidebarMobile,
  });

  @override
  Size get preferredSize => const Size.fromHeight(68.0);

  @override
  Widget build(BuildContext context) {
    final activeCompany = TenantContext.instance.activeCompanyName ?? 'NAKHL&NAHL Holding A.Ş.';
    final activeBranch = TenantContext.instance.activeTenantCode ?? 'Riyadh Merkez';
    final userProfile = AuthService.instance.aktifProfil;

    return Container(
      height: preferredSize.height,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          // Mobil Çekmece Açma Butonu
          if (onOpenSidebarMobile != null)
            IconButton(
              icon: const Icon(Icons.menu_rounded, color: AppColors.primary),
              onPressed: onOpenSidebarMobile,
              tooltip: 'Menü',
            ),

          // Şirket & Şube Seçici (Multi-Company Context)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.business_rounded, size: 16, color: AppColors.secondary),
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activeCompany,
                      style: AppTypography.caption(color: AppColors.textPrimary).copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      activeBranch,
                      style: AppTypography.caption(color: AppColors.textSecondary).copyWith(
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_drop_down_rounded, size: 18, color: AppColors.textSecondary),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Küresel Arama Barı (Command Palette CMD+K)
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: InkWell(
                  onTap: onOpenSearch,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded, size: 18, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Her yerde ara (Müşteri, Fatura, Ürün, Rapor)...',
                            style: AppTypography.secondary(color: AppColors.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            '⌘ K',
                            style: AppTypography.caption(color: AppColors.textSecondary).copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Sağ İşlem Araçları: Dil, Asistan, Bildirim, Profil
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dil Seçici Butonu
              PopupMenuButton<String>(
                tooltip: 'Dil & Alfabe Seç',
                icon: const Icon(Icons.translate_rounded, color: AppColors.textSecondary, size: 20),
                onSelected: (langCode) {
                  LocaleScriptManager.instance.switchToLanguage(langCode);
                },
                itemBuilder: (ctx) {
                  return LocaleScriptManager.instance.userLanguages.map((code) {
                    final isCurrent = LocaleScriptManager.instance.activeLanguageCode == code;
                    final lang = LocaleScriptManager.languagesCatalog[code];
                    return PopupMenuItem(
                      value: code,
                      child: Row(
                        children: [
                          if (isCurrent) const Icon(Icons.check, size: 16, color: AppColors.secondary) else const SizedBox(width: 16),
                          const SizedBox(width: 8),
                          Text('${lang?.nativeName ?? code} (${code.toUpperCase()})'),
                        ],
                      ),
                    );
                  }).toList();
                },
              ),

              // Bildirim Butonu
              IconButton(
                tooltip: 'Bildirim Merkezi',
                icon: Stack(
                  children: [
                    const Icon(Icons.notifications_none_rounded, color: AppColors.textSecondary, size: 22),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
                onPressed: onOpenNotifications,
              ),

              // AI & 5N1K Asistan Butonu
              IconButton(
                tooltip: 'NAKHL Intelligence Asistanı',
                icon: const Icon(Icons.auto_awesome_rounded, color: AppColors.accent, size: 22),
                onPressed: onOpenAssistant,
              ),

              const SizedBox(width: 8),

              // Kullanıcı Profil Kartı
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 17,
                    backgroundColor: AppColors.primaryContainer,
                    child: Text(
                      userProfile?.adSoyad.isNotEmpty == true ? userProfile!.adSoyad[0].toUpperCase() : 'U',
                      style: AppTypography.badge(color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userProfile?.adSoyad ?? 'Yönetici',
                        style: AppTypography.caption(color: AppColors.textPrimary).copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        userProfile?.rol.baslik ?? 'Sistem Yöneticisi',
                        style: AppTypography.caption(color: AppColors.textSecondary).copyWith(
                          fontSize: 9.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
