# Security Policy

## Supported Versions

Only the latest stable release receives security updates.

| Version    | Supported          |
|------------|--------------------|
| 0.1.x      | :white_check_mark: |
| older      | :x:                |

## Reporting a Vulnerability

If you discover a security issue in Brrk, please report it responsibly.

**Do NOT file a public GitHub issue for security vulnerabilities.**

Instead:

1. Email the maintainer directly (see GitHub profile), or
2. Send a private security report via GitHub's "Report a vulnerability" link
   on the repository.

### What to include in a report

- Description of the issue and how it can be exploited
- Steps to reproduce (do not include real sensitive data)
- Affected version(s) and Android version(s)
- Any suggested mitigations (optional)

Do NOT include actual API keys, document contents, or personal data in reports.

### What to expect

- **Acknowledgement**: within 48 hours on business days
- **Initial assessment**: within 1 week
- **Resolution or workaround**: timeline varies by severity and complexity

### Disclosure

We follow a responsible disclosure model:
- We aim to publish a fix before public disclosure
- If a fix is delayed, we coordinate with the reporter on a disclosure date
- Public changelog will note security-related changes without exposing exploit details

## Out of Scope

- Social engineering or physical device access attacks
- Vulnerabilities in third-party dependencies (report to upstream maintainers;
  see `flutter pub outdated` and `cargo outdated` for your dependency versions)
- Issues that require a rooted or modified OS to exploit
- Denial of service that requires unusual resource consumption

## No Bounty

Brrk is an open source hobby project with no funding and no bug bounty program.
We appreciate responsible disclosure and will credit reporters in release notes
unless anonymity is requested.