import 'models.dart';

class EventsData {
  static const List<EventCategory> allCategories = [
    EventCategory(
      title: 'ALLIANCE ONE',
      description: 'Main Event Portal',
      events: [
        EventItem(
          title: 'Alliance One',
          description: 'Click to access Alliance One',
          rules: [],
          url: 'https://one.alliance.edu.in',
        ),
      ],
    ),
    EventCategory(
      title: 'RESULTS',
      description: 'Check Your Results',
      events: [
        EventItem(
          title: 'Results',
          description: 'Click to view results',
          rules: [],
          url: 'https://results.pmk.codes',
        ),
      ],
    ),
  ];
}
