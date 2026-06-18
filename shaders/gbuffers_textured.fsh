#version 460

uniform sampler2D gtexture;
uniform sampler2D lightmap;

uniform vec3 shadowLightPosition;
uniform int worldTime;

in vec2 uv;
in vec3 vertexColor;
in vec3 viewNormal;
in vec2 lightmapUV;

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 outColor;

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

    float dayFactor =
        clamp(
            sin(
                timeOfDay *
                6.2831853 /
                24000.0
            ) * 0.5 + 0.5,
            0.0,
            1.0
        );

    vec3 sunriseColor =
        vec3(
            1.00,
            0.55,
            0.30
        );

    vec3 noonColor =
        vec3(
            1.00,
            0.98,
            0.92
        );

    vec3 moonColor =
        vec3(
            0.35,
            0.45,
            0.70
        );

    vec3 daylightColor =
        mix(
            sunriseColor,
            noonColor,
            smoothstep(
                0.15,
                0.85,
                dayFactor
            )
        );

    vec3 sunlightColor =
        mix(
            moonColor,
            daylightColor,
            dayFactor
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
            0.35
        ) +
        diffuse *
        0.65 *
        sunlightColor;

    vec3 finalColor =
        textureColor.rgb *
        vertexColor *
        lighting *
        lightmapColor;

    outColor =
        vec4(
            finalColor,
            textureColor.a
        );
}