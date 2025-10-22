import 'package:flutter/material.dart';
import 'package:message_ai/features/authentication/presentation/pages/sign_in_page.dart';
import 'package:message_ai/features/authentication/presentation/pages/sign_up_page.dart';

/// Main authentication page with tabs for Sign In and Sign Up
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MessageAI'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Sign In'),
            Tab(text: 'Sign Up'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          SignInPage(),
          SignUpPage(),
        ],
      ),
    );
  }
}
