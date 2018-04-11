//
//  CCVertexAttribArrayBuffer.m
//  01 粒子系统
//
//  Created by CC老师 on 2018/2/25.
//  Copyright © 2018年 CC老师. All rights reserved.
//封装缓冲区工具类

#import "CCVertexAttribArrayBuffer.h"

@implementation CCVertexAttribArrayBuffer


//此方法在当前的OpenGL ES上下文中创建一个顶点属性数组缓冲区
- (id)initWithAttribStride:(GLsizeiptr)aStride
          numberOfVertices:(GLsizei)count
                     bytes:(const GLvoid *)dataPtr
                     usage:(GLenum)usage
{
    self = [super init];
    
    if(self != nil)
    {
        _stride = aStride;
        _bufferSizeBytes = _stride * count;
        //初始化缓冲区 --创建VBO
        //生成一个标记
        glGenBuffers(1, &_name);
        // 绑定缓冲区
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, self.name);
        //拷贝数据到缓冲区
        glBufferData(GL_ARRAY_BUFFER, _bufferSizeBytes, dataPtr, usage);
    }
    
    return self;
}

//此方法加载由接收存储的数据
- (void)reinitWithAttribStride:(GLsizeiptr)aStride
              numberOfVertices:(GLsizei)count
                         bytes:(const GLvoid *)dataPtr
{
    
    //重新开辟空间，重新初始化
    _stride = aStride;
    _bufferSizeBytes = aStride * count;
    
    
    //不用生成标记了
    glBindBuffer(GL_ARRAY_BUFFER, self.name);
    glBufferData(GL_ARRAY_BUFFER, _bufferSizeBytes, dataPtr, GL_DYNAMIC_DRAW);
}

//当应用程序希望使用缓冲区呈现任何几何图形时，必须准备一个顶点属性数组缓冲区。当你的应用程序准备一个缓冲区时，一些OpenGL ES状态被改变，允许绑定缓冲区和配置指针。
- (void)prepareToDrawWithAttrib:(GLuint)index
            numberOfCoordinates:(GLint)count
                   attribOffset:(GLsizeiptr)offset
                   shouldEnable:(BOOL)shouldEnable
{
   //数据规范化判断
    if(count<0||count>4){
        NSLog(@"Error:");
    }
    
    glBindBuffer(GL_ARRAY_BUFFER, self.name);
    if(shouldEnable){
        glEnableVertexAttribArray(index);
    }
    
    glVertexAttribPointer(index, count, GL_FLOAT, GL_FALSE, (int)self.stride, NULL + offset);
}

//绘制
//提交由模式标识的绘图命令，并指示OpenGL ES从准备好的缓冲区中的顶点开始，从先前准备好的缓冲区中使用计数顶点。
+ (void)drawPreparedArraysWithMode:(GLenum)mode
                  startVertexIndex:(GLint)first
                  numberOfVertices:(GLsizei)count
{
   
    glDrawArrays(mode, first, count);
}

//将绘图命令模式和instructsopengl ES确定使用缓冲区从顶点索引的第一个数的顶点。顶点索引从0开始。
- (void)drawArrayWithMode:(GLenum)mode
         startVertexIndex:(GLint)first
         numberOfVertices:(GLsizei)count
{
   glDrawArrays(mode, first, count);
}


- (void)dealloc
{
    //从当前上下文删除缓冲区
    if (0 != _name)
    {
        glDeleteBuffers (1, &_name);
        _name = 0;
    }
}


@end
