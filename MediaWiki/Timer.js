/*!
   转自碧蓝航线wiki
 * 如果再给我一次重新写的机会
 * 我一定不会再写出如此春虫虫的代码
 * BY：丩卩夂忄
 */
TimerNumber=document.getElementsByClassName("TimerNumber")
TimerNumbers=new Array()
for(i=0;i<TimerNumber.length;i++){
	TimerNumbers=TimerNumber[i].innerHTML
}
TimerNumber=Math.max(TimerNumbers)
TimerZone=new Date().getTimezoneOffset()/60;
TimerOffset=(8+TimerZone)*60*60*1000;
Timers=new Array();
TimerEndTimes=new Array();
TimerPMrs=new Array();
TimerDays=new Array();
TimerHours=new Array();
TimerMinutes=new Array();
TimerSeconds=new Array();

for(CountTimers=0;CountTimers<=TimerNumber;CountTimers++){
	Timers[CountTimers]=document.getElementById("Timer"+CountTimers);
	if(!Timers[CountTimers]){
		continue
	}
	TimerEndTimes[CountTimers]=document.getElementById("TimerEndTime"+CountTimers);
	TimerPMrs[CountTimers]=document.getElementById("TimerPMr"+CountTimers);
	TimerDays[CountTimers]=document.getElementById("TimerDay"+CountTimers);
	TimerHours[CountTimers]=document.getElementById("TimerHour"+CountTimers);
	TimerMinutes[CountTimers]=document.getElementById("TimerMinute"+CountTimers);
	TimerSeconds[CountTimers]=document.getElementById("TimerSecond"+CountTimers);
	document.getElementById("TimerPMl"+CountTimers).innerHTML = "距离";
	Timers[CountTimers].style.display="";

}
function TimerRun(){
	for(CountTimers=0;CountTimers<=TimerNumber;CountTimers++){
		if(!Timers[CountTimers]){
		continue
		}
		TimerEndTime=new Date(TimerEndTimes[CountTimers].innerHTML);
		TimerNowTime=new Date();
		TimerDifference=TimerEndTime.getTime()-TimerNowTime.getTime()-TimerOffset;
		if(TimerDifference<0){
			TimerDay=Math.abs(Math.ceil(TimerDifference/1000/60/60/24));
			TimerHour=Math.abs(Math.ceil(TimerDifference/1000/60/60%24));
			TimerMinute=Math.abs(Math.ceil(TimerDifference/1000/60%60));
			TimerSecond=Math.abs(Math.ceil(TimerDifference/1000%60));
			TimerPMrs[CountTimers].innerHTML = "已经过去";
		}
		else{
			TimerDifference+=1000;
			TimerDay=Math.abs(Math.floor(TimerDifference/1000/60/60/24));
			TimerHour=Math.abs(Math.floor(TimerDifference/1000/60/60%24));
			TimerMinute=Math.abs(Math.floor(TimerDifference/1000/60%60));
			TimerSecond=Math.abs(Math.floor(TimerDifference/1000%60));
			TimerPMrs[CountTimers].innerHTML = "还有";
		};
		TimerDays[CountTimers].innerHTML=TimerDay + "天";
		TimerHours[CountTimers].innerHTML=TimerHour + "时";
		TimerMinutes[CountTimers].innerHTML=TimerMinute + "分";
		TimerSeconds[CountTimers].innerHTML=TimerSecond + "秒";
		
	};
};
setInterval(TimerRun,0);