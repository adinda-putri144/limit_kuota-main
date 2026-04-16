import 'package:flutter/material.dart';
import 'package:limit_kuota/src/core/data/database_helper.dart';
import 'models/data_usage_model.dart';
import 'widgets/data_usage_chart.dart';
import 'widgets/data_limit_card.dart';
import 'widgets/app_usage_list.dart';
import 'limit_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late Future<List<Map<String, dynamic>>> _historyList;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    _historyList = DatabaseHelper.instance.getHistory();
  }

  Future<double> _getLimit() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('monthly_limit_mb') ?? 5000;
  }

  String _formatBytes(int bytes) {
    double mb = bytes / (1024 * 1024);
    if (mb > 1024) return "${(mb / 1024).toStringAsFixed(2)} GB";
    return "${mb.toStringAsFixed(2)} MB";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Riwayat Penggunaan")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _historyList,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Belum ada riwayat data."));
          }

          final data = snapshot.data!;

          // Urutkan tanggal
          data.sort((a, b) =>
              DateTime.parse(a['date']).compareTo(DateTime.parse(b['date'])));

          // ================= TOTAL BULAN INI =================
          final now = DateTime.now();
          double totalMonthMb = 0;

          for (var item in data) {
            final date = DateTime.parse(item['date']);
            if (date.month == now.month && date.year == now.year) {
              final totalBytes =
                  (item['wifi'] as int) + (item['mobile'] as int);
              totalMonthMb += totalBytes / (1024 * 1024);
            }
          }

          // ================= DATA 7 HARI TERAKHIR =================
          final last7Days =
              data.reversed.take(7).toList().reversed.toList();

          final chartData = last7Days.map((item) {
            final totalBytes =
                (item['wifi'] as int) + (item['mobile'] as int);
            final mb = totalBytes / (1024 * 1024);

            final date = DateTime.parse(item['date']);
            final dayName =
                ["Min", "Sen", "Sel", "Rab", "Kam", "Jum", "Sab"]
                    [date.weekday - 1];

            return DataUsage(dayName, mb);
          }).toList();

          return Column(
            children: [
              const SizedBox(height: 16),

              // ================= DATA LIMIT CARD =================
              FutureBuilder<double>(
                future: _getLimit(),
                builder: (context, limitSnap) {
                  if (!limitSnap.hasData) return const SizedBox();

                  return GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LimitPage()),
                      );
                      setState(() {
                        _refresh();
                      });
                    },
                    child: DataLimitCard(
                      usedMb: totalMonthMb,
                      limitMb: limitSnap.data!,
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // ================= CHART =================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DataUsageChart(data: chartData),
              ),

              const SizedBox(height: 20),

              // ================= APP USAGE LIST =================
              const Text(
                "Aplikasi Paling Boros Hari Ini",
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const AppUsageList(),

              const SizedBox(height: 16),

              // ================= LIST HISTORY =================
              Expanded(
                child: ListView.builder(
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final item = data[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      child: ListTile(
                        leading: const Icon(Icons.history,
                            color: Colors.blue),
                        title: Text(item['date']),
                        subtitle: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text("WiFi: ${_formatBytes(item['wifi'])}"),
                            Text("Mobile: ${_formatBytes(item['mobile'])}"),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}