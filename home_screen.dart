import 'package:flutter/material.dart';
import 'comments_screen.dart';
import '../repositories/social_repository.dart';
import '../models/post_model.dart';

class HomeScreen extends StatelessWidget{
 const HomeScreen({super.key});
 Future<void> _comment(BuildContext context,String postId) async {
  final c=TextEditingController();
  final ok=await showDialog<bool>(context:context,builder:(_)=>AlertDialog(title:const Text('Comment'),content:TextField(controller:c,maxLines:3,decoration:const InputDecoration(hintText:'Write a comment')),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(context,c.text.trim().isNotEmpty),child:const Text('Post'))]));
  if(ok==true) await SocialRepository().addComment(postId,c.text);
 }
 @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('AFRICA LINK'),actions:[
  IconButton(onPressed:()=>Navigator.pushNamed(c,'/search'),icon:const Icon(Icons.search)),IconButton(onPressed:()=>Navigator.pushNamed(c,'/notifications'),icon:const Icon(Icons.notifications_none)),IconButton(onPressed:()=>Navigator.pushNamed(c,'/safety'),icon:const Icon(Icons.shield_outlined)),IconButton(onPressed:()=>Navigator.pushNamed(c,'/profile'),icon:const Icon(Icons.person_outline))]),
  body:StreamBuilder(stream:SocialRepository().feedStream(),builder:(c,s){
   if(s.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator());
   final posts=s.data??const <PostModel>[];
   if(posts.isEmpty)return const Center(child:Text('No posts yet. Be the first to connect Africa.'));
   return ListView.builder(itemCount:posts.length,itemBuilder:(c,i){final p=posts[i];return _PostCard(post:p,onComment:()=>_comment(c,p.id));});}),
  floatingActionButton:FloatingActionButton(onPressed:()=>Navigator.pushNamed(c,'/create'),child:const Icon(Icons.add)));
}
class _PostCard extends StatefulWidget{final PostModel post;final VoidCallback onComment;const _PostCard({required this.post,required this.onComment});@override State<_PostCard> createState()=>_PostCardState();}
class _PostCardState extends State<_PostCard>{bool liked=false;bool busy=false;
 Future<void> toggle()async{if(busy)return;setState(()=>busy=true);try{await SocialRepository().toggleLike(widget.post.id,liked);setState(()=>liked=!liked);}finally{if(mounted)setState(()=>busy=false);}}
 @override Widget build(BuildContext c)=>Card(margin:const EdgeInsets.fromLTRB(8,8,8,2),child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(widget.post.authorName,style:const TextStyle(fontWeight:FontWeight.bold)),const SizedBox(height:6),Text(widget.post.body),Row(children:[IconButton(onPressed:busy?null:toggle,icon:Icon(liked?Icons.favorite:Icons.favorite_border)),Text('${widget.post.likeCount+(liked?1:0)}'),IconButton(onPressed:widget.onComment,icon:const Icon(Icons.comment_outlined)),Text('${widget.post.commentCount}')])])));
}
