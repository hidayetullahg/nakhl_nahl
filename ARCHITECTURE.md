# NAKHL&NAHL ERP — Enterprise System Architecture & Development Blueprint

> **Version:** 2.0.0-Enterprise  
> **Target Framework:** Flutter 3.19.6 / Dart 3.3.4  
> **Backend Architecture:** Multi-Tenant PostgreSQL (Supabase 2.6.0)  
> **Security Model:** Row Level Security (RLS) + Tenant Isolation + Role-Based Access Control (RBAC)  
> **Quality Gate Status:** 243/243 Tests Passing • 0 Static Analysis Issues  

---

## 1. Executive Summary & Architectural Vision

NAKHL&NAHL ERP is an **Intelligent Enterprise Operating System** designed for international multi-company trading, agricultural supply chain, halal export logistics, and executive decision intelligence. It is not merely an operational ERP, but a unified data-to-decision engine:

```
Business Transaction (Sales, Purchase, Stock, Payment)
        ↓
Data & Event Store (Ledgers, Party, Traces, Documents)
        ↓
Operational & Executive KPIs (Revenue, DSO, Yield, Margin)
        ↓
Universal Visualization (ChartEngine, Heatmaps, Gauges)
        ↓
Analytics & BI Explorer (Measures, Dimensions, Groupings)
        ↓
Formal Enterprise Report (Multi-block, Scheduled, Exportable)
        ↓
Executive Presentation Studio (Data-driven Slides, Presenter Mode)
        ↓
Strategic Management & Mind Maps (OKRs, Initiatives, Dependencies)
        ↓
Management Decision & Action (Approval Center, Task Assignment)
```

---

## 2. Forensic Audit Matrix (Phase 00)

### 2.1 Technology Stack & Platform Capabilities
| Dimension | Existing Implementation | Architectural Status |
|---|---|---|
| **Core Framework** | Flutter 3.19.6 (Dart 3.3.4) | Native cross-platform (Web, macOS, iOS, Android) |
| **Backend & DB** | Supabase Flutter 2.6.0 / PostgreSQL 15 | 62 Production SQL Migrations (Multi-tenant, RLS, Functions) |
| **Design System** | Custom Enterprise Design Tokens (`AppColors`, `AppTypography`, `AppSpacing`, `EnterpriseUiComponents`) | 8px grid, WCAG AA/AAA compliance, Dark mode support |
| **I18n & Transliteration** | `LocaleScriptManager` (TR, EN, AR-Arab, AR-Latn, UY-Arab, UY-Latn, Hybrid) | Real-time script & direction (LTR/RTL) switching |
| **State Management** | Multi-Provider / `ChangeNotifier` / `Listenable.merge` / Scoped Controllers | Clean reactive dataflow with minimal render cycles |
| **Universal Charts** | `UniversalChartEngine` (CustomPainter line, area, bar, donut, heatmap, aging) | Zero external JS/HTML overhead, 60fps Flutter canvas |
| **Static Verification** | `flutter analyze` & `flutter_lints 3.0.0` | 0 warnings, 0 errors, strict type safety |
| **Test Verification** | `flutter_test` (43 test files) | 243/243 unit, widget, and integration tests passing |

---

## 3. Directory & Bounded Context Structure

```
lib/
├── core/
│   ├── accessibility/          # A11y manager, high-contrast, motion reducers
│   ├── address/                # Hierarchical address catalogs (KSA, TR, GCC)
│   ├── coding/                 # Enterprise SKU/Lot/Barcoding generators
│   ├── config/                 # AppConfig, environment variables
│   ├── i18n/                   # Multi-locale & script transliteration engine
│   ├── legislation/            # Tax rules, ZATCA, E-Fatura, local compliance
│   ├── market/                 # FX rates, multi-currency conversion
│   ├── parameter/              # Dynamic tenant-level parameters
│   ├── tenant/                 # Multi-tenant context & isolation
│   ├── theme/                  # AppColors, AppTypography, AppBreakpoints, Tokens
│   └── time/                   # Hijri/Gregorian calendars & fiscal periods
├── features/
│   └── ai/                     # AI Gateway, Guidance, LLM advisory tools
├── models/                     # Strongly-typed domain models (Party, Sales, Ledger, etc.)
├── repositories/               # 30+ Typed data repositories (Accounting, Sales, Stock, etc.)
├── screens/
│   ├── admin/                  # Tenant management, audit logs, system setup
│   ├── approvals/              # Multi-tier Approval Center & workflows
│   ├── billing/                # Subscription plans, invoices, quotas
│   ├── integrations/           # E-Invoice, ZATCA, logistics carriers
│   ├── legislation/            # Global tax shelf & legal libraries
│   ├── migration/              # Data import/export & legacy migration wizards
│   ├── onboarding/             # 16-step guided company setup wizard
│   ├── presentation/           # Management Presentation Studio (Data-driven slides)
│   ├── settings/               # User preferences, themes, security
│   ├── strategy/               # Strategy Mind Map & OKR tracking
│   ├── dashboard_screen.dart   # Executive & operational enterprise dashboard
│   └── ...                     # Operational screens (Cari, Fatura, Stok, Sevkiyat)
├── services/                   # Business logic services (Auth, Export, Reports, ZATCA)
└── widgets/
    ├── ai/                     # AI assistant drawer & contextual hints
    ├── charts/                 # Universal Chart Engine & Canvas renderers
    ├── dashboard/              # KPI cards, quick actions, task centers
    ├── help/                   # Universal interactive help system
    └── navigation/             # AppShell, AppSidebar, AppTopBar, InsightPanel
```

