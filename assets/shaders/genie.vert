#version 440

layout(location = 0) in vec4 qt_Vertex;
layout(location = 1) in vec2 qt_MultiTexCoord0;

layout(location = 0) out vec2 qt_TexCoord0;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float progress;
    float widthVal;
    float heightVal;
};

void main()
{
    qt_TexCoord0 = qt_MultiTexCoord0;

    float nx = qt_MultiTexCoord0.x;
    float ny = qt_MultiTexCoord0.y;

    // collapse: 1 when hidden, 0 when fully shown
    float collapse = 1.0 - progress;

    // Bottom rows squeeze more: cubic curve gives genie shape
    // ny=0 is top (no squeeze), ny=1 is bottom (max squeeze)
    float squeeze = ny * ny * collapse;

    // New x: squeeze toward horizontal center
    float newX = (0.5 + (nx - 0.5) * (1.0 - squeeze)) * widthVal;

    // Vertical: bottom pulls up slightly when collapsing
    float yShift = ny * ny * collapse * 0.15;
    float newY = (ny + yShift * (1.0 - ny)) * heightVal;

    gl_Position = qt_Matrix * vec4(newX, newY, 0.0, 1.0);
}
