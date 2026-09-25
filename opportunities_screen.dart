import 'package:flutter/material.dart';
import '../repositories/opportunity_repository.dart';
class OpportunitiesScreen extends StatelessWidget{const OpportunitiesScreen({super.key});@override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('Opportunities')),body:FutureBuilder(future:OpportunityRepository().list(),builder:(c,s){if(!s.hasData)return const Center(child:CircularProgressIndicator());return ListView(children:s.data!.map((o)=>ListTile(title:Text(o['title']??''),subtitle:Text(o['type']??''))).toList());}));}}
