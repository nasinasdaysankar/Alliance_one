import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../theme/theme.dart';

class EventDetailsScreen extends StatefulWidget {
  final EventItem event;
  final String categoryName;

  const EventDetailsScreen({
    super.key,
    required this.event,
    required this.categoryName,
  });

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  late bool _isLinkActive;

  @override
  void initState() {
    super.initState();
    _checkLinkAvailability();
  }

  void _checkLinkAvailability() {
    final now = DateTime.now();
    final startTime = TimeOfDay(hour: 9, minute: 0);
    final endTime = TimeOfDay(hour: 17, minute: 0);
    final nowTimeOfDay = TimeOfDay.fromDateTime(now);
    _isLinkActive = _isTimeInRange(nowTimeOfDay, startTime, endTime);
  }

  bool _isTimeInRange(TimeOfDay current, TimeOfDay start, TimeOfDay end) {
    final currentMinutes = current.hour * 60 + current.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
  }

  Future<void> _launchUrl(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch URL')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error launching URL: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        title: Text(widget.event.title),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (widget.event.url != null && widget.event.url!.isNotEmpty) ...[
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed:
                    _isLinkActive ? () => _launchUrl(widget.event.url!) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isLinkActive ? AppTheme.accentColor : Colors.grey,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                ),
                child: Text(
                  _isLinkActive
                      ? 'Access Alliance One'
                      : 'Link Not Available Now',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (!_isLinkActive)
                Text(
                  'Available: 9:00 AM - 5:00 PM',
                  style: TextStyle(
                    color: Colors.orange.shade300,
                    fontSize: 12,
                  ),
                ),
              const SizedBox(height: 32),
            ],
            if (widget.event.description.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.accentColor,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.event.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
