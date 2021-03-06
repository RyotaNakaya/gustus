import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'common/header.dart';
import 'common/validator.dart';
import 'login.dart';

class RankItemsPage extends StatefulWidget {
  final String rankId;
  final String rankName;
  const RankItemsPage({Key? key, required this.rankId, required this.rankName})
      : super(key: key);

  @override
  _RankItemsPageState createState() => _RankItemsPageState();
}

class _RankItemsPageState extends State<RankItemsPage> {
  @override
  Widget build(BuildContext context) {
    final UserState userState = Provider.of<UserState>(context);
    final User user = userState.user!;
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    final rankId = args['rankId'];
    final rankName = args['rankName'];
    var itemLength = 1;

    return Scaffold(
      appBar: const Header(text: 'ランキングアイテム一覧'),
      body: Column(
        children: <Widget>[
          Text(rankName),
          Expanded(
              child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('ranks')
                      .where('user_id', isEqualTo: user.uid)
                      .snapshots(),
                  builder: (context, rankSnapshot) {
                    if (rankSnapshot.hasData) {
                      List order = [];
                      final List<DocumentSnapshot> documents =
                          rankSnapshot.data!.docs;
                      // rankId の一致するドキュメントを抽出するのだけど、これもうちょいどうにかならのか
                      for (final doc in documents) {
                        if (doc.id == rankId) {
                          order = doc['rank_item_order'];
                          break;
                        }
                      }
                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('rank_items')
                            .where('rank_id', isEqualTo: rankId)
                            .where('user_id', isEqualTo: user.uid)
                            .snapshots(),
                        builder: (context, itemSnapshot) {
                          // データが取得できた場合
                          if (itemSnapshot.hasData) {
                            final List<DocumentSnapshot> documents =
                                itemSnapshot.data!.docs;
                            itemLength = documents.length;
                            // 取得した一覧を元にリスト表示
                            // FIXME: ダブルループしてしまうのが微妙
                            final list = <Widget>[];
                            order.asMap().forEach((idx, id) {
                              for (final document in documents) {
                                if (id == document.id) {
                                  list.add(RankItemCard(
                                      id: document.id,
                                      rankId: rankId,
                                      name: document['name'],
                                      order: idx));
                                }
                              }
                            });
                            return ListView(children: list);
                          }
                          // データが読込中の場合
                          return const Center(
                            child: Text('読込中...'),
                          );
                        },
                      );
                    }
                    // データが読込中の場合
                    return const Center(
                      child: Text('読込中...'),
                    );
                  })),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context)
              .push(MaterialPageRoute(builder: (context) {
            return RankItemAddPage(rankId: rankId, itemLength: itemLength);
          }));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class RankItemAddPage extends StatefulWidget {
  final String rankId;
  final int itemLength;
  const RankItemAddPage({
    Key? key,
    required this.rankId,
    required this.itemLength,
  }) : super(key: key);

  @override
  _RankItemAddPageState createState() => _RankItemAddPageState();
}

class _RankItemAddPageState extends State<RankItemAddPage> {
  String _name = '';
  int _targetOrder = 0;
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final UserState userState = Provider.of<UserState>(context);
    final User user = userState.user!;

    return Scaffold(
      appBar: const Header(text: 'ランキングアイテム追加'),
      body: Container(
        padding: const EdgeInsets.all(64),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextFormField(
                decoration: const InputDecoration(labelText: 'Enter name'),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) {
                  final res = NameValidator.validate(value!);
                  if (res != '') {
                    return res;
                  }
                },
                onChanged: (String value) {
                  setState(() {
                    _name = value;
                  });
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Enter order'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) {
                  final max = widget.itemLength + 1;
                  if (value!.isNotEmpty) {
                    if (int.parse(value) > max) {
                      return '最下位は$max位です。';
                    }
                    if (int.parse(value) == 0) {
                      return '0 は入力できません。';
                    }
                  }
                },
                onChanged: (String value) {
                  setState(() {
                    _targetOrder = int.parse(value);
                  });
                },
              ),
              const SizedBox(height: 8),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    primary: Colors.blue,
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final date = DateTime.now().toLocal().toIso8601String();
                      final firestoreInstance = FirebaseFirestore.instance;
                      firestoreInstance.runTransaction((transaction) async {
                        // add rank item
                        final ref =
                            firestoreInstance.collection('rank_items').doc();
                        transaction.set(ref, {
                          'rank_id': widget.rankId,
                          'name': _name,
                          'user_id': user.uid,
                          'date': date
                        });

                        // update rank item order
                        final ranks = await firestoreInstance
                            .collection('ranks')
                            .doc(widget.rankId)
                            .get();
                        final order = ranks['rank_item_order'];
                        if (_targetOrder == 0) {
                          order.add(ref.id);
                        } else {
                          // array index が 0 start なのでマイナス1する
                          order.insert(_targetOrder - 1, ref.id);
                        }
                        transaction.update(
                            firestoreInstance
                                .collection('ranks')
                                .doc(widget.rankId),
                            {'rank_item_order': order});
                      });
                      // 1つ前の画面に戻る
                      Navigator.of(context).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('入力値が不正です。')),
                      );
                    }
                  },
                  child: const Text('ランキングアイテム追加',
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
      ),
    );
  }
}

class RankItemCard extends StatefulWidget {
  final String id;
  final String rankId;
  final String name;
  final int order;
  const RankItemCard(
      {Key? key,
      required this.id,
      required this.rankId,
      required this.name,
      required this.order})
      : super(key: key);

  @override
  _RankItemCardState createState() => _RankItemCardState();
}

class _RankItemCardState extends State<RankItemCard> {
  String _name = '';
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  void _changeIsEditing(bool e) => setState(() => _isEditing = e);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Text('${widget.order + 1}位'),
        title: _isEditing
            ? Form(
                key: _formKey,
                child: TextFormField(
                  initialValue: widget.name,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (value) {
                    final res = NameValidator.validate(value!);
                    if (res != '') {
                      return res;
                    }
                  },
                  onChanged: (String value) {
                    setState(() {
                      _name = value;
                    });
                  },
                ))
            : Text(widget.name),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isEditing)
              IconButton(
                icon: const Icon(Icons.check),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    if (_name != widget.name) {
                      await FirebaseFirestore.instance
                          .collection('rank_items')
                          .doc(widget.id)
                          .update({'name': _name});
                    }
                    _changeIsEditing(false);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('入力値が不正です。')),
                    );
                  }
                },
              )
            else
              IconButton(
                icon: const Icon(Icons.create),
                onPressed: () {
                  _changeIsEditing(true);
                },
              ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                final firestoreInstance = FirebaseFirestore.instance;
                final ranks = await firestoreInstance
                    .collection('ranks')
                    .doc(widget.rankId)
                    .get();
                final order = ranks['rank_item_order'];
                // 削除対象の item_id を order から削除する
                for (var i = 0; i < order.length; i++) {
                  if (order[i] == widget.id) {
                    order.removeAt(i);
                  }
                }
                firestoreInstance
                    .collection('ranks')
                    .doc(widget.rankId)
                    .update({'rank_item_order': order});
                firestoreInstance
                    .collection('rank_items')
                    .doc(widget.id)
                    .delete();
              },
            ),
          ],
        ),
      ),
    );
  }
}
