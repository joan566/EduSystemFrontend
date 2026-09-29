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

## Commands

```bash
flutter analyze
flutter test
flutter run -d chrome --dart-define-from-file=env/development.json
```
