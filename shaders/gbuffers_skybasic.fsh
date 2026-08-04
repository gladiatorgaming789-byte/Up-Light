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

float valueNoise(
    vec2 p
) {

    vec2 cell =
        floor(
            p
        );

    vec2 localPosition =
        fract(
            p
        );

    localPosition =
        localPosition *
        localPosition *
        (
            3.0 -
            2.0 *
            localPosition
        );

    float bottomLeft =
        hash12(
            cell
        );

    float bottomRight =
        hash12(
            cell +
            vec2(
                1.0,
                0.0
            )
        );

    float topLeft =
        hash12(
            cell +
            vec2(
                0.0,
                1.0
            )
        );

    float topRight =
        hash12(
            cell +
            vec2(
                1.0,
                1.0
            )
        );

    float bottom =
        mix(
            bottomLeft,
            bottomRight,
            localPosition.x
        );

    float top =
        mix(
            topLeft,
            topRight,
            localPosition.x
        );

    return
        mix(
            bottom,
            top,
            localPosition.y
        );
}

vec3 getMilkyWay(
    vec3 dir,
    float rawDayFactor,
    float celestialAmount
) {

    /*
        Stage 7E: Milky Way / star band.

        A tilted great-circle band gives the night sky a faint cloudy structure.
        Two inexpensive noise layers break up the shape while a darker lane
        prevents it from reading as a flat glowing stripe.
    */
    vec3 bandNormal =
        normalize(
            vec3(
                0.38,
                0.22,
                -0.90
            )
        );

    float bandDistance =
        abs(
            dot(
                dir,
                bandNormal
            )
        );

    float wideBand =
        1.0 -
        smoothstep(
            0.08,
            0.30,
            bandDistance
        );

    float coreBand =
        1.0 -
        smoothstep(
            0.01,
            0.115,
            bandDistance
        );

    /*
        Direction-based coordinates avoid a visible longitude seam.
    */
    vec2 cloudUV =
        vec2(
            dot(
                dir,
                vec3(
                    1.7,
                    2.3,
                    -0.9
                )
            ),
            dot(
                dir,
                vec3(
                    -1.2,
                    0.6,
                    2.1
                )
            )
        ) *
        2.6;

    float broadNoise =
        valueNoise(
            cloudUV *
            1.8 +
            vec2(
                4.2,
                8.1
            )
        );

    float fineNoise =
        valueNoise(
            cloudUV *
            4.7 +
            vec2(
                13.8,
                2.6
            )
        );

    float cloudNoise =
        broadNoise *
        0.68 +
        fineNoise *
        0.32;

    float cloudTexture =
        smoothstep(
            0.24,
            0.82,
            cloudNoise
        );

    float dustNoise =
        valueNoise(
            cloudUV *
            6.2 +
            vec2(
                20.1,
                11.7
            )
        );

    float dustLane =
        smoothstep(
            0.54,
            0.78,
            dustNoise
        ) *
        coreBand;

    float bandStrength =
        wideBand *
        mix(
            0.30,
            1.00,
            cloudTexture
        );

    bandStrength +=
        coreBand *
        0.20;

    bandStrength *=
        1.0 -
        dustLane *
        0.52;

    float nightVisibility =
        1.0 -
        smoothstep(
            0.06,
            0.34,
            rawDayFactor
        );

    float horizonFade =
        smoothstep(
            0.03,
            0.26,
            dir.y
        );

    float celestialFade =
        1.0 -
        smoothstep(
            0.94,
            0.997,
            celestialAmount
        );

    vec3 coolBandColor =
        vec3(
            0.16,
            0.21,
            0.36
        );

    vec3 warmBandColor =
        vec3(
            0.28,
            0.24,
            0.32
        );

    vec3 bandColor =
        mix(
            coolBandColor,
            warmBandColor,
            broadNoise *
            0.35
        );

    return
        bandColor *
        bandStrength *
        nightVisibility *
        horizonFade *
        celestialFade *
        0.040;
}

