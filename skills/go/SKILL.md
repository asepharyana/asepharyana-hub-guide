---
name: go
description: Go best practices — idiomatic Go, project layout, error handling, interfaces, concurrency, testing, and dependency management. Use when writing Go code, reviewing Go projects. Triggers when working with this language's files, regardless of spoken language."
---

# Go Best Practices

## Project Layout

```
project/
├── cmd/
│   └── server/
│       └── main.go              # Entry point
├── internal/
│   ├── domain/                  # Business entities, value objects
│   ├── application/             # Use cases, ports
│   ├── infrastructure/          # DB, HTTP, cache adapters
│   └── api/                     # HTTP handlers, middleware
├── pkg/                         # Public library code (for external consumption)
├── tests/                       # Integration/E2E tests
├── go.mod
├── go.sum
└── Makefile
```

- `cmd/` — one directory per binary. Small main function, defer to package.
- `internal/` — not importable outside this module. Clean architecture layering.
- `pkg/` — safe for external packages to import.

## Idiomatic Go

```go
// Named returns are OK but prefer bare in simple cases
func Parse(input string) (result Result, err error) {
    if input == "" {
        return result, errors.New("empty input")
    }
    result.Value = input
    return
}
```

**Rules:**
- **Favor files over functions** — one logical unit per file, not one function per file.
- **Short variable names** — `ctx`, `r` (request), `w` (response writer), `cfg` (config).
- **Getters don't have `Get` prefix** — `user.Name()` not `user.GetName()`.
- **Zero-value is useful** — initialize your structs so zero value is usable.
- **`gofmt` is the law** — no style debates. Run `gofmt` (or `gofumpt`).
- **`go vet` before commit** — catches subtle bugs.

## Error Handling

```go
// Always handle errors. No discard.
result, err := doSomething()
if err != nil {
    return fmt.Errorf("doing something: %w", err)  // wrap with context
}

// Sentinel errors for specific cases
var ErrNotFound = errors.New("not found")

// Custom error types for additional context
type ValidationError struct {
    Field string
    Err   error
}
func (e *ValidationError) Error() string {
    return fmt.Sprintf("validation failed on %s: %v", e.Field, e.Err)
}
func (e *ValidationError) Unwrap() error { return e.Err }
```

- **Error wrapping** — `fmt.Errorf("context: %w", err)` for the call chain.
- **`errors.Is()`** for sentinel errors. **`errors.As()`** for custom types.
- **Don't use `_` to discard errors** — unless truly intentional (e.g. `fmt.Fprint`).
- **Defer for cleanup** — `defer file.Close()`, `defer mu.Unlock()`.

## Interfaces

```go
// Define interfaces in the consumer package (application/domain), not producer
type UserRepository interface {
    FindByID(ctx context.Context, id string) (*User, error)
    Save(ctx context.Context, user *User) error
}

// Small interfaces are Go's superpower
type Reader interface { Read(p []byte) (n int, err error) }
type Writer interface { Write(p []byte) (n int, err error) }
type Stringer interface { String() string }
```

- **Accept interfaces, return structs** — consumer declares what it needs.
- **Interface satisfaction is implicit** — no `implements` keyword.
- **Prefer single-method interfaces (IO pattern).**
- **Don't export interfaces:**

## Concurrency

```go
// Goroutines + channels for communication
func processBatch(ctx context.Context, items []Item) error {
    results := make(chan Result, len(items))
    ctx, cancel := context.WithCancel(ctx)
    defer cancel()

    // Fan-out
    for _, item := range items {
        item := item  // copy for closure
        go func() {
            select {
            case results <- process(item):
            case <-ctx.Done():
            }
        }()
    }

    // Fan-in
    for range items {
        select {
        case r := <-results:
            if r.err != nil { return r.err }
        case <-ctx.Done():
            return ctx.Err()
        }
    }
    return nil
}

// sync.WaitGroup for waiting
var wg sync.WaitGroup
for _, v := range items {
    wg.Add(1)
    go func(v Item) {
        defer wg.Done()
        process(v)
    }(v)
}
wg.Wait()
```

- **Don't communicate by sharing memory; share memory by communicating.**
- **Channel or mutex?** — channel when passing ownership or signaling; mutex for shared state.
- **Context first param** — `ctx context.Context` is always the first function parameter.
- **Never start goroutines without knowing when they stop.**
- **Use `errgroup`** for concurrent operations that share context.

## Testing

```go
func TestCreateUser(t *testing.T) {
    t.Parallel()

    // Table-driven tests
    tests := []struct {
        name    string
        input   CreateUserInput
        wantErr bool
    }{
        {name: "valid user", input: CreateUserInput{Email: "a@b.com"}, wantErr: false},
        {name: "empty email", input: CreateUserInput{}, wantErr: true},
    }

    for _, tt := range tests {
        tt := tt  // capture for t.Parallel
        t.Run(tt.name, func(t *testing.T) {
            t.Parallel()
            repo := NewInMemoryUserRepo()  // fake
            svc := NewUserService(repo)
            err := svc.CreateUser(context.Background(), tt.input)
            if (err != nil) != tt.wantErr {
                t.Errorf("got err = %v, wantErr = %v", err, tt.wantErr)
            }
        })
    }
}

func BenchmarkCreateUser(b *testing.B) {
    for b.Loop() {  // go 1.24+
        repo := NewInMemoryUserRepo()
        svc := NewUserService(repo)
        if err := svc.CreateUser(context.Background(), validInput); err != nil {
            b.Fatal(err)
        }
    }
}
```

- **`testing/slog`** for test logging. **`testing/fstest`** for filesystem fakes.
- **Fakes over mocks** — in-memory implementations are simpler and more maintainable.
- **`testify`** is common but stdlib `testing` has improved — prefer `got/want` comparison.

## Standard Library First

Go's stdlib is extensive. Reach for it before frameworks:
- `net/http` — for basic HTTP servers (chi/echo for routing, but stdlib for the basics).
- `encoding/json` — JSON serialization (better than most third-party libs).
- `database/sql` — database access (with `pgx` for Postgres).
- `testing` — built-in test runner, fuzzing, benchmarks.
- `context` — cancellation, deadlines, request-scoped values.
- `slog` — structured logging (go 1.21+).

## Anti-patterns

- ❌ `context.Background()` in handlers — use `req.Context()`
- ❌ Global variables — pass dependencies explicitly
- ❌ `init()` functions — they break control flow and test isolation
- ❌ `_ = foo()` — silent error discard; handle or at least log
- ❌ Embedding HTTP server logic — `ListenAndServe` in `main.go`, not hidden in a library
- ❌ Deeply nested if-err chains — flatten with early returns
- ❌ `interface{}` / `any` where concrete type works
