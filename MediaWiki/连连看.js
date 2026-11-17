if(document.body.clientWidth>=992){
	var nx = 12, ny = 10;	//电脑端尺寸
}
else{
	var nx = 4, ny = 8;	//手机端尺寸
}

var symbols = new Array()
symbols.push(	//手机端部分
		"https://patchwiki.biligame.com/images/klbq/9/96/gnq73w8t5yci2k9wlibkyze0q6xe9uw.png",	
		"https://patchwiki.biligame.com/images/klbq/3/34/0fdtwedpm64zklfhwen86sodfexcncj.png",	
		"https://patchwiki.biligame.com/images/klbq/4/4a/j2ttergvukhsa9drpv6z4itm0d3fkid.png",	
		"https://patchwiki.biligame.com/images/klbq/2/23/8t3dv5df377mtaxnsva2awbrjtja8wi.png",	
		"https://patchwiki.biligame.com/images/klbq/7/76/jclml4pbtkg6c7t7sy91inrfz1bt92u.png",	
		"https://patchwiki.biligame.com/images/klbq/2/23/8t3dv5df377mtaxnsva2awbrjtja8wi.png"
);
if(document.body.clientWidth>=992){
	symbols.push(	//电脑端额外部分
		"https://patchwiki.biligame.com/images/klbq/9/96/gnq73w8t5yci2k9wlibkyze0q6xe9uw.png",	
		"https://patchwiki.biligame.com/images/klbq/3/34/0fdtwedpm64zklfhwen86sodfexcncj.png",	
		"https://patchwiki.biligame.com/images/klbq/4/4a/j2ttergvukhsa9drpv6z4itm0d3fkid.png",	
		"https://patchwiki.biligame.com/images/klbq/2/23/8t3dv5df377mtaxnsva2awbrjtja8wi.png",	
		"https://patchwiki.biligame.com/images/klbq/7/76/jclml4pbtkg6c7t7sy91inrfz1bt92u.png",	
		"https://patchwiki.biligame.com/images/klbq/2/23/8t3dv5df377mtaxnsva2awbrjtja8wi.png"
	);
}
var gameDiv = document.getElementById("game");
var timerSpan=document.getElementById("timer");
gameDiv.onselectstart=function(){
	return false;
}
gameDiv.ondragstart=function(){
	return false;
}
var start=false
gameDiv.onclick=function(){
	if(!start){
		timer=setInterval('timerSpan.innerHTML++',1000);
		start=true
	}
}
var selectedCell = null;
var empty = '&nbsp;';
var count = nx*ny;
var cellArray = [];
function fc(x, y){
	if(x<0||x>nx+1||y<0||y>ny+1){
		return null;
	}
	return cellArray[y][x];
}
function neibors(c){
	var neiborArr = [
		fc(c.x-1, c.y),
		fc(c.x+1, c.y),
		fc(c.x, c.y+1),
		fc(c.x, c.y-1)
	];
	return neiborArr;
}

function findPath(c, target, pathStack, trunCount){
	if(!c){
		return false;
	}
	var c_2 = pathStack[pathStack.length-2];
	if(c_2&&c_2.x!=c.x&&c_2.y!=c.y){
		if(++trunCount>2){
			return false;
		}
	}
	if(c == target){
		pathStack.push(c);
		return true;
	}
	if(c.innerHTML != empty){
		return false;
	}
	if(pathStack.indexOf(c)>=0){
		return false;
	}
	pathStack.push(c);
	
	var nexts = neibors(c);
	for(var i=0;i<nexts.length;i++){
		if(findPath(nexts[i], target, pathStack, trunCount)){
			return true;
		}
	}
	pathStack.pop();
	return false;
}

function tryMatch(ca, cb){
	if(ca==cb){
		return;
	}
	if(ca.innerHTML !== cb.innerHTML){
		return;
	}
	var pathStack = [ca];
	var found = false;
	var nexts = neibors(ca);
	for(var i=0;i<nexts.length;i++){
		if(findPath(nexts[i], cb, pathStack, 0)){
			found = true;
			break;
		}
	}
	
	if(!found){
		return;
	}
	ca.innerHTML = cb.innerHTML = empty;
	count-=2;
	if(count<2){
		clearInterval(timer)
		alert('可以刷新页面再玩一次喵');
	}
}
function onCellClicked(e){
	console.log(this.x+' '+this.y);
	if(this.innerHTML == empty){
		return;
	}
	if(selectedCell){
		tryMatch(selectedCell, this);
		selectedCell.setAttribute('class', 'cell');
		selectedCell = null;
	}else{
		selectedCell = this;
		selectedCell.setAttribute('class', 'cell selected');
	}
}
function init(m, n){
	for(var i=0;i<n+2;i++){
		var row = document.createElement('div');
		row.setAttribute('class', 'row');
		var cellArrayRow = [];
		cellArray.push(cellArrayRow);
		gameDiv.appendChild(row);
		for(var j=0;j<m+2;j++){
			var cell = document.createElement('div');
			cellArrayRow.push(cell);
			if(i==0||j==0||i==n+1||j==m+1){
				cell.setAttribute('class', 'border');
				cell.innerHTML = empty;
			}else{
				cell.setAttribute('class', 'cell');
				cell.addEventListener('click', onCellClicked);
			}
			cell.setAttribute('id', j+'_gc_'+i);
			cell.x = j;
			cell.y = i;
			row.appendChild(cell);
		}
	}
}
init(nx, ny);
function reset(){
	var all = count = nx*ny;
	var halfAll = all/2;
	var tmp = [];
	for(var i=0;i<halfAll;i++){
		var c = symbols[Math.floor(Math.random()*symbols.length)];
		tmp.push(c);
		tmp.push(c);
	}
	for(var i=all-1;i>=0;i--){
		var r = Math.floor(Math.random()*i);
		var c = tmp.splice(r,1);
		var y = Math.floor(i/nx);
		var x = i-y*nx;
		fc(x+1,y+1).innerHTML='<img src="'+c+'" height="76px" width="76px"/>';
	}
}
reset();