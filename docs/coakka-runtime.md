# CoAkka Runtime

CoAkka Runtime is for application-owned work that needs a clear boundary but
does not deserve another private backend HTTP endpoint.

It gives the host application a small connector API while the native runtime
owns target routing, active route generation, bounded admission, reply
matching, deadletters, lifecycle state, and diagnostics.

## The Boundary It Replaces

Many systems keep a real public HTTP edge, then grow a second private HTTP API
only to call work owned by the same app or team:

```text
browser or public client
  -> public API
  -> private backend URL
  -> handler
```

CoAkka keeps the public edge where it belongs, but replaces the fake internal
URL with a named target:

```text
browser or public client
  -> public API
  -> CoAkka target "customer.store.create"
  -> handler
  -> reply or deadletter
```

The claim is not "HTTP is bad." Public HTTP, gRPC, auth, deployment policy,
and product APIs still belong to the application. CoAkka is for the internal
runtime boundary where work is clearer as a target than as another backend URL.

## What The Runtime Owns

| Concern | Runtime role |
| --- | --- |
| Target routing | Resolve a target name through the active route snapshot. |
| Request/reply | Correlate replies back to the caller within the caller's timeout budget. |
| Deadletters | Return delivery failure evidence instead of hiding misses behind generic timeouts. |
| Route generation | Apply newer route snapshots atomically and reject stale snapshots. |
| Bounded admission | Keep queues explicit so pressure can be observed and handled. |
| Diagnostics | Expose runtime info, health, config, stats, and route evidence. |

The app still owns validation, authorization, transactions, idempotency,
business semantics, public response shape, and rollout policy.

## Same Process First

The first useful shape is often one process:

```text
controller/job/UI command -> runtime target -> local handler -> reply
```

That lets a team remove one awkward internal boundary while keeping the rest of
the system unchanged. The same target vocabulary can later move to another
process or language when the boundary needs to scale.

## Cross-Language Shape

CoAkka is useful when a capability boundary has to survive language or process
changes:

```text
Go API -> target "customer.store.create" -> Swift, Python, JVM, Node, or Go handler
```

The caller keeps asking a target. The active route decides whether the handler
is local, remote, or missing. A missing route becomes a deadletter with target
and generation context.

## Why It Matters

CoAkka makes the boundary explicit:

- target names describe capability ownership better than private URLs
- route snapshots make delivery state observable
- deadletters are terminal evidence, not vague timeout guesses
- bounded queues make pressure visible before the host loses control
- connectors let each language keep idiomatic API shape over one runtime model

## Read Next

- AI-assisted integration: `https://github.com/phuong-tran/coakka-samples/blob/main/docs/ai-assisted-integration.md`
- Runtime model: `https://github.com/phuong-tran/coakka-samples/blob/main/docs/runtime-message-and-routing-model.md`
- How it works: `https://github.com/phuong-tran/coakka-samples/blob/main/docs/how-it-works.md`
- Incremental adoption: `https://github.com/phuong-tran/coakka-samples/blob/main/docs/incremental-adoption.md`
- Compatibility: `https://github.com/phuong-tran/coakka-publish/blob/main/docs/compatibility-matrix.md`
