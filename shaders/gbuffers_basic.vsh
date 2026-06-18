#version 460

// Vertex Attributes
in vec3 vaPosition;
in vec4 vaColor;

// Uniforms
uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;

// Outputs
out vec4 vertexColor;

void main() {

    vertexColor = vaColor;

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