/// Datatype for table column
enum TabularType { int, cat } // TODO Add dec?

/// Frequency of table records
enum TableFreq { free, day, week }

/// Frequency of grouping timestamps
enum GroupFreq { day, week, month }

/// What are we importing
enum ImportMode { event, tabular }
