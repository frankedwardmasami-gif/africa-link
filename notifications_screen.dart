import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/supabase_service.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});
  @override Widget build(BuildContext c){
    final id=SupabaseService.client.auth.currentUser!.id;
    return Scaffold(appBar:AppBar(title:const Text('Notifications')),body:StreamBuilder(stream:NotificationService().stream(id),builder:(c,s){
      if(s.hasError)return Center(child:Text('${s.error}'));
      final rows=s.data??[];
      if(rows.isEmpty)return const Center(child:Text('No notifications yet.'));
      return ListView.builder(itemCount:rows.length,itemBuilder:(c,i){
        final n=rows[i];
        return ListTile(
          tileColor:n['read']==true?null:Theme.of(c).colorScheme.primaryContainer,
          leading:Icon(n['read']==true?Icons.notifications_none:Icons.notifications_active),
          title:Text('${n['title']??'Notification'}'),
          subtitle:Text('${n['body']??''}'),
          onTap:()async{await NotificationService().markRead(n['id'] as String);},
        );
      });
    }));
  }
}
