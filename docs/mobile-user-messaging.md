# Mobile user messaging

`AppMessage` in `user_app/lib/core/utils/app_message.dart` is the canonical
transient user-message API for the Flutter application. Feature code must not
construct a `SnackBar` or call `ScaffoldMessenger` directly.

## Message types

- `AppMessage.success` confirms a completed action, such as a copy, save, or
  completed download.
- `AppMessage.error` reports an action that failed and uses the longer default
  display duration.
- `AppMessage.warning` reports unavailable, incomplete, or potentially unsafe
  actions that require the user's attention.
- `AppMessage.info` communicates neutral progress or status.
- `AppMessage.show` is reserved for code that must select `AppMessageType`
  dynamically.

Messages replace the currently displayed transient message by default. Use the
optional `actionLabel` and `onAction` arguments for one contextual action such
as **Retry**. When no custom action is supplied, AppMessage provides a standard
**Dismiss** action.

```dart
AppMessage.success(context, 'Guideline link copied.');

AppMessage.error(
  context,
  'The guideline could not be downloaded.',
  actionLabel: 'RETRY',
  onAction: retryDownload,
);
```

## Intentional exceptions

AppMessage is not a replacement for every communication surface:

- field-level validation remains next to the affected field;
- persistent page failures use `AppErrorView` or a feature-specific error
  panel with recovery controls;
- clinical warnings and safety notices remain visible in the content rather
  than disappearing automatically;
- confirmations that require a decision use a dialog;
- multi-step tasks and selections use a page or bottom sheet;
- system notifications and outbreak alerts use the governed notification and
  Firebase Cloud Messaging workflow.

Do not include patient-identifiable information, access tokens, raw response
bodies, or secrets in AppMessage text. Convert technical failures into concise,
actionable user language before displaying them.

## Action feedback checklist

Every user-triggered asynchronous action must either update an obvious,
persistent part of the current screen or report its outcome through
`AppMessage`. Check these actions whenever a screen is added or reviewed:

- copy, share, or open an external link;
- save, submit, bookmark, remove, cancel, or retry;
- download content or remove an offline copy;
- persist an onboarding or preference choice;
- navigate using data that may be missing or stale.

Show success when the completed result is not otherwise clear. Always catch a
failure at the UI boundary, unless the action delegates to a controller whose
state renders a persistent error with a recovery control. Background analytics,
read-progress tracking, cache refreshes, and other best-effort bookkeeping must
not interrupt the user with transient messages.

The current audit covers authentication and onboarding, home navigation,
global search, guideline reading and publication tools, conversation copying,
offline content, outbreak resources and documents, and calculator review.

## Application wiring

`MaterialApp.router` owns the shared `AppKeys.scaffoldMessengerKey`, while the
GoRouter root navigator and `AppNavigator` share `AppKeys.navigatorKey`. This
keeps controller-originated messages attached to the mounted application
shell. The previous unused Toastification wrapper and dependency were removed
to prevent a second transient-message system from being introduced.

## Review rule

The repository check for bypasses is:

```sh
rg 'ScaffoldMessenger|SnackBar\\(' user_app/lib --glob '*.dart'
```

Only `core/utils/app_message.dart`, the application key declaration, and
framework-level wiring should match.
