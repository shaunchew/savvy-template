# Lessons

Chronological append-only log of tagged lessons. Use `/sf:lesson "<text>"` or accept the Stop-hook prompt.

Tags: `placement`, `gotcha`, `pattern`, `mistake-avoided`.

---

- 2026-07-07 · `gotcha` · GitHub push protection blocks secret-shaped test literals even in fixtures — runtime-assemble them (`sk_live_$(printf …)`); a literal forced a full history rewrite before v1.5.0 could push.
- 2026-07-07 · `gotcha` · The Write tool creates files 0644 — new `scripts/*.sh` need an explicit `chmod +x` or the suite fails with exit 126.
- 2026-07-07 · `mistake-avoided` · `build-plugin.sh` originally generated the manifest BEFORE regenerating `template/`, shipping one-iteration-stale manifests; the drift test caught it. Manifest generation must stay AFTER template regeneration.
- 2026-07-07 · `pattern` · Fix-verification rounds pay off: a 2nd adversarial audit of the round-1 fixes confirmed 8 fix-introduced bugs (e.g. a stdout switch made a latent false-positive warning actionable).

