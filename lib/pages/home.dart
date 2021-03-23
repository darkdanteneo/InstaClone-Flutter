import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:MySocial/models/user.dart';
import 'package:MySocial/pages/create_account.dart';
import 'package:MySocial/pages/activity_feed.dart';
import 'package:MySocial/pages/profile.dart';
import 'package:MySocial/pages/search.dart';
import 'package:MySocial/pages/timeline.dart';
import 'package:MySocial/pages/upload.dart';
import 'package:google_sign_in/google_sign_in.dart';

GoogleSignIn googleSignIn = GoogleSignIn();
final usersRef = FirebaseFirestore.instance.collection('users');
final postsRef = FirebaseFirestore.instance.collection('posts');
final commentsRef = FirebaseFirestore.instance.collection('comments');
final activityFeedRef = FirebaseFirestore.instance.collection('feed');
final followersRef = FirebaseFirestore.instance.collection('followers');
final followingRef = FirebaseFirestore.instance.collection('following');
final timelineRef = FirebaseFirestore.instance.collection('timeline');
final Reference storageRef = FirebaseStorage.instance.ref();
final DateTime timeStamp = DateTime.now();
User currentUser;

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool isAuth = false;
  PageController pageController;
  int pageIndex = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  onTap(int pageIndex) {
    pageController.animateToPage(
      pageIndex,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
    );
  }

  onPageChanged(int pageIndex) {
    setState(() {
      this.pageIndex = pageIndex;
    });
  }

  login() {
    googleSignIn.signIn();
  } //sign in and sign out functions

  logout() {
    googleSignIn.signOut();
  }

  handleSignIn(GoogleSignInAccount account) async {
    if (account != null) {
      await createUserInFireStore();
      setState(() {
        isAuth = true;
      });
      configurePushNotifications();
    } else {
      setState(() {
        isAuth = false;
      });
    }
  }

  configurePushNotifications() {
    final GoogleSignInAccount user = googleSignIn.currentUser;
    if (Platform.isIOS) getIosPermissions();

    _firebaseMessaging.getToken().then((token) {
      // print("Firebase Messaging Token: $token\n");
      usersRef.doc(user.id).update({"androidNotificationToken": token});
    });

    _firebaseMessaging.configure(
      // onLaunch: (Map<String, dynamic> message) async {},
      // onResume: (Map<String, dynamic> message) async {},
      onMessage: (Map<String, dynamic> message) async {
        //print("on message: $message\n");
        final String recipientId = message['data']['recipient'];
        final String body = message['notification']['body'];
        if (recipientId == user.id) {
          //print("Notification shown!");
          SnackBar snackbar = SnackBar(
              content: Text(
            body,
            overflow: TextOverflow.ellipsis,
          ));
          _scaffoldKey.currentState.showSnackBar(snackbar);
        }
        print("Notification NOT shown");
      },
    );
  }

  getIosPermissions() {
    _firebaseMessaging.requestNotificationPermissions(IosNotificationSettings(
      alert: true,
      badge: true,
      sound: true,
    ));
    _firebaseMessaging.onIosSettingsRegistered.listen((settings) {
      //print("settings registered : $settings");
    });
  }

  createUserInFireStore() async {
    // check if the user is on our database
    final GoogleSignInAccount user = googleSignIn.currentUser;
    DocumentSnapshot doc = await usersRef.doc(user.id).get();
    // if not create new user
    if (!doc.exists) {
      final username = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreateAccount(),
        ),
      );
      usersRef.doc(user.id).set({
        "id": user.id,
        "username": username,
        "photoURL": user.photoUrl,
        "displayName": user.displayName,
        "email": user.email,
        "bio": "",
        "timeStamp": timeStamp,
      });
      //add user to his own followers
      followersRef.doc(user.id).collection('userFollowers').doc(user.id).set({});
      doc = await usersRef.doc(user.id).get();
    }
    currentUser = User.fromDocument(doc);
    // print(currentUser.email);
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  Scaffold buildAuthScreen() {
    return Scaffold(
      key: _scaffoldKey,
      body: PageView(
        children: <Widget>[
          Timeline(currentUser: currentUser),
          ActivityFeed(),
          Upload(currentUser: currentUser),
          Search(currentId: currentUser?.id),
          Profile(
            profileId: currentUser?.id,
            currentId: currentUser?.id,
          ),
        ],
        controller: pageController,
        onPageChanged: onPageChanged,
        physics: NeverScrollableScrollPhysics(),
      ),
      bottomNavigationBar: CupertinoTabBar(
        activeColor: Theme.of(context).accentColor,
        currentIndex: pageIndex,
        onTap: onTap,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.android_outlined)),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_active)),
          BottomNavigationBarItem(
              icon: Icon(
            Icons.photo_camera,
            size: 35.0,
          )),
          BottomNavigationBarItem(icon: Icon(Icons.search)),
          BottomNavigationBarItem(icon: Icon(Icons.account_box)),
        ],
      ),
    );
  }

  Scaffold buildUnAuthScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Theme.of(context).accentColor,
              Theme.of(context).primaryColorLight,
            ],
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              'Instagram!',
              style: TextStyle(
                fontFamily: 'Signatra',
                fontSize: 90.0,
                color: Colors.white,
              ),
            ), //title
            GestureDetector(
              onTap: login,
              child: Image.asset(
                'assets/images/google_signin_button.png',
                height: 50.0,
                width: 350.0,
              ),
            ), // i was able to use flat button also ?google sign in
          ],
        ),
      ),
    );
  }

  Future<void> initializeDefault() async {
    FirebaseApp app = await Firebase.initializeApp();
    assert(app != null);
    print('Initialized default app $app');
  }

  @override
  void initState() {
    // recognizeing loging in and out
    googleSignIn.onCurrentUserChanged.listen((account) {
      handleSignIn(account);
    }, onError: (err) {
      print(err);
    });
    googleSignIn.signInSilently(suppressErrors: false).then((account) {
      handleSignIn(account);
    }).catchError((err) {
      print(err);
    });
    pageController = PageController(); //can change initital page
    //followersRef.document(currentUser.id).collection('userFollowers').document(currentUser.id).setData({});

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    initializeDefault();
    return isAuth ? buildAuthScreen() : buildUnAuthScreen();
    /*return FutureBuilder(
      future: Firebase.initializeApp(),
      builder: (context, snapshot) {
        // Check for errors
        if (snapshot.hasError) {
          return Text("Error");
        }

        // Once complete, show your application
        if (snapshot.connectionState == ConnectionState.done) {
          return isAuth ? buildAuthScreen() : buildUnAuthScreen();
        }

        // Otherwise, show something whilst waiting for initialization to complete
        return Text("Loading");
      },
    );*/
  }
}
