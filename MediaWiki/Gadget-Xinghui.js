"use strict";
(function () {
	if (window.matchMedia && window.matchMedia("(prefers-reduced-motion:reduce)").matches) return
	
	var xingHui = document.getElementById("spriteXingHui");

	if (!xingHui || document.body.clientWidth < 600) return;

	document.body.appendChild(xingHui);
	xingHui.style.display = "";
	xingHui.style.transform = "translate(var(--x),var(--y))rotateY(var(--r))";

	var reversed = false;

	function updateCSS(pos) {
		return Object.entries({
			x: Math.floor(pos.x) + "px",
			y: Math.floor(pos.y) + "px",
			r: reversed ? 0 : "180deg",
		}).forEach(function (d) {
			return xingHui.style.setProperty("--" + d[0], d[1]);
		});
	}

	var range = {
			minX: -50,
			minY: -50,
		},
		speed = {
			x: (Math.random() + 1) * 1.5,
			y: (Math.random() + 1) * 1.5,
		},
		pos = { x: -200, y: 0 },
		raf =
			window.requestAnimationFrame ||
			function (callback) {
				return setTimeout(callback, 12);
			};

	(function xingHuiMove() {
		range.maxX = document.body.clientWidth - 150;
		range.maxY = document.body.clientHeight - 150;
		if (pos.x < range.minX)
			(speed.x = Math.abs(speed.x)), (reversed = false);
		else if (pos.x > range.maxX) (speed.x *= -1), (reversed = true);
		if (pos.y < range.minY) speed.y = Math.abs(speed.y);
		else if (pos.y > range.maxY) speed.y *= -1;
		pos.x += speed.x;
		pos.y += speed.y;
		updateCSS(pos), raf(xingHuiMove);
	})();
})();