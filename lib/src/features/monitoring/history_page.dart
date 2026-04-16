import 'package:flutter/material.dart';
import 'package:limit_kuota/src/core/data/database_helper.dart';
import 'models/data_usage_model.dart';
import 'widgets/data_usage_chart.dart';
import 'widgets/data_limit_card.dart';
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
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;

          data.sort((a, b) =>
              DateTime.parse(a['date']).compareTo(DateTime.parse(b['date'])));

          double totalMonthMb = 0;
          for (var item in data) {
            final totalBytes =
                (item['wifi'] as int) + (item['mobile'] as int);
            totalMonthMb += totalBytes / (1024 * 1024);
          }

          final last7Days =
              data.reversed.take(7).toList().reversed.toList();

          final chartData = last7Days.map((item) {
            final totalBytes =
                (item['wifi'] as int) + (item['mobile'] as int);
            final mb = totalBytes / (1024 * 1024);

            final date = DateTime.parse(item['date']);
            final dayName =
                ["Min", "Sen", "Sel", "Rab", "Kam", "Jum", "Sab"]
                    [date.weekday % 7];

            return DataUsage(dayName, mb);
          }).toList();

          return Column(
            children: [
              const SizedBox(height: 16),

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
                      setState(() {});
                    },
                    child: DataLimitCard(
                      usedMb: totalMonthMb,
                      limitMb: limitSnap.data!,
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DataUsageChart(data: chartData),
              ),

              const SizedBox(height: 16),

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