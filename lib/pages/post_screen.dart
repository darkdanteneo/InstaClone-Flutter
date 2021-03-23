import 'package:flutter/material.dart';
import 'package:MySocial/pages/home.dart';
import 'package:MySocial/widgets/header.dart';
import 'package:MySocial/widgets/post.dart';
import 'package:MySocial/widgets/progress.dart';

class PostScreen extends StatelessWidget {
  final String postId, userId;
  PostScreen({this.postId, this.userId});
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: postsRef.doc(userId).collection('usersPosts').doc(postId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return circularProgress();
        Post post = Post.fromDocument(snapshot.data);
        return Center(
          child: Scaffold(
            appBar: header(context, pageTitle: post.caption),
            body: ListView(
              children: <Widget>[
                Container(
                  child: post,
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
