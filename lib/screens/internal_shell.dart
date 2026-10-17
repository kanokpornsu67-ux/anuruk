import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import 'camp_screens.dart';
import 'history_screen.dart';
import 'club_dashboard_screen.dart';
import 'calendar_screen.dart';
import 'login_screen.dart';


class InternalShell extends StatefulWidget {
  const InternalShell({super.key});

  @override
  State<InternalShell> createState() => _InternalShellState();
}

class _InternalShellState extends State<InternalShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
     final screens = [

      ClubDashboardScreen(),
      
      const CalendarScreen(), 

      CampListScreen(),

      CampHistoryScreen(),

      

    ];
   
    return Scaffold(
      appBar: AppBar(
        title: Text(app.currentDept == null ? 'ระบบชมรม' : 'Welcome, ${app.currentDept!.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'ออกจากระบบ',
            onPressed: () {
              app.logout();
              if (context.mounted) {
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => const LoginScreen()),
    (route) => false,
  );
              }
            },
          ),
        ],
      ),
      body: screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'แดชบอร์ด'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'ปฏิทิน'),
          NavigationDestination(icon: Icon(Icons.nature_outlined), selectedIcon: Icon(Icons.nature), label: 'จัดการค่าย'),
          NavigationDestination(icon: Icon(Icons.history), label: 'ประวัติค่าย'),
          
        ],
      ),
    );
  }
}