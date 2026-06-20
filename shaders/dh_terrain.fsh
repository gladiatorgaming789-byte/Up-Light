#version 460 compatibility

uniform vec3 shadowLightPosition;
uniform int worldTime;

in vec4 vertexColor;
in vec3 viewNormal;
in vec2 lightmapUV;

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 outColor;

const float AMBIENT_LIGHT_STRENGTH = 0.42;
const float DIRECT_LIGHT_STRENGTH = 0.55;
const float LIGHTMAP_TINT_STRENGTH = 0.80;
const float TAU = 6.2831853;

vec3 getLightmapTint(
    vec2 lightMap
) {

    vec2 lm =
        clamp(
            lightMap,
            vec2(0.0),
            vec2(1.0)
        );

    float blockLight =
        lm.x;

    float skyLight =
        lm.y;

    vec3 blockLightColor =
        vec3(
            1.00,
            0.72,
            0.42
        ) *
        blockLight;

    vec3 skyLightColor =
        vec3(
            1.0
        ) *
        skyLight;

    vec3 lightColor =
        max(
            skyLightColor,
            blockLightColor
        );

    lightColor =
        mix(
            vec3(1.0),
            lightColor,
            LIGHTMAP_TINT_STRENGTH
        );

    return
        max(
            lightColor,
            vec3(0.25)
        );
}

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

    float skyTime =
        mod(
            timeOfDay + 2600.0,
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

    float transitionDistance =
        abs(
            rawDayFactor - 0.5
        ) * 2.0;

    float stableDirectLight =
        smoothstep(
            0.22,
            0.68,
            transitionDistance
        );

    vec3 daylightColor =
        vec3(
            1.00,
            0.93,
            0.80
        );

    vec3 moonlightColor =
        vec3(
            0.26,
            0.34,
            0.62
        );

    vec3 sunsetColor =
        vec3(
            1.00,
            0.38,
            0.16
        );

    vec3 dayAmbientColor =
        vec3(
            1.00,
            0.96,
            0.88
        );

    vec3 nightAmbientColor =
        vec3(
            0.28,
            0.35,
            0.60
        );

    vec3 sunsetAmbientColor =
        vec3(
            1.00,
            0.52,
            0.28
        );

    vec3 directLightColor =
        mix(
            moonlightColor,
            daylightColor,
            dayFactor
        );

    directLightColor =
        mix(
            directLightColor,
            sunsetColor,
            dawnDuskFactor * 0.28
        );

    vec3 ambientLightColor =
        mix(
            nightAmbientColor,
            dayAmbientColor,
            dayFactor
        );

    ambientLightColor =
        mix(
            ambientLightColor,
            sunsetAmbientColor,
            dawnDuskFactor * 0.18
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

    vec3 lighting =
        ambientLightColor *
        AMBIENT_LIGHT_STRENGTH +
        directLightColor *
        diffuse *
        DIRECT_LIGHT_STRENGTH *
        stableDirectLight;

    vec3 finalColor =
        vertexColor.rgb *
        getLightmapTint(
            lightmapUV
        ) *
        lighting;

    outColor =
        vec4(
            finalColor,
            vertexColor.a
        );
}