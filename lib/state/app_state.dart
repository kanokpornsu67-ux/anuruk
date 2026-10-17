import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/database_helper.dart';

class AppState extends ChangeNotifier {
  // รหัสผ่านกลางของชมรม
  static const String clubPassword = 'anuruk';

  final List<Place> places = [];
  final List<Equipment> equipments = [];
  final List<Camp> camps = [];
  final List<CampEquipmentUse> equipmentUses = [];
  final List<DeptTask> tasks = [];
  final List<CalendarEvent> calendarEvents = [];
  final DatabaseHelper _db = DatabaseHelper.instance;

  Department? currentDept;
  int _seq = 0;
  String _id(String p) => '$p${DateTime.now().microsecondsSinceEpoch}_${++_seq}';

  void _persist(Future<void> job) {
    job.catchError((Object e) {
      debugPrint('DB error: $e');
    });
  }

  Future<void> init() async {
    if (await _db.isEmpty()) {
      seed();
      return;
    }
    final d = await _db.loadAll();
    places..clear()..addAll(d.places);
    equipments..clear()..addAll(d.equipments);
    camps..clear()..addAll(d.camps);
    equipmentUses..clear()..addAll(d.equipmentUses);
    tasks..clear()..addAll(d.tasks);
    calendarEvents..clear()..addAll(d.calendarEvents);
    notifyListeners();
  }

  bool get isLoggedIn => currentDept != null;
  bool get isCommittee => currentDept==Department.committee;
  bool canEdit(Department d) => isCommittee || currentDept == d;
  String? login(String username, String password) {
    if (password != clubPassword) {
      return 'รหัสผ่านชมรมไม่ถูกต้อง';
    }

    final input = username.trim().toLowerCase();
    Department? matchedDept;

    switch (input) {
      case 'welfare':
        matchedDept = Department.welfare;
        break;
      case 'medical':
        matchedDept = Department.medical;
        break;
      case 'venue':
        matchedDept = Department.venue;
        break;
      case 'publication':
        matchedDept = Department.publication;
        break;
      case 'recreation':
        matchedDept = Department.recreation;
        break;
      case 'houseleader':
        matchedDept = Department.houseLeader;
        break;
      case 'media':
        matchedDept = Department.media;
        break;
      case 'committee':
        matchedDept = Department.committee;
        break;
    }

    if (matchedDept == null) {
      return 'ไม่พบชื่อฝ่ายนี้ในระบบ';
    }

    currentDept = matchedDept;
    notifyListeners();
    return null; // ล็อกอินสำเร็จ
  }
  void logout() {
    currentDept = null;
    notifyListeners();
  }

  // ---------- LOOKUP ----------
  Camp? camp(String id) => camps.where((c) => c.id == id).firstOrNull;
  Place? place(String? id) => id == null ? null : places.where((p) => p.id == id).firstOrNull;
  Equipment? equipment(String id) => equipments.where((e) => e.id == id).firstOrNull;

  List<Camp> get publicCamps =>
      camps.where((c) => c.status != CampStatus.draft).toList()..sort((a, b) => b.start.compareTo(a.start));
  List<Camp> get activeCamps =>
      camps.where((c) => c.status != CampStatus.finished).toList()..sort((a, b) => a.start.compareTo(b.start));
  List<Camp> get finishedCamps =>
      camps.where((c) => c.status == CampStatus.finished).toList()..sort((a, b) => b.start.compareTo(a.start));

  List<CampEquipmentUse> equipmentOf(String campId) => equipmentUses.where((e) => e.campId == campId).toList();
  List<DeptTask> tasksOf(String campId, {Department? dept}) =>
      tasks.where((t) => t.campId == campId && (dept == null || t.dept == dept)).toList();

  // ---------- CAMP CRUD ----------
  Camp createCamp({
    required String name,
    required DateTime start,
    required DateTime end,
    String? placeId,
    int participantTarget = 0,
    String description = '',
    List<String>? images,
  }) {
    final c = Camp(
      id: _id('camp'),
      name: name,
      start: start,
      end: end,
      placeId: placeId,
      participantTarget: participantTarget,
      description: description,
      images: images ?? [], 
      status: CampStatus.preparing, 
    );
    camps.add(c);
    _persist(_db.saveCamp(c));
    notifyListeners();
    return c;
  }

  void deleteCamp(String campId) {
    camps.removeWhere((c) => c.id == campId);
    equipmentUses.removeWhere((e) => e.campId == campId);
    tasks.removeWhere((t) => t.campId == campId);
    _persist(_db.deleteCamp(campId));
    notifyListeners();
  }

  void updateCampStatus(String campId, CampStatus s) {
    final c = camp(campId);
    if (c == null) return;
    c.status = s;
    _persist(_db.saveCamp(c));
    notifyListeners();
  }

  // ---------- PLACES (จัดการสถานที่อิสระ) ----------
  void addPlace({required String name, required String province, required int capacity, required String contact}) {
    final p = Place(id: _id('p'), name: name, province: province, capacity: capacity, contact: contact);
    places.add(p);
    _persist(_db.savePlace(p));
    notifyListeners();
  }

  void deletePlace(String id) {
    places.removeWhere((p) => p.id == id);
    _persist(_db.deletePlace(id));
    notifyListeners();
  }

