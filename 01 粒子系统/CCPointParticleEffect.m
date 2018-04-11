//
//  CCPointParticleEffect.m
//  01 粒子系统
//
//  Created by CC老师 on 2018/2/25.
//  Copyright © 2018年 CC老师. All rights reserved.
//

#import "CCPointParticleEffect.h"
#import "CCVertexAttribArrayBuffer.h"


//用于定义粒子属性的类型
typedef struct
{
    GLKVector3 emissionPosition;//发射位置
    GLKVector3 emissionVelocity;//发射速度
    GLKVector3 emissionForce;//发射重力
    GLKVector2 size;//发射大小
    GLKVector2 emissionTimeAndLife;//发射时间和寿命
}CCParticleAttributes;

//GLSL程序Uniform 参数
enum
{
    CCMVPMatrix,//MVP矩阵
    CCSamplers2D,//Samplers2D纹理
    CCElapsedSeconds,//耗时
    CCGravity,//重力
    CCNumUniforms//Uniforms个数
};

//属性标识符
typedef enum {
    CCParticleEmissionPosition = 0,//粒子发射位置
    CCParticleEmissionVelocity,//粒子发射速度
    CCParticleEmissionForce,//粒子发射重力
    CCParticleSize,//粒子发射大小
    CCParticleEmissionTimeAndLife,//粒子发射时间和寿命
} CCParticleAttrib;

@interface CCPointParticleEffect()
{
    GLfloat elapsedSeconds;//耗时
    GLuint program;//程序
    GLint uniforms[CCNumUniforms];//Uniforms数组
}

//顶点属性数组缓冲区
@property (strong, nonatomic, readwrite)CCVertexAttribArrayBuffer  * particleAttributeBuffer;

//粒子个数
@property (nonatomic, assign, readonly) NSUInteger numberOfParticles;

//粒子属性数据
@property (nonatomic, strong, readonly) NSMutableData *particleAttributesData;

//是否更新粒子数据
@property (nonatomic, assign, readwrite) BOOL particleDataWasUpdated;

//加载shaders
- (BOOL)loadShaders;

//编译shaders
- (BOOL)compileShader:(GLuint *)shader
                 type:(GLenum)type
                 file:(NSString *)file;
//链接Program
- (BOOL)linkProgram:(GLuint)prog;

//验证Program
- (BOOL)validateProgram:(GLuint)prog;

@end

@implementation CCPointParticleEffect

@synthesize gravity;
@synthesize elapsedSeconds;
@synthesize texture2d0;
@synthesize transform;
@synthesize particleAttributeBuffer;
@synthesize particleAttributesData;
@synthesize particleDataWasUpdated;

//初始化
-(id)init
{
    self = [super init];
    if (self != nil) {
        
       //初始化纹理
        texture2d0 = [[GLKEffectPropertyTexture alloc]init];
        texture2d0.enabled = YES;
        texture2d0.name = 0;
        texture2d0.target = GLKTextureTarget2D;
        
        texture2d0.envMode = GLKTextureEnvModeReplace;
        
        //设置transform 坐标信息转换，相当于变换管道
        transform = [[GLKEffectPropertyTransform alloc]init];
        //初始化重力
        gravity = CCDefaultGravity;
        
        // 耗时
        elapsedSeconds = 0.0f;
        
        //创建粒子数据
        particleAttributesData = [[NSMutableData alloc]init];
    }
    
    return self;
}

//获取粒子的属性值
- (CCParticleAttributes)particleAtIndex:(NSUInteger)anIndex
{
    
    //获取数据
    const CCParticleAttributes *particlesPtr = (CCParticleAttributes *)[self.particleAttributesData bytes];
    
    return particlesPtr[anIndex];
}


//设置粒子的属性
- (void)setParticle:(CCParticleAttributes)aParticle
            atIndex:(NSUInteger)anIndex
{
    //拿到对应的粒子
    CCParticleAttributes *particlesPtr = (CCParticleAttributes *)[self.particleAttributesData mutableBytes];
    particlesPtr[anIndex] = aParticle;
    
    //粒子是否更新
    self.particleDataWasUpdated = YES;

}

