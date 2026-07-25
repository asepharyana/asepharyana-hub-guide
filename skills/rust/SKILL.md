---
name: rust
description: Rust best practices — ownership, error handling, async, project structure, clippy rules, testing, and idiomatic Rust. Use when writing Rust code, reviewing Rust projects. Triggers when working with this language's files, regardless of spoken language."
---

# Rust Best Practices

## Project Structure (Clean Architecture)

```
src/
├── domain/           # Entities, value objects, domain events
├── application/      # Use cases, repository ports (traits)
├── infrastructure/   # Adapters (DB, HTTP client, cache)
├── api/              # Axum/Actix handlers, middleware
├── config/           # App configuration
└── main.rs           # Entry point, composition root
```

## Error Handling

```rust
// Use thiserror for application errors
use thiserror::Error;

#[derive(Error, Debug)]
pub enum OrderError {
    #[error("order not found: {0}")]
    NotFound(String),
    #[error("validation error: {0}")]
    Validation(String),
    #[error("database error: {0}")]
    Database(#[from] sqlx::Error),
}

// Use Result in application layer
pub async fn create_order(input: CreateOrderInput) -> Result<Order, OrderError> {
    let user = user_repo.find_by_id(&input.user_id)
        .await?
        .ok_or_else(|| OrderError::NotFound("user".into()))?;
    // ...
}
```

**Rules:**
- `thiserror` for library/app errors. `anyhow` for binary/CLI errors.
- Never `unwrap()` or `expect()` in production code. Use `?` or match.
- `Result` for recoverable errors. `panic!` only for unrecoverable states.

## Ownership & Borrowing

```rust
// Prefer borrowing over taking ownership
fn process(items: &[Item]) -> usize {
    items.iter().filter(|i| i.active).count()
}

// Clone when ownership is truly needed (and it actually needs to be owned)
fn save(items: Vec<Item>) { ... }
```

- **One mutable reference (`&mut`) XOR many immutable refs (`&`).**
- **Use `Cow`** for "borrow if possible, own if modified."
- **Prefer `&str`** over `&String` for function params.
- **Rc/Arc** — only when shared ownership is needed (graphs, caches).

## Async (Tokio)

```rust
#[tokio::main]
async fn main() -> Result<()> {
    // ...
    Ok(())
}

// Use tokio::spawn for concurrent tasks
let handle = tokio::spawn(async move {
    process_batch(items).await
});
let result = handle.await??;
```

**Rules:**
- `tokio` for runtime. Axum for HTTP.
- `tokio::select!` for timeouts, race conditions.
- No `block_on` in async code. No sync mutex in async — use `tokio::sync::Mutex`.
- Use `tokio::sync::Semaphore` for rate limiting concurrent tasks.

## Traits (Interfaces)

```rust
// Port — defined in domain/application layer
#[async_trait]
pub trait UserRepository: Send + Sync {
    async fn find_by_id(&self, id: &str) -> Result<Option<User>, DbError>;
    async fn save(&self, user: &User) -> Result<(), DbError>;
}

// Adapter — implemented in infrastructure layer
pub struct PostgresUserRepository {
    pool: sqlx::PgPool,
}

#[async_trait]
impl UserRepository for PostgresUserRepository {
    async fn find_by_id(&self, id: &str) -> Result<Option<User>, DbError> {
        sqlx::query_as("SELECT * FROM users WHERE id = $1")
            .bind(id)
            .fetch_optional(&self.pool)
            .await
            .map_err(Into::into)
    }
}
```

## Database (sqlx / SeaORM)

```rust
// sqlx — prefer raw SQL with compile-time checking
let user = sqlx::query_as::<_, User>(
    "SELECT id, email, name FROM users WHERE id = $1"
)
.bind(user_id)
.fetch_optional(&pool)
.await?;
```

- **sqlx** for type-safe raw SQL. **SeaORM** when you need a full ORM.
- Use migrations (`sqlx migrate` or `sea-orm-cli`).
- Connection pooling via `sqlx::PgPool` or `deadpool`.

## Testing

```rust
// Unit tests inline
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn order_total_calculates_correctly() {
        let order = Order::new(vec![
            OrderItem::new(10.0, 2),
            OrderItem::new(5.0, 1),
        ]);
        assert_eq!(order.total(), 25.0);
    }

    #[tokio::test]
    async fn create_order_requires_user() {
        let repo = InMemoryUserRepo::new();
        let result = create_order(CreateOrderInput { user_id: "nonexistent".into() }, &repo).await;
        assert!(result.is_err());
    }
}

// Integration tests in tests/
```

- **Unit tests** inline in module. **Integration** in `tests/` directory.
- **Fakes** (in-memory repos) over mocking libraries.
- **Property-based testing** with `proptest` for complex logic.

## Clippy Rules

```toml
# .clippy.toml
# Enable in Cargo.toml or rustfmt.toml:
# [lints.clippy]
# pedantic = "warn"
# nursery = "warn"
```

Default: `#![warn(clippy::pedantic, clippy::nursery)]`

## Serialization (serde)

```rust
use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize)]
pub struct UserResponse {
    pub id: String,
    pub email: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub name: Option<String>,
}
```

## Anti-patterns

- ❌ `unwrap()` / `expect()` in production — crash on any error
- ❌ Large `main.rs` — everything in one file
- ❌ `unsafe` without documented safety invariants
- ❌ `Rc<RefCell<...>>` in async contexts — use `Arc<Mutex<...>>`
- ❌ `Box<dyn Trait>` where generics work — `impl Trait` or generic param
- ❌ Ignoring clippy warnings — run `clippy` before every commit
- ❌ `#[tokio::main]` on library code — only in binary entry points
