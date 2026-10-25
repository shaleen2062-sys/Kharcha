# Contributing to Kharcha

Thank you for helping improve Kharcha. Contributions should make receipt
capture, review, budgeting, or spending insight more reliable and easier to
use.

## Before you start

1. Read the [README](README.md) and the component guide for the area you want
   to change.
2. Search existing issues and pull requests before starting duplicate work.
3. For a large feature or behavior change, open an issue first so the approach
   can be discussed.
4. Never commit `.env` files, Firebase private keys, service-role keys,
   database credentials, receipt images containing personal information, or
   other secrets.

## Repository areas

| Area | Scope |
| --- | --- |
| `kharcha_app/` | Flutter client, navigation, screens, local cache, and sync |
| `Kharcha-backend/` | Express API, authentication, persistence, budgets, alerts |
| `reader/` | OCR, receipt parsing, categorization, and reader API |
| `notebooks/` | Training and model experimentation |
| `AI_USAGE.md` | File-level explanation of how AI output drives the product |

## Development workflow

```bash
git checkout -b feature/short-description
```

Keep each change focused. Follow the existing feature-based architecture,
naming conventions, validation helpers, and error-handling patterns.

### Flutter changes

```bash
cd kharcha_app
flutter pub get
dart format .
flutter analyze
flutter test
```

### Backend changes

```bash
cd Kharcha-backend
npm install
npm run typecheck
npm test
npm run build
```

### Reader changes

```bash
cd reader
python -m unittest discover -s tests -p "test*.py" -v
```

Update the relevant README and API contract when setup, configuration,
endpoints, or observable behavior changes.

## AI and data guidelines

- Keep AI inference open and self-hostable; do not add proprietary hosted AI
  APIs without an explicit project decision.
- AI output must be consumed by application logic, not only displayed as text.
- Preserve confidence, reconciliation, and review behavior when changing the
  reader pipeline.
- Do not add private receipts, personal data, or credentials to fixtures.
- If a model, prompt, feature, or processing step changes, update
  [AI_USAGE.md](AI_USAGE.md).
- Prefer deterministic validation and explicit failure states over silently
  accepting uncertain model output.

## Pull requests

Please include:

- A clear description of the problem and solution.
- The affected component(s).
- Screenshots or a short recording for UI changes.
- Test commands run and their results.
- Configuration or migration notes, if applicable.
- Documentation updates for user-visible or developer-visible changes.

Before requesting review, confirm:

- [ ] The change is limited to the intended scope.
- [ ] No secrets or personal receipt data are included.
- [ ] Relevant tests and static checks pass.
- [ ] New behavior has tests where practical.
- [ ] Error and empty states are handled.
- [ ] README/API/AI documentation is updated when needed.

## Commit messages

Use concise, imperative commit messages:

```text
Add receipt review confidence state
Fix offline upload retry handling
Document reader environment variables
```

## Code of conduct

Be respectful, constructive, and inclusive. Assume good intent, explain
technical disagreements clearly, and focus feedback on the work.
