import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import 'login_screen.dart';


class CampListScreen extends StatelessWidget {
  const CampListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final camps = app.camps.toList()..sort((a, b) => b.start.compareTo(a.start));

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: app.isCommittee
          ? FloatingActionButton.extended(
              backgroundColor: kGreen,
              icon: const Icon(Icons.add),
              label: const Text('เพิ่มค่ายใหม่'),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CampFormScreen())),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionTitle('จัดการค่ายทั้งหมด'),
          if (camps.isEmpty) const EmptyState('ยังไม่มีค่ายในระบบ'),
          ...camps.asMap().entries.map((e) {
            final c = e.value;
            final place = app.place(c.placeId);
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: const EdgeInsets.all(10),
                leading: c.images.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(File(c.images.first), width: 64, height: 64, fit: BoxFit.cover),
                      )
                    : CampThumb(seed: e.key),
                title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('${thaiRange(c.start, c.end)} • ${place?.province ?? 'ไม่ระบุสถานที่'}',
                        style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 6),
                    StatusChip(c.status.label, c.status.color),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (app.isCommittee) ...[
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blueGrey),
                        tooltip: 'แก้ไขข้อมูลค่าย',
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => CampFormScreen(camp: c)),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        tooltip: 'ลบค่าย',
                        onPressed: () => _confirmDelete(context, app, c),
                      ),
                    ],
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CampDetailScreen(campId: c.id)),
                ),
              ),
            );
          }),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, AppState app, Camp camp) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('ยืนยันลบค่าย "${camp.name}"?'),
        content: const Text('ข้อมูลอุปกรณ์ และงานของฝ่ายทั้งหมดในค่ายนี้จะถูกลบถาวร'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              app.deleteCamp(camp.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ลบค่ายเรียบร้อยแล้ว')));
            },
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
  }
}

class CampFormScreen extends StatefulWidget {
  final Camp? camp;
  const CampFormScreen({super.key, this.camp});

  @override
  State<CampFormScreen> createState() => _CampFormScreenState();
}

