import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config/api.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  List<Map<String, dynamic>> _programs = [];
  bool _loadingPrograms = true;
  Map<String, String> _programIdToName = {};
  String? _expandedProgramId;
  late Stream<QuerySnapshot> _resultsStream;

  @override
  void initState() {
    super.initState();
    _fetchPrograms();
    _resultsStream = FirebaseFirestore.instance
        .collection('results')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> _fetchPrograms() async {
    try {
      print('📡 Fetching programs from: ${ApiConfig.baseUrl}/programs');
      
      final response = await http
          .get(Uri.parse("${ApiConfig.baseUrl}/programs"))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) throw Exception('Failed to load programs');

      final List<dynamic> programList = jsonDecode(response.body);

      if (!mounted) return;

      final idToName = <String, String>{};
      final programs = programList.map((p) {
        final id = p['id']?.toString() ?? '';
        final name = (p['name']?.toString() ?? 'Unnamed').trim();
        idToName[id] = name;
        return {'id': id, 'name': name};
      }).toList();

      setState(() {
        _programs = programs;
        _programIdToName = idToName;
        _loadingPrograms = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loadingPrograms = false);
      }
    }
  }

  Future<void> _openResult(BuildContext context, String url, String fileName) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final dir = await getApplicationDocumentsDirectory();
      final name = fileName.endsWith('.pdf') ? fileName : '$fileName.pdf';
      final path = '${dir.path}/$name';

      await Dio().download(url, path);
      if (!context.mounted) return;
      Navigator.pop(context);

      final result = await OpenFilex.open(path);
      if (result.type != ResultType.done && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open file: ${result.message}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    }
  }

  List<QueryDocumentSnapshot> _getResultsForProgram(
    String programId,
    List<QueryDocumentSnapshot> allDocs,
  ) {
    return allDocs.where((doc) {
      final pid = doc.get('program_id') ?? doc.get('programId') ?? '';
      return pid.toString() == programId;
    }).toList();
  }

  Widget _buildResultTile(QueryDocumentSnapshot doc) {
    final eventName = doc['eventName']?.toString() ?? 'Unknown Event';
    final fileUrl = doc['fileUrl']?.toString() ?? '';
    final fileName = doc['fileName']?.toString() ?? 'Result';

    String dateStr = '';
    if (doc['timestamp'] is Timestamp) {
      dateStr = DateFormat('MMM d, yyyy').format((doc['timestamp'] as Timestamp).toDate());
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _openResult(context, fileUrl, fileName),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.11)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.13),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Text(
                          eventName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      const SizedBox(height: 5),
                      Text(
                        dateStr.isEmpty ? '—' : dateStr,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.65),
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white54, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgramCard(Map<String, dynamic> program, List<QueryDocumentSnapshot> allDocs) {
    final id = program['id'] as String? ?? '';
    final name = program['name'] as String? ?? 'Program';
    final isExpanded = _expandedProgramId == id;
    final results = _getResultsForProgram(id, allDocs);
    final count = results.length;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
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
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.15),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header row – always visible
              InkWell(
                onTap: () {
                  setState(() {
                    if (isExpanded) {
                      _expandedProgramId = null;
                    } else {
                      _expandedProgramId = id;
                    }
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C63FF).withOpacity(0.18),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.folder_rounded,
                          color: Color(0xFF9F91FF),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6C63FF).withOpacity(0.16),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '$count ${count == 1 ? "Result" : "Results"}',
                                style: const TextStyle(
                                  color: Color(0xFF9F91FF),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeInOutCubic,
                        child: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Color(0xFF9F91FF),
                          size: 26,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Expanded content – smooth height animation
              AnimatedSize(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeInOutCubicEmphasized,
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(),
                  child: isExpanded
                      ? Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            border: const Border(
                              top: BorderSide(color: Colors.white12, width: 0.5),
                            ),
                          ),
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                          child: results.isEmpty
                              ? Center(
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(vertical: 24),
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.03),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.folder_off_outlined,
                                          size: 40,
                                          color: Colors.white.withOpacity(0.4),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'No results yet',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white.withOpacity(0.5),
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : Column(
                                  children: results.map(_buildResultTile).toList(),
                                ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            child: Column(
              children: [
                Expanded(
                  child: _loadingPrograms
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF9F91FF)))
                      : StreamBuilder<QuerySnapshot>(
                          stream: _resultsStream,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.folder_open_outlined,
                                        size: 80, color: Colors.white.withOpacity(0.35)),
                                    const SizedBox(height: 16),
                                    const Text(
                                      "No results available yet",
                                      style: TextStyle(color: Colors.white70, fontSize: 18),
                                    ),
                                  ],
                                ),
                              );
                            }

                            final docs = snapshot.data!.docs;

                            if (_programs.isEmpty) {
                              return const Center(
                                child: Text(
                                  "No programs loaded",
                                  style: TextStyle(color: Colors.white60, fontSize: 17),
                                ),
                              );
                            }

                            // Sort programs by result count (descending)
                            final sortedPrograms = List<Map<String, dynamic>>.from(_programs);
                            sortedPrograms.sort((a, b) {
                              final idA = a['id']?.toString() ?? '';
                              final idB = b['id']?.toString() ?? '';
                              final countA = _getResultsForProgram(idA, docs).length;
                              final countB = _getResultsForProgram(idB, docs).length;
                              return countB.compareTo(countA); // Descending
                            });

                            return ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                              physics: const BouncingScrollPhysics(),
                              itemCount: sortedPrograms.length,
                              itemBuilder: (context, i) => _buildProgramCard(sortedPrograms[i], docs),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}