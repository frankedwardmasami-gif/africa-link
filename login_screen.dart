import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState()=>_LoginScreenState();
}
class _LoginScreenState extends State<LoginScreen> {
  final email=TextEditingController(), password=TextEditingController();
  bool loading=false;
  Future<void> submit() async {
    setState(()=>loading=true);
    try { await AuthService().signIn(email.text.trim(), password.text);
      if(mounted) Navigator.of(context).pushReplacementNamed('/home');
    } catch(e) { if(mounted) ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content:Text(e.toString()))); }
    finally { if(mounted)setState(()=>loading=false); }
  }
  @override Widget build(BuildContext c)=>Scaffold(
    appBar:AppBar(title:const Text('AFRICA LINK')),
    body:Padding(padding:const EdgeInsets.all(20),child:Column(
      children:[
        TextField(controller:email, decoration:const InputDecoration(labelText:'Email')),
        TextField(controller:password, obscureText:true, decoration:const InputDecoration(labelText:'Password')),
        const SizedBox(height:16),
        FilledButton(onPressed:loading?null:submit, child:Text(loading?'Signing in…':'Sign in')),
        TextButton(onPressed:()=>Navigator.pushNamed(c,'/register'),child:const Text('Create account')),
      ])));
}
