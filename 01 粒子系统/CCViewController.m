//
//  CCViewController.m
//  01 粒子系统
//
//  Created by CC老师 on 2018/2/25.
//  Copyright © 2018年 CC老师. All rights reserved.
//

#import "CCViewController.h"
#import "CCVertexAttribArrayBuffer.h"
#import "CCPointParticleEffect.h"


@interface CCViewController ()

//上下文
@property (nonatomic , strong) EAGLContext* mContext;

//管理并且绘制所有的粒子对象
@property (strong, nonatomic) CCPointParticleEffect *particleEffect;

@property (assign, nonatomic) NSTimeInterval autoSpawnDelta;
@property (assign, nonatomic) NSTimeInterval lastSpawnTime;

@property (assign, nonatomic) NSInteger currentEmitterIndex;
@property (strong, nonatomic) NSArray *emitterBlocks;

//粒子纹理对象
@property (strong, nonatomic) GLKTextureInfo *ballParticleTexture;

@end

@implementation CCViewController

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    //新建OpenGLES上下文
    self.mContext = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    //GLKView
    GLKView *view = (GLKView *)self.view;
    view.context = self.mContext;
    view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    //纹理路径
    NSString *path = [[NSBundle bundleForClass:[self class]]pathForResource:@"ball" ofType:@"png"];
    if(path == nil){
        return;
    }
    //加载纹理
    self.ballParticleTexture = [GLKTextureLoader textureWithContentsOfFile:path options:nil error:nil];
    
    //获取粒子对象
    self.particleEffect = [[CCPointParticleEffect alloc]init];
    self.particleEffect.texture2d0.name = self.ballParticleTexture.name;
    self.particleEffect.texture2d0.target = self.ballParticleTexture.target;
    
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
    
    //4种block，每一种效果对应一种block
    void(^blockA)() = ^{
        //设置时间
        self.autoSpawnDelta = 0.5f;
        //重力
        self.particleEffect.gravity = CCDefaultGravity;
        
        //速度 X轴产生随机速度
        float randomXVelocity = -0.5f + 1.0f * (float)random()/(float)RAND_MAX;
        
        //添加粒子
        [self.particleEffect addParticleAtPosition:GLKVector3Make(0.0f, 0.0f, 0.9f) velocity:GLKVector3Make(randomXVelocity, 1.0f, -1.0f) force:GLKVector3Make(0.0f, 9.0f, 0.0f) size:8.0f lifeSpanSeconds:3.2f fadeDurationSeconds:0.5f];
    };
    
    void(^blockB)() = ^{
        //设置时间
        self.autoSpawnDelta = 0.05f;
        //重力 随机
        self.particleEffect.gravity = GLKVector3Make(0.0f, 0.5f, 0.0f);
        
        //一次创建多少粒子
        int n = 50;
        for (int i=0; i<n; i++) {
            //X轴速度
            float randomXVelocity = -0.1f + 0.2f *(float)random()/(float)RAND_MAX;
            //Z轴速度
            float randowmZVelocity = 0.1f + 0.2f *(float)random()/(float)RAND_MAX;
            //添加粒子
            [self.particleEffect addParticleAtPosition:GLKVector3Make(0.0f, -0.5f, 0.0f) velocity:GLKVector3Make(randomXVelocity, 0.0f, randowmZVelocity) force:GLKVector3Make(0.0f, 0.0f, 0.0f) size:16.0f lifeSpanSeconds:2.2f fadeDurationSeconds:3.0f];
        }
    };
    
    void(^blockC)() = ^{
        //设置时间
        self.autoSpawnDelta = 0.5f;
        //重力
        self.particleEffect.gravity = GLKVector3Make(0.0f, 0.0f, 0.0f);
        
        //一次创建多少粒子
        int n = 100;
        for (int i=0; i<n; i++) {
            //X轴速度
            float randomXVelocity = -0.5f + 1.0f *(float)random()/(float)RAND_MAX;
            //Y轴速度
            float randomYVelocity = -0.5f + 1.0f *(float)random()/(float)RAND_MAX;
            //Z轴速度
            float randowmZVelocity = -0.5f + 1.0f *(float)random()/(float)RAND_MAX;
            //添加粒子
            [self.particleEffect addParticleAtPosition:GLKVector3Make(0.0f, 0.0f, 0.0f) velocity:GLKVector3Make(randomXVelocity, randomYVelocity, randowmZVelocity) force:GLKVector3Make(0.0f, 0.0f, 0.0f) size:4.0f lifeSpanSeconds:3.2f fadeDurationSeconds:0.5f];
        }
    };
    
    void(^blockD)() = ^{
        //设置时间
        self.autoSpawnDelta = 3.2f;
        //重力
        self.particleEffect.gravity = GLKVector3Make(0.0f, 0.0f, 0.0f);
        
        //一次创建多少粒子
        int n = 100;
        for (int i=0; i<n; i++) {
            //X轴速度
            float randomXVelocity = -0.5f + 1.0f *(float)random()/(float)RAND_MAX;
            //Y轴速度
            float randomYVelocity = -0.5f + 1.0f *(float)random()/(float)RAND_MAX;
            
            //计算速度与方向  GLKVector3Normalize计算法向量
            GLKVector3 velocity = GLKVector3Normalize(GLKVector3Make(randomXVelocity, randomYVelocity, 0.0f));
            
            //添加粒子
            [self.particleEffect addParticleAtPosition:GLKVector3Make(0.0f, 0.0f, 0.0f) velocity:velocity force:GLKVector3MultiplyScalar(velocity, -1.5f) size:4.0f lifeSpanSeconds:3.2f fadeDurationSeconds:0.1f];
        }
    };
    
    //将4种不同效果的block块存储到数组中
    self.emitterBlocks = @[[blockA copy],[blockB copy],[blockC copy],[blockD copy]];
    
   //纵横比
    float aspect = (float)CGRectGetWidth(self.view.bounds)/CGRectGetHeight(self.view.bounds);
    //设置投影方式
    [self preparePointOfViewWithAspectRatio:aspect];
}

//MVP矩阵
- (void)preparePointOfViewWithAspectRatio:(GLfloat)aspectRatio
{
   //设置投影方式
    self.particleEffect.transform.projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(85.0f), aspectRatio, 0.1f, 20.0f);
    
    //设置模型矩阵
    self.particleEffect.transform.modelviewMatrix = GLKMatrix4MakeLookAt(0.0f, 0.0f, 1.0f, 0.0f, 0.0f, 0.0f, 0.0f, 1.0f, 0.0f);
}

//更新
- (void)update
{
    //判断
    //时间间隔 上次恢复时间
    NSTimeInterval timeElapsed = self.timeSinceLastResume;
    
    //消耗时间
    self.particleEffect.elapsedSeconds = timeElapsed;
    //动画时间 《 当前时间与上次更新时间
    if (self.autoSpawnDelta < (timeElapsed - self.lastSpawnTime)) {
        //更新上一次更新时间
        self.lastSpawnTime = timeElapsed;
        
        void(^emitterBlock)() = [self.emitterBlocks objectAtIndex:self.currentEmitterIndex];
        
        //执行block
        emitterBlock();
    }
    
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
   //
    glClearColor(0.3f, 0.3f, 0.3f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
    
    //准备绘制
    [self.particleEffect prepareToDraw];
    
    [self.particleEffect draw];
    
}

- (IBAction)ChangeIndex:(UISegmentedControl *)sender {
    
    self.currentEmitterIndex = [sender selectedSegmentIndex];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation !=
            UIInterfaceOrientationPortraitUpsideDown);
}


@end
