#version 460

uniform sampler2D gtexture;
uniform sampler2D lightmap;

uniform vec3 shadowLightPosition;
uniform int worldTime;

in vec2 uv;
in vec4 vertexColor;
in vec3 viewNormal;
in vec2 lightmapUV;

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 outColor;

const float AMBIENT_LIGHT = 0.40;
const float DIRECT_LIGHT_STRENGTH = 0.65;
const float TAU = 6.2831853;

void main() {

    vec4 textureColor =
        texture(
            gtexture,
            uv
        );

    if (textureColor.a < 0.1) {
        discard;
    }

    vec3 lightmapColor =
        texture(
            lightmap,
            lightmapUV
        ).rgb;

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
            0.15,
            0.85,
            rawDayFactor
        );

    float skyTime =
        mod(
            timeOfDay + 1850.0,
            24000.0
        );

    float dawnDuskFactor =
        pow(
            max(
                0.0,
                sin(
                    skyTime *
                    TAU /
                    12000.0
                )
            ),
            2.0
        );

    vec3 daylightColor =
        vec3(
            1.00,
            0.98,
            0.95
        );

    vec3 moonlightColor =
        vec3(
            0.45,
            0.55,
            0.75
        );

    vec3 sunsetColor =
        vec3(
            1.00,
            0.55,
            0.20
        );

    vec3 sunlightColor =
        mix(
            moonlightColor,
            daylightColor,
            dayFactor
        );

    sunlightColor =
        mix(
            sunlightColor,
            sunsetColor,
            dawnDuskFactor * 0.25
        );

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

    vec3 lighting =
        vec3(
            AMBIENT_LIGHT
        ) +
        diffuse *
        DIRECT_LIGHT_STRENGTH *
        sunlightColor;

    vec3 finalColor =
        textureColor.rgb *
        vertexColor.rgb *
        lightmapColor *
        lighting;

    outColor =
        vec4(
            finalColor,
            textureColor.a
        );
}