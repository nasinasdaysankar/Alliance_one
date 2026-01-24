import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class FindVenueScreen extends StatelessWidget {
  const FindVenueScreen({super.key});

  final List<Map<String, String>> _venues = const [
    {
      'name': 'Alfresco',
      'query': 'Alfresco, Alliance University',
      'description': 'Open-air dining and hanging out spot',
      'icon': 'restaurant_menu',
    },
    {
      'name': 'Admin Block',
      'query': 'Alliance University Admin Block',
      'description': 'Main administrative building',
      'icon': 'admin_panel_settings',
    },
    {
      'name': 'Football Ground',
      'query': 'Alliance University Football Ground',
      'description': 'Main sports ground',
      'icon': 'sports_soccer',
    },
    {
      'name': 'LC1 Block',
      'query': 'Alliance School of Law, Alliance University',
      'description': 'Alliance School of Law',
      'icon': 'class',
    },
    {
      'name': 'LC2 Block',
      'query': 'Alliance College of Engineering and Design',
      'description': 'Alliance College of Engineering and Design',
      'icon': 'school',
    },
    {
      'name': 'Library',
      'query': 'Alliance University Library',
      'description': 'Central Library',
      'icon': 'local_library',
    },
  ];

  Future<void> _launchMaps(String query) async {
    final Uri googleMapsUrl = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}');
    final Uri appleMapsUrl = Uri.parse(
        'https://maps.apple.com/?q=${Uri.encodeComponent(query)}');

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(appleMapsUrl)) {
      await launchUrl(appleMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch maps';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Find Venue',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, Color(0xFF1A1A2E)],
          ),
        ),
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _venues.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final venue = _venues[index];
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _launchMaps(venue['query']!),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF252525),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.05),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C63FF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getIcon(venue['icon']!),
                          color: const Color(0xFF6C63FF),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              venue['name']!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              venue['description']!,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: Colors.white.withOpacity(0.3),
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'restaurant_menu':
        return Icons.restaurant_menu;
      case 'admin_panel_settings':
        return Icons.admin_panel_settings;
      case 'sports_soccer':
        return Icons.sports_soccer;
      case 'class':
        return Icons.class_;
      case 'school':
        return Icons.school;
      case 'local_library':
        return Icons.local_library;
      default:
        return Icons.location_on;
    }
  }
}
