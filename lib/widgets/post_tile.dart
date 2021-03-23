import 'package:flutter/material.dart';
import 'package:MySocial/widgets/custom_image.dart';
import 'package:MySocial/widgets/post.dart';
import 'package:MySocial/pages/post_screen.dart';

class PostTile extends StatelessWidget {
  final Post post;
  showPost(context) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => PostScreen(
                  userId: post.ownerId,
                  postId: post.postId,
                )));
  }

  PostTile(this.post);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: cachedNetworkImage(post.mediaUrl),
      onTap: () => showPost(context),
    );
  }
}