vec3 getProceduralStars(
    vec3 dir,
    float timeOfDay,
    float rawDayFactor,
    float celestialAmount
) {

    /*
        Stage 7C: Star brightness tuning.

        Tuned from 2560x1440 night screenshots. Stars remain subtle, but their
        cores are large enough to survive sub-pixel rendering at high resolution.
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
            0.04,
            0.30,
            dir.y
        );

    /*
        Only hide stars close to the moon/sun disc. The older 0.14-0.62 range
        dimmed stars across most of the visible hemisphere.
    */
    float celestialFade =
        1.0 -
        smoothstep(
            0.92,
            0.992,
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
            0.9865,
            0.9950,
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
            0.045,
            0.090,
            hash12(
                starCell + 91.13
            )
        );

    float starCore =
        1.0 -
        smoothstep(
            0.0,
            starSize * 0.48,
            distanceToStar
        );

    float starGlow =
        1.0 -
        smoothstep(
            starSize * 0.30,
            starSize,
            distanceToStar
        );

    float starShape =
        max(
            starCore,
            starGlow * 0.42
        ) *
        starMask;

    float largeStarMask =
        step(
            0.9982,
            randomValue
        );

    float largeStar =
        (
            1.0 -
            smoothstep(
                0.0,
                starSize * 1.55,
                distanceToStar
            )
        ) *
        largeStarMask;

    float twinkle =
        0.95 +
        sin(
            timeOfDay *
            0.004 +
            randomValue *
            91.0
        ) *
        0.05;

    float starBrightness =
        mix(
            0.52,
            1.20,
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
            largeStar * 0.70
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

        shadowLightPosition follows the moon at night, so this broad daytime
        scattering must be faded out by dayFactor. Without that gate, changing
        the small explicit moon halo barely affects the much larger visible glow.
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

    float atmosphereDayVisibility =
        smoothstep(
            0.08,
            0.32,
            dayFactor
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
        atmosphereDayVisibility *
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
        atmosphereDayVisibility *
        0.25;

    /*
        Stage 7D: Moonlight sky polish.

        This is mainly a directional color shift, not another bright halo.
        The moon-facing sky becomes slightly cooler while the opposite side
        becomes a little deeper, giving the night sky more shape around stars.
    */
    float nightFactor =
        1.0 -
        dayFactor;

    float moonFacingAmount =
        pow(
            celestialAmount,
            1.8
        ) *
        nightFactor;

    vec3 moonFacingScale =
        vec3(
            0.93,
            1.03,
            1.16
        );

    skyColor *=
        mix(
            vec3(1.0),
            moonFacingScale,
            moonFacingAmount * 0.32
        );

    float moonCoreAmount =
        pow(
            celestialAmount,
            6.0
        ) *
        nightFactor;

    skyColor +=
        vec3(
            0.0015,
            0.0030,
            0.0070
        ) *
        moonCoreAmount;

    float antiMoonAmount =
        pow(
            oppositeAmount,
            1.5
        ) *
        nightFactor;

    vec3 antiMoonScale =
        vec3(
            0.94,
            0.96,
            1.01
        );

    skyColor *=
        mix(
            vec3(1.0),
            antiMoonScale,
            antiMoonAmount * 0.16
        );

    /*
        Stage 7E: Milky Way / star band.

        The diffuse band is added before the procedural stars so individual
        stars remain crisp and readable on top of the faint cloud structure.
    */
    vec3 milkyWay =
        getMilkyWay(
            dir,
            rawDayFactor,
            celestialAmount
        );

    skyColor +=
        milkyWay;

    /*
        Stage 7C: Procedural star tuning.

        Stars are generated from world-space sky direction, fade smoothly by
        time of day, fade near the horizon, and fade only close to the moon/sun.
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
        0.94;

    /*
        Stage 6B: Sun / Moon halo.

        The night halo is intentionally very subtle. It should frame the moon
        without noticeably washing out the surrounding star field.
    */
    float haloWideExponent =
        mix(
            28.0,
            5.0,
            dayFactor
        );

    float haloCoreExponent =
        mix(
            72.0,
            18.0,
            dayFactor
        );

    float haloCutoffExponent =
        mix(
            240.0,
            96.0,
            dayFactor
        );

    float haloWide =
        pow(
            celestialAmount,
            haloWideExponent
        );

    float haloCore =
        pow(
            celestialAmount,
            haloCoreExponent
        ) *
        (
            1.0 -
            pow(
                celestialAmount,
                haloCutoffExponent
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
            0.20,
            0.25,
            0.42
        );

    vec3 haloColor =
        mix(
            moonHaloColor,
            sunHaloColor,
            dayFactor
        );

    float haloStrength =
        mix(
            0.008,
            0.22,
            dayFactor
        );

    float haloWideWeight =
        mix(
            0.08,
            0.35,
            dayFactor
        );

    skyColor +=
        haloColor *
        (
            haloWide * haloWideWeight +
            haloCore
        ) *
        haloStrength;

    outColor0 =
        vec4(
            skyColor,
            1.0
        );
}