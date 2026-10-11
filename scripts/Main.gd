extends Control
# واجهة اللعبة (تُبنى بالكود) مع دعم RTL

const S = {
 "title":["فخري مانجر 3D","Fakhri Manager 3D"],
 "tagline":["لعبة محاكاة مهنة مدرب كرة القدم","Football manager career simulator"],
 "new":["مسيرة جديدة","New Career"],"cont":["متابعة المسيرة المحفوظة","Continue saved career"],
 "lang":["English","العربية"],"coach_name":["اسم المدرب","Coach name"],"default_coach":["المدرب","Coach"],
 "pick_club":["اختر النادي","Choose your club"],"begin":["ابدأ المسيرة","Start career"],"back":["رجوع","Back"],
 "coach":["المدرب","Coach"],"season":["الموسم","Season"],"week":["الجولة","Round"],"budget":["الميزانية","Budget"],
 "next":["المباراة القادمة","Next match"],"rank":["الترتيب","Rank"],"play":["العب الجولة","Play round"],
 "mail":["البريد والعروض","Mail & offers"],"history":["سجل المدرب","Coach record"],"settings":["الإعدادات والحفظ","Settings & save"],
 "home":["الرئيسية","Home"],"squad":["الفريق","Squad"],"match":["المباراة","Match"],"table":["الدوري","League"],"market":["الانتقالات","Transfers"],
 "formation":["التشكيلة","Formation"],"tactic":["التكتيك","Tactic"],
 "balanced":["متوازن","Balanced"],"possession":["استحواذ","Possession"],"press":["ضغط عالٍ","High press"],"counter":["مرتدات","Counter"],"deep":["دفاع متأخر","Deep defence"],
 "gk":["حارس","GK"],"def":["مدافع","DEF"],"mid":["وسط","MID"],"att":["مهاجم","ATT"],
 "ovr":["تقييم","OVR"],"pot":["إمكانات","POT"],"age":["العمر","Age"],"fit":["لياقة","Fit"],"inj":["إصابة","Inj"],"weeks":["أسابيع","wks"],
 "value":["القيمة","Value"],"wage":["الراتب/أسبوع","Wage/wk"],"contract":["العقد (سنوات)","Contract (yrs)"],"goals":["أهداف","Goals"],"apps":["مشاركات","Apps"],
 "sell":["بيع اللاعب","Sell player"],"buy":["عرض","Offer"],"best":["الأفضل","Top players"],"youth":["مواهب شابة (كشافة)","Young talents (scout)"],
 "ok":["تمت الصفقة!","Deal done!"],"rejected":["رفض النادي العرض","Offer rejected"],"no_funds":["الميزانية لا تكفي","Not enough budget"],
 "squad_full":["الفريق ممتلئ (26)","Squad full (26)"],"squad_min":["لا يمكن البيع: الحد الأدنى 16","Cannot sell: minimum 16"],"sold":["تم البيع","Sold"],"gone":["اللاعب غير متاح","Player unavailable"],
 "accept":["قبول","Accept"],"reject":["رفض","Reject"],"no_offers":["لا توجد عروض حالياً","No offers right now"],"offer_from":["عرض من","Offer from"],
 "saved":["تم الحفظ","Saved"],"save_fail":["فشل الحفظ","Save failed"],"save":["حفظ يدوي","Manual save"],"load":["تحميل المسيرة","Load career"],"load_fail":["لا يوجد حفظ صالح","No valid save found"],"loaded":["تم التحميل","Loaded"],
 "poss":["الاستحواذ","Possession"],"shots":["التسديدات","Shots"],"sot":["على المرمى","On target"],"corners":["ركنيات","Corners"],"fouls":["أخطاء","Fouls"],"passes":["تمريرات","Passes"],
 "results":["نتائج الجولة","Round results"],"events":["أحداث المباراة","Match events"],"stats":["الإحصائيات","Stats"],
 "hdr":["لعب فاز تعادل خسارة +/- نقاط","P W D L GD Pts"],"none":["لا يوجد","None"],"champ":["البطل","Champion"],"pos":["المركز","Position"]}

