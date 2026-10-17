import 'package:flutter/material.dart';
import '../models/models.dart';

const kGreen = Color(0xFF2E7D4F);
const kDarkGreen = Color(0xFF1B4332);
const kBg = Color(0xFFF4F8F4);

const _thMonths = [
  '', 'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
  'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
];

String thaiDate(DateTime d) => '${d.day} ${_thMonths[d.month]} ${d.year + 543}';

String thaiRange(DateTime a, DateTime b) =>
    a.month == b.month && a.year == b.year
        ? '${a.day} - ${b.day} ${_thMonths[b.month]} ${b.year + 543}'
        : '${thaiDate(a)} - ${thaiDate(b)}';

class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const StatusChip(this.label, this.color, {super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      );
}

class StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const StatCard({super.key, required this.label, required this.value, required this.icon, this.color = kGreen});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 10),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
      );
}

class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 18, 0, 10),
        child: Row(
          children: [
            Expanded(child: Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold))),
            if (trailing != null) trailing!,
          ],
        ),
      );
}

class CampThumb extends StatelessWidget {
  final double size;
  final int seed;
  const CampThumb({super.key, this.size = 64, this.seed = 0});

  @override
  Widget build(BuildContext context) {
    const images = [
      'assets/images/three.jpg',
      'assets/images/two.jpg',
      'assets/images/one.jpg',
    ];
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(images[seed % images.length], width: size, height: size, fit: BoxFit.cover)
    );
  }
}

class EmptyState extends StatelessWidget {
  final String text;
  const EmptyState(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 36),
        child: Column(
          children: [
            const Icon(Icons.inbox_outlined, size: 40, color: Colors.black26),
            const SizedBox(height: 8),
            Text(text, style: const TextStyle(color: Colors.black45)),
          ],
        ),
      );
}

class DeptAvatar extends StatelessWidget {
  final Department dept;
  const DeptAvatar(this.dept, {super.key});

  @override
  Widget build(BuildContext context) => CircleAvatar(
        radius: 18,
        backgroundColor: dept.color.withOpacity(.15),
        child: Icon(dept.icon, size: 18, color: dept.color),
      );
}