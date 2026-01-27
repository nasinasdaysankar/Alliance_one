import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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
      const String baseUrl = "http://10.1.160.89:3000/api";

      print("📡 Fetching programs from backend...");

      final response = await http.get(
        Uri.parse("$baseUrl/programs"),
        headers: {
          "Content-Type": "application/json",
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timeout'),
      );

      print("📊 Response Status: ${response.statusCode}");
      print("📦 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> programList = jsonDecode(response.body);
        print("✅ Programs loaded: ${programList.length}");

        if (mounted) {
          setState(() {
            _programs = programList
                .map((p) => {
                      'id': p['id']?.toString() ?? '',
                      'name': p['name']?.toString() ?? 'Unknown Program',
                    })
                .cast<Map<String, dynamic>>()
                .toList();
            _loadingPrograms = false;

            if (_programs.isNotEmpty) {
              print("✅ Programs set in state: ${_programs.length}");
            }
          });
        }
      } else {
        print("❌ Failed to load programs: ${response.statusCode}");
        if (mounted) {
          setState(() {
            _loadingPrograms = false;
            _programs = [];
          });
        }
      }
    } catch (e) {
      print("🔥 Error fetching programs: $e");
      if (mounted) {
        setState(() {
          _loadingPrograms = false;
          _programs = [];
        });
      }
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
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                height: 1,
                color: Colors.white.withOpacity(0.1),
              ),
              const SizedBox(height: 16),
              Text(
                body,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  timeStr,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
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
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
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
      print("⚠️ program_id field missing in document $id");
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
              foregroundColor: Colors.white,
              padding: EdgeInsets.zero,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.delete, color: Colors.white, size: 24),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Delete',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.black.withOpacity(0.4),
                Colors.black.withOpacity(0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isResultNotification
                  ? const Color(0xFF6C63FF).withOpacity(0.8)
                  : Colors.white.withOpacity(0.15),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
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
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isResultNotification
                            ? const Color(0xFF6C63FF).withOpacity(0.2)
                            : Colors.white.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isResultNotification
                            ? Icons.emoji_events
                            : Icons.notifications_active,
                        color: isResultNotification
                            ? const Color(0xFF6C63FF)
                                .withOpacity(isRead ? 0.7 : 1.0)
                            : Colors.white.withOpacity(isRead ? 0.5 : 0.9),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
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
                                  style: TextStyle(
                                    color: Colors.white
                                        .withOpacity(isRead ? 0.7 : 1.0),
                                    fontSize: 14,
                                    fontWeight: isRead
                                        ? FontWeight.normal
                                        : FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (isResultNotification)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6C63FF)
                                        .withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text('VIEW',
                                      style: TextStyle(
                                          fontSize: 9,
                                          color: Color(0xFF6C63FF),
                                          fontWeight: FontWeight.bold)),
                                )
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            body,
                            style: TextStyle(
                              color: Colors.white.withOpacity(isRead ? 0.5 : 0.8),
                              fontSize: 12,
                              fontWeight:
                                  isRead ? FontWeight.normal : FontWeight.w500,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            timeStr,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.3),
                              fontSize: 10,
                            ),
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
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background with gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A0033),
                  Color(0xFF2D1B4E),
                  Color(0xFF3D2861),
                  Color(0xFF4A3675),
                ],
                stops: [0.0, 0.3, 0.6, 1.0],
              ),
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
                  return const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF6C63FF)));
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
                                            ? const Color(0xFF6C63FF)
                                            : Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: _selectedFilter == 'All'
                                              ? const Color(0xFF6C63FF)
                                              : Colors.white.withOpacity(0.2),
                                        ),
                                      ),
                                      child: Text(
                                        'All',
                                        style: TextStyle(
                                          color: _selectedFilter == 'All'
                                              ? Colors.white
                                              : Colors.white70,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
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
                                              ? const Color(0xFF6C63FF)
                                              : Colors.white.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: isSelected
                                                ? const Color(0xFF6C63FF)
                                                : Colors.white.withOpacity(0.2),
                                          ),
                                        ),
                                        child: Text(
                                          programName,
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.white70,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
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
                          icon: const Icon(Icons.done_all,
                              size: 16, color: Color(0xFF6C63FF)),
                          label: const Text(
                            'Mark all as read',
                            style: TextStyle(
                                color: Color(0xFF6C63FF),
                                fontWeight: FontWeight.bold),
                          ),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            alignment: Alignment.centerRight,
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