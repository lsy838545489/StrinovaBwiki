//
//  PaperManModelLoader.js 
//
//  Created by 剑走诗湖 on 2024-01-18.
//  Copyright 2024-2024 剑走诗湖. All rights reserved.
//  Version-0.5.
//  感谢Bwiki攻略组大佬们的支持，特别是glamcurrent、拉菲、Zyszhao、秋漫语、马小萌、点点、胶水等大佬们。
//  感谢Bwiki官方人员特别是环理的支持。
//  直接使用请保留文件头，谢谢~
//

var script = document.createElement('script');
script.type = 'importmap';
script.innerHTML = `
{
  "imports": {
    "three": "https://unpkg.com/three@0.160.0/build/three.module.js",
    "three/addons/": "https://unpkg.com/three@0.160.0/examples/jsm/"
  }
}`;
document.head.appendChild(script);

var script2 = document.createElement('script');
script2.type = 'module';
script2.innerHTML = `
			import * as THREE from 'three';
			import {
				MTLLoader
			} from 'https://wiki.biligame.com/klbq/index.php?title=MediaWiki:MTLLoader.js&action=raw&ctype=text/javascript';
			import {
				OBJLoader
			} from 'https://wiki.biligame.com/klbq/index.php?title=MediaWiki:OBJLoader.js&action=raw&ctype=text/javascript';
			import {
				OrbitControls
			} from 'https://wiki.biligame.com/klbq/index.php?title=MediaWiki:OrbitControls.js&action=raw&ctype=text/javascript';
			
			import {
				MMDLoader
			} from 'three/addons/loaders/MMDLoader.js';
			import {
				OutlineEffect
			} from 'three/addons/effects/OutlineEffect.js';
			
			document.THREE=THREE;
			document.OrbitControls=OrbitControls;
			document.MTLLoader=MTLLoader;
			document.OBJLoader=OBJLoader;
			document.MMDLoader=MMDLoader;
			document.OutlineEffect=OutlineEffect;
			let script = document.createElement('script');
			script.src = 'https://cdnjs.cloudflare.com/ajax/libs/jszip/3.10.1/jszip.min.js';
			script.onload=()=>{RLQ.push(['jquery', document.initDom]);};
			document.head.appendChild(script);
			
			//document.klbqModelLoad();
			//RLQ.push(['jquery', document.initDom]);
			`;
document.body.appendChild(script2);

function writeInDoc(textInfo) {
	// document.write(textInfo)
	var a = document.getElementsByClassName("model-showcase")[0]
	// console.log(a)
	if (a != null) {
		// a.innerHTML = null;
		if (typeof textInfo == 'object') {
			a.appendChild(textInfo)
		} else a.innerHTML = textInfo
	} else {
		if (typeof textInfo == 'object') {
			document.append(textInfo)
		} else document.write(textInfo)
	}
}

// let parse_odt_text = (odtpath, end_handler, exception_handler) => {

// 	let xhr = new XMLHttpRequest();
// 	xhr.open('GET', odtpath);
// 	xhr.responseType = 'arraybuffer';
// 	xhr.onload = function(e) {
// 		if (this.status == 200) {
// 			let arrayBufferView = new Uint8Array(this.response);
// 			processOdtFile(arrayBufferView, end_handler);
// 		} else {
// 			exception_handler(e);
// 		}
// 	};
// 	xhr.send();
// }

function getRealFileUrl(fileName) {
	let apiUrl = 'https://wiki.biligame.com/' + getWikiName() + '/Api.php?action=query&titles=File:' + fileName +
		'&prop=imageinfo&iiprop=url&format=json';
	let xhr = new XMLHttpRequest();
	xhr.open('GET', apiUrl, false);
	xhr.send();
	let response = JSON.parse(xhr.responseText);
	let pages = response.query.pages;
	for (let page in pages) {
		let imageinfo = pages[page].imageinfo;
		if (imageinfo) {
			return imageinfo[0].url;
		}
	}
	return null;
}

let parse_odt_text = async (odtpath, end_handler, exception_handler) => {
	try {
		let response = await fetch(odtpath, {
			method: 'GET', // or 'POST'
			credentials: 'same-origin', // include, *same-origin, omit
			mode: 'cors', // no-cors, *cors, same-origin
		});
		if (!response.ok) {
			throw new Error(`HTTP error! status: ${response.status}`);
		}
		let arrayBuffer = await response.arrayBuffer();
		let arrayBufferView = new Uint8Array(arrayBuffer);
		processOdtFile(arrayBufferView, end_handler);
	} catch (e) {
		exception_handler(e);
	}
}


