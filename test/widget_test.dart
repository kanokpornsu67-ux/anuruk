import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:anuruk_app/main.dart';
import 'package:anuruk_app/state/app_state.dart';
import 'package:anuruk_app/models/models.dart';

void main() {
  testWidgets('หน้าแรกสาธารณะแสดงชื่อชมรมและรายการค่าย', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState()..seed(),
        child: const GreenClubApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ชมรมอนุรักษ์'), findsOneWidget);
    expect(find.text('ค่ายและกิจกรรมล่าสุด'), findsOneWidget);
    expect(find.text('ค่ายพบเพื่อนเดินป่า ครั้งที่ 23'), findsOneWidget);
  });

  test('R1 - กรรมการสร้างค่ายใหม่แล้วข้อมูลถูกบันทึก', () {
    final app = AppState()..seed();
    final before = app.camps.length;

    final camp = app.createCamp(
      name: 'ค่ายทดสอบ ครั้งที่ 1',
      start: DateTime(2026, 12, 1),
      end: DateTime(2026, 12, 3),
      placeId: app.places.first.id,
      participantTarget: 60,
    );

    expect(app.camps.length, before + 1);
    expect(app.camp(camp.id)?.name, 'ค่ายทดสอบ ครั้งที่ 1');
    expect(app.camp(camp.id)?.participantTarget, 60);
  });

  test('การจัดการอุปกรณ์อิสระรายค่าย', () {
    final app = AppState()..seed();
    final camp = app.camps.first;

    app.addEquipmentUse(camp.id, 'เต็นท์โดม', 'ที่พัก', 10, 'หลัง');
    expect(app.equipmentOf(camp.id).length, 1);
    expect(app.equipmentOf(camp.id).first.qty, 10);
  });

  test('R3 + R4 - ฝ่ายอัปเดตงาน แล้ว Dashboard เห็นความพร้อมล่าสุด', () {
    final app = AppState()..seed();
    final camp = app.camps.first;

    app.addTask(camp.id, Department.medical, 'เตรียมยาสามัญประจำบ้าน');
    final task = app.tasksOf(camp.id, dept: Department.medical).last;

    final before = app.readiness(camp.id, Department.medical);
    app.updateTask(task.id, status: TaskStatus.done);
    final after = app.readiness(camp.id, Department.medical);

    expect(task.status, TaskStatus.done);
    expect(after, greaterThan(before));
  });

  test('R5 - ปิดค่ายแล้วข้อมูลถูกเก็บเป็นประวัติ', () {
    final app = AppState()..seed();
    final camp = app.camps.first;

    app.closeCamp(
      camp.id,
      CampSummary(
        text: 'สรุปกิจกรรมทดสอบ',
        lessons: 'ควรจองรถล่วงหน้า',
        actualParticipants: 112,
        photos: ['ภาพหมู่'],
      ),
    );

    expect(app.camp(camp.id)?.status, CampStatus.finished);
    expect(app.finishedCamps.any((c) => c.id == camp.id), true);
    expect(app.camp(camp.id)?.summary?.actualParticipants, 112);
  });

  test('สิทธิ์ - สมาชิกฝ่ายแก้ได้เฉพาะงานฝ่ายตัวเอง', () {
    final app = AppState()..seed();
    expect(app.login('nichapat', AppState.clubPassword), null);
    expect(app.canEdit(Department.welfare), true);
    expect(app.canEdit(Department.medical), false);

    app.logout();
    expect(app.login('porramet', AppState.clubPassword), null);
    expect(app.canEdit(Department.medical), true); // กรรมการแก้ได้ทุกฝ่าย
  });
}