import 'package:flutter/material.dart';
import '../services/module_service.dart';
import 'module_detail.dart';

class UnifiedModules extends StatelessWidget {
  const UnifiedModules({super.key});
  @override Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('Explore Africa')),
    body: GridView.count(crossAxisCount: 2, padding: const EdgeInsets.all(12), children: [
      _tile(c,'Communities','communities',Icons.groups), _tile(c,'Events','events',Icons.event),
      _tile(c,'Education','courses',Icons.school), _tile(c,'Business','businesses',Icons.store),
      _tile(c,'Funding','funding_opportunities',Icons.account_balance), _tile(c,'Projects','projects',Icons.engineering),
    ]));
  Widget _tile(BuildContext c,String t,String table,IconData i) => Card(child: InkWell(
    onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>ModuleList(title:t,table:table))),
    child: Column(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(i,size:38),const SizedBox(height:8),Text(t)])));
}
class ModuleList extends StatelessWidget {
  final String title, table; const ModuleList({super.key,required this.title,required this.table});
  @override Widget build(BuildContext c) => Scaffold(appBar:AppBar(title:Text(title)), body:
    FutureBuilder<List<Map<String,dynamic>>>(future:ModuleService().list(table),builder:(c,s){
      if(s.hasError)return Center(child:Padding(padding:const EdgeInsets.all(20),child:Text('Unable to load $title.\n${s.error}')));
      if(!s.hasData)return const Center(child:CircularProgressIndicator());
      if(s.data!.isEmpty)return Center(child:Text('No $title available yet.'));
      return RefreshIndicator(onRefresh:() async { /* FutureBuilder will be rebuilt by a new route; keep gesture safe. */ await ModuleService().list(table); },child:ListView.builder(itemCount:s.data!.length,itemBuilder:(c,i){final x=s.data![i];
        final subtitle = x['country'] ?? x['description'] ?? x['type'] ?? x['status'] ?? '';
        return Card(child:ListTile(title:Text('${x['name']??x['title']??'Item'}'),subtitle:Text('$subtitle'),trailing:const Icon(Icons.chevron_right),onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>ModuleDetail(module:table,item:x))));
      }));
    }));
}
