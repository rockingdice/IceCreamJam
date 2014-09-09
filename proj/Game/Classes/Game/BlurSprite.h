//
//  BlurSprite.h
//  JellyMania
//
//  Created by  James Lee on 13-12-13.
//
//

#ifndef __JellyMania__BlurSprite__
#define __JellyMania__BlurSprite__

#include <iostream>
#include "cocos2d.h"
using namespace cocos2d;

class SpriteBlur : public CCSprite
{
public:
    ~SpriteBlur();
    void setBlurSize(float f);
    bool initWithTexture(CCTexture2D* texture, const CCRect&  rect);
    void draw();
    void initProgram();
    void listenBackToForeground(CCObject *obj);
    
    static SpriteBlur* create(const char *pszFileName);
    static SpriteBlur* createWithSpriteFrame(CCSpriteFrame * frame);
    CCPoint blur_;
    GLfloat    sub_[4];
    
    GLuint    blurLocation;
    GLuint    subLocation;
}; 

#endif /* defined(__JellyMania__BlurSprite__) */
