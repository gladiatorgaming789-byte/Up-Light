#version 460

in vec3 skyDirection;

uniform int worldTime;
uniform vec3 shadowLightPosition;
uniform mat4 gbufferModelViewInverse;
uniform int renderStage;

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 outColor0;

const float PI = 3.14159265;
const float TAU = 6.2831853;

float hash12(
    vec2 p
) {

    vec3 p3 =
        fract(
            vec3(
                p.x,
                p.y,
                p.x
            ) *
            0.1031
        );

    p3 +=
        dot(
            p3,
            p3.yzx + 33.33
        );

    return
        fract(
            (
                p3.x +
                p3.y
            ) *
            p3.z
        );
}

vec3 getProceduralStars(
    vec3 dir,
    float timeOfDay,
    float rawDayFactor,
    float celestialAmount
) {

    /*
        Stage 7C: Star brightness tuning.

        This keeps stars visible and pretty, but less noisy/overbright.
        It also fades stars harder near the horizon and around the moon/sun.
    */
    float nightVisibility =
        1.0 -
        smoothstep(
            0.06,
            0.34,
            rawDayFactor
        );

    float horizonFade =
        smoothstep(
            0.08,
            0.38,
            dir.y
        );

    float celestialFade =
        1.0 -
        smoothstep(
            0.12,
            0.58,
            celestialAmount
        );

    vec2 starUV =
        vec2(
            atan(
                dir.z,
                dir.x
            ) /
            TAU +
            0.5,
            asin(
                clamp(
                    dir.y,
                    -1.0,
                    1.0
                )
            ) /
            PI +
            0.5
        );

    vec2 gridScale =
        vec2(
            440.0,
            190.0
        );

    vec2 starCell =
        floor(
            starUV *
            gridScale
        );

    vec2 localPosition =
        fract(
            starUV *
            gridScale
        );

    float randomValue =
        hash12(
            starCell
        );

    /*
        Higher number = fewer stars.
        Lower number = more stars.
    */
    float starMask =
        smoothstep(
            0.9885,
            0.9960,
            randomValue
        );

    vec2 starCenter =
        vec2(
            hash12(
                starCell + 17.31
            ),
            hash12(
                starCell + 41.73
            )
        );

    float distanceToStar =
        length(
            localPosition -
            starCenter
        );

    float starSize =
        mix(
            0.026,
            0.055,
            hash12(
                starCell + 91.13
            )
        );

    float starCore =
        1.0 -
        smoothstep(
            0.0,
            starSize * 0.42,
            distanceToStar
        );

    float starGlow =
        1.0 -
        smoothstep(
            starSize * 0.35,
            starSize,
            distanceToStar
        );

    float starShape =
        max(
            starCore,
            starGlow * 0.45
        ) *
        starMask;

    float largeStarMask =
        step(
            0.9984,
            randomValue
        );

    float largeStar =
        (
            1.0 -
            smoothstep(
                0.0,
                starSize * 1.65,
                distanceToStar
            )
        ) *
        largeStarMask;

    float twinkle =
        0.94 +
        sin(
            timeOfDay *
            0.004 +
            randomValue *
            91.0
        ) *
        0.06;

    float starBrightness =
        mix(
            0.38,
            1.05,
            hash12(
                starCell + 7.77
            )
        );

    vec3 coolStarColor =
        vec3(
            0.78,
            0.86,
            1.00
        );

    vec3 warmStarColor =
        vec3(
            1.00,
            0.92,
            0.78
        );

    vec3 starColor =
        mix(
            coolStarColor,
            warmStarColor,
            hash12(
                starCell + 23.19
            ) * 0.55
        );

    vec3 stars =
        starColor *
        (
            starShape +
            largeStar * 0.75
        ) *
        starBrightness *
        twinkle;

    stars *=
        nightVisibility *
        horizonFade *
        celestialFade;

    return
        stars;
}

