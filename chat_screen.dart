import 'package:flutter/material.dart';
import '../repositories/messaging_repository.dart';
class ChatScreen extends StatefulWidget{final String conversationId;const ChatScreen({super.key,required this.conversationId});@override State<ChatScreen> createState()=>_S();}
class _S extends State<ChatScreen>{final b=TextEditingController();Future<void> send()async{if(b.text.trim().isEmpty)return;await MessagingRepository().send(widget.conversationId,b.text.trim());b.clear();}
 Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('Chat')),body:Column(children:[Expanded(child:StreamBuilder(stream:MessagingRepository().messages(widget.conversationId),builder:(c,s)=>ListView(children:(s.data??[]).map((m)=>ListTile(title:Text(m.body),subtitle:Text(m.senderId))).toList()))),Row(children:[Expanded(child:TextField(controller:b)),IconButton(onPressed:send,icon:const Icon(Icons.send))])]));
}
