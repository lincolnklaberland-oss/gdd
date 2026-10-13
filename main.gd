extends Node2D
# Временные геометрические фигуры — заглушки, не новый дизайн персонажей.
const SPEED := 210.0
var player := Vector2(480,270)
var direction := Vector2.RIGHT
var hp := 5
var essence := 0
var kills := 0
var started := false
var dead := false
var attack_cd := 0.0
var attack_flash := 0.0
var hurt := 0.0
var enemies: Array[Dictionary] = []
var orbs: Array[Vector2] = []
var joy := Vector2.ZERO
var joy_origin := Vector2(88,445)
var joy_id := -1
var font: Font

func _ready():
	font = ThemeDB.fallback_font
	for i in range(5): spawn_enemy()
	set_process(true)

func spawn_enemy():
	var a = randf()*TAU
	var p = player + Vector2(cos(a),sin(a))*randf_range(380,520)
	enemies.append({"pos":p,"hp":2,"speed":randf_range(48,75),"kind":"goblin" if randf()<0.65 else "slime"})

func _process(delta):
	if started and not dead:
		attack_cd=maxf(0,attack_cd-delta)
		attack_flash=maxf(0,attack_flash-delta)
		hurt=maxf(0,hurt-delta)
		player += joy*SPEED*delta
		if joy.length()>0.1: direction=joy.normalized()
		for i in range(enemies.size()-1,-1,-1):
			var e=enemies[i]
			var ep:Vector2=e.pos
			var diff=player-ep
			if diff.length()>18: ep+=diff.normalized()*e.speed*delta
			e.pos=ep
			enemies[i]=e
			if diff.length()<22 and hurt<=0:
				hp-=1; hurt=0.8
				if hp<=0: hp=0; dead=true
		for i in range(orbs.size()-1,-1,-1):
			if player.distance_to(orbs[i])<27:
				essence+=1; orbs.remove_at(i)
		if enemies.size()<5 and randf()<delta*0.7: spawn_enemy()
	queue_redraw()

func _input(event):
	if event is InputEventScreenTouch:
		touch(event.position,event.pressed,event.index)
	elif event is InputEventScreenDrag and event.index==joy_id:
		update_joy(event.position)
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		touch(event.position,event.pressed,0)
	elif event is InputEventMouseMotion and joy_id==0 and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		update_joy(event.position)

func touch(pos:Vector2, pressed:bool, idx:int):
	if not pressed:
		if idx==joy_id: joy_id=-1; joy=Vector2.ZERO
		return
	if not started: started=true; return
	if dead:
		player=Vector2(480,270); hp=5; essence=0; kills=0; dead=false; enemies.clear(); orbs.clear()
		for i in range(5): spawn_enemy()
		return
	var size=get_viewport_rect().size
	if pos.x>size.x-150 and pos.y>size.y-150:
		attack()
	elif pos.x<size.x*0.48 and pos.y>size.y*0.48:
		joy_id=idx; joy_origin=Vector2(88,size.y-95); update_joy(pos)

func update_joy(pos:Vector2):
	var v=pos-joy_origin
	joy=v.normalized()*minf(v.length()/48.0,1.0)

func attack():
	if attack_cd>0: return
	attack_cd=0.38; attack_flash=0.2
	for i in range(enemies.size()-1,-1,-1):
		var e=enemies[i]
		var v:Vector2=e.pos-player
		if v.length()<76 and direction.dot(v.normalized())>0.2:
			e.hp-=1
			if e.hp<=0:
				orbs.append(e.pos); enemies.remove_at(i); kills+=1
			else: enemies[i]=e

func world_to_screen(p:Vector2,size:Vector2)->Vector2:
	return size*0.5+p-player

func _draw():
	var size=get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO,size),Color("#0a111c"))
	var tile=36
	for y in range(-tile,int(size.y)+tile,tile):
		for x in range(-tile,int(size.x)+tile,tile):
			var pos=Vector2(x+fposmod(-player.x,tile),y+fposmod(-player.y,tile))
			draw_rect(Rect2(pos,Vector2(34,34)),Color("#111b27") if (x/tile+y/tile)%4==0 else Color("#0e1722"))
	for orb in orbs:
		draw_rect(Rect2(world_to_screen(orb,size)-Vector2(4,4),Vector2(8,8)),Color("#e77aa5"))
	for e in enemies:
		var p=world_to_screen(e.pos,size)
		if e.kind=="goblin":
			draw_rect(Rect2(p+Vector2(-8,-7),Vector2(16,15)),Color("#55744c"))
			draw_rect(Rect2(p+Vector2(-7,-12),Vector2(14,8)),Color("#6e8854"))
			draw_rect(Rect2(p+Vector2(-5,-4),Vector2(3,3)),Color("#e9d59b"))
			draw_rect(Rect2(p+Vector2(2,-4),Vector2(3,3)),Color("#e9d59b"))
		else:
			draw_circle(p,11,Color("#6a9a9b"))
			draw_circle(p+Vector2(-4,-2),2,Color("#f5f1d7"))
			draw_circle(p+Vector2(4,-2),2,Color("#f5f1d7"))
	var c=size*0.5
	draw_rect(Rect2(c+Vector2(-8,-2),Vector2(16,18)),Color("#171923"))
	draw_rect(Rect2(c+Vector2(-6,-10),Vector2(12,12)),Color("#6d4938"))
	draw_rect(Rect2(c+Vector2(-11,2),Vector2(22,14)),Color("#24202b"))
	draw_line(c+direction*8,c+direction*29,Color("#b7b9c4"),4)
	if attack_flash>0: draw_arc(c,52,direction.angle()-0.9,direction.angle()+0.9,20,Color("#f0b7bd"),4)
	draw_rect(Rect2(12,12,210,78),Color(0.03,0.05,0.08,0.9))
	label("ГАУТЭР",Vector2(22,35),17,Color("#f0d8c3"))
	label("♥ ".repeat(hp)+"♡ ".repeat(5-hp),Vector2(22,60),18,Color("#e15c67"))
	label("Тёмная эссенция: %d"%essence,Vector2(22,82),13,Color("#d9b8c7"))
	label("Победы: %d"%kills,Vector2(22,104),13,Color("#bfc8d2"))
	var jc=Vector2(88,size.y-95)
	draw_circle(jc,44,Color(0.06,0.1,0.15,0.8)); draw_arc(jc,44,0,TAU,48,Color("#566273"),2)
	draw_circle(jc+joy*27,17,Color("#8293a6"))
	var ac=Vector2(size.x-88,size.y-95)
	draw_circle(ac,44,Color(0.15,0.07,0.11,0.85)); draw_arc(ac,44,0,TAU,48,Color("#9c5969"),2)
	label("⚔",ac+Vector2(-14,11),28,Color("#f3d9d5"))
	if not started: panel(size,"ФУАРЕНИР","Нажми экран, чтобы начать")
	elif dead: panel(size,"ГАУТЭР ПАЛ","Нажми экран для нового забега")

func label(t:String,p:Vector2,s:int,c:Color):
	draw_string(font,p,t,HORIZONTAL_ALIGNMENT_LEFT,-1,s,c)

func panel(size:Vector2,title:String,sub:String):
	var r=Rect2(size*0.5-Vector2(190,65),Vector2(380,130))
	draw_rect(r,Color(0.04,0.05,0.09,0.95)); draw_rect(r,Color("#7f4c65"),false,2)
	label(title,r.position+Vector2(26,47),26,Color("#ff9a9a"))
	label(sub,r.position+Vector2(26,83),16,Color("#eee4dd"))
