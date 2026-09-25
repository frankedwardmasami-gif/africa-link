import 'package:flutter/material.dart';
import '../repositories/social_repository.dart';
class CreatePostScreen extends StatefulWidget{const CreatePostScreen({super.key});@override State<CreatePostScreen> createState()=>_S();}
class _S extends State<CreatePostScreen>{final b=TextEditingController();bool busy=false;
 @override void dispose(){b.dispose();super.dispose();}
 Future<void> save()async{if(b.text.trim().isEmpty)return;setState(()=>busy=true);try{await SocialRepository().createPost(b.text.trim());if(mounted)Navigator.pop(context);}finally{if(mounted)setState(()=>busy=false);}}
 Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('Create post')),body:Padding(padding:const EdgeInsets.all(20),child:Column(children:[TextField(controller:b,maxLines:6,decoration:const InputDecoration(hintText:'Share with Africa…')),const SizedBox(height:12),FilledButton(onPressed:busy?null:save,child:const Text('Publish'))])));
}
