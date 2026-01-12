## roadmap

- ✅ _25-04-12_ Normalize all
- ✅ _25-04-23_ TodaySummary widget
- ✅ _25-04-26_ EventManager
- ✅ _25-05-03_ cleaner CSV import
- ✅ _25-05-18_ tabular data: integers
- ✅ _25-05-30_ edit event names, calendar view, prevent rotation
- ✅ _25-06-08_ day view `v0.0.6`
- ✅ _25-08-19_ migrate events from String -> Type Records
- ✅ _25-09-13_ big refactor: edits+IO, TZ-safety, type-manager, MVM-architecture. `v0.0.7`
- ✅ _25-12-11_ refactor db-repos, clean up settings, logging.
- ✅ _25-12-16_ Filter, select and summarize (event types) `v0.0.8`
- ✅ _26-01-12_ Export csv event summary, Import/export event types. Faster import. Consistent text search behavior. `v0.0.9`
- ❓ event type timeseries stats view, range inclusion setting, user defined "day starts at"
- ❓ Improved suggestions (recent, dynamic, pinned)
- ❓ auto-backup, backup pruning (more compact file format?)
- ❓ Linting: duplicates, overlapping events
- ❓ Welcome screen
- ❓ even safer+faster import? batching, exact duplicate detection etc?
- ❓ better calendar UI, horizontal page + vertical scroll?
- ❓ tabular data, link to event
- ❓ improved color system (color groups for categories?)
- ❓ event aggregations. per-day-db? or save to file?
- ❓ Persistent event filter, can apply globally in app.
- ❓ bag of activity vector

## Known and suspected issues

- is calendar TZ safe?
- Reduce storage permissions?
- today-summary sometimes forgets cached type-recs. also, might want to reload/precompute more.
- pop import dialog

## Overall architecture

- UI goes in `lib/screens`, `lib/widgets`, `lib/dialogs`.
- Data access in `lib/repos`.

### Home

- today's overview
- navigation

### Events

- start/stop, see latest

### Event types

- see all types, with count
- go to overview + edit

### Calendar

- monthly summary
- go to day summary

### import

- Choose a CSV file with events

### Settings

- color scheme
- delete all data

## notes

- When updating app with `flutter install`, the database is (partially?) cleared. So remember to save a backup, and load after.
