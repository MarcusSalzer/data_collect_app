## roadmap

- ✅ 12/4 Normalize all
- ✅ 19/4 Some summary graph
- ✅ 23/4 TodaySummary widget
- ✅ 26/4 EventManager
- ✅ 03/5 cleaner CSV import
- ✅ 18/5 tabular data: integers
- ✅ 28/5 edit event names
- ✅ 29/5 calendar view
- ✅ 30/5 prevent rotation
- ✅ 08/6 day view `v0.0.6`
- ✅ 19/8 migrate events from String -> Cats
- ❓ ??/? big refactor: safe edits+IO, TZs, colors, type-manager, MVM-architecture. `v0.0.7`
- ❓ ??/? in app benchmark, logging?
- ❓ ??/? Event Filter
- ❓ ??/? event aggregations. per-day-db?
- ❓ ??/? user defined export directory, improved settings page
- ❓ ??/? auto-backup (more compact file format?)
- ❓ ??/? detect duplicates and overlapping events
- ❓ ??/? user defined "day starts at"
- ❓ ??/? export screen? for example choose iso8601 or ms?
- ❓ ??/? better calendar UI, horizontal page + vertical scroll?
- ❓ ??/? DB summary screen (count and storage sizes)
- ❓ ??/? computed color system
- ❓ ??/? Safer import, exact duplicate detection etc?

## Overall architecture

### Events

- Stored in DB

Event types

## notes

- When updating app with `flutter install`, the database is (partially?) cleared. So remember to save a backup, and load after.

## ideas

- day2vec
- event details, what/for/where/how
