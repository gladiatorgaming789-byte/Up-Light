layout(location = 0) out vec4 outColor0;

const float VOXY_TRANSLUCENT_TAU = 6.2831853;

vec2 voxy_decodeLightmap(
    vec2 lightMap
) {

    return
        clamp(
            (
                lightMap -
                vec2(
                    0.03125
                )
            ) *
            1.0666667,
            vec2(
                0.0
            ),
            vec2(
                1.0
            )
        );
}

void voxy_emitFragment(
    VoxyFragmentParameters parameters
) {

    float timeOfDay =
        mod(
            float(worldTime),
            24000.0
        );

    float rawDayFactor =
        sin(
            timeOfDay *
            VOXY_TRANSLUCENT_TAU /
            24000.0
        ) * 0.5 + 0.5;

    float dayFactor =
        smoothstep(
            0.12,
            0.88,
            rawDayFactor
        );

    vec2 lightMap =
        voxy_decodeLightmap(
            parameters.lightMap
        );

    float blockLight =
        lightMap.x;

    float skyLight =
        lightMap.y;

    vec4 sampledColor =
        parameters.sampledColour *
        parameters.tinting;

    vec3 dayTint =
        vec3(
            0.86,
            0.95,
            1.00
        );

    vec3 nightTint =
        vec3(
            0.34,
            0.42,
            0.72
        );

    vec3 timeTint =
        mix(
            nightTint,
            dayTint,
            dayFactor
        );

    float skyBrightness =
        mix(
            0.46,
            1.0,
            dayFactor
        );

    float brightness =
        0.42 +
        skyLight *
        skyBrightness *
        0.42 +
        blockLight *
        0.35;

    vec3 finalColor =
        sampledColor.rgb *
        timeTint *
        brightness;

    finalColor =
        max(
            finalColor,
            sampledColor.rgb *
            vec3(
                0.16,
                0.19,
                0.30
            )
        );

    outColor0 =
        vec4(
            finalColor,
            sampledColor.a
        );
}