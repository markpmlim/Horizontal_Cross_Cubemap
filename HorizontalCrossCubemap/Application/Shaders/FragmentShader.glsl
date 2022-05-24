//https://www.shadertoy.com/view/tlyXzG

#ifdef GL_ES
precision mediump float;
#endif

#if __VERSION__ >= 140
in vec2 texCoords;

out vec4 FragColor;

#else

in vec2 texCoords;

#endif

uniform sampler2D image;
uniform vec2 u_resolution;  // Canvas size (width, height)
uniform vec2 u_mouse;       // mouse position in screen pixels
uniform float u_time;       // Time in seconds since load

#define iResolution u_resolution
#define iMouse      u_mouse
#define iTime       u_time
const float PI = 3.14159265359;
const vec2 dim = vec2(4.0, 3.0);

/*
 Convert a direction to a pair of uv coordinates and a face index.
 */
vec2 dirToCubeUV(vec3 dir, out int faceIndex) {

    vec3 absV = abs(dir);

    bool isXPositive = dir.x > 0.0 ? true : false;
    bool isYPositive = dir.y > 0.0 ? true : false;
    bool isZPositive = dir.z > 0.0 ? true : false;

    // As per Renderman specifications:
    //  ma is largest magnitude coordinate direction.
    //  sc = s-coordinate
    //  tc = t-coordinate
    float ma, sc, tc;

    if (absV.x >= absV.y && absV.x >= absV.z) {
        ma = absV.x;
        if (isXPositive) {
            // POSITIVE X
            // u (0 to 1) goes from +z to -z
            // v (0 to 1) goes from -y to +y
            sc = -dir.z;
            tc =  dir.y;
            faceIndex = 0;
        }
        else {
            // NEGATIVE X
            // u (0 to 1) goes from -z to +z
            // v (0 to 1) goes from -y to +y
            sc = dir.z;
            tc = dir.y;
            faceIndex = 1;
        }
    }
    else if (absV.y >= absV.x && absV.y >= absV.z) {
        ma = absV.y;
        if (isYPositive) {
            // POSITIVE Y
            // u (0 to 1) goes from -x to +x
            // v (0 to 1) goes from +z to -z
            sc =  dir.x;
            tc = -dir.z;
            faceIndex = 2;
        }
        else {
            // NEGATIVE Y
            // u (0 to 1) goes from -x to +x
            // v (0 to 1) goes from -z to +z
            sc = dir.x;
            tc = dir.z;
            faceIndex = 3;
        }
    }
    else if (absV.z >= absV.x && absV.z >= absV.y) {
        ma = absV.z;
        if (isZPositive) {
            // POSITIVE Z
            // u (0 to 1) goes from -x to +x
            // v (0 to 1) goes from -y to +y
            // Position Z
            sc = dir.x;
            tc = dir.y;
            faceIndex = 4;
        }
        else {
            // NEGATIVE Z
            // u (0 to 1) goes from +x to -x
            // v (0 to 1) goes from -y to +y
            sc = -dir.x;
            tc =  dir.y;
            faceIndex = 5;
        }
    }
    /*
        s   =   ( sc/|ma| + 1 ) / 2
        t   =   ( tc/|ma| + 1 ) / 2
     */
    vec2 uv;
    // Convert range from -1 to 1 to 0 to 1
    uv.x = 0.5f * (sc / ma + 1.0);
    uv.y = 0.5f * (tc / ma + 1.0);
    return uv;
}

/*
 Assume we have a 4x3 canvas consisting of 12 squares each having
  an area of 1x1 squared unit. In other words, the entire canvas is a
  rectangular grid of 12 squared units.
 We are only interested in 6 of those squares which make up the
  horizontal cross. We map the input uv to one of these 6 squares.
 Then we scale the resulting uv by 4x3 which can then be used to
  access the texture which has a resolution of 4:3.
 We are using a texture with dimensions 2048 by 1536 pixels.
 (4x512 by 3x512)
 This idea can be applied to map the input uv to any 2D texture
 e.g.
 a) vertical cross layout (3x4)
 b) vertical strip layout(1x6)
 c) horizontal strip layout(6x1)
 d) compact layout (3x2)
 */
vec2 mappingTo4by3(vec2 uv, int faceIndex) {
    // The coords of bottom left corner of 6 faces of the horizontal cross.
    const vec2 translateVectors[6] = vec2[6](vec2(2.0, 1.0),    // bottom left of face +X
                                             vec2(0.0, 1.0),    // bottom left of face -X
                                             vec2(1.0, 2.0),    // bottom left of face +Y
                                             vec2(1.0, 0.0),    // bottom left of face -Y
                                             vec2(1.0, 1.0),    // bottom left of face +Z
                                             vec2(3.0, 1.0));   // bottom left of face -Z

    // Map it to a point on a 4:3 quad made up of 12 squares of 1x1 unit squared.
    uv += translateVectors[faceIndex];
    // Scale it down so that we can access the pixels of the texture passed as a uniform.
    uv /= dim;

    return uv;
}


void main(void) {
    // [0, width] & [0, height]
    vec2 fragCoord = vec2(gl_FragCoord.xy);
    vec2 mouseUV = iMouse;
    if (mouseUV == vec2(0.0, 0.0))
        mouseUV = vec2(iResolution/2.0);
    // rotX
    // 1) Get mouse position between 0 and 1
    // 2) Multiply by 2pi
    // rotX varies between 0 and 2π
    // rotY varies between 0 and π
    // 0 at left side, 2π at right
    float rotX = (mouseUV.x / iResolution.x) * 2.0 * PI;
    float rotY = (mouseUV.y / iResolution.y) * PI;

    // Calculate the camera's orientation
    vec3 camO = vec3(cos(rotX), cos(rotY), sin(rotX));

    // The forward vector - the camera is at centre (0.0, 0.0, 0.0) of the cube.
    vec3 camD = normalize(vec3(0) - camO);

    // The vec3(0, 1, 0) does not have to be perpendicular to camD.
    // The right vector is orthogonal to both camD and vec3(0, 1, 0).
    vec3 camR = normalize(cross(camD, vec3(0, 1, 0)));

    // Calculate the UP vector wrt to the camera (no need to normalize
    // since the right and forward vectors are already unit vectors.)
    // The vectors camD, camR and camU are mutually orthogonal vectors.
    // These 3 vectors can form a set of orthonormal basis vectors.
    vec3 camU = cross(camR, camD);

    vec2 uv = 2.5 * (fragCoord.xy - 0.5 * iResolution.xy) / iResolution.xx;
    
    // Compute the ray direction
    vec3 dir =  normalize(camD + uv.x * camR + uv.y * camU);
    // Need to flip horizontally.
    dir.z = -dir.z;

    int faceIndex;
    uv = dirToCubeUV(dir, faceIndex);
    uv = mappingTo4by3(uv, faceIndex);

#if __VERSION__ >= 140
    FragColor = texture(image, uv);
#else
    gl_FragColor = texture2D(image, uv);
#endif
}
