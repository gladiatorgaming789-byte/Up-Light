#version 460

uniform vec3 shadowLightPosition;

in vec4 vertexColor;
in vec3 viewNormal;

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 outColor0;

void main() {

    vec3 sunDirection =
        normalize(
            shadowLightPosition
        );

    float diffuse =
        max(
            dot(
                viewNormal,
                sunDirection
            ),
            0.0
        );

    float lighting =
        0.35 +
        diffuse * 0.65;

    outColor0 =
        vec4(
            vertexColor.rgb *
            lighting,
            vertexColor.a
        );
}