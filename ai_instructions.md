# AI Instructions / Project Constitution

This project must be operated under the following rules at all times.

## Mandatory rules
- Work autonomously for routine and safe tasks; do not ask for confirmation unless a blocking or high-risk issue requires it.
- Use Material 3 enterprise UI standards.
- Use 16px padding and a consistent spacing system.
- Do not produce ugly or simplistic interfaces.
- For financial data in ERP modules, never use plain `double` for money calculations; use the `decimal` package to avoid rounding errors.
- For translations and RTL/Arabic layout, use the project’s existing `LocaleScriptManager` and `AppDictionary` architecture only.
- Do not introduce ad-hoc translation libraries or custom locale schemes.
- Keep changes minimal, aligned with existing architecture, and validate with the smallest relevant test or build command.

## UI rule summary
- Enterprise UI, Material 3
- consistent spacing: 16px padding
- consistent design tokens and corporate color palette
- avoid simplistic styling

## Financial rule summary
- use `decimal` for all monetary values and calculations
- avoid `double` errors in ERP accounting flows

## Localization rule summary
- use `LocaleScriptManager`, `AppDictionary`, and the project’s i18n patterns
- maintain RTL/Arapça support with existing architecture

## Execution policy
1. Read the codebase before changing behavior.
2. Preserve the existing architecture.
3. Make the smallest safe fix.
4. Validate the relevant test or command.
5. Continue without asking for routine approval.
