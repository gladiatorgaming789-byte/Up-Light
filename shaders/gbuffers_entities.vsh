#version 460

in vec3 vaPosition;
in vec2 vaUV0;
in vec4 vaColor;
in vec3 vaNormal;
in ivec2 vaUV2;

uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;
uniform mat3 normalMatrix;

out vec2 uv;
out vec4 vertexColor;
out vec3 viewNormal;
out vec2 lightmapUV;

void main() {

    uv = vaUV0;
    vertexColor = vaColor;
    lightmapUV = vec2(vaUV2) / 256.0;

    viewNormal =
        normalize(
            normalMatrix *
            vaNormal
        );

    vec4 viewPosition =
        modelViewMatrix *
        vec4(
            vaPosition,
            1.0
        );

    gl_Position =
        projectionMatrix *
        viewPosition;
}