extends Node
# منطق اللعبة: البيانات، المحاكاة، الانتقالات، الحفظ
const SAVE_PATH = "user://fakhri_save.json"
const FORMS = {"4-3-3":[1,4,3,3],"4-2-3-1":[1,4,5,1],"4-4-2":[1,4,4,2],"3-5-2":[1,3,5,2]}
const TACTICS = ["balanced","possession","press","counter","deep"]
const CLUBS_AR = ["نادي الصقور","نادي النمور","نادي الفرسان","نادي الأسود","نادي النجوم","نادي العاصفة","نادي الشراع","نادي الواحة"]
const CLUBS_EN = ["Falcons FC","Tigers FC","Knights FC","Lions FC","Stars FC","Storm FC","Sails FC","Oasis FC"]
const FN_AR = ["عمر","خالد","يوسف","سامي","ماجد","فارس","نبيل","رامي","هشام","طارق","زياد","ليث"]
const FN_EN = ["Omar","Khaled","Yousef","Sami","Majed","Fares","Nabil","Rami","Hisham","Tarek","Ziad","Layth"]
const LN_AR = ["الحداد","النجار","المنصور","الفهد","السالم","الزعبي","الراشد","البدر","العلي","الشامي","القاسم","التميمي"]
const LN_EN = ["Haddad","Najjar","Mansour","Fahd","Salem","Zoubi","Rashed","Badr","Ali","Shami","Qasim","Tamimi"]

var lang = "ar"
var coach = ""
var club = 0
var week = 0
var season = 1
var formation = "4-3-3"
var tactic = "balanced"
var clubs = []
var players = []
var fixtures = []
var history = []
var inbox = []
var offers = []
var last = {}
var round_results = []
var next_id = 0

func ar(): return lang == "ar"
func club_name(i): return CLUBS_AR[i] if ar() else CLUBS_EN[i]
func pname(p): return (FN_AR[p.fn] + " " + LN_AR[p.ln]) if ar() else (FN_EN[p.fn] + " " + LN_EN[p.ln])
func find(id):
	for p in players:
		if p.id == id: return p
	return null
func squad(c):
	return players.filter(func(x): return x.club == c)

func calc_value(p):
	p.value = int(pow(maxf(float(p.ovr - 45), 1.0), 2.3) * 3.0 * (1.0 if p.age < 30 else 0.7))
	p.wage = maxi(3, int(p.value / 180.0))

func gen_player(c, pos, strength):
	var ovr = clampi(strength + randi_range(-9, 9), 40, 90)
	var age = randi_range(17, 36)
	var pot = clampi(ovr + (randi_range(0, 12) if age < 24 else randi_range(0, 2)), ovr, 94)
	var p = {"id": next_id, "fn": randi() % 12, "ln": randi() % 12, "age": age, "pos": pos, "club": c,
		"ovr": ovr, "pot": pot, "contract": randi_range(1, 4), "fit": 100, "inj": 0, "goals": 0, "apps": 0}
	next_id += 1
	calc_value(p)
	return p

func build_fixtures():
	var t = range(8)
	var rounds = []
	for r in 7:
		var rd = []
		for i in 4:
			var a = t[i]
			var b = t[7 - i]
			rd.append([a, b] if r % 2 == 0 else [b, a])
		rounds.append(rd)
		t.insert(1, t.pop_back())
	var second = []
	for rd in rounds:
		var rv = []
		for m in rd: rv.append([m[1], m[0]])
		second.append(rv)
	fixtures = rounds + second

func reset_table():
	for c in clubs:
		c.pts = 0; c.pl = 0; c.w = 0; c.d = 0; c.l = 0; c.gf = 0; c.ga = 0

func new_career(coach_name, club_idx):
	randomize()
	coach = coach_name if coach_name != "" else "Coach"
	club = club_idx; week = 0; season = 1
	formation = "4-3-3"; tactic = "balanced"
	clubs = []; players = []; history = []; inbox = []; offers = []; last = {}; next_id = 0
	for i in 8:
		var s = 55 + randi_range(0, 18)
		clubs.append({"strength": s, "budget": 40000})
		for k in [[0, 2], [1, 6], [2, 6], [3, 4]]:
			for j in k[1]: players.append(gen_player(i, k[0], s))
	reset_table()
	build_fixtures()
	save_game()

func next_fixture():
	for m in fixtures[week]:
		if m[0] == club or m[1] == club: return m
	return [club, club]

func lineup(c):
	var f = formation if c == club else "4-4-2"
	var need = FORMS[f]
	var xi = []
	for pos in 4:
		var pool = players.filter(func(x): return x.club == c and x.pos == pos and x.inj <= 0)
		pool.sort_custom(func(a, b): return a.ovr * (0.7 + a.fit / 333.0) > b.ovr * (0.7 + b.fit / 333.0))
		xi.append_array(pool.slice(0, need[pos]))
	return xi