//添加一个粒子
- (void)addParticleAtPosition:(GLKVector3)aPosition
                     velocity:(GLKVector3)aVelocity
                        force:(GLKVector3)aForce
                         size:(float)aSize
              lifeSpanSeconds:(NSTimeInterval)aSpan
          fadeDurationSeconds:(NSTimeInterval)aDuration;
{
    //创建一个新的粒子
    CCParticleAttributes newParticle;
    //设置相关参数 位置/速度/重力/大小/耗时
    newParticle.emissionPosition = aPosition;
    newParticle.emissionVelocity = aVelocity;
    newParticle.emissionForce = aForce;
    newParticle.size = GLKVector2Make(aSize, aDuration);
    newParticle.emissionTimeAndLife = GLKVector2Make(elapsedSeconds, elapsedSeconds+aSpan);
    
    //是否可以复用
    BOOL foundSlot = NO;
    
    //粒子的个数
    const long count = self.numberOfParticles;
    
    //循环创建例子
    for (int i=0; i<count && foundSlot; i++) {
        //获取当前旧的粒子
        CCParticleAttributes oldParticle = [self particleAtIndex:i];
        if(oldParticle.emissionTimeAndLife.y<self.elapsedSeconds){
            //更新粒子
            [self setParticle:newParticle atIndex:i];
            
            //是否替换
            foundSlot = YES;
        }
        
    }
    
    //如果不替换
    if(!foundSlot){
        //在粒子的数据中添加数据
        [self.particleAttributesData appendBytes:&newParticle length:sizeof(newParticle)];
        
        //粒子数据是否更新
        self.particleDataWasUpdated = YES;
    }
    

}

//获取粒子个数
- (NSUInteger)numberOfParticles;
{
    //获取粒子个数
    static long last;
    //总数据大小/单个粒子结构体大小
    long ret = [self.particleAttributesData length]/sizeof(CCParticleAttributes);
    
    if(last != ret){
        last = ret;
        NSLog(@"count %ld",ret);
    }
 
    return ret;
}


- (void)prepareToDraw
{
   //准备绘制的前提是 有数据
    if(program == 0){
//        加载shader
        [self loadShaders];
    }
    if(program != 0){
        //使用program
        glUseProgram(program);
        
        //实现矩阵变换
        GLKMatrix4 modelViewProjectionMatrix = GLKMatrix4Multiply(self.transform.projectionMatrix, self.transform.modelviewMatrix);
        
        //通过uniform传结果
        glUniformMatrix4fv(uniforms[CCMVPMatrix], 1, 0, modelViewProjectionMatrix.m);
        
        //纹理采样
        glUniform1i(uniforms[CCSamplers2D], 0);
        
        //粒子的物理重力
        glUniform3fv(uniforms[CCGravity], 1, self.gravity.v);
        
        //耗时
        glUniform1fv(uniforms[CCElapsedSeconds], 1, &elapsedSeconds);
        
        if(self.particleDataWasUpdated){
            if(self.particleAttributeBuffer == nil && [self.particleAttributesData length]>0){
                //将顶点数据送GPU
                //数据大小
                GLsizeiptr size = sizeof(CCParticleAttributes);
                //个数
                int count = (int)self.particleAttributesData.length / sizeof(CCParticleAttributes);
                self.particleAttributeBuffer = [[CCVertexAttribArrayBuffer alloc]initWithAttribStride:size numberOfVertices:count bytes:self.particleAttributesData.bytes usage:GL_DYNAMIC_DRAW];
            }else{
                //为新的数据开辟新的缓冲区
                //数据大小
                GLsizeiptr size = sizeof(CCParticleAttributes);
                
                //个数
                int count = (int)self.particleAttributesData.length / size;
                 [self.particleAttributeBuffer  reinitWithAttribStride:size numberOfVertices:count bytes:[self.particleAttributesData bytes]];
            }
            
            //恢复
            self.particleDataWasUpdated = NO;
        }
        
        //准备绘制数据 把顶点数据放缓存区
        [self.particleAttributeBuffer prepareToDrawWithAttrib:CCParticleEmissionPosition numberOfCoordinates:3 attribOffset:offsetof(CCParticleAttributes, emissionPosition) shouldEnable:YES];
        //发射速度
        [self.particleAttributeBuffer prepareToDrawWithAttrib:CCParticleEmissionVelocity numberOfCoordinates:3 attribOffset:offsetof(CCParticleAttributes, emissionVelocity) shouldEnable:YES];
        
        //重力数据
        [self.particleAttributeBuffer prepareToDrawWithAttrib:CCParticleEmissionForce numberOfCoordinates:3 attribOffset:offsetof(CCParticleAttributes, emissionForce) shouldEnable:YES];
        
        //大小数据
        [self.particleAttributeBuffer prepareToDrawWithAttrib:CCParticleSize numberOfCoordinates:2 attribOffset:offsetof(CCParticleAttributes, size) shouldEnable:YES];
        //耗时持续
        [self.particleAttributeBuffer prepareToDrawWithAttrib:CCParticleEmissionTimeAndLife numberOfCoordinates:2 attribOffset:offsetof(CCParticleAttributes, emissionTimeAndLife) shouldEnable:YES];
        
        //纹理单元
        glActiveTexture(GL_TEXTURE0);
        
        //判断纹理标记是否为空
        if(self.texture2d0.name != 0 && self.texture2d0.enabled){
            //绑定纹理
            glBindTexture(GL_TEXTURE_2D, self.texture2d0.name);
        }else{
            glBindTexture(GL_TEXTURE_2D, 0);
        }
    }

}

