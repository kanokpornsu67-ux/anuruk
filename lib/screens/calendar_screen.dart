import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/models.dart';
import '../state/app_state.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    
    // ดึงรายการของวันที่ถูกเลือก
    final selectedEvents = app.calendarEvents.where((event) {
      if (_selectedDay == null) return false;
      return event.date.year == _selectedDay!.year &&
          event.date.month == _selectedDay!.month &&
          event.date.day == _selectedDay!.day;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('ปฏิทินกิจกรรมและนัดหมาย'),
      ),
      // ใช้ SingleChildScrollView เพื่อให้เลื่อนหน้าจอได้ทั้งหมด
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ตารางปฏิทิน
            TableCalendar<CalendarEvent>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarFormat: CalendarFormat.month,
              eventLoader: (day) {
                return app.calendarEvents.where((event) {
                  return event.date.year == day.year &&
                      event.date.month == day.month &&
                      event.date.day == day.day;
                }).toList();
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              calendarStyle: const CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.orangeAccent,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
            ),
            const Divider(height: 20),

            // หัวข้อแสดงวันที่เลือก
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'กำหนดการวันที่ ${_selectedDay?.day ?? ''}/${_selectedDay?.month ?? ''}/${_selectedDay?.year ?? ''}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),

            // รายการกิจกรรม (ใช้ ListView แบบปิดการเลื่อนภายใน และให้ SingleChildScrollView คุมแทน)
            selectedEvents.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(
                      child: Text(
                        'ไม่มีกำหนดการในวันนี้',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true, // สำคัญ: ให้หดความสูงตามเนื้อหา
                    physics: const NeverScrollableScrollPhysics(), // ปิดการเลื่อนแยก ปล่อยให้หน้าหลักเลื่อนแทน
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: selectedEvents.length,
                    itemBuilder: (context, index) {
                      final event = selectedEvents[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                            event.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(event.description),
                          trailing: app.isCommittee
                              ? IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => app.deleteCalendarEvent(event.id),
                                )
                              : null,
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 80), // เผื่อพื้นที่ด้านล่างให้ไม่ทับ FloatingActionButton
          ],
        ),
      ),
      // ปุ่มบวกเพิ่มกิจกรรม (แสดงเฉพาะกรรมการ)
      floatingActionButton: app.isCommittee
          ? FloatingActionButton(
              onPressed: () => _showAddEventDialog(context, _selectedDay ?? DateTime.now()),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  // Dialog สำหรับให้กรรมการกรอกข้อมูล
  void _showAddEventDialog(BuildContext context, DateTime defaultDate) {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('เพิ่มกำหนดการ (${defaultDate.day}/${defaultDate.month}/${defaultDate.year})'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'หัวข้อ / งาน / การประชุม'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'รายละเอียดเพิ่มเติม'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  context.read<AppState>().addCalendarEvent(
                        title: titleController.text,
                        description: descController.text,
                        date: defaultDate,
                      );
                  Navigator.pop(context);
                }
              },
              child: const Text('บันทึก'),
            ),
          ],
        );
      },
    );
  }
}