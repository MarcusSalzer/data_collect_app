## roadmap

- ✅ 25-04-12 Normalize all
- ✅ 25-04-19 Some summary graph
- ✅ 25-04-23 TodaySummary widget
- ✅ 25-04-26 EventManager
- ✅ 25-05-03 cleaner CSV import
- ✅ 25-05-18 tabular data: integers
- ✅ 25-05-30 edit event names, calendar view, prevent rotation
- ✅ 25-06-08 day view `v0.0.6`
- ✅ 25-08-19 migrate events from String -> Cats
- ✅ 25-09-13 big refactor: edits+IO, TZ-safety, type-manager, MVM-architecture. `v0.0.7`
- ❓ ??/? in app benchmark, logging?
- ❓ ??/? DB summary screen (count and storage sizes)
- ❓ ??/? Event Filter
- ❓ ??/? user defined export directory, improved settings page
- ❓ ??/? auto-backup (more compact file format?)
- ❓ ??/? Linting: duplicates, overlapping events
- ❓ ??/? user defined "day starts at"
- ❓ ??/? export screen? for example choose iso8601 or ms?
- ❓ ??/? better calendar UI, horizontal page + vertical scroll?
- ❓ ??/? computed color system
- ❓ ??/? Safer import, exact duplicate detection etc?
- ❓ ??/? tabular data, link to event
- ❓ ??/? computed color system (color groups for categories?)
- ❓ ??/? event type timeseries stats view
- ❓ ??/? smarter suggestions
- ❓ ??/? event aggregations. per-day-db? or save to file?
- ❓ ??/? bag of activity vector
- ❓ ??/? flexible Preference DB

## TODO/bugs

- is calendar TZ safe?

## Overall architecture

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
