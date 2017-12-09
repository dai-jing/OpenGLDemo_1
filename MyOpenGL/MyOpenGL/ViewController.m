//
//  ViewController.m
//  MyOpenGL
//
//  Created by Kobe Dai on 06/12/2017.
//  Copyright © 2017 daijing. All rights reserved.
//

/**
 *  EAGL (Embedded Apple Graphics Library）嵌入式苹果图形库，和CAEAGLLayer中的是一样的。
 */

#import "ViewController.h"

@interface ViewController ()

@property (nonatomic, strong) EAGLContext *context;
@property (nonatomic, assign) GLuint shaderProgram;
@property (nonatomic, assign) GLfloat count;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self setupContext];
    [self setupShader];
}

- (void)setupContext {
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    [EAGLContext setCurrentContext:self.context];
}

- (void)setupShader {
    NSString *vertexShaderPath = [[NSBundle mainBundle] pathForResource:@"vertex" ofType:@"glsl"];
    NSString *fragmentShaderPath = [[NSBundle mainBundle] pathForResource:@"fragment" ofType:@"glsl"];
    NSString *vertexShaderContent = [NSString stringWithContentsOfFile:vertexShaderPath encoding:NSUTF8StringEncoding error:nil];
    NSString *fragmentShaderContent = [NSString stringWithContentsOfFile:fragmentShaderPath encoding:NSUTF8StringEncoding error:nil];
    GLuint program;
    createProgram(vertexShaderContent.UTF8String, fragmentShaderContent.UTF8String, &program);
    self.shaderProgram = program;
}

- (void)update {
    if (self.count >= 100) {
        self.count = -1;
    } else if (self.count <= -100) {
        self.count = 1;
    }
    if (self.count >= 0) {
        self.count++;
    } else {
        self.count--;
    }
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    // 清空之前的绘制
    glClearColor(1.f, 1.f, 1.f, 1.f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    // 使用fragment.glsl 和 vertex.glsl中的shader
    glUseProgram(self.shaderProgram);
    
    GLuint countUniformLocation = glGetUniformLocation(self.shaderProgram, "count");
    glUniform1f(countUniformLocation, self.count);
    
    [self drawRectangle];
}

- (void)drawRectangle {
    /**
     *  1. Vertex Data: e.g. square meshes provided by 3D modeling tools
     */
    static GLfloat vertextData[24] = {
        -0.5f,  0.5f, 0, 1, 0, 0,   // x, y, z, r, g, b
        0.5f,   0.5f, 0, 0, 0, 0,
        -0.5f, -0.5f, 0, 0, 1, 0,
        0.5f,  -0.5f, 0, 0, 0, 1,
    };
    
    /**
     *  2. Vertex Shader: a small program in GLSL(OpenGL Shading Language) is applied to each vertext
     *
     *  为shader中的position和color赋值
     *
     *  如何将顶点数据传递给Shader: 顶点数据只会传递给Vertex Shader，所以不能把attribute vec4 position写到Fragment Shader里
     */
    GLuint positionAttribLocation = glGetAttribLocation(self.shaderProgram, "position");    // get position attribute in shader
    glEnableVertexAttribArray(positionAttribLocation);                                      // enable position attribute in shader
    GLuint colorAttribLocation = glGetAttribLocation(self.shaderProgram, "color");          // get position color in shader
    glEnableVertexAttribArray(colorAttribLocation);                                         // enable color attribute in shader
    
    // 激活Vertex Shader中的属性后就可以传值给它了，下面是传值代码
    // 告诉Vertex Shader，向位置属性传递的数据大小是3个GLfloat，每个顶点数据有6个GLfloat，位置数据起始的指针是(char *)vertextData。
    // OpenGL读取完第一个位置数据后，就会将指针增加6个GLfloat的大小，访问下一个顶点位置。颜色也是相同的道理
    glVertexAttribPointer(positionAttribLocation, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(GLfloat), (char *)vertextData);                     // position attribute
    glVertexAttribPointer(colorAttribLocation, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(GLfloat), (char *)vertextData + 3 * sizeof(GLfloat));  // color attribute
    
    /**
     *  3. Primitive Assembly: setup of primitives, e.g. triangles, lines, and points
     *
     *  以形状为单位汇总渲染指令，为下一步栅格化颜色插值做准备
     */
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    /**
     *  4. Rasterization: interpolation of data(e.g. color) for all pixels covered by the primitive
     */
    
    /**
     *  5. Fragment Shader: a small program in GLSL is applied to each fragment(i.e. covered pixel)
     */
    
    /**
     *  6. Pre-Fragment Operations: configurable operations on each fragment(i.e. covered pixel)
     *
     *  处理OpenGL对像素的一些固定操作。比如深度测试，剪裁测试等。通过OpenGL的API进行配置。
     */
    
    /**
     *  7. Framebuffer: array of pixels in which the computed fragment colors are stored
     *
     *  最终写入Framebuffer，交换缓冲区后显示在窗口上。
     */
}

#pragma mark - <Prepare Shaders>

bool createProgram(const char *vertexShader, const char *fragmentShader, GLuint *pProgram) {
    GLuint program, vertShader, fragShader;
    // Create shader program.
    program = glCreateProgram();
    
    const GLchar *vssource = (GLchar *)vertexShader;
    const GLchar *fssource = (GLchar *)fragmentShader;
    
    if (!compileShader(&vertShader,GL_VERTEX_SHADER, vssource)) {
        printf("Failed to compile vertex shader");
        return false;
    }
    
    if (!compileShader(&fragShader,GL_FRAGMENT_SHADER, fssource)) {
        printf("Failed to compile fragment shader");
        return false;
    }
    
    // Attach vertex shader to program.
    glAttachShader(program, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(program, fragShader);
    
    // Link program.
    if (!linkProgram(program)) {
        printf("Failed to link program: %d", program);
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (program) {
            glDeleteProgram(program);
            program = 0;
        }
        return false;
    }
    
    // Release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(program, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(program, fragShader);
        glDeleteShader(fragShader);
    }
    
    *pProgram = program;
    printf("Effect build success => %d \n", program);
    return true;
}


bool compileShader(GLuint *shader, GLenum type, const GLchar *source) {
    GLint status;
    
    if (!source) {
        printf("Failed to load vertex shader");
        return false;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    
#if Debug
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        printf("Shader compile log:\n%s", log);
        printf("Shader: \n %s\n", source);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return false;
    }
    
    return true;
}

bool linkProgram(GLuint prog) {
    GLint status;
    glLinkProgram(prog);
    
#if Debug
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        printf("Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return false;
    }
    
    return true;
}

bool validateProgram(GLuint prog) {
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        printf("Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0) {
        return false;
    }
    
    return true;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
