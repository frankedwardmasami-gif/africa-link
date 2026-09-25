import 'supabase_service.dart';

class DiscoveryService {
  final db=SupabaseService.client;

  Future<List<Map<String,dynamic>>> search(String q) async {
    final s=q.trim();
    if(s.isEmpty)return [];
    final out=<Map<String,dynamic>>[];
    final searches=<String,List<String>>{
      'profiles':['full_name','username','african_citizenship','current_country'],
      'communities':['name','description','country'],
      'events':['title','description','country'],
      'courses':['title','description','level'],
      'businesses':['name','description','country'],
      'funding_opportunities':['title','description','type'],
      'projects':['title','description','country','status'],
    };
    for(final entry in searches.entries){
      try{
        final filter=entry.value.map((c)=>'$c.ilike.%$s%').join(',');
        final rows=await db.from(entry.key).select().or(filter).limit(12);
        for(final r in rows){out.add({...Map<String,dynamic>.from(r),'_type':entry.key});}
      }catch(_){ }
    }
    return out;
  }
}
