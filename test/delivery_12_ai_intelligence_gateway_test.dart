// ==============================================================================
// NAKHL & NAHL — DELIVERY 12: AI & INTELLIGENCE INTEGRATION LAYER TEST SUITE
// ==============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:nakhl_nahl/features/ai/ai_provider.dart';
import 'package:nakhl_nahl/features/ai/ai_gateway.dart';
import 'package:nakhl_nahl/features/ai/ai_router.dart';
import 'package:nakhl_nahl/features/ai/prompt_library.dart';
import 'package:nakhl_nahl/features/ai/guidance/five_w_one_h_guidance.dart';
import 'package:nakhl_nahl/features/ai/tools/erp_tool_registry.dart';

void main() {
  setUp(() {
    AIGateway.instance.initializeDefaults();
    ERPToolRegistry.instance.initializeDefaults();
  });

  group('Delivery 12: AI Intelligence, Gateway & Multi-Tenant Security', () {
    test('AI Gateway registers multiple providers (OpenAI, Gemini, Claude, DeepSeek, LocalAI)', () {
      final gateway = AIGateway.instance;
      expect(gateway.providers.length, greaterThanOrEqualTo(5));

      final openai = gateway.getProvider(AIProviderType.openAI);
      final gemini = gateway.getProvider(AIProviderType.gemini);
      final claude = gateway.getProvider(AIProviderType.claude);

      expect(openai?.capabilities.supportsTools, isTrue);
      expect(gemini?.capabilities.supportsVision, isTrue);
      expect(claude?.capabilities.supportsStructuredOutput, isTrue);
    });

    test('AIRouter routes tasks appropriately to task-specific providers', () {
      final router = AIRouter.instance;
      final accModel = router.routeTask(AITaskType.accounting);
      final legalModel = router.routeTask(AITaskType.legal);
      final transModel = router.routeTask(AITaskType.translation);

      expect(accModel, equals(AIProviderType.openAI));
      expect(legalModel, equals(AIProviderType.claude));
      expect(transModel, equals(AIProviderType.qwen));
    });

    test('PromptLibrary creates dynamic context prompt suitable for copy-paste export', () {
      final prompt = PromptLibrary.createDynamicSystemContext(
        country: 'Saudi Arabia',
        company: 'NAKHL & NAHL Trading Ltd.',
        branch: 'Riyadh Central',
        currentModule: 'export',
        currentScreen: 'shipment_preparation',
        userRole: 'Accountant',
        locale: 'tr-Latn',
      );

      expect(prompt, contains('NAKHL & NAHL'));
      expect(prompt, contains('Saudi Arabia'));
      expect(prompt, contains('Riyadh Central'));
      expect(prompt, contains('Accountant'));
      expect(prompt, contains('NE?'));
      expect(prompt, contains('NEDEN?'));
      expect(prompt, contains('Supabase/PostgreSQL'));
    });

    test('FiveWOneHGuidance generates structured 5N1K actionable guidance', () {
      final guide = FiveWOneHGuidance.getGuidanceForScreen(
        module: 'export',
        screen: 'shipment',
        country: 'SA',
      );

      expect(guide.what, isNotEmpty);
      expect(guide.why, isNotEmpty);
      expect(guide.where, isNotEmpty);
      expect(guide.when, isNotEmpty);
      expect(guide.how, isNotEmpty);
      expect(guide.who, isNotEmpty);
      expect(guide.requiredDocuments.isNotEmpty, isTrue);
      expect(guide.nextStep, isNotEmpty);
    });

    test('ERPToolRegistry contains safe tools and forbids raw destructive SQL execution', () {
      final registry = ERPToolRegistry.instance;
      final tools = registry.tools;

      final toolNames = tools.map((t) => t.name).toList();
      expect(toolNames, contains('get_exchange_rate'));
      expect(toolNames, contains('get_gold_price'));
      expect(toolNames, contains('search_legal_rules'));
      expect(toolNames, contains('create_invoice_draft'));

      // Raw SQL execution is strictly excluded from AI tool registry
      expect(toolNames, isNot(contains('execute_sql')));
      expect(toolNames, isNot(contains('run_query')));
      expect(toolNames, isNot(contains('drop_table')));

      // Tool execution with draft action level creates draft safely
      final result = registry.executeTool(
        toolName: 'create_invoice_draft',
        parameters: {'customer': 'Al-Madinah Trading', 'total': 15000},
        tenantId: 'TENANT_001',
      );

      expect(result.isSuccess, isTrue);
      expect(result.data?['status'], equals('DRAFT'));
    });
  });
}
