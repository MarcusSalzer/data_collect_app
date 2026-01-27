/// Datatype for table column
enum TabularType { int, cat } // TODO Add dec?

/// Frequency of table records
enum TableFreq { free, day, week }

/// Frequency of grouping timestamps
enum GroupFreq { day, week, month }

/// What are we importing (Deprecated??)
enum ImportMode { event, tabular }

/// What are we importing
enum ImportFileRole { events, eventTypes, unknown }

/// What to summarize
enum SummaryMode {
  evtType,
  category;

  String get description => switch (this) {
    evtType => "Summarize each type separately.",
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

/// How to aggregate events in time
enum RangeAggMode {
  start,
  end,
  inside;

  String get description => switch (this) {
    start => "todo.",
    end => "todo.",
    inside => "todo",
  };
}