function processOdtFile(data, end_handler) {
	JSZip.loadAsync(data).then(function(zip) {
		zip.forEach(function(relativePath, zipEntry) {
			// 'content.xml'
			if (!zipEntry.dir && relativePath === 'word/document.xml') {
				return zipEntry.async("string").then(function(textContent) {
					var parser = new DOMParser();
					var xmlDoc = parser.parseFromString(textContent, "text/xml");
					// xmlDoc.querySelectorAll("p")
					temp1 = xmlDoc.querySelectorAll("t");
					outtext = ""

					for (let i of temp1) {
						outtext += i.innerHTML + "\n"
					}
					// console.log(outtext)
					if (typeof end_handler == 'function')
						end_handler(outtext);
				});
			}
		});
	}).catch(function(error) {
		// console.log(outtext)
		if (typeof end_handler == 'function')
			end_handler(outtext);
	});
}

var skinmodels = {};
var background, render_type, modelScale, shadow_radius, suffix_obj, suffix_mtl, delimiter;
var nowModel;
var nowModelName;
var isBigScreen = false;

function reloadSkinSelect() {
	let s_s = document.querySelector("#skin-select");
	s_s.innerHTML = "";
	let c_v = document.querySelector("#character-select").selectedOptions[0].value;
	for (let i of skinmodels[c_v]) {
		s_s.innerHTML += '<option value ="' + i + '">' + i + '</option>';
	}
}

document.initDom = () => {
	let modelConfigHolder = document.querySelector(".model-info").dataset;
	render_type = modelConfigHolder.renderType;
	shadow_radius = modelConfigHolder.shadowRadius;
	suffix_obj = modelConfigHolder.suffixObj;
	suffix_mtl = modelConfigHolder.suffixMtl;
	delimiter = modelConfigHolder.delimiter;
	background = modelConfigHolder.background;
	modelScale = modelConfigHolder.modelScale;
	modelScale = parseFloat(modelScale) <= 0 ? 1 : parseFloat(modelScale);

	let infos = modelConfigHolder.list.split(modelConfigHolder.delimiterGroup);
	for (let i of infos) {
		let var0 = i.split(delimiter);
		if (var0.length == 2) {
			if (skinmodels[var0[0]]) {
				skinmodels[var0[0]].push(var0[1]);
			} else skinmodels[var0[0]] = [var0[1]]
		}
	}
	console.log(JSON.stringify(skinmodels));

	writeInDoc(`
	<div class='Model'>
	<div class='model-button'><input id='advanced_model' type="checkbox" >大屏模式</input></div>
	<div class='model-select' style='margin: 5px;'>选择角色：<select id='character-select' style='background: rgba(255,255,255,0.5);box-shadow: 2px 2px 8px #ddd;padding: 5px;border-radius: 5px;'></select>  选择皮肤：<select id='skin-select'  style='background: rgba(255,255,255,0.5);box-shadow: 2px 2px 8px #ddd;padding: 5px;border-radius: 5px;'></select></div>
	<div class='ModelConatainer'></div>
	</div>
	`);
	let c_s = document.querySelector("#character-select");
	for (let i of Object.keys(skinmodels)) {
		c_s.innerHTML += '<option value ="' + i + '">' + i + '</option>';
	}
	reloadSkinSelect();
	document.initTHREE();
	document.klbqModelLoad();
	$('#character-select').on("change", (e) => {
		reloadSkinSelect();
		document.klbqModelLoad();
	});
	$('#skin-select').on("change", (e) => {
		document.klbqModelLoad();
	});
	$('#advanced_model').on('change', (e) => {
		isBigScreen = !isBigScreen;
		// $('#advanced_model')[0].innerHTML=isBigScreen?'小屏模式':'大屏模式';
		window.dispatchEvent(new CustomEvent('resize'));
	});
}
// initDom();
var THREE, OrbitControls, MTLLoader, OBJLoader, OutlineEffect;
var camera, scene, renderer, effect;

function getWikiName() {
	return mw.config.values['wgGameName'];
}

function getPrePath() {
	let pre = '';
	if (typeof mw != 'undefined') {
		pre = mw.config.values['wgServer'] + mw.config.values['wgScriptPath'] + '/Special:FilePath/';
		// pre = mw.config.get('wgScriptPath') ;
	}
	return pre;
}

function isToon() {
	return render_type === "卡通";
}

var isdrag = false;
var isloadingmodel = false;

