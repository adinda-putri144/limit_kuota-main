import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LimitPage extends StatefulWidget {
  const LimitPage({super.key});

  @override
  State<LimitPage> createState() => _LimitPageState();
}

class _LimitPageState extends State<LimitPage> {
  final TextEditingController _controller = TextEditingController();

  Future<void> _saveLimit() async {
    final prefs = await SharedPreferences.getInstance();
    final value = double.tryParse(_controller.text) ?? 0;
    await prefs.setDouble('monthly_limit_mb', value);
    Navigator.pop(context);
  }

  Future<void> _loadLimit() async {
    final prefs = await SharedPreferences.getInstance();
    final limit = prefs.getDouble('monthly_limit_mb') ?? 5000;
    _controller.text = limit.toStringAsFixed(0);
  }

  @override
  void initState() {
    super.initState();
    _loadLimit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Atur Limit Bulanan")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Limit dalam MB (contoh: 5000 = 5GB)",
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveLimit,
              child: const Text("Simpan"),
            )
          ],
        ),
      ),
    );
  }
}