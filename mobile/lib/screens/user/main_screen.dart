import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class MainScreen extends StatefulWidget {
  final Widget child;

  const MainScreen({Key? key, required this.child}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<NavigationItem> _items = [
    NavigationItem(
      route: '/home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Home',
    ),
    NavigationItem(
      route: '/bookings',
      icon: Icons.book_outlined,
      activeIcon: Icons.book,
      label: 'Bookings',
    ),
    NavigationItem(
      route: '/chats',
      icon: Icons.chat_outlined,
      activeIcon: Icons.chat,
      label: 'Chats',
    ),
    NavigationItem(
      route: '/payment',
      icon: Icons.payment_outlined,
      activeIcon: Icons.payment,
      label: 'Payment',
    ),
    NavigationItem(
      route: '/profile',
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    context.go(_items[index].route);
  }

  @override
  Widget build(BuildContext context) {
    // Update selected index based on current route
    final location = GoRouterState.of(context).matchedLocation;
    final newIndex = _items.indexWhere((item) => location.startsWith(item.route));
    if (newIndex != -1 && newIndex != _selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedIndex = newIndex;
          });
        }
      });
    }

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isSelected = _selectedIndex == index;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => _onItemTapped(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isSelected ? item.activeIcon : item.icon,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.6),
                            size: 22,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.label,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight:
                                  isSelected ? FontWeight.w600 : FontWeight.w400,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.6),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class NavigationItem {
  final String route;
  final IconData icon;
  final IconData activeIcon;
  final String label;

  NavigationItem({
    required this.route,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
