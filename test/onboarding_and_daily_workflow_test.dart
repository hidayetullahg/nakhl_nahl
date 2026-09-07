// ==============================================================================
// NAKHL & NAHL — ONBOARDING VE GÜNLÜK İŞLETME İŞ AKIŞI TESTLERİ
// Complies with Master Prompt Sections 4-23, 52, 65, 82, 86
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nakhl_nahl/services/opening_balance_service.dart';
import 'package:nakhl_nahl/screens/onboarding/first_time_setup_screen.dart';

void main() {
  group('1. OpeningBalanceService & Snapshot Tests', () {
    test('Calculates net worth and liquid assets correctly', () {
      final snapshot = BusinessSnapshot(
        totalCash: 50000.0,
        totalBank: 200000.0,
        pocketCash: 10000.0,
        totalReceivables: 150000.0,
        totalPayables: 75000.0,
        totalInventoryValue: 300000.0,
        customerCount: 10,
        supplierCount: 5,
        productCount: 20,
        warehouseCount: 2,
        branchCount: 1,
        openingDate: DateTime.now(),
        currency: 'SAR',
      );

      // Total assets: 50k + 200k + 10k + 150k + 300k = 710k
      // Net worth: 710k - 75k = 635k
      expect(snapshot.netWorth, equals(635000.0));
      // Liquid assets: 50k + 200k + 10k = 260k
      expect(snapshot.totalLiquidAssets, equals(260000.0));
    });

    test('Identifies setup deficiencies correctly', () {
      final service = OpeningBalanceService.instance;

      // Null snapshot check
      service.saveSnapshot(BusinessSnapshot(
        totalCash: 0,
        totalBank: 0,
        pocketCash: 0,
        totalReceivables: 0,
        totalPayables: 0,
        totalInventoryValue: 0,
        customerCount: 0,
        supplierCount: 0,
        productCount: 0,
        warehouseCount: 0,
        branchCount: 0,
        openingDate: DateTime(2026, 1, 1),
        currency: 'SAR',
      ));

      final deficiencies = service.getSetupDeficiencies();
      expect(deficiencies.contains('Kasa nakit bakiyesi tanımlanmadı.'), isTrue);
      expect(deficiencies.contains('Banka hesabı tanımlanmadı.'), isTrue);
      expect(deficiencies.contains('Operasyonel depo tanımlanmadı.'), isTrue);
      expect(deficiencies.contains('Kayıtlı ürün/hizmet kartı bulunmuyor.'), isTrue);
      expect(deficiencies.contains('Açılış stokları girilmedi.'), isTrue);
    });

    test('Manages daily checklist items and toggling', () {
      final service = OpeningBalanceService.instance;
      final initialList = service.dailyChecklist;

      expect(initialList.length, equals(10));
      expect(initialList.any((x) => x.id == 'kasa_kontrol'), isTrue);
      expect(initialList.any((x) => x.id == 'gun_sonu'), isTrue);

      final initialCompleted = initialList.first.isCompleted;
      service.toggleChecklistItem('kasa_kontrol');
      expect(service.dailyChecklist.first.isCompleted, equals(!initialCompleted));
    });

    test('Initializes demo snapshot for testing and evaluation', () {
      final service = OpeningBalanceService.instance;
      service.initializeDemoSnapshot(currency: 'SAR');

      final snap = service.currentSnapshot;
      expect(snap, isNotNull);
      expect(snap!.totalCash, equals(45000.0));
      expect(snap.totalBank, equals(185000.0));
      expect(snap.currency, equals('SAR'));
      expect(snap.netWorth, greaterThan(0));
    });
  });

  group('2. FirstTimeSetupScreen Widget Tests', () {
    testWidgets('Renders initial step with language choices and title',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: FirstTimeSetupScreen(),
        ),
      );

      expect(find.text('1. Hangi Dillerde Kullanmak İstiyorsunuz?'), findsOneWidget);
      expect(find.text('Türkçe'), findsWidgets);
      expect(find.text('Devam Et'), findsOneWidget);
      expect(find.text('Yardım Al'), findsOneWidget);
    });

    testWidgets('Navigates through setup steps on Devam Et button tap',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: FirstTimeSetupScreen(),
        ),
      );

      // Step 1 -> Step 2
      final nextBtn = find.text('Devam Et');
      expect(nextBtn, findsOneWidget);
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();

      expect(find.text('2. Dil Alfabesi ve Yazı Sistemi Seçimi'), findsOneWidget);
      expect(find.text('Latin Alfabesi (LTR)'), findsOneWidget);

      // Step 2 -> Step 3
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();

      expect(find.text('3. Faaliyet Gösterilen Ülkeler'), findsOneWidget);
      expect(find.text('Suudi Arabistan (KSA)'), findsOneWidget);
    });

    testWidgets('Shows help dialog when Yardım Al is clicked',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: FirstTimeSetupScreen(),
        ),
      );

      final helpBtn = find.text('Yardım Al');
      expect(helpBtn, findsOneWidget);
      await tester.tap(helpBtn);
      await tester.pumpAndSettle();

      expect(find.text('Kurulum Rehberi'), findsOneWidget);
      expect(find.text('Anladım'), findsOneWidget);

      await tester.tap(find.text('Anladım'));
      await tester.pumpAndSettle();
      expect(find.text('Kurulum Rehberi'), findsNothing);
    });
  });
}
