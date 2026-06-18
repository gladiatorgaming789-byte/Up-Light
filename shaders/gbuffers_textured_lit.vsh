#version 460

// Vertex Attributes
in vec3 vaPosition;
in vec2 vaUV0;
in vec4 vaColor;
in vec3 vaNormal;
in ivec2 vaUV2;

// Uniforms
uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;
uniform mat3 normalMatrix;
uniform vec3 chunkOffset;

// Outputs
out vec2 uv;
out vec3 vertexColor;
out vec3 viewNormal;
out vec2 lightmapUV;

void main() {

    uv = vaUV0;
    vertexColor = vaColor.rgb;

    viewNormal = normalize(normalMatrix * vaNormal);

    lightmapUV =
        vec2(
            vaUV2
        ) / 256.0;

    vec3 worldPosition =
        vaPosition +
        chunkOffset;

    vec4 viewPosition =
        modelViewMatrix *
        vec4(worldPosition, 1.0);

    gl_Position =
        projectionMatrix *
        viewPosition;
}