var body: VBoxContainer
var nav: HBoxContainer
var title_lbl: Label
var status: Label
var name_edit: LineEdit
var club_opt: OptionButton
var market_mode = "best"

func T(k):
	return S[k][0 if Game.ar() else 1] if S.has(k) else k
func money(k): return "%.1fM" % (k / 1000.0)
func pos_name(i): return T(["gk", "def", "mid", "att"][i])

func _ready():
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var th = Theme.new()
	th.default_font_size = 34
	theme = th
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.12, 0.09)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var mc = MarginContainer.new()
	mc.set_anchors_preset(Control.PRESET_FULL_RECT)
	for s in ["left", "right", "top", "bottom"]: mc.add_theme_constant_override("margin_" + s, 24)
	add_child(mc)
	var vb = VBoxContainer.new()
	mc.add_child(vb)
	title_lbl = Label.new()
	title_lbl.add_theme_font_size_override("font_size", 48)
	title_lbl.add_theme_color_override("font_color", Color(0.5, 1, 0.6))
	vb.add_child(title_lbl)
	status = Label.new()
	status.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	vb.add_child(status)
	var sc = ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(sc)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(body)
	nav = HBoxContainer.new()
	vb.add_child(nav)
	apply_dir()
	show_start()

func apply_dir():
	layout_direction = Control.LAYOUT_DIRECTION_RTL if Game.ar() else Control.LAYOUT_DIRECTION_LTR

func reset_ui(show_nav):
	for c in body.get_children(): c.queue_free()
	for c in nav.get_children(): c.queue_free()
	status.text = ""
	if show_nav:
		for it in [["home", show_dash], ["squad", show_squad], ["match", show_match], ["table", show_table], ["market", show_market]]:
			var b = Button.new()
			b.text = T(it[0])
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.custom_minimum_size = Vector2(0, 90)
			b.pressed.connect(it[1])
			nav.add_child(b)

func lbl(txt, col = null):
	var l = Label.new()
	l.text = txt
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if col != null: l.add_theme_color_override("font_color", col)
	body.add_child(l)
	return l

func btn(txt, cb):
	var b = Button.new()
	b.text = txt
	b.custom_minimum_size = Vector2(0, 90)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.pressed.connect(cb)
	body.add_child(b)
	return b

# ---------- البداية ----------
func show_start():
	reset_ui(false)
	title_lbl.text = T("title")
	lbl(T("tagline"))
	btn(T("new"), show_new)
	if FileAccess.file_exists(Game.SAVE_PATH): btn(T("cont"), _on_continue)
	btn(T("lang"), _toggle_lang)

func _on_continue():
	if Game.load_game():
		apply_dir()
		show_dash()
	else:
		status.text = T("load_fail")

func _toggle_lang():
	Game.lang = "en" if Game.ar() else "ar"
	apply_dir()
	if Game.clubs.is_empty(): show_start()
	else: show_settings()

func show_new():
	reset_ui(false)
	title_lbl.text = T("new")
	lbl(T("coach_name"))
	name_edit = LineEdit.new()
	name_edit.text = T("default_coach")
	name_edit.custom_minimum_size = Vector2(0, 90)
	body.add_child(name_edit)
	lbl(T("pick_club"))
	club_opt = OptionButton.new()
	club_opt.custom_minimum_size = Vector2(0, 90)
	for i in Game.CLUBS_AR.size(): club_opt.add_item(Game.club_name(i), i)
	body.add_child(club_opt)
	btn(T("begin"), _begin)
	btn(T("back"), show_start)

func _begin():
	Game.new_career(name_edit.text.strip_edges(), club_opt.get_selected_id())
	show_dash()

