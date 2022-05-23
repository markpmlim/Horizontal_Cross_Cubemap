//
//  OpenGLRenderer.swift
//  HorizontalCrossCubemap
//
//  Created by Mark Lim Pak Mun on 20/05/2022.
//  Copyright © 2022 mark lim pak mun. All rights reserved.
//

#if os(iOS)
import UIKit
import OpenGLES
#else
import AppKit
import OpenGL.GL3
#endif

import simd
import GLKit


class OpenGLRenderer: NSObject {
    var _defaultFBOName: GLuint = 0
    var _viewSize: CGSize = CGSize()
    var glslProgram: GLuint = 0
    // Parameters to be passed to the fragment shader.
    // The origin is at the left hand corner
    var mouseCoords: [GLfloat] = [0.0, 0.0]
    var currentTime: GLfloat = 0.0
    var resolutionLoc: GLint = 0
    var mouseLoc: GLint = 0
    var timeLoc: GLint = 0

    var triangleVAO: GLuint = 0
    var _projectionMatrix = matrix_identity_float4x4
    var textureID: GLuint = 0
    var u_tex0Resolution: [GLfloat] = [0.0, 0.0]

    init(_ defaultFBOName: GLuint) {
        super.init()
        // Build all of your objects and setup initial state here.
        _defaultFBOName = defaultFBOName
        //Swift.print(_defaultFBOName)
        let vertexSourceURL = Bundle.main.url(forResource: "VertexShader",
                                              withExtension: "glsl");

        let fragmentSourceURL = Bundle.main.url(forResource: "FragmentShader",
                                                withExtension: "glsl");
        textureID = loadTexture("HorizontalCross.hdr",
                                resolution: &u_tex0Resolution,
                                isHDR: true)
        //Swift.print("texture size:", u_tex0Resolution)
        glslProgram = buildProgram(with: vertexSourceURL!,
                                   and: fragmentSourceURL!)
        resolutionLoc = glGetUniformLocation(glslProgram, "u_resolution")
        mouseLoc = glGetUniformLocation(glslProgram, "u_mouse")
        timeLoc = glGetUniformLocation(glslProgram, "u_time")

        glGenVertexArrays (1, &triangleVAO);    // Required
    }

    private func updateTime() {
        currentTime += 1/60
    }

