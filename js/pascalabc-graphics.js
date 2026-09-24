function colorToRgba(value) {
  const argb = Number(value) >>> 0;
  return [((argb >>> 16) & 255) / 255, ((argb >>> 8) & 255) / 255, (argb & 255) / 255, ((argb >>> 24) & 255) / 255];
}

function colorToCss(value) {
  const [red, green, blue, alpha] = colorToRgba(value);
  return `rgba(${red * 255}, ${green * 255}, ${blue * 255}, ${alpha})`;
}

function applyStroke(context, command) {
  context.strokeStyle = colorToCss(command.strokeColor ?? command.color);
  context.lineWidth = Math.max(.1, Number(command.lineWidth) || 1);
  context.lineCap = "round";
  context.lineJoin = "round";
}

function applyFill(context, command) {
  context.fillStyle = colorToCss(command.fillColor ?? command.color);
}

export class CanvasGraphicsRenderer {
  constructor(canvas, options = {}) {
    if (!(canvas instanceof HTMLCanvasElement))
      throw new TypeError("CanvasGraphicsRenderer requires an HTMLCanvasElement.");
    this.canvas = canvas;
    this.options = options;
    this.context = canvas.getContext("2d", { alpha: true });
    if (!this.context) throw new Error("Canvas 2D is unavailable in this browser.");
    this.executionId = null;
    this.logicalWidth = canvas.width || 800;
    this.logicalHeight = canvas.height || 500;
  }

  handle(envelope) {
    if (!envelope || envelope.protocol !== 1 || !envelope.command) return;
    const command = envelope.command;
    if (command.renderer && command.renderer !== "canvas2d") return;
    if (command.op === "open" || envelope.executionId !== this.executionId) {
      this.executionId = envelope.executionId;
      if (command.op !== "open") this.#resize(this.logicalWidth, this.logicalHeight);
    }
    switch (command.op) {
      case "open":
        this.#resize(command.width, command.height);
        this.canvas.hidden = false;
        this.canvas.dispatchEvent(new CustomEvent("pascalabcgraphicsopen", { detail: command }));
        this.options.onOpen?.(command);
        break;
      case "resize": this.#resize(command.width, command.height); break;
      case "title": this.options.onTitle?.(command.title); break;
      case "clear":
        this.context.save();
        this.context.setTransform(1, 0, 0, 1, 0, 0);
        this.context.fillStyle = colorToCss(command.color);
        this.context.fillRect(0, 0, this.canvas.width, this.canvas.height);
        this.context.restore();
        break;
      case "line":
        applyStroke(this.context, command);
        this.context.beginPath();
        this.context.moveTo(command.x1, command.y1);
        this.context.lineTo(command.x2, command.y2);
        this.context.stroke();
        break;
      case "rectangle":
        if (command.fill) { applyFill(this.context, command); this.context.fillRect(command.x, command.y, command.width, command.height); }
        if (command.stroke) { applyStroke(this.context, command); this.context.strokeRect(command.x, command.y, command.width, command.height); }
        break;
      case "ellipse":
        this.context.beginPath();
        this.context.ellipse(command.x, command.y, Math.abs(command.radiusX), Math.abs(command.radiusY), 0, 0, Math.PI * 2);
        if (command.fill) { applyFill(this.context, command); this.context.fill(); }
        if (command.stroke) { applyStroke(this.context, command); this.context.stroke(); }
        break;
      case "arc": this.#drawArc(command); break;
      case "polygon": this.#drawPolygon(command); break;
      case "text": this.#drawText(command); break;
    }
  }

  clear() { this.context.clearRect(0, 0, this.logicalWidth, this.logicalHeight); }
  dispose() {}

