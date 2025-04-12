// Based on the following Shader Toy entry
//
// [SH17A] Matrix rain. Created by Reinder Nijhoff 2017
// Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
// @reindernijhoff
//
// https://www.shadertoy.com/view/ldjBW1
//
// Shader Toy API:
//
// uniform vec3      iResolution;           // viewport resolution (in pixels)
// uniform float     iTime;                 // shader playback time (in seconds)
// uniform float     iTimeDelta;            // render time (in seconds)
// uniform float     iFrameRate;            // shader frame rate
// uniform int       iFrame;                // shader playback frame
// uniform float     iChannelTime[4];       // channel playback time (in seconds)
// uniform vec3      iChannelResolution[4]; // channel resolution (in pixels)
// uniform vec4      iMouse;                // mouse pixel coords. xy: current (if MLB down), zw: click
// uniform samplerXX iChannel0..3;          // input channel. XX = 2D/Cube
// uniform vec4      iDate;                 // (year, month, day, time in seconds)

#define TAU                    6.283185307e0    //
#define GREEN_ALPHA                    3.3e-1   //
#define BLACK_BLEND_THRESHOLD          2.0e-1   //
#define SPEED_FACTOR                   3.0e-1   // 0.1 - slow,   0.5 - default, 1.0 - fast
#define SCALE_FACTOR                   5.0e-1   // 0.1 - coarse, 0.5 - default, 1.0 - fine

// Ref: https://registry.khronos.org/OpenGL-Refpages/gl4/html/fract.xhtml
#define R fract(1e2 * sin(p.x * 8.0e0 + p.y))

// Ref: https://www.shadertoy.com/howto
void mainImage(out vec4 fragColor, vec2 fragCoord) {
    // Normalised current pixel's coordinates, i.e. [0, 1]
    // NB: 5.0e-1 is a part of Shader Toy API
    vec3 normCoord = vec3(fragCoord, 1) / iResolution - 5.0e-1;

    // Size of the pseudo-characters
    vec3 s = SCALE_FACTOR / abs(normCoord);

    // What on earth is going on here?
    s.z = min(s.x, s.y);

    // NB: condition
    vec3 i = ceil(8e2 * s.z * (s.y < s.x ? normCoord.xzz : normCoord.zyz)) * .1;

    vec3 j = fract(i);
    i -= j;

    vec3 p = vec3(9, int(iTime * SPEED_FACTOR * (9. + 8. * sin(i).x)), 0) + i;

    vec3 col = fragColor.rgb;
    col.g = R / s.z;
    p *= j;

    // NB: condition
    col *= (R > .5 && j.x < .6 && j.y < .8) ? GREEN_ALPHA : 0.;

    // Sample the terminal screen texture including alpha channel
    // `iChannel0` uniform is a texture containing the rendered terminal screen
    //
    // Ref: https://lettier.github.io/3d-game-shaders-for-beginners/texturing.html
    // Ref: https://registry.khronos.org/OpenGL-Refpages/gl4/html/texture.xhtml
    // Ref: https://en.wikipedia.org/wiki/UV_mapping
    //
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec4 terminalColor = texture(iChannel0, uv);

    // Calculate alpha channel
    //
    // Ref: https://registry.khronos.org/OpenGL-Refpages/gl4/html/length.xhtml
    // Ref: https://registry.khronos.org/OpenGL-Refpages/gl4/html/step.xhtml
    // Ref: https://registry.khronos.org/OpenGL-Refpages/gl4/html/mix.xhtml
    //
    float alpha = step(length(terminalColor.rgb), BLACK_BLEND_THRESHOLD);
    vec3 blendedColor = mix(terminalColor.rgb * 1.2, col, alpha);

    // Preserve alpha channel: what was transparent stays transparent
    // 
    // Ref: https://en.wikipedia.org/wiki/Alpha_compositing
    fragColor = vec4(blendedColor, terminalColor.a);
}
