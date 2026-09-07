// NAKHL & NAHL — Universal Help Tooltip Widget
// Complies with Master Directive Sections 15, 16, 48, 49, 50

import 'package:flutter/material.dart';
import '../../models/help_models.dart';
import '../../services/help/help_controller.dart';
import '../../services/help/help_registry.dart';
import 'help_drawer.dart';

class HelpTooltip extends StatelessWidget {
  final String? helpId;
  final String? route;
  final String? title;
  final String? shortDescription;
  final List<String>? steps;
  final Color? iconColor;
  final double iconSize;

  const HelpTooltip({
    super.key,
    this.helpId,
    this.route,
    this.title,
    this.shortDescription,
    this.steps,
    this.iconColor,
    this.iconSize = 18.0,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: HelpController(),
      builder: (context, _) {
        final controller = HelpController();
        if (!controller.isHelpVisible) {
          return const SizedBox.shrink();
        }

        // Determine content
        HelpContent? resolvedContent;
        if (helpId != null) {
          try {
            resolvedContent = HelpRegistry.defaultContents.firstWhere((c) => c.id == helpId);
          } catch (_) {}
        }
        if (resolvedContent == null && route != null) {
          resolvedContent = HelpRegistry().getContentByRoute(route!);
        }

        final effectiveTitle = title ?? resolvedContent?.title ?? 'Yardım';
        final effectiveDesc = shortDescription ?? resolvedContent?.shortDescription ?? 'Bu alan hakkında bilgi almak için tıklayın.';

        final tooltipMessage = '$effectiveTitle\n\n$effectiveDesc\n(Detaylı kılavuz için tıklayın)';

        return Semantics(
          label: '$effectiveTitle yardım bilgisi',
          button: true,
          child: Tooltip(
            message: tooltipMessage,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            margin: const EdgeInsets.all(8),
            textStyle: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                if (resolvedContent != null) {
                  controller.openDrawer(resolvedContent);
                  HelpDrawer.show(context, resolvedContent);
                } else {
                  // Fallback content on the fly
                  final fallback = HelpContent(
                    id: 'adhoc_help',
                    route: route ?? '/',
                    menuKey: 'adhoc',
                    title: effectiveTitle,
                    shortDescription: effectiveDesc,
                    longDescription: effectiveDesc,
                    steps: (steps ?? [])
                        .asMap()
                        .entries
                        .map((e) => HelpStep(step: e.key + 1, title: 'Adım ${e.key + 1}', desc: e.value))
                        .toList(),
                    searchableText: effectiveTitle,
                  );
                  controller.openDrawer(fallback);
                  HelpDrawer.show(context, fallback);
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Icon(
                  Icons.help_outline_rounded,
                  size: iconSize,
                  color: iconColor ?? Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