  #resize(width, height) {
    this.logicalWidth = Math.max(1, Math.round(Number(width) || 800));
    this.logicalHeight = Math.max(1, Math.round(Number(height) || 500));
    const scale = Math.max(1, Math.min(2, globalThis.devicePixelRatio || 1));
    this.canvas.width = Math.round(this.logicalWidth * scale);
    this.canvas.height = Math.round(this.logicalHeight * scale);
    this.canvas.style.aspectRatio = `${this.logicalWidth} / ${this.logicalHeight}`;
    this.context.setTransform(scale, 0, 0, scale, 0, 0);
  }

  #drawArc(command) {
    const start = -Number(command.startAngle) * Math.PI / 180;
    const end = -Number(command.endAngle) * Math.PI / 180;
    this.context.beginPath();
    if (command.sector) this.context.moveTo(command.x, command.y);
    this.context.arc(command.x, command.y, Math.abs(command.radius), start, end, true);
    if (command.sector) this.context.closePath();
    if (command.fill) { applyFill(this.context, command); this.context.fill(); }
    if (command.stroke) { applyStroke(this.context, command); this.context.stroke(); }
  }

  #drawPolygon(command) {
    const coordinates = command.coordinates ?? [];
    if (coordinates.length < 4) return;
    this.context.beginPath();
    this.context.moveTo(coordinates[0], coordinates[1]);
    for (let index = 2; index + 1 < coordinates.length; index += 2)
      this.context.lineTo(coordinates[index], coordinates[index + 1]);
    if (command.fill) this.context.closePath();
    if (command.fill) { applyFill(this.context, command); this.context.fill(); }
    if (command.stroke) { applyStroke(this.context, command); this.context.stroke(); }
  }

  #drawText(command) {
    const [horizontal = "left", vertical = "top"] = String(command.alignment || "left-top").split("-");
    const fontStyle = command.fontStyle === "bold-italic" ? "italic 700"
      : command.fontStyle === "bold" ? "700" : command.fontStyle === "italic" ? "italic" : "normal";
    this.context.save();
    this.context.translate(command.x, command.y);
    this.context.rotate(-Number(command.angle || 0) * Math.PI / 180);
    this.context.fillStyle = colorToCss(command.color);
    this.context.font = `${fontStyle} ${Math.max(1, Number(command.fontSize) || 14)}px ${JSON.stringify(command.fontFamily || "Arial")}`;
    this.context.textAlign = horizontal === "center" ? "center" : horizontal === "right" ? "right" : "left";
    this.context.textBaseline = vertical === "center" ? "middle" : vertical === "bottom" ? "bottom" : "top";
    this.context.fillText(String(command.text ?? ""), 0, 0);
    this.context.restore();
  }
}

const identity = () => new Float32Array([1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]);

function multiply(a, b) {
  const out = new Float32Array(16);
  for (let column = 0; column < 4; column++)
    for (let row = 0; row < 4; row++)
      for (let index = 0; index < 4; index++)
        out[column * 4 + row] += a[index * 4 + row] * b[column * 4 + index];
  return out;
}

function translation(x, y, z) {
  const out = identity(); out[12] = x; out[13] = y; out[14] = z; return out;
}

function scaling(x, y, z) {
  const out = identity(); out[0] = x; out[5] = y; out[10] = z; return out;
}

function rotation(axisX, axisY, axisZ, angle) {
  const length = Math.hypot(axisX, axisY, axisZ) || 1;
  const x = axisX / length, y = axisY / length, z = axisZ / length;
  const radians = angle * Math.PI / 180, c = Math.cos(radians), s = Math.sin(radians), t = 1 - c;
  return new Float32Array([
    x * x * t + c, y * x * t + z * s, z * x * t - y * s, 0,
    x * y * t - z * s, y * y * t + c, z * y * t + x * s, 0,
    x * z * t + y * s, y * z * t - x * s, z * z * t + c, 0,
    0, 0, 0, 1
  ]);
}

function perspective(fov, aspect, near, far) {
  const f = 1 / Math.tan(fov / 2), range = 1 / (near - far), out = new Float32Array(16);
  out[0] = f / aspect; out[5] = f; out[10] = (far + near) * range; out[11] = -1; out[14] = 2 * far * near * range;
  return out;
}

function normalize([x, y, z]) {
  const length = Math.hypot(x, y, z) || 1; return [x / length, y / length, z / length];
}

function cross([ax, ay, az], [bx, by, bz]) {
  return [ay * bz - az * by, az * bx - ax * bz, ax * by - ay * bx];
}

