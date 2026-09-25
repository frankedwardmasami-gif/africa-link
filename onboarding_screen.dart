import 'package:flutter/material.dart';
import '../repositories/profile_repository.dart';
import '../models/profile_model.dart';
import '../services/supabase_service.dart';

class OnboardingScreen extends StatefulWidget{const OnboardingScreen({super.key});@override State<OnboardingScreen> createState()=>_S();}
class _S extends State<OnboardingScreen>{
 final name=TextEditingController(),user=TextEditingController(),cit=TextEditingController(),country=TextEditingController(),skills=TextEditingController();
 Future<void> save() async{
  final id=SupabaseService.client.auth.currentUser!.id;
  await ProfileRepository().upsert(ProfileModel(id:id,fullName:name.text,username:user.text,citizenship:cit.text,currentCountry:country.text,skills:skills.text.split(',').map((x)=>x.trim()).where((x)=>x.isNotEmpty).toList()));
  if(mounted)Navigator.pushReplacementNamed(context,'/home');
 }
 Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('Welcome to AFRICA LINK')),body:ListView(padding:const EdgeInsets.all(20),children:[
  const Text('Tell Africa who you are',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold)),
  TextField(controller:name,decoration:const InputDecoration(labelText:'Full name')),
  TextField(controller:user,decoration:const InputDecoration(labelText:'Username')),
  TextField(controller:cit,decoration:const InputDecoration(labelText:'African citizenship')),
  TextField(controller:country,decoration:const InputDecoration(labelText:'Current country')),
  TextField(controller:skills,decoration:const InputDecoration(labelText:'Skills (comma separated)')),
  const SizedBox(height:20),FilledButton(onPressed:save,child:const Text('Continue'))]));
}