    // Main draw function. Called by both iOS and macOS modules.
    func draw() {
        updateTime()
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT) | GLbitfield(GL_DEPTH_BUFFER_BIT))
        glClearColor(0.5, 0.5, 0.5, 1.0)

        glViewport(0, 0,
                   (GLsizei)(_viewSize.width),
                   (GLsizei)(_viewSize.height))
        glBindVertexArray(triangleVAO)
        glUseProgram(glslProgram)
        //glUniform2fv(resolutionLoc, 1, u_tex0Resolution)
        glUniform2f(resolutionLoc,
                    GLfloat(_viewSize.width), GLfloat(_viewSize.height))
        glUniform1f(timeLoc, GLfloat(currentTime))
        glUniform2fv(mouseLoc, 1, mouseCoords)
        glActiveTexture(GLenum(GL_TEXTURE0))
        glBindTexture(GLenum(GL_TEXTURE_2D), textureID)
        glDrawArrays(GLenum(GL_TRIANGLES), 0, 3)
        glUseProgram(0)
        glBindVertexArray(0)
    }

    func resize(_ size: CGSize) {
        _viewSize = size
        let aspect = (Float)(size.width) / (Float)(size.height)
        // The projection Matrix is not used.
        _projectionMatrix = matrix_perspective_left_hand(65.0 * (Float.pi / 180.0),
                                                         aspect,
                                                         1.0, 5000.0);
    }

    // Returns an OpenGL texture name (id) & the texture's width and height.
    func loadTexture(_ name : String, resolution: inout [GLfloat],
                     isHDR: Bool) -> GLuint {
        let mainBundle = Bundle.main
        var width: Int32 = 0
        var height: Int32  = 0
        var textureID: UInt32 = 0
        if isHDR {
            let subStrings = name.components(separatedBy:".")
            guard let filePath = mainBundle.path(forResource: subStrings[0],
                                           ofType: subStrings[1])
            else {
                Swift.print("The file \(name) is not available")
                exit(1)
            }
            textureID = textureFromRadianceFile(filePath, &width, &height)
            resolution[0] = GLfloat(width)
            resolution[1] = GLfloat(height)
        }
        else {
            let subStrings = name.components(separatedBy:".")
            guard let url = mainBundle.url(forResource: subStrings[0],
                                           withExtension: subStrings[1])
                else {
                    Swift.print("File \(name): not found")
                    exit(2)
            }
            var textureInfo: GLKTextureInfo!
            do {
                let options: [String : NSNumber] = [
                    GLKTextureLoaderOriginBottomLeft: NSNumber(value: true)
                ]
                textureInfo = try GLKTextureLoader.texture(withContentsOf: url,
                                                           options: options)
            }
            catch let error {
                fatalError("Error loading picture file:\(error)")
            }
            resolution[0] = GLfloat(textureInfo.width)
            resolution[1] = GLfloat(textureInfo.height)
            textureID = textureInfo.name
        }
        return textureID
    }

    /*
     Only expect a pair of vertex and fragment shaders.
     This function should work for both fixed pipeline and modern OpenGL syntax.
     */
    func buildProgram(with vertSrcURL: URL,
                      and fragSrcURL: URL) -> GLuint {
        // Prepend the #version preprocessor directive to the vertex and fragment shaders.
        var  glLanguageVersion: Float = 0.0
        let glslVerstring = String(cString: glGetString(GLenum(GL_SHADING_LANGUAGE_VERSION)))
    #if os(iOS)
        let index = glslVerstring.index(glslVerstring.startIndex, offsetBy: 18)
    #else
        let index = glslVerstring.index(glslVerstring.startIndex, offsetBy: 0)
    #endif
        let range = index..<glslVerstring.endIndex
        let verStr = glslVerstring.substring(with: range)

        let scanner = Scanner(string: verStr)
        scanner.scanFloat(&glLanguageVersion)
        // We need to convert the float to an integer and then to a string.
        var shaderVerStr = String(format: "#version %d", Int(glLanguageVersion*100))
    #if os(iOS)
        if EAGLContext.current().api == .openGLES3 {
            shaderVerStr = shaderVerStr.appending(" es")
        }
    #endif

        var vertSourceString = String()
        var fragSourceString = String()
        do {
            vertSourceString = try String(contentsOf: vertSrcURL)
        }
        catch _ {
            Swift.print("Error loading vertex shader")
        }

        do {
            fragSourceString = try String(contentsOf: fragSrcURL)
        }
        catch _ {
            Swift.print("Error loading fragment shader")
        }
        vertSourceString = shaderVerStr + "\n" + vertSourceString
        //Swift.print(vertSourceString)
        fragSourceString = shaderVerStr + "\n" + fragSourceString
        //Swift.print(fragSourceString)

        // Create a GLSL program object.
        let prgName = glCreateProgram()

        // We can choose to bind our attribute variable names to specific
        //  numeric attribute locations. Must be done before linking.
        //glBindAttribLocation(prgName, AAPLVertexAttributePosition, "a_Position")

        let vertexShader = glCreateShader(GLenum(GL_VERTEX_SHADER))
        var cSource = vertSourceString.cString(using: .utf8)!
        var glcSource: UnsafePointer<GLchar>? = UnsafePointer<GLchar>(cSource)
        glShaderSource(vertexShader, 1, &glcSource, nil)
        glCompileShader(vertexShader)

        var compileStatus : GLint = 0
        glGetShaderiv(vertexShader, GLenum(GL_COMPILE_STATUS), &compileStatus)
        if compileStatus == GL_FALSE {
            var infoLength : GLsizei = 0
            glGetShaderiv(vertexShader, GLenum(GL_INFO_LOG_LENGTH), &infoLength)
            if infoLength > 0 {
                // Convert an UnsafeMutableRawPointer to UnsafeMutablePointer<GLchar>
                let log = malloc(Int(infoLength)).assumingMemoryBound(to: GLchar.self)
                glGetShaderInfoLog(vertexShader, infoLength, &infoLength, log)
                let errMsg = NSString(bytes: log,
                                      length: Int(infoLength),
                                      encoding: String.Encoding.ascii.rawValue)
                print(errMsg!)
                glDeleteShader(vertexShader)
                free(log)
            }
        }
        // Attach the vertex shader to the program.
        glAttachShader(prgName, vertexShader);

        // Delete the vertex shader because it's now attached to the program,
        //  which retains a reference to it.
        glDeleteShader(vertexShader);

        /*
         * Specify and compile a fragment shader.
         */
        let fragmentShader = glCreateShader(GLenum(GL_FRAGMENT_SHADER))
        cSource = fragSourceString.cString(using: .utf8)!
        glcSource = UnsafePointer<GLchar>(cSource)
        glShaderSource(fragmentShader, 1, &glcSource, nil)
        glCompileShader(fragmentShader)

        glGetShaderiv(fragmentShader, GLenum(GL_COMPILE_STATUS), &compileStatus)
        if compileStatus == GL_FALSE {
            var infoLength : GLsizei = 0
            glGetShaderiv(fragmentShader, GLenum(GL_INFO_LOG_LENGTH), &infoLength)
            if infoLength > 0 {
                // Convert an UnsafeMutableRawPointer to UnsafeMutablePointer<GLchar>
                let log = malloc(Int(infoLength)).assumingMemoryBound(to: GLchar.self)
                glGetShaderInfoLog(fragmentShader, infoLength, &infoLength, log)
                let errMsg = NSString(bytes: log,
                                      length: Int(infoLength),
                                      encoding: String.Encoding.ascii.rawValue)
                print(errMsg!)
                glDeleteShader(fragmentShader)
                free(log)
            }
        }

        // Attach the fragment shader to the program.
        glAttachShader(prgName, fragmentShader)

        // Delete the fragment shader because it's now attached to the program,
        //  which retains a reference to it.
        glDeleteShader(fragmentShader)

        /*
         * Link the program.
         */
        var linkStatus: GLint = 0
        glLinkProgram(prgName)
        glGetProgramiv(prgName, GLenum(GL_LINK_STATUS), &linkStatus)

        if (linkStatus == GL_FALSE) {
            var logLength : GLsizei = 0
            glGetProgramiv(prgName, GLenum(GL_INFO_LOG_LENGTH), &logLength)
            if (logLength > 0) {
                let log = malloc(Int(logLength)).assumingMemoryBound(to: GLchar.self)
                glGetProgramInfoLog(prgName, logLength, &logLength, log)
                NSLog("Program link log:\n%s.\n", log)
                free(log)
            }
        }

        // We can locate all uniform locations here
        //let samplerLoc = glGetUniformLocation(prgName, "image")
        //Swift.print(samplerLoc)

        //getGLError()
        return prgName
    }
}