class _CampFormScreenState extends State<CampFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _target;
  late final TextEditingController _desc;
  DateTime? _start, _end;
  String? _placeId;
  final List<String> _campImages = [];

  @override
  void initState() {
    super.initState();
    final c = widget.camp;
    _name = TextEditingController(text: c?.name ?? '');
    _target = TextEditingController(text: '${c?.participantTarget ?? 0}');
    _desc = TextEditingController(text: c?.description ?? '');
    _start = c?.start;
    _end = c?.end;
    _placeId = c?.placeId;
    if (c != null && c.images.isNotEmpty) {
      _campImages.addAll(c.images);
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );
      
      // ตรวจสอบว่าได้เลือกรูปจริงหรือไม่ ก่อนเรียก setState
      if (pickedFile != null && mounted) {
        setState(() {
          _campImages.add(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่สามารถเลือกรูปภาพได้ กรุณาลองใหม่อีกครั้ง')),
        );
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final d = await showDatePicker(
      context: context,
      initialDate: isStart ? (_start ?? DateTime.now()) : (_end ?? _start ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (d != null) {
      setState(() {
        if (isStart) {
          _start = d;
          if (_end != null && _end!.isBefore(d)) _end = d;
        } else {
          _end = d;
        }
      });
    }
  }

  void _addNewPlaceDialog(AppState app) {
    final nameCtrl = TextEditingController();
    final provCtrl = TextEditingController();
    final capCtrl = TextEditingController(text: '50');
    final contactCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('เพิ่มสถานที่จัดค่ายใหม่'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'ชื่อสถานที่')),
              const SizedBox(height: 10),
              TextField(controller: provCtrl, decoration: const InputDecoration(labelText: 'จังหวัด')),
              const SizedBox(height: 10),
              TextField(controller: capCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'ความจุ (คน)')),
              const SizedBox(height: 10),
              TextField(controller: contactCtrl, decoration: const InputDecoration(labelText: 'เบอร์ติดต่อ')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก')),
          FilledButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              app.addPlace(
                name: nameCtrl.text.trim(),
                province: provCtrl.text.trim(),
                capacity: int.tryParse(capCtrl.text) ?? 50,
                contact: contactCtrl.text.trim(),
              );
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('บันทึกสถานที่'),
          ),
        ],
      ),
    );
  }

    void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_start == null || _end == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณาเลือกวันที่เริ่มและวันที่สิ้นสุด')));
      return;
    }
    final app = context.read<AppState>();

    if (widget.camp == null) {
      app.createCamp(
        name: _name.text.trim(),
        start: _start!,
        end: _end!,
        placeId: _placeId,
        participantTarget: int.tryParse(_target.text) ?? 0,
        description: _desc.text.trim(),
        images: _campImages,
      );
       if (mounted) {

        Navigator.pushAndRemoveUntil(

          context,

          MaterialPageRoute(builder: (_) => const LoginScreen()),

          (route) => false,

        );

      }

    } else {

      app.updateCampInfo(

        widget.camp!.id,

        name: _name.text.trim(),

        start: _start!,

        end: _end!,

        placeId: _placeId,

        participantTarget: int.tryParse(_target.text) ?? 0,

        description: _desc.text.trim(),

        images: _campImages,

      );
  }
    }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final isEditing = widget.camp != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'แก้ไขข้อมูลค่าย' : 'สร้างค่ายใหม่')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'ชื่อค่าย *'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'กรุณากรอกชื่อค่าย' : null,
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _DateField(label: 'วันที่เริ่ม *', value: _start, onTap: () => _pickDate(true))),
              const SizedBox(width: 10),
              Expanded(child: _DateField(label: 'วันที่สิ้นสุด *', value: _end, onTap: () => _pickDate(false))),
            ]),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _placeId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'สถานที่จัดค่าย'),
                    items: app.places
                        .map((p) => DropdownMenuItem(value: p.id, child: Text('${p.name} จ.${p.province}', overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (v) => setState(() => _placeId = v),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.add),
                  tooltip: 'เพิ่มสถานที่ใหม่',
                  onPressed: () => _addNewPlaceDialog(app),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _target,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'จำนวนผู้เข้าร่วม (คน)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _desc,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'รายละเอียดค่าย'),
            ),
            const SizedBox(height: 16),
            const Text('รูปภาพบรรยากาศค่าย', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black26),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, color: Colors.grey),
                          SizedBox(height: 4),
                          Text('เพิ่มรูป', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ..._campImages.map((path) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(File(path), width: 100, height: 100, fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => setState(() => _campImages.remove(path)),
                                child: Container(
                                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                  child: const Icon(Icons.close, size: 18, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: kGreen),
                icon: const Icon(Icons.save),
                label: Text(isEditing ? 'บันทึกการแก้ไข' : 'บันทึกค่าย'),
                onPressed: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  const _DateField({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(labelText: label, suffixIcon: const Icon(Icons.calendar_today, size: 18)),
          child: Text(value == null ? 'เลือกวันที่' : thaiDate(value!),
              style: TextStyle(color: value == null ? Colors.black38 : Colors.black87)),
        ),
      );
}

class CampDetailScreen extends StatelessWidget {
  final String campId;
  const CampDetailScreen({super.key, required this.campId});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final camp = app.camp(campId);

    if (camp == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('ไม่พบข้อมูลค่าย')),
        body: const Center(child: Text('ค่ายนี้อาจถูกลบไปแล้ว')),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(camp.name, style: const TextStyle(fontSize: 16)),
          actions: [
            if (app.isCommittee)
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'แก้ไขข้อมูลค่าย',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CampFormScreen(camp: camp)),
                ),
              ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            labelColor: kGreen,
            indicatorColor: kGreen,
            tabs: [
              Tab(text: 'ภาพรวม'),
              Tab(text: 'อุปกรณ์'),
              Tab(text: 'งานของฝ่าย'),
            ],
          ),
        ),
        body: TabBarView(children: [
          _OverviewTab(campId: campId),
          _EquipmentTab(campId: campId),
          _TaskTab(campId: campId),
        ]),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final String campId;
  const _OverviewTab({required this.campId});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final camp = app.camp(campId)!;
    final place = app.place(camp.placeId);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (camp.images.isNotEmpty) ...[
          const SectionTitle('รูปภาพบรรยากาศ'),
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: camp.images
                  .map((path) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(File(path), width: 120, height: 120, fit: BoxFit.cover),
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 10),
        ],
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _row(Icons.event, thaiRange(camp.start, camp.end)),
                _row(Icons.place, place == null ? 'ยังไม่ระบุสถานที่' : '${place.name} จ.${place.province}'),
                _row(Icons.groups, 'เป้าหมายผู้เข้าร่วม ${camp.participantTarget} คน'),
                _row(Icons.inventory_2_outlined, 'อุปกรณ์ ${app.equipmentOf(campId).length} รายการ'),
                const SizedBox(height: 8),
                StatusChip(camp.status.label, camp.status.color),
              ],
            ),
          ),
        ),
        const SectionTitle('รายละเอียด'),
        Text(camp.description.isEmpty ? '-' : camp.description, style: const TextStyle(height: 1.6)),
        if (app.isCommittee && camp.status != CampStatus.finished) ...[
          const SectionTitle('การจัดการ (กรรมการ)'),
          Wrap(spacing: 8, children: [
            for (final s in [CampStatus.draft, CampStatus.preparing, CampStatus.ongoing])
              ChoiceChip(
                label: Text(s.label),
                selected: camp.status == s,
                onSelected: (_) => app.updateCampStatus(campId, s),
              ),
          ]),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: kDarkGreen),
              icon: const Icon(Icons.archive_outlined),
              label: const Text('ปิดค่ายและบันทึกสรุป'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CloseCampScreen(campId: campId)),
              ),
            ),
          ),
        ],
        if (camp.summary != null) ...[
          const SectionTitle('สรุปหลังจบค่าย'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ผู้เข้าร่วมจริง ${camp.summary!.actualParticipants} คน',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(camp.summary!.text, style: const TextStyle(height: 1.6)),
                  const Divider(height: 20),
                  Text('บทเรียน: ${camp.summary!.lessons}', style: const TextStyle(height: 1.6)),
                  if (camp.summary!.photos.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Text('อัลบั้มภาพกิจกรรม:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: camp.summary!.photos
                          .map((p) => ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(File(p), width: 80, height: 80, fit: BoxFit.cover),
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _row(IconData i, String t) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Icon(i, size: 17, color: Colors.black45),
          const SizedBox(width: 10),
          Expanded(child: Text(t, style: const TextStyle(fontSize: 13))),
        ]),
      );
}

class _EquipmentTab extends StatelessWidget {
  final String campId;
  const _EquipmentTab({required this.campId});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final list = app.equipmentOf(campId);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kGreen,
        icon: const Icon(Icons.add_box_outlined),
        label: const Text('เพิ่มอุปกรณ์'),
        onPressed: () => _equipmentDialog(context, app, null),
      ),
      body: list.isEmpty
          ? const Center(
              child: EmptyState('ยังไม่มีรายการอุปกรณ์ในค่ายนี้'),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: list.map((u) {
                final e = app.equipment(u.equipmentId);
                if (e == null) return const SizedBox.shrink();
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const Icon(Icons.inventory_2_outlined, color: kGreen),
                    title: Text(e.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: Text('หมวด ${e.category} • จำนวน ${u.qty} ${e.unit}',
                        style: const TextStyle(fontSize: 12)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blueGrey),
                          onPressed: () => _equipmentDialog(context, app, u),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18, color: Colors.redAccent),
                          onPressed: () => app.removeEquipmentUse(campId, e.id),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }

  void _equipmentDialog(BuildContext context, AppState app, CampEquipmentUse? item) {
    final eq = item != null ? app.equipment(item.equipmentId) : null;
    final nameCtrl = TextEditingController(text: eq?.name ?? '');
    final catCtrl = TextEditingController(text: eq?.category ?? 'ทั่วไป');
    final qtyCtrl = TextEditingController(text: item != null ? '${item.qty}' : '1');
    final unitCtrl = TextEditingController(text: eq?.unit ?? 'ชิ้น');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(item == null ? 'เพิ่มอุปกรณ์สำหรับค่าย' : 'แก้ไขอุปกรณ์'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'ชื่ออุปกรณ์')),
              const SizedBox(height: 10),
              TextField(controller: catCtrl, decoration: const InputDecoration(labelText: 'หมวดหมู่ (เช่น ครัว, ที่พัก)')),
              const SizedBox(height: 10),
              TextField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'จำนวน')),
              const SizedBox(height: 10),
              TextField(controller: unitCtrl, decoration: const InputDecoration(labelText: 'หน่วย (เช่น หลัง, ใบ, ชุด)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก')),
          FilledButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              final qty = int.tryParse(qtyCtrl.text) ?? 1;
              if (item != null) {
                app.removeEquipmentUse(campId, item.equipmentId);
              }
              app.addEquipmentUse(campId, nameCtrl.text.trim(), catCtrl.text.trim(), qty, unitCtrl.text.trim());
              Navigator.pop(context);
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }
}

