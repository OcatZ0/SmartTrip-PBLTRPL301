import '../../../core/error/api_failure.dart';
import '../../../l10n/app_localizations.dart';

/// User-facing text for a failed trip API call. Laravel's 422 message already
/// carries the specific reason (e.g. "Kandidat tempat tidak cukup").
String tripErrorMessage(Object error, AppLocalizations l10n) {
  return switch (error) {
    NetworkFailure() => l10n.errorNetwork,
    ValidationFailure(:final message?) => message,
    _ => l10n.errorGeneric,
  };
}
