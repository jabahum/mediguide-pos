# Mobile visual regression

The full-screen Flutter golden suite covers the 17 high-value screens required
by the mobile redesign:

- onboarding, guest home and guest search
- outbreak hub and situation-report detail
- guideline overview and structured, partial and original-document readers
- authenticated home, My Library, AI assistant, Tools and Profile
- algorithm, table and offline-content viewers

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
