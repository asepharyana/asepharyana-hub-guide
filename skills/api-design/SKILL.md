---
name: api-design
description: Best practices for API design — REST, GraphQL, RPC conventions, versioning, status codes, pagination, error responses, and documentation. Use when designing new endpoints, reviewing API contracts, or whenever the user mentions "API design," "REST," "RESTful," "GraphQL," "endpoint," "status code," "pagination," "API versioning," "OpenAPI," "gRPC," or "API contract."
---

# API Design

## REST Conventions

### URL Structure
```
POST   /resources          # Create
GET    /resources          # List (with query params for filtering/pagination)
GET    /resources/:id     # Read one
PUT    /resources/:id     # Full replace
PATCH  /resources/:id     # Partial update
DELETE /resources/:id     # Delete
GET    /resources/:id/related  # Nested resource
```

- **Plural nouns**, not verbs: `/users` not `/getUsers`
- **Kebab-case** for multi-word: `/order-items` not `/orderItems`
- **No file extensions**: `/users` not `/users.json`
- **Version in URL or Accept header**: `/v1/users` or `Accept: application/vnd.api.v1+json`

### Response Format
```json
// Success
HTTP 200
{ "data": { "id": "1", "name": "Alice", "email": "alice@example.com" } }

// List with pagination
HTTP 200
{
  "data": [ ... ],
  "meta": { "total": 100, "page": 1, "per_page": 20 },
  "links": { "self": "?page=1", "next": "?page=2", "prev": null }
}

// Error
HTTP 422
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Email is required",
    "details": [{ "field": "email", "issue": "required" }]
  }
}
```

### Status Codes — Use Precisely

| Code | When |
|------|------|
| **200** | Success (GET, PUT, PATCH) |
| **201** | Created (POST) |
| **204** | No Content (DELETE success) |
| **301** | Moved permanently (redirect) |
| **400** | Bad request (malformed input) |
| **401** | Unauthenticated (missing/invalid credentials) |
| **403** | Forbidden (authenticated but not authorized) |
| **404** | Not found |
| **409** | Conflict (duplicate, version mismatch) |
| **422** | Unprocessable entity (validation failure) |
| **429** | Too many requests (rate limit) |
| **500** | Internal server error (unhandled, doesn't fit above) |
| **502/503** | Upstream / service unavailable |

Never return 200 with an error body. Never return 500 for validation errors.

### Pagination
```typescript
// Cursor-based (preferred for live data)
GET /items?cursor=abc123&limit=20
Response: { data: [], meta: { next_cursor: "xyz789", has_more: true } }

// Page-based (fine for stable datasets)
GET /items?page=1&per_page=20
Response: { data: [], meta: { total: 100, page: 1, per_page: 20 } }
```

### Filtering, Sorting, Fields
```typescript
GET /items?filter[status]=active&filter[created_at]=2024-01-01..2024-12-31
GET /items?sort=-created_at,name       // -prefix = descending
GET /items?fields=id,name,status       // sparse fieldset (performance)
```

## GraphQL

- **Schema-first** — design the schema before implementing resolvers.
- **N+1 problem** — use DataLoader for batch loading.
- **Expose a single endpoint** — no per-resource URLs.
- **Mutations return the mutated object** — always include the affected type.
- **Paginate connections** — use the Relay Connection spec (`edges { node }`).

## API Versioning

- **URL versioning** (`/v1/users`) — simplest, most explicit.
- **Header versioning** (`Accept: application/vnd.api.v2+json`) — cleaner URL.
- **Never remove fields** — deprecate first, remove in next major version.
- **Document breaking changes** — changelog, migration guide, sunset header (`Sunset: Sat, 1 Nov 2025 00:00:00 GMT`).

## API Documentation

- **OpenAPI 3.x** for REST APIs. Generate from code (Hono Zod OpenAPI, FastAPI).
- **Include in docs:** endpoint, method, params, request body schema, response schema, error codes, auth requirement, example requests/responses.
- **Keep a changelog** — versioned alongside the API spec.

## Other API Styles

### gRPC
- Use for internal service-to-service communication.
- Proto3, HTTP/2, streaming support.
- Better than REST for high-throughput, low-latency internal APIs.

### RPC-style (tRPC, Elysia Eden)
- No URL routing — direct function calls from client.
- Type-safe end-to-end. Preferred for full-stack TypeScript.
- Trade-off: couples client and server types.

## Idempotency

- **PUT and DELETE are idempotent** — same request multiple times = same result.
- **POST is not idempotent** — provide `Idempotency-Key` header for payment-like operations.
- **PATCH can be idempotent** if you send the full delta (not increments).

## API Anti-patterns

- ❌ **Leaking internal implementation** — exposing DB fields, raw SQL, internal IDs
- ❌ **Inconsistent error format** — sometimes `{error}`, sometimes `{message}`, sometimes `{errors}[]`
- ❌ **Over-fetching/n+1** — returning more data than needed, making N+1 queries
- ❌ **No rate limit info** — no `Retry-After`, no `X-RateLimit-*` headers
- ❌ **Version in body** — `/api?version=2`, version field in JSON body
- ❌ **200 for errors** — `HTTP 200 {"error": "not found"}` should be `HTTP 404`
