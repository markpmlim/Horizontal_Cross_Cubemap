This project consists of a simple program to demonstrate how to render a 3D skybox from 2D horizontal cross cubemap. 

![](HorzCross.png)

The dimensions of the 2D image must be in the ratio 4:3.

 Instantiation of a 2D OpenGL texture from High Dynamic Radiance (hdr) files is supported. The graphics engine is Apple's OpenGL implementation for the macOS or its OpenGLES implementation for the iOS.

Testing is done only for modern OpenGL 3.2 and OpenGLES 3.0.
<br />
<br />
<br />

**HorizontalCrossCubemap** 

For macOS programmers, creating cubemaps from six 2D textures is straightforward when the Graphics Engine is OpenGL. There are two GLKTextureLoader class methods

```swift
    cubeMap(withContentsOfFile:, options:)
```
and 

```swift
    cubeMap(withContentsOf:, options:)
```

which when call will instantiate an OpenGL cubemap texture and return an instance of GLKTextureInfo containing information about the newly created texture. The "name" property is texture name that is used for binding with the call:

```c
    glBindTexture(GLenum target, GLuint texture);
```

where target is GL_TEXTURE_CUBE_MAP whenever the skybox needs to be drawn as part of the update process. (The class GLKTextureLoader was available for iOS 5.0 and macOS 10.8).

The demo will be using the GLKTextureLoader call:

```swift
    texture(withContentsOf: options:)
```

to load a 2D image file with a resolution of 2048:1536 (ratio 4:3) for filetype png or a custom C call

```c
    textureFromRadianceFile(const char *pathName, int *width, int *height)
```

to load high dynamic range images and create a 2D texture.

Once the 2D texture (of type GL_TEXTURE_2D) are instantiated and the setup is complete, the draw() is called to render the 3D skybox.

To allow the user to observe the skybox, a simple camera (based on raytracing) is implemented.

Basically, the vertex shader produces a large triangle which is clipped by OpenGL into a quad.

The fragment shader receives some uniforms from the CPU side to help setup a simple camera. All the user needs to do is drag the mouse (use a one-finger touch for iOS devices) to look around the skybox.

In order to access a cubemap texture, a 3D direction must be produce from the mouse drags. The direction is converted into a faceIndex and a pair of uv coodinates by calling the function

```glsl
    dirToCubeUV(vec3 dir, out int faceIndex)
```

Applying a simple mapping system will access to the pixels of the correct square of the 4:3 grid.

<br />
<br />
<br />

**Requirements:** XCode 9.x, Swift 4.x and macOS 10.13.4 or later.
<br />
<br />

**References:**







