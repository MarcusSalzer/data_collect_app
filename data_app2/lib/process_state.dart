// Define a sealed base type
sealed class ProcessState<T> {
  const ProcessState();
}

// Variants
class Loading<T> extends ProcessState<T> {
  const Loading();
}

class Ready<T> extends ProcessState<T> {
  final T data;
  const Ready(this.data);
}

class Done<T> extends ProcessState<T> {
  const Done();
}

class Error<T> extends ProcessState<T> {
  // TODO: Use title+ descr instead? + extradata..
  final Object error;
  final List<String>? examples;
  const Error(this.error, {this.examples});
}
