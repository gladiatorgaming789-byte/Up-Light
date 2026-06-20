#version 460 compatibility

out vec4 vertexColor;
out vec3 viewNormal;
out vec2 lightmapUV;

void main() {

    vertexColor =
        gl_Color;

    viewNormal =
        normalize(
            gl_NormalMatrix *
            gl_Normal
        );

    lightmapUV =
        gl_MultiTexCoord2.xy /
        256.0;

    gl_Position =
        ftransform();
}