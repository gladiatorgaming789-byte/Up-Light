layout(location = 0) out vec4 outColor0;

const float VOXY_TRANSLUCENT_AMBIENT = 0.48;
const float VOXY_TRANSLUCENT_TAU = 6.2831853;

vec3 voxy_getTranslucentLightmapTint(
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

    lm =
        clamp(
            lm,
            vec2(0.0),
            vec2(1.0)
        );

    float brightness =
        max(
            lm.x,
            lm.y
        );

    return
        mix(
            vec3(0.35),
            vec3(1.0),
            brightness
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

    vec3 dayTint =
        vec3(
            0.85,
            0.95,
            1.00
        );

    vec3 nightTint =
        vec3(
            0.28,
            0.36,
            0.62
        );

    vec3 timeTint =
        mix(
            nightTint,
            dayTint,
            dayFactor
        );

    vec4 sampledColor =
        parameters.sampledColour *
        parameters.tinting;

    vec3 finalColor =
        sampledColor.rgb *
        timeTint *
        voxy_getTranslucentLightmapTint(
            parameters.lightMap
        ) *
        VOXY_TRANSLUCENT_AMBIENT;

    outColor0 =
        vec4(
            finalColor,
            sampledColor.a
        );
}