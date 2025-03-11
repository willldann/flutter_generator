import 'package:flutter/material.dart';
import 'package:flutter_generator/services/gemini_services.dart';
import 'package:flutter_generator/ui/secadule_result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Map<String, dynamic>> tasks = [];
  final TextEditingController taskController = TextEditingController();
  final TextEditingController durationController = TextEditingController();
  String? priority;
  bool isLoading = false;

  void _addTask() {
    if (taskController.text.isNotEmpty && durationController.text.isNotEmpty && priority != null) {
      setState(() {
        tasks.add({
          "name": taskController.text,
          "priority": priority!,
          "duration": int.tryParse(durationController.text) ?? 30,
          "deadline": "Tidak Ada"
        });
      });
      taskController.clear();
      durationController.clear();
    }
  }

  void _clearTasks() {
    setState(() => tasks.clear());
  }

  Future<void> _generateSchedule() async {
    if (tasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠ Harap tambahkan tugas terlebih dahulu!")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      String schedule = await GeminiService.generateSchedule(tasks);
      await Future.delayed(Duration(seconds: 1));

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ScheduleResultScreen(scheduleResult: schedule),
        ),
      ).then((_) {
        setState(() => isLoading = false);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menghasilkan jadwal: $e")),
      );
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Schedule Generator", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: taskController,
              decoration: InputDecoration(
                labelText: "Nama Tugas",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: durationController,
              decoration: InputDecoration(
                labelText: "Durasi (menit)",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: priority,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              hint: Text("Pilih Prioritas"),
              onChanged: (value) => setState(() => priority = value),
              items: ["Tinggi", "Sedang", "Rendah"].map((priorityMember) =>
                DropdownMenuItem(value: priorityMember, child: Text(priorityMember))
              ).toList(),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: _addTask,
                  icon: Icon(Icons.add),
                  label: Text("Tambahkan"),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _clearTasks,
                  icon: Icon(Icons.delete, color: Colors.white),
                  label: Text("Hapus Semua", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                    margin: EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: Icon(Icons.task_alt, color: Colors.blueAccent),
                      title: Text("${task['name']}", style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        "Prioritas: ${task['priority']} | Durasi: ${task['duration']} menit",
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 16),
            isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _generateSchedule,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text("Generate Schedule", style: TextStyle(fontSize: 16)),
                  ),
          ],
        ),
      ),
    );
  }
}
