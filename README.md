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
- ✅ _26-01-12_ Export event summary, Import/export types. Faster import. Consistent text search. `v0.0.9`
- ✅ _26-02-02_ Welcome screen, categories, standardized Repos, CSV and domain models. `v0.1.0`
- ✅ _26-02-06_ JSON-serializable prefs, improved test coverage, Import help screen
- ✅ _26-02-10_ Consistent edit screens, category-color system. Daily summary `v0.1.1`
- ❓ "day starts at", better time range filter, test coverage, state consumer cleanup

Maybe:

- ❓ Persistent event filter, can apply globally in app?
- ❓ event type stats: timeseries and summary statistics
- ❓ tabular data, link to event
- ❓ auto-backup, backup pruning (more compact file format?)
- ❓ Linting: duplicates, overlapping events, DB change detection
- ❓ Improved suggestions (recent, dynamic, pinned)
- ❓ better calendar UI, horizontal page + vertical scroll?
- ❓ event aggregations. per-day-db? or save to file?
- ❓ bag of activity vector
- ❓ location data type

## Known and suspected issues

- is calendar TZ safe?
- Reduce storage permissions?
- today-summary sometimes forgets cached type-recs. also, might want to reload/precompute more.

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
