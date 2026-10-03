
class DefenseUnit {
  int row,col,type;double hp,clock;
  DefenseUnit(this.row,this.col,this.type):hp=type==2?300:100,clock=type==0?8:0;
  Map<String,dynamic> toJson()=>{'r':row,'c':col,'type':type,'hp':hp,'clock':clock};
}
class LaneEnemy {
  int row,type;double x,hp;
  LaneEnemy(this.row,this.type):x=6.2,hp=[100.0,200.0,60.0][type];
  double get speed=>[0.16,0.12,0.24][type];double get damage=>[20.0,20.0,15.0][type];
  Map<String,dynamic> toJson()=>{'r':row,'type':type,'x':x,'hp':hp};
}
class LaneBullet {int row;double x;LaneBullet(this.row,this.x);Map<String,dynamic> toJson()=>{'r':row,'x':x};}
class EnergyDrop {int row,col;double expires;EnergyDrop(this.row,this.col,this.expires);Map<String,dynamic> toJson()=>{'r':row,'c':col,'expires':expires};}
class LaneDefense {
  final int level;double time=0,nextWave=12,nextRain=10;int energy=100,wave=0,kills=0;String? result;
  final List<DefenseUnit> units=[];final List<LaneEnemy> enemies=[];final List<LaneBullet> bullets=[];final List<EnergyDrop> drops=[];
  final List<Map<String,dynamic>> scheduled=[];final List<double> cooldowns=[0,0,0];final List<bool> safety=[true,true,true];
  static const costs=[50,75,50];
  LaneDefense([this.level=0]);
  bool plant(int row,int col,int type){if(result!=null||row<0||row>2||col<0||col>4||type<0||type>2||cooldowns[type]>time||energy<costs[type]||units.any((u)=>u.row==row&&u.col==col))return false;energy-=costs[type];cooldowns[type]=time+5;units.add(DefenseUnit(row,col,type));return true;}
  bool remove(int row,int col){if(result!=null)return false;final count=units.length;units.removeWhere((u)=>u.row==row&&u.col==col);return count!=units.length;}
  int collect(){if(result!=null)return 0;final value=drops.where((d)=>d.expires>time).length*25;energy+=value;drops.clear();return value;}
  void _wave(){wave++;final kinds=level==0?[0,0,0]:level==1?[0,0,0,1]:[0,0,1,2,2];for(int i=0;i<kinds.length;i++){scheduled.add({'at':time+i*2,'row':(wave+i-1)%3,'type':kinds[i]});}nextWave+=12;}
  void tick(double dt){if(result!=null||dt<=0)return;time+=dt;
    if(time>=nextWave&&wave<5)_wave();
    while(time>=nextRain){drops.add(EnergyDrop(-1,-1,time+10));nextRain+=10;}
    final ready=scheduled.where((s)=>(s['at'] as num)<=time).toList();for(final s in ready){enemies.add(LaneEnemy(s['row'] as int,s['type'] as int));scheduled.remove(s);}
    drops.removeWhere((d)=>d.expires<=time);
    for(final u in units){u.clock-=dt;if(u.type==0&&u.clock<=0){drops.add(EnergyDrop(u.row,u.col,time+10));u.clock+=8;}else if(u.type==1&&u.clock<=0&&enemies.any((e)=>e.row==u.row&&e.x>=u.col+0.4)){bullets.add(LaneBullet(u.row,u.col+0.45));u.clock=1;}}
    final spent=<LaneBullet>{};for(final b in bullets){final old=b.x;b.x+=1.8*dt;final targets=enemies.where((e)=>e.row==b.row&&e.hp>0&&e.x>=old-0.12&&e.x<=b.x+0.12).toList()..sort((a,c)=>a.x.compareTo(c.x));if(targets.isNotEmpty){targets.first.hp-=20;spent.add(b);}}
    bullets.removeWhere((b)=>spent.contains(b)||b.x>6.4);
    kills+=enemies.where((e)=>e.hp<=0).length;enemies.removeWhere((e)=>e.hp<=0);
    for(final e in enemies){final blockers=units.where((u)=>u.row==e.row&&u.hp>0&&u.col+0.35<=e.x+0.001).toList()..sort((a,b)=>b.col.compareTo(a.col));if(blockers.isNotEmpty){final u=blockers.first;final stop=u.col+0.35;if(e.x-e.speed*dt<=stop){e.x=stop;u.hp-=e.damage*dt;}else{e.x-=e.speed*dt;}}else{e.x-=e.speed*dt;}}
    units.removeWhere((u)=>u.hp<=0);
    for(int row=0;row<3;row++){if(enemies.any((e)=>e.row==row&&e.x<=0)){if(safety[row]){safety[row]=false;kills+=enemies.where((e)=>e.row==row).length;enemies.removeWhere((e)=>e.row==row);}else{result='防线失守';return;}}}
    if(wave==5&&scheduled.isEmpty&&enemies.isEmpty)result='守线成功';
  }
  Map<String,dynamic> toJson()=>{'version':1,'level':level,'time':time,'nextWave':nextWave,'nextRain':nextRain,'energy':energy,'wave':wave,'kills':kills,'result':result,'units':units.map((u)=>u.toJson()).toList(),'enemies':enemies.map((e)=>e.toJson()).toList(),'bullets':bullets.map((b)=>b.toJson()).toList(),'drops':drops.map((d)=>d.toJson()).toList(),'scheduled':scheduled,'cooldowns':cooldowns,'safety':safety};
  static LaneDefense? fromJson(Map<String,dynamic> j){try{
    if(j['version']!=1)return null;final level=j['level'] as int;if(level<0||level>2)return null;final g=LaneDefense(level);g.time=(j['time'] as num).toDouble();g.nextWave=(j['nextWave'] as num).toDouble();g.nextRain=(j['nextRain'] as num).toDouble();g.energy=j['energy'] as int;g.wave=j['wave'] as int;g.kills=j['kills'] as int;g.result=j['result'] as String?;
    if(!g.time.isFinite||g.time<0||g.energy<0||g.wave<0||g.wave>5||!g.nextWave.isFinite||!g.nextRain.isFinite)return null;
    for(final item in j['units'] as List){final m=item as Map;final r=m['r'] as int,c=m['c'] as int,t=m['type'] as int;if(r<0||r>2||c<0||c>4||t<0||t>2||g.units.any((u)=>u.row==r&&u.col==c))return null;final u=DefenseUnit(r,c,t)..hp=(m['hp'] as num).toDouble()..clock=(m['clock'] as num).toDouble();if(!u.hp.isFinite||u.hp<=0||u.hp>(t==2?300:100)||!u.clock.isFinite)return null;g.units.add(u);}
    for(final item in j['enemies'] as List){final m=item as Map;final r=m['r'] as int,t=m['type'] as int;if(r<0||r>2||t<0||t>2)return null;final e=LaneEnemy(r,t)..x=(m['x'] as num).toDouble()..hp=(m['hp'] as num).toDouble();if(!e.x.isFinite||(e.x<0&&g.result!='防线失守')||e.x>6.3||!e.hp.isFinite||e.hp<=0)return null;g.enemies.add(e);}
    for(final item in j['bullets'] as List){final m=item as Map;final b=LaneBullet(m['r'] as int,(m['x'] as num).toDouble());if(b.row<0||b.row>2||!b.x.isFinite||b.x<0||b.x>6.4)return null;g.bullets.add(b);}
    for(final item in j['drops'] as List){final m=item as Map;final d=EnergyDrop(m['r'] as int,m['c'] as int,(m['expires'] as num).toDouble());if(!d.expires.isFinite||d.expires<g.time||d.row< -1||d.row>2||d.col< -1||d.col>4)return null;g.drops.add(d);}
    g.scheduled.addAll((j['scheduled'] as List).map((s)=>Map<String,dynamic>.from(s as Map)));for(final s in g.scheduled){if(s['at'] is! num||!(s['at'] as num).toDouble().isFinite||s['row'] is! int||s['type'] is! int||(s['row'] as int)<0||(s['row'] as int)>2||(s['type'] as int)<0||(s['type'] as int)>2)return null;}
    final cds=List<num>.from(j['cooldowns'] as List),safe=List<bool>.from(j['safety'] as List);if(cds.length!=3||safe.length!=3||cds.any((c)=>!c.toDouble().isFinite))return null;for(int i=0;i<3;i++){g.cooldowns[i]=cds[i].toDouble();g.safety[i]=safe[i];}return g;
  }catch(_){return null;}}
}
