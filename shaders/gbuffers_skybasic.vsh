#version 460

in vec3 vaPosition;

uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;
uniform mat4 gbufferModelViewInverse;

out vec3 skyDirection;

void main() {

    vec3 viewDirection =
        (
            modelViewMatrix *
            vec4(
                vaPosition,
                1.0
            )
        ).xyz;

    skyDirection =
        mat3(
            gbufferModelViewInverse
        ) *
        viewDirection;

    gl_Position =
        projectionMatrix *
        modelViewMatrix *
        vec4(
            vaPosition,
            1.0
        );
}