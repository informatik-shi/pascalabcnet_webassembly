using System.Runtime.InteropServices.JavaScript;
using System.Text.Json;

namespace PascalABC.Web.Graphics;

/// <summary>
/// Narrow, browser-safe graphics boundary used by the Pascal compatibility units.
/// Commands are emitted from the .NET/WASM worker and rendered on the main thread.
/// </summary>
public static partial class BrowserGraphicsBridge
{
    private const int DefaultWidth = 800;
    private const int DefaultHeight = 500;
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);
    private static long executionId;
    private static bool opened;
    private static int width = DefaultWidth;
    private static int height = DefaultHeight;
    private static string title = "GraphWPF";

    [JSImport("emit", "pascalabc.graphics")]
    private static partial void EmitToJavaScript(string commandJson);

    public static void BeginExecution()
    {
        executionId++;
        opened = false;
        width = DefaultWidth;
        height = DefaultHeight;
        title = "GraphWPF";
    }

    public static void Open(int requestedWidth, int requestedHeight, string? requestedTitle)
    {
        width = Math.Clamp(requestedWidth, 1, 4096);
        height = Math.Clamp(requestedHeight, 1, 4096);
        title = string.IsNullOrWhiteSpace(requestedTitle) ? "GraphWPF" : requestedTitle;
        Emit(new { op = "open", renderer = "canvas2d", width, height, title });
        opened = true;
    }

    public static void Resize(int requestedWidth, int requestedHeight)
    {
        width = Math.Clamp(requestedWidth, 1, 4096);
        height = Math.Clamp(requestedHeight, 1, 4096);
        EnsureOpen();
        Emit(new { op = "resize", width, height });
    }

    public static void SetTitle(string? requestedTitle)
    {
        title = string.IsNullOrWhiteSpace(requestedTitle) ? "GraphWPF" : requestedTitle;
        EnsureOpen();
        Emit(new { op = "title", title });
    }

    public static void Clear(int color)
    {
        EnsureOpen();
        Emit(new { op = "clear", color });
    }

    public static void Line(double x1, double y1, double x2, double y2, int color, double lineWidth)
    {
        EnsureOpen();
        Emit(new { op = "line", x1, y1, x2, y2, color, lineWidth });
    }

    public static void Rectangle(
        double x,
        double y,
        double rectangleWidth,
        double rectangleHeight,
        int fillColor,
        int strokeColor,
        double lineWidth,
        bool fill,
        bool stroke)
    {
        EnsureOpen();
        Emit(new
        {
            op = "rectangle",
            x,
            y,
            width = rectangleWidth,
            height = rectangleHeight,
            fillColor,
            strokeColor,
            lineWidth,
            fill,
            stroke
        });
    }

    public static void Ellipse(
        double x,
        double y,
        double radiusX,
        double radiusY,
        int fillColor,
        int strokeColor,
        double lineWidth,
        bool fill,
        bool stroke)
    {
        EnsureOpen();
        Emit(new
        {
            op = "ellipse",
            x,
            y,
            radiusX,
            radiusY,
            fillColor,
            strokeColor,
            lineWidth,
            fill,
            stroke
        });
    }

    public static void Arc(
        double x,
        double y,
        double radius,
        double startAngle,
        double endAngle,
        int fillColor,
        int strokeColor,
        double lineWidth,
        bool sector,
        bool fill,
        bool stroke)
    {
        EnsureOpen();
        Emit(new
        {
            op = "arc",
            x,
            y,
            radius,
            startAngle,
            endAngle,
            fillColor,
            strokeColor,
            lineWidth,
            sector,
            fill,
            stroke
        });
    }

    public static void Polygon(double[] coordinates, int fillColor, int strokeColor, double lineWidth, bool fill, bool stroke)
    {
        EnsureOpen();
        Emit(new { op = "polygon", coordinates, fillColor, strokeColor, lineWidth, fill, stroke });
    }

    public static void Text(
        double x,
        double y,
        string? text,
        int color,
        double fontSize,
        string? fontFamily,
        string? fontStyle,
        string? alignment,
        double angle)
    {
        EnsureOpen();
        Emit(new
        {
            op = "text",
            x,
            y,
            text = text ?? string.Empty,
            color,
            fontSize,
            fontFamily = string.IsNullOrWhiteSpace(fontFamily) ? "Arial" : fontFamily,
            fontStyle = fontStyle ?? "normal",
            alignment = alignment ?? "left-top",
            angle
        });
    }

    private static void EnsureOpen()
    {
        if (!opened)
            Open(width, height, title);
    }

    private static void Emit<T>(T payload)
    {
        var envelope = new GraphicsEnvelope<T>(1, executionId, payload);
        EmitToJavaScript(JsonSerializer.Serialize(envelope, JsonOptions));
    }

    private sealed record GraphicsEnvelope<T>(int Protocol, long ExecutionId, T Command);
}
