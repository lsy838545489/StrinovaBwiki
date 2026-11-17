/*  转自明日方舟WIKI https://wiki.biligame.com/arknights/MediaWiki:EventTimer.js  */
try{
	eventTimers
}
catch(e){
	eventTimers=document.getElementsByClassName("eventTimer")
	function eventTimerRun(){
		for(let i=0;i<eventTimers.length;i++){
			let start=new Date(eventTimers[i].dataset.start)
			let end=new Date(eventTimers[i].dataset.end)
			let info=eventTimers[i].dataset.info
			let nowBJ=new Date(new Date()-(8+new Date().getTimezoneOffset()/60)*60*60*1000)
			let str="距离"+info
			let timeD=""
			if(start>nowBJ){
				timeD=start-nowBJ
				str+="开始还有"
			}
			else if(end<nowBJ){
				timeD=nowBJ-end
				str+="结束已经过去"
			}
			else{
				timeD=end-nowBJ
				str+="结束还有"
			}
			let format=dhms(timeD)
			str+=format[0]+"天"+format[1]+"小时"+format[2]+"分钟"
			eventTimers[i].innerHTML=str
		}
	}
	function dhms(timeD){
		let day=Math.floor(timeD/1000/60/60/24)
		timeD-=day*1000*60*60*24
		let hour=Math.floor(timeD/1000/60/60)
		timeD-=hour*1000*60*60
		let minute=Math.floor(timeD/1000/60)
		return [day,hour,minute]
	}
	setInterval(eventTimerRun,1000)
}