document.initTHREE = () => {
	THREE = document.THREE;
	OrbitControls = document.OrbitControls;
	MTLLoader = document.MTLLoader;
	OBJLoader = document.OBJLoader;
	OutlineEffect = document.OutlineEffect;
	init();
	animate();
	addShadow();



	document.querySelector('canvas').addEventListener('mouseup', (e) => {
		isdrag = false;
	})
	document.querySelector('canvas').addEventListener('mousedown', (e) => {
		isdrag = true;
		animate();
	})
	document.querySelector('canvas').addEventListener('mouseleave', (e) => {
		isdrag = false;
	})
	document.querySelector('canvas').addEventListener('wheel', (e) => {
		animate();
	})
	document.querySelector('canvas').addEventListener('touchstart', (e) => {
		isdrag = true;
		animate();
	})
	document.querySelector('canvas').addEventListener('touchmove', (e) => {
		// animate();
	})
	document.querySelector('canvas').addEventListener('touchend', (e) => {
		isdrag = false;
	})

	function init() {

		camera = new THREE.PerspectiveCamera(45, 0.8, 0.1, 20);
		camera.position.z = 2.25;
		document.tr = THREE;
		document.ca = camera;
		// camera.position.set(0, 10, 2.5) // 设置相机在三维坐标中的位置


		scene = new THREE.Scene();
		document.scene = scene;


		const ambientLight = new THREE.AmbientLight(0xffffff);
		scene.add(ambientLight);


		if (!isToon()) {
			const pointLight = new THREE.PointLight(0xffffff, 18);
			camera.add(pointLight);
			scene.add(camera);
		} else {
			const directionalLight = new THREE.DirectionalLight("#dedede", 3.2);
			directionalLight.position.set(0, 1, 2).normalize();
			scene.add(directionalLight);
		}
		renderer = new THREE.WebGLRenderer({
			antialias: true
		});
		// if (isToon()) {
		// 	effect = new OutlineEffect(renderer);
		// }


		// renderer.setSize(window.innerWidth, window.innerHeight);
		onWindowResize();
		// document.querySelector(".ModelConatainer").innerHTML = '';
		document.querySelector(".ModelConatainer").appendChild(renderer.domElement);
		// document.body.appendChild(renderer.domElement);
		// renderer.setClearColor(new THREE.Color("#8e804b"));

		if (background.startsWith("#")) {
			renderer.setClearColor(new THREE.Color(background));
		} else {
			const texture = new THREE.TextureLoader().load(getPrePath() + background);
			document.scene.background = texture;
		}
		// writeInDoc(renderer.domElement)
		//

		const controls = new OrbitControls(camera, renderer.domElement);
		controls.minDistance = 2;
		controls.maxDistance = 3.5;
		// controls.minPolarAngle = -Math.PI / 4;
		// controls.maxPolarAngle = Math.PI / 4;
		window.addEventListener('resize', onWindowResize);

	}

	function onWindowResize() {

		let col = document.querySelector('.ModelConatainer');
		let cilentWith = col.offsetWidth;
		let cilentHeight = col.offsetHeight;
		let width = cilentWith < 400 || isBigScreen ? cilentWith : 400;
		let height = isBigScreen ? 800 : 500;
		camera.aspect = width / height;
		camera.updateProjectionMatrix();
		// if (isToon())
		// 	effect.setSize(width, height);
		// else 
		renderer.setSize(width, height);
		renderer.setPixelRatio(isBigScreen ? window.devicePixelRatio : parseInt(window.devicePixelRatio * 1.6));
		// console.log(renderer)
		// console.log("窗口大小变化", window.innerWidth, window.innerHeight);
		requestAnimationFrame(animate);
	}

	//



	function addShadow() {
		shadow_radius = parseFloat(shadow_radius);
		shadow_radius = shadow_radius ? shadow_radius : 0.35;
		const shadowGeom = new THREE.CircleGeometry(0.35, 32);
		const shadowMat = new THREE.MeshBasicMaterial({
			color: 0x000000,
			transparent: true,
			opacity: 0.5,
			side: THREE.DoubleSide,
		});
		const shadowMesh = new THREE.Mesh(shadowGeom, shadowMat);
		shadowMesh.rotation.x = -Math.PI / 2
		scene.add(shadowMesh)
		shadowMesh.position.y = -0.87;
	}
}

var lastTime = new Date().getTime();
var nowtime = 0;
var repaintcount = 0;

