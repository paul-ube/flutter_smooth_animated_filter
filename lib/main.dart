import 'package:flutter/material.dart';
import 'package:smooth_animated_filter/enums.dart';
import 'package:smooth_animated_filter/utils.dart';

import 'constants.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const ScaffoldWrapper(),
    );
  }
}

class ScaffoldWrapper extends StatelessWidget {
  const ScaffoldWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: SliverAppBar.large(
                title: Text('Messages'),
                forceElevated: innerBoxIsScrolled,
                leading: Icon(
                  Icons.arrow_back,
                  color: colorScheme.onSurfaceVariant,
                ),
                actions: [
                  IconButton(onPressed: () {}, icon: Icon(Icons.search)),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(m3ToolbarHeight),
                  child: Filter(),
                ),
              ),
            ),
          ];
        },
        body: Builder(
          builder: (context) {
            return CustomScrollView(
              slivers: [
                SliverOverlapInjector(
                  handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                    context,
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: colorScheme.surfaceContainerHigh,
                        foregroundColor: colorScheme.onSurfaceVariant,
                        child: Icon(Icons.person_rounded),
                      ),
                      title: Text('Message'),
                      subtitle: Text('This is message $index'),
                    );
                  }),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class Filter extends StatefulWidget {
  const Filter({super.key});

  @override
  State<Filter> createState() =>
      _FilterState();
}

class _FilterState extends State<Filter> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  late List<FilterListItem> _currentItems;

  FilterViewState viewState = FilterViewState.showingMain;
  bool _wasShowingSubfilters = false;

  MessageThreadFilter selectedFilter = MessageThreadFilter.all;
  final Set<Enum> subfilters = {};

  @override
  void initState() {
    super.initState();
    _currentItems = _buildFilterList();
    _wasShowingSubfilters = viewState == FilterViewState.showingSubFilters;
  }

  void setSelectedFilter(MessageThreadFilter filter) {
    final isSameFilter = selectedFilter == filter;
    final newFilter = isSameFilter ? MessageThreadFilter.all : filter;
    final isAllFilter = newFilter == MessageThreadFilter.all;

    setState(() {
      selectedFilter = newFilter;
      viewState = isAllFilter
          ? FilterViewState.showingMain
          : FilterViewState.showingSubFilters;

      if (isAllFilter) subfilters.clear();

      updateList();
    });
  }

  void toggleSubfilters(Enum filter) {
    setState(() {
      subfilters.contains(filter)
          ? subfilters.remove(filter)
          : subfilters.add(filter);

      updateList();
    });
  }

  void resetFilters() => setSelectedFilter(MessageThreadFilter.all);

  List<FilterListItem> _buildFilterList() {
    final list = <FilterListItem>[
      MainFilterItem(
        MessageThreadFilter.all,
        isBack: viewState == FilterViewState.showingSubFilters,
      ),
    ];

    if (viewState == FilterViewState.showingMain) {
      list.addAll([
        MainFilterItem(MessageThreadFilter.hosting),
        MainFilterItem(MessageThreadFilter.traveling),
        MainFilterItem(MessageThreadFilter.support),
      ]);
    } else {
      list.add(MainFilterItem(selectedFilter));
      final subEnumValues = switch (selectedFilter) {
        MessageThreadFilter.hosting => HostingSubFilter.values,
        MessageThreadFilter.traveling => TravelingSubFilter.values,
        MessageThreadFilter.support => SupportSubFilter.values,
        _ => [],
      };

      for (final sub in subEnumValues) {
        list.add(SubFilterItem(sub, sub.prefix));
      }
    }

    return list;
  }

  void updateList() {
    final newItems = _buildFilterList();
    final newIds = newItems.map((e) => e.id).toSet();

    final isNowSubfilters = viewState == FilterViewState.showingSubFilters;
    final isEnteringSubfilterView = isNowSubfilters && !_wasShowingSubfilters;
    _wasShowingSubfilters = isNowSubfilters;

    for (int i = _currentItems.length - 1; i >= 0; i--) {
      final item = _currentItems[i];
      if (!newIds.contains(item.id)) {
        final shouldAnimate = isEnteringSubfilterView ||
            item.id == 'all' ||
            item.id.startsWith('back');

        _listKey.currentState?.removeItem(
          i,
              (context, animation) => _buildChip(
            context,
            item,
            animation,
            isRemoved: true,
            isFromMainToSub: isEnteringSubfilterView,
          ),
          duration: shouldAnimate
              ? const Duration(milliseconds: kExpressiveFastSpacialDuration)
              : Duration.zero,
        );

        _currentItems.removeAt(i);
      }
    }

    // Animate insertions
    for (int i = 0; i < newItems.length; i++) {
      final item = newItems[i];
      final exists = _currentItems.any((e) => e.id == item.id);
      if (!exists) {
        _currentItems.insert(i, item);

        final duration = Duration(milliseconds: kExpressiveFastSpacialDuration);
        final delay = item is SubFilterItem
            ? Duration(
          milliseconds: (kExpressiveFastSpacialDuration / 2 + (i * 10)).toInt(),
        )
            : Duration.zero;

        Future.delayed(delay, () {
          _listKey.currentState?.insertItem(i, duration: duration);
        });
      }
    }
  }

  Widget _buildChip(
      BuildContext context,
      FilterListItem item,
      Animation<double> animation, {
        bool isRemoved = false,
        bool isFromMainToSub = false,
      }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final Widget chip = switch (item) {
      MainFilterItem main => _buildMainChip(main, colorScheme),
      SubFilterItem sub => _buildSubChip(sub, colorScheme),
      _ => const SizedBox.shrink(),
    };

    return _buildChipAnimation(item, chip, animation, isRemoved, isFromMainToSub);
  }

  Widget _buildMainChip(MainFilterItem item, ColorScheme colorScheme) {
    final isSelected = selectedFilter == item.filter;
    final isAll = item.filter == MessageThreadFilter.all;
    final isShowingSubfilters =
        viewState == FilterViewState.showingSubFilters;

    return FilledButton(
      key: ValueKey(item.id),
      style: FilledButton.styleFrom(
        backgroundColor: isSelected
            ? colorScheme.primary
            : colorScheme.surfaceContainer,
        foregroundColor: isSelected
            ? colorScheme.onPrimary
            : colorScheme.onSurfaceVariant,
        shape: isSelected
            ? RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(m3MediumShapeRadius),
        )
            : const StadiumBorder(),
        minimumSize: const Size(48, 40),
        padding: isAll && isShowingSubfilters
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(horizontal: 24),
      ),
      onPressed: () => setSelectedFilter(item.filter),
      child: isAll && isShowingSubfilters
          ? const Icon(Icons.arrow_back, size: 16)
          : Text(item.filter.title),
    );
  }

  Widget _buildSubChip(SubFilterItem item, ColorScheme colorScheme) {
    final isSelected = subfilters.contains(item.subfilter);

    return FilledButton(
      key: ValueKey(item.id),
      style: FilledButton.styleFrom(
        backgroundColor: isSelected
            ? colorScheme.secondary
            : colorScheme.surfaceContainer,
        foregroundColor: isSelected
            ? colorScheme.onSecondary
            : colorScheme.onSurfaceVariant,
        shape: isSelected
            ? RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(m3MediumShapeRadius),
        )
            : const StadiumBorder(),
        minimumSize: const Size(48, 40),
      ),
      onPressed: () => toggleSubfilters(item.subfilter),
      child: Text(item.subfilter.title),
    );
  }

  Widget _buildChipAnimation(
      FilterListItem item,
      Widget chip,
      Animation<double> animation,
      bool isRemoved,
      bool isFromMainToSub,
      ) {
    final isBackOrAll = item is MainFilterItem &&
        (item.id == 'all' || item.id.startsWith('back'));

    if (!isRemoved && isBackOrAll) {
      return FadeTransition(
        opacity: animation.drive(
          Tween(begin: 0.0, end: 1.0)
              .chain(CurveTween(curve: kExpressiveFastSpacialCurve)),
        ),
        child: ScaleTransition(
          scale: animation.drive(
            Tween(begin: 0.5, end: 1.0)
                .chain(CurveTween(curve: kExpressiveFastSpacialCurve)),
          ),
          child: chip,
        ),
      );
    }

    if (isRemoved && item is MainFilterItem) {
      return SizeTransition(
        sizeFactor: animation.drive(
          Tween(begin: 0.0, end: 1.0)
              .chain(CurveTween(curve: kExpressiveFastSpacialCurve.flipped)),
        ),
        axis: Axis.horizontal,
        child: FadeTransition(
          opacity: animation.drive(
            Tween(begin: 0.0, end: 0.1)
                .chain(CurveTween(curve: kExpressiveFastSpacialCurve.flipped)),
          ),
          child: ScaleTransition(
            scale: animation.drive(
              Tween(begin: 0.95, end: 1.0)
                  .chain(CurveTween(curve: kExpressiveFastSpacialCurve.flipped)),
            ),
            child: chip,
          ),
        ),
      );
    }

    if (!isRemoved && item is MainFilterItem) {
      return SizeTransition(
        sizeFactor: animation.drive(
          Tween(begin: 0.0, end: 1.0)
              .chain(CurveTween(curve: kExpressiveFastSpacialCurve)),
        ),
        axis: Axis.horizontal,
        child: FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: animation.drive(
              Tween(begin: 0.95, end: 1.0)
                  .chain(CurveTween(curve: kExpressiveFastSpacialCurve)),
            ),
            child: chip,
          ),
        ),
      );
    }

    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: animation.drive(
          Tween(begin: 0.8, end: 1.0)
              .chain(CurveTween(curve: kExpressiveFastSpacialCurve)),
        ),
        child: chip,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: m3ToolbarHeight,
      alignment: Alignment.centerLeft,
      child: AnimatedList(
        key: _listKey,
        initialItemCount: _currentItems.length,
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemBuilder: (context, index, animation) {
          final item = _currentItems[index];
          return Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? kIndent : 4,
              right: index == _currentItems.length - 1 ? 16 : 4,
            ),
            child: _buildChip(context, item, animation),
          );
        },
      ),
    );
  }
}
