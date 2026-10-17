import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import 'camp_screens.dart';

class ClubDashboardScreen extends StatelessWidget {
  const ClubDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final camps = app.camps.toList()..sort((a, b) => b.start.compareTo(a.start));

    final totalCamps = camps.length;
    final ongoingCamps = camps.where((c) => c.status == CampStatus.ongoing).length;
    final finishedCamps = camps.where((c) => c.status == CampStatus.finished).length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionTitle('ภาพรวมสถานะค่ายทั้งหมด'),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(child: StatCard(label: 'ค่ายทั้งหมด', value: '$totalCamps', icon: Icons.event_note)),
            const SizedBox(width: 10),
            Expanded(child: StatCard(label: 'กำลังดำเนินการ', value: '$ongoingCamps', icon: Icons.trending_up, color: Colors.orange)),
            const SizedBox(width: 10),
            Expanded(child: StatCard(label: 'เสร็จสิ้นแล้ว', value: '$finishedCamps', icon: Icons.check_circle_outline, color: kGreen)),
          ],
        ),
        const SectionTitle('ความคืบหน้าของแต่ละค่ายและรายฝ่าย'),
        if (camps.isEmpty) const EmptyState('ยังไม่มีค่ายในระบบ'),
        ...camps.map((camp) {
          final overallProgress = app.overallReadiness(camp.id);
          final overallPercent = (overallProgress * 100).toInt();

          return Card(
            margin: const EdgeInsets.only(bottom: 14),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CampDetailScreen(campId: camp.id)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            camp.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        StatusChip(camp.status.label, camp.status.color),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(thaiRange(camp.start, camp.end), style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    const Divider(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('ความคืบหน้าภาพรวม', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        Text('$overallPercent%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kGreen)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: overallProgress,
                        minHeight: 8,
                        backgroundColor: Colors.black12,
                        color: camp.status == CampStatus.finished ? kGreen : Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('สถานะความคืบหน้าแต่ละฝ่าย:', style: TextStyle(fontSize: 11, color: Colors.black54)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: app.workingDepartments.map((dept) {
                        final deptProgress = app.readiness(camp.id, dept);
                        final deptPercent = (deptProgress * 100).toInt();
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: dept.color.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: dept.color.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            '${dept.label}: $deptPercent%',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: dept.color),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}