/// Datatype for table column
enum TabularType { int, cat }

/// Frequency of table records
enum TableFreq { free, day, week }

/// Frequency of grouping timestamps
enum GroupFreq { day, week, month }

/// What are we importing (Deprecated??)
enum ImportMode { event, tabular }

/// What are we importing
enum ImportFileRole { events, eventTypes, eventCats, unknown }

/// How to consider events in a range
enum OverlapMode { fullyInside, overlapping, endInside }

/// How to summarize events in a range
enum RangeSummaryInclusionMode {
  fullyInside,
  endsIn,
  endsInPlusFill;

  String get description => switch (this) {
    RangeSummaryInclusionMode.fullyInside => "within",
    RangeSummaryInclusionMode.endsIn => "ends in",
    RangeSummaryInclusionMode.endsInPlusFill => "ends in full",
  };
}

/// What to summarize
enum SummaryMode {
  type,
  category;

  String get description => switch (this) {
    type => "Summarize each type separately.",
    category => "Group summary by category.",
  };
}

/// For storing/loading the loglevel in DB
enum LogLevel {
  off,
  error,
  warning,
  info,
  debug;

  String get description => switch (this) {
    off => "No logging output.",
    error => "Only logs critical errors.",
    warning => "Logs errors and warnings.",
    info => "Logs general information about application behavior.",
    debug => "Logs detailed information for debugging.",
  };
}

/// How to search things
enum TextSearchMode {
  contains,
  starts,
  wordStarts;

  String get label => switch (this) {
    contains => "Contains",
    starts => "Starts with",
    wordStarts => "Word starts",
  };

  String get description => switch (this) {
    contains => "Finds options that contain the query.",
    starts => "Finds options that start with the query.",
    wordStarts => "Finds options where a word starts with the query.",
  };
}

enum ImportStep { scanningFolder, confirmFiles, preparingModels, confirmImport, importing, done, error }

/// How to import data, when its id is already in the DB
enum ImportOverlapPolicy {
  skip,
  // overwrite,
  fail,
  // reassignNew, // make new ids
}
