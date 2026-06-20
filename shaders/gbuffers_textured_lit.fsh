#version 460

uniform sampler2D gtexture;
uniform sampler2D lightmap;

uniform vec3 shadowLightPosition;
uniform int worldTime;

in vec2 uv;
in vec3 vertexColor;
in vec3 viewNormal;
in vec2 lightmapUV;

layout(location = 0) out vec4 outColor;

const float AMBIENT_LIGHT_STRENGTH = 0.42;
const float DIRECT_LIGHT_STRENGTH = 0.72;
const float LIGHTMAP_TINT_STRENGTH = 0.90;
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

    vec3 sunDirection =
        normalize(
            shadowLightPosition
        );

    vec3 normalDirection =
        normalize(
            viewNormal
        );

    float diffuse =
        max(
            dot(
                normalDirection,
                sunDirection
            ),
            0.0
        );

    float directVisibility =
        stableDirectLight;

    vec3 lighting =
        ambientLightColor *
        AMBIENT_LIGHT_STRENGTH +
        directLightColor *
        diffuse *
        DIRECT_LIGHT_STRENGTH *
        directVisibility;

    vec3 finalColor =
        textureColor.rgb *
        vertexColor *
        lightmapTint *
        lighting;

    outColor =
        vec4(
            finalColor,
            textureColor.a
        );
}