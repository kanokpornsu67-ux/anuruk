import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import 'camp_screens.dart';

class CampHistoryScreen extends StatelessWidget {
  const CampHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final finished = app.finishedCamps;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionTitle('คลังประวัติค่ายที่เสร็จสิ้นแล้ว'),
          if (finished.isEmpty) const EmptyState('ยังไม่มีประวัติค่ายที่ปิดตัวลง'),
          ...finished.asMap().entries.map((e) {
            final c = e.value;
            final place = app.place(c.placeId);
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: const EdgeInsets.all(10),
                leading: CampThumb(seed: e.key),
                title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('${thaiRange(c.start, c.end)} • ${place?.province ?? ''}', style: const TextStyle(fontSize: 12)),
                    if (c.summary != null) ...[
                      const SizedBox(height: 4),
                      Text('ผู้เข้าร่วมจริง: ${c.summary!.actualParticipants} คน',
                          style: const TextStyle(fontSize: 11, color: Colors.black54)),
                    ],
                  ],
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CampDetailScreen(campId: c.id)),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}