function lookAt(eye, target, up) {
  const z = normalize([eye[0] - target[0], eye[1] - target[1], eye[2] - target[2]]);
  const x = normalize(cross(up, z)), y = cross(z, x);
  return new Float32Array([
    x[0], y[0], z[0], 0, x[1], y[1], z[1], 0, x[2], y[2], z[2], 0,
    -(x[0] * eye[0] + x[1] * eye[1] + x[2] * eye[2]),
    -(y[0] * eye[0] + y[1] * eye[1] + y[2] * eye[2]),
    -(z[0] * eye[0] + z[1] * eye[1] + z[2] * eye[2]), 1
  ]);
}

function pushVertex(data, position, normal) { data.push(...position, ...normal); }

function cubeGeometry() {
  const data = [], faces = [
    [[1, 0, 0], [[.5, -.5, -.5], [.5, .5, -.5], [.5, .5, .5], [.5, -.5, .5]]],
    [[-1, 0, 0], [[-.5, .5, -.5], [-.5, -.5, -.5], [-.5, -.5, .5], [-.5, .5, .5]]],
    [[0, 1, 0], [[-.5, .5, -.5], [.5, .5, -.5], [.5, .5, .5], [-.5, .5, .5]]],
    [[0, -1, 0], [[.5, -.5, -.5], [-.5, -.5, -.5], [-.5, -.5, .5], [.5, -.5, .5]]],
    [[0, 0, 1], [[-.5, -.5, .5], [.5, -.5, .5], [.5, .5, .5], [-.5, .5, .5]]],
    [[0, 0, -1], [[-.5, .5, -.5], [.5, .5, -.5], [.5, -.5, -.5], [-.5, -.5, -.5]]]
  ];
  for (const [normal, corners] of faces)
    for (const index of [0, 1, 2, 0, 2, 3]) pushVertex(data, corners[index], normal);
  return data;
}

function sphereGeometry(latitudeBands = 18, longitudeBands = 28) {
  const data = [];
  const point = (latitude, longitude) => {
    const phi = latitude * Math.PI / latitudeBands - Math.PI / 2;
    const theta = longitude * Math.PI * 2 / longitudeBands;
    const normal = [Math.cos(phi) * Math.cos(theta), Math.cos(phi) * Math.sin(theta), Math.sin(phi)];
    return { position: normal.map(value => value * .5), normal };
  };
  for (let latitude = 0; latitude < latitudeBands; latitude++)
    for (let longitude = 0; longitude < longitudeBands; longitude++) {
      const vertices = [point(latitude, longitude), point(latitude + 1, longitude), point(latitude + 1, longitude + 1), point(latitude, longitude + 1)];
      for (const index of [0, 1, 2, 0, 2, 3]) pushVertex(data, vertices[index].position, vertices[index].normal);
    }
  return data;
}

function cylinderGeometry(topScale = 1, segments = 32) {
  const data = [], bottomRadius = .5, topRadius = .5 * Math.max(0, topScale);
  for (let index = 0; index < segments; index++) {
    const a = index * Math.PI * 2 / segments, b = (index + 1) * Math.PI * 2 / segments;
    const sideNormalA = normalize([Math.cos(a), Math.sin(a), bottomRadius - topRadius]);
    const sideNormalB = normalize([Math.cos(b), Math.sin(b), bottomRadius - topRadius]);
    const ba = [bottomRadius * Math.cos(a), bottomRadius * Math.sin(a), -.5];
    const bb = [bottomRadius * Math.cos(b), bottomRadius * Math.sin(b), -.5];
    const ta = [topRadius * Math.cos(a), topRadius * Math.sin(a), .5];
    const tb = [topRadius * Math.cos(b), topRadius * Math.sin(b), .5];
    for (const [position, normal] of [[ba, sideNormalA], [bb, sideNormalB], [tb, sideNormalB], [ba, sideNormalA], [tb, sideNormalB], [ta, sideNormalA]])
      pushVertex(data, position, normal);
    for (const position of [[0, 0, -.5], bb, ba]) pushVertex(data, position, [0, 0, -1]);
    if (topRadius > 0) for (const position of [[0, 0, .5], ta, tb]) pushVertex(data, position, [0, 0, 1]);
  }
  return data;
}

