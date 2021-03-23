import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:MySocial/models/user.dart';
import 'package:MySocial/pages/search.dart';
import 'package:MySocial/widgets/header.dart';
import 'package:MySocial/widgets/post.dart';
import 'package:MySocial/widgets/progress.dart';
import 'home.dart';

class Timeline extends StatefulWidget {
  final User currentUser;
  Timeline({this.currentUser});
  @override
  _TimelineState createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {
  List<Post> posts;
  List<String> followingList = [];
  getTimeline() async {
    QuerySnapshot snapshot = await timelineRef
        .doc(widget.currentUser.id)
        .collection("timelinePosts")
        .orderBy("timeStamp", descending: true)
        .get();
    List<Post> posts = snapshot.docs.map((doc) => Post.fromDocument(doc)).toList();
    setState(() {
      this.posts = posts;
    });
  }

  buildTimeline() {
    if (posts == null) {
      return circularProgress();
    } else if (posts.isEmpty) {
      return buildUsersToFollow();
    } else
      return ListView(children: posts, padding: EdgeInsets.all(6));
  }

  buildUsersToFollow() {
    return StreamBuilder(
        stream: usersRef.orderBy('timeStamp', descending: false).limit(30).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return circularProgress();
          }
          List<UserResult> userResults = [];
          snapshot.data.docs.forEach((doc) {
            User user = User.fromDocument(doc);
            final bool isAuth = widget.currentUser.id == user.id;
            final bool isFollowingUser = followingList.contains(user.id);
            if (isAuth || isFollowingUser)
              return;
            else {
              UserResult userResult = UserResult(user);
              userResults.add(userResult);
            }
          });
          return Container(
            color: Theme.of(context).primaryColor.withOpacity(.2),
            child: Column(
              children: <Widget>[
                Container(
                  padding: EdgeInsets.all(10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        Icons.person_add,
                        color: Theme.of(context).accentColor,
                        size: 30,
                      ),
                      SizedBox(width: 10.0),
                      Text(
                        "Users To Follow",
                        style: TextStyle(
                          fontSize: 30.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: userResults,
                ),
              ],
            ),
          );
        });
  }

  getFollowingUsers() async {
    QuerySnapshot snapshot = await followingRef.doc(currentUser.id).collection('userFollowers').get();
    setState(() {
      followingList = snapshot.docs.map((doc) => doc.id).toList();
    });
  }

  @override
  void initState() {
    getTimeline();
    getFollowingUsers();
    super.initState();
  }

  @override
  Widget build(context) {
    return Scaffold(
      appBar: header(context, isTimeLine: true),
      body: RefreshIndicator(child: buildTimeline(), onRefresh: () => getTimeline()),
    );
  }
}