func rating(c):
	var xi = lineup(c)
	var sums = [0.0, 0.0, 0.0, 0.0]
	var cnt = [0, 0, 0, 0]
	for p in xi:
		sums[p.pos] += p.ovr * (0.7 + p.fit / 333.0)
		cnt[p.pos] += 1
	var v = []
	for i in 4: v.append(sums[i] / cnt[i] if cnt[i] > 0 else 30.0)
	var r = {"gk": v[0], "def": v[1], "mid": v[2], "att": v[3]}
	if c == club:
		match tactic:
			"possession": r.mid += 3; r.att -= 1
			"press": r.att += 2; r.def -= 2
			"counter": r.att += 2; r.mid -= 2
			"deep": r.def += 3; r.att -= 3
	return r

func pick_scorer(xi):
	var tot = 0.0
	var w = []
	for p in xi:
		var x = [0.0, 0.7, 2.0, 5.0][p.pos]
		w.append(x); tot += x
	var r = randf() * tot
	for i in xi.size():
		r -= w[i]
		if r <= 0: return xi[i]
	return xi[xi.size() - 1]

func sim_match(h, a):
	var rt = [rating(h), rating(a)]
	var xi = [lineup(h), lineup(a)]
	var ids = [h, a]
	var ph = clampf(50.0 + (rt[0].mid - rt[1].mid) * 1.3 + 3.0, 30.0, 70.0)
	var st = {"poss": [ph, 100.0 - ph], "shots": [0, 0], "sot": [0, 0], "corners": [0, 0], "fouls": [0, 0], "passes": [0, 0], "goals": [0, 0]}
	var ev = []
	for s in 2:
		var o = 1 - s
		var n = maxi(3, 6 + int(st.poss[s] / 10.0) + randi_range(0, 5) + int((rt[s].att - rt[o].def) * 0.25))
		st.shots[s] = n
		st.passes[s] = int(300 * st.poss[s] / 50.0) + randi_range(-30, 30)
		st.corners[s] = randi_range(1, 3) + int(n / 4.0)
		st.fouls[s] = randi_range(7, 15)
		var pr = clampf(0.11 + (rt[s].att - (rt[o].def + rt[o].gk) * 0.5) * 0.006, 0.03, 0.35)
		for i in n:
			var m = randi_range(1, 90)
			if randf() < pr:
				var p = pick_scorer(xi[s])
				st.sot[s] += 1; st.goals[s] += 1
				ev.append({"m": m, "s": s, "t": "goal", "pid": p.id,
					"txt": ("⚽ هدف لـ %s بواسطة %s!" % [club_name(ids[s]), pname(p)]) if ar() else ("⚽ GOAL for %s by %s!" % [club_name(ids[s]), pname(p)])})
			elif randf() < 0.35:
				st.sot[s] += 1
				var p2 = pick_scorer(xi[s])
				ev.append({"m": m, "s": s, "t": "save", "pid": -1,
					"txt": ("🧤 تسديدة من %s يتصدى لها الحارس" % pname(p2)) if ar() else ("🧤 Shot by %s saved by the keeper" % pname(p2))})
		for i in randi_range(0, 3):
			var cands = xi[s].filter(func(x): return x.pos != 0)
			var cp = cands[randi() % cands.size()]
			ev.append({"m": randi_range(5, 90), "s": s, "t": "yellow", "pid": -1,
				"txt": ("🟨 بطاقة صفراء لـ %s" % pname(cp)) if ar() else ("🟨 Yellow card: %s" % pname(cp))})
	ev.sort_custom(func(x, y): return x.m < y.m)
	return {"h": h, "a": a, "gh": st.goals[0], "ga": st.goals[1], "ev": ev, "st": st, "xi": xi}

func apply_match(r):
	var hh = clubs[r.h]
	var aa = clubs[r.a]
	hh.pl += 1; aa.pl += 1
	hh.gf += r.gh; hh.ga += r.ga; aa.gf += r.ga; aa.ga += r.gh
	if r.gh > r.ga:
		hh.pts += 3; hh.w += 1; aa.l += 1
	elif r.gh < r.ga:
		aa.pts += 3; aa.w += 1; hh.l += 1
	else:
		hh.pts += 1; aa.pts += 1; hh.d += 1; aa.d += 1
	for e in r.ev:
		if e.t == "goal":
			var p = find(e.pid)
			if p != null: p.goals += 1
	for s in 2:
		var cid = r.h if s == 0 else r.a
		var cost_hi = 12 if (cid == club and tactic == "press") else 9
		for p in r.xi[s]:
			p.apps += 1
			p.fit = maxi(40, p.fit - randi_range(5, cost_hi))
			if randf() < 0.02:
				p.inj = randi_range(1, 5) + 1
				if p.club == club:
					inbox.push_front(("🚑 %s مصاب لمدة %d أسابيع" % [pname(p), p.inj - 1]) if ar() else ("🚑 %s injured for %d weeks" % [pname(p), p.inj - 1]))

