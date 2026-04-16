import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppUsageList extends StatefulWidget {
  const AppUsageList({super.key});

  @override
  State<AppUsageList> createState() => _AppUsageListState();
}

class _AppUsageListState extends State<AppUsageList> {
  static const platform = MethodChannel('limit_kuota/channel');

  List<dynamic> apps = [];

  @override
  void initState() {
    super.initState();
    loadApps();
  }

  Future<void> loadApps() async {
    final result = await platform.invokeMethod('getAppUsage');
    setState(() {
      apps = result;
    });
  }

  String formatBytes(int bytes) {
    double mb = bytes / (1024 * 1024);
    if (mb > 1024) return "${(mb / 1024).toStringAsFixed(2)} GB";
    return "${mb.toStringAsFixed(2)} MB";
  }

  @override
  Widget build(BuildContext context) {
    if (apps.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text("Belum ada data aplikasi"),
      );
    }

    return Column(
      children: apps.map((app) {
        return ListTile(
          leading: const Icon(Icons.apps, color: Colors.blue),
          title: Text(app['appName']),
          trailing: Text(formatBytes(app['bytes'])),
        );
      }).toList(),
    );
  }
}