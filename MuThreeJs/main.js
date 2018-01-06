var g_scene, g_camera, g_renderer;

var g_plane;

function renderLoop() {
	requestAnimationFrame( renderLoop );
	g_renderer.render(g_scene, g_camera);
	
	// g_plane.rotation.y += 0.01;
}

window.onload = function() {
	$ = document.getElementById;
	g_scene = new THREE.Scene();
	g_camera = new THREE.PerspectiveCamera(
		75,                                     // fov
		window.innerWidth / window.innerHeight, // ratio
		0.1, 1000                               // zmin, zmax
	);
	g_renderer = new THREE.WebGLRenderer();
	g_renderer.setSize(window.innerWidth, window.innerHeight);
	
	document.body.appendChild(g_renderer.domElement);
	
	// geometry
	geometry = new THREE.PlaneGeometry(100, 100, 256, 256);
	for(y = 0; y != 256; ++y) {
		for(x = 0; x != 256; ++x) {
			geometry.vertices[257*y+x].z = g_height[y][x]/255 * 5;
			geometry.faces[(256*y+x)*2].materialIndex = g_textures[255-y][x];
			geometry.faces[(256*y+x)*2+1].materialIndex = g_textures[255-y][x];
		}
	}

	// materials
	var materials = [];
	materials.push(new THREE.MeshBasicMaterial({ map: THREE.ImageUtils.loadTexture('world0/TileGrass01.jpg')}));
	materials.push(new THREE.MeshBasicMaterial({ map: THREE.ImageUtils.loadTexture('world0/TileGrass02.jpg')}));
	materials.push(new THREE.MeshBasicMaterial({ map: THREE.ImageUtils.loadTexture('world0/TileGround01.jpg')}));
	materials.push(new THREE.MeshBasicMaterial({ map: THREE.ImageUtils.loadTexture('world0/TileGround02.jpg')}));
	materials.push(new THREE.MeshBasicMaterial({ map: THREE.ImageUtils.loadTexture('world0/TileGround03.jpg')}));
	materials.push(new THREE.MeshBasicMaterial({ map: THREE.ImageUtils.loadTexture('world0/TileWater01.jpg')}));
	materials.push(new THREE.MeshBasicMaterial({ map: THREE.ImageUtils.loadTexture('world0/TileWood01.jpg')}));
	materials.push(new THREE.MeshBasicMaterial({ map: THREE.ImageUtils.loadTexture('world0/TileRock01.jpg')}));
	materials.push(new THREE.MeshBasicMaterial({ map: THREE.ImageUtils.loadTexture('world0/TileRock02.jpg')}));
	materials.push(new THREE.MeshBasicMaterial({ map: THREE.ImageUtils.loadTexture('world0/TileRock03.jpg')}));
	materials.push(new THREE.MeshBasicMaterial({ map: THREE.ImageUtils.loadTexture('world0/TileRock04.jpg')}));
	materials.push(new THREE.MeshBasicMaterial({ map: THREE.ImageUtils.loadTexture('world0/TileRock05.jpg')}));
	materials.push(new THREE.MeshBasicMaterial({ map: THREE.ImageUtils.loadTexture('world0/TileRock06.jpg')}));
	materials.push(new THREE.MeshBasicMaterial({ map: THREE.ImageUtils.loadTexture('world0/TileRock07.jpg')}));

	// Add materialIndex to face
	var l = geometry.faces.length/2;
	var bok = Math.sqrt(geometry.faces.length/2);
	for (var i = 0; i < l; i++) {
			j = i*2;
			// geometry.faces[j].materialIndex = 0;
			// geometry.faces[j+1].materialIndex = 0;
			
			geometry.faceVertexUvs[0][j][0] = new THREE.Vector2(0.0, 1.0);
			geometry.faceVertexUvs[0][j][1] = new THREE.Vector2(0.0, 0.0)
			geometry.faceVertexUvs[0][j][2] = new THREE.Vector2(1.0, 1.0)
			
			geometry.faceVertexUvs[0][j+1][0] = new THREE.Vector2(0.0, 0.0)
			geometry.faceVertexUvs[0][j+1][1] = new THREE.Vector2(1.0, 0.0)
			geometry.faceVertexUvs[0][j+1][2] = new THREE.Vector2(1.0, 1.0)
	}
		
	// plane mesh
	g_plane = new THREE.Mesh( geometry, new THREE.MeshFaceMaterial(materials));
	g_plane.rotation.x = -Math.PI/2;
	g_plane.position.y = -10;
	// g_plane.rotation.y = Math.PI/8;
	g_scene.add(g_plane);
	
	document.body.onclick = function() {mouse.init(document.getElementsByTagName('canvas')[0]);};
	keyboard.init(window);
	renderLoop();
}