func play_round():
	var rd = fixtures[week]
	round_results = []
	last = {}
	var xis = []
	for m in rd:
		var r = sim_match(int(m[0]), int(m[1]))
		apply_match(r)
		round_results.append(r)
		xis.append_array(r.xi[0]); xis.append_array(r.xi[1])
		if r.h == club or r.a == club: last = r
	for p in players:
		if not xis.has(p): p.fit = mini(100, p.fit + 8)
		else: p.fit = mini(100, p.fit + 2)
		if p.inj > 0: p.inj -= 1
	for i in 8:
		var wages = 0
		for p in squad(i): wages += p.wage
		clubs[i].budget += 900 - wages
	if randf() < 0.15: make_offer()
	week += 1
	if week >= fixtures.size(): end_season()
	save_game()

func sorted_table():
	var idx = range(8)
	idx.sort_custom(func(a, b):
		var x = clubs[a]
		var y = clubs[b]
		if x.pts != y.pts: return x.pts > y.pts
		if (x.gf - x.ga) != (y.gf - y.ga): return (x.gf - x.ga) > (y.gf - y.ga)
		return x.gf > y.gf)
	return idx

func rank_of(c): return sorted_table().find(c) + 1

func end_season():
	var t = sorted_table()
	var rk = t.find(club) + 1
	history.append({"season": season, "champ": t[0], "pos": rk, "pts": clubs[club].pts})
	inbox.push_front(("🏆 نهاية الموسم %d: البطل %s، وترتيبك %d" % [season, club_name(t[0]), rk]) if ar() else ("🏆 Season %d over: champions %s, you finished %d" % [season, club_name(t[0]), rk]))
	clubs[club].budget += (9 - rk) * 1500
	for p in players:
		p.age += 1
		if p.age <= 24: p.ovr = mini(p.pot, p.ovr + randi_range(0, 4))
		elif p.age >= 31: p.ovr = maxi(40, p.ovr - randi_range(0, 3))
		else: p.ovr = clampi(p.ovr + randi_range(-1, 1), 40, 92)
		p.contract -= 1
		if p.contract <= 0: p.contract = 2
		p.goals = 0; p.apps = 0; p.fit = 100; p.inj = 0
		calc_value(p)
	season += 1; week = 0
	reset_table()
	build_fixtures()
	offers = []

func buy(pid, pct):
	var p = find(pid)
	if p == null: return "gone"
	var price = int(p.value * pct / 100.0)
	if price > clubs[club].budget: return "no_funds"
	if squad(club).size() >= 26: return "squad_full"
	if randf() < clampf(0.25 + (pct - 85) * 0.02, 0.05, 0.95):
		clubs[club].budget -= price
		clubs[p.club].budget += price
		p.club = club; p.contract = 3
		save_game()
		return "ok"
	return "rejected"

func sell(pid, price = -1):
	var p = find(pid)
	if p == null or p.club != club: return "gone"
	if squad(club).size() <= 16: return "squad_min"
	var pr = price if price >= 0 else int(p.value * 0.95)
	var buyer = (club + randi_range(1, 7)) % 8
	clubs[club].budget += pr
	clubs[buyer].budget -= pr
	p.club = buyer
	offers = offers.filter(func(o): return o.pid != pid)
	save_game()
	return "sold"

func make_offer():
	var mine = squad(club)
	if mine.is_empty() or offers.size() >= 3: return
	var p = mine[randi() % mine.size()]
	for o in offers:
		if o.pid == p.id: return
	offers.append({"pid": p.id, "club": (club + randi_range(1, 7)) % 8, "price": int(p.value * randf_range(0.9, 1.4))})

func save_game():
	var d = {"lang": lang, "coach": coach, "club": club, "week": week, "season": season, "formation": formation,
		"tactic": tactic, "clubs": clubs, "players": players, "fixtures": fixtures, "history": history,
		"inbox": inbox, "offers": offers, "next_id": next_id}
	var f = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null: return false
	f.store_string(JSON.stringify(d))
	f.close()
	return true

func load_game():
	if not FileAccess.file_exists(SAVE_PATH): return false
	var f = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null: return false
	var d = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(d) != TYPE_DICTIONARY: return false
	for k in ["coach", "club", "week", "season", "formation", "tactic", "clubs", "players", "fixtures"]:
		if not d.has(k): return false
	coach = str(d.coach); club = int(d.club); week = int(d.week); season = int(d.season)
	formation = str(d.formation); tactic = str(d.tactic)
	lang = str(d.get("lang", "ar"))
	next_id = int(d.get("next_id", 0))
	clubs = d.clubs
	for c in clubs:
		for k in c.keys(): c[k] = int(c[k])
	players = d.players
	for p in players:
		for k in p.keys(): p[k] = int(p[k])
	fixtures = []
	for rd in d.fixtures:
		var rv = []
		for m in rd: rv.append([int(m[0]), int(m[1])])
		fixtures.append(rv)
	history = d.get("history", [])
	for h in history:
		for k in h.keys(): h[k] = int(h[k])
	inbox = d.get("inbox", [])
	offers = d.get("offers", [])
	for o in offers:
		for k in o.keys(): o[k] = int(o[k])
	last = {}
	return true
