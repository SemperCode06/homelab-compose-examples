# Security

## Reporting a vulnerability or exposed secret

Do not open a public issue containing a credential, exploit detail, private hostname, or personal network information.

Use GitHub's private vulnerability reporting feature.

## If the secret belongs to you

1. Revoke or rotate it at the provider immediately.
2. Check provider audit logs for unexpected use.
3. Tell the repository owner privately which file and commit contain it.
4. Replace the committed value with a documented placeholder.
5. Treat history cleanup as containment, not revocation. Existing clones and forks may retain the original commit.

Automated scanners can miss secrets and produce false positives. Contributors remain responsible for reviewing what they publish.

