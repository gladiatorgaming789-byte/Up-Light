#version 460 compatibility

uniform vec3 shadowLightPosition;
uniform int worldTime;

in vec4 vertexColor;
in vec3 viewNormal;
in vec2 lightmapUV;

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 outColor;

const float AMBIENT_LIGHT_STRENGTH = 0.46;
const float DIRECT_LIGHT_STRENGTH = 0.40;
const float TAU = 6.2831853;

void main() {

    float timeOfDay =
        mod(
            float(worldTime),
            24000.0
        );

    float rawDayFactor =
        sin(
            timeOfDay *
            TAU /
            24000.0
        ) * 0.5 + 0.5;

    float dayFactor =
        smoothstep(
            0.12,
            0.88,
            rawDayFactor
        );

    vec3 dayWaterColor =
        vec3(
            0.42,
            0.68,
            0.82
        );

    vec3 nightWaterColor =
        vec3(
            0.08,
            0.13,
            0.25
        );

    vec3 waterTint =
        mix(
            nightWaterColor,
            dayWaterColor,
            dayFactor
        );

    vec3 normalDirection =
        normalize(
            viewNormal
        );

    vec3 sunDirection =
        normalize(
            shadowLightPosition
        );

    float diffuse =
        max(
            dot(
                normalDirection,
                sunDirection
            ),
            0.0
        );

    vec3 baseColor =
        mix(
            vertexColor.rgb,
            waterTint,
            0.35
        );

    vec3 lighting =
        vec3(
            AMBIENT_LIGHT_STRENGTH
        ) +
        diffuse *
        DIRECT_LIGHT_STRENGTH;

    vec3 finalColor =
        baseColor *
        lighting;

    outColor =
        vec4(
            finalColor,
            vertexColor.a
        );
}