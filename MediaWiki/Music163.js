/* --转自火环WIKI-- */
/* --Music163-- */
Music163=document.getElementsByClassName("Music163")
for(i=0;i<Music163.length;i++){
	Musicinfo=Music163[i].getElementsByTagName("span")
	Music163id=Musicinfo[0].innerHTML
	Music163type=Musicinfo[1].innerHTML
	if(Music163type=="0"){
		Music163[i].innerHTML='<iframe frameborder="no" border="0" marginwidth="0" marginheight="0" width=560 height=110 src="//music.163.com/outchain/player?type='+Music163type+'&id='+Music163id+'&auto=0&height=430"></iframe>'
	}else{
		Music163[i].innerHTML='<iframe frameborder="no" border="0" marginwidth="0" marginheight="0" width=100% height=86 src="//music.163.com/outchain/player?type='+Music163type+'&id='+Music163id+'&auto=0&height=66"></iframe>'
	}
}