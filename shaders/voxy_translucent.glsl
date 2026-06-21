layout(location = 0) out vec4 outColor0;

const float VOXY_TRANSLUCENT_TAU = 6.2831853;

vec2 voxy_normalizeLightmap(
    vec2 lightMap
) {

    vec2 lm =
        lightMap;

    if (
        max(
            lm.x,
            lm.y
        ) > 1.5
    ) {

        lm /=
            256.0;
    }

    return
        clamp(
            lm,
            vec2(0.0),
            vec2(1.0)
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
        voxy_normalizeLightmap(
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
            0.40,
            0.48,
            0.76
        );

    vec3 timeTint =
        mix(
            nightTint,
            dayTint,
            dayFactor
        );

    float brightness =
        mix(
            0.56,
            0.86,
            dayFactor
        );

    brightness +=
        skyLight *
        mix(
            0.20,
            0.34,
            dayFactor
        );

    brightness +=
        blockLight *
        0.42;

    brightness =
        clamp(
            brightness,
            0.42,
            1.0
        );

    vec3 finalColor =
        sampledColor.rgb *
        timeTint *
        brightness;

    outColor0 =
        vec4(
            finalColor,
            sampledColor.a
        );
}