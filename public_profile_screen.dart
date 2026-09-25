import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../services/connection_service.dart';
import '../repositories/messaging_repository.dart';
import 'chat_screen.dart';

class PublicProfileScreen extends StatefulWidget {
  final Map<String,dynamic> profile;
  const PublicProfileScreen({super.key, required this.profile});
  @override State<PublicProfileScreen> createState()=>_PublicProfileScreenState();
}
class _PublicProfileScreenState extends State<PublicProfileScreen>{
  String? status; bool busy=false;
  String get id=>'${widget.profile['id']}';
  @override void initState(){super.initState(); _load();}
  Future<void> _load() async { try { status=await ConnectionService().statusWith(id); } finally { if(mounted)setState((){}); } }
  Future<void> _connect() async { setState(()=>busy=true); try { await ConnectionService().connect(id); await _load(); } finally { if(mounted)setState(()=>busy=false); } }
  Future<void> _message() async { final cid=await MessagingRepository().startConversation(id); if(mounted)Navigator.push(context,MaterialPageRoute(builder:(_)=>ChatScreen(conversationId:cid))); }
  @override Widget build(BuildContext c){
    final p=widget.profile; final isSelf=id==SupabaseService.client.auth.currentUser?.id;
    final s=status?.split('|'); final state=s?.first; final incoming=s!=null && s.length>2 && s[2]==SupabaseService.client.auth.currentUser?.id;
    return Scaffold(appBar:AppBar(title:Text(p['full_name']??'Profile')),body:ListView(padding:const EdgeInsets.all(20),children:[
      const CircleAvatar(radius:42,child:Icon(Icons.person,size:42)), const SizedBox(height:12),
      Text('${p['full_name']??''}',style:Theme.of(c).textTheme.headlineSmall), Text('@${p['username']??''}'),
      if(p['verification_status']=='verified')const Padding(padding:EdgeInsets.only(top:6),child:Row(children:[Icon(Icons.verified,size:18),SizedBox(width:5),Text('Verified')])),
      const Divider(height:30),
      Text('African citizenship: ${p['african_citizenship']??'-'}'), Text('Current country: ${p['current_country']??'-'}'),
      const SizedBox(height:12), Text(p['bio']??''), const SizedBox(height:12),
      if((p['skills'] as List?)?.isNotEmpty??false) Text('Skills: ${(p['skills'] as List).join(', ')}'),
      if(!isSelf) ...[
        const SizedBox(height:20),
        Row(children:[Expanded(child:FilledButton.icon(onPressed:busy?null:(state==null?_connect:(state=='pending'&&incoming?null:state=='accepted'?null:_connect)),icon:Icon(state=='accepted'?Icons.check:Icons.person_add),label:Text(state=='accepted'?'Connected':state=='pending'?(incoming?'Request pending':'Request sent'):'Connect'))),const SizedBox(width:10),
        Expanded(child:OutlinedButton.icon(onPressed:_message,icon:const Icon(Icons.chat),label:const Text('Message')))]),
      ]
    ]));
  }
}
