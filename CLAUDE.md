# EduSistem Frontend

Flutter (Web + Android) client for the EduSistem REST API. UI copy is in Spanish.

## Mobile and desktop are separate implementations

Mobile and desktop are different products, not one layout that stretches.
Never write a widget that "adapts itself" (`if (isMobile)` inside a
component, a table that turns into cards, paddings via ternaries). There is
intentionally no `context.isMobile`.

- `lib/core/layout/responsive.dart` holds the breakpoints and
  `ResponsiveBuilder`. That is the only place the tree forks, and it is used
  only at a page entry point (and in `AppShell`).
- Tablet belongs to the desktop family unless a screen has a real reason to
  diverge (`ResponsiveBuilder.tablet`).

### Layout of a feature's presentation layer

```
features/<feature>/presentation/
  pages/      thin entry point: loads data, owns state that must survive a
              layout switch, then ResponsiveBuilder(mobile:, desktop:)
  mobile/     <x>_mobile_view.dart — the phone UI
  desktop/    <x>_desktop_view.dart — the desktop UI
  shared/     platform-agnostic pieces both views use: forms, actions
              (save/delete + feedback), controllers, labels, content cards
  providers/  state (ChangeNotifier), unchanged by layout
```

- State that must survive resizing across the breakpoint (selected class,
  filters, drafts, picked files, tab index) lives in the page entry point or
  in a `shared/*_controller.dart` ChangeNotifier owned by it, never inside a
  view.
- Forms are shared content wrapped in `AppFormFrame`; the view picks the
  presenter: `showDesktopDialog` (desktop) vs `showMobileForm` /
  `showMobileSheet` (mobile). The presenter supplies the chrome.
- Where a shared section needs a platform-specific piece (for example file
  intake: drop zone vs picker button), the view passes it in. The section
  never decides.

### Core widgets

- `core/widgets/shared/`: platform-neutral primitives (buttons, fields,
  cards, chips, states, `TintedIcon`, `AppFormFrame`, `showAppConfirmDialog`,
  `PickedFile`).
- `core/widgets/mobile/`: `MobileShell`/`MobileBottomNav`, `MobileBrandBar`
  (top bar of home-level screens), `MobilePageHeader`, `MobileSectionCard`,
  `MobileSelectField`, `MobileCardList`, `showMobileForm`/`showMobileSheet`,
  `MobileFilePickerButton`, `MobileMorePage`.
- `core/widgets/desktop/`: `DesktopShell`/`TabletShell`, `DesktopPageHeader`,
  `DesktopSectionCard`/`DesktopHoverTile`, `DesktopDataTable`,
  `showDesktopDialog`, `DesktopUploadZone`, `DesktopHeroBanner`,
  `DesktopStatCard`.

### Loading states

- Content being read shows a skeleton shaped like the real UI, never a
  spinner: `core/widgets/shared/skeleton/` (`Skeleton` root with the shared
  shimmer and a short reveal delay against flicker, `SkeletonBox`,
  `SkeletonText`, `SkeletonTile`, `SkeletonSurface`, `SkeletonTileList`...),
  `mobile_skeletons.dart` (`MobileListSkeleton`, `MobileDetailSkeleton`,
  `MobileSectionSkeleton`) and `desktop_skeletons.dart`
  (`DesktopListTableSkeleton` with the real column labels,
  `DesktopDataTableSkeleton`, `DesktopDetailSkeleton`,
  `DesktopSectionSkeleton`, `DesktopStatsRowSkeleton`). Shared state views
  take the platform's skeleton as a `placeholder`.
- Loading is not empty: switches handle `initial`/`loading` before any
  "Sin …" fallback.
- Server-paged listings keep the previous page on screen while the next
  loads (`KeptListing` in the page entry point + `AppUpdating`).
- Actions (save, delete, download) keep their inline indicator
  (`AppButton.isLoading`); uploads/processing keep `AppProgressBar`.

## Data, cache and sessions

Providers hold the teacher's data for the session, not "what a screen
shows". Navigating is mostly reading memory; the backend is read only when
data is missing, stale, expired, or on an explicit refresh.

- **Session isolation.** `core/session/session_scope.dart` owns every domain
  provider, the `DomainEvents` bus and its own `GoRouter`, keyed by the
  signed-in user id (`main.dart`). Logout, expiry, account deletion or
  another teacher signing in rebuilds it empty — never add a `reset()`.
  Only `ApiClient`, `AuthProvider` and `SessionExpiryNotifier` are
  app-level. Nothing private is persisted to disk.
- **Providers** extend `SessionNotifier` and create their caches with
  `cachedValue()` / `keyedCache()` (`core/cache/`). Key per-entity data by
  id and per-class data by `teachingPeriodId` — never a single `state`
  slot shared by screens. Catalogs (levels, subjects, periods, courses,
  assignments, classes, scales) are whole lists (`Catalog`, all pages via
  `fetchAllPages`) filtered and paged in memory; students stay
  server-paginated, cached per exact query.
- **API**: `ensureX()` (read only if needed), `refreshX()` (force; pull to
  refresh, retry), getters returning `ListViewState`/`DetailViewState`.
  Filters, search, page, selection live in the page entry point.
- **Mutations**: backend first, then write the answer locally
  (`upsert`/`update`/`set`/`remove`); if the endpoint answers nothing,
  re-read only that resource. Then `publish` a `DomainEvent`
  (`ClassDataChanged`, `CatalogChanged`, `StudentsChanged`,
  `ExamResultsChanged`, `SessionDataReset`); other providers only mark
  their own caches stale in `onDomainEvent` (never fetch there). Optimistic
  updates only for simple toggles, with rollback.
- **Pages** use `SyncedDataState` (`ensureData()` runs on entry, on return
  via `shellRouteObserver`, and after events while visible). Never fetch
  from `build`. TTL only for time-sensitive data (today/week agenda, audit);
  `AppResumed` re-reads them, and everything after a long background.
- Debug builds log `[HTTP] METHOD /route` per request and expose
  `ext.edusystem.httpReport` (counts and timings per route, no ids,
  queries, bodies or headers).

## Commands

```bash
flutter analyze
flutter test
flutter run -d chrome --dart-define-from-file=env/development.json
```
