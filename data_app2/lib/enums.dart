/// Datatype for table column
enum TabularType { int, cat } // TODO Add dec?

/// Frequency of table records
enum TableFreq { free, day, week }

/// What are we importing
enum ImportMode { event, tabular }

/// how is it going?
enum ImportState { loading, ready, done, error }
