import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  static const platform = MethodChannel('limit_kuota/channel');

  late Future<List<Map<String, dynamic>>> _historyList;
  late Future<List<dynamic>> _appUsageFuture;

  @override
  void initState() {
    super.initState();
    _initPage();
  }

  // ===== INI YANG SEBELUMNYA HILANG =====
  Future<void> _saveTodayUsageToDb() async {
    final result = await platform.invokeMethod('getTodayUsage');

    String today =
        "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";

    int wifi = result['wifi'] ?? 0;
    int mobile = result['mobile'] ?? 0;

    await DatabaseHelper.instance.insertOrUpdate(today, wifi, mobile);
  }

  Future<void> _initPage() async {
    await _saveTodayUsageToDb(); // WAJIB JALAN DULU
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _historyList = DatabaseHelper.instance.getHistory();
      _appUsageFuture = _getAppUsage();
    });
  }

  Future<List<dynamic>> _getAppUsage() async {
    final result = await platform.invokeMethod('getAppUsage');
    return result;
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

  String _formatAppBytes(int bytes) {
    double mb = bytes / (1024 * 1024);
    return "${mb.toStringAsFixed(1)} MB";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F6FA),
      body: SafeArea(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _historyList,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data!;
            data.sort((a, b) =>
                DateTime.parse(a['date']).compareTo(DateTime.parse(b['date'])));

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

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      borderRadius:
                          BorderRadius.vertical(bottom: Radius.circular(30)),
                    ),
                    child: const Text(
                      "Monitoring Kuota Internet",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                  ),

                  const SizedBox(height: 20),

                  FutureBuilder<double>(
                    future: _getLimit(),
                    builder: (context, limitSnap) {
                      if (!limitSnap.hasData) return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const LimitPage()),
                            );
                          },
                          child: DataLimitCard(
                            usedMb: totalMonthMb,
                            limitMb: limitSnap.data!,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: DataUsageChart(data: chartData),
                      ),
                    ),
                  ),
const SizedBox(height: 20),

// ===== TOP APLIKASI BOROS =====
const Padding(
  padding: EdgeInsets.symmetric(horizontal: 20),
  child: Text(
    "Top Aplikasi Paling Boros",
    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  ),
),
const SizedBox(height: 10),

FutureBuilder<List<dynamic>>(
  future: _appUsageFuture,
  builder: (context, snap) {
    if (!snap.hasData) {
      return const Center(child: CircularProgressIndicator());
    }

    final apps = snap.data!;
    if (apps.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text("Tidak ada data aplikasi"),
      );
    }

    int maxBytes = apps.first['bytes'];

    return ListView.builder(
      itemCount: apps.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final app = apps[index];
        double percent = app['bytes'] / maxBytes;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15)),
          child: ListTile(
            leading: CircleAvatar(
              child: Text("#${index + 1}"),
            ),
            title: Text(app['appName']),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_formatAppBytes(app['bytes'])),
                const SizedBox(height: 6),
                LinearProgressIndicator(value: percent),
              ],
            ),
          ),
        );
      },
    );
  },
),
                  const SizedBox(height: 20),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "Riwayat Harian",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),

                  ListView.builder(
                    itemCount: data.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final item = data[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                        child: ListTile(
                          leading: const Icon(Icons.calendar_today,
                              color: Colors.blue),
                          title: Text(item['date']),
                          subtitle: Text(
                              "WiFi: ${_formatBytes(item['wifi'])} | Mobile: ${_formatBytes(item['mobile'])}"),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}