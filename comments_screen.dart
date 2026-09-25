import 'package:flutter/material.dart';
import '../services/advanced_social_service.dart';

class CommentsScreen extends StatefulWidget { final String postId; const CommentsScreen({super.key,required this.postId}); @override State<CommentsScreen> createState()=>_S(); }
class _S extends State<CommentsScreen>{final api=AdvancedSocialService();final c=TextEditingController();List<Map<String,dynamic>> rows=[];bool loading=true;
 @override void dispose(){c.dispose();super.dispose();}
 @override void initState(){super.initState();_load();}
 Future<void> _load()async{rows=await api.comments(widget.postId);if(mounted)setState(()=>loading=false);}
 Future<void> _send()async{if(c.text.trim().isEmpty)return;await api.addComment(widget.postId,c.text);c.clear();await _load();}
 @override Widget build(BuildContext x)=>Scaffold(appBar:AppBar(title:const Text('Comments')),body:Column(children:[Expanded(child:loading?const Center(child:CircularProgressIndicator()):RefreshIndicator(onRefresh:_load,child:ListView.builder(itemCount:rows.length,itemBuilder:(c,i){final r=rows[i];return ListTile(leading:const CircleAvatar(child:Icon(Icons.person)),title:Text('${r['author_name']??'Member'}'),subtitle:Text('${r['body']??''}'),trailing:r['author_id']==api.uid?IconButton(icon:const Icon(Icons.delete_outline),onPressed:()async{await api.deleteComment(r['id']);_load();}):null);}))),SafeArea(child:Row(children:[Expanded(child:Padding(padding:const EdgeInsets.all(8),child:TextField(controller:c,decoration:const InputDecoration(hintText:'Write a comment...',border:OutlineInputBorder())))),IconButton(onPressed:_send,icon:const Icon(Icons.send))]))]));}
}