# ---------- لوحة التحكم ----------
func show_dash():
	reset_ui(true)
	title_lbl.text = Game.club_name(Game.club)
	var c = Game.clubs[Game.club]
	lbl("%s: %s  |  %s %d  |  %s %d" % [T("coach"), Game.coach, T("season"), Game.season, T("week"), Game.week + 1])
	lbl("%s: %s" % [T("budget"), money(c.budget)])
	var m = Game.next_fixture()
	lbl("%s: %s - %s" % [T("next"), Game.club_name(m[0]), Game.club_name(m[1])])
	lbl("%s: %d" % [T("rank"), Game.rank_of(Game.club)])
	btn(T("play"), show_match)
	btn("%s (%d)" % [T("mail"), Game.offers.size()], show_mail)
	btn(T("history"), show_history)
	btn(T("settings"), show_settings)

# ---------- الفريق ----------
func show_squad():
	reset_ui(true)
	title_lbl.text = T("squad")
	var fo = OptionButton.new()
	fo.custom_minimum_size = Vector2(0, 90)
	var keys = Game.FORMS.keys()
	for i in keys.size():
		fo.add_item(keys[i], i)
		if keys[i] == Game.formation: fo.select(i)
	fo.item_selected.connect(func(i): Game.formation = keys[i])
	lbl(T("formation"))
	body.add_child(fo)
	var to = OptionButton.new()
	to.custom_minimum_size = Vector2(0, 90)
	for i in Game.TACTICS.size():
		to.add_item(T(Game.TACTICS[i]), i)
		if Game.TACTICS[i] == Game.tactic: to.select(i)
	to.item_selected.connect(func(i): Game.tactic = Game.TACTICS[i])
	lbl(T("tactic"))
	body.add_child(to)
	var list = Game.squad(Game.club)
	list.sort_custom(func(a, b): return a.pos < b.pos or (a.pos == b.pos and a.ovr > b.ovr))
	for p in list:
		var pid = p.id
		var inj = ("  🚑%d" % p.inj) if p.inj > 0 else ""
		btn("%s  %s  %s %d  %s %d  %s %d%s" % [Game.pname(p), pos_name(p.pos), T("ovr"), p.ovr, T("age"), p.age, T("fit"), p.fit, inj], func(): show_player(pid, show_squad))

func show_player(pid, back):
	reset_ui(true)
	var p = Game.find(pid)
	if p == null:
		show_squad()
		return
	title_lbl.text = Game.pname(p)
	lbl("%s | %s: %d | %s: %d | %s: %d" % [pos_name(p.pos), T("age"), p.age, T("ovr"), p.ovr, T("pot"), p.pot])
	lbl("%s: %s | %s: %s" % [T("value"), money(p.value), T("wage"), "%dk" % p.wage])
	lbl("%s: %d | %s: %d%%" % [T("contract"), p.contract, T("fit"), p.fit])
	lbl("%s: %d | %s: %d" % [T("goals"), p.goals, T("apps"), p.apps])
	if p.inj > 0: lbl("🚑 %s: %d %s" % [T("inj"), p.inj, T("weeks")], Color(1, 0.5, 0.4))
	lbl(Game.club_name(p.club))
	if p.club == Game.club:
		btn(T("sell"), func(): _do_sell(pid, back))
	else:
		for pct in [90, 100, 115]:
			btn("%s %d%% (%s)" % [T("buy"), pct, money(int(p.value * pct / 100.0))], func(): _do_buy(pid, pct, back))
	btn(T("back"), back)

func _do_buy(pid, pct, back):
	var r = Game.buy(pid, pct)
	if r == "ok": back.call()
	else: status.text = T(r)

func _do_sell(pid, back):
	var r = Game.sell(pid)
	if r == "sold": back.call()
	else: status.text = T(r)

# ---------- المباراة ----------
func show_match():
	reset_ui(true)
	title_lbl.text = T("match")
	var m = Game.next_fixture()
	lbl("%s %d: %s - %s" % [T("week"), Game.week + 1, Game.club_name(m[0]), Game.club_name(m[1])])
	btn(T("play"), _play)
	if Game.last.size() > 0: draw_result(Game.last)

func _play():
	Game.play_round()
	show_match()

