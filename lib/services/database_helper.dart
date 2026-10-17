import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/models.dart';

class LoadedData {
  final List<Place> places;
  final List<Equipment> equipments;
  final List<Camp> camps;
  final List<CampEquipmentUse> equipmentUses;
  final List<DeptTask> tasks;
  final List<CalendarEvent> calendarEvents; // เพิ่มเข้ามา

  LoadedData({
    required this.places,
    required this.equipments,
    required this.camps,
    required this.equipmentUses,
    required this.tasks,
    required this.calendarEvents, // เพิ่มเข้ามา
  });
}

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const _dbName = 'anuruk_v4.db';
  static const _dbVersion = 2; // เปลี่ยนเวอร์ชันจาก 1 เป็น 2 เพื่อให้ระบบสร้างตารางใหม่ให้อัตโนมัติ

  Database? _db;

  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), _dbName);
    return openDatabase(
      path, 
      version: _dbVersion, 
      onCreate: _onCreate,
      onUpgrade: (db, oldVersion, newVersion) async {
        // รองรับกรณีอัปเกรดฐานข้อมูลข้ามเวอร์ชัน
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE calendar_events (
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              description TEXT NOT NULL,
              date TEXT NOT NULL,
              target_dept TEXT
            )''');
        }
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE places (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        province TEXT NOT NULL,
        contact TEXT NOT NULL,
        capacity INTEGER NOT NULL
      )''');

    await db.execute('''
      CREATE TABLE equipments (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        unit TEXT NOT NULL,
        total INTEGER NOT NULL
      )''');

    await db.execute('''
      CREATE TABLE camps (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        place_id TEXT,
        participant_target INTEGER NOT NULL,
        status TEXT NOT NULL,
        camp_images TEXT,
        summary_text TEXT,
        summary_lessons TEXT,
        summary_actual INTEGER,
        summary_photos TEXT,
        summary_archived_at TEXT
      )''');

    await db.execute('''
      CREATE TABLE camp_equipment_use (
        camp_id TEXT NOT NULL,
        equipment_id TEXT NOT NULL,
        qty INTEGER NOT NULL,
        actual_qty INTEGER,
        PRIMARY KEY (camp_id, equipment_id)
      )''');

    await db.execute('''
      CREATE TABLE dept_tasks (
        id TEXT PRIMARY KEY,
        camp_id TEXT NOT NULL,
        dept TEXT NOT NULL,
        title TEXT NOT NULL,
        note TEXT NOT NULL,
        status TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )''');

    // เพิ่มตารางปฏิทินใหม่
    await db.execute('''
      CREATE TABLE calendar_events (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        date TEXT NOT NULL,
        target_dept TEXT
      )''');
  }

  Future<bool> isEmpty() async {
    final db = await database;
    final n = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM camps'));
    return (n ?? 0) == 0;
  }

  Future<LoadedData> loadAll() async {
    final db = await database;

    final places = (await db.query('places')).map((r) => Place(
          id: r['id'] as String,
          name: r['name'] as String,
          province: r['province'] as String,
          contact: r['contact'] as String,
          capacity: r['capacity'] as int,
        )).toList();

    final equipments = (await db.query('equipments')).map((r) => Equipment(
          id: r['id'] as String,
          name: r['name'] as String,
          category: r['category'] as String,
          unit: r['unit'] as String,
          total: r['total'] as int,
        )).toList();

    final camps = (await db.query('camps')).map((r) {
      CampSummary? summary;
      if (r['summary_archived_at'] != null) {
        summary = CampSummary(
          text: (r['summary_text'] as String?) ?? '',
          lessons: (r['summary_lessons'] as String?) ?? '',
          actualParticipants: (r['summary_actual'] as int?) ?? 0,
          photos: List<String>.from(jsonDecode((r['summary_photos'] as String?) ?? '[]') as List),
          archivedAt: DateTime.parse(r['summary_archived_at'] as String),
        );
      }
      return Camp(
        id: r['id'] as String,
        name: r['name'] as String,
        description: r['description'] as String,
        start: DateTime.parse(r['start_date'] as String),
        end: DateTime.parse(r['end_date'] as String),
        placeId: r['place_id'] as String?,
        participantTarget: r['participant_target'] as int,
        status: CampStatus.values.byName(r['status'] as String),
        summary: summary,
        images: List<String>.from(jsonDecode((r['camp_images'] as String?) ?? '[]') as List),
      );
    }).toList();

    final uses = (await db.query('camp_equipment_use')).map((r) => CampEquipmentUse(
          campId: r['camp_id'] as String,
          equipmentId: r['equipment_id'] as String,
          qty: r['qty'] as int,
          actualQty: r['actual_qty'] as int?,
        )).toList();

    final tasks = (await db.query('dept_tasks')).map((r) => DeptTask(
          id: r['id'] as String,
          campId: r['camp_id'] as String,
          dept: Department.values.byName(r['dept'] as String),
          title: r['title'] as String,
          note: r['note'] as String,
          status: TaskStatus.values.byName(r['status'] as String),
          updatedAt: DateTime.parse(r['updated_at'] as String),
        )).toList();

    // โหลดข้อมูลปฏิทินจากฐานข้อมูล
    final calendarEvents = (await db.query('calendar_events')).map((r) => CalendarEvent(
          id: r['id'] as String,
          title: r['title'] as String,
          description: r['description'] as String,
          date: DateTime.parse(r['date'] as String),
          targetDept: r['target_dept'] != null ? Department.values.byName(r['target_dept'] as String) : null, // ปรับชื่อฟิลด์ตามโมเดลของคุณ
        )).toList();

    return LoadedData(
      places: places,
      equipments: equipments,
      camps: camps,
      equipmentUses: uses,
      tasks: tasks,
      calendarEvents: calendarEvents, // ส่งค่ากลับไป
    );
  }

  Future<void> savePlace(Place p) async {
    final db = await database;
    await db.insert('places', {
      'id': p.id,
      'name': p.name,
      'province': p.province,
      'contact': p.contact,
      'capacity': p.capacity,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deletePlace(String id) async {
    final db = await database;
    await db.delete('places', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> saveEquipment(Equipment e) async {
    final db = await database;
    await db.insert('equipments', {
      'id': e.id,
      'name': e.name,
      'category': e.category,
      'unit': e.unit,
      'total': e.total,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteEquipment(String id) async {
    final db = await database;
    await db.delete('equipments', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> saveCamp(Camp c) async {
    final db = await database;
    final s = c.summary;
    await db.insert(
      'camps',
      {
        'id': c.id,
        'name': c.name,
        'description': c.description,
        'start_date': c.start.toIso8601String(),
        'end_date': c.end.toIso8601String(),
        'place_id': c.placeId,
        'participant_target': c.participantTarget,
        'status': c.status.name,
        'camp_images': jsonEncode(c.images),
        'summary_text': s?.text,
        'summary_lessons': s?.lessons,
        'summary_actual': s?.actualParticipants,
        'summary_photos': s == null ? null : jsonEncode(s.photos),
        'summary_archived_at': s?.archivedAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteCamp(String campId) async {
    final db = await database;
    await db.delete('camps', where: 'id = ?', whereArgs: [campId]);
    await db.delete('camp_equipment_use', where: 'camp_id = ?', whereArgs: [campId]);
    await db.delete('dept_tasks', where: 'camp_id = ?', whereArgs: [campId]);
  }

  Future<void> saveEquipmentUse(CampEquipmentUse u) async {
    final db = await database;
    await db.insert('camp_equipment_use', {
      'camp_id': u.campId,
      'equipment_id': u.equipmentId,
      'qty': u.qty,
      'actual_qty': u.actualQty,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteEquipmentUse(String campId, String equipmentId) async {
    final db = await database;
    await db.delete('camp_equipment_use',
        where: 'camp_id = ? AND equipment_id = ?', whereArgs: [campId, equipmentId]);
  }

  Future<void> saveTask(DeptTask t) async {
    final db = await database;
    await db.insert('dept_tasks', {
      'id': t.id,
      'camp_id': t.campId,
      'dept': t.dept.name,
      'title': t.title,
      'note': t.note,
      'status': t.status.name,
      'updated_at': t.updatedAt.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteTask(String id) async {
    final db = await database;
    await db.delete('dept_tasks', where: 'id = ?', whereArgs: [id]);
  }

  // ฟังก์ชันบันทึกข้อมูลปฏิทินลง Database
  Future<void> saveCalendarEvent(CalendarEvent e) async {
    final db = await database;
    await db.insert('calendar_events', {
      'id': e.id,
      'title': e.title,
      'description': e.description,
      'date': e.date.toIso8601String(),
      'target_dept': e.targetDept?.name,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ฟังก์ชันลบข้อมูลปฏิทินจาก Database
  Future<void> deleteCalendarEvent(String id) async {
    final db = await database;
    await db.delete('calendar_events', where: 'id = ?', whereArgs: [id]);
  }
}