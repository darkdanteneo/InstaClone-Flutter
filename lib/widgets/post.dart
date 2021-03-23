import 'dart:async';

import 'package:animator/animator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:MySocial/models/user.dart';
import 'package:MySocial/pages/activity_feed.dart';
import 'package:MySocial/pages/comments.dart';
import 'package:MySocial/pages/home.dart';
import 'package:MySocial/widgets/custom_image.dart';
import 'package:MySocial/widgets/progress.dart';

class Post extends StatefulWidget {
  final String ownerId, postId, username, location, caption, mediaUrl;
  final dynamic likes;
  Post({
    this.username,
    this.location,
    this.mediaUrl,
    this.postId,
    this.caption,
    this.likes,
    this.ownerId,
  });
  factory Post.fromDocument(DocumentSnapshot doc) {
    return Post(
      ownerId: doc['ownerId'],
      postId: doc['postId'],
      username: doc['username'],
      location: doc['location'],
      mediaUrl: doc['mediaUrl'],
      caption: doc['caption'],
      likes: doc['likes'],
    );
  }
  int getLikesCount(likes) {
    if (likes == null) return 0;
    int likesCount = 0;
    likes.values.forEach((val) {
      if (val == true) likesCount++;
    });
    return likesCount;
  }

  @override
  _PostState createState() => _PostState(
        postId: this.postId,
        username: this.username,
        ownerId: this.ownerId,
        mediaUrl: this.mediaUrl,
        location: this.location,
        caption: this.caption,
        likes: this.likes,
        likesCount: getLikesCount(this.likes),
      );
}

class _PostState extends State<Post> {
  final String ownerId, postId, username, location, caption, mediaUrl;
  final String currentUserId = currentUser?.id;
  Map likes;
  int likesCount;
  bool isLiked;
  bool showHeart = false;
  _PostState(
      {this.username,
      this.location,
      this.mediaUrl,
      this.postId,
      this.caption,
      this.likes,
      this.ownerId,
      this.likesCount});
  buildPostHeader() {
    return FutureBuilder(
      future: usersRef.doc(ownerId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return circularProgress();
        User user = User.fromDocument(snapshot.data);
        return ListTile(
          visualDensity: VisualDensity.compact,
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(user.photoUrl),
            backgroundColor: Colors.orange[700],
          ),
          title: Text(
            user.username,
            style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'RocknRoll'),
          ),
          onTap: () => showProfile(context, profileId: ownerId),
          subtitle: Text((location == null) ? location : "Image"),
          trailing: ownerId == currentUserId
              ? IconButton(
                  onPressed: () => handleDeletePost(context),
                  icon: Icon(Icons.more_vert),
                )
              : Text(""),
        );
      },
    );
  }

  handleDeletePost(BuildContext parentContext) {
    return showDialog(
        context: parentContext,
        builder: (context) {
          return SimpleDialog(
            title: Text("Remove this post..?!"),
            children: <Widget>[
              SimpleDialogOption(
                child: Text(
                  "Delete",
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => Home()));
                  deletePost();
                },
              ),
              SimpleDialogOption(
                child: Text(
                  "cancel",
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          );
        });
  }

  deletePost() async {
    // delete post itself
    postsRef.doc(ownerId).collection("usersPosts").doc(postId).get().then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    // delete img from database
    storageRef.child("post_$postId.jpg").delete();
    // delete activity feed
    QuerySnapshot activityFeedSnapshot =
        await activityFeedRef.doc(ownerId).collection("feedItems").where("postId", isEqualTo: postId).get();
    activityFeedSnapshot.docs.forEach((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    // delete comments
    QuerySnapshot commentsSnapshot = await commentsRef.doc(postId).collection("comment").get();
    commentsSnapshot.docs.forEach((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    followersRef.doc(currentUser.id).collection('userFollowers').get().then((docs) => docs.docs.forEach((doc) =>
        (timelineRef.doc(doc.id).collection('timelinePosts').doc(postId).get().then((doc) => doc.reference.delete()))));
  }

  addLikeToActivityFeed() {
    if (currentUserId != ownerId) {
      activityFeedRef.doc(ownerId).collection('feedItems').doc(postId).set({
        'type': 'like',
        'username': currentUser.username,
        'userId': currentUser.id,
        'userProfileImg': currentUser.photoUrl,
        'postId': postId,
        'mediaUrl': mediaUrl,
        'timestamp': timeStamp,
      });
    }
  }

  removeLikeFromFeed() {
    if (currentUserId != ownerId) {
      activityFeedRef.doc(ownerId).collection('feedItems').doc(postId).get().then((doc) {
        if (doc.exists) doc.reference.delete();
      });
    }
  }

  handleLikePost() {
    bool _isLiked = likes[currentUserId] == true;
    if (_isLiked) {
      postsRef.doc(ownerId).collection('usersPosts').doc(postId).update({'likes.$currentUserId': false});
      removeLikeFromFeed();
      setState(() {
        likesCount -= 1;
        isLiked = false;
        likes[currentUserId] = false;
      });
    } else if (!_isLiked) {
      postsRef.doc(ownerId).collection('usersPosts').doc(postId).update({'likes.$currentUserId': true});
      addLikeToActivityFeed();
      setState(() {
        likesCount += 1;
        isLiked = true;
        likes[currentUserId] = true;
        showHeart = true;
      });
      Timer(Duration(milliseconds: 500), () {
        setState(() {
          showHeart = false;
        });
      });
    }
  }

  buildPostImage() {
    return GestureDetector(
      onDoubleTap: handleLikePost,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          cachedNetworkImage(mediaUrl),
          showHeart
              ? Animator(
                  duration: Duration(milliseconds: 300),
                  tween: Tween(begin: .8, end: 1.6),
                  curve: Curves.elasticOut,
                  cycles: 0,
                  builder: (context, anim, child) => Transform.scale(
                    scale: anim.value,
                    child: Icon(
                      Icons.favorite,
                      size: 120.0,
                      color: Colors.red,
                    ),
                  ),
                )
              : Text(""),
        ],
      ),
    );
  }

  showComments(BuildContext context, {String postId, String ownerId, String mediaUrl}) {
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return Comments(
        postId: postId,
        postOwnerId: ownerId,
        mediaUrl: mediaUrl,
      );
    }));
  }

  buildPostFooter() {
    return Column(
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(top: 40, left: 20),
            ),
            GestureDetector(
              onTap: handleLikePost,
              child: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                size: 28,
                color: Colors.pink,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(right: 20),
            ),
            GestureDetector(
              onTap: () => showComments(
                context,
                postId: postId,
                ownerId: ownerId,
                mediaUrl: mediaUrl,
              ),
              child: Icon(
                Icons.chat,
                size: 28,
                color: Colors.blue[900],
              ),
            ),
          ],
        ),
        Row(
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 20),
              child: Text(
                '$likesCount likes',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        Padding(
          padding: EdgeInsets.all(3),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    isLiked = (likes[currentUserId] == true);
    return Padding(
      child: Container(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            buildPostHeader(),
            buildPostImage(),
            buildPostFooter(),
          ],
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 5,
              blurRadius: 7,
              offset: Offset(0, 3), // changes position of shadow
            ),
          ],
        ),
      ),
      padding: EdgeInsets.all(6),
    );
  }
}
