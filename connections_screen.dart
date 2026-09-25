import 'package:flutter/material.dart';
import '../services/advanced_social_service.dart';
import 'public_profile_screen.dart';

class ConnectionsScreen extends StatefulWidget { const ConnectionsScreen({super.key}); @override State<ConnectionsScreen> createState()=>_S(); }
class _S extends State<ConnectionsScreen>{ final api=AdvancedSocialService(); bool loading=true; List<Map<String,dynamic>> conns=[], requests=[];
 @override void initState(){super.initState();_load();}
 Future<void> _load() async {setState(()=>loading=true);try{conns=await api.connections();requests=await api.incomingRequests();}finally{if(mounted)setState(()=>loading=false);}}
 Widget person(Map<String,dynamic> p,{bool request=false})=>ListTile(leading:const CircleAvatar(child:Icon(Icons.person)),title:Text('${p['full_name']??''}'),subtitle:Text('@${p['username']??''}'),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>PublicProfileScreen(profile:p))),trailing:request?Row(mainAxisSize:MainAxisSize.min,children:[IconButton(icon:const Icon(Icons.close),onPressed:()async{await api.respond(p['id'],false);_load();}),IconButton(icon:const Icon(Icons.check),onPressed:()async{await api.respond(p['id'],true);_load();})]):IconButton(icon:const Icon(Icons.person_remove_outlined),onPressed:()async{await api.removeConnection(p['id']);_load();}));
 @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('Connections')),body:loading?const Center(child:CircularProgressIndicator()):RefreshIndicator(onRefresh:_load,child:ListView(padding:const EdgeInsets.all(12),children:[if(requests.isNotEmpty)...[const Text('Requests',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),...requests.map((p)=>person(p,request:true)),const Divider()],const Text('My connections',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),if(conns.isEmpty)const Padding(padding:EdgeInsets.all(20),child:Text('No connections yet.')),...conns.map(person)]));
}
