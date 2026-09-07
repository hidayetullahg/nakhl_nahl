// NAKHL & NAHL — Universal Help & Guidance System Unit and Widget Tests
// Complies with Master Directive Sections 12-28, 40

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nakhl_nahl/models/help_models.dart';
import 'package:nakhl_nahl/models/integration_models.dart';
import 'package:nakhl_nahl/services/help/help_registry.dart';
import 'package:nakhl_nahl/services/help/help_controller.dart';
import 'package:nakhl_nahl/widgets/help/help_tooltip.dart';
import 'package:nakhl_nahl/widgets/help/help_drawer.dart';
import 'package:nakhl_nahl/widgets/help/onboarding_wizard_dialog.dart';
import 'package:nakhl_nahl/widgets/help/empty_state_help.dart';
import 'package:nakhl_nahl/widgets/help/error_help_banner.dart';
import 'package:nakhl_nahl/widgets/help/form_field_help_icon.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('1. HelpRegistry Knowledge Coverage Tests', () {
    final registry = HelpRegistry();

    test('Registry contains all core ERP modules', () {
      final items = HelpRegistry.defaultContents;
      expect(items.length, greaterThanOrEqualTo(10));

      final routes = items.map((c) => c.route).toList();
      expect(routes.contains('/customers'), isTrue);
      expect(routes.contains('/inventory/products'), isTrue);
      expect(routes.contains('/inventory/stocks'), isTrue);
      expect(routes.contains('/sales/invoices'), isTrue);
      expect(routes.contains('/settings/integrations'), isTrue);
      expect(routes.contains('/accounting/ledger'), isTrue);
      expect(routes.contains('/pos'), isTrue);
      expect(routes.contains('/settings/backup'), isTrue);
    });

    test('Route lookup returns appropriate content', () {
      final customerHelp = registry.getContentByRoute('/customers');
      expect(customerHelp, isNotNull);
      expect(customerHelp!.title.contains('Müşteri'), isTrue);
      expect(customerHelp.steps.isNotEmpty, isTrue);

      final invoiceHelp = registry.getContentByRoute('/sales/invoices');
      expect(invoiceHelp, isNotNull);
      expect(invoiceHelp!.title.contains('Fatura'), isTrue);
    });

    test('Search with keyword synonym expansion works', () {
      // Query 'fatura kesmek' should find Invoices and E-Invoice
      final faturaResults = registry.search('fatura kesmek');
      expect(faturaResults.isNotEmpty, isTrue);
      expect(faturaResults.any((c) => c.route == '/sales/invoices'), isTrue);

      // Query 'stok' should find stocks and products
      final stokResults = registry.search('stok');
      expect(stokResults.isNotEmpty, isTrue);
      expect(stokResults.any((c) => c.route == '/inventory/stocks'), isTrue);

      // Query 'müşteri' should find customers
      final cariResults = registry.search('müşteri');
      expect(cariResults.isNotEmpty, isTrue);
      expect(cariResults.any((c) => c.route == '/customers'), isTrue);
    });

    test('Task-based guides are loaded', () {
      expect(HelpRegistry.taskGuides.isNotEmpty, isTrue);
      final firstSaleGuide = HelpRegistry.taskGuides.firstWhere((g) => g.id == 'task_first_sale');
      expect(firstSaleGuide.steps.length, 5);
      expect(firstSaleGuide.targetRoute, '/sales/invoices');
    });
  });

  group('2. HelpController State Tests', () {
    final controller = HelpController();

    test('Controller toggles HelpMode correctly', () {
      controller.setHelpMode(HelpMode.off);
      expect(controller.mode, HelpMode.off);
      expect(controller.isHelpVisible, isFalse);

      controller.setHelpMode(HelpMode.detailed);
      expect(controller.mode, HelpMode.detailed);
      expect(controller.isHelpVisible, isTrue);
      expect(controller.isDetailedHelp, isTrue);
    });

    test('Controller handles drawer opening and closing', () {
      final sample = HelpRegistry.defaultContents.first;
      controller.openDrawer(sample);
      expect(controller.isDrawerOpen, isTrue);
      expect(controller.activeContent?.id, sample.id);

      controller.closeDrawer();
      expect(controller.isDrawerOpen, isFalse);
    });

    test('Wizard step completion marks progress', () {
      controller.markWizardStepCompleted(1);
      expect(controller.completedWizardSteps.containsKey('step_1'), isTrue);

      controller.markWizardStepCompleted(2);
      expect(controller.completedWizardSteps.length, greaterThanOrEqualTo(2));
    });
  });

  group('3. Help UI Components Widget Tests', () {
    testWidgets('HelpTooltip widget renders and responds to tap', (tester) async {
      HelpController().setHelpMode(HelpMode.detailed);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: HelpTooltip(
                title: 'Test Başlık',
                shortDescription: 'Test açıklama',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(HelpTooltip), findsOneWidget);
      expect(find.byIcon(Icons.help_outline_rounded), findsOneWidget);

      // Tap on help icon opens drawer
      await tester.tap(find.byType(HelpTooltip));
      await tester.pumpAndSettle();

      expect(find.text('Test Başlık'), findsOneWidget);
    });

    testWidgets('HelpDrawer renders structured guidance steps and tips', (tester) async {
      const content = HelpContent(
        id: 'test_drawer',
        route: '/test',
        menuKey: 'test',
        title: 'Müşteri Kılavuzu',
        shortDescription: 'Kısa bilgi',
        longDescription: 'Detaylı rehber açıklaması.',
        steps: [
          HelpStep(step: 1, title: 'Adım 1 Başlık', desc: 'Adım 1 Detay'),
          HelpStep(step: 2, title: 'Adım 2 Başlık', desc: 'Adım 2 Detay'),
        ],
        warnings: ['Bu işlem geri alınamaz.'],
        tips: ['Kısayol tuşlarını kullanabilirsiniz.'],
        searchableText: 'test',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HelpDrawer(content: content),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Müşteri Kılavuzu'), findsOneWidget);
      expect(find.text('Bu Ekran Ne İşe Yarar?'), findsOneWidget);
      expect(find.text('Adım 1 Başlık'), findsOneWidget);
      expect(find.text('Adım 2 Başlık'), findsOneWidget);
      expect(find.text('Bu işlem geri alınamaz.'), findsOneWidget);
      expect(find.text('Kısayol tuşlarını kullanabilirsiniz.'), findsOneWidget);
    });

    testWidgets('OnboardingWizardDialog displays 15 steps', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OnboardingWizardDialog(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('NAKHL & NAHL Kurulum ve Başlangıç Sihirbazı'), findsOneWidget);
      expect(find.text('Şirketinizi Oluşturun'), findsWidgets);
      expect(find.text('ADIM 1 / 15'), findsOneWidget);
      expect(find.text('Sonraki'), findsOneWidget);

      // Advance step
      await tester.tap(find.text('Sonraki'));
      await tester.pumpAndSettle();
      expect(find.text('ADIM 2 / 15'), findsOneWidget);
      expect(find.text('Şube Oluşturun'), findsWidgets);
    });

    testWidgets('EmptyStateHelp widget renders with actions', (tester) async {
      bool actionTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateHelp(
              icon: Icons.inventory_2_outlined,
              title: 'Henüz Ürününüz Yok',
              description: 'İlk ürününüzü tanımlayarak satışa başlayın.',
              primaryActionLabel: 'Yeni Ürün Ekle',
              onPrimaryAction: () => actionTapped = true,
              helpRoute: '/inventory/products',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Henüz Ürününüz Yok'), findsOneWidget);
      expect(find.text('Yeni Ürün Ekle'), findsOneWidget);
      expect(find.text('❓ Nasıl yapılır?'), findsOneWidget);

      await tester.tap(find.text('Yeni Ürün Ekle'));
      expect(actionTapped, isTrue);
    });

    testWidgets('ErrorHelpBanner renders error diagnostics and fix button', (tester) async {
      bool fixTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorHelpBanner(
              errorCode: IntegrationErrorCode.authenticationError,
              onFixAction: () => fixTapped = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Kimlik Doğrulama Hatası (API / Token Geçersiz)'), findsOneWidget);
      expect(find.text('Şimdi Düzelt'), findsOneWidget);

      await tester.tap(find.text('Şimdi Düzelt'));
      expect(fixTapped, isTrue);
    });

    testWidgets('FormFieldHelpIcon renders tooltip message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: FormFieldHelpIcon.vkn(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(FormFieldHelpIcon), findsOneWidget);
      expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
    });
  });
}
