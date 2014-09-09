//
//  FMSoundManager.h
//  FarmMania
//
//  Created by  James Lee on 13-6-9.
//
//

#ifndef __FarmMania__FMSoundManager__
#define __FarmMania__FMSoundManager__

#include <iostream>
#include "cocos2d.h"
#include "SimpleAudioEngine.h"
#include "NEAnimNode.h"
using namespace cocos2d;
using namespace CocosDenshion;
using namespace neanim;
#define SoundGlobalCooldown 0.1f
struct SoundPlayData {
    float cooldown; //cooldown will reset to delay
    float delay;
    int queue;
    std::set<std::string> files;
};
class FMSound : public NEAnimSoundDelegate, public CCObject
{
private:
    FMSound();
    ~FMSound();
    std::map<std::string, SoundPlayData> m_soundeffects;
public:
    static FMSound * manager();
public:
    static void stopMusic();
    static void pauseMusic();
    static void resumeMusic();
    static void playMusic(const char * name, bool force = false);
    static void playMusicGroup(const char * name, ...);
    void playEffectC(CCString * name);
    static void playEffect(const char * name, float lifetime = 0.3f, float delay = 0.1f);
    static void playEffect(const char * name, const char * groupname, float lifetime = 0.3f, float delay = 0.1f);
//    static void playEffect(const char * name);
    static const char * getRandomEffect(const char * name, ...);
    static void setMusicOn(bool on);
    static void setEffectOn(bool on);
    
protected:
    virtual void animationWillPlaySound(const char * fileName);
    virtual void update(float delta);
private:
    void _playEffect(const char * name, const char * groupname, float lifetime, float delay);
    void _enginePlayEffect(const char * name);
    void _enginePlayMusic(const char * name);
};
#endif /* defined(__FarmMania__FMSoundManager__) */
