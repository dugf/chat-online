import 'package:app_chat/chat_message.dart';
import 'package:app_chat/text_composer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';

import 'dart:io';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  final GoogleSignIn googleSignIn = GoogleSignIn();
  User? _currentUser;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    FirebaseAuth.instance.authStateChanges().listen((user) {
      setState(() {
        _currentUser = user;
      });
    });
  }

  Future<User?> _getUser() async {
    if (_currentUser != null) return _currentUser;
    try {
      final GoogleSignInAccount? googleSignInAccount =
          await googleSignIn.signIn();
      final GoogleSignInAuthentication? googleSignInAuthentication =
          await googleSignInAccount?.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleSignInAuthentication?.idToken,
          accessToken: googleSignInAuthentication?.accessToken);

      final UserCredential authResult =
          await FirebaseAuth.instance.signInWithCredential(credential);

      final User? user = authResult.user;

      return user;
    } catch (error) {
      return null;
    }
  }

  void _sendMessage({String? text, XFile? imgFile}) async {
    final User? user = await _getUser();

    if (user == null) {
      _scaffoldMessengerKey.currentState!.showSnackBar(const SnackBar(
        content: Text("Não foi possível fazer login. Tente novamente!"),
        backgroundColor: Colors.red,
      ));
    }

    Map<String, dynamic> data = {
      'uid': user?.uid,
      'senderName': user?.displayName,
      'senderPhotoUrl': user?.photoURL,
      'time': Timestamp.now(),
    };

    if (imgFile != null) {
      firebase_storage.UploadTask task = firebase_storage
          .FirebaseStorage.instance
          .ref()
          .child(user!.uid + DateTime.now().millisecondsSinceEpoch.toString())
          .putFile(File(imgFile.path));

      setState(() {
        _isLoading = true;
      });

      firebase_storage.TaskSnapshot taskSnapshot =
          await task.whenComplete(() => imgFile);
      String url = await taskSnapshot.ref.getDownloadURL();
      data['imgUrl'] = url;

      setState(() {
        _isLoading = false;
      });
    }

    if (text != null) {
      data['text'] = text;
    }

    FirebaseFirestore.instance.collection('messages').add(data);
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_currentUser != null
              ? 'Olá, ${_currentUser?.displayName}'
              : 'Chat App'),
          centerTitle: true,
          elevation: 0,
          actions: [
            _currentUser != null
                ? IconButton(
                    icon: const Icon(Icons.exit_to_app),
                    onPressed: () {
                      FirebaseAuth.instance.signOut();
                      googleSignIn.signOut();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Você saiu com sucesso!"),
                        ),
                      );
                    })
                : Container()
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('messages')
                    .orderBy('time')
                    .snapshots(),
                builder: (context, snapshot) {
                  switch (snapshot.connectionState) {
                    case ConnectionState.none:
                    case ConnectionState.waiting:
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    default:
                      List<DocumentSnapshot<Map<String, dynamic>>> documents =
                          snapshot.data!.docs
                              .cast<DocumentSnapshot<Map<String, dynamic>>>()
                              .reversed
                              .toList();

                      return ListView.builder(
                        itemCount: documents.length,
                        reverse: true,
                        itemBuilder: (context, index) {
                          return ChatMessage(
                              documents[index].data() as Map<String, dynamic>,
                              documents[index]["uid"] == _currentUser?.uid);
                        },
                      );
                  }
                },
              ),
            ),
            _isLoading == true ? const LinearProgressIndicator() : Container(),
            TextComposer(sendMessage: _sendMessage),
          ],
        ),
      ),
    );
  }
}
