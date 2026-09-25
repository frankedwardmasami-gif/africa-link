import 'package:flutter/material.dart';
import '../services/module_service.dart';
import 'chat_screen.dart';

class ModuleDetail extends StatefulWidget {
  final String module; final Map<String,dynamic> item;
  const ModuleDetail({super.key,required this.module,required this.item});
  @override State<ModuleDetail> createState()=>_ModuleDetailState();
}
class _ModuleDetailState extends State<ModuleDetail>{
  final api=ModuleService(); bool busy=false, active=false; List<Map<String,dynamic>> extra=[]; Map<String,dynamic>? application;
  String get id=>widget.item['id'].toString();
  @override void initState(){super.initState();_load();}
  Future<void> _load() async {try{
    if(widget.module=='communities'){active=await api.isMember('community_members','community_id',id);extra=await api.communityPosts(id);}
    if(widget.module=='events') active=await api.isMember('event_registrations','event_id',id);
    if(widget.module=='projects'){active=await api.isMember('project_members','project_id',id);extra=await api.projectSkills(id);}
    if(widget.module=='courses'){active=await api.isEnrolled(id);extra=await api.lessons(id);}
    if(widget.module=='funding_opportunities') application=await api.myFundingApplication(id);
  }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Load failed: $e')));}finally{if(mounted)setState((){});}}
  Future<void> _action() async {setState(()=>busy=true);try{
    if(widget.module=='communities') await api.toggleCommunity(id,active);
    else if(widget.module=='events') await api.toggleEvent(id,active);
    else if(widget.module=='projects') await api.joinProject(id,active);
    else if(widget.module=='courses') await api.enrollCourse(id);
    else if(widget.module=='funding_opportunities') await _applyFunding();
    else if(widget.module=='businesses') await _inquiry();
    await _load();
  }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Action failed: $e')));}finally{if(mounted)setState(()=>busy=false);}}
  Future<void> _applyFunding() async {final c=TextEditingController(text:application?['statement']??'');final ok=await showDialog<bool>(context:context,builder:(_)=>AlertDialog(title:const Text('Funding application'),content:TextField(controller:c,maxLines:5,decoration:const InputDecoration(labelText:'Statement')),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(context,c.text.trim().isNotEmpty),child:const Text('Submit'))]));if(ok==true)await api.applyFunding(id,c.text);}
  Future<void> _inquiry() async {final c=TextEditingController();final ok=await showDialog<bool>(context:context,builder:(_)=>AlertDialog(title:const Text('Business inquiry'),content:TextField(controller:c,maxLines:5,decoration:const InputDecoration(labelText:'Message')),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(context,c.text.trim().isNotEmpty),child:const Text('Send'))]));if(ok==true)await api.createInquiry(id,c.text);}
  Future<void> _communityPost() async {final c=TextEditingController();final ok=await showDialog<bool>(context:context,builder:(_)=>AlertDialog(title:const Text('New community post'),content:TextField(controller:c,maxLines:5,decoration:const InputDecoration(hintText:'Share something with the community')),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(context,c.text.trim().isNotEmpty),child:const Text('Post'))]));if(ok==true){await api.addCommunityPost(id,c.text);await _load();}}
  @override Widget build(BuildContext c){final x=widget.item;final title='${x['name']??x['title']??'Item'}';final date=x['starts_at'];return Scaffold(appBar:AppBar(title:Text(title)),body:ListView(padding:const EdgeInsets.all(16),children:[
    Text(title,style:Theme.of(c).textTheme.headlineSmall),const SizedBox(height:10),Text('${x['description']??''}'),
    if(x['country']!=null&&'${x['country']}'.isNotEmpty)ListTile(leading:const Icon(Icons.public),title:Text('${x['country']}')),
    if(date!=null)ListTile(leading:const Icon(Icons.schedule),title:Text('Starts: $date')),
    if(x['level']!=null)ListTile(leading:const Icon(Icons.school),title:Text('Level: ${x['level']}')),
    if(x['status']!=null)ListTile(leading:const Icon(Icons.info_outline),title:Text('Status: ${x['status']}')),
    if(widget.module=='businesses' && x['verified']==true)const ListTile(leading:Icon(Icons.verified),title:Text('Verified business')),
    const SizedBox(height:8),
    if(widget.module=='funding_opportunities'&&application!=null)Card(child:ListTile(title:const Text('My application'),subtitle:Text('Status: ${application!['status']}'))),
    if(['communities','events','projects','courses'].contains(widget.module))FilledButton.icon(onPressed:busy?null:_action,icon:const Icon(Icons.touch_app),label:Text(widget.module=='courses'?(active?'Enrolled':'Enroll'):active?'Leave':'Join')),
    if(widget.module=='funding_opportunities')FilledButton.icon(onPressed:busy?null:_action,icon:const Icon(Icons.send),label:Text(application==null?'Apply':'Update application')),
    if(widget.module=='businesses')FilledButton.icon(onPressed:busy?null:_action,icon:const Icon(Icons.mail_outline),label:const Text('Send inquiry')),
    if(widget.module=='communities'&&active)...[TextButton.icon(onPressed:_communityPost,icon:const Icon(Icons.post_add),label:const Text('Create community post')),TextButton.icon(onPressed:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>CommunityMembers(communityId:id))),icon:const Icon(Icons.groups),label:const Text('View members')),TextButton.icon(onPressed:()async{final cid=await api.getOrCreateCommunityConversation(id);if(mounted)Navigator.push(c,MaterialPageRoute(builder:(_)=>ChatScreen(conversationId:cid)));},icon:const Icon(Icons.chat),label:const Text('Community chat'))],
    if(widget.module=='communities'&&extra.isNotEmpty)...[const Divider(),const Text('Community posts',style:TextStyle(fontWeight:FontWeight.bold)),...extra.map((p)=>ListTile(title:Text('${p['body']??''}'),subtitle:Text('${p['profiles']?['full_name']??'Member'}')))],
    if(widget.module=='courses'&&extra.isNotEmpty)...[const Divider(),const Text('Lessons',style:TextStyle(fontWeight:FontWeight.bold)),...extra.map((l)=>LessonTile(lesson:l,api:api))],
    if(widget.module=='projects'&&extra.isNotEmpty)...[const Divider(),const Text('Skills needed',style:TextStyle(fontWeight:FontWeight.bold)),...extra.map((s)=>ListTile(leading:const Icon(Icons.build),title:Text('${s['skill']??''}')))],
  ]));}
}
class LessonTile extends StatefulWidget{final Map<String,dynamic> lesson;final ModuleService api;const LessonTile({super.key,required this.lesson,required this.api});@override State<LessonTile> createState()=>_LessonTileState();}
class _LessonTileState extends State<LessonTile>{bool done=false;@override void initState(){super.initState();_load();}Future<void>_load()async{done=await widget.api.lessonCompleted(widget.lesson['id'].toString());if(mounted)setState((){});}Future<void>_toggle(bool v)async{await widget.api.setLessonProgress(widget.lesson['id'].toString(),v);setState(()=>done=v);}Widget build(BuildContext c)=>CheckboxListTile(value:done,onChanged:widget.api.db.auth.currentUser==null?null:(v)=>_toggle(v??false),title:Text('${widget.lesson['position']??''}. ${widget.lesson['title']??'Lesson'}'),subtitle:Text('${widget.lesson['content']??''}'));}
class CommunityMembers extends StatelessWidget{final String communityId;const CommunityMembers({super.key,required this.communityId});@override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('Members')),body:FutureBuilder(future:ModuleService().members(communityId),builder:(c,s){if(s.hasError)return Center(child:Text('${s.error}'));if(!s.hasData)return const Center(child:CircularProgressIndicator());return ListView(children:s.data!.map<Widget>((m){final p=m['profiles'];return ListTile(leading:const CircleAvatar(child:Icon(Icons.person)),title:Text('${p?['full_name']??'Member'}'),subtitle:Text('@${p?['username']??''}'));}).toList());}));}
