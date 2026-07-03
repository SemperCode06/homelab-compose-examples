# Contributing

Thanks for helping make these examples safer or easier to understand. Please keep contributions portable: use `example.com`, documentation IP ranges, obvious credential placeholders, and configurable storage paths.

## Protect your secrets first

Do not copy a live Compose directory into this repository and clean it afterward. Start with the template and move only the settings you intend to share. Git remembers deleted values, and forks or automation may copy a commit almost immediately.

Install the commit-time checks after cloning:

```bash
python3 -m pip install pre-commit
pre-commit install
pre-commit run --all-files
```

The hooks run the repository's generic sanitization checks and Gitleaks 8.30.1. They are safeguards, not proof that a file is safe. Review your staged diff before every commit:

```bash
git diff --cached
```

Before opening a pull request, also run the full validation if Docker Compose and ripgrep are installed:

```bash
./scripts/validate.sh
```

## Pull requests

- Explain what the stack or change is meant to demonstrate.
- Update the relevant README when behavior, variables, ports, volumes, or networks change.
- Keep real domains, email addresses, usernames, LAN details, credentials, and runtime data out of examples.
- Do not weaken or bypass a security check just to make CI pass. Explain suspected false positives in the pull request without posting the matched value.

## If you accidentally expose a secret

Stop and revoke or rotate it with the provider immediately. Deleting the line or rewriting the latest commit does not invalidate the credential or remove every copy. After rotation, contact the repository owner privately before sharing details publicly.

