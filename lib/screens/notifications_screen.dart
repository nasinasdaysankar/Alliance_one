import 'package:alliance_one/config/api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../theme/theme.dart';
import '../widgets/shimmer_loading.dart';

class NotificationsPage extends StatefulWidget {
  final VoidCallback? onResultClick;

  const NotificationsPage({super.key, this.onResultClick});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  Set<String> _readIds = {};
  Set<String> _deletedIds = {};
  String _selectedFilter = 'All';
  List<Map<String, dynamic>> _programs = [];
  bool _loadingPrograms = true;

  @override
  void initState() {
    super.initState();
    _loadState();
    _fetchPrograms();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> readList =
        prefs.getStringList('read_notifications') ?? [];
    final List<String> deletedList =
        prefs.getStringList('deleted_notifications') ?? [];
    if (mounted) {
      setState(() {
        _readIds = readList.toSet();
        _deletedIds = deletedList.toSet();
      });
    }
  }

 Future<void> _fetchPrograms() async {
  try {
    print("📡 Fetching programs from backend...");

    final response = await http
        .get(
          Uri.parse("${ApiConfig.baseUrl}/programs"),
          headers: {
            "Content-Type": "application/json",
          },
        )
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw Exception('Request timeout'),
        );

    print("📊 Response Status: ${response.statusCode}");
    print("📦 Response Body: ${response.body}");

    if (response.statusCode == 200) {
      final List<dynamic> programList = jsonDecode(response.body);
      print("✅ Programs loaded: ${programList.length}");

      if (!mounted) return;

      setState(() {
        _programs = programList
            .map((p) => {
                  'id': p['id']?.toString() ?? '',
                  'name': p['name']?.toString() ?? 'Unknown Program',
                })
            .toList();
        _loadingPrograms = false;
      });
    } else {
      print("❌ Failed to load programs: ${response.statusCode}");
      if (!mounted) return;
      setState(() {
        _loadingPrograms = false;
        _programs = [];
      });
    }
  } catch (e) {
    print("🔥 Error fetching programs: $e");
    if (!mounted) return;
    setState(() {
      _loadingPrograms = false;
      _programs = [];
    });
  }
}


  Future<void> _markAsRead(String id) async {
    if (!_readIds.contains(id)) {
      setState(() {
        _readIds.add(id);
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('read_notifications', _readIds.toList());
    }
  }

  Future<void> _markAllAsRead(List<String> ids) async {
    if (ids.isEmpty) return;
    setState(() {
      _readIds.addAll(ids);
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('read_notifications', _readIds.toList());
  }

  Future<void> _deleteNotification(String id) async {
    setState(() {
      _deletedIds.add(id);
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('deleted_notifications', _deletedIds.toList());
  }

  void _showNotificationDetails(String title, String body, String timeStr) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(
                        color: AppTheme.textColor,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: AppTheme.subTextColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                height: 1,
                color: Colors.white.withOpacity(0.05),
              ),
              const SizedBox(height: 20),
              Text(
                body,
                style: AppTheme.darkTheme.textTheme.bodyLarge?.copyWith(
                  color: AppTheme.subTextColor,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  timeStr,
                  style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.mutedTextColor,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Text(
        title,
        style: AppTheme.darkTheme.textTheme.labelLarge?.copyWith(
          color: AppTheme.mutedTextColor,
          letterSpacing: 1.2,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildNotificationItem(QueryDocumentSnapshot doc) {
    final id = doc.id;
    final title = doc['title'] ?? 'No Title';
    final body = doc['body'] ?? '';

    // Safely access program_id
    dynamic programId = '';
    try {
      programId = doc.get('program_id') ?? '';
    } catch (e) {
      programId = '';
    }

    final isResultNotification = title.toString().toLowerCase().contains('result') ||
        body.toString().toLowerCase().contains('result');
    final isRead = _readIds.contains(id);

    // Timestamp
    String timeStr = '';
    if (doc['time'] != null && doc['time'] is Timestamp) {
      timeStr = DateFormat('MMM d, h:mm a')
          .format((doc['time'] as Timestamp).toDate());
    }

    // Colors determine state
    final Color unreadBgColor = AppTheme.surfaceColor; // Distinct purple-grey
    final Color readBgColor = Colors.transparent; // Blends into background

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Slidable(
        key: Key(id),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          extentRatio: 0.25,
          children: [
            CustomSlidableAction(
              onPressed: (_) => _deleteNotification(id),
              backgroundColor: Colors.transparent,
              foregroundColor: AppTheme.accentSecondary,
              padding: EdgeInsets.zero,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.accentSecondary.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.accentSecondary, width: 1),
                    ),
                    child: const Icon(Icons.delete_outline_rounded, 
                      color: AppTheme.accentSecondary, size: 20),
                  ),
                ],
              ),
            ),
          ],
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: isRead ? readBgColor : unreadBgColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(
              color: isResultNotification
                  ? const Color(0xFF6C63FF).withOpacity(0.5)
                  : (isRead 
                      ? Colors.white.withOpacity(0.05) 
                      : AppTheme.primaryColor.withOpacity(0.3)),
              width: 1,
            ),
             boxShadow: isRead 
                ? [] 
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              onTap: () {
                _markAsRead(id);
                if (isResultNotification) {
                  if (widget.onResultClick != null) widget.onResultClick!();
                } else {
                  _showNotificationDetails(title, body, timeStr);
                }
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon Container
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isResultNotification
                            ? AppTheme.primaryColor.withOpacity(0.1)
                            : (isRead 
                                ? Colors.white.withOpacity(0.05)
                                : AppTheme.primaryColor.withOpacity(0.1)),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isResultNotification
                            ? Icons.emoji_events_rounded
                            : (isRead ? Icons.notifications_none_rounded : Icons.notifications_active_rounded),
                         color: isResultNotification
                            ? AppTheme.primaryColor
                            : (isRead 
                                ? AppTheme.subTextColor.withOpacity(0.5)
                                : AppTheme.primaryColor),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Text Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                                    color: isRead 
                                        ? AppTheme.subTextColor 
                                        : AppTheme.textColor,
                                    fontWeight: isRead 
                                        ? FontWeight.w500 
                                        : FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (!isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.accentSecondary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            body,
                            style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                              color: isRead 
                                  ? AppTheme.mutedTextColor 
                                  : AppTheme.subTextColor,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                timeStr,
                                style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith( // Using bodySmall essentially
                                  color: AppTheme.mutedTextColor,
                                  fontSize: 10,
                                ),
                              ),
                              if (isResultNotification)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text('VIEW RESULT',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.bold)),
                                )
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
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

          SafeArea(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .orderBy('time', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 20),
                    itemCount: 8,
                    itemBuilder: (context, index) => const ShimmerListTile(),
                  );
                }

                final allDocs = snapshot.data!.docs;

                // Filter out deleted notifications locally
                final visibleDocs = allDocs
                    .where((doc) => !_deletedIds.contains(doc.id))
                    .toList();

                // Filter by selected program
                final filteredDocs = _selectedFilter == 'All'
                    ? visibleDocs
                    : visibleDocs.where((doc) {
                        try {
                          final programId = doc.get('program_id') ?? '';
                          return programId.toString() == _selectedFilter;
                        } catch (e) {
                          return false;
                        }
                      }).toList();

                if (visibleDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          color: Colors.white.withOpacity(0.5),
                          size: 80,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No notifications yet',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 18,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Segregate Unread and Read
                final unreadDocs = filteredDocs
                    .where((doc) => !_readIds.contains(doc.id))
                    .toList();
                final readDocs = filteredDocs
                    .where((doc) => _readIds.contains(doc.id))
                    .toList();

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  children: [
                    // Program Filter Chips
                    _loadingPrograms
                        ? const Center(
                            child: SizedBox(
                                height: 40,
                                child: CircularProgressIndicator(
                                    color: Color(0xFF6C63FF))))
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                // "All" chip
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedFilter = 'All';
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: _selectedFilter == 'All'
                                            ? AppTheme.primaryColor
                                            : AppTheme.surfaceColor,
                                        borderRadius: BorderRadius.circular(AppTheme.radiusRound),
                                        border: Border.all(
                                          color: _selectedFilter == 'All'
                                              ? AppTheme.primaryColor
                                              : AppTheme.surfaceLight,
                                        ),
                                      ),
                                      child: Text(
                                        'All',
                                        style: _selectedFilter == 'All'
                                          ? AppTheme.darkTheme.textTheme.labelLarge?.copyWith(
                                              color: Colors.white,
                                              fontSize: 12,
                                            )
                                          : AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                                              color: AppTheme.subTextColor,
                                              fontSize: 12,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                                // Program chips
                                ..._programs.map((program) {
                                  final programId = program['id']?.toString() ?? '';
                                  final programName =
                                      program['name'] ?? 'Unknown';
                                  final isSelected =
                                      _selectedFilter == programId;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedFilter = programId;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppTheme.primaryColor
                                              : AppTheme.surfaceColor,
                                          borderRadius: BorderRadius.circular(AppTheme.radiusRound),
                                          border: Border.all(
                                            color: isSelected
                                                ? AppTheme.primaryColor
                                                : AppTheme.surfaceLight,
                                          ),
                                        ),
                                        child: Text(
                                          programName,
                                          style: isSelected
                                            ? AppTheme.darkTheme.textTheme.labelLarge?.copyWith(
                                                color: Colors.white,
                                                fontSize: 12,
                                              )
                                            : AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                                                color: AppTheme.subTextColor,
                                                fontSize: 12,
                                              ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                    const SizedBox(height: 16),

                    // Mark All Read Button
                    if (unreadDocs.isNotEmpty)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => _markAllAsRead(
                              unreadDocs.map((d) => d.id).toList()),
                          icon: const Icon(Icons.done_all_rounded,
                              size: 16, color: AppTheme.primaryColor),
                          label: Text(
                            'Mark all as read',
                            style: AppTheme.darkTheme.textTheme.labelLarge?.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                            ),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ),

                    if (filteredDocs.isEmpty && visibleDocs.isNotEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text(
                            'No notifications for this program',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 16,
                            ),
                          ),
                        ),
                      )
                    else ...[
                      if (unreadDocs.isNotEmpty) ...[
                        if (readDocs.isNotEmpty) _buildSectionHeader('NEW'),
                        ...unreadDocs.map(_buildNotificationItem),
                      ],
                      if (readDocs.isNotEmpty) ...[
                        if (unreadDocs.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: _buildSectionHeader('EARLIER'),
                          ),
                        ...readDocs.map(_buildNotificationItem),
                      ],
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}