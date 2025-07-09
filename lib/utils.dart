

import 'enums.dart';

sealed class FilterListItem {
  String get id;
}

class MainFilterItem extends FilterListItem {
  final MessageThreadFilter filter;
  final bool isBack;

  MainFilterItem(this.filter, {this.isBack = false});

  @override
  String get id => isBack ? 'back-${filter.name}' : filter.name;
}

class SubFilterItem<T> extends FilterListItem {
  final T subfilter;
  final String prefix;

  SubFilterItem(this.subfilter, this.prefix);

  @override
  String get id {
    final name = _getSubfilterName(subfilter);
    return '$prefix-$name';
  }

  String _getSubfilterName(T subfilter) {
    if (subfilter is HostingSubFilter) return (subfilter as HostingSubFilter).name;
    if (subfilter is TravelingSubFilter) return (subfilter as TravelingSubFilter).name;
    if (subfilter is SupportSubFilter) return (subfilter as SupportSubFilter).name;
    throw ArgumentError('Unknown subfilter type: $subfilter');
  }
}

// FilterListItem createSubfilterItem(Enum subfilter) {
//   if (subfilter is HostingSubFilter) {
//     return SubFilterItem(subfilter, 'hosting-sub');
//   } else if (subfilter is TravelingSubFilter) {
//     return SubFilterItem(subfilter, 'traveling-sub');
//   } else if (subfilter is SupportSubFilter) {
//     return SubFilterItem(subfilter, 'support-sub');
//   } else {
//     throw ArgumentError('Unknown subfilter type: $subfilter');
//   }
// }