# Mobile visual regression

The full-screen Flutter golden suite covers the 17 high-value screens required
by the mobile redesign:

- onboarding, guest home and guest search
- outbreak hub and situation-report detail
- guideline overview and structured, partial and original-document readers
- authenticated home, My Library, AI assistant, Tools and Profile
- algorithm, table and offline-content viewers

## Visual direction

The supplied MediGuide mobile reference is the visual source of truth. The
implementation applies its design language to complete screens—not only the
navigation shell:

- clinical blue is used for navigation, links, primary actions and icon tiles
- red is reserved for urgent outbreak and destructive states
- content sits on white or quiet slate surfaces with subtle neutral borders
- cards are flat, compact and consistently rounded instead of elevated
- headings use a dense, high-contrast Geist hierarchy suitable for scanning
- search, filters, tabs, chips, fields and buttons share the same geometry
- list destinations use blue-tinted rounded-square icons and restrained chevrons
- dark mode preserves semantic color roles rather than inverting fixed colors

The onboarding, guest home, library and profile layouts deliberately mirror
the reference's information hierarchy while continuing to use live typed data.

Every screen is captured using deterministic typed fixtures in five viewport
configurations:

| Baseline | Logical size | Text scale | Theme |
|---|---:|---:|---|
| narrow phone | 320 × 720 | 100% | light |
| large phone | 430 × 932 | 100% | light |
| tablet | 800 × 1280 | 100% | light |
| accessibility | 390 × 844 | 200% | light |
| dark phone | 390 × 844 | 100% | dark |

Run the comparison suite from `user_app`:

```bash
.fvm/flutter_sdk/bin/flutter test test/full_screen_golden_matrix_test.dart
```

Update images only after reviewing an intentional UI change:

```bash
.fvm/flutter_sdk/bin/flutter test \
  test/full_screen_golden_matrix_test.dart --update-goldens
```

The committed matrix contains 85 PNG files under
`test/goldens/full_screen`. Tests fail on both pixel drift and Flutter layout
exceptions such as overflow.

Original guideline PDFs and published situation reports open in the embedded
Android/iOS reader. Remote files are downloaded to an atomic temporary path
before rendering; partial downloads are deleted. The reader retains an
explicit external-application fallback.
