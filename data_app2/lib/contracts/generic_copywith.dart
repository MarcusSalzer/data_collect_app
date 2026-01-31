class _Unset {
  const _Unset();
}

const unset = _Unset();

/// Maybe useful for updating nullable fields
/// If we dont want specific updating methods
mixin CopyWithNullableFields<T> {
  T copyWithInternal(Map<Symbol, Object?> updates);

  T copyWith(Map<Symbol, Object?> updates) {
    return copyWithInternal(updates);
  }
}
TField resolve<TField>(Object? value, TField current) {
  return identical(value, unset) ? current : value as TField;
}
// class EvtDraft with CopyWith<EvtDraft> {
//   final DateTime? start;
//   final DateTime? end;
//   final int typeId;

//   const EvtDraft({
//     required this.typeId,
//     this.start,
//     this.end,
//   });

//   @override
//   EvtDraft copyWithInternal(Map<Symbol, Object?> u) {
//     return EvtDraft(
//       typeId: resolve(u[#typeId] ?? unset, typeId),
//       start: resolve(u[#start] ?? unset, start),
//       end: resolve(u[#end] ?? unset, end),
//     );
//   }

//   EvtDraft copyWith({
//     Object? typeId = unset,
//     Object? start = unset,
//     Object? end = unset,
//   }) {
//     return copyWithInternal({
//       #typeId: typeId,
//       #start: start,
//       #end: end,
//     });
//   }
// }
