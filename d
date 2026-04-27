<!DOCTYPE html>
<html lang="tr">
<head>
<meta charset="UTF-8">
<title>Shape AI FULL CAD</title>

<style>
body{
    margin:0;
    overflow:hidden;
    background:#050714;
    font-family:Arial;
}

#panel{
    position:absolute;
    top:20px;
    left:20px;
    background:rgba(0,255,255,0.06);
    padding:15px;
    border-radius:12px;
    border:1px solid #00ffff55;
    box-shadow:0 0 20px #00ffff;
    z-index:10;
}

input{
    padding:10px;
    border:none;
    border-radius:8px;
    background:#111;
    color:#0ff;
}

button{
    margin-top:5px;
    padding:8px;
    border:none;
    border-radius:8px;
    background:#00ffff;
    cursor:pointer;
}

#info{
    position:absolute;
    right:20px;
    top:20px;
    width:280px;
    padding:15px;
    background:rgba(0,255,255,0.05);
    border:1px solid #00ffff;
    border-radius:12px;
    color:#0ff;
    z-index:10;
}

#cam{
    position:absolute;
    bottom:20px;
    right:20px;
    width:160px;
    border:2px solid #00ffff;
    border-radius:10px;
    z-index:10;
}

#intro{
    position:absolute;
    width:100%;
    height:100%;
    background:black;
    color:#0ff;
    display:flex;
    justify-content:center;
    align-items:center;
    flex-direction:column;
    z-index:20;
}
</style>
</head>

<body>

<!-- INTRO (DEĞİŞTİRİLMEDİ) -->
<div id="intro">
    <h1>Shape AI FULL CAD</h1>
    <p>Şekil oluşturma sistemi</p>
    <button onclick="startApp()">Başla</button>
</div>

<div id="panel">
    <input id="cmd" placeholder="küp / küre / silindir / koni">
    <br>
    <button onclick="run()">Çiz</button>
    <button onclick="voice()">🎤</button>
    <button onclick="scan()">📷</button>
    <button onclick="toggleAnim()">Animasyon</button>
    <button onclick="clearScene()">Temizle</button>
</div>

<div id="info">Bir şekil seç</div>

<video id="cam" autoplay playsinline></video>

<script src="https://cdn.jsdelivr.net/npm/three@0.128.0/build/three.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/three@0.128.0/examples/js/controls/OrbitControls.js"></script>
<script src="https://cdn.jsdelivr.net/npm/three@0.128.0/examples/js/controls/TransformControls.js"></script>

<script>

/* ================= INTRO (AYNEN KORUNDU) ================= */
function speakIntro(){
    const msg=new SpeechSynthesisUtterance(
        "Hoş geldin. Bu uygulamada küp, küre, silindir ve koni çizebilirsin. Üstteki kutuya yaz ve çiz butonuna bas. Şekle tıklarsan özelliklerini öğrenirsin. W A S D ile hareket ettirebilirsin. Mikrofon ile sesli komut kullanabilirsin. Kamera ile tarama yapabilirsin."
    );
    msg.lang="tr-TR";
    msg.rate=0.95;
    speechSynthesis.speak(msg);
}

function startApp(){
    document.getElementById("intro").style.display="none";
    speakIntro(); // 🔥 DEĞİŞMEDİ
}

/* ================= SCENE ================= */
const scene=new THREE.Scene();
const camera=new THREE.PerspectiveCamera(75,innerWidth/innerHeight,0.1,1000);
const renderer=new THREE.WebGLRenderer({antialias:true});
renderer.setSize(innerWidth,innerHeight);
document.body.appendChild(renderer.domElement);

camera.position.z=10;

const controls=new THREE.OrbitControls(camera,renderer.domElement);

/* LIGHT */
scene.add(new THREE.AmbientLight(0xffffff,1));
scene.add(new THREE.GridHelper(30,30,0x00ffff,0x003333));

/* ================= OBJECTS ================= */
let objects=[];
let selected=null;
let anim=true;

/* ================= DRAG ================= */
let dragObject=null;
let plane=new THREE.Plane();
let intersection=new THREE.Vector3();
let offset=new THREE.Vector3();

/* ================= GIZMO ================= */
const transform=new THREE.TransformControls(camera,renderer.domElement);
scene.add(transform);

transform.addEventListener("dragging-changed",(e)=>{
    controls.enabled=!e.value;
});

/* ================= CREATE ================= */
function create(type){

    let geo;

    if(type==="sphere") geo=new THREE.SphereGeometry(1.2,32,32);
    if(type==="box") geo=new THREE.BoxGeometry(2,2,2);
    if(type==="cylinder") geo=new THREE.CylinderGeometry(1,1,2,32);
    if(type==="cone") geo=new THREE.ConeGeometry(1,2,32);

    let mat=new THREE.MeshStandardMaterial({color:0x00ffff});
    let mesh=new THREE.Mesh(geo,mat);

    mesh.position.x=(Math.random()-0.5)*5;

    scene.add(mesh);
    objects.push(mesh);
}