//绘制
- (void)draw;
{
    glDepthMask(GL_FALSE);
    
    //绘制
    [self.particleAttributeBuffer drawArrayWithMode:GL_POINTS startVertexIndex:0 numberOfVertices:(int)self.numberOfParticles];
    
    glDepthMask(GL_TRUE);

    
}

#pragma mark -  OpenGL ES shader compilation

- (BOOL)loadShaders
{
    GLuint vertShader,fragShader;
    NSString *vertShaderPathName,*fragShaderPathName;
    //创建program
    program = glCreateProgram();
    
    //指定顶点着色器路径以及片元着色器路径
    vertShaderPathName = [[NSBundle mainBundle] pathForResource:@"CCPointParticleShader" ofType:@"vsh"];
    //编译顶点着色器
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathName]) {
        NSLog(@"Failed to complie vertex shader");
        return NO;
    }
    
    //指定片元着色器路径
    fragShaderPathName = [[NSBundle mainBundle] pathForResource:@"CCPointParticleShader" ofType:@"fsh"];
    
    //编译片元着色器
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathName]) {
        NSLog(@"Failed to complie vertex shader");
        return NO;
    }
    
    //顶点着色器附着到program
    glAttachShader(program, vertShader);
    glAttachShader(program, fragShader);
    
    //绑定属性的位置 在link之前绑定
    glBindAttribLocation(program, CCParticleEmissionPosition, "a_emissonPosition");
    glBindAttribLocation(program, CCParticleEmissionVelocity, "a_emissionVelocity");
    glBindAttribLocation(program, CCParticleEmissionForce, "a_emissionForce");
    glBindAttribLocation(program, CCParticleSize, "a_size");
    glBindAttribLocation(program, CCParticleEmissionTimeAndLife, "a_emissionAndDeathTimes");
    //link
    if (![self linkProgram:program]) {
        NSLog(@"Failed to link Program!%d",program);
        if(vertShader){
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if(fragShader){
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if(program){
            glDeleteProgram(program);
            program = 0;
        }
        return NO;
    }
    //获取uniform变量的位置
    uniforms[CCMVPMatrix] = glGetUniformLocation(program, "u_mvpMatrix");
    uniforms[CCSamplers2D] = glGetUniformLocation(program, "u_samplers2D");
    uniforms[CCGravity] = glGetUniformLocation(program, "u_garvity");
    uniforms[CCElapsedSeconds] = glGetUniformLocation(program, "u_elapsedSeconds");
    
    //使用完，删除
    if (vertShader) {
        glDetachShader(program, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(program, fragShader);
        glDeleteShader(fragShader);
    }
    return YES;
}


//编译shader
- (BOOL)compileShader:(GLuint *)shader
                 type:(GLenum)type
                 file:(NSString *)file
{
    //路径--C语言
    //    OC string -> Char *
    const GLchar *source;
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    
    if (!source) {
        NSLog(@"Failed to compile vertex/ shader");
        return NO;
    }
    //shader是地址，要拿到变量需要加*;
    *shader = glCreateShader(type);
    
    //绑定shader
    glShaderSource(*shader, 1, &source, NULL);
    
    //编译shader
    glCompileShader(*shader);
    
    //获取加载shader的日志信息
    GLint logLength;
    //参数1shader值  参数2获取信息类型编译状态，日志长度，着色器源文件长度
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength>0) {
        //创建日志字符串
        GLchar *log = (GLchar *)malloc(logLength);
        
        //获取日志信息
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        //打印日志 char* 对应%s
        NSLog(@"shader compile log:%s\n",log);
        
        free(log);
        return 0;
        
    }
    return YES;
}

//链接program
- (BOOL)linkProgram:(GLuint)prog
{
   
    glLinkProgram(prog);
    
    //日志
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    
    if (logLength>0) {
        GLchar *log = malloc(logLength);
        
        glGetShaderInfoLog(prog, logLength, &logLength, log);
        //打印日志 char* 对应%s
        NSLog(@"shader compile log:%s\n",log);
        
        free(log);
        return NO;
    }
    return YES;
}

//验证Program
- (BOOL)validateProgram:(GLuint)prog
{
    
    GLint logLength,status;
    //验证
    glValidateProgram(prog);
    
    //获取验证的日志信息
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength>0) {
        GLchar *log = malloc(logLength);
        
        glGetShaderInfoLog(prog, logLength, &logLength, log);
        //打印日志 char* 对应%s
        NSLog(@"valid program log:%s\n",log);
        
        free(log);
        
        //获取验证状态
        glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
        if (status == 0) {
            return NO;
        }
    }
    return YES;
}

//默认重力加速度向量与地球的匹配
//{ 0，（-9.80665米/秒/秒），0 }假设+ Y坐标系的建立
//默认重力
const GLKVector3 CCDefaultGravity = {0.0f, -9.80665f, 0.0f};

@end
