import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(GustusApp());
}

class GustusApp extends StatelessWidget {
  GustusApp() : super();
  final UserState userState = UserState();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<UserState>(
      create: (context) => UserState(),
      child: MaterialApp(
        title: 'Gustus App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: LoginPage(),
      ),
    );
  }
}

class UserState extends ChangeNotifier {
  User? user;

  void setUser(User newUser) {
    user = newUser;
    notifyListeners();
  }
}

class RankListPage extends StatefulWidget {
  @override
  _RankListPageState createState() => _RankListPageState();
}

class _RankListPageState extends State<RankListPage> {
  @override
  Widget build(BuildContext context) {
    final UserState userState = Provider.of<UserState>(context);
    final User user = userState.user!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ランキング一覧'),
      ),
      body: Column(
        children: <Widget>[
          Text(user.email.toString()),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // TODO: 自分が登録したデータだけ fetch する
              stream: FirebaseFirestore.instance
                  .collection('ranks')
                  .orderBy('date')
                  .snapshots(),
              builder: (context, snapshot) {
                // データが取得できた場合
                if (snapshot.hasData) {
                  final List<DocumentSnapshot> documents = snapshot.data!.docs;
                  // 取得した一覧を元にリスト表示
                  return ListView(
                    children: documents.map((document) {
                      return InkWell(
                        // ランクコンテンツページに遷移
                        onTap: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (context) {
                              return RankContentsPage(
                                  document.id, document['name']);
                            }),
                          );
                        },
                        child: Card(
                          child: ListTile(
                            title: Text(document['name']),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection('ranks')
                                    .doc(document.id)
                                    .delete();
                              },
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }
                // データが読込中の場合
                return const Center(
                  child: Text('読込中...'),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context)
              .push(MaterialPageRoute(builder: (context) {
            return RankAddPage();
          }));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class RankAddPage extends StatefulWidget {
  @override
  _RankAddPageState createState() => _RankAddPageState();
}

class _RankAddPageState extends State<RankAddPage> {
  String _name = '';

  Widget build(BuildContext context) {
    final UserState userState = Provider.of<UserState>(context);
    final User user = userState.user!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ランキング追加'),
      ),
      body: Container(
        padding: const EdgeInsets.all(64),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              _name,
              style: const TextStyle(color: Colors.blue),
            ),
            const SizedBox(height: 8),
            TextField(
              onChanged: (String value) {
                setState(() {
                  _name = value;
                });
              },
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary: Colors.blue,
                ),
                onPressed: () async {
                  final date = DateTime.now().toLocal().toIso8601String();
                  final email = user.email;
                  await FirebaseFirestore.instance
                      .collection('ranks') // コレクションID指定
                      .doc() // ドキュメントID自動生成
                      .set({'name': _name, 'email': email, 'date': date});
                  // 1つ前の画面に戻る
                  Navigator.of(context).pop();
                },
                child: const Text('ランキング追加',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('キャンセル'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RankContentsPage extends StatefulWidget {
  final String rankId;
  final String rankName;
  // RankContentsPage({Key? rankId}) : super(key: rankId);
  RankContentsPage(this.rankId, this.rankName);

  @override
  _RankContentsPageState createState() => _RankContentsPageState();
}

class _RankContentsPageState extends State<RankContentsPage> {
  Widget build(BuildContext context) {
    // final UserState userState = Provider.of<UserState>(context);
    // final User user = userState.user!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ランキングコンテンツ一覧'),
      ),
      body: Column(
        children: <Widget>[
          Text(widget.rankId),
          Text(widget.rankName),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // TODO: 自分が登録したデータだけ fetch する
              // TODO: rankId を元にランクコンテンツを取得する
              stream: FirebaseFirestore.instance
                  .collection('rank_contents')
                  .orderBy('date')
                  .snapshots(),
              builder: (context, snapshot) {
                // データが取得できた場合
                if (snapshot.hasData) {
                  final List<DocumentSnapshot> documents = snapshot.data!.docs;
                  // 取得した一覧を元にリスト表示
                  return ListView(
                    children: documents.map((document) {
                      return Card(
                        child: ListTile(
                          title: Text(document['name']),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('rank_contents')
                                  .doc(document.id)
                                  .delete();
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }
                // データが読込中の場合
                return const Center(
                  child: Text('読込中...'),
                );
              },
            ),
          ),
        ],
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () async {
      //     await Navigator.of(context)
      //         .push(MaterialPageRoute(builder: (context) {
      //       return RankAddPage();
      //     }));
      //   },
      //   child: const Icon(Icons.add),
      // ),
    );
  }
}

// ログイン画面用Widget
class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // メッセージ表示用
  String infoText = '';
  // 入力したメールアドレス・パスワード
  String email = '';
  String password = '';

  @override
  Widget build(BuildContext context) {
    final UserState userState = Provider.of<UserState>(context);
    return Scaffold(
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // メールアドレス入力
              TextFormField(
                decoration: const InputDecoration(labelText: 'メールアドレス'),
                onChanged: (String value) {
                  setState(() {
                    email = value;
                  });
                },
              ),
              // パスワード入力
              TextFormField(
                decoration: const InputDecoration(labelText: 'パスワード'),
                obscureText: true,
                onChanged: (String value) {
                  setState(() {
                    password = value;
                  });
                },
              ),
              Container(
                padding: const EdgeInsets.all(8),
                // メッセージ表示
                child: Text(infoText),
              ),
              Container(
                width: double.infinity,
                // ログイン登録ボタン
                child: ElevatedButton(
                  child: const Text('ログイン'),
                  onPressed: () async {
                    try {
                      // メール/パスワードでログイン
                      final FirebaseAuth auth = FirebaseAuth.instance;
                      final result = await auth.signInWithEmailAndPassword(
                        email: email,
                        password: password,
                      );
                      userState.setUser(result.user!);
                      // ログインに成功した場合
                      await Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) {
                          return RankListPage();
                        }),
                      );
                    } catch (e) {
                      // ログインに失敗した場合
                      setState(() {
                        infoText = 'ログインに失敗しました：${e.toString()}';
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                // ユーザー登録ボタン
                child: OutlinedButton(
                  child: const Text('ユーザー登録'),
                  onPressed: () async {
                    try {
                      // メール/パスワードでユーザー登録
                      final FirebaseAuth auth = FirebaseAuth.instance;
                      final result = await auth.createUserWithEmailAndPassword(
                        email: email,
                        password: password,
                      );
                      userState.setUser(result.user!);
                      // ユーザー登録に成功した場合
                      await Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) {
                          return RankListPage();
                        }),
                      );
                    } catch (e) {
                      // ユーザー登録に失敗した場合
                      setState(() {
                        infoText = '登録に失敗しました：${e.toString()}';
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
