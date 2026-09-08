import 'package:flutter/material.dart';
import '../../core/parameter/parameter_model.dart';
import '../../core/parameter/parameter_scope.dart';
import '../../core/theme/app_theme_tokens.dart';
import '../../services/parameter/dynamic_parameter_service.dart';

class ParameterManagementScreen extends StatefulWidget {
  const ParameterManagementScreen({super.key});

  @override
  State<ParameterManagementScreen> createState() =>
      _ParameterManagementScreenState();
}

class _ParameterManagementScreenState extends State<ParameterManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: ParameterDomain.values.length + 1,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showAddParameterDialog() {
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    final defaultValController = TextEditingController();
    final descController = TextEditingController();
    final allowedValuesController = TextEditingController();

    ParameterDomain selectedDomain = ParameterDomain.accounting;
    ParameterDataType selectedType = ParameterDataType.string;
    ParameterScope selectedScope = ParameterScope.company;
    bool isRequired = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final tokens = AppThemeManager.instance.tokens;

            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.tune_rounded, color: Color(0xFFD4AF37)),
                  SizedBox(width: 8),
                  Text('Yeni ERP Parametresi Ekle'),
                ],
              ),
              content: SizedBox(
                width: 550,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Yeni parametre tüm yetkili kullanıcılar ve kapsamlar için anında yürürlüğe girer.',
                        style: TextStyle(fontSize: 12, color: tokens.textMuted),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Parametre Adı *',
                          hintText: 'Örn: Maksimum Sipariş Vadesi (Gün)',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: codeController,
                        decoration: const InputDecoration(
                          labelText: 'Parametre Kodu (Sistem Anahtarı) *',
                          hintText: 'Örn: MAX_ORDER_PAYMENT_TERMS_DAYS',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<ParameterDomain>(
                              value: selectedDomain,
                              decoration: const InputDecoration(labelText: 'Domain / Alan'),
                              items: ParameterDomain.values.map((d) {
                                return DropdownMenuItem(
                                  value: d,
                                  child: Text(d.label, overflow: TextOverflow.ellipsis),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() => selectedDomain = val);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<ParameterDataType>(
                              value: selectedType,
                              decoration: const InputDecoration(labelText: 'Veri Tipi'),
                              items: ParameterDataType.values.map((t) {
                                return DropdownMenuItem(
                                  value: t,
                                  child: Text(t.label),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() => selectedType = val);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<ParameterScope>(
                              value: selectedScope,
                              decoration: const InputDecoration(labelText: 'Öncelikli Kapsam (Scope)'),
                              items: ParameterScope.values.map((s) {
                                return DropdownMenuItem(
                                  value: s,
                                  child: Text('${s.label} (${s.code})'),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() => selectedScope = val);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: defaultValController,
                        decoration: const InputDecoration(
                          labelText: 'Varsayılan Değer *',
                          hintText: 'Örn: 90',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: allowedValuesController,
                        decoration: const InputDecoration(
                          labelText: 'İzin Verilen Değerler (Virgülle ayırın)',
                          hintText: 'Örn: 30, 60, 90, 120',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Açıklama & Hukuki / Operasyonel Gerekçe',
                          hintText: 'Parametrenin kullanım amacını açıklayın...',
                        ),
                      ),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: isRequired,
                        title: const Text('Bu parametre işlemlerde zorunludur'),
                        onChanged: (v) =>
                            setDialogState(() => isRequired = v ?? false),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('İptal'),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('Kaydet ve Etkinleştir'),
                  onPressed: () {
                    final name = nameController.text.trim();
                    final code = codeController.text.trim().toUpperCase();
                    final defVal = defaultValController.text.trim();

                    if (name.isEmpty || code.isEmpty || defVal.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Lütfen zorunlu alanları (*) doldurun.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final allowedList = allowedValuesController.text
                        .split(',')
                        .map((e) => e.trim())
                        .where((e) => e.isNotEmpty)
                        .toList();

                    final newParam = ParameterDefinition(
                      id: 'param_${DateTime.now().millisecondsSinceEpoch}',
                      code: code,
                      name: name,
                      domain: selectedDomain,
                      dataType: selectedType,
                      defaultValue: defVal,
                      allowedValues: allowedList,
                      isRequired: isRequired,
                      description: descController.text.trim(),
                      scope: selectedScope,
                      isActive: true,
                    );

                    DynamicParameterService.instance.addParameter(newParam);
                    Navigator.pop(ctx);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✓ Parametre $code başarıyla kaydedildi.'),
                        backgroundColor: const Color(0xFF10B981),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditValueDialog(ParameterDefinition param) {
    final valueController =
        TextEditingController(text: param.effectiveValue?.toString() ?? '');
    ParameterScope selectedScope = param.scope;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('${param.name} — Değer Güncelle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Kod: ${param.code}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (param.allowedValues.isNotEmpty) ...[
                const Text('İzin Verilen Değerler:'),
                Wrap(
                  spacing: 6,
                  children: param.allowedValues.map((v) {
                    return ActionChip(
                      label: Text(v),
                      onPressed: () => valueController.text = v,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: valueController,
                decoration: InputDecoration(
                  labelText: 'Yeni Değer',
                  hintText: 'Varsayılan: ${param.defaultValue}',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                DynamicParameterService.instance.updateParameterValue(
                  param.code,
                  valueController.text.trim(),
                  scope: selectedScope,
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✓ Parametre değeri güncellendi.'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              },
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeManager.instance.tokens;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kurumsal Parametre Yönetimi'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: ElevatedButton.icon(
              onPressed: _showAddParameterDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Yeni Parametre'),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            const Tab(text: 'Tümü'),
            ...ParameterDomain.values.map((d) => Tab(text: d.label)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Arama Çubuğu
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Parametre adı, kodu veya açıklamasında ara...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),

          // Parametre Listesi
          Expanded(
            child: AnimatedBuilder(
              animation: DynamicParameterService.instance,
              builder: (context, _) {
                return TabBarView(
                  controller: _tabController,
                  children: [
                    // Tümü
                    _buildParameterList(null, tokens),
                    // Her domain ayrı tab
                    ...ParameterDomain.values.map((d) {
                      return _buildParameterList(d, tokens);
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParameterList(ParameterDomain? domain, AppThemeTokens tokens) {
    final service = DynamicParameterService.instance;
    List<ParameterDefinition> list;

    if (domain == null) {
      list = _searchQuery.isEmpty
          ? service.allDefinitions
          : service.searchParameters(_searchQuery);
    } else {
      list = service.getParametersByDomain(domain);
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        list = list
            .where((p) =>
                p.name.toLowerCase().contains(q) ||
                p.code.toLowerCase().contains(q))
            .toList();
      }
    }

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.tune_outlined, size: 48, color: tokens.textMuted),
            const SizedBox(height: 12),
            Text('Eşleşen parametre bulunamadı.',
                style: TextStyle(color: tokens.textMuted)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final param = list[index];
        return Card(
          elevation: tokens.cardElevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tokens.borderRadius),
            side: BorderSide(color: tokens.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: tokens.primaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        param.code,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: tokens.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: tokens.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        param.scope.label,
                        style: TextStyle(fontSize: 10, color: tokens.textMuted),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      tooltip: 'Değeri Düzenle',
                      onPressed: () => _showEditValueDialog(param),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  param.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: tokens.textPrimary,
                  ),
                ),
                if (param.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    param.description,
                    style: TextStyle(fontSize: 12, color: tokens.textSecondary),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('Yürürlükteki Değer: ',
                        style:
                            TextStyle(fontSize: 12, color: tokens.textMuted)),
                    Text(
                      '${param.effectiveValue}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: tokens.success,
                      ),
                    ),
                    if (param.currentValue != null &&
                        param.currentValue != param.defaultValue) ...[
                      const SizedBox(width: 8),
                      Text(
                        '(Varsayılan: ${param.defaultValue})',
                        style: TextStyle(fontSize: 11, color: tokens.textMuted),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