void main() {

    vec3 worldSunDirection =
        normalize(
            mat3(gbufferModelViewInverse) *
            shadowLightPosition
        );

    vec3 dir =
        normalize(
            skyDirection
        );

    #ifdef MC_RENDER_STAGE_STARS
        if (renderStage == MC_RENDER_STAGE_STARS) {
            discard;
        }
    #endif

    float celestialAmount =
        max(
            dot(
                dir,
                worldSunDirection
            ),
            0.0
        );

    float timeOfDay =
        mod(
            float(worldTime),
            24000.0
        );

    float skyTime =
        mod(
            timeOfDay + 1850.0,
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

    float t =
        clamp(
            dir.y * 0.5 + 0.5,
            0.0,
            1.0
        );

    float horizonBand =
        1.0 -
        abs(
            t - 0.5
        ) * 1.5;

    horizonBand =
        clamp(
            horizonBand,
            0.0,
            1.0
        );

    horizonBand =
        pow(
            horizonBand,
            3.0
        );

    float horizonGlow =
        horizonBand *
        dawnDuskFactor;

    vec3 sunsetColor =
        vec3(
            1.00,
            0.55,
            0.20
        );

    vec3 dayHorizon =
        vec3(
            0.85,
            0.92,
            1.00
        );

    vec3 dayZenith =
        vec3(
            0.45,
            0.65,
            1.00
        );

    vec3 nightHorizon =
        vec3(
            0.04,
            0.05,
            0.10
        );

    vec3 nightZenith =
        vec3(
            0.01,
            0.02,
            0.06
        );

    vec3 horizonColor =
        mix(
            nightHorizon,
            dayHorizon,
            dayFactor
        );

    vec3 zenithColor =
        mix(
            nightZenith,
            dayZenith,
            dayFactor
        );

    vec3 skyColor =
        mix(
            horizonColor,
            zenithColor,
            t
        );

    float upperSkyGlow =
        pow(
            dawnDuskFactor,
            1.5
        ) *
        pow(
            t,
            0.7
        );

    vec3 upperAtmosphereColor =
        vec3(
            1.00,
            0.55,
            0.35
        );

    skyColor =
        mix(
            skyColor,
            upperAtmosphereColor,
            upperSkyGlow * 0.20
        );

    skyColor =
        mix(
            skyColor,
            sunsetColor,
            horizonGlow * 0.25
        );

    /*
        Stage 6C: Horizon haze.

        This adds a soft atmospheric band near the horizon.
        It is subtle during the day, cooler at night, and warmer at sunrise/sunset.
    */
    float horizonHaze =
        1.0 -
        smoothstep(
            0.02,
            0.45,
            abs(
                dir.y
            )
        );

    horizonHaze =
        pow(
            clamp(
                horizonHaze,
                0.0,
                1.0
            ),
            1.35
        );

    vec3 dayHazeColor =
        vec3(
            0.78,
            0.88,
            1.00
        );

    vec3 nightHazeColor =
        vec3(
            0.07,
            0.09,
            0.17
        );

    vec3 sunsetHazeColor =
        vec3(
            1.00,
            0.62,
            0.32
        );

    vec3 hazeColor =
        mix(
            nightHazeColor,
            dayHazeColor,
            dayFactor
        );

    hazeColor =
        mix(
            hazeColor,
            sunsetHazeColor,
            dawnDuskFactor * 0.45
        );

    float hazeStrength =
        mix(
            0.10,
            0.18,
            dayFactor
        );

    hazeStrength +=
        dawnDuskFactor *
        0.08;

    skyColor =
        mix(
            skyColor,
            hazeColor,
            horizonHaze * hazeStrength
        );

    float sunHeight =
        clamp(
            worldSunDirection.y * 0.5 + 0.5,
            0.0,
            1.0
        );

    float middayBoost =
        smoothstep(
            0.25,
            0.85,
            sunHeight
        );

    /*
        Atmospheric scattering.

        The second multiplier prevents the atmosphere from becoming strongest
        directly on top of the sun/moon texture. This keeps the celestial body
        from becoming overexposed while preserving a glow around it.
    */
    float atmosphere =
        pow(
            celestialAmount,
            2.0
        ) *
        (
            1.0 -
            pow(
                celestialAmount,
                8.0
            )
        );

    vec3 atmosphereColor =
        vec3(
            0.70,
            0.85,
            1.00
        );

    skyColor +=
        atmosphereColor *
        atmosphere *
        middayBoost *
        0.15;

    float oppositeAmount =
        max(
            dot(
                dir,
                -worldSunDirection
            ),
            0.0
        );

    float oppositeAtmosphere =
        pow(
            oppositeAmount,
            2.0
        );

    skyColor +=
        vec3(
            0.05,
            0.10,
            0.20
        ) *
        oppositeAtmosphere *
        middayBoost *
        0.25;

    /*
        Stage 7: Procedural stars.

        Stars are generated from world-space sky direction, fade smoothly by
        time of day, fade near the horizon, and fade around the sun/moon halo.
    */
    vec3 proceduralStars =
        getProceduralStars(
            dir,
            timeOfDay,
            rawDayFactor,
            celestialAmount
        );

    skyColor +=
        proceduralStars *
        0.85;

    /*
        Stage 6B: Sun / Moon halo.

        This is intentionally placed after the procedural stars so the halo
        can softly overpower nearby stars around the moon or sun.
    */
    float haloWide =
        pow(
            celestialAmount,
            5.0
        );

    float haloCore =
        pow(
            celestialAmount,
            18.0
        ) *
        (
            1.0 -
            pow(
                celestialAmount,
                96.0
            )
        );

    vec3 sunHaloColor =
        vec3(
            1.00,
            0.78,
            0.45
        );

    vec3 moonHaloColor =
        vec3(
            0.35,
            0.45,
            0.75
        );

    vec3 haloColor =
        mix(
            moonHaloColor,
            sunHaloColor,
            dayFactor
        );

    float haloStrength =
        mix(
            0.10,
            0.22,
            dayFactor
        );

    skyColor +=
        haloColor *
        (
            haloWide * 0.35 +
            haloCore
        ) *
        haloStrength;

    outColor0 =
        vec4(
            skyColor,
            1.0
        );
}