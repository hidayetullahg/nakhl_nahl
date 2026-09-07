# NAKHL&NAHL Universal Help, Education & Contextual Guidance System

## 1. System Philosophy
The NAKHL&NAHL Universal Help System is designed around a **4-level cognitive guidance model**:
1. **Level 1 (Ambient/Hover Tooltip):** Non-intrusive `HelpTooltip` widget displaying concise 1-2 sentence summaries on desktop hover or mobile tap.
2. **Level 2 (Contextual Popover / Inline Help):** Form field helper icons (`FormFieldHelpIcon.vkn()`, `.csid()`, etc.) explaining fiscal jargon right at data entry point.
3. **Level 3 (Interactive Help Drawer / Sheet):** Deep, structured modal sidebar explaining screen purpose, step-by-step instructions, cautionary tips, and links to documentation.
4. **Level 4 (Guided Walkthrough Tour & 15-Step Wizard):** Onboarding wizard (`OnboardingWizardDialog`) and spotlight guided tours (`GuidedTourOverlay`) walking first-time users from blank state to complete operation.

## 2. Help Architecture
- **Data Model:** `HelpContent`, `HelpStep`, `UserHelpProgress`, `TaskGuide`.
- **Knowledge Catalog:** `HelpRegistry` containing verified procedural guides for all 34 core ERP modules.
- **Search Engine:** Intelligent keyword & synonym matcher ("fatura kesmek" -> Invoices, "stok sayımı" -> Inventory, "cari bakiye" -> Accounts).
- **Multi-Lingual Support:** Pre-configured for Turkish (TR), English (EN), and Arabic (AR).
- **Role-Based Filtering:** Automatically filters guidance based on user authorization (Admin, Accountant, Warehouse Worker, Sales Rep, POS Cashier).
- **Privacy & Analytics:** Tracks user progression in `user_help_progress` and non-PII operational events in `help_usage_events` with forced RLS.
