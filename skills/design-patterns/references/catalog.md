# Design Patterns Catalog

## Creational Patterns

### Factory Method
Define an interface for creating an object, but let subclasses decide which class to instantiate.

```typescript
// The pattern
interface PaymentGateway { charge(amount: Money): Result }
class StripeGateway implements PaymentGateway { ... }
class MidtransGateway implements PaymentGateway { ... }

class PaymentFactory {
  static create(type: 'stripe' | 'midtrans'): PaymentGateway {
    if (type === 'stripe') return new StripeGateway();
    return new MidtransGateway();
  }
}
```

**When:** A class doesn't know the exact type of objects it must create.
**Modern alt:** `(type) => new Gateway(type)` — factory function, not a class.

### Abstract Factory
Provide an interface for creating *families* of related objects.

```typescript
interface UIFactory { createButton(): Button; createDialog(): Dialog }
class MaterialFactory implements UIFactory { ... }
class AntDesignFactory implements UIFactory { ... }
```

**When:** You need to enforce that objects from the same family are used together (Material button with Material dialog).
**Real example:** UI theme systems, database abstraction across vendors.

### Builder
Separate the construction of a complex object from its representation.

```typescript
class QueryBuilder {
  private select: string[] = [];
  private from = '';
  private where: string[] = [];

  select(...fields: string[]) { this.select.push(...fields); return this; }
  from(table: string) { this.from = table; return this; }
  where(condition: string) { this.where.push(condition); return this; }
  build() { return `SELECT ${this.select.join(', ')} FROM ${this.from} WHERE ${this.where.join(' AND ')}`; }
}

// Usage
new QueryBuilder().select('id', 'name').from('users').where('active = true').build();
```

**When:** An object has many optional parts or complex construction.

### Singleton
Ensure a class has only one instance and provide a global access point.

```typescript
// The pattern — but prefer DI
class Config {
  private static instance: Config;
  static getInstance(): Config {
    if (!Config.instance) Config.instance = new Config();
    return Config.instance;
  }
}
```

**⚠️ Use sparingly.** Singletons are global state in disguise. Prefer DI container managing a single instance.
**Only acceptable:** Logging, hardware interfaces, actual system-wide singletons.

### Prototype
Create new objects by cloning an existing instance.

```typescript
class Document implements Cloneable {
  clone(): Document { return structuredClone(this); }
}
```

**When:** Creating objects is expensive and cloning is cheaper (config objects, document templates).

---

## Structural Patterns

### Adapter
Convert one interface into another that the client expects.

```typescript
// Legacy interface
class LegacyMailer { sendMail(from: string, to: string, body: string) { ... } }
// New interface
interface NotificationService { send(recipient: string, message: string): void }

class MailerAdapter implements NotificationService {
  constructor(private legacy: LegacyMailer) {}
  send(recipient: string, message: string) {
    this.legacy.sendMail('noreply@x.com', recipient, message);
  }
}
```

**When:** Interface mismatch between expected and actual. Wrap, don't modify.

### Bridge
Decouple an abstraction from its implementation so they can vary independently.

```typescript
// Abstraction
abstract class Remote { abstract press(): void }
class TVRemote extends Remote { constructor(private device: TV) {} }
class RadioRemote extends Remote { constructor(private device: Radio) {} }

// Implementation
interface Device { on(): void; off(): void }
class SonyTV implements Device { ... }
class PhilipsTV implements Device { ... }
```

**When:** Both the abstraction and implementation vary independently.

### Composite
Compose objects into tree structures to represent part-whole hierarchies.

```typescript
interface FileSystemNode { getSize(): number; }
class File implements FileSystemNode { constructor(private size: number) {} getSize() { return this.size; } }
class Directory implements FileSystemNode {
  constructor(private children: FileSystemNode[]) {}
  getSize() { return this.children.reduce((acc, c) => acc + c.getSize(), 0); }
}
```

**When:** Tree structures (UI trees, file systems, menu hierarchies).

### Decorator
Dynamically add responsibilities to an object.

```typescript
interface DataSource { write(data: string): void; read(): string }
class FileDataSource implements DataSource { ... }

class CompressionDecorator implements DataSource {
  constructor(private wrappee: DataSource) {}
  write(data: string) { this.wrappee.write(compress(data)); }
  read() { return decompress(this.wrappee.read()); }
}

new CompressionDecorator(new EncryptionDecorator(new FileDataSource('file.txt')));
```

**When:** You need to layer behavior (middleware, streams, I/O pipelines).
**Modern alt:** Hono/Express middleware chains are a functional take on Decorator.

### Facade
Provide a unified interface to a complex subsystem.

```typescript
class PaymentFacade {
  async pay(amount: Money, method: PaymentMethod): Promise<Receipt> {
    const gateway = PaymentFactory.create(method.type);
    const result = await gateway.charge(amount);
    await this.receiptRepo.save(result.receipt);
    await this.notifier.send(result.receipt);
    return result.receipt;
  }
}
```

**When:** Simplifying a complex subsystem with a single entry point.