func draw_result(r):
	lbl("%s  %d - %d  %s" % [Game.club_name(r.h), r.gh, r.ga, Game.club_name(r.a)], Color(0.5, 1, 0.6))
	lbl(T("stats"))
	var st = r.st
	for k in ["poss", "shots", "sot", "corners", "fouls", "passes"]:
		var a = st[k][0]
		var b = st[k][1]
		lbl("%s: %d - %d" % [T(k), int(a), int(b)])
	lbl(T("events"))
	for e in r.ev: lbl("%d'  %s" % [e.m, e.txt])
	lbl(T("results"))
	for x in Game.round_results: lbl("%s %d-%d %s" % [Game.club_name(x.h), x.gh, x.ga, Game.club_name(x.a)])

# ---------- الدوري ----------
func show_table():
	reset_ui(true)
	title_lbl.text = T("table")
	lbl(T("hdr"))
	var t = Game.sorted_table()
	for i in t.size():
		var c = Game.clubs[t[i]]
		var col = Color(0.5, 1, 0.6) if t[i] == Game.club else null
		lbl("%d. %s   %d  %d  %d  %d  %+d  %d" % [i + 1, Game.club_name(t[i]), c.pl, c.w, c.d, c.l, c.gf - c.ga, c.pts], col)
	lbl(T("goals"))
	var sc = Game.players.duplicate()
	sc.sort_custom(func(a, b): return a.goals > b.goals)
	for i in 5:
		if sc[i].goals > 0: lbl("%s (%s): %d" % [Game.pname(sc[i]), Game.club_name(sc[i].club), sc[i].goals])

# ---------- الانتقالات ----------
func show_market():
	reset_ui(true)
	title_lbl.text = T("market")
	lbl("%s: %s" % [T("budget"), money(Game.clubs[Game.club].budget)])
	btn(T("best"), func(): market_mode = "best"; show_market())
	btn(T("youth"), func(): market_mode = "youth"; show_market())
	var pool = Game.players.filter(func(p): return p.club != Game.club)
	if market_mode == "youth":
		pool = pool.filter(func(p): return p.age <= 21)
		pool.sort_custom(func(a, b): return a.pot > b.pot)
	else:
		pool.sort_custom(func(a, b): return a.ovr > b.ovr)
	for i in mini(20, pool.size()):
		var p = pool[i]
		var pid = p.id
		btn("%s  %s  %s %d/%d  %s %d  %s" % [Game.pname(p), pos_name(p.pos), T("ovr"), p.ovr, p.pot, T("age"), p.age, money(p.value)], func(): show_player(pid, show_market))

# ---------- البريد والعروض ----------
func show_mail():
	reset_ui(true)
	title_lbl.text = T("mail")
	if Game.offers.is_empty(): lbl(T("no_offers"))
	for i in Game.offers.size():
		var o = Game.offers[i]
		var p = Game.find(o.pid)
		if p == null: continue
		lbl("%s %s: %s ← %s" % [T("offer_from"), Game.club_name(o.club), Game.pname(p), money(o.price)])
		var pid = p.id
		var price = o.price
		var idx = i
		btn(T("accept"), func(): _accept(pid, price))
		btn(T("reject"), func(): _reject(idx))
	for s in Game.inbox.slice(0, 15): lbl(s)

func _accept(pid, price):
	var r = Game.sell(pid, price)
	if r != "sold": status.text = T(r)
	show_mail()

func _reject(i):
	Game.offers.remove_at(i)
	show_mail()

func show_history():
	reset_ui(true)
	title_lbl.text = T("history")
	if Game.history.is_empty(): lbl(T("none"))
	for h in Game.history:
		lbl("%s %d: %s %s | %s %d" % [T("season"), h.season, T("champ"), Game.club_name(h.champ), T("pos"), h.pos])

func show_settings():
	reset_ui(not Game.clubs.is_empty())
	title_lbl.text = T("settings")
	btn(T("save"), _manual_save)
	btn(T("load"), _manual_load)
	btn(T("lang"), _toggle_lang)

func _manual_save():
	status.text = T("saved") if Game.save_game() else T("save_fail")

func _manual_load():
	if Game.load_game():
		apply_dir()
		show_dash()
	else:
		status.text = T("load_fail")