function animate() {
	// if(repaintcount==0)document.ttsd=new Date().getTime();
	// console.log(isdrag,new Date().getTime()-document.ttsd,repaintcount)
	if (isdrag)
		requestAnimationFrame(animate);
	else if (isloadingmodel) {
		// // 由于没有提供相应的事件，只能指定100帧之后停止刷新
		// if (repaintcount > 100) {
		// 	isloadingmodel = false;
		// 	isdrag = false;
		// 	repaintcount = 0;

		// 	requestAnimationFrame(animate);
		// } else {
		// 	repaintcount++;
		// 	requestAnimationFrame(animate);
		// }
		// lastTime = nowtime;
		requestAnimationFrame(animate);
	}
	renderer.render(scene, camera);
}

document.klbqModelLoad = () => {

	// console.log(11, document.OrbitControls)

	let pre = getPrePath();

	let c_v = document.querySelector("#character-select").selectedOptions[0].value;
	let s_v = document.querySelector("#skin-select").selectedOptions[0].value;
	let newmodelName = c_v + delimiter + s_v
	if (nowModelName == newmodelName)
		return;
	else nowModelName = newmodelName;

	// p_model = pre + newmodelName + suffix_obj + '.docx'
	// p_material = pre + newmodelName + suffix_mtl + '.docx'
	p_model = getRealFileUrl(newmodelName + suffix_obj + '.docx');
	p_material = getRealFileUrl(newmodelName + suffix_mtl + '.docx');
	let handler2 = (e) => {
		if (nowModel)
			scene.remove(nowModel);
		// console.log(e);
		alert(e.target.statusText);

	};
	parse_odt_text(p_material, (mtl) => {
		materials = new MTLLoader().parse(mtl);

		console.log(materials);
		materials.preload();

		if (render_type === "卡通")
			for (let i of Object.keys(materials.materials)) {
				let new_material = new THREE.MeshToonMaterial({
					map: materials.materials[i].map,
					transparent: true,
					// transparent: materials.materials[i].transparent,
					opacity: materials.materials[i].opacity,
					side: THREE.DoubleSide
				});
				// new_material.userData.outlineParameters = {
				// 	thickness: 0.0006,
				// 	color: "#ffaa7f",
				// 	alpha: 1
				// };
				materials.materials[i] = new_material;

			}

		let handler1 = (modelInfo) => {
			obj = new OBJLoader()
				.setMaterials(materials)
				.parse(modelInfo);

			obj.position.y = -0.85;
			if (!isBigScreen) {
				if (modelScale < 1)
					obj.scale.setScalar(modelScale);
			} else obj.scale.setScalar(modelScale * 1.6);
			if (nowModel)
				scene.remove(nowModel);
			scene.add(obj);
			nowModel = obj;
			isloadingmodel = true;
			animate();
			// scene.onAfterRender = (e) => {
			// 	repaintcount++;
			// 	console.log(e,repaintcount)
			// 	// 这里需要设置为5是因为渲染第一次不完全，而且我们有两个物品。
			// 	if (repaintcount > 5)
			// 		scene.onAfterRender = () => {
			// 			repaintcount = 0;
			// 			isloadingmodel = false;

			// 		};
			// 	// console.log(new Date())
			// };
			// materials.onAfterRender = (e) => {
			// 	console.log(e,repaintcount)
			// };
			onAfterRender(obj, 0, 0, () => {
				isloadingmodel = false;
			})

		};

		parse_odt_text(p_model, handler1, handler2);

	}, handler2);
}


// 后面的代码来自网络
// https://blog.csdn.net/delongcpp/article/details/129681925

/**
 * 获取模型当前已渲染的贴图数
 * @param model       模型对象
 * @returns {number}  贴图数
 */
function getImageCount(model) {
	let iCount = 0

	model.traverse(item => {
		if (item instanceof THREE.Mesh) {
			if (Array.isArray(item.material)) {
				item.material.forEach(m => {
					if (m.map && m.map.image) {
						iCount++
					}
				})
			} else {
				if (item.material.map && item.material.map.image) {
					iCount++
				}
			}
		}
	})

	return iCount
}

/**
 *
 * @param model     模型对象
 * @param ic        贴图计数器
 * @param ec        重复次数
 * @param callback  回调函数
 */
function onAfterRender(model, ic, ec, callback) {
	const wait = 3

	let iCount = ic

	let equalCount = ec

	setTimeout(() => {
		const res = getImageCount(model)

		if (iCount === res) {
			if (equalCount === wait) {
				callback()
			} else {
				equalCount++
				onAfterRender(model, iCount, equalCount, callback)
			}
		} else {
			iCount = res
			equalCount = 0
			onAfterRender(model, iCount, equalCount, callback)
		}
	}, 100)
}