class _TaskTab extends StatefulWidget {
  final String campId;
  const _TaskTab({required this.campId});
  @override
  State<_TaskTab> createState() => _TaskTabState();
}

class _TaskTabState extends State<_TaskTab> {
  Department? _filter;

  @override
  void initState() {
    super.initState();
    final u = context.read<AppState>().currentDept;
    if (u != null && u != Department.committee) _filter = u;
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final tasks = app.tasksOf(widget.campId, dept: _filter);
    final targetDept = _filter ?? app.currentDept ?? Department.welfare;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kGreen,
        icon: const Icon(Icons.add_task),
        label: const Text('เพิ่มงาน'),
        onPressed: () => _taskDialog(context, app, dept: targetDept),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 58,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: const Text('ทุกฝ่าย'),
                    selected: _filter == null,
                    onSelected: (_) => setState(() => _filter = null),
                  ),
                ),
                ...app.workingDepartments.map((d) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(d.label),
                        selected: _filter == d,
                        onSelected: (_) => setState(() => _filter = d),
                      ),
                    )),
              ],
            ),
          ),
          Expanded(
            child: tasks.isEmpty
                ? const EmptyState('ยังไม่มีงานในฝ่ายนี้')
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                    children: tasks.map((t) {
                      final editable = app.canEdit(t.dept);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: DeptAvatar(t.dept),
                          title: Text(t.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('${t.dept.label} • อัปเดต ${thaiDate(t.updatedAt)}',
                                  style: const TextStyle(fontSize: 11)),
                              if (t.note.isNotEmpty)
                                Text(t.note, style: const TextStyle(fontSize: 11, color: Colors.black54)),
                              const SizedBox(height: 6),
                              StatusChip(t.status.label, t.status.color),
                            ],
                          ),
                          trailing: editable
                              ? PopupMenuButton<String>(
                                  onSelected: (v) {
                                    if (v == 'edit') {
                                      _taskDialog(context, app, dept: t.dept, task: t);
                                    } else if (v == 'delete') {
                                      app.deleteTask(t.id);
                                    } else {
                                      app.updateTask(t.id, status: TaskStatus.values.byName(v));
                                    }
                                  },
                                  itemBuilder: (_) => [
                                    ...TaskStatus.values.map((s) =>
                                        PopupMenuItem(value: s.name, child: Text('ตั้งเป็น: ${s.label}'))),
                                    const PopupMenuDivider(),
                                    const PopupMenuItem(value: 'edit', child: Text('แก้ไข')),
                                    const PopupMenuItem(value: 'delete', child: Text('ลบ')),
                                  ],
                                )
                              : const Icon(Icons.lock_outline, size: 16, color: Colors.black26),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  void _taskDialog(BuildContext context, AppState app, {required Department dept, DeptTask? task}) {
    if (!app.canEdit(task?.dept ?? dept)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('แก้ไขได้เฉพาะงานของฝ่ายตัวเอง (หรือกรรมการ)')),
      );
      return;
    }
    final title = TextEditingController(text: task?.title ?? '');
    final note = TextEditingController(text: task?.note ?? '');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(task == null ? 'เพิ่มงาน — ${dept.label}' : 'แก้ไขงาน'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: title, decoration: const InputDecoration(labelText: 'ชื่องาน')),
            const SizedBox(height: 10),
            TextField(controller: note, decoration: const InputDecoration(labelText: 'หมายเหตุ')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก')),
          FilledButton(
            onPressed: () {
              if (title.text.trim().isEmpty) return;
              if (task == null) {
                app.addTask(widget.campId, dept, title.text.trim(), note: note.text.trim());
              } else {
                app.updateTask(task.id, title: title.text.trim(), note: note.text.trim());
              }
              Navigator.pop(context);
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }
}

class CloseCampScreen extends StatefulWidget {
  final String campId;
  const CloseCampScreen({super.key, required this.campId});
  @override
  State<CloseCampScreen> createState() => _CloseCampScreenState();
}

class _CloseCampScreenState extends State<CloseCampScreen> {
  late final TextEditingController _summary;
  late final TextEditingController _lessons;
  late final TextEditingController _actual;
  late List<String> _photos;

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    final camp = app.camp(widget.campId);
    
    _summary = TextEditingController(text: camp?.summary?.text ?? '');
    _lessons = TextEditingController(text: camp?.summary?.lessons ?? '');
    _actual = TextEditingController(text: '${camp?.summary?.actualParticipants ?? camp?.participantTarget ?? 0}');
    _photos = List.from(camp?.summary?.photos ?? []);
  }

  Future<void> _pickSummaryImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _photos.add(pickedFile.path);
      });
    }
  }

  @override
  void dispose() {
    _summary.dispose();
    _lessons.dispose();
    _actual.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('ปิดค่ายและบันทึกประวัติ')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _actual,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'จำนวนผู้เข้าร่วมจริง (คน)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _summary,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'สรุปกิจกรรมที่เกิดขึ้น'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _lessons,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'บทเรียน / ข้อเสนอแนะสำหรับรุ่นต่อไป'),
          ),
          const SectionTitle('อัลบั้มภาพกิจกรรม (จากเครื่อง)'),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                GestureDetector(
                  onTap: _pickSummaryImage,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black26),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate, color: Colors.grey),
                        SizedBox(height: 4),
                        Text('เพิ่มรูปสรุป', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ..._photos.map((path) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(File(path), width: 100, height: 100, fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => setState(() => _photos.remove(path)),
                              child: Container(
                                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                child: const Icon(Icons.close, size: 18, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: kDarkGreen),
              icon: const Icon(Icons.archive),
              label: const Text('ปิดค่ายและบันทึก'),
              onPressed: () {
                app.closeCamp(
                  widget.campId,
                  CampSummary(
                    text: _summary.text.trim(),
                    lessons: _lessons.text.trim(),
                    actualParticipants: int.tryParse(_actual.text) ?? 0,
                    photos: _photos,
                  ),
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('บันทึกข้อมูลค่ายเข้าคลังประวัติเรียบร้อย')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}