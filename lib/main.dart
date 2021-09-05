import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'pages/login.dart';
import 'pages/rank.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(GustusApp());
}

class GustusApp extends StatelessWidget {
  GustusApp({Key? key}) : super(key: key);
  final UserState userState = UserState();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<UserState>(
      create: (context) => UserState(),
      child: MaterialApp(
        title: 'Navigation with Routes',
        initialRoute: '/',
        routes: {
          '/': (_) => const LoginPage(),
          '/rank': (_) => const RankListPage(),
          '/rank_item': (_) => const RankItemsPage(
                rankId: '',
                rankName: '',
                order: [],
              ),
        },
      ),
    );
  }
}
