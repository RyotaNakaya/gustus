import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gustus/pages/login.dart';
import 'package:provider/provider.dart';

class Header extends StatelessWidget with PreferredSizeWidget {
  final String text;
  const Header({Key? key, this.text = ''}) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(text),
      actions: [
        PopupMenuButton(
          icon: const Icon(Icons.account_circle),
          itemBuilder: (BuildContext context) {
            return const [
              PopupMenuItem(
                child: Text('Sign out'),
                value: 0,
              )
            ];
          },
          onSelected: (result) {
            if (result == 0) {
              signOut(context);
            }
          },
        ),
      ],
    );
  }
}

Future<void> signOut(BuildContext context) async {
  final UserState userState = Provider.of<UserState>(context, listen: false);
  await FirebaseAuth.instance.signOut();
  userState.unsetUser();
  Navigator.of(context).pushNamed('/');
}
