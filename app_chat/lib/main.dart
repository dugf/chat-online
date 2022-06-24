import 'package:app_chat/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());

  //Acessar um documento de uma coleção:

  // DocumentSnapshot snapshot = await FirebaseFirestore.instance
  //     .collection('mensagens')
  //     .doc('j0B1g9U3QpVaBY4JBZNT')
  //     .get();

  // print(snapshot.data());

  //Acessar varios documentos de uma coleção:
  // QuerySnapshot snapshot =
  //     await FirebaseFirestore.instance.collection('mensagens').get();
  // for (var d in snapshot.docs) {
  //   // print(d.data()); //documentos
  //   // print(d.id); //ID dos documentos
  //   d.reference.update(
  //       {'lido': false}); //atualização do documento adicionando o campo lido
  // }

  //ler coleções em tempo real
  // FirebaseFirestore.instance.collection('mensagens').snapshots().listen((dado) {
  //   for (var d in dado.docs) {
  //     print(d.data());
  //   }
  // });

  //ler um documento em tempo real
  // FirebaseFirestore.instance
  //     .collection('mensagens')
  //     .doc('2Z2mjtWtPR82OydnQXtO')
  //     .snapshots()
  //     .listen((dado) {
  //   print(dado.data());
  // });
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Chat Flutter',
        theme: ThemeData(
            primarySwatch: Colors.blue,
            iconTheme: const IconThemeData(color: Colors.blue)),
        home: const ChatScreen());
  }
}