### Flyweight
Share common state across many objects to save memory.

```typescript
class Character {
  constructor(public char: string, public style: TextStyle) {} // style shared
}
class TextStyle { constructor(public font: string, public size: number, public bold: boolean) {} }
```

**When:** Many fine-grained objects with shared intrinsic state (text editors, game particle systems).

### Proxy
Control access to another object.

```typescript
class CachedUserRepo implements UserRepository {
  private cache = new Map<string, User>();
  constructor(private real: UserRepository) {}
  async findById(id: string): Promise<User | null> {
    if (this.cache.has(id)) return this.cache.get(id)!;
    const user = await this.real.findById(id);
    if (user) this.cache.set(id, user);
    return user;
  }
}
```

**When:** Lazy loading, caching, access control, logging — without modifying the real object.

---

## Behavioral Patterns

### Strategy
Define a family of algorithms, encapsulate each one, and make them interchangeable.

```typescript
interface AuthStrategy { authenticate(creds: Credentials): Promise<User> }
class PasswordAuth implements AuthStrategy { ... }
class OAuthStrategy implements AuthStrategy { ... }
class MFAStrategy implements AuthStrategy { ... }

class AuthService {
  constructor(private strategy: AuthStrategy) {}
  async login(creds: Credentials) { return this.strategy.authenticate(creds); }
}
```

**When:** Multiple algorithms for the same task. **Modern alt:** Pass a lambda/function.

### Observer
Define a one-to-many dependency so that when one object changes state, all dependents are notified.

```typescript
class EventBus {
  private handlers = new Map<string, Function[]>();
  on(event: string, handler: Function) { ... }
  emit(event: string, data: unknown) { ... }
}
```

**When:** Event handling, pub/sub, data binding. **Modern alt:** Reactive streams (RxJS), event emitters.

### Command
Encapsulate a request as an object, allowing parameterization, queuing, and undo.

```typescript
interface Command { execute(): void; undo(): void }
class CreateOrderCommand implements Command { ... }
class CancelOrderCommand implements Command { ... }
class CommandQueue {
  private history: Command[] = [];
  execute(cmd: Command) { cmd.execute(); this.history.push(cmd); }
  undo() { this.history.pop()?.undo(); }
}
```

**When:** Job queues, undo/redo, transaction logging.
**Modern alt:** Functions as first-class commands (JS/TS closures).

### Template Method
Define the skeleton of an algorithm, letting subclasses override specific steps.

```typescript
abstract class DataExporter {
  export(): string {
    const data = this.fetch();
    const formatted = this.format(data);
    return this.write(formatted);
  }
  abstract fetch(): unknown;
  abstract format(data: unknown): string;
  abstract write(data: string): string;
}
class CSVExporter extends DataExporter { ... }
class JSONExporter extends DataExporter { ... }
```

**When:** Multiple implementations share the same algorithm structure but vary in steps.

### State
Allow an object to alter its behavior when its internal state changes.

```typescript
interface OrderState { next(order: Order): void; cancel(order: Order): void }
class PendingState implements OrderState { ... }
class PaidState implements OrderState { ... }
class ShippedState implements OrderState { ... }
class CancelledState implements OrderState { ... }
```

**When:** An object's behavior depends on its state and must change at runtime (orders, documents, workflows).

### Chain of Responsibility
Pass a request along a chain of handlers until one processes it.

```typescript
abstract class Handler {
  constructor(protected next?: Handler) {}
  abstract handle(request: HttpRequest): HttpResponse | null;
}

class AuthHandler extends Handler { handle(r) { return r.isAuthenticated ? this.next?.handle(r) : new HttpResponse(401); } }
class RateLimitHandler extends Handler { handle(r) { return r.notRateLimited ? this.next?.handle(r) : new HttpResponse(429); } }
class Router extends Handler { handle(r) { return new HttpResponse(200, 'OK'); } }

new AuthHandler(new RateLimitHandler(new Router()));
```

**When:** Middleware, validation pipelines, logging chains.

### Visitor
Represent an operation to be performed on elements of an object structure.

```typescript
interface ASTNode { accept(v: Visitor): void }
class NumberNode implements ASTNode { accept(v) { v.visitNumber(this); } }
class BinaryOpNode implements ASTNode { accept(v) { v.visitBinaryOp(this); } }

interface Visitor { visitNumber(node: NumberNode): void; visitBinaryOp(node: BinaryOpNode): void }
class Evaluator implements Visitor { ... }
class ASTPrinter implements Visitor { ... }
```

**When:** You need to add new operations to a stable object structure. Use with caution — it violates OCP if the structure changes.

---

## When to NOT Use a Pattern

- **Pattern for pattern's sake** — a simple function is better than a Strategy class with one implementation.
- **AbstractFactoryFactory** — over-abstracting what a simple `new` handles.
- **Singleton as global state** — use DI with single instance.
- **Observer with no actual observers** — simple callbacks suffice.
- **Visitor with a changing object structure** — every new type means updating all visitors.
