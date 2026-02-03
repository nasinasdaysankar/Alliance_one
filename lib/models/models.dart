class EventCategory {
  final String title;
  final String description;
  final List<EventItem> events;

  const EventCategory({
    required this.title,
    this.description = '',
    required this.events,
  });
}

class EventItem {
  final String title;
  final String description;
  final List<String> rules;
  final List<String> details;
  final String? url;

  const EventItem({
    required this.title,
    this.description = '',
    required this.rules,
    this.details = const [],
    this.url,
  });
}
