import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';
  List<Map<String, dynamic>> _programs = [];
  bool _loadingPrograms = true;
  Map<String, String> _programIdToName = {}; // Map to store program ID -> Name

  @override
  void initState() {
    super.initState();
    _fetchPrograms();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
          // Create a map for quick lookup
          final Map<String, String> idToName = {};
          
          setState(() {
            _programs = programList
                .map((p) {
                  final id = p['id']?.toString() ?? '';
                  final name = p['name']?.toString() ?? 'Unknown Program';
                  idToName[id] = name;
                  return {
                    'id': id,
                    'name': name,
                  };
                })
                .cast<Map<String, dynamic>>()
                .toList();
            
            _programIdToName = idToName;
            _loadingPrograms = false;

            if (_programs.isNotEmpty) {
              print("✅ Programs set in state: ${_programs.length}");
              print("📋 Program Map: $_programIdToName");
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

  Future<void> _openResult(BuildContext context, String url, String fileName) async {
    // 1. Show Loading Indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF))),
    );

    try {
      // 2. Get Directory
      final dir = await getApplicationDocumentsDirectory();
      // Ensure specific filename extension
      final name = fileName.endsWith('.pdf') ? fileName : '$fileName.pdf';
      final path = '${dir.path}/$name';

      // 3. Download File
      await Dio().download(url, path);

      // 4. Close Loading
      if (context.mounted) Navigator.pop(context);

      // 5. Open File (Native Viewer)
      final result = await OpenFilex.open(path);
      
      if (result.type != ResultType.done) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Could not open file: ${result.message}')),
          );
        }
      }

    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading if error
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Download failed: $e')),
        );
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, 
      body: Container(
        decoration: const BoxDecoration(
           gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black, Color(0xFF1A1A2E)],
           ),
        ),
        child: Column(
          children: [
            // Search Bar - NOW AT THE TOP
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SizedBox(
                height: 48,
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search results...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
                    prefixIcon: Icon(Icons.search, size: 20, color: Colors.white.withOpacity(0.4)),
                    filled: true,
                    fillColor: const Color(0xFF252525),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
            ),

            // Program Filter Chips - NOW BELOW SEARCH BAR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: _loadingPrograms
                  ? const SizedBox(
                      height: 40,
                      child: CircularProgressIndicator(
                          color: Color(0xFF6C63FF)))
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
                            final programName = program['name'] ?? 'Unknown';
                            final isSelected = _selectedFilter == programId;
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
            ),
            
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('results')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.assignment_turned_in_outlined,
                            color: Colors.white.withOpacity(0.5),
                            size: 80,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No results available yet',
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

                  // Get all docs
                  final allDocs = snapshot.data!.docs;

                  // Filter by selected program
                  final programFilteredDocs = _selectedFilter == 'All'
                      ? allDocs
                      : allDocs.where((doc) {
                          try {
                            // Try both 'programId' and 'program_id' field names
                            final programId = doc.get('program_id') ?? doc.get('programId') ?? '';
                            print("🔍 Document: ${doc.id}, Program ID: $programId, Selected: $_selectedFilter");
                            return programId.toString() == _selectedFilter;
                          } catch (e) {
                            print("⚠️ Error reading program_id from ${doc.id}: $e");
                            return false;
                          }
                        }).toList();

                  // Filter by search query
                  final filteredDocs = programFilteredDocs.where((doc) {
                    final eventName = (doc['eventName'] ?? '').toString().toLowerCase();
                    final fileName = (doc['fileName'] ?? '').toString().toLowerCase();
                    return eventName.contains(_searchQuery) || fileName.contains(_searchQuery);
                  }).toList();

                  if (programFilteredDocs.isEmpty && _selectedFilter != 'All') {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            color: Colors.white.withOpacity(0.5),
                            size: 60,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No results for this program',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 16,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (filteredDocs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            color: Colors.white.withOpacity(0.5),
                            size: 60,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No matching results found',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 16,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      final doc = filteredDocs[index];
                      final eventName = doc['eventName'] ?? 'Unknown Event';
                      final fileUrl = doc['fileUrl'] ?? '';
                      
                      // Get program ID and display program name
                      String programDisplayName = '';
                      try {
                        final programId = doc.get('program_id') ?? doc.get('programId') ?? '';
                        programDisplayName = _programIdToName[programId] ?? 'Unknown Program';
                      } catch (e) {
                        programDisplayName = 'Unknown Program';
                      }
                      
                      // Timestamp
                      String dateStr = '';
                      if (doc['timestamp'] != null) {
                         final ts = doc['timestamp'] as Timestamp;
                         dateStr = DateFormat('MMM d, yyyy').format(ts.toDate());
                      }

                      final fileName = doc['fileName'] ?? 'View Result';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF2A2A3E),
                              const Color(0xFF2A2A3E).withOpacity(0.6),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white.withOpacity(0.08),
                            width: 1,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => _openResult(context, fileUrl, fileName),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF6C63FF).withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.emoji_events_rounded,
                                          color: Color(0xFF6C63FF),
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              eventName,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                height: 1.2,
                                                letterSpacing: 0.2,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.calendar_today_rounded,
                                                  size: 12,
                                                  color: Colors.white.withOpacity(0.4),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  dateStr,
                                                  style: TextStyle(
                                                    color: Colors.white.withOpacity(0.4),
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Program Badge
                                  if (programDisplayName.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 12.0),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF6C63FF).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: const Color(0xFF6C63FF).withOpacity(0.4),
                                          ),
                                        ),
                                        child: Text(
                                          programDisplayName,
                                          style: const TextStyle(
                                            color: Color(0xFF6C63FF),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.25),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.picture_as_pdf_rounded,
                                          color: Colors.redAccent,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            fileName,
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.9),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(
                                          Icons.arrow_forward_rounded,
                                          color: Color(0xFF6C63FF),
                                          size: 14,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}