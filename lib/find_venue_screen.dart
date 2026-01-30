import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'theme.dart';

class FindVenueScreen extends StatefulWidget {
  const FindVenueScreen({super.key});

  @override
  State<FindVenueScreen> createState() => _FindVenueScreenState();
}

class _FindVenueScreenState extends State<FindVenueScreen>
    with TickerProviderStateMixin {
  late AnimationController _pageController;
  int _hoveredIndex = -1;

  final List<Map<String, String>> _venues = const [
    {
      'name': 'Alfresco',
      'query': 'Alfresco, Alliance University',
      'description': 'Open-air dining and hanging out spot',
      'icon': 'restaurant_menu',
      'color': 'FF6B6B',
    },
    {
      'name': 'Admin Block',
      'query': 'Alliance University Admin Block',
      'description': 'Main administrative building',
      'icon': 'admin_panel_settings',
      'color': '4ECDC4',
    },
    {
      'name': 'Football Ground',
      'query': 'Alliance University Football Ground',
      'description': 'Main sports ground',
      'icon': 'sports_soccer',
      'color': '45B7D1',
    },
    {
      'name': 'LC1 Block',
      'query': 'Alliance School of Law, Alliance University',
      'description': 'Alliance School of Law',
      'icon': 'class',
      'color': 'FFA502',
    },
    {
      'name': 'LC2 Block',
      'query': 'Alliance College of Engineering and Design',
      'description': 'Alliance College of Engineering and Design',
      'icon': 'school',
      'color': '9D84B7',
    },
    {
      'name': 'Library',
      'query': 'Alliance University Library',
      'description': 'Central Library',
      'icon': 'local_library',
      'color': '6C63FF',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _launchMaps(String query) async {
    try {
      final String encodedQuery = Uri.encodeComponent(query);
      final Uri googleMapsUrl = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$encodedQuery',
      );

      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not open maps')));
      }
    }
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

  Color _getColor(String hexColor) {
    return Color(int.parse('FF$hexColor', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Stack(
        children: [
          // Background with gradient
          Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.backgroundGradient,
            ),
          ),
          // Decorative circles
          Positioned(
            left: -80,
            top: 40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            left: -40,
            top: 100,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            left: 20,
            top: 160,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            left: -60,
            top: 280,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),
          Positioned(
            right: -100,
            bottom: 100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6C63FF).withOpacity(0.1),
              ),
            ),
          ),
          // Main content
          Column(
            children: [
              // App Bar
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.05),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.chevron_left_rounded,
                            color: AppTheme.textColor,
                            size: 24,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            'Venues',
                            style: AppTheme.darkTheme.textTheme.displayMedium?.copyWith(
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
              ),
              // Venues list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                  itemCount: _venues.length,
                  itemBuilder: (context, index) {
                    return _buildVenueCard(index);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVenueCard(int index) {
    final venue = _venues[index];
    final accentColor = _getColor(venue['color'] ?? '6C63FF');
    final isHovered = _hoveredIndex == index;

    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, child) {
        final double delayValue = (index * 0.06);
        final double animValue = (_pageController.value - delayValue).clamp(
          0.0,
          1.0,
        );
        final double curvedValue = Curves.easeOut.transform(animValue);

        return Transform.translate(
          offset: Offset(0, 40 * (1 - curvedValue)),
          child: Opacity(opacity: curvedValue, child: child),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: MouseRegion(
          onEnter: (_) {
            setState(() {
              _hoveredIndex = index;
            });
          },
          onExit: (_) {
            setState(() {
              _hoveredIndex = -1;
            });
          },
          child: GestureDetector(
            onTap: () => _launchMaps(venue['query'] ?? ''),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isHovered
                      ? [
                          Colors.white.withOpacity(0.15),
                          Colors.white.withOpacity(0.1),
                        ]
                      : [
                          Colors.black.withOpacity(0.4),
                          Colors.black.withOpacity(0.3),
                        ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isHovered
                      ? accentColor.withOpacity(0.6)
                      : Colors.white.withOpacity(0.15),
                  width: 1.2,
                ),
                boxShadow: isHovered
                    ? [
                        BoxShadow(
                          color: accentColor.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              transform: isHovered
                  ? (Matrix4.identity()..translate(0.0, -6.0))
                  : Matrix4.identity(),
              child: Row(
                children: [
                  // Icon Container
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accentColor.withOpacity(0.2),
                          accentColor.withOpacity(0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: accentColor.withOpacity(isHovered ? 0.4 : 0.3),
                        width: 1.2,
                      ),
                    ),
                    child: Icon(
                      _getIcon(venue['icon'] ?? ''),
                      color: accentColor,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Text Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          venue['name'] ?? 'Venue',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          venue['description'] ?? '',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.2,
                            height: 1.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Arrow Icon
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(isHovered ? 0.2 : 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: accentColor.withOpacity(isHovered ? 0.4 : 0.2),
                        width: 1,
                      ),
                    ),
                    child: AnimatedRotation(
                      turns: isHovered ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: accentColor.withOpacity(isHovered ? 1 : 0.5),
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
