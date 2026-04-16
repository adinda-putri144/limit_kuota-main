import 'package:flutter/material.dart';
import 'package:limit_kuota/src/core/data/database_helper.dart';
import 'models/data_usage_model.dart';
import 'widgets/data_usage_chart.dart';

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

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0.00 MB";
    double mb = bytes / (1024 * 1024);
    if (mb > 1024) {
      return "${(mb / 1024).toStringAsFixed(2)} GB";
    }
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

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Belum ada riwayat data."));
          }

          final data = snapshot.data!;

          // WAJIB diurutkan berdasarkan tanggal
          data.sort((a, b) =>
              DateTime.parse(a['date'])
                  .compareTo(DateTime.parse(b['date'])));

          // Ambil 7 hari terakhir yang BENAR
          final last7Days =
              data.reversed.take(7).toList().reversed.toList();

          // Siapkan data untuk chart
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
                        leading: const Icon(
                          Icons.history,
                          color: Colors.blue,
                        ),
                        title: Text(
                          item['date'],
                          style: const TextStyle(
                              fontWeight: FontWeight.bold),
                        ),
                        subtitle: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                                "WiFi: ${_formatBytes(item['wifi'])}"),
                            Text(
                                "Mobile: ${_formatBytes(item['mobile'])}"),
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