---

## 4. Architectural Gap Analysis & Roadmap

| Master System Phase | Target Capability | Codebase Status | Architectural Action |
|---|---|---|---|
| **00 — Forensic Audit** | Tech audit, tree, gap analysis | **Complete** | Completed and documented in `ARCHITECTURE.md` |
| **01 — Architecture Foundation** | Typed domain interfaces, repositories | **Existing** | Expand unified `DataRepository` & `BusinessDataGraph` interfaces |
| **02 — Design System Tokens** | Central tokens, semantic color mappings | **Existing** | Align palette with `#0B4F82`, `#1479A9`, `#22A6C7` token aliases |
| **03 — Application Shell** | Responsive shell, persistent sidebar, topbar | **Existing** | Connect module routing to full ERP sidebar items |
| **04 — Command Center** | CMD+K global search & action registry | **Existing** | Enrich searchable entities across orders, invoices, and reports |
| **05 — Dashboard Engine** | Configurable widgets, layouts, filters | **Existing** | Add widget drag/resize and preset executive layouts |
| **06 — KPI Engine** | Drill-down KPIs, achievement, trends | **Existing** | Connect KPI card click events to drill-down routes |
| **07 — Universal Chart Engine** | Reusable ChartEngine, drill-down events | **Existing** | Standardize `ChartInteractionEvent` with route payloads |
| **08 — Analytics Explorer** | Data Source → Measure → Dimension → Viz | **New** | Build dedicated `/analytics` query builder |
| **09 — Pivot Engine** | Enterprise multi-dimensional pivot table | **New** | Implement interactive Flutter `PivotTable` widget |
| **10 — Enterprise DataTable** | Dense tables, column ordering, saved views | **Refactor** | Enhance table widgets with saved user views |
| **11 — Drill-Down Lineage** | Universal breadcrumbed record inspection | **New** | Implement stateful `DataLineageNavigator` |
| **12–18 — ERP Core Modules** | Sales, CRM, Finance, Stock, Production, HR | **Existing** | Connect existing repositories to unified BI data graph |
| **19–20 — Report Builder & Scheduler**| Multi-block report builder, cron scheduler | **Refactor** | Standardize `ReportDefinition` serialization |
| **21–22 — Presentation & Narrative**| Presentation Studio, auto-narratives | **Existing** | Deepen live metric bindings in `PresentationStudio` |
| **23 — AI Ready BI** | Predictive insights, deterministic narratives | **Existing** | Utilize `AIGateway` with zero-hallucination guards |
| **24–25 — Strategy & Mind Maps** | OKRs, initiatives, interactive business mind maps | **Existing** | Enhance `StrategyMindMapScreen` node ERP links |
| **26–28 — RBAC, Audit, Export** | Role permissions, audit viewer, universal export| **Existing** | Unify `ExportService` across CSV, XLSX, PDF, PNG |
| **29–33 — UX, Performance, Dark, QA**| Tablet/mobile drawer, lazy loading, A11y, QA | **Existing** | Maintain 100% test pass rate and 0 analyzer errors |
| **34 — Business Data Graph** | End-to-end entity relationship tracing | **New** | Link Customer → Order → Invoice → Payment → KPI |
| **35 — Management Decision Loop** | Observe → Understand → Decide → Act | **New** | Connect KPI anomalies to tasks and approval workflows |

---

## 5. Non-Negotiable Engineering Directives

1. **Never Break Working Code:** All 243 existing tests must remain green at every commit.
2. **Deterministic Data Lineage:** No synthetic or hardcoded numbers in executive views. Every metric derives from transactional tables or typed repository streams.
3. **No Fake Controls:** Every button, filter, and drill-down link executes a concrete action or displays an explicit empty/unconfigured state.
4. **Strict Type Safety:** Zero `dynamic` or `any` leaks. All data models implement strict immutability and JSON serializations.
5. **Phase-by-Phase Verification:** Each phase must pass `flutter analyze` and `flutter test` before progressing to the next.
