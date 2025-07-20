

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme.dart';
import 'supabase/supabase_config.dart';
import 'services/auth_service.dart';
import 'services/service_provider_service.dart';
import 'pages/login_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/services_page.dart';
import 'pages/orders_page.dart';
import 'pages/finance_page.dart';
import 'pages/warehouse_page.dart';
import 'pages/complete_profile_page.dart';
import 'pages/add_service_page.dart';
import 'pages/branches_page.dart';
import 'pages/promotional_dashboard_page.dart';
import 'widgets/custom_sidebar.dart';
import 'utils/arabic_helpers.dart';

void main() async {
  
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await SupabaseConfig.initialize();
  } catch (e) {
    print('Failed to initialize Supabase: $e');
  }
  
  runApp(const ProviderScope(child: JeenaApp()));
}

class JeenaApp extends ConsumerWidget {
  const JeenaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'جينا - منصة مزودي الخدمات',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      locale: ArabicHelpers.arabicLocale,
      home: const AuthWrapper(),
      routes: {
        '/dashboard': (context) => const MainNavigator(),
        '/complete-profile': (context) => const CompleteProfilePage(),
        '/login': (context) => const LoginPage(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(currentUserProvider);
    
    return authState.when(
      data: (user) {
        if (user != null) {
          return const ProfileCheckWrapper();
        } else {
          return const LoginPage();
        }
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stackTrace) {
        print('Auth error: $error');
        return const LoginPage();
      },
    );
  }
}

class ProfileCheckWrapper extends StatefulWidget {
  const ProfileCheckWrapper({super.key});

  @override
  State<ProfileCheckWrapper> createState() => _ProfileCheckWrapperState();
}

class _ProfileCheckWrapperState extends State<ProfileCheckWrapper> {
  bool _isChecking = true;
  bool _hasCompletedProfile = false;

  @override
  void initState() {
    super.initState();
    _checkProfileCompletion();
  }

  Future<void> _checkProfileCompletion() async {
    final hasCompleted = await ServiceProviderService.hasCompletedProfile();
    setState(() {
      _hasCompletedProfile = hasCompleted;
      _isChecking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_hasCompletedProfile) {
      return const MainNavigator();
    } else {
      return const CompleteProfilePage();
    }
  }
}

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  String currentPage = 'dashboard';
  bool isSidebarOpen = false;

  void _onPageChanged(String page) {
    setState(() {
      currentPage = page;
      // Close mobile sidebar when navigating
      if (isSidebarOpen) {
        isSidebarOpen = false;
      }
    });
    
    // Close the drawer on mobile after navigation
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    if (!isDesktop && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    
    // Refresh the page data when navigating
    print('Navigating to page: $page');
  }

  Widget _buildPage() {
    switch (currentPage) {
      case 'dashboard':
        return DashboardPage(key: ValueKey('dashboard_$currentPage'));
      case 'services':
        return ServicesPage(key: ValueKey('services_$currentPage'));
      case 'orders':
        return OrdersPage(key: ValueKey('orders_$currentPage'));
      case 'inventory':
        return WarehousePage(key: ValueKey('inventory_$currentPage'));
      case 'finance':
        return FinancePage(key: ValueKey('finance_$currentPage'));
      case 'branches':
        return BranchesPage();
      case 'promotions':
        return PromotionalDashboardPage(key: ValueKey('promotions_$currentPage'));
      default:
        return DashboardPage(key: ValueKey('dashboard_$currentPage'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024; // Changed to 1024px for better responsive design
    
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: !isDesktop ? AppBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          title: Text(
            'جينا',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getPageTitle(),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ) : null,
        drawer: !isDesktop ? Drawer(
          child: CustomSidebar(
            currentPage: currentPage,
            onPageChanged: _onPageChanged,
          ),
        ) : null,
        body: Row(
          children: [
            // Sidebar - Always visible on desktop, drawer on mobile
            if (isDesktop)
              SizedBox(
                width: 300, // Increased width for better proportions
                child: CustomSidebar(
                  currentPage: currentPage,
                  onPageChanged: _onPageChanged,
                ),
              ),
            
            // Main content area
            Expanded(
              child: _buildPage(),
            ),
          ],
        ),
      ),
    );
  }

  String _getPageTitle() {
    switch (currentPage) {
      case 'dashboard':
        return 'لوحة التحكم';
      case 'services':
        return 'الخدمات';
      case 'orders':
        return 'الطلبات';
      case 'inventory':
        return 'المستودع';
      case 'finance':
        return 'الفواتير';
      case 'branches':
        return 'إدارة الفروع';
      case 'promotions':
        return 'العروض والترويجات';
      default:
        return 'لوحة التحكم';
    }
  }


}