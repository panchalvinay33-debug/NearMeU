import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/user_service.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() =>
      _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  final UserService _userService = UserService();

  final TextEditingController _searchController =
      TextEditingController();

  bool _loading = true;

  String _selectedFilter = "Pending";

  List<Map<String, dynamic>> _reports = [];

  List<Map<String, dynamic>> _filteredReports = [];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadReports() async {
    setState(() {
      _loading = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection("reports")
          .orderBy("createdAt", descending: true)
          .get();

      _reports = snapshot.docs
          .map((e) => {
                "id": e.id,
                ...e.data(),
              })
          .toList();

      _applyFilter();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }

    if (!mounted) return;

    setState(() {
      _loading = false;
    });
  }

  void _applyFilter() {
    List<Map<String, dynamic>> list = List.from(_reports);

    if (_selectedFilter == "Pending") {
      list = list.where((e) {
        return (e["status"] ?? "pending") == "pending";
      }).toList();
    }

    if (_selectedFilter == "Resolved") {
      list = list.where((e) {
        return (e["status"] ?? "") == "resolved";
      }).toList();
    }

    final keyword =
        _searchController.text.trim().toLowerCase();

    if (keyword.isNotEmpty) {
      list = list.where((e) {
        final reporter =
            (e["reporterName"] ?? "")
                .toString()
                .toLowerCase();

        final reported =
            (e["reportedUserName"] ?? "")
                .toString()
                .toLowerCase();

        final reason =
            (e["reason"] ?? "")
                .toString()
                .toLowerCase();

        return reporter.contains(keyword) ||
            reported.contains(keyword) ||
            reason.contains(keyword);
      }).toList();
    }

    setState(() {
      _filteredReports = list;
    });
  }

  int get pendingCount => _reports
      .where((e) => (e["status"] ?? "pending") == "pending")
      .length;

  int get resolvedCount => _reports
      .where((e) => (e["status"] ?? "") == "resolved")
      .length;

  Widget _buildTopCard(
    String title,
    int value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xff171717),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 30,
            ),
            const SizedBox(height: 12),
            Text(
              value.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(String text) {
    final selected = _selectedFilter == text;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = text;
          });

          _applyFilter();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? Colors.purpleAccent
                : const Color(0xff171717),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildReportCard(
    Map<String, dynamic> report,
  ) {
    final Timestamp? ts =
        report["createdAt"] as Timestamp?;

    final created = ts?.toDate();

    final bool resolved =
        (report["status"] ?? "") == "resolved";

    return Card(
      color: const Color(0xff171717),
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                CircleAvatar(
                  radius: 28,
                  backgroundImage:
                      (report["reportedUserPhoto"] ?? "")
                              .toString()
                              .isNotEmpty
                          ? NetworkImage(
                              report["reportedUserPhoto"],
                            )
                          : null,
                  child:
                      (report["reportedUserPhoto"] ?? "")
                              .toString()
                              .isEmpty
                          ? const Icon(Icons.person)
                          : null,
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [

                      Text(
                        report["reportedUserName"] ??
                            "Unknown User",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      SelectableText(
                        report["reportedUserId"] ??
                            "",
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: resolved
                              ? Colors.green
                              : Colors.orange,
                          borderRadius:
                              BorderRadius.circular(
                                  20),
                        ),
                        child: Text(
                          resolved
                              ? "Resolved"
                              : "Pending",
                          style:
                              const TextStyle(
                            color: Colors.white,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            const Divider(),

            const SizedBox(height: 12),

            const Text(
              "Reporter",
              style: TextStyle(
                color: Colors.white54,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              report["reporterName"] ??
                  "Unknown",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            SelectableText(
              report["reporterId"] ?? "",
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              "Reason",
              style: TextStyle(
                color: Colors.white54,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              report["reason"] ?? "",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),

            if ((report["description"] ?? "")
                .toString()
                .trim()
                .isNotEmpty) ...[
              const SizedBox(height: 18),

              const Text(
                "Description",
                style: TextStyle(
                  color: Colors.white54,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                report["description"],
                style: const TextStyle(
                  color: Colors.white,
                ),
              ),
            ],

            const SizedBox(height: 20),

            Text(
              created == null
                  ? ""
                  : created.toString(),
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 20),
            Row(
              children: [

                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () async {
                      final bool suspended =
                          report["suspended"] == true;

                      await _userService
                          .setUserSuspended(
                        userId:
                            report["reportedUserId"],
                        suspended: !suspended,
                      );

                      await _loadReports();
                    },
                    icon: Icon(
                      report["suspended"] == true
                          ? Icons.lock_open
                          : Icons.block,
                    ),
                    label: Text(
                      report["suspended"] == true
                          ? "Unsuspend"
                          : "Suspend",
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    onPressed: resolved
                        ? null
                        : () async {
                            await FirebaseFirestore
                                .instance
                                .collection("reports")
                                .doc(report["id"])
                                .update({
                              "status":
                                  "resolved",
                              "reviewedAt":
                                  FieldValue
                                      .serverTimestamp(),
                              "action":
                                  "resolved",
                            });

                            await _loadReports();
                          },
                    icon: const Icon(
                      Icons.check,
                    ),
                    label: const Text(
                      "Resolve",
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.grey.shade800,
                ),
                onPressed: () async {

                  final confirm =
                      await showDialog<bool>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text(
                          "Delete Report",
                        ),
                        content: const Text(
                          "Are you sure you want to permanently delete this report?",
                        ),
                        actions: [

                          TextButton(
                            onPressed: () {
                              Navigator.pop(
                                context,
                                false,
                              );
                            },
                            child: const Text(
                              "Cancel",
                            ),
                          ),

                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(
                                context,
                                true,
                              );
                            },
                            child: const Text(
                              "Delete",
                            ),
                          ),
                        ],
                      );
                    },
                  );

                  if (confirm != true) {
                    return;
                  }

                  await FirebaseFirestore
                      .instance
                      .collection("reports")
                      .doc(report["id"])
                      .delete();

                  await _loadReports();
                },
                icon: const Icon(
                  Icons.delete_forever,
                ),
                label: const Text(
                  "Delete Report",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(0xff0B0B0B),
      appBar: AppBar(
        title: const Text(
          "User Reports",
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        actions: [

          IconButton(
            onPressed: _loadReports,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.purpleAccent,
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadReports,
              child: Column(
                children: [

                  const SizedBox(height: 16),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                    ),
                    child: Row(
                      children: [

                        _buildTopCard(
                          "Pending",
                          pendingCount,
                          Icons.flag,
                          Colors.orange,
                        ),

                        const SizedBox(width: 12),

                        _buildTopCard(
                          "Resolved",
                          resolvedCount,
                          Icons.check_circle,
                          Colors.green,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => _applyFilter(),
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                      decoration: InputDecoration(
                        hintText:
                            "Search reporter, reported user or reason",
                        hintStyle: const TextStyle(
                          color: Colors.white54,
                        ),
                        prefixIcon:
                            const Icon(Icons.search),
                        filled: true,
                        fillColor:
                            const Color(0xff171717),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                    ),
                    child: Row(
                      children: [

                        _buildFilterButton("All"),

                        _buildFilterButton("Pending"),

                        _buildFilterButton("Resolved"),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Expanded(
                    child: _filteredReports.isEmpty
                        ? const Center(
                            child: Text(
                              "No Reports Found",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 18,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding:
                                const EdgeInsets.all(16),
                            itemCount:
                                _filteredReports.length,
                            itemBuilder:
                                (context, index) {

                              return _buildReportCard(
                                _filteredReports[index],
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