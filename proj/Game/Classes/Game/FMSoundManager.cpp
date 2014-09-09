//
//  FMSoundManager.cpp
//  FarmMania
//
//  Created by  James Lee on 13-6-9.
//
//

#include "FMSoundManager.h"
#include "FMDataManager.h"

static FMSound * m_instance = NULL;
std::string currentMusic = "";

FMSound::FMSound()
{
    CCScheduler * scheduler = CCDirector::sharedDirector()->getScheduler();
    scheduler->scheduleUpdateForTarget(this, -1, false);
}

FMSound::~FMSound()
{
    
}

FMSound * FMSound::manager()
{
    if (!m_instance) {
        m_instance = new FMSound;
    }
    return m_instance;
}

void FMSound::playEffectC(cocos2d::CCString *name)
{
    playEffect(name->getCString());
}

void FMSound::playEffect(const char *name, float lifetime, float delay)
{
    FMSound::manager()->_playEffect(name, NULL, lifetime, delay);
}

void FMSound::playEffect(const char * name, const char * groupname, float lifetime, float delay)
{
    FMSound::manager()->_playEffect(name, groupname, lifetime, delay);
}

void FMSound::_playEffect(const char *name, const char * groupname, float lifetime, float delay)
{
    if (groupname == NULL) {
        groupname = name;
    }
    std::string file = std::string(name);
    std::string key = std::string(groupname);
    std::map<std::string, SoundPlayData>::iterator it = m_soundeffects.find(key);
    if (it != m_soundeffects.end()) {
        SoundPlayData & data = it->second;
        data.delay = delay;
        if (data.files.find(file) == data.files.end()) {
            data.files.insert(file);
        }
        if (data.cooldown != 0.f) {
            //playing effect now
            //check lifetime
            float waitingTime = data.cooldown + data.queue * data.delay;
            if (waitingTime >= lifetime) {
                //discard
            }
            else {
                data.queue++;
            }
        }
        else if (data.queue == 0){
            //no queue, no cooldown, play it now
            data.cooldown = data.delay;
            _enginePlayEffect(name);
        }
    }
    else {
        SoundPlayData d;
        d.cooldown = delay;
        d.delay = delay;
        d.files.insert(file);
        d.queue = 0;
        m_soundeffects[key] = d;
        _enginePlayEffect(name);
    }
}

//void FMSound::playEffect(const char *name, float delay, float lifetime)
//{
//    
//}

const char * FMSound::getRandomEffect(const char *name, ...)
{
    va_list arguments; 
    va_start(arguments, name);
    std::vector<const char *> group;
    group.push_back(name);
    const char * n = va_arg(arguments, const char *);
    while (n) {
        group.push_back(n);
        n = va_arg(arguments, const char *);
    }
    va_end(arguments);
    int ran = FMDataManager::getRandom() % group.size();
    const char * eff = group[ran];
    return eff;
}

void FMSound::stopMusic()
{
    SimpleAudioEngine::sharedEngine()->stopBackgroundMusic();
    currentMusic = "";
}

void FMSound::pauseMusic()
{
    SimpleAudioEngine::sharedEngine()->pauseBackgroundMusic();
}

void FMSound::resumeMusic()
{
    SimpleAudioEngine::sharedEngine()->resumeBackgroundMusic();
}

void FMSound::playMusicGroup(const char *name, ...)
{
    va_list arguments;
    va_start(arguments, name);
    std::vector<const char *> group;
    group.push_back(name);
    const char * n = va_arg(arguments, const char *);
    while (n) {
        group.push_back(n);
        n = va_arg(arguments, const char *);
    }
    va_end(arguments);
    int ran = FMDataManager::getRandom() % group.size();
    const char * eff = group[ran];
    playMusic(eff);
}

void FMSound::playMusic(const char *name, bool force)
{
    resumeMusic();
    if (strcmp(currentMusic.c_str(), name) == 0 && !force) {
        return;
    }
    currentMusic = name;
    FMSound::manager()->_enginePlayMusic(name);
}

void FMSound::setMusicOn(bool on)
{
    if (on) {
        SimpleAudioEngine::sharedEngine()->setBackgroundMusicVolume(1.f);
        SimpleAudioEngine::sharedEngine()->resumeBackgroundMusic();
    }
    else{
        SimpleAudioEngine::sharedEngine()->setBackgroundMusicVolume(0.f);
        SimpleAudioEngine::sharedEngine()->pauseBackgroundMusic();
    }
}

void FMSound::setEffectOn(bool on)
{
    if (on) {
        SimpleAudioEngine::sharedEngine()->setEffectsVolume(1.f);
        SimpleAudioEngine::sharedEngine()->resumeAllEffects();
    }
    else {
        SimpleAudioEngine::sharedEngine()->setEffectsVolume(0.f);
        SimpleAudioEngine::sharedEngine()->pauseAllEffects();
    }
}

void FMSound::animationWillPlaySound(const char *fileName)
{
    FMSound::playEffect(fileName);
}

void FMSound::update(float delta)
{
    for (std::map<std::string, SoundPlayData>::iterator it = m_soundeffects.begin(); it != m_soundeffects.end(); it++) {
        SoundPlayData & data = it->second;
        data.cooldown -= delta;
        if (data.cooldown <= 0.f) {
            data.cooldown = 0.f;
            if (data.queue > 0) {
                //play this effect again
                data.queue--;
                data.cooldown = data.delay;
                if (data.files.size() != 0) {
                    int r = FMDataManager::getRandom() % data.files.size();
                    std::set<std::string>::iterator nit(data.files.begin());
                    std::advance(nit, r);
                    std::string filename = *nit; 
                    _enginePlayEffect(filename.c_str());
                }
            }
            else {
                //no queue
            }
        }
    }
}

void FMSound::_enginePlayEffect(const char *name)
{ 
    SimpleAudioEngine::sharedEngine()->playEffect(name, false);
}

void FMSound::_enginePlayMusic(const char *name)
{ 
    SimpleAudioEngine::sharedEngine()->playBackgroundMusic(name, true);
}