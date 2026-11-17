(function(){ 'use strict';
const Roleavatars = {
	米雪儿:
		"https://patchwiki.biligame.com/images/klbq/1/1b/tgwx7q9203dafj6rsypza3flbultqf7.png",
	信: "https://patchwiki.biligame.com/images/klbq/e/e6/s4r4y425r5vn5fbq0sw4i1d7l8d6ft4.png",
	心夏: "https://patchwiki.biligame.com/images/klbq/4/44/jvg14awbm8ip4fmf4nlkdr7f9nd88xs.png",
	伊薇特:
		"https://patchwiki.biligame.com/images/klbq/4/42/j71nx9i25shxr65jnoxxh24x4y0t0b5.png",
	芙拉薇娅:
		"https://patchwiki.biligame.com/images/klbq/c/c5/8bp7psa0s66d19ceyczzv78b26ydaqp.png",
	忧雾: "https://patchwiki.biligame.com/images/klbq/7/7e/mlxxmgdoh7lgfedoq9xw2p8ex1p3ksr.png",
	蕾欧娜:
		"https://patchwiki.biligame.com/images/klbq/3/38/mjk5un92714vlaegklmdwowye45ly3z.png",
	千代: "https://patchwiki.biligame.com/images/klbq/5/52/igsqgyro1n6ab6luk64lv4zj2yk7rwr.png",
	明: "https://patchwiki.biligame.com/images/klbq/1/11/88ba41q1irr2wpoh96dakhf175vmuuq.png",
	拉薇: "https://patchwiki.biligame.com/images/klbq/f/f3/1zor7pqxy3rn3uggyenorigvf37q4hr.png",
	梅瑞狄斯:
		"https://patchwiki.biligame.com/images/klbq/d/dd/20gac3391nb2prx6r69yrdkfatxapdu.png",
	令: "https://patchwiki.biligame.com/images/klbq/1/14/eqwt5hnh4lwfof08mcuzo67r2979a66.png",
	香奈美:
		"https://patchwiki.biligame.com/images/klbq/1/1d/ffln5mqrwtvr0dj0wq54guvs10jsfdo.png",
	艾卡: "https://patchwiki.biligame.com/images/klbq/9/92/j9snx5dgcw3wh8otfx8cqrwefluouum.png",
	珐格兰丝:
		"https://patchwiki.biligame.com/images/klbq/2/2a/s7uzltd131q57yryp0x6a6dnaqquf24.png",
	玛拉: "https://patchwiki.biligame.com/images/klbq/e/e7/gs4p0jqeei6dgxn6a3xcogywnest6gv.png",
	星绘: "https://patchwiki.biligame.com/images/klbq/f/f2/9rwg399wannhzh80knjj5tmwffnjg0m.png",
	奥黛丽:
		"https://patchwiki.biligame.com/images/klbq/2/2d/hmkcsrcvp79ctofkwv92iint9iupvnk.png",
	玛德蕾娜:
		"https://patchwiki.biligame.com/images/klbq/d/d6/hfq5r7kv7blidsu49fieu0b3wqbpjwu.png",
	绯莎: "https://patchwiki.biligame.com/images/klbq/f/f4/rtraite3bno62mzfatae961ke36hc5b.png",
	白墨: "https://patchwiki.biligame.com/images/klbq/d/d1/px8wh6qtz21h2brodfpkk6kp7dw5u1q.png",
	加拉蒂亚:
		"https://patchwiki.biligame.com/images/klbq/8/8f/2xobrcsqsmf35yi94lt7ix50m3tu76i.png",
	汐:
		"https://patchwiki.biligame.com/images/klbq/2/2e/2ti5xm227cj8xt5oy60awrv8ot6askx.png",
	诺诺:
		"https://patchwiki.biligame.com/images/klbq/4/40/9acjnv2oq4nogdupj5zx0olf98xty2t.png",
	莉莉丝:
		"https://patchwiki.biligame.com/images/klbq/1/1d/ten5w6kaavg85t400szqq7ll2odgg21.png",
	宣传车:
		"https://patchwiki.biligame.com/images/klbq/c/c4/50pztvv1r8wsc0ci76yiaggqx2d2124.jpg",
	官博娘:
		"https://patchwiki.biligame.com/images/klbq/b/b2/inshrfi46z92zploku8wkevvkozglzb.jpg",
};

  const Rolevoices = [
    {
      role: "米雪儿",
      DiaryDay: [
        "https://patchwiki.biligame.com/images/klbq/6/64/ql9dld74ec6bxtloswtxy9k2xtv8xqc.mp3",
      ],
      Birthday: [
        "https://patchwiki.biligame.com/images/klbq/c/cc/7q9myi08bec8auye4abxn3bdamifdnf.mp3",
      ],
      SpringFestival: [
        "https://patchwiki.biligame.com/images/klbq/e/ec/dleuavshipd18t2vuxvmtubxqlujk2z.mp3",
      ],
      CalabiYau: [
        "https://patchwiki.biligame.com/images/klbq/4/41/0dbkw05glqjbia8mev0v5a0iyos7em8.mp3",
      ],
      QixiFestival: [
        "https://patchwiki.biligame.com/images/klbq/6/66/mwo87ww6wi3r0tehqlphpntz5xrv5u3.mp3",
      ],
      Christmas: [
        "https://patchwiki.biligame.com/images/klbq/3/39/2xs9x0w003k50b0uc68oneuamtjt7nm.mp3",
      ],
      NewYear: [
        "https://patchwiki.biligame.com/images/klbq/c/ce/6je78fbnu3xzq10t5eqvc33h8w4jd75.mp3",
      ],
    },
    {
      role: "心夏",
      DiaryDay: [
        "https://patchwiki.biligame.com/images/klbq/a/ae/6c9vvi5fhhzr2ixqo13qtaicjpw83v7.mp3",
      ],
      Birthday: [
        "https://patchwiki.biligame.com/images/klbq/6/6b/lh2et76rfhk5nmedfum23vl4kzgjmyk.mp3",
        "https://patchwiki.biligame.com/images/klbq/2/2b/so01nivo4y892jc6bx4z53txy1snjld.mp3",
      ],
      SpringFestival: [
        "https://patchwiki.biligame.com/images/klbq/7/75/orpl04lbd6f8ze71olppgqi4zoxomua.mp3",
      ],
      CalabiYau: [
        "https://patchwiki.biligame.com/images/klbq/a/a8/pd1pdtocxdnw2ddalqa95s4875ox58m.mp3",
      ],
      QixiFestival: [
        "https://patchwiki.biligame.com/images/klbq/d/df/kodsmhv2aew9tyctdo4m9r60a6f9luu.mp3",
      ],
      Christmas: [
        "https://patchwiki.biligame.com/images/klbq/d/db/bstl41fs3ftc3lodri4ior7f3ibr49y.mp3",
      ],
      NewYear: [
        "https://patchwiki.biligame.com/images/klbq/0/08/d7v5w46cqw9zdfug8detcz5fbtxswph.mp3",
      ],
    },
    {
      role: "伊薇特",
      DiaryDay: [
        "https://patchwiki.biligame.com/images/klbq/8/80/2tzp5ad5dcte1swjczptsdrxtbop9bb.mp3",
      ],
      Birthday: [
        "https://patchwiki.biligame.com/images/klbq/3/31/42796pj5xceg6wm7rnrgoz4pixb5wii.mp3",
        "https://patchwiki.biligame.com/images/klbq/9/99/egfjfqslvb9sq9t0nldwbu0avwuanme.mp3",
      ],
      SpringFestival: [
        "https://patchwiki.biligame.com/images/klbq/9/9d/rc6g7rmzo4bwp8tc7vb17d34hdcy564.mp3",
      ],
      CalabiYau: [
        "https://patchwiki.biligame.com/images/klbq/f/f3/h7rgcc5penptbieao4j9dkstdm68ce0.mp3",
      ],
      QixiFestival: [
        "https://patchwiki.biligame.com/images/klbq/2/2d/3mujx480aidsridjd4ipvskmvbx5t3t.mp3",
      ],
      Christmas: [
        "https://patchwiki.biligame.com/images/klbq/4/4f/jlk62s16jap7oepyglbax4jxw57mp89.mp3",
      ],
      NewYear: [
        "https://patchwiki.biligame.com/images/klbq/a/a8/hqwhfcl3ovi15n09cbrbc0i0h9a9vak.mp3",
      ],
    },
    {
      role: "明",
      DiaryDay: [
        "https://patchwiki.biligame.com/images/klbq/7/72/2ccmuby332c6the304yf2d6oqfsq89i.mp3",
      ],
      Birthday: [
        "https://patchwiki.biligame.com/images/klbq/d/d4/8pvx0ukbe75h1099w90799stwuu2czb.mp3",
      ],
      SpringFestival: [
        "https://patchwiki.biligame.com/images/klbq/d/dd/td69jbpopj7u1f2ow9hnzixfkwmkpdt.mp3",
      ],
      CalabiYau: [
        "https://patchwiki.biligame.com/images/klbq/5/59/t7fa9kgkbqnqsmvw1wusjqz0ihoo5dd.mp3",
      ],
      QixiFestival: [
        "https://patchwiki.biligame.com/images/klbq/0/00/jva16arak78yamwcli4n6y67y60doy0.mp3",
      ],
      Christmas: [
        "https://patchwiki.biligame.com/images/klbq/e/ef/hzpn4yt77jm7bt8hfd4aw89tcxe2bmp.mp3",
      ],
      NewYear: [
        "https://patchwiki.biligame.com/images/klbq/6/69/8ludxugtd65yjcmbdy7j6zylzaortr8.mp3",
      ],
    },
    {
      role: "拉薇",
      DiaryDay: [
        "https://patchwiki.biligame.com/images/klbq/c/c6/j4ww6j0pihwzy7co08nfgtgpcxg27xo.mp3",
      ],
      Birthday: [
        "https://patchwiki.biligame.com/images/klbq/e/ee/15murcrn9xnxxkf21u9kfa2vwvopn2z.mp3",
        "https://patchwiki.biligame.com/images/klbq/1/18/sdjnixl9x5d9dqhqvqcdme4xvn0o1pd.mp3",
      ],
      SpringFestival: [
        "https://patchwiki.biligame.com/images/klbq/6/69/itz63x6nlsc67i6dkw75u9a12c9dg8a.mp3",
      ],
      CalabiYau: [
        "https://patchwiki.biligame.com/images/klbq/b/bb/6t044kewppbrcrl59eqdjy0lg2e374m.mp3",
      ],
      QixiFestival: [
        "https://patchwiki.biligame.com/images/klbq/a/a3/9on2h7zw4bto2zyvaxkq0uswpo3l2f6.mp3",
      ],
      Christmas: [
        "https://patchwiki.biligame.com/images/klbq/7/7c/4u0ar5ntim676qo27g73ykrwoy5ajx8.mp3",
      ],
      NewYear: [
        "https://patchwiki.biligame.com/images/klbq/2/24/b1skbdvfu6ld3erero91aii6u6oienm.mp3",
      ],
    },
    {
      role: "香奈美",
      DiaryDay: [
        "https://patchwiki.biligame.com/images/klbq/b/bc/034a5bsg6l4e1sfgcy7f0h220h7cmz3.mp3",
      ],
      Birthday: [
        "https://patchwiki.biligame.com/images/klbq/e/e5/q6fjdjkzh4gds1igcjy3nt3g6or5n5y.mp3",
        "https://patchwiki.biligame.com/images/klbq/8/8e/nvacl3aq03vwl7e8gqwhn8hpqeiasn6.mp3",
      ],
      SpringFestival: [
        "https://patchwiki.biligame.com/images/klbq/b/be/gk7advsy32vf1flgxsqpi96ufz3ee4b.mp3",
      ],
      CalabiYau: [
        "https://patchwiki.biligame.com/images/klbq/8/88/4clqrglpv4pngf6l6re77v3uwq6379b.mp3",
      ],
      QixiFestival: [
        "https://patchwiki.biligame.com/images/klbq/e/e6/r0a47jfif3uxqaogsggvu27oowf654y.mp3",
        "https://patchwiki.biligame.com/images/klbq/c/cc/gcqznmn3ehlfo2rn7mo0a5b2t94bnon.mp3",
      ],
      Christmas: [
        "https://patchwiki.biligame.com/images/klbq/4/41/4gweu2d4arknfaqg75vmlki6sdpxn9i.mp3",
        "https://patchwiki.biligame.com/images/klbq/a/a2/j3do6i036iq1l6p027dmqt0dhjpz3x9.mp3",
      ],
      NewYear: [
        "https://patchwiki.biligame.com/images/klbq/a/ab/ie7lt6vabgid5mhj22yd1mdwa6vugtx.mp3",
      ],
    },
    {
      role: "星绘",
      DiaryDay: [
        "https://patchwiki.biligame.com/images/klbq/e/ed/mpkacobi633eorg8bkdzdau6owoq8jc.mp3",
        "https://patchwiki.biligame.com/images/klbq/5/5a/c509v1a1tzxhrjy4xn6yhrkmy6vgu4i.mp3",
      ],
      Birthday: [
        "https://patchwiki.biligame.com/images/klbq/a/a3/c2s0oko3sst50xvgpztqjs7tf0e5wdo.mp3",
        "https://patchwiki.biligame.com/images/klbq/7/7f/gbygduc1jfmuxol8m38ahb3t5lchpbt.mp3",
        "https://patchwiki.biligame.com/images/klbq/6/69/2kx96glz3duev2rlc4edpr9c6q30uav.mp3",
      ],
      SpringFestival: [
        "https://patchwiki.biligame.com/images/klbq/6/65/gy63wnrtgpp0yuktgtc8qnvbymmfrbc.mp3",
        "https://patchwiki.biligame.com/images/klbq/4/45/f8hfizdwwmdqa05b77cgjzdvpr5jb0p.mp3",
      ],
      CalabiYau: [
        "https://patchwiki.biligame.com/images/klbq/8/87/qlv79e43lw7sbyxy0tf80sgjys1noka.mp3",
      ],
      QixiFestival: [
        "https://patchwiki.biligame.com/images/klbq/b/bb/oiq9iaw0svrklksge8rhjw5p45qecqa.mp3",
        "https://patchwiki.biligame.com/images/klbq/0/0c/pvd0ivszqjeqy44v8muan9bo0vw84sq.mp3",
      ],
      Christmas: [
        "https://patchwiki.biligame.com/images/klbq/8/8e/kzz1ppboy1h2luekek0nyx0mufd84fe.mp3",
        "https://patchwiki.biligame.com/images/klbq/5/50/c07bg36x6a961kqwr7frtv1yin6tetj.mp3",
      ],
      NewYear: [
        "https://patchwiki.biligame.com/images/klbq/8/87/aosw153ehiv4m4de34wd3hla90k3hin.mp3",
        "https://patchwiki.biligame.com/images/klbq/6/6f/pcxj0xlgj38yh1me2hbgy5y3744bltb.mp3",
      ],
    },
    {
      role: "奥黛丽",
      DiaryDay: [
        "https://patchwiki.biligame.com/images/klbq/7/7c/nxfmvfi9iyucvq4wwxoe4r6qv03vjn0.mp3",
        "https://patchwiki.biligame.com/images/klbq/7/71/tc0kw1k5s334vz0si4fyoc8n03rqbth.mp3",
      ],
      Birthday: [
        "https://patchwiki.biligame.com/images/klbq/b/be/g4rg2gol4ra8tuphniemipqjh6gh8y0.mp3",
        "https://patchwiki.biligame.com/images/klbq/3/3e/i1jx17cv9kv099wsjrugjy2yje9a9wj.mp3",
        "https://patchwiki.biligame.com/images/klbq/1/16/49rhc0l5fabbvt50p71ab16hz419fhf.mp3",
      ],
      SpringFestival: [
        "https://patchwiki.biligame.com/images/klbq/b/b8/hw633w463rygn66atvfzn5hno7yqnu4.mp3",
      ],
      CalabiYau: [
        "https://patchwiki.biligame.com/images/klbq/a/a5/n4ori5sg1dmt6us3t60n3fag71bhw98.mp3",
      ],
      QixiFestival: [
        "https://patchwiki.biligame.com/images/klbq/f/fc/8q61044j6um76zpm9qve5reiu68wu1g.mp3",
        "https://patchwiki.biligame.com/images/klbq/a/ac/h49ci528hkf2aoyobhaunxx6zfakh3t.mp3",
      ],
      Christmas: [
        "https://patchwiki.biligame.com/images/klbq/6/68/imrvndukcwo1vimesliibw65ici1ift.mp3",
      ],
      NewYear: [
        "https://patchwiki.biligame.com/images/klbq/8/8b/n9lckwtw4av6q3e42qhrc6ol71wnf2e.mp3",
      ],
    },
    {
      role: "玛德蕾娜",
      DiaryDay: [
        "https://patchwiki.biligame.com/images/klbq/c/c2/7lt84kl7gdr9ettnps2xw9arr8yk45a.mp3",
        "https://patchwiki.biligame.com/images/klbq/2/2f/5v1qgrmgsv4u98l5rdqgisc6dy03dgd.mp3",
      ],
      Birthday: [
        "https://patchwiki.biligame.com/images/klbq/7/72/earlnz2zcamdjg6ariuj94a7qnsuuo9.mp3",
        "https://patchwiki.biligame.com/images/klbq/e/e7/bufy5pw3kqt9ymhwh7bejktzai8vnhe.mp3",
        "https://patchwiki.biligame.com/images/klbq/c/ce/cvz28swdg2c3suzu4pz09ubbhjg8ddm.mp3",
      ],
      SpringFestival: [
        "https://patchwiki.biligame.com/images/klbq/8/8b/9rfybt42jsrhw5hk9lidjuqgeu8jlw0.mp3",
        "https://patchwiki.biligame.com/images/klbq/f/f1/fvhf9v5vaswk74mj2trrbo01ss43w0m.mp3",
      ],
      CalabiYau: [
        "https://patchwiki.biligame.com/images/klbq/5/57/d93x44y6ddyn8qzi075tz1s4dhpkneo.mp3",
      ],
      QixiFestival: [
        "https://patchwiki.biligame.com/images/klbq/1/1e/nbtlyfwx5e0nmq1gihvelnjx9u61ici.mp3",
      ],
      Christmas: [
        "https://patchwiki.biligame.com/images/klbq/2/2a/6a2eut4v0wx2cedrfl4yo48n5ru9529.mp3",
      ],
      NewYear: [
        "https://patchwiki.biligame.com/images/klbq/5/54/aseqqkued1cxpp60qoi868ziikrygei.mp3",
      ],
    },
    {
      role: "绯莎",
      DiaryDay: [
        "https://patchwiki.biligame.com/images/klbq/f/f7/2xvekr2zvhfquxqb3wsb8shs1pb0w47.mp3",
      ],
      Birthday: [
        "https://patchwiki.biligame.com/images/klbq/3/37/skflbguc0b2j27wz71ecoyzvtthr35u.mp3",
        "https://patchwiki.biligame.com/images/klbq/1/16/h6uats6zzeipjl0wdzoeijs5hiqcczk.mp3",
      ],
      SpringFestival: [
        "https://patchwiki.biligame.com/images/klbq/0/0f/02c8vipc4bebe45hnr28q4zwrj4rgfg.mp3",
        "https://patchwiki.biligame.com/images/klbq/2/2b/ibyuve9mr077b9qbnvim0dy3n4pq3gh.mp3",
      ],
      CalabiYau: [
        "https://patchwiki.biligame.com/images/klbq/f/f1/3yn6hk4y7fvebtvkrnf4l5nopkp8ef9.mp3",
        "https://patchwiki.biligame.com/images/klbq/f/ff/41m9aj7te06hjgft019fksyjunxunff.mp3",
      ],
      QixiFestival: [
        "https://patchwiki.biligame.com/images/klbq/0/09/suj7x23u4ycjrh2ttjl2c3x557opllg.mp3",
      ],
      Christmas: [
        "https://patchwiki.biligame.com/images/klbq/3/34/fdywk8arnysnn0lfdv26zbd4wb343n4.mp3",
      ],
      NewYear: [
        "https://patchwiki.biligame.com/images/klbq/6/67/js09tyg0kldaf84932nn3a02p1qeqob.mp3",
        "https://patchwiki.biligame.com/images/klbq/5/51/rs4r9g3y1rj1pey1cewptrany9kmt3z.mp3",
      ],
    },
  ];

const Rolebirthdays = [
	{ role: "令", month: 1, day: 5 },
	{ role: "千代", month: 1, day: 10 },
	{ role: "香奈美", month: 1, day: 27 },
	{ role: "芙拉薇娅", month: 2, day: 14 },
	{ role: "加拉蒂亚", month: 2, day: 22 },
	{ role: "玛德蕾娜", month: 3, day: 7 },
	{ role: "忧雾", month: 3, day: 22 },
	{ role: "米雪儿", month: 3, day: 25 },
	{ role: "玛拉", month: 4, day: 1 },
	{ role: "绯莎", month: 5, day: 10 },
	{ role: "伊薇特", month: 5, day: 23 },
	{ role: "官博娘", month: 6, day: 6 },
	{ role: "莉莉丝", month: 6, day: 6 },
	{ role: "汐", month: 6, day: 21 },
	{ role: "信", month: 7, day: 11 },
	{ role: "奥黛丽", month: 7, day: 29 },
	{ role: "明", month: 8, day: 15 },
	{ role: "梅瑞狄斯", month: 8, day: 28 },
	{ role: "珐格兰丝", month: 9, day: 10 },
	{ role: "星绘", month: 9, day: 26 },
	{ role: "蕾欧娜", month: 10, day: 10 },
	{ role: "诺诺", month: 10, day: 24 },
	{ role: "拉薇", month: 10, day: 29 },
	{ role: "艾卡", month: 11, day: 11 },
	{ role: "心夏", month: 12, day: 12 },
	{ role: "宣传车", month: 12, day: 18 },
	{ role: "白墨", month: 12, day: 20 },
];

const Holidaytime = [
	{
		name: "SpringFestival",
		dateRanges: [
			{
				start: new Date(new Date().getFullYear(), 1, 6), // 2-6
				end: new Date(new Date().getFullYear(), 1, 9), // 2-9
			},
		],
	},
	{
		name: "DiaryDay",
		dateRanges: [
			{
				start: new Date(new Date().getFullYear(), 1, 14), // 2-14
				end: new Date(new Date().getFullYear(), 1, 14),
			},
		],
	},
	{
		name: "QixiFestival",
		dateRanges: [
			{
				start: new Date(new Date().getFullYear(), 7, 19), // 8-19
				end: new Date(new Date().getFullYear(), 7, 19),
			},
		],
	},
    {
      name: "CalabiYau",
      dateRanges: [
        {
          start: new Date(new Date().getFullYear(), 7, 3), // 8-3
          end: new Date(new Date().getFullYear(), 7, 3),
        },
      ],
    },
    {
      name: "Christmas",
      dateRanges: [
        {
          start: new Date(new Date().getFullYear(), 11, 25), // 12-25
          end: new Date(new Date().getFullYear(), 11, 25),
        },
      ],
    },
    {
      name: "NewYear",
      dateRanges: [
        {
          start: new Date(new Date().getFullYear(), 0, 1), // 1-1
          end: new Date(new Date().getFullYear(), 0, 1),
        },
      ],
    },
  ];

const Holidaywishes = [
	{
		name: "Birthday",
		text: "今天（{Date}）是{role}的生日，让我们一起祝ta生日快乐吧！",
		themeClass: "holiday-theme-birthday",
		sideImage:
			"https://patchwiki.biligame.com/images/klbq/0/01/9ehjfw6vjk51wfz2k3485m9avjd4icx.svg",
	},
	{
		name: "SpringFestival",
		text: "春节快乐，引航者！",
		themeClass: "holiday-theme-spring",
		sideImage:
			"https://patchwiki.biligame.com/images/klbq/7/7e/oq1522u4wiab8web941rcnhnhfy9azz.svg",
	},
	{
		name: "DiaryDay",
		text: "情人节快乐，引航者！",
		themeClass: "holiday-theme-diaryday",
		sideImage:
			"https://patchwiki.biligame.com/images/klbq/c/c4/kb0t8fkf8wgxp5lbqqak9nge20izflw.svg",
	},
	{
		name: "QixiFestival",
		text: "七夕快乐，引航者！",
		themeClass: "holiday-theme-diaryday",
		sideImage:
			"https://patchwiki.biligame.com/images/klbq/4/4d/pzevsogl8y8sir53uj0xpz513y0finu.svg",
	},
    {
      name: "CalabiYau",
      text: "卡拉彼丘纪念日快乐喵，引航者！",
      themeClass: "holiday-theme-CalabiYau",
      sideImage:
        "https://patchwiki.biligame.com/images/klbq/7/74/nrs8ouv86a7wrg6nmd01cu76esr1xmo.svg",
    },
    {
      name: "Christmas",
      text: "圣诞节快乐，引航者！",
      themeClass: "holiday-theme-christmas",
      sideImage:
        "https://patchwiki.biligame.com/images/klbq/0/03/28sjozpnr49uqcay3tk6eud8j47709g.svg",
    },
    {
      name: "NewYear",
      text: "新年快乐喵，引航者！",
      themeClass: "holiday-theme-spring",
      sideImage:
        "https://patchwiki.biligame.com/images/klbq/7/7e/oq1522u4wiab8web941rcnhnhfy9azz.svg",
    },
  ];

  /* 工具函数 */
  function createImage(src, className) {
  const img = document.createElement('img');
  img.src = src;
  img.className = className;
  img.alt = '';
    return img;
  }

  // 数组随机取值
  function getRandomItem(array) {
    return array && array.length > 0 ? array[Math.floor(Math.random() * array.length)] : null;
  }

  // 检测是否为首页
  function isHomePage() {
    try {
      const pageNames = ['首页', 'Main_Page', '主页'];
      const currentPage = (mw.config.get('wgPageName') || 
                         document.title.replace(/ - .*$/, '') || 
                         location.pathname.split('/').pop()).toLowerCase();
      return pageNames.some(name => name.toLowerCase() === currentPage);
    } catch (e) {
      console.error("检测首页出错:", e);
      return false;
    }
  }

  // 获取角色语音（如果没有则返回null）
  function getRoleVoice(roleName, eventType) {
    try {
      const role = Rolevoices.find(v => v.role === roleName);
      return role && role[eventType] ? getRandomItem(role[eventType]) : null;
    } catch (e) {
      console.error("获取角色语音出错:", e);
      return null;
    }
  }

  // 获取所有当前有效事件
  function getAllCurrentEvents() {
    const now = new Date();
    const events = [];

    // 检测节日
    Holidaytime.forEach(holiday => {
      holiday.dateRanges.forEach(range => {
        range.start.setHours(0, 0, 0, 0);
        range.end.setHours(23, 59, 59, 999);
        if (now >= range.start && now <= range.end) {
          events.push({ type: "holiday", name: holiday.name });
        }
      });
    });

    // 检测生日
    const currentMonth = now.getMonth() + 1;
    const currentDay = now.getDate();
    Rolebirthdays.forEach(birthday => {
      if (birthday.month === currentMonth && birthday.day === currentDay) {
        events.push({
          type: "birthday",
          role: birthday.role,
          date: `${birthday.month}月${birthday.day}日`
        });
      }
    });

    return events;
  }

  /* 渲染相关函数 */

  // 主渲染函数
  function renderContent() {
    const container = document.getElementById("klbq-sitenotice");
    if (!container) {
      console.warn("未找到klbq-sitenotice容器");
      return;
    }

    // 清空容器
    container.innerHTML = '';
    container.style.display = 'block';

    // 获取当前事件
    const events = getAllCurrentEvents();
    console.log("检测到的事件:", events, "当前日期:", new Date());

    // 处理事件显示逻辑
    if (events.length > 0) {
      // 全站显示节日/生日祝福
      const selectedEvent = getRandomItem(events);
      renderEvent(container, selectedEvent);
    } else if (isHomePage()) {
      // 仅首页显示默认公告
      renderDefaultNotice(container);
    } else {
      // 非首页且无事件时隐藏
      container.style.display = 'none';
    }
  }

  // 渲染节日/生日事件
  function renderEvent(container, event) {
    const wishConfig = Holidaywishes.find(w => 
      event.type === "birthday" ? 
      w.name === "Birthday" : w.name === event.name
    );

    if (!wishConfig) {
      console.error("未找到匹配的祝福配置");
      return;
    }

    const renderData = {
      type: event.type,
      text: wishConfig.text,
      theme: wishConfig.themeClass,
      sideImage: wishConfig.sideImage
    };

    // 处理生日事件
    if (event.type === "birthday") {
      renderData.role = event.role;
      renderData.avatar = Roleavatars[event.role];
      renderData.text = renderData.text
        .replace("{role}", event.role)
        .replace("{Date}", event.date);
      renderData.audio = getRoleVoice(event.role, "Birthday");
    } 
    // 处理节日事件
    else {
      const availableRoles = Object.keys(Roleavatars)
        .map(role => ({
          role,
          audio: getRoleVoice(role, event.name)
        }))
        .filter(role => Roleavatars[role.role]);

      if (availableRoles.length > 0) {
        const selectedRole = getRandomItem(availableRoles);
        renderData.role = selectedRole.role;
        renderData.avatar = Roleavatars[selectedRole.role];
        renderData.audio = selectedRole.audio;
      }
    }

    // 渲染事件内容
    renderEventContent(container, renderData);
  }

  // 渲染事件内容
  function renderEventContent(container, config) {
    const wrapper = document.createElement('div');
    wrapper.className = `HolidayContainer ${config.theme}`;

    const content = document.createElement("div");
    content.className = "blessingContent";

    // 角色头像
    if (config.avatar) {
      content.appendChild(createImage(config.avatar, "roleImage radius50"));
    }

    // 祝福文本
    const text = document.createElement("span");
    text.className = "blessingText";
    text.textContent = config.text;
    content.appendChild(text);

    // 只在有音频时添加播放按钮
    if (config.audio) {
      content.appendChild(createAudioPlayer(config.audio));
    }

    // 装饰元素
    wrapper.append(
      createImage(config.sideImage, "leftImage"),
      content,
      createImage(config.sideImage, "rightImage")
    );

    container.appendChild(wrapper);
  }

  // 创建音频播放器
  function createAudioPlayer(audioUrl) {
    const wrapper = document.createElement("div");
    wrapper.className = "audio-wrapper";

    const audio = new Audio(audioUrl);
    const button = document.createElement("button");
    button.className = "play-button";
    button.title = "播放语音";

    const icon = document.createElement("img");
    icon.className = "playIcon";
    icon.src = "https://patchwiki.biligame.com/images/klbq/4/46/dbsnom35gkz79lqfi4xp5jo93dsec5a.svg";
    icon.alt = "播放按钮";

    button.addEventListener("click", () => {
      audio[audio.paused ? "play" : "pause"]();
      icon.src = audio.paused ? 
        "https://patchwiki.biligame.com/images/klbq/4/46/dbsnom35gkz79lqfi4xp5jo93dsec5a.svg" :
        "https://patchwiki.biligame.com/images/klbq/d/d8/asq90b8opfqll0o7jrzmcccfrzrg02y.svg";
    });

    audio.addEventListener("ended", () => {
      icon.src = "https://patchwiki.biligame.com/images/klbq/4/46/dbsnom35gkz79lqfi4xp5jo93dsec5a.svg";
    });

    button.appendChild(icon);
    wrapper.append(button, audio);
    return wrapper;
  }

  // 默认公告（仅首页显示）
  function renderDefaultNotice(container) {
  	const feedbackUrl = mw.util.getUrl('WIKI反馈版');
    container.classList.add("DefaultSitenotice");
    container.innerHTML = `
      <div class="default-notice-content">
        <p>本Wiki对全体读者开放编辑。</p>
        <p>暗夜模式切换功能已上线测试，如有UI适配问题或者编辑相关问题欢迎添加首页交流群或前往<a href="${feedbackUrl}" title="WIKI反馈版">WIKI反馈版</a>留言询问，欢迎更多引航者加入我们。</p>
        <p>按右上角<em>"WIKI功能→编辑"</em>即可修改页面内容。</p>
      </div>
    `;
  }

  /* 初始化 */
  function init() {
    if (typeof mw !== 'undefined' && mw.loader) {
      mw.loader.using('mediawiki.util').then(renderContent).catch(renderContent);
    } else {
      setTimeout(renderContent, 100);
    }
  }

  // 确保DOM加载完成后执行
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }

  console.log(
            "%c Sitenotice %c Initialized",
            "color: #334155; padding: 5px 0; background: rgba(248, 249, 250, 0.9);",
            "padding: 5px 5px 5px 0; background: #fff;"
        );
})();