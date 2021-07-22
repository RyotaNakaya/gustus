import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart';

class RankListPage extends StatefulWidget {
  const RankListPage({Key? key}) : super(key: key);
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
              stream: FirebaseFirestore.instance
                  .collection('ranks')
                  .where('user_id', isEqualTo: user.uid)
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
                          Navigator.of(context).pushNamed('/rank_content',
                              arguments: {
                                'rankId': document.id,
                                'rankName': document['name']
                              });
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
            return const RankAddPage();
          }));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class RankAddPage extends StatefulWidget {
  const RankAddPage({Key? key}) : super(key: key);
  @override
  _RankAddPageState createState() => _RankAddPageState();
}

class _RankAddPageState extends State<RankAddPage> {
  String _name = '';

  @override
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
            SizedBox(
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
                      .set({'name': _name, 'user_id': user.uid, 'date': date});
                  // 1つ前の画面に戻る
                  Navigator.of(context).pop();
                },
                child: const Text('ランキング追加',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
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
  const RankContentsPage(
      {Key? key, required this.rankId, required this.rankName})
      : super(key: key);

  @override
  _RankContentsPageState createState() => _RankContentsPageState();
}

class _RankContentsPageState extends State<RankContentsPage> {
  @override
  Widget build(BuildContext context) {
    final UserState userState = Provider.of<UserState>(context);
    final User user = userState.user!;
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    final rankId = args['rankId'];
    final rankName = args['rankName'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('ランキングコンテンツ一覧'),
      ),
      body: Column(
        children: <Widget>[
          Text(rankName),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('rank_contents')
                  .where('rank_id', isEqualTo: rankId)
                  .where('user_id', isEqualTo: user.uid)
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context)
              .push(MaterialPageRoute(builder: (context) {
            return RankContentAddPage(rankId: rankId);
          }));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class RankContentAddPage extends StatefulWidget {
  final String rankId;
  const RankContentAddPage({
    Key? key,
    required this.rankId,
  }) : super(key: key);

  @override
  _RankContentAddPageState createState() => _RankContentAddPageState();
}

class _RankContentAddPageState extends State<RankContentAddPage> {
  String _name = '';

  @override
  Widget build(BuildContext context) {
    final UserState userState = Provider.of<UserState>(context);
    final User user = userState.user!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ランキングコンテンツ追加'),
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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary: Colors.blue,
                ),
                onPressed: () async {
                  final date = DateTime.now().toLocal().toIso8601String();
                  await FirebaseFirestore.instance
                      .collection('rank_contents') // コレクションID指定
                      .doc() // ドキュメントID自動生成
                      .set({
                    'rank_id': widget.rankId,
                    'name': _name,
                    'user_id': user.uid,
                    'date': date
                  });
                  // 1つ前の画面に戻る
                  Navigator.of(context).pop();
                },
                child: const Text('ランキングコンテンツ追加',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
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
