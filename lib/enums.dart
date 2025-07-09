enum MessageThreadFilter {
  all('All'),
  hosting('Hosting'),
  traveling('Traveling'),
  support('Support');

  const MessageThreadFilter(this.title);

  final String title;
}

enum HostingSubFilter {
  unread('Unread', 'hosting-sub'),
  tripStage('Trip stage', 'hosting-sub'),
  starred('Starred', 'hosting-sub');

  const HostingSubFilter(this.title, this.prefix);

  final String title;
  final String prefix;
}

enum TravelingSubFilter {
  unread('Unread', 'traveling-sub'),
  starred('Starred', 'traveling-sub');

  const TravelingSubFilter(this.title, this.prefix);

  final String title;
  final String prefix;
}

enum SupportSubFilter {
  unread('Unread', 'support-sub');

  const SupportSubFilter(this.title, this.prefix);

  final String title;
  final String prefix;
}

enum FilterViewState { showingMain, showingSubFilters }
