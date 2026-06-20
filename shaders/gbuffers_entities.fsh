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

const float AMBIENT_LIGHT = 0.38;
const float DIRECT_LIGHT_STRENGTH = 0.68;
const float LIGHTMAP_TINT_STRENGTH = 0.85;
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

    vec3 lightmapTint =
        mix(
            vec3(1.0),
            lightmapColor,
            LIGHTMAP_TINT_STRENGTH
        );

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
            0.96,
            0.88
        );

    vec3 moonlightColor =
        vec3(
            0.34,
            0.43,
            0.68
        );

    vec3 sunsetColor =
        vec3(
            1.00,
            0.48,
            0.22
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
            dawnDuskFactor * 0.35
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

    float directVisibility =
        mix(
            1.0,
            0.35,
            dawnDuskFactor
        );

    vec3 lighting =
        vec3(
            AMBIENT_LIGHT
        ) +
        diffuse *
        DIRECT_LIGHT_STRENGTH *
        directVisibility *
        sunlightColor;

    vec3 finalColor =
        textureColor.rgb *
        vertexColor.rgb *
        lightmapTint *
        lighting;

    outColor =
        vec4(
            finalColor,
            textureColor.a
        );
}