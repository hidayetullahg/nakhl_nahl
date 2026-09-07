// NAKHL & NAHL — Universal Empty State Guidance Component
// Complies with Master Directive Section 26

import 'package:flutter/material.dart';
import '../../services/help/help_controller.dart';
import '../../services/help/help_registry.dart';
import 'help_drawer.dart';

class EmptyStateHelp extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String primaryActionLabel;
  final VoidCallback onPrimaryAction;
  final String? helpRoute;
  final String? helpId;

  const EmptyStateHelp({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.primaryActionLabel,
    required this.onPrimaryAction,
    this.helpRoute,
    this.helpId,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: const Color(0xFF0F172A)),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(primaryActionLabel),
                  onPressed: onPrimaryAction,
                ),
                if (helpRoute != null || helpId != null)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.help_outline_rounded, size: 18),
                    label: const Text('❓ Nasıl yapılır?'),
                    onPressed: () {
                      final content = helpId != null
                          ? HelpRegistry.defaultContents.firstWhere(
                              (c) => c.id == helpId,
                              orElse: () => HelpRegistry.defaultContents.first,
                            )
                          : HelpRegistry().getContentByRoute(helpRoute ?? '/');
                      if (content != null) {
                        HelpController().openDrawer(content);
                        HelpDrawer.show(context, content);
                      }
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