  // ---------- EQUIPMENT (จัดการอุปกรณ์อิสระรายค่าย) ----------
  void addEquipmentUse(String campId, String name, String category, int qty, String unit) {
    final eId = _id('eq');
    final eq = Equipment(id: eId, name: name, category: category, unit: unit, total: qty);
    equipments.add(eq);
    _persist(_db.saveEquipment(eq));

    final use = CampEquipmentUse(campId: campId, equipmentId: eId, qty: qty);
    equipmentUses.add(use);
    _persist(_db.saveEquipmentUse(use));
    notifyListeners();
  }

  void removeEquipmentUse(String campId, String equipmentId) {
    equipmentUses.removeWhere((e) => e.campId == campId && e.equipmentId == equipmentId);
    equipments.removeWhere((e) => e.id == equipmentId);
    _persist(_db.deleteEquipmentUse(campId, equipmentId));
    _persist(_db.deleteEquipment(equipmentId));
    notifyListeners();
  }

  // ---------- TASKS (งานของแต่ละฝ่าย) ----------
  void addTask(String campId, Department dept, String title, {String note = ''}) {
    final t = DeptTask(id: _id('task'), campId: campId, dept: dept, title: title, note: note);
    tasks.add(t);
    _persist(_db.saveTask(t));
    notifyListeners();
  }

  void updateTask(String taskId, {String? title, TaskStatus? status, String? note}) {
    final t = tasks.where((e) => e.id == taskId).firstOrNull;
    if (t == null) return;
    if (title != null) t.title = title;
    if (status != null) t.status = status;
    if (note != null) t.note = note;
    t.updatedAt = DateTime.now();
    _persist(_db.saveTask(t));
    notifyListeners();
  }

  void deleteTask(String taskId) {
    tasks.removeWhere((t) => t.id == taskId);
    _persist(_db.deleteTask(taskId));
    notifyListeners();
  }

  // ---------- READINESS (ความพร้อม & เปอร์เซ็นต์) ----------
  double readiness(String campId, Department dept) {
    final list = tasksOf(campId, dept: dept);
    if (list.isEmpty) return 0;
    return list.where((t) => t.status == TaskStatus.done).length / list.length;
  }

  double overallReadiness(String campId) {
    final list = tasksOf(campId);
    if (list.isEmpty) return 0;
    return list.where((t) => t.status == TaskStatus.done).length / list.length;
  }

  List<Department> get workingDepartments =>
      Department.values.where((d) => d != Department.committee).toList();

  // ---------- CLOSE CAMP ----------
  void closeCamp(String campId, CampSummary summary) {
    final c = camp(campId);
    if (c == null) return;
    c.summary = summary;
    c.status = CampStatus.finished;
    _persist(_db.saveCamp(c));
    notifyListeners();
  }
  //-------update camp -------------
  void updateCampInfo(
    String campId, {
    required String name,
    required DateTime start,
    required DateTime end,
    String? placeId,
    int participantTarget = 0,
    String description = '',
    List<String>? images,
  }) {
    final c = camp(campId);
    if (c == null) return;

    c.name = name;
    c.start = start;
    c.end = end;
    c.placeId = placeId;
    c.participantTarget = participantTarget;
    c.description = description;
    if (images != null) {

      c.images = images; 

    }

    // บันทึกลงฐานข้อมูล SQLite และแจ้งเตือนหน้าจอทันที
    _persist(_db.saveCamp(c));
    notifyListeners();
  }

  // ---------- SEED ----------
  void seed() {
    addPlace(name: 'อุทยานแห่งชาติดอยอินทนนท์', province: 'เชียงใหม่', capacity: 150, contact: '053-286-729');
    addPlace(name: 'ศูนย์เรียนรู้ป่าชุมชนบ้านห้วยปลาหลด', province: 'ตาก', capacity: 80, contact: '081-234-5678');

    final c1 = createCamp(
      name: 'ค่ายพบเพื่อนเดินป่า ครั้งที่ 23',
      start: DateTime(2026, 3, 15),
      end: DateTime(2026, 3, 17),
      placeId: places.first.id,
      participantTarget: 120,
      description: 'ค่ายอนุรักษ์ประจำปีของชมรม เน้นการปลูกป่า ฟื้นฟูระบบนิเวศ',
    );
    c1.status = CampStatus.ongoing;
    _persist(_db.saveCamp(c1));

    for (final d in workingDepartments) {
      addTask(c1.id, d, 'วางแผนงาน${d.label}');
      addTask(c1.id, d, 'สรุปรายการเบิก-จ่ายของ${d.label}');
    }
    updateTask(tasks.first.id, status: TaskStatus.done);
    updateTask(tasks[1].id, status: TaskStatus.done);
  }
    // เพิ่มตัวแปรเก็บข้อมูลปฏิทินตรงนี้
  final List<CalendarEvent> CalendarEvents = [];

  // เพิ่มฟังก์ชันจัดการปฏิทินตรงนี้
  Future<void> addCalendarEvent({
    required String title,
    required String description,
    required DateTime date,
    Department? targetDept,
  }) async {
    if (!isCommittee) return;
    
    final event = CalendarEvent(
      id: _id('evt'),
      title: title,
      description: description,
      date: date,
      targetDept: targetDept,
    );
    calendarEvents.add(event);
    _persist(_db.saveCalendarEvent(event));
    notifyListeners();
  }

  void deleteCalendarEvent(String id) {
    if (!isCommittee) return;
    calendarEvents.removeWhere((e) => e.id == id);
    notifyListeners();
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}