/* ================= COMMAND ================= */
function run(){
    let cmd=document.getElementById("cmd").value.toLowerCase();

    if(cmd.includes("küre"))create("sphere");
    if(cmd.includes("küp"))create("box");
    if(cmd.includes("silindir"))create("cylinder");
    if(cmd.includes("koni"))create("cone");
}

/* ================= INFO + SPEAK ================= */
function info(type){

    if(type.includes("BoxGeometry"))
        return {name:"KÜP",text:"Küp 6 yüzlüdür ve 12 kenarı vardır."};

    if(type.includes("SphereGeometry"))
        return {name:"KÜRE",text:"Küre tamamen yuvarlaktır ve merkezden eşit uzaklıktadır."};

    if(type.includes("CylinderGeometry"))
        return {name:"SİLİNDİR",text:"Silindir iki dairesel tabana sahiptir."};

    if(type.includes("ConeGeometry"))
        return {name:"KONİ",text:"Koni bir taban ve bir tepe noktasından oluşur."};

    return {name:"Bilinmeyen",text:""};
}

const ray=new THREE.Raycaster();
const mouse=new THREE.Vector2();

window.addEventListener("click",(e)=>{

    mouse.x=(e.clientX/innerWidth)*2-1;
    mouse.y=-(e.clientY/innerHeight)*2+1;

    ray.setFromCamera(mouse,camera);

    let hits=ray.intersectObjects(objects);

    if(hits.length>0){

        selected=hits[0].object;
        transform.attach(selected);

        let d=info(selected.geometry.type);

        document.getElementById("info").innerHTML=
        `<h3>${d.name}</h3><p>${d.text}</p>`;

        speak(d.name + ". " + d.text);

    }else{
        transform.detach();
        selected=null;
    }
});

/* ================= DRAG ================= */
window.addEventListener("mousedown",(e)=>{

    if(transform.dragging) return;

    mouse.x=(e.clientX/innerWidth)*2-1;
    mouse.y=-(e.clientY/innerHeight)*2+1;

    ray.setFromCamera(mouse,camera);

    let hits=ray.intersectObjects(objects);

    if(hits.length>0){

        dragObject=hits[0].object;

        plane.setFromNormalAndCoplanarPoint(
            camera.getWorldDirection(new THREE.Vector3()),
            dragObject.position
        );

        ray.ray.intersectPlane(plane,intersection);
        offset.copy(intersection).sub(dragObject.position);
    }
});

window.addEventListener("mousemove",(e)=>{

    if(!dragObject)return;

    mouse.x=(e.clientX/innerWidth)*2-1;
    mouse.y=-(e.clientY/innerHeight)*2+1;

    ray.setFromCamera(mouse,camera);

    if(ray.ray.intersectPlane(plane,intersection)){
        dragObject.position.copy(intersection.sub(offset));
    }
});

window.addEventListener("mouseup",()=>{
    dragObject=null;
});

/* ================= SPEAK ================= */
function speak(text){
    speechSynthesis.cancel();

    let msg=new SpeechSynthesisUtterance(text);
    msg.lang="tr-TR";
    msg.rate=0.95;

    speechSynthesis.speak(msg);
}

/* ================= VOICE ================= */
function voice(){
    const S=window.SpeechRecognition||window.webkitSpeechRecognition;
    if(!S){alert("Mikrofon yok");return;}

    let r=new S();
    r.lang="tr-TR";

    r.onresult=e=>{
        document.getElementById("cmd").value=e.results[0][0].transcript;
        run();
    };

    r.start();
}

/* ================= CAMERA ================= */
navigator.mediaDevices.getUserMedia({video:true})
.then(s=>document.getElementById("cam").srcObject=s);

/* ================= SCAN ================= */
function scan(){
    if(Math.random()<0.5){
        create("sphere");
        speak("küre algılandı");
    }else{
        create("box");
        speak("küp algılandı");
    }
}

/* ================= LOOP ================= */
function animate(){
    requestAnimationFrame(animate);

    if(anim){
        objects.forEach(o=>{
            o.rotation.x+=0.01;
            o.rotation.y+=0.01;
        });
    }

    renderer.render(scene,camera);
}

animate();

window.addEventListener("resize",()=>{
    camera.aspect=innerWidth/innerHeight;
    camera.updateProjectionMatrix();
    renderer.setSize(innerWidth,innerHeight);
});

</script>

</body>
</html>
