var keyboard = {
	init: function(e) {
		e.onkeydown = keyboard.keydown;
		e.onkeyup = keyboard.keyup;
		
		setInterval(keyboard.process, 10);
	},
	
	process: function() {
		var sin = Math.sin(g_camera.rotation.y);
		var cos = Math.cos(g_camera.rotation.y);
		if(keyboard.keys.w) {
			g_camera.position.x -= 0.1 * sin;
			g_camera.position.z -= 0.1 * cos;
			// TODO: fly - y
		}
		if(keyboard.keys.s) {
			g_camera.position.x += 0.1 * sin;
			g_camera.position.z += 0.1 * cos;
		}
		if(keyboard.keys.a) {
			g_camera.position.x -= 0.1 * cos;
			g_camera.position.z += 0.1 * sin;
		}
		if(keyboard.keys.d) {
			g_camera.position.x += 0.1 * cos;
			g_camera.position.z -= 0.1 * sin;
		}
		if(keyboard.keys.space)
			g_camera.position.y += 0.1;
		if(keyboard.keys.ctrl)
			g_camera.position.y -= 0.1;
	},
	
	keydown: function(e) {
		var pressed = 1;
		switch(e.keyCode) {
			case 17:
				keyboard.keys.ctrl = 1;
				break;
			case 32:
				keyboard.keys.space = 1;
				break;
			case 65:
				keyboard.keys.a = 1;
				break;
			case 68:
				keyboard.keys.d = 1;
				break;
			case 83:
				keyboard.keys.s = 1;
				break;
			case 87:
				keyboard.keys.w = 1;
				break;
			default:
				pressed = 0;
				// $('keyCode').innerHTML = e.keyCode;
		}
		if(pressed)
			return false;
	},
	
	keyup: function(e) {
		var pressed = 1;
		switch(e.keyCode) {
			case 17:
				keyboard.keys.ctrl = 0;
				break;
			case 32:
				keyboard.keys.space = 0;
				break;
			case 65:
				keyboard.keys.a = 0;
				break;
			case 68:
				keyboard.keys.d = 0;
				break;
			case 83:
				keyboard.keys.s = 0;
				break;
			case 87:
				keyboard.keys.w = 0;
				break;
			default:
				pressed = 0;
				// $('keyCode').innerHTML = e.keyCode;
		}
		if(pressed)
			return false;
	},
	
	keys: {}
};

var mouse = {
	element: null,
	
	init: function(e) {
		if(document.pointerLockElement || document.mozPointerLockElement)
			return;
		mouse.element = e;
		e.requestPointerLock = e.requestPointerLock || e.mozRequestPointerLock;
		document = document.onpointerlockerror = document.onmozpointerlockerror = mouse.hookRetry;
		e.onmousemove = mouse.process;
		e.requestPointerLock();
	},
	
	hookRetry: function() {
		console.log('err ' + document.mozPointerLockElement);
		// mouse.element.requestPointerLock();
	},
	
	process: function(evt) {
		var dx = evt.movementY || evt.mozMovementY;
		var dy = evt.movementX || evt.mozMovementX;
		
		var dAngX = Math.PI/2*(dx/mouse.element.height);
		var dAngY = Math.PI/2*(dy/mouse.element.width);
		
		// g_camera.rotation.x += 0.0.1;
		// g_camera.rotation.y = (g_camera.rotation.y + dAngY) % (Math.PI*2);
		// console.log(mouse.element.height);
		g_camera.rotation.order = "YXZ";
		g_camera.rotation.y -= dAngY;
		g_camera.rotation.x -= dAngX;
		// $('dx').innerHTML = g_camera.rot.x;
		// $('dy').innerHTML = g_camera.rot.y;
	}
}