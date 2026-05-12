import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'colors.dart';
import 'surveys_screens.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'extra_screens.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isLoggedIn = prefs.getInt('userId') != null && prefs.getInt('userId') != 0;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _navigateToProfile() {
    setState(() {
      _selectedIndex = 3;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    final List<Widget> pages = [
      EstanqueScreen(isLoggedIn: _isLoggedIn, onGoToProfile: _navigateToProfile),
      CreateSurveyScreen(isLoggedIn: _isLoggedIn, onGoToProfile: _navigateToProfile),
      AnalyticsScreen(isLoggedIn: _isLoggedIn, onGoToProfile: _navigateToProfile),
      ProfileScreen(onLoginSuccess: () {
        _checkLoginStatus();
      }),
    ];

    return Scaffold(
      backgroundColor: backgroundLight,
      body: Row(
        children: [
          if (isDesktop)
            Container(
              width: 280,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(right: BorderSide(color: borderGray)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: secondaryYellow,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.flutter_dash, color: primaryDeepNavy, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'RubberDuckSurveys',
                          style: TextStyle(
                            color: primaryDeepNavy,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildNavTile(Icons.ballot_outlined, "Feed", 0),
                  _buildNavTile(Icons.add_circle_outline, "Create", 1),
                  _buildNavTile(Icons.analytics_outlined, "Analytics", 2),
                  _buildNavTile(Icons.person_outline, "Profile", 3),
                  const Spacer(),
                  _buildNavTile(Icons.settings_outlined, "Settings", -1, onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                  }),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          Expanded(
            child: pages[_selectedIndex],
          ),
        ],
      ),
      bottomNavigationBar: isDesktop
          ? null
          : Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: primaryDeepNavy.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildBottomNavItem(Icons.ballot, "Feed", 0),
                      _buildBottomNavItem(Icons.add_circle, "Create", 1),
                      _buildBottomNavItem(Icons.analytics, "Analytics", 2),
                      _buildBottomNavItem(Icons.person, "Profile", 3),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildNavTile(IconData icon, String label, int index, {VoidCallback? onTap}) {
    final isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: onTap ?? () => _onItemTapped(index),
        leading: Icon(icon, color: isSelected ? tertiaryBlue : neutralGray),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? primaryDeepNavy : neutralGray,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        selected: isSelected,
        selectedTileColor: tertiaryBlue.withValues(alpha: 0.05),
      ),
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label, int index, {VoidCallback? onTap}) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: onTap ?? () => _onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? secondaryYellow : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isSelected ? primaryDeepNavy : neutralGray,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? primaryDeepNavy : neutralGray,
            ),
          ),
        ],
      ),
    );
  }
}
