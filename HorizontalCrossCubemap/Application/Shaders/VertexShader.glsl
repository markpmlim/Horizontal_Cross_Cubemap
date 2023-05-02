#if __VERSION__ >= 140
out vec2 texCoords;

#else
varying vec2 texCoords;
#endif


/*
 https://rauwendaal.net/2014/06/14/rendering-a-screen-covering-triangle-in-opengl/

 No geometry are passed to this vertex shader; the range of gl_VertexID: [0, 2]
 The position and texture coordinates attributes of 3 vertices are
 generated on the fly.
 position: (-1.0, -1.0), (3.0, -1.0), (-1.0, 3.0)
       uv: ( 0.0,  0.0), (2.0,  0.0), ( 0.0, 2.0)
 The area of the generated triangle covers the entire clip space.
 Note: any geometry rendered outside this 2D space is clipped.
 Clip space:
 Range of position: [-1.0, 1.0] both horizontally and vertically.
 Range of       uv: [ 0.0, 1.0] both horizontally and vertically.
 The origin of the uv axes starts at the bottom left corner of the
 2D NDC space with u-axis from left to right and
 v-axis from bottom to top.
 For the mathematically-inclined, the line y = -x + 2 is the hypotenuse of a
  right-angled triangle. The other 2 lines are x = -1.0 and y = -1.0.
 The points (3.0, -1.0) and (-1.0, 3.0) lie on the sloping line.
 The last point (-1.0, -1.0) lie on x = -1.0 and y = -1.0.
 */
void main(void)
{
    float x = float((gl_VertexID & 1) << 2);
    float y = float((gl_VertexID & 2) << 1);
    texCoords = vec2(x * 0.5, y * 0.5);
    gl_Position = vec4(x - 1.0, y - 1.0, 0, 1);
}
