function colorToCss(value) {
  const argb = Number(value) >>> 0;
  const alpha = ((argb >>> 24) & 0xff) / 255;
  const red = (argb >>> 16) & 0xff;
  const green = (argb >>> 8) & 0xff;
  const blue = argb & 0xff;
  return `rgba(${red}, ${green}, ${blue}, ${alpha})`;
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
      case "resize":
        this.#resize(command.width, command.height);
        break;
      case "title":
        this.options.onTitle?.(command.title);
        break;
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
        if (command.fill) {
          applyFill(this.context, command);
          this.context.fillRect(command.x, command.y, command.width, command.height);
        }
        if (command.stroke) {
          applyStroke(this.context, command);
          this.context.strokeRect(command.x, command.y, command.width, command.height);
        }
        break;
      case "ellipse":
        this.context.beginPath();
        this.context.ellipse(command.x, command.y, Math.abs(command.radiusX), Math.abs(command.radiusY), 0, 0, Math.PI * 2);
        if (command.fill) {
          applyFill(this.context, command);
          this.context.fill();
        }
        if (command.stroke) {
          applyStroke(this.context, command);
          this.context.stroke();
        }
        break;
      case "arc":
        this.#drawArc(command);
        break;
      case "polygon":
        this.#drawPolygon(command);
        break;
      case "text":
        this.#drawText(command);
        break;
    }
  }

  clear() {
    this.context.clearRect(0, 0, this.logicalWidth, this.logicalHeight);
  }

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
    if (command.fill) {
      applyFill(this.context, command);
      this.context.fill();
    }
    if (command.stroke) {
      applyStroke(this.context, command);
      this.context.stroke();
    }
  }

  #drawPolygon(command) {
    const coordinates = command.coordinates ?? [];
    if (coordinates.length < 4) return;
    this.context.beginPath();
    this.context.moveTo(coordinates[0], coordinates[1]);
    for (let index = 2; index + 1 < coordinates.length; index += 2)
      this.context.lineTo(coordinates[index], coordinates[index + 1]);
    if (command.fill) this.context.closePath();
    if (command.fill) {
      applyFill(this.context, command);
      this.context.fill();
    }
    if (command.stroke) {
      applyStroke(this.context, command);
      this.context.stroke();
    }
  }

  #drawText(command) {
    const [horizontal = "left", vertical = "top"] = String(command.alignment || "left-top").split("-");
    const fontStyle = command.fontStyle === "bold-italic"
      ? "italic 700"
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