function lineGeometry(points) {
  const data = []; for (const point of points) pushVertex(data, point, [0, 0, 0]); return data;
}

function createProgram(gl, vertexSource, fragmentSource) {
  const compile = (type, source) => {
    const shader = gl.createShader(type); gl.shaderSource(shader, source); gl.compileShader(shader);
    if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) throw new Error(gl.getShaderInfoLog(shader));
    return shader;
  };
  const program = gl.createProgram();
  gl.attachShader(program, compile(gl.VERTEX_SHADER, vertexSource));
  gl.attachShader(program, compile(gl.FRAGMENT_SHADER, fragmentSource));
  gl.linkProgram(program);
  if (!gl.getProgramParameter(program, gl.LINK_STATUS)) throw new Error(gl.getProgramInfoLog(program));
  return program;
}

export class WebGLGraphicsRenderer {
  constructor(canvas, options = {}) {
    this.canvas = canvas;
    this.options = options;
    this.gl = canvas.getContext("webgl2", { antialias: true, alpha: false, preserveDrawingBuffer: true });
    if (!this.gl) throw new Error("WebGL 2 is unavailable in this browser.");
    this.executionId = null;
    this.logicalWidth = canvas.width || 800;
    this.logicalHeight = canvas.height || 500;
    this.background = colorToRgba(0xff101827);
    this.objects = new Map(); this.meshes = new Map();
    this.showGrid = true; this.showAxes = true;
    this.eye = [9, -11, 8]; this.target = [0, 0, 0]; this.renderPending = false;
    this.#initializeGl(); this.#initializeInteraction(); this.#updateOrbit();
  }

