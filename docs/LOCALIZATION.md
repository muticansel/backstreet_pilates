# Localization

The app currently supports English (`en`) and Turkish (`tr`). The language
menu is available before sign-in and on both member and admin surfaces; changing
it updates the running application immediately.

`lib/l10n/app_localizations.dart` is the single source of translated UI text
and defines the supported locales. Add a key to both language maps before using
`AppLocalizations.of(context).text('key')` in a page. Missing Turkish text falls
back to English deliberately, so a new screen remains usable while its wording
is translated.

The selection is intentionally kept in memory for this first pass. It resets to
English on a full app restart. Persisting a preference requires a reviewed local
storage dependency and is not coupled to authentication or Supabase profile data.

Current translated coverage: login, signup, the admin overview, cash-payment
approval queue, and the language controls. Existing member-dashboard preview
content retains English fallback and can be translated page by page.
