import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:limit_kuota/src/core/data/database_helper.dart';
import 'package:limit_kuota/src/core/services/intent_helper.dart';
import 'package:limit_kuota/src/features/monitoring/history_page.dart';
import 'package:limit_kuota/src/features/monitoring/widgets/app_usage_list.dart';

class Network extends StatefulWidget {
  const Network({super.key});

  @override
  State<Network> createState() => _NetworkState();
}

class _NetworkState extends State<Network> {
  static const platform = MethodChannel('limit_kuota/channel');

  String wifiUsage = "0.00 MB";
  String mobileUsage = "0.00 MB";

  Future<void> fetchUsage() async {
    try {
      final Map<dynamic, dynamic> result =
          await platform.invokeMethod('getTodayUsage');

      String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

      int wifiBytes = result['wifi'] ?? 0;
      int mobileBytes = result['mobile'] ?? 0;

      await DatabaseHelper.instance.insertOrUpdate(
        todayDate,
        wifiBytes,
        mobileBytes,
      );

      setState(() {
        wifiUsage = _formatBytes(wifiBytes);
        mobileUsage = _formatBytes(mobileBytes);
      });

      // Cek limit kuota setelah update
      checkLimitAndWarn(wifiBytes + mobileBytes);
    } on PlatformException catch (e) {
      if (e.code == "PERMISSION_DENIED") {
        _showPermissionDialog();
      }
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0.00 MB";
    double mb = bytes / (1024 * 1024);
    if (mb > 1024) {
      return "${(mb / 1024).toStringAsFixed(2)} GB";
    }
    return "${mb.toStringAsFixed(2)} MB";
  }

  Future<void> checkLimitAndWarn(int currentUsage) async {
    int limitInBytes = 1024 * 1024 * 1024; // 1 GB contoh

    if (currentUsage >= limitInBytes) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Batas Kuota Tercapai!"),
          content: const Text(
            "Penggunaan data Anda sudah mencapai limit.\n\n"
            "Silakan aktifkan 'Set Data Limit' di pengaturan sistem agar koneksi terputus otomatis.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Nanti"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                IntentHelper.openDataLimitSettings();
              },
              child: const Text("Buka Pengaturan"),
            ),
          ],
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    fetchUsage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitoring Data'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryPage()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _usageCard("WiFi Today", wifiUsage, Icons.wifi),
              const SizedBox(height: 20),
              _usageCard(
                  "Mobile Today", mobileUsage, Icons.signal_cellular_alt),
              const SizedBox(height: 40),

              ElevatedButton.icon(
                onPressed: fetchUsage,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Data'),
              ),

              const SizedBox(height: 30),

              const Text(
                "Aplikasi Paling Boros",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              const AppUsageList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _usageCard(String title, String value, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 40, color: Colors.blue),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                value,
                style:
                    const TextStyle(fontSize: 20, color: Colors.blueAccent),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Izin Diperlukan"),
          content: const Text(
            "Aplikasi membutuhkan izin 'Akses Penggunaan'.\n\n"
            "Silakan aktifkan izin di halaman pengaturan.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                fetchUsage();
              },
              child: const Text("Buka Pengaturan"),
            ),
          ],
        );
      },
    );
  }
}