  #initializeGl() {
    const gl = this.gl;
    this.program = createProgram(gl, `#version 300 es
      in vec3 aPosition; in vec3 aNormal; uniform mat4 uModel; uniform mat4 uViewProjection; out vec3 vNormal;
      void main() { gl_Position = uViewProjection * uModel * vec4(aPosition, 1.0); vNormal = mat3(uModel) * aNormal; }`,
    `#version 300 es
      precision highp float; in vec3 vNormal; uniform vec4 uColor; uniform bool uUnlit; out vec4 outColor;
      void main() { float light = uUnlit ? 1.0 : 0.28 + 0.72 * max(dot(normalize(vNormal), normalize(vec3(0.35, -0.45, 0.82))), 0.0); outColor = vec4(uColor.rgb * light, uColor.a); }`);
    this.locations = {
      position: gl.getAttribLocation(this.program, "aPosition"), normal: gl.getAttribLocation(this.program, "aNormal"),
      model: gl.getUniformLocation(this.program, "uModel"), viewProjection: gl.getUniformLocation(this.program, "uViewProjection"),
      color: gl.getUniformLocation(this.program, "uColor"), unlit: gl.getUniformLocation(this.program, "uUnlit")
    };
    gl.enable(gl.DEPTH_TEST); gl.enable(gl.CULL_FACE);
  }

  #initializeInteraction() {
    let dragging = false, lastX = 0, lastY = 0;
    this.pointerDown = event => { dragging = true; lastX = event.clientX; lastY = event.clientY; this.canvas.setPointerCapture?.(event.pointerId); };
    this.pointerMove = event => {
      if (!dragging) return;
      this.yaw -= (event.clientX - lastX) * .008;
      this.pitch = Math.max(-1.45, Math.min(1.45, this.pitch + (event.clientY - lastY) * .008));
      lastX = event.clientX; lastY = event.clientY; this.#applyOrbit(); this.#scheduleRender();
    };
    this.pointerUp = () => { dragging = false; };
    this.wheel = event => { event.preventDefault(); this.distance = Math.max(.5, Math.min(200, this.distance * Math.exp(event.deltaY * .001))); this.#applyOrbit(); this.#scheduleRender(); };
    this.canvas.addEventListener("pointerdown", this.pointerDown);
    this.canvas.addEventListener("pointermove", this.pointerMove);
    this.canvas.addEventListener("pointerup", this.pointerUp);
    this.canvas.addEventListener("pointercancel", this.pointerUp);
    this.canvas.addEventListener("wheel", this.wheel, { passive: false });
  }

  handle(envelope) {
    if (!envelope || envelope.protocol !== 1 || !envelope.command) return;
    const command = envelope.command;
    if (command.renderer && command.renderer !== "webgl2") return;
    if (command.op === "open" || envelope.executionId !== this.executionId) { this.executionId = envelope.executionId; this.objects.clear(); }
    switch (command.op) {
      case "open":
        this.background = colorToRgba(command.backgroundColor); this.#resize(command.width, command.height);
        this.canvas.hidden = false;
        this.canvas.dispatchEvent(new CustomEvent("pascalabcgraphicsopen", { detail: command }));
        this.options.onOpen?.(command);
        break;
      case "resize": this.#resize(command.width, command.height); break;
      case "title": this.options.onTitle?.(command.title); break;
      case "create3d": this.objects.set(command.id, {
        mesh: this.#mesh(command.shape, command.topScale), position: [command.x, command.y, command.z],
        size: [command.sizeX, command.sizeY, command.sizeZ], rotation: identity(), scale: [1, 1, 1], color: colorToRgba(command.color)
      }); break;
      case "move3d": { const object = this.objects.get(command.id); if (object) object.position = [command.x, command.y, command.z]; break; }
      case "scale3d": { const object = this.objects.get(command.id); if (object) object.scale = object.scale.map((value, index) => value * [command.x, command.y, command.z][index]); break; }
      case "rotate3d": { const object = this.objects.get(command.id); if (object) object.rotation = multiply(object.rotation, rotation(command.axisX, command.axisY, command.axisZ, command.angle)); break; }
      case "color3d": { const object = this.objects.get(command.id); if (object) object.color = colorToRgba(command.color); break; }
      case "remove3d": this.objects.delete(command.id); break;
      case "view3d": this.showGrid = command.showGrid; this.showAxes = command.showAxes; this.background = colorToRgba(command.backgroundColor); break;
      case "camera3d": this.eye = [command.x, command.y, command.z]; this.target = [command.targetX, command.targetY, command.targetZ]; this.#updateOrbit(); break;
    }
    this.#scheduleRender();
  }

  clear() { this.objects.clear(); this.#scheduleRender(); }

  dispose() {
    this.canvas.removeEventListener("pointerdown", this.pointerDown); this.canvas.removeEventListener("pointermove", this.pointerMove);
    this.canvas.removeEventListener("pointerup", this.pointerUp); this.canvas.removeEventListener("pointercancel", this.pointerUp);
    this.canvas.removeEventListener("wheel", this.wheel);
  }

  #uploadMesh(key, data, mode) {
    if (this.meshes.has(key)) return this.meshes.get(key);
    const gl = this.gl, vao = gl.createVertexArray(), buffer = gl.createBuffer();
    gl.bindVertexArray(vao); gl.bindBuffer(gl.ARRAY_BUFFER, buffer); gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(data), gl.STATIC_DRAW);
    gl.enableVertexAttribArray(this.locations.position); gl.vertexAttribPointer(this.locations.position, 3, gl.FLOAT, false, 24, 0);
    gl.enableVertexAttribArray(this.locations.normal); gl.vertexAttribPointer(this.locations.normal, 3, gl.FLOAT, false, 24, 12);
    const mesh = { vao, count: data.length / 6, mode }; this.meshes.set(key, mesh); return mesh;
  }

  #mesh(shape, topScale = 1) {
    const key = shape === "cylinder" ? `${shape}:${Number(topScale).toFixed(5)}` : shape;
    const data = shape === "sphere" ? sphereGeometry() : shape === "cylinder" ? cylinderGeometry(topScale) : cubeGeometry();
    return this.#uploadMesh(key, data, this.gl.TRIANGLES);
  }

  #helperMesh(key, points) { return this.#uploadMesh(key, lineGeometry(points), this.gl.LINES); }

  #resize(width, height) {
    this.logicalWidth = Math.max(1, Math.round(Number(width) || 800));
    this.logicalHeight = Math.max(1, Math.round(Number(height) || 500));
    const scale = Math.max(1, Math.min(2, globalThis.devicePixelRatio || 1));
    this.canvas.width = Math.round(this.logicalWidth * scale); this.canvas.height = Math.round(this.logicalHeight * scale);
    this.canvas.style.aspectRatio = `${this.logicalWidth} / ${this.logicalHeight}`;
    this.gl.viewport(0, 0, this.canvas.width, this.canvas.height); this.#scheduleRender();
  }

  #updateOrbit() {
    const dx = this.eye[0] - this.target[0], dy = this.eye[1] - this.target[1], dz = this.eye[2] - this.target[2];
    this.distance = Math.max(.5, Math.hypot(dx, dy, dz)); this.yaw = Math.atan2(dy, dx); this.pitch = Math.asin(dz / this.distance);
  }

  #applyOrbit() {
    const horizontal = this.distance * Math.cos(this.pitch);
    this.eye = [this.target[0] + horizontal * Math.cos(this.yaw), this.target[1] + horizontal * Math.sin(this.yaw), this.target[2] + this.distance * Math.sin(this.pitch)];
  }

  #scheduleRender() {
    if (this.renderPending) return;
    this.renderPending = true; requestAnimationFrame(() => { this.renderPending = false; this.#render(); });
  }

  #draw(mesh, model, color, unlit, viewProjection) {
    const gl = this.gl; gl.bindVertexArray(mesh.vao);
    gl.uniformMatrix4fv(this.locations.model, false, model); gl.uniformMatrix4fv(this.locations.viewProjection, false, viewProjection);
    gl.uniform4fv(this.locations.color, color); gl.uniform1i(this.locations.unlit, unlit ? 1 : 0); gl.drawArrays(mesh.mode, 0, mesh.count);
  }

  #render() {
    const gl = this.gl; gl.clearColor(...this.background); gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT); gl.useProgram(this.program);
    const viewProjection = multiply(perspective(Math.PI / 4, this.canvas.width / this.canvas.height, .05, 1000), lookAt(this.eye, this.target, [0, 0, 1]));
    if (this.showGrid) {
      const points = []; for (let n = -10; n <= 10; n++) points.push([-10, n, 0], [10, n, 0], [n, -10, 0], [n, 10, 0]);
      this.#draw(this.#helperMesh("grid", points), identity(), [.28, .36, .48, 1], true, viewProjection);
    }
    if (this.showAxes)
      this.#draw(this.#helperMesh("axes", [[0, 0, 0], [3, 0, 0], [0, 0, 0], [0, 3, 0], [0, 0, 0], [0, 0, 3]]), identity(), [.95, .48, .28, 1], true, viewProjection);
    for (const object of this.objects.values()) {
      const model = multiply(translation(...object.position), multiply(object.rotation, scaling(
        object.size[0] * object.scale[0], object.size[1] * object.scale[1], object.size[2] * object.scale[2])));
      this.#draw(object.mesh, model, object.color, false, viewProjection);
    }
  }
}

export class BrowserGraphicsRenderer {
  constructor(canvas, options = {}) {
    if (!(canvas instanceof HTMLCanvasElement)) throw new TypeError("BrowserGraphicsRenderer requires an HTMLCanvasElement.");
    this.canvas = canvas; this.options = options; this.renderer = null; this.rendererKind = null;
  }

  handle(envelope) {
    const command = envelope?.command;
    if (!command) return;
    const requestedKind = command.renderer || this.rendererKind || "canvas2d";
    if (command.op === "open" && requestedKind !== this.rendererKind) this.#switchRenderer(requestedKind);
    this.renderer?.handle(envelope);
  }

  clear() { this.renderer?.clear(); }
  dispose() { this.renderer?.dispose(); }

  #switchRenderer(kind) {
    if (this.renderer) {
      this.renderer.dispose();
      const replacement = this.canvas.cloneNode(false);
      replacement.width = this.canvas.width; replacement.height = this.canvas.height;
      this.canvas.replaceWith(replacement); this.canvas = replacement;
    }
    this.rendererKind = kind;
    this.renderer = kind === "webgl2" ? new WebGLGraphicsRenderer(this.canvas, this.options) : new CanvasGraphicsRenderer(this.canvas, this.options);
  }
}
