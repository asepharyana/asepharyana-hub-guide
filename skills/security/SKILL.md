---
name: security
description: Security best practices for software development — input validation, authentication, authorization, secrets management, OWASP Top 10, and secure coding patterns. Use when handling user input, designing auth flows, storing secrets, configuring CORS/headers, or whenever the user mentions "security," "XSS," "SQL injection," "CSRF," "authentication," "authorization," "JWT," "OAuth," "encryption," "secrets," "CORS," "RBAC," "OWASP," or "security review."
---

# Security Best Practices

## OWASP Top 10 (Quick Reference)

1. **Broken Access Control** — verify authorization for every action, not just login.
2. **Cryptographic Failures** — use modern crypto (AES-256-GCM, bcrypt/Argon2 for passwords, TLS 1.3).
3. **Injection** — never concatenate user input into SQL/shell/HTML. Use parameterized queries.
4. **Insecure Design** — threat model before building. Rate limit, throttle, validate.
5. **Security Misconfiguration** — remove defaults, disable debug in prod, use secure headers.
6. **Vulnerable Components** — keep dependencies updated. Use SCA tools (Dependabot, Renovate).
7. **Auth Failures** — MFA, rate-limit login, no weak passwords, secure session management.
8. **Data Integrity Failures** — signed JWTs, integrity checks on CI/CD pipeline.
9. **Logging Failures** — log auth failures, never log secrets, monitor suspicious patterns.
10. **SSRF** — validate URLs, restrict outbound network access.

## Input Validation (First Line of Defense)

- **Whitelist > blacklist** — define what's allowed, not what's blocked.
- **Validate at every trust boundary** — API gateway → service → use case.
- **Type coercion** — parse, cast, then use. Never trust raw strings.
- **Size limits** — enforce max lengths, max file sizes.
- **Content types** — validate `Content-Type` and reject unexpected formats.

## Authentication

- **Passwords:** bcrypt (cost ≥10), Argon2id, or PBKDF2. Never MD5/SHA1.
- **JWTs:** Use `jose`/`jsonwebtoken` with RS256 or ES256. Short TTL (15min access, 7d refresh max). Validate `aud`, `iss`, `exp`, `nbf`.
- **Sessions:** HttpOnly, Secure, SameSite=Strict cookies. Rotate on privilege change.
- **MFA:** Prefer TOTP/WebAuthn over SMS (SIM swap risk).
- **Rate limiting:** Login/registration/password-reset endpoints. 5 attempts/15min per IP is standard.

## Authorization

- **RBAC** — roles assigned to users, permissions assigned to roles.
- **ABAC** (attribute-based) — for fine-grained: resource owner, department, region.
- **Check every request** — authorization at every endpoint, not just at login.
- **Default deny** — fail closed. If no rule allows it, deny it.
- **Middleware pattern:**
  ```typescript
  // Authenticate → Authorize → Execute
  app.use('/api/*', authenticate);
  app.use('/api/admin/*', authorize('admin'));
  app.post('/api/orders', authorizeOrderAccess);
  ```

## Secrets Management

- **Never commit secrets.** Use environment variables or a vault (Vault, AWS Secrets Manager, 1Password CLI).
- **.env files** — never committed to git. Use `.env.example` as a template.
- **Scan for secrets** — use `trufflehog`, `git-secrets`, or GitHub secret scanning.
- **Rotate regularly** — API keys, DB passwords, JWT signing keys.
- **Principle of least privilege** — tokens/secrets should have minimal scope.

## API Security

### Headers (via Traefik or middleware)
```yaml
# Traefik example
middleware:
  secure-headers:
    headers:
      frameDeny: true
      contentTypeNosniff: true
      browserXssFilter: true
      sslRedirect: true
      referrerPolicy: "no-referrer-when-downgrade"
      permissionsPolicy: "camera=(), microphone=(), geolocation=()"
      customFrameOptionsValue: "SAMEORIGIN"
      contentSecurityPolicy: "default-src 'self'; script-src 'self'"
```

### CORS
- **Default:** same-origin only.
- **For APIs:** whitelist specific origins, never `Access-Control-Allow-Origin: *` for authenticated endpoints.
- **Credentials:** `Access-Control-Allow-Credentials: true` only with explicit origin.

### Rate Limiting
- **Per IP, per user, per endpoint.** Different limits for different tiers.
- **Return `429 Too Many Requests`** with `Retry-After` header.
- **Log rate limit hits** — they often precede attacks.

## Data Protection

- **Encrypt at rest** — AES-256-GCM for PII. Transparent encryption or app-level.
- **Encrypt in transit** — TLS 1.3 minimum. HSTS with `max-age=63072000`.
- **PII minimization** — don't collect what you don't need. Anonymize when possible.
- **Data retention** — delete old data. Have a purge policy.
- **SQL injection prevention:**
  ```typescript
  // ❌ Never
  db.execute(`SELECT * FROM users WHERE id = '${id}'`);
  // ✅ Always
  db.execute('SELECT * FROM users WHERE id = $1', [id]);
  ```

## XSS Prevention

- **React/Vue/Svelte/Solid** — auto-escaped by default. Avoid `dangerouslySetInnerHTML`/`v-html`.
- **CSP headers** — `Content-Security-Policy` restricts script sources.
- **Never eval user input** — `JSON.parse` is safe, `eval` is not.
- **Sanitize HTML** — use DOMPurify if you must render user HTML.

## CSRF Prevention

- **SameSite cookies** — `SameSite=Strict`/`Lax` covers most cases.
- **CSRF tokens** — for forms without SameSite support.
- **Custom headers** — `X-Requested-By` is a valid CSRF token pattern for APIs.

## Dependency Security

- **Regular audits** — `npm audit`, `cargo audit`, `pip-audit`.
- **Lock files** — commit `package-lock.json`, `Cargo.lock`, `poetry.lock`.
- **Dependabot/Renovate** — automate dependency updates.
- **No `*` ranges** — pin major/minor, allow patches.
- **SBOM** — generate Software Bill of Materials for production deployments.

## Language-Specific

| Language | Key Practice |
|----------|-------------|
| TypeScript | `strict: true`, no `any`, use `jose` for JWT |
| Python | Use `httpx`/`requests` with TLS verify. Pydantic for validation |
| Rust | `cargo audit`, `ring` for crypto, parameterized queries via sqlx |
| Go | `crypto` stdlib, parameterized with `database/sql`, govulncheck |
