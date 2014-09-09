#include "NEAnimNode.h"
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
#include "FMDataManager.h"
#endif
namespace neanim {

static float m_scaleFactor;
    
static NEPropertyType propertyPriority[] = {
    kProperty_Texture,
    kProperty_FNTFile,
    
    kProperty_Position,
    kProperty_Scale,
    kProperty_Skew,
    kProperty_Rotation,
    kProperty_Color,
    
    kProperty_Alpha,
    kProperty_AnchorPoint,  //Instant
    kProperty_Visible,
    kProperty_Sound,
    
    kProperty_Callback,
    kProperty_StringValue,
    kProperty_Particle,
    kProperty_Animation,
    kProperty_FontName,
    
    kProperty_FontSize,
    kProperty_AnimName,     //Permanant
    kProperty_NodeName,
    kProperty_AnimFPS,
    kProperty_AnimLength,
    
    kProperty_ParticleControl,
    kProperty_AnimationControl,
    kProperty_ZDepth,
    kProperty_Hide,
    kProperty_Lock,
    
    kProperty_BlendSrc,
    kProperty_BlendDst,
    kProperty_Loop,
    kProperty_ContentSize,
    
    kProperty_Insets,
    kProperty_AnimSkin,
};

static void stringsplit(std::string& s, std::string& delim,std::vector< std::string >* ret)
{
    size_t last = 0;
    size_t index=s.find_first_of(delim,last);
    while (index!=std::string::npos)
    {
        ret->push_back(s.substr(last,index-last));
        last=index+1;
        index=s.find_first_of(delim,last);
    }
    if (index-last>0)
    {
        ret->push_back(s.substr(last,index-last));
    }
}

static std::string stringFileName(std::string& path )
{
    std::string file = path;
    size_t pos = path.find_last_of("/");
    if (pos != std::string::npos)
    {
        file = path.substr(pos+1);
    }
    return file;
}
    
    
bool isFileExist(const char *filePath)
{
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
    return FMDataManager::sharedManager()->isFileExist(filePath);
#else
    std::string fullPath = CCFileUtils::sharedFileUtils()->fullPathForFilename(filePath);
    FILE *fp = fopen(fullPath.c_str(), "r");
    if (! fp)
    {
        return false;
    }
    else {
        fclose(fp);
        return true;
    }
#endif
}

// NEAnimManager
static NEAnimManager * m_sharedManager;
NEAnimManager::NEAnimManager() :
        m_soundDelegate(NULL),
        m_stringDelegate(NULL)
{
    m_scaleFactor = 1.f;

    m_textureFileRefCount = CCDictionary::create();
    m_textureFileRefCount->retain();
    m_sharedDataRefCount = CCDictionary::create();
    m_sharedDataRefCount->retain();
    m_textureMap = CCDictionary::create();
    m_textureMap->retain();
    m_autoRemoveSharedAnimData = false;
    m_autoRemoveTexture = false;
}

NEAnimManager::~NEAnimManager()
{
    m_textureFileRefCount->release();
    m_textureFileRefCount = NULL;
    m_sharedDataRefCount->release();
    m_sharedDataRefCount = NULL;
    m_textureMap->release();
    m_textureMap = NULL;
}

NEAnimManager * NEAnimManager::sharedManager()
{
    if (!m_sharedManager) {
        m_sharedManager = new NEAnimManager();
    }
    return m_sharedManager;
}

void NEAnimManager::destroyManager()
{
    delete m_sharedManager;
    m_sharedManager = NULL;
}

//#pragma mark - User Functions
void NEAnimManager::setScaleFactor(float scaleFactor)
{
    m_scaleFactor = scaleFactor;
}

float NEAnimManager::getScaleFactor()
{
    return m_scaleFactor;
}

void NEAnimManager::preloadTextureForAnimFile(const char *fileName, const char *animationName)
{
    NEAnimFileData * sharedData = getSharedDataForFile(fileName);
    NEAnimData * animData = sharedData->getAnimData(animationName);
    if (animData) {
        for (int i=0; i<animData->m_usedTextureFiles->count(); i++) {
            CCString * texFile = (CCString *)animData->m_usedTextureFiles->objectAtIndex(i);
            if (strcmp(texFile->getCString() , "") == 0) {
                continue;
            }
            loadSpriteframesFromFile(texFile);
        }
    }
}

//#pragma mark - Memory Management

void NEAnimManager::setAutoRemoveTexture(bool isAuto)
{
    m_autoRemoveTexture = isAuto;
}

void NEAnimManager::setAutoRemoveSharedAnimData(bool isAuto)
{
    m_autoRemoveSharedAnimData = isAuto;
}

void NEAnimManager::cleanMemory()
{
    removeUnusedData();
    removeUnusedTextures();
}


void NEAnimManager::removeUnusedTextures()
{
    CCDictElement * pElement = NULL;
    std::vector<const char *> removed;
    CCDICT_FOREACH(m_textureFileRefCount, pElement) {
        const char * key = pElement->getStrKey();
        CCInteger * ref = (CCInteger *)m_textureFileRefCount->objectForKey(key);
        int refCount = ref->getValue();
        if (refCount <= 0) {
            CCSpriteFrameCache::sharedSpriteFrameCache()->removeSpriteFrameByName(key);
            CCTextureCache::sharedTextureCache()->removeTextureForKey(key);
        } 
        removed.push_back(key);
    }
    for (std::vector<const char *>::iterator it = removed.begin(); it!=removed.end(); it++) {
        const char * key = *it;
        m_textureFileRefCount->removeObjectForKey(key);
    }
}


void NEAnimManager::removeUnusedData()
{
    CCArray * keys = CCArray::createWithArray(m_sharedDataRefCount->allKeys());
    for (int i=0; i<keys->count(); i++) {
        CCString * key = (CCString *)keys->objectAtIndex(i);
        NEAnimFileData * data = (NEAnimFileData *)m_sharedDataRefCount->objectForKey(key->getCString());
        int refCount = data->getRefCount();
        if (refCount <= 0) {
            m_sharedDataRefCount->removeObjectForKey(key->m_sString);
        }
    }
}

//#pragma mark - Main logic
NEAnimFileData * NEAnimManager::getSharedDataForFile(const char *fileName)
{
    std::string fileNameString(fileName);
    std::string fn = stringFileName(fileNameString);
    NEAnimFileData * sharedData = (NEAnimFileData *)m_sharedDataRefCount->objectForKey(fn);
    if (!sharedData) {
        sharedData = NEAnimFileData::createFromFile(fileName);
        m_sharedDataRefCount->setObject(sharedData, fn);
    }
    return sharedData;
}

void NEAnimManager::reloadDataWithFile(const char *fileName)
{
    NEAnimFileData * data = getSharedDataForFile(fileName);
    if (data) {
        std::string fileNameString(fileName);
        std::string fn = stringFileName(fileNameString);
        
        data->retain();
        
        NEAnimFileData * sharedData = NEAnimFileData::createFromFile(fileName);
        
        data->changeToAnimData(sharedData);
        data->release();
        
        m_sharedDataRefCount->setObject(sharedData, fn);
    }
}

bool NEAnimManager::loadSpriteframesFromFile(CCString *filePath)
{
    bool succeed = false;
    CCString * texFile = getTextureFileFromPlistFile(filePath);
    if (isPlistFile(filePath)) {
        CCTexture2D * pTexture = CCTextureCache::sharedTextureCache()->addImage(texFile->getCString());

        if (pTexture) {
            m_textureFileRefCount->setObject(CCInteger::create(0), texFile->m_sString);
            CCDictionary * frames = getFramesFromPlistFile(filePath, pTexture);
            //add frames

            CCArray * keys = frames->allKeys();
            for (unsigned int i=0; i<keys->count(); i++) {
                CCString * key = (CCString *)keys->objectAtIndex(i);
                CCSpriteFrame * frame = (CCSpriteFrame *)frames->objectForKey(key->m_sString);
                CCSpriteFrameCache::sharedSpriteFrameCache()->addSpriteFrame(frame, key->getCString());
            }
            succeed = true;
        }
    }
    else {
        //new texture, create ref to it and load the texture
        CCTexture2D * pTexture = CCTextureCache::sharedTextureCache()->addImage(texFile->getCString());
        if (pTexture) {
            m_textureFileRefCount->setObject(CCInteger::create(0), texFile->m_sString);
            CCSize s = pTexture->getContentSizeInPixels();
            CCSpriteFrame * frame = CCSpriteFrame::createWithTexture(pTexture, CCRect(0, 0, s.width, s.height));
            std::string file = texFile->m_sString;
            CCString * key = CCString::create(stringFileName(file));
            CCSpriteFrameCache::sharedSpriteFrameCache()->addSpriteFrame(frame, key->getCString());
            succeed = true;
        }
    }
    
    return succeed;

}


void NEAnimManager::useSpriteframesFromFile(CCString *filePath)
{
    //see if plist file
    CCString * texFile = getTextureFileFromPlistFile(filePath);
    CCInteger * texRef = (CCInteger *)m_textureFileRefCount->objectForKey(texFile->m_sString);
    if (isPlistFile(filePath)) {
        //extract
        if (texRef) {
            //already exist, add ref to it
            int ref = texRef->getValue();
            ref++;
            m_textureFileRefCount->setObject(CCInteger::create(ref), texFile->m_sString);
        }
        else {
            //new texture, load the texture
            bool succeed = loadSpriteframesFromFile(filePath);
            if (succeed)
                useSpriteframesFromFile(filePath);
        }
    }
    else {
        //other file format
        //try to load as an image file
        if (texRef) {
            //already exist, add ref to it
            int ref = texRef->getValue();
            ref++;
            m_textureFileRefCount->setObject(CCInteger::create(ref), texFile->m_sString);
        }
        else {
            bool succeed = loadSpriteframesFromFile(filePath);
            if (succeed)
                useSpriteframesFromFile(filePath);
        }
    }
}


void NEAnimManager::unusedSpriteframesFromFile(CCString *filePath)
{
    //see if plist file
    if (isPlistFile(filePath)) {
        //extract
        CCString * texFile = getTextureFileFromPlistFile(filePath);
        CCInteger * texRef = (CCInteger *)m_textureFileRefCount->objectForKey(texFile->m_sString);
        if (texRef) {
            //already exist, add ref to it
            int ref = texRef->getValue();
            ref--;
            if (ref <= 0 && m_autoRemoveTexture) {
                CCArray * frameNames = getFrameNamesFromPlistFile(filePath);
                //remove frames
                for (unsigned int i=0; i<frameNames->count(); i++) {
                    CCString * key = (CCString *)frameNames->objectAtIndex(i);
                    CCSpriteFrameCache::sharedSpriteFrameCache()->removeSpriteFrameByName(key->getCString());
                }
                CCTextureCache::sharedTextureCache()->removeTextureForKey(texFile->getCString());
                m_textureFileRefCount->removeObjectForKey(texFile->getCString());
            }
            else {
                m_textureFileRefCount->setObject(CCInteger::create(ref),texFile->m_sString);
            }
        }
        else {
            CCLOG("Cannot remove the file:%s", filePath);
        }
    }
    else {
        //other file format
        CCString * texFile = getTextureFileFromPlistFile(filePath);
        CCInteger * texRef = (CCInteger *)m_textureFileRefCount->objectForKey(texFile->getCString());
        if (texRef) {
            //already exist
            int ref = texRef->getValue();
            ref--;
            if (ref <= 0 && m_autoRemoveTexture) {
                std::string file = texFile->m_sString;
                CCString * key = CCString::create(stringFileName(file));
                CCSpriteFrameCache::sharedSpriteFrameCache()->removeSpriteFrameByName(key->getCString());
                CCTextureCache::sharedTextureCache()->removeTextureForKey(texFile->getCString());
                m_textureFileRefCount->removeObjectForKey(texFile->m_sString);
            }
            else {
                m_textureFileRefCount->setObject(CCInteger::create(ref), texFile->m_sString);
            }
        }
        else {
            CCLOG("Cannot remove the file:%s", filePath);
        }
    }

}



//#pragma mark - Helper
bool NEAnimManager::isPlistFile(CCString *filePath)
{
    std::string s = filePath->m_sString;
    if(s.substr(s.find_last_of(".") + 1) == "plist") {
        return true;
    } else {
        return false;
    }
}


CCString * NEAnimManager::getTextureFileFromPlistFile(CCString *pszPlist)
{
    CCAssert(pszPlist, "plist filename should not be NULL");

    CCString * textureFile = (CCString *)m_textureMap->objectForKey(pszPlist->getCString());
    if (textureFile) {
        return textureFile;
    }
    std::string path = CCFileUtils::sharedFileUtils()->fullPathForFilename(pszPlist->getCString());
    CCDictionary *dict = CCDictionary::createWithContentsOfFileThreadSafe(path.c_str());


    std::string texturePath("");
    CCDictionary *metadataDict = (CCDictionary *)dict->objectForKey("metadata");
    if( metadataDict )
        // try to read  texture file name from meta data
        texturePath = metadataDict->valueForKey("textureFileName")->getCString();

    if (! texturePath.empty())
    {
        // build texture path relative to plist file
        texturePath = CCFileUtils::sharedFileUtils()->fullPathFromRelativeFile(texturePath.c_str(), pszPlist->getCString());
    }
    else
    {
        // build texture path by replacing file extension
        texturePath = pszPlist->getCString();

        // remove .xxx
        size_t startPos = texturePath.find_last_of(".");
        texturePath = texturePath.erase(startPos);

        // append .png
        texturePath = texturePath.append(".png");

        CCLOG("cocos2d: CCSpriteFrameCache: Trying to use file %s as texture", texturePath.c_str());
    }
    CCString * tp = CCString::create(texturePath);
    m_textureMap->setObject(tp, pszPlist->m_sString);
    return tp;
}

CCArray * NEAnimManager::getFrameNamesFromPlistFile(CCString *pszPlist)
{
    //std::map<std::string, CCSpriteFrame *> retVal;
    CCArray * retVal = CCArray::create();
    std::string pszPath = CCFileUtils::sharedFileUtils()->fullPathForFilename(pszPlist->getCString());
    CCDictionary *dictionary = CCDictionary::createWithContentsOfFile(pszPath.c_str());

    /*
     Supported Zwoptex Formats:

     ZWTCoordinatesFormatOptionXMLLegacy = 0, // Flash Version
     ZWTCoordinatesFormatOptionXML1_0 = 1, // Desktop Version 0.0 - 0.4b
     ZWTCoordinatesFormatOptionXML1_1 = 2, // Desktop Version 1.0.0 - 1.0.1
     ZWTCoordinatesFormatOptionXML1_2 = 3, // Desktop Version 1.0.2+
     */

    CCDictionary *metadataDict = (CCDictionary*)dictionary->objectForKey("metadata");
    CCDictionary *framesDict = (CCDictionary*)dictionary->objectForKey("frames");
    int format = 0;

    // get the format
    if(metadataDict != NULL)
    {
        format = metadataDict->valueForKey("format")->intValue();
    }

    // check the format
    CCAssert(format >=0 && format <= 3, "format is not supported for CCSpriteFrameCache addSpriteFramesWithDictionary:textureFilename:");

    std::string plistFile = std::string(pszPlist->getCString());
    std::string plistFileName = stringFileName(plistFile);

    for (int i=0; i<framesDict->count(); i++) {
        CCString * key = (CCString *)framesDict->allKeys()->objectAtIndex(i);
        CCString * frameKey = CCString::createWithFormat("%s|%s", plistFileName.c_str(), key->getCString());
        retVal->addObject(frameKey);
    }
    return retVal;
}


CCDictionary * NEAnimManager::getFramesFromPlistFile(CCString *pszPlist, CCTexture2D *pobTexture)
{
    CCDictionary * retVal = CCDictionary::create();
    std::string pszPath = CCFileUtils::sharedFileUtils()->fullPathForFilename(pszPlist->getCString());
    CCDictionary * dictionary = CCDictionary::createWithContentsOfFile(pszPath.c_str());

    /*
     Supported Zwoptex Formats:
     ZWTCoordinatesFormatOptionXMLLegacy = 0, // Flash Version
     ZWTCoordinatesFormatOptionXML1_0 = 1, // Desktop Version 0.0 - 0.4b
     ZWTCoordinatesFormatOptionXML1_1 = 2, // Desktop Version 1.0.0 - 1.0.1
     ZWTCoordinatesFormatOptionXML1_2 = 3, // Desktop Version 1.0.2+
     */
    CCDictionary *metadataDict = (CCDictionary *)dictionary->objectForKey("metadata");
    CCDictionary *framesDict = (CCDictionary *)dictionary->objectForKey("frames");

    int format = 0;

    // get the format
    if(metadataDict != NULL)
        format = metadataDict->valueForKey("format")->intValue();

        // check the format
        CCAssert( format >= 0 && format <= 3, "format is not supported for CCSpriteFrameCache addSpriteFramesWithDictionary:textureFilename:");

        // SpriteFrame info
        CCRect rectInPixels;
    bool isRotated;
    CCPoint frameOffset;
    CCSize originalSize;

    // add real frames
    for (int i=0; i<framesDict->count(); i++) {
        CCString *frameDictKey = (CCString *)framesDict->allKeys()->objectAtIndex(i);
        CCDictionary *frameDict = (CCDictionary *)framesDict->objectForKey(frameDictKey->m_sString);
        CCSpriteFrame *spriteFrame = NULL;
        if(format == 0) {
            float x = frameDict->valueForKey("x")->floatValue();
            float y = frameDict->valueForKey("y")->floatValue();
            float w = frameDict->valueForKey("width")->floatValue();
            float h = frameDict->valueForKey("height")->floatValue();
            float ox = frameDict->valueForKey("offsetX")->floatValue();
            float oy = frameDict->valueForKey("offsetY")->floatValue();
            int ow = frameDict->valueForKey("originalWidth")->intValue();
            int oh = frameDict->valueForKey("originalHeight")->intValue();
            // check ow/oh
            if(!ow || !oh)
                CCLOGWARN("cocos2d: WARNING: originalWidth/Height not found on the CCSpriteFrame. AnchorPoint won't work as expected. Regenrate the .plist");
                // abs ow/oh
                ow = abs(ow);
                oh = abs(oh);

                // set frame info
                rectInPixels = CCRectMake(x, y, w, h);
                isRotated = false;
                frameOffset = CCPointMake(ox, oy);
                originalSize = CCSizeMake(ow, oh);
                }
        else if(format == 1 || format == 2) {
            CCRect frame = CCRectFromString(frameDict->valueForKey("frame")->getCString());
            bool rotated = false;
            // rotation
            if (format == 2)
            {
                rotated = frameDict->valueForKey("rotated")->boolValue();
            }
            CCPoint offset = CCPointFromString(frameDict->valueForKey("offset")->getCString());
            CCSize sourceSize = CCSizeFromString(frameDict->valueForKey("sourceSize")->getCString());

                        // set frame info
                        rectInPixels = frame;
                        isRotated = rotated;
                        frameOffset = offset;
                        originalSize = sourceSize;
            }
        else if(format == 3) {

            // get values
            CCSize spriteSize = CCSizeFromString(frameDict->valueForKey("spriteSize")->getCString());
            CCPoint spriteOffset = CCPointFromString(frameDict->valueForKey("spriteOffset")->getCString());
            CCSize spriteSourceSize = CCSizeFromString(frameDict->valueForKey("spriteSourceSize")->getCString());
            CCRect textureRect = CCRectFromString(frameDict->valueForKey("textureRect")->getCString());
            bool textureRotated = frameDict->valueForKey("textureRotated")->boolValue();

                            // set frame info
                            rectInPixels = CCRectMake(textureRect.origin.x, textureRect.origin.y, spriteSize.width, spriteSize.height);
                            isRotated = textureRotated;
                            frameOffset = spriteOffset;
                            originalSize = spriteSourceSize;
                        }

        spriteFrame = CCSpriteFrame::createWithTexture(pobTexture, rectInPixels, isRotated, frameOffset, originalSize);

        // add sprite frame
        std::string plistFile = std::string(pszPlist->getCString());
        std::string plistFileName = stringFileName(plistFile);
        CCString * key = CCString::createWithFormat("%s|%s", plistFileName.c_str(), frameDictKey->getCString());
        retVal->setObject(spriteFrame, key->getCString());
    }
    return retVal;
}
    
void NEAnimManager::setSoundDelegate(neanim::NEAnimSoundDelegate *delegate)
{
    m_soundDelegate = delegate;
}
    
void NEAnimManager::playSound(const char *sound)
{
    if (m_soundDelegate) {
        m_soundDelegate->animationWillPlaySound(sound);
    }
}
    
void NEAnimManager::setStringDelegate(neanim::NEAnimStringDelegate *delegate)
{
    m_stringDelegate = delegate;
}
    
const char * NEAnimManager::getLocalizedString(const char *string)
{
    if (m_stringDelegate) {
        return m_stringDelegate->animationGetLocalizedString(string);
    }
    else
        return string;
}
// NEAnimData

NEAnimData::NEAnimData() :
    m_length(0),
    m_fps(10),
    m_spf(0.1f),
    m_loop(false),
    m_animName("")
{
    m_keyframesData = CCDictionary::create();
    m_keyframesData->retain();
    m_usedTextureFiles = CCArray::create();
    m_usedTextureFiles->retain();
}

NEAnimData::~NEAnimData()
{
    CCArray * av1 = m_keyframesData->allKeys();
    for (int i=0; i<av1->count(); i++) {
        int key = ((CCInteger *)av1->objectAtIndex(i))->getValue();
        CCDictionary * v1 = (CCDictionary *)m_keyframesData->objectForKey(key);
        CCArray * av2 = v1->allKeys();
        for (int j=0; j<av2->count(); j++) {
            int ikey =((CCInteger *)av2->objectAtIndex(j))->getValue();
            CCValue<NEFrame *> * v = (CCValue<NEFrame *> *)v1->objectForKey(ikey);
            NEFrame * f = v->getValue();
            delete f;
        }
    }
    m_keyframesData->release();
    m_usedTextureFiles->release();
}
    
struct NEFrameDefault
{
    int type;
    NEEaseType easeType;
    NEEaseClass easeClass;
    int dimension;
    float data[4];
};
    
static NEFrameDefault defaultData[] = {
    {kProperty_Position, kEase_Linear, kEase_NA, 2, {0.f, 0.f, 0.f, 0.f}},
    {kProperty_Scale, kEase_Linear, kEase_NA, 2, {1.f, 1.f, 0.f, 0.f}},
    {kProperty_Skew, kEase_Linear, kEase_NA, 2, {0.f, 0.f, 0.f, 0.f}},
    {kProperty_Rotation, kEase_Linear, kEase_NA, 2, {0.f, 0.f, 0.f, 0.f}},
    {kProperty_Color, kEase_Linear, kEase_NA, 3, {255.f, 255.f, 255.f, 0.f}},
    {kProperty_Alpha, kEase_Linear, kEase_NA, 1, {255.f, 0.f, 0.f, 0.f}},
    {kProperty_AnchorPoint, kEase_Linear, kEase_NA, 2, {0.5f, 0.5f, 0.f, 0.f}},
    {kProperty_Visible, kEase_NoChange, kEase_NA, 1, {0.f, 0.f, 0.f, 0.f}},
    {kProperty_Texture, kEase_NoChange, kEase_NA, 1, {-1.f, 0.f, 0.f, 0.f}},
    {kProperty_Sound, kEase_Pulse, kEase_NA, 1, {-1.f, 0.f, 0.f, 0.f}},
    {kProperty_Callback, kEase_Pulse, kEase_NA, 1, {-1.f, 0.f, 0.f, 0.f}},
    {kProperty_StringValue, kEase_NoChange, kEase_NA, 1, {-1.f, 0.f, 0.f, 0.f}},
    {kProperty_Particle, kEase_NoChange, kEase_NA, 1, {-1.f, 0.f, 0.f, 0.f}},
    {kProperty_Animation, kEase_NoChange, kEase_NA, 1, {-1.f, 0.f, 0.f, 0.f}},
    {kProperty_FontName, kEase_NoChange, kEase_NA, 1, {-1.f, 0.f, 0.f, 0.f}},
    {kProperty_FontSize, kEase_NoChange, kEase_NA, 1, {12.f, 0.f, 0.f, 0.f}},
    {kProperty_AnimName, kEase_NoChange, kEase_NA, 1, {-1.f, 0.f, 0.f, 0.f}},
    {kProperty_NodeName, kEase_NoChange, kEase_NA, 1, {-1.f, 0.f, 0.f, 0.f}},
    {kProperty_AnimFPS, kEase_NoChange, kEase_NA, 1, {30.f, 0.f, 0.f, 0.f}},
    {kProperty_AnimLength, kEase_NoChange, kEase_NA, 1, {60.f, 0.f, 0.f, 0.f}},
    {kProperty_ParticleControl, kEase_Pulse, kEase_NA, 1, {-1.f, 0.f, 0.f, 0.f}},
    {kProperty_AnimationControl, kEase_Pulse, kEase_NA, 4, {0.f, -1.f, -1.f, 0.f}},
    {kProperty_ZDepth, kEase_NoChange, kEase_NA, 1, {1.f, 0.f, 0.f, 0.f}},
    {kProperty_Lock, kEase_NoChange, kEase_NA, 1, {0.f, 0.f, 0.f, 0.f}},
    {kProperty_Hide, kEase_NoChange, kEase_NA, 1, {0.f, 0.f, 0.f, 0.f}},
    {kProperty_BlendSrc, kEase_NoChange, kEase_NA, 1, {1.f, 0.f, 0.f, 0.f}},
    {kProperty_BlendDst, kEase_NoChange, kEase_NA, 1, {771.f, 0.f, 0.f, 0.f}},
    {kProperty_Loop, kEase_NoChange, kEase_NA, 1, {0.f, 0.f, 0.f, 0.f}},
    {kProperty_FNTFile, kEase_NoChange, kEase_NA, 1, {-1.f, 0.f, 0.f, 0.f}},
    {kProperty_ContentSize, kEase_NoChange, kEase_NA, 2, {0.f, 0.f, 0.f, 0.f}},
    {kProperty_Insets, kEase_NoChange, kEase_NA, 4, {0.f, 0.f, 0.f, 0.f}},
    {kProperty_AnimSkin, kEase_NoChange, kEase_NA, 1, {-1.f, 0.f, 0.f, 0.f}},
};
    
CCValue<NEFrame *> * defaultFrames[30] = {NULL};
 
    
static std::map<int, std::vector<NEPropertyType> > propertiesOfType;

std::vector<NEPropertyType> & getPropertyOfType(int nodeType)
{
    if (propertiesOfType.find(nodeType) == propertiesOfType.end()) {
        std::vector<NEPropertyType> types;
        switch (nodeType) {
            case 0:
            {
                types.push_back(kProperty_Sound);
                types.push_back(kProperty_Callback);
                types.push_back(kProperty_AnimName);
                types.push_back(kProperty_AnimLength);
                types.push_back(kProperty_NodeName);
                types.push_back(kProperty_AnimFPS);
                types.push_back(kProperty_Loop);
                propertiesOfType[nodeType] = types;
            }
                break;
            case 1:
            {
                types.push_back(kProperty_Position);
                types.push_back(kProperty_Scale);
                types.push_back(kProperty_Rotation);
                types.push_back(kProperty_AnchorPoint);
                types.push_back(kProperty_Visible);
                types.push_back(kProperty_Color);
                types.push_back(kProperty_Alpha);
                types.push_back(kProperty_Texture);
                types.push_back(kProperty_ZDepth);
                types.push_back(kProperty_BlendSrc);
                types.push_back(kProperty_BlendDst);
                propertiesOfType[nodeType] = types;
            }
                break;
            case 3:
            {
                types.push_back(kProperty_Position);
                types.push_back(kProperty_Scale);
                types.push_back(kProperty_Rotation);
                types.push_back(kProperty_AnchorPoint);
                types.push_back(kProperty_Visible);
                types.push_back(kProperty_Color);
                types.push_back(kProperty_Alpha);
                types.push_back(kProperty_Texture);
                types.push_back(kProperty_ZDepth);
                types.push_back(kProperty_BlendSrc);
                types.push_back(kProperty_BlendDst);
                propertiesOfType[nodeType] = types;
            }
                break;
            case kNode_Sprite9:
            {
                types.push_back(kProperty_Position);
                types.push_back(kProperty_Scale);
                types.push_back(kProperty_Rotation);
                types.push_back(kProperty_AnchorPoint);
                types.push_back(kProperty_Visible);
                types.push_back(kProperty_Color);
                types.push_back(kProperty_Alpha);
                types.push_back(kProperty_Texture);
                types.push_back(kProperty_ZDepth);
                types.push_back(kProperty_BlendSrc);
                types.push_back(kProperty_BlendDst);
                types.push_back(kProperty_ContentSize);
                types.push_back(kProperty_Insets);
                propertiesOfType[nodeType] = types;
            }
                break;
            case kNode_NEAnimNode:
            {
                types.push_back(kProperty_Position);
                types.push_back(kProperty_Scale);
                types.push_back(kProperty_Rotation);
                types.push_back(kProperty_AnchorPoint);
                types.push_back(kProperty_Visible);
                types.push_back(kProperty_Animation);
                types.push_back(kProperty_AnimationControl);
                types.push_back(kProperty_ZDepth);
            }
                break;
            default:
                break;
        }
    }
    return propertiesOfType.at(nodeType);
}
    
CCValue<NEFrame *> * NEAnimData::getDefaultFrame(int type)
{
    if (defaultFrames[type] == NULL) {
        NEFrame * f = new NEFrame;
        //create default keyframe
        f->index = 0;
        f->easeType = defaultData[type].easeType;
        f->easeClass = defaultData[type].easeClass;
        for (int i=0; i<defaultData[type].dimension; i++) {
            f->data[i] = defaultData[type].data[i];
        }
        CCValue<NEFrame *> * frame = CCValue<NEFrame *>::valueWithValue(f);
        frame->retain();
        defaultFrames[type] = frame;
    }
    return defaultFrames[type];
}
    
NEFrame * NEAnimData::getFrame(int nodeID, int type, int oIndex)
{
    CCDictionary * props = (CCDictionary *)m_keyframesData->objectForKey(nodeID);
    CCArray * frames = (CCArray *)props->objectForKey(type);
    if (!frames) {
        return getDefaultFrame(type)->getValue();
    }
//    if (frames->count() > oIndex) {
    CCValue<NEFrame *> * f = (CCValue<NEFrame *> *)frames->objectAtIndex(oIndex);
    return f->getValue();
//    }
//    else {
//        if (oIndex == 0) {
//            //create default keyframe
//            NEFrame * f = new NEFrame;
//            f->easeType = defaultData[type].easeType;
//            f->easeClass = defaultData[type].easeClass;
//            for (int i=0; i<defaultData[type].dimension; i++) {
//                f->data[i] = defaultData[type].data[i];
//            }
//            CCValue<NEFrame *> * frame = CCValue<NEFrame *>::valueWithValue(f);
//            frames->insertObject(frame, 0);
//            return f;
//        }
//    }
//    return NULL;
}

//return true if arrive at a new keyframe
NEFrame * NEAnimData::getRefFrame(NEFrame * frame, NEAnimNode * nodeData)
{
    int vid = frame->ref;
    if (vid != -1) {
        //check node
        NEFrame * refFrame = NULL;
        refFrame = nodeData->getVariableKeyframe(vid);
        if (refFrame) {
            refFrame->index = frame->index;
            return refFrame;
        }
        else {
            refFrame = nodeData->sharedData()->getVariableFrame(nodeData->getCurrentSkinName(), vid);
            if (refFrame) {
                refFrame->index = frame->index;
                return refFrame;
            }
        }
    }
    return frame;
}
    
void NEAnimData::getFrameData(NEFrame *frameData, int nodeID, int type, int oIndex, float fIndex, bool * arriveAtNew, bool * needUpdate, bool * updateEnd, NEAnimNode * nodeData)
{
    CCDictionary * props = (CCDictionary *)m_keyframesData->objectForKey(nodeID);
    CCArray * frames = (CCArray *)props->objectForKey(type);
    CCValue<NEFrame *> * f1 = (CCValue<NEFrame *> *)frames->objectAtIndex(oIndex);
    CCValue<NEFrame *> * f2 = (CCValue<NEFrame *> *)frames->objectAtIndex(oIndex+1);

    NEFrame * f2Frame = f2->getValue();
    bool retVal = false;
    
    *updateEnd = false;
    *needUpdate = false;
    if (fIndex >= f2Frame->index) {
        //check ref
        f2Frame = getRefFrame(f2Frame, nodeData);
        frameData->fill(f2Frame); 
        
        retVal = true;
        if (oIndex+2 >= frames->count()) {
            //final keyframe
            *updateEnd = true;
        }
        else {
            CCValue<NEFrame *> * f3 = (CCValue<NEFrame *> *)frames->objectAtIndex(oIndex+2);
            NEFrame * f3Frame = f3->getValue();
            if (f3Frame->index <= fIndex) {
                //need update
                *needUpdate = true;
            }
        }
        *arriveAtNew = retVal;
        return;
    }
    //interpolate
    NEFrame * f1Frame = f1->getValue();
    int f1Index = f1Frame->index;
    int f2Index = f2Frame->index;
    f1Frame = getRefFrame(f1Frame, nodeData);
    f2Frame = getRefFrame(f2Frame, nodeData);
    frameData->index = f1Index;
    frameData->easeType = f1Frame->easeType;
    frameData->easeClass = f1Frame->easeClass;
    float t = (fIndex - f1Index) / (float)(f2Index - f1Index);
    t = NEEaseInterpolate::getValue(f1Frame->easeType, f1Frame->easeClass, t);

    for (int i=0; i<defaultData[type].dimension; i++) {
        float d1 = f1Frame->data[i];
        float d2 = f2Frame->data[i];
        frameData->data[i] = d1 + (d2 - d1) * t;
    }

    *arriveAtNew = retVal;
}

int NEAnimData::getKeyframeIndexFromArray(CCArray *frames, int frameIndex)
{
    int last = frames->count() - 1;
    if (frameIndex > last) {
        return -1;
    }
    int index = getKeyframe(frames, 0, last, frameIndex);
    return index;
}


CCPoint NEAnimData::getPoint(NEFrame *frame)
{
    return ccp(frame->data[0], frame->data[1]);
}

CCSize NEAnimData::getSize(NEFrame *frame)
{
    return CCSizeMake(frame->data[0], frame->data[1]);
}
    
CCRect NEAnimData::getRect(NEFrame *frame)
{
    return CCRect(frame->data[0], frame->data[1], frame->data[2], frame->data[3]);
}

float NEAnimData::getFloat(NEFrame *frame)
{
    return frame->data[0];
}

int NEAnimData::getInt(NEFrame *frame)
{
    return (int)(frame->data[0]);
}

bool NEAnimData::getBool(NEFrame *frame)
{
    return (bool)(frame->data[0]);
}

ccColor3B NEAnimData::getColor(NEFrame *frame)
{
    return ccc3(frame->data[0], frame->data[1], frame->data[2]);
}

int NEAnimData::getKeyframe(CCArray *frames, int first, int last, int index)
{
    if (first + 1 >= last) {
        return first;
    }
    int mid = (last + first) / 2;
    CCValue<NEFrame *> * frameData = (CCValue<NEFrame *> *)frames->objectAtIndex(mid);
    NEFrame * f = frameData->getValue();
    if (f->index == index) {
        return f->index;
    }
    if (f->index < index) {
        return NEAnimData::getKeyframe(frames, mid, last, index);
    }
    return NEAnimData::getKeyframe(frames, first, mid, index);
}

// NEAnimFileData

NEAnimFileData::NEAnimFileData() :
    m_fileName("")
{
    m_stringsCache = CCDictionary::create();
    m_stringsCache->retain();
    m_texturesMap = CCDictionary::create();
    m_texturesMap->retain();
    m_nodeStructData = CCArray::create();
    m_nodeStructData->retain();
    m_animationDataMap = CCDictionary::create();
    m_animationDataMap->retain();
    m_refs.clear();
    m_nodeOrder.clear(); 
}

NEAnimFileData::~NEAnimFileData()
{
     m_stringsCache->release();
     m_texturesMap->release();
     m_nodeStructData->release();
     m_animationDataMap->release();
    m_refs.clear();
    m_nodeOrder.clear();
}

void NEAnimFileData::initWithFile(const char * fileName)
{
    m_fileName = fileName;
    xmlDocPtr doc = NULL;
    std::string path = CCFileUtils::sharedFileUtils()->fullPathForFilename(fileName);
    CCString * xml = CCString::createWithContentsOfFile(path.c_str());

    xmlKeepBlanksDefault(0);
    doc = xmlParseMemory(xml->getCString(), xml->length());
    if (doc) {
        //ok
        parseXMLContent(doc);
    }
    xmlFreeDoc(doc);
    xmlCleanupParser();
    xmlMemoryDump();//debug memory for regression tests
}

NEAnimFileData * NEAnimFileData::createFromFile(const char *fileName)
{
    NEAnimFileData * data = new NEAnimFileData;
    data->autorelease();
    data->initWithFile(fileName);
    return data;
}

std::string NEAnimFileData::getFileName()
{
    return m_fileName;
}

int NEAnimFileData::getRefCount()
{
    return m_refs.size();
}


CCArray * NEAnimFileData::getDataNodeStructure()
{
    return m_nodeStructData;
}


std::vector<int> & NEAnimFileData::getNodeOrder()
{
    return m_nodeOrder;
}
     

CCArray * NEAnimFileData::getAnimationNames()
{
    return m_animationDataMap->allKeys();
}
    
bool NEAnimFileData::hasAnimationNamed(const char *animationName)
{
    if (!animationName) {
        return false;
    }
    std::string key = std::string(animationName);
    return m_animationDataMap->objectForKey(key) != NULL;
}

NEAnimData * NEAnimFileData::getAnimData(const char *animationName)
{
    std::string key = std::string(animationName);
    return (NEAnimData *)m_animationDataMap->objectForKey(key);
}

CCString * NEAnimFileData::getStringByID(int stringID)
{
    return (CCString *)m_stringsCache->objectForKey(stringID);
}

int NEAnimFileData::getIDByString(const char *animName)
{
    CCArray * keys = m_stringsCache->allKeys();
    for (int i=0; i<m_stringsCache->count(); i++) {
        int sid = ((CCInteger *)keys->objectAtIndex(i))->getValue();
        CCString * string = getStringByID(sid);
        if (strcmp(string->getCString(), animName) == 0) {
            return sid;
        }
    }
    return -1;
}

CCSpriteFrame * NEAnimFileData::getTextureByID(int texID)
{
    CCInteger * sidNum = (CCInteger *)m_texturesMap->objectForKey(texID);
    if (sidNum) {
        int sid = sidNum->getValue();
        CCString * string = getStringByID(sid);
//        CCLOG("%s", string->getCString());
//        CCTextureCache::sharedTextureCache()->dumpCachedTextureInfo();
        return CCSpriteFrameCache::sharedSpriteFrameCache()->spriteFrameByName(string->getCString());
    }
    return NULL;
}

void NEAnimFileData::registAnimNode(NEAnimNode *rootNode)
{
    m_refs.insert(rootNode);
}

void NEAnimFileData::unregistAnimNode(NEAnimNode *rootNode)
{
    std::set<NEAnimNode *>::iterator it = m_refs.find(rootNode);
    if (it != m_refs.end()) {
        m_refs.erase(it);
    }
}

void NEAnimFileData::changeToAnimData(neanim::NEAnimFileData *animData)
{
    std::set<NEAnimNode *> refs = m_refs;
    
    std::set<NEAnimNode *>::iterator it = refs.begin();
    for (; it != refs.end(); it++) {
        NEAnimNode * node = *it;
        node->replaceWithAnimData(animData);
    } 
}
    
bool NEAnimFileData::isSkinExist(const char *skinName)
{
    std::string key = std::string(skinName);
    return m_skins.find(key) != m_skins.end();
}

bool NEAnimFileData::isVariableExist(const char *varName)
{
    std::string key = std::string(varName);
    return m_variables.find(key) != m_variables.end();
}

NEFrame * NEAnimFileData::getVariableFrame(const char *skinName, int vid)
{
    if (isSkinExist(skinName)) {
        std::string key = std::string(skinName);
        std::map<int, NEFrame *> & frames = m_skins[key];
        if (frames.find(vid) != frames.end()) {
            return frames[vid];
        }
    }
    return NULL;
}

int NEAnimFileData::getVariableID(const char *varName)
{
    if (isVariableExist(varName)) {
        std::string key = std::string(varName);
        return m_variables[key];
    }
    return -1;
}

int getIntegerFromXML(xmlNodePtr ptr, const char * attName)
{
    char * strPtr = (char *)xmlGetProp(ptr, (const xmlChar *)attName);
    if (!strPtr) {
        return -1;
    }
    int integer = (int)strtol(strPtr, NULL, 10);
    xmlFree(strPtr);
    return integer;
}
    
CCString * getStringFromXML(xmlNodePtr ptr, const char * attName)
{
    char * strPtr = (char *)xmlGetProp(ptr, (const xmlChar *)attName);
    CCString * string = CCString::createWithFormat("%s", strPtr);
    xmlFree(strPtr);
    return string;
}
    
void NEAnimFileData::parseXMLContent(xmlDocPtr doc)
{
    xmlNodePtr  root = xmlDocGetRootElement(doc);
    xmlNodePtr  cur = root;
    //walk the tree
    cur=cur->xmlChildrenNode;//get sub node
    while(cur !=NULL)
    {
        if ((!xmlStrcmp(cur->name, (const xmlChar *)"StringCache"))){
            xmlNodePtr lastNode = cur;
            cur = cur->xmlChildrenNode;
            while (cur != NULL) {
                int sid = getIntegerFromXML(cur, "SID");
                CCString * string = getStringFromXML(cur, "String");
                m_stringsCache->setObject(string, sid);
                cur = cur->next;
            }
            cur = lastNode;
        }
        else if ((!xmlStrcmp(cur->name, (const xmlChar *)"xidLinks"))) {
            xmlNodePtr lastNode = cur;
            cur = cur->xmlChildrenNode;
            while (cur != NULL) {
                int sid = getIntegerFromXML(cur, "SID");
                int xid = getIntegerFromXML(cur, "XID");
            
                m_texturesMap->setObject(CCInteger::create(sid), xid);
                cur = cur->next;
            }
            cur = lastNode;
        }
        else if ((!xmlStrcmp(cur->name, (const xmlChar *)"Variables"))) {
            xmlNodePtr lastNode = cur;
            cur = cur->xmlChildrenNode;
            while (cur != NULL) {
                int vid = getIntegerFromXML(cur, "VID");
                CCString * name = getStringFromXML(cur, "name");
                std::string key = std::string(name->getCString());
                m_variables[key] = vid;
                cur = cur->next;
            }
            cur = lastNode;
        }
        else if ((!xmlStrcmp(cur->name, (const xmlChar *)"Skins"))) {
            xmlNodePtr lastNode = cur;
            cur = cur->xmlChildrenNode;
            while (cur != NULL) {
                CCString * skinName = getStringFromXML(cur, "name");
                std::string key = std::string(skinName->getCString());
                xmlNodePtr lastAnimNode = cur;
                cur = cur->xmlChildrenNode;
                std::map<int, NEFrame *> & frames = m_skins[key];
                while (cur != NULL) {
                    NEFrame * f = new NEFrame;
                    int vid = (int) getIntegerFromXML(cur, "VID");
                    f->easeType = (NEEaseType)getIntegerFromXML(cur, "changeType");
                    f->easeClass = (NEEaseClass)getIntegerFromXML(cur, "changeClass");
                    std::string dataStr = getStringFromXML(cur, "data")->getCString();
                    std::string split = std::string("|");
                    std::vector<std::string> splits;
                    stringsplit(dataStr, split, &splits);
                    for (int i=0; i<splits.size(); i++) {
                        f->data[i] = atof(splits.at(i).c_str());
                    }
                    frames[vid] = f;
                    cur = cur->next;
                }
                cur = lastAnimNode;
                
                cur = cur->next;
            }
            cur = lastNode;
        }
        else if ((!xmlStrcmp(cur->name, (const xmlChar *)"NodeStructure"))) {
            xmlNodePtr lastNode = cur;
            cur = cur->xmlChildrenNode;
            while (cur != NULL) {
                int from = getIntegerFromXML(cur, "From");
                int to = getIntegerFromXML(cur, "To");
                int type = getIntegerFromXML(cur, "Type");
                CCString * nameStr = getStringFromXML(cur, "Name");
                const char * name = nameStr->getCString();
                if (name) {
                    m_nodeStructData->addObject(CCString::createWithFormat("%d|%d|%d|%s", from, to, type, name));
                }
                else {
                    m_nodeStructData->addObject(CCString::createWithFormat("%d|%d|%d", from, to, type));
                }
                m_nodeOrder.push_back(to);
                cur = cur->next;
            }
            cur = lastNode;
        }
        else if ((!xmlStrcmp(cur->name, (const xmlChar *)"Animations"))) {
            xmlNodePtr lastNode = cur;
            cur = cur->xmlChildrenNode;
            while (cur != NULL) {
                //animation

                NEAnimData * data = new NEAnimData; 

                xmlNodePtr lastAnimNode = cur;
                cur = cur->xmlChildrenNode;
                while (cur != NULL) {
                    if ((!xmlStrcmp(cur->name, (const xmlChar *)"TextureFiles"))) {
                        xmlNodePtr texNode = cur;
                        cur = cur->xmlChildrenNode;
                        while (cur != NULL) {
                            CCString * string = getStringFromXML(cur, "FileName");
                            data->m_usedTextureFiles->addObject(string);
                            cur = cur->next;
                        }
                        cur = texNode;
                    }
                    else if ((!xmlStrcmp(cur->name, (const xmlChar *)"Keyframes"))) {
                        xmlNodePtr texNode = cur;
                        cur = cur->xmlChildrenNode;
                        while (cur != NULL) {
                            CCDictionary * nodeFrames = CCDictionary::create();
                            int nodeID = getIntegerFromXML(cur, "NodeID");
                            data->m_keyframesData->setObject(nodeFrames, nodeID);
                            xmlNodePtr propertyNode = cur;
                            cur = cur->xmlChildrenNode;
                            while (cur != NULL) {
                                NEPropertyType type = (NEPropertyType)getIntegerFromXML(cur, "Type");
                                CCArray * typeFrames = CCArray::create();
                                nodeFrames->setObject(typeFrames, type);
                                xmlNodePtr frameNode = cur;
                                cur = cur->xmlChildrenNode;

                                while (cur != NULL) {
                                    NEFrame * f = new NEFrame;
                                    f->index = (int) getIntegerFromXML(cur, "index");
                                    f->ref = (int) getIntegerFromXML(cur, "ref");
                                    f->easeType = (NEEaseType)getIntegerFromXML(cur, "changeType");
                                    f->easeClass = (NEEaseClass)getIntegerFromXML(cur, "changeClass");
                                    std::string dataStr = getStringFromXML(cur, "data")->getCString();
                                    std::string split = std::string("|");
                                    std::vector<std::string> splits;
                                    stringsplit(dataStr, split, &splits);
                                    for (int i=0; i<splits.size(); i++) {
                                        f->data[i] = atof(splits.at(i).c_str());
                                    }
                                    CCValue<NEFrame *> * value = CCValue<NEFrame *>::valueWithValue(f);
                                    typeFrames->addObject(value);
                                    cur = cur->next;
                                }
                                cur = frameNode;
                                cur = cur->next;
                            }
                            cur = propertyNode;
                            cur = cur->next;
                        }
                        cur = texNode;
                    }
                    cur = cur->next;
                }
                
                
                NEFrame * animf = data->getFrame(0, kProperty_AnimName, 0);
                int sid = NEAnimData::getInt(animf);
                data->m_animName = getStringByID(sid)->m_sString;
                animf = data->getFrame(0, kProperty_AnimLength, 0);
                data->m_length = NEAnimData::getInt(animf);
                animf = data->getFrame(0, kProperty_AnimFPS, 0);
                data->m_fps = NEAnimData::getInt(animf);
                data->m_spf = 1.f / (float) data->m_fps;
                animf = data->getFrame(0, kProperty_Loop, 0);
                data->m_loop = NEAnimData::getBool(animf);
                
                m_animationDataMap->setObject(data, data->m_animName.c_str());
                cur = lastAnimNode;
                cur = cur->next;
            }
            cur = lastNode;
        }
        cur = cur->next;
    }
    CCDictElement * pElement = NULL;
    CCDICT_FOREACH(m_animationDataMap, pElement) {

        for (std::vector<int>::iterator it = m_nodeOrder.begin(); it != m_nodeOrder.end(); it++) {
        //CCARRAY_FOREACH(m_nodeOrder, pNodeElement) {
//        CCDICT_FOREACH(m_nodesIndexMap, pNodeElement) {
//            int nodeid = pNodeElement->getValue();
            int nodeid = *it;
            NEAnimData * animData = (NEAnimData *)pElement->getObject();
            CCDictionary * keyFrames = (CCDictionary *)animData->m_keyframesData->objectForKey(nodeid);
            if (!keyFrames) {
                keyFrames = CCDictionary::create();
                animData->m_keyframesData->setObject(keyFrames, nodeid);
            }
            int nodetype = nodeid == 0 ? 0 : 1;
            std::vector<NEPropertyType> & types = getPropertyOfType(nodetype);

            for (std::vector<NEPropertyType>::iterator it = types.begin(); it!=types.end(); it++) {
                int i = *it;
                CCArray * frames = (CCArray *)keyFrames->objectForKey(i);
                if (!frames) {
                    frames = CCArray::create();
                    keyFrames->setObject(frames, i);
                }
                if (frames->count() == 0) {
                    frames->addObject(NEAnimData::getDefaultFrame(i));
                }
                else {
                    CCValue<NEFrame *> * value = (CCValue<NEFrame *> *)frames->objectAtIndex(0);
                    NEFrame * f = value->getValue();
                    if (f->index != 0) {
                        frames->insertObject(NEAnimData::getDefaultFrame(i), 0);
                    }
                }
            }
        }
    }
//    NSLog(@"%@", m_stringsCache);
//    NSLog(@"%@", m_texturesMap);
//    NSLog(@"%@", m_nodeStructData);
//    NSLog(@"%@", m_animationDataMap);

}




// NEAnimNode

NEAnimNode::NEAnimNode() :
    m_sharedData(NULL),
    m_currentAnimData(NULL),
    m_time(0.f),
    m_paused(true),
    m_delegate(NULL),
    m_smoothAnimation(true),
    m_isAutoRemove(false),
    m_currentFrameIndex(0),
    m_lastFrameIndex(0)
{
    init();
//    m_updateArray = CCArray::create();
//    m_updateArray->retain();
    m_updateArray.clear();
    m_nodeMap.clear();
    m_nodeIDMap.clear();
    m_callbacks = CCDictionary::create();
    m_callbacks->retain();
}

NEAnimNode::~NEAnimNode()
{
//    if (m_sharedData && m_currentAnimData) {
//        CCLog("anim deleted: %s %s", m_sharedData->getFileName().c_str(), m_currentAnimData->m_animName.c_str());
//    }
//    else {
//        CCLog("anim deleted, empty");
//    }

    destroyNodeStructure();
    if (m_sharedData) {
        m_sharedData->unregistAnimNode(this);
    }
//    m_updateArray->release();
    m_updateArray.clear();
    m_callbacks->release();
}
    
//void NEAnimNode::retain()
//{
//    //CCLOG("node:%x, retcount:%d->%d, retain", this, retainCount(), retainCount() + 1);
//    CCSprite::retain();
//}
//    
//void NEAnimNode::release()
//{
//    //CCLOG("node:%x, retcount:%d->%d, release", this, retainCount(), retainCount() - 1);
//    CCSprite::release();
//}

NEAnimNode * NEAnimNode::create()
{
    NEAnimNode * node = new NEAnimNode;
    node->autorelease();
    return node;
}
    
NEAnimNode * NEAnimNode::createNodeFromFile(const char *fileName)
{
    NEAnimNode * node = new NEAnimNode;
    node->autorelease();
    node->useAnimFile(fileName);
    return node;
}
    
void NEAnimNode::changeFile(const char *fileName)
{
    if (m_sharedData && m_sharedData->getFileName().compare(fileName) == 0) {
        return;
    }
    useAnimFile(fileName);
}

//#pragma mark - User Functions
void NEAnimNode::setDelegate(NEAnimCallback *delegate)
{
    m_delegate = delegate;
}

void NEAnimNode::playAnimation(const char * animationName, int frameIndex, bool isPaused, bool isContinue)
{
    if (isContinue && isPlayingAnimation(animationName)) {
        //do nothing
        return;
    }
    if (!m_sharedData || !m_sharedData->hasAnimationNamed(animationName)) {
        return;
    }
    loadAnimation(animationName);
    m_paused = isPaused;
    m_time = 0.f;
    setCurrentFrameIndex(frameIndex);
//    if (m_sharedData) {
//        CCLog("play anim : %s, %s", m_sharedData->getFileName().c_str(), animationName);
//    }

}
    
void NEAnimNode::playAnimationCallback(cocos2d::CCString *animationName)
{
    playAnimation(animationName->getCString());
}

void NEAnimNode::pauseAnimation(bool paused)
{
    m_paused = paused;
}

void NEAnimNode::resumeAnimation()
{
    m_paused = false;
}
    
bool NEAnimNode::isPaused()
{
    return m_paused;
}

void NEAnimNode::stopAnimation()
{
    if (m_currentAnimData) {
        setCurrentFrameIndex(m_currentAnimData->m_length);
    }
    m_paused = true;
}
    
bool NEAnimNode::isPlayingAnimation(const char * animationName)
{
    if (!m_currentAnimData) {
        return false;
    }
    if (animationName) {
        if (strcmp(m_currentAnimData->m_animName.c_str(), animationName) == 0) {
            return true;
        }
        else {
            return false;
        }
    }
    else {
        return !m_paused;
    }
}
void NEAnimNode::useAnimFile(const char *fileName)
{
    if (m_sharedData) {
        if (m_sharedData->getFileName().compare(fileName) == 0) {
            return;
        }
        else {
            //unregist self
            unloadCurrentAnimation();
            m_sharedData->unregistAnimNode(this);
            m_sharedData = NEAnimManager::sharedManager()->getSharedDataForFile(fileName);
            m_sharedData->registAnimNode(this);
            loadFileData();
        }
    }
    else {
        m_sharedData = NEAnimManager::sharedManager()->getSharedDataForFile(fileName);
        m_sharedData->registAnimNode(this);
        loadFileData();
    }
}
    
void NEAnimNode::replaceWithAnimData(neanim::NEAnimFileData *sharedData)
{
    if (m_sharedData) { 
        //unregist self
        m_paused = true;
        unloadCurrentAnimation();
        m_sharedData->unregistAnimNode(this);
        m_sharedData = sharedData;
        m_sharedData->registAnimNode(this);
        loadFileData(); 
    }
    else {
        m_sharedData = sharedData;
        m_sharedData->registAnimNode(this);
        loadFileData();
    }
}
    
void NEAnimNode::setSmoothPlaying(bool smooth)
{
    m_smoothAnimation = smooth;
}

bool NEAnimNode::isSmoothPlaying()
{
    return m_smoothAnimation;
}


//#pragma mark - Core
void NEAnimNode::onEnter()
{
    CCSprite::onEnter();
    scheduleUpdate();
}

void NEAnimNode::onExit()
{
    m_delegate = NULL;
    unscheduleUpdate();
    CCSprite::onExit();
}
    
void NEAnimNode::update(float delta)
{
    if (m_paused) {
        return;
    }
    if (!m_currentAnimData) {
        m_paused = true;
        return;
    }
    m_time += delta;
    float spf = 1.f / m_customFPS;
    bool update = m_smoothAnimation ? true : m_time > spf;
    if (update) {
        m_time = 0.f;
        m_currentFrameIndex += m_smoothAnimation ? delta * m_customFPS : 1;
        if (m_currentFrameIndex >= m_currentAnimData->m_length - 1) {
            //animation end
            m_currentFrameIndex = m_currentAnimData->m_length - 1;
            if (m_currentAnimData->m_loop) {
                setCurrentFrameIndex(0);
            }
            else {
                pauseAnimation();
                if (m_delegate) {
                    m_delegate->animationEnded(this, m_currentAnimData->m_animName.c_str());
                    m_delegate = NULL;
                }
                if (m_isAutoRemove) {
                    removeFromParentAndCleanup(true);
                    return;
                }
            }
        } 
        //update
        NEFrame f;
//        CCArray * updateEnds = CCArray::create();
        std::vector<int> updateEnds;
        for (int i=0; i<m_updateArray.size(); i++) {
            updateData & nodeData = m_updateArray[i];
            
            int nodeID = nodeData.nodeID;
            int type = nodeData.propType;
            if (!isPropertyInControl(nodeID, (NEPropertyType)type)) {
                continue;
            }
            int objectIndex = nodeData.index;
            bool arriveAtNew = false;
            bool needUpdateNow = true;
            bool updateEnd = false;
            
            while (needUpdateNow) {
                m_currentAnimData->getFrameData(&f, nodeID, type, objectIndex, m_currentFrameIndex, &arriveAtNew, &needUpdateNow, &updateEnd, this);
                CCNode * node = getNodeByNodeID(nodeID);
                if (f.easeType == kEase_Pulse) {
                    if (m_lastFrameIndex < f.index && m_currentFrameIndex >= f.index) {
                        setNodeProperty(&f, (NEPropertyType)type, node);
                    }
                }
                else {
                    setNodeProperty(&f, (NEPropertyType)type, node);
                }
                
                
                if (updateEnd) {
                    updateEnds.push_back(i);
                }
                else if (arriveAtNew) {
                    objectIndex++;
                }
            }
            nodeData.nodeID = nodeID;
            nodeData.index = objectIndex;
            nodeData.propType = type;
            m_updateArray[i] = nodeData;
//            CCArray * array = CCArray::create();
//            array->addObject(CCInteger::create(nodeID));
//            array->addObject(CCInteger::create(type));
//            array->addObject(CCInteger::create(objectIndex));
//            m_updateArray->replaceObjectAtIndex(i, array);

        }
//        m_updateArray->removeObjectsInArray(updateEnds);
        for (int i=updateEnds.size()-1; i>=0; i--) {
            int idx = updateEnds[i];
            std::vector<updateData>::iterator it = m_updateArray.begin() + idx;
            m_updateArray.erase(it);
        }
        m_lastFrameIndex = m_currentFrameIndex;
    }
}
//#pragma mark - helper

void NEAnimNode::setCurrentFrameIndex(int frameIndex)
{
    m_currentFrameIndex = frameIndex;
    m_lastFrameIndex = m_currentFrameIndex;
//    m_updateArray->removeAllObjects();
    m_updateArray.clear(); 
    //will update all nodes' state
    std::vector<int> & nodeOrder = m_sharedData->getNodeOrder();
    for (std::vector<int>::iterator it = nodeOrder.begin(); it!= nodeOrder.end(); it++) {
        int nodeID = *it;
        
        std::set<int> * releaseTypes = NULL;
        if (m_releaseControlNodes.find(nodeID) != m_releaseControlNodes.end()) {
            releaseTypes = &(m_releaseControlNodes[nodeID]);
        }
        if (releaseTypes) {
            if (releaseTypes->find(kProperty_All) != releaseTypes->end()) {
                //skip all properties
                continue;
            }
        }
        
        CCNode * node = getNodeByNodeID(nodeID);
        if (!node) {
            continue;
        }
        CCDictionary * data = (CCDictionary *)m_currentAnimData->m_keyframesData->objectForKey(nodeID);
        for (int i=0; i<kProperty_Num; i++) {
            int propType = propertyPriority[i];
            if (data->objectForKey(propType) == NULL) {
                continue;
            }
            
            if (releaseTypes && releaseTypes->find(propType) != releaseTypes->end()) {
                //skip this property
                continue;
            }
            CCArray * frames = (CCArray *)data->objectForKey(propType);
            int index = NEAnimData::getKeyframeIndexFromArray(frames, 0);
            //NSAssert(index != -1, @"check key frames data! empty key frames array");
            NEFrame * frame;
            CCValue<NEFrame*> * value = (CCValue<NEFrame*> *)frames->objectAtIndex(index);
            frame = value->getValue();
            frame = NEAnimData::getRefFrame(frame, this);
            setNodeProperty(frame, (NEPropertyType)propType, node);
            if (index != frames->count() - 1) {
                //update this node in coming frames
                updateData d;
                d.index = index;
                d.propType = propType;
                d.nodeID = nodeID;
                m_updateArray.push_back(d);
            }
        }
    }
}

void NEAnimNode::setNodeProperty(NEFrame *frameData, NEPropertyType type, CCNode *node)
{
    switch (type) {
        case kProperty_Position:{
            CCPoint p = NEAnimData::getPoint(frameData);
            node->setPosition(ccp(m_scaleFactor * p.x, m_scaleFactor * p.y));
        }
            break;
        case kProperty_Scale:{
            CCSize size = NEAnimData::getSize(frameData);
            node->setScaleX(size.width);
            node->setScaleY(size.height);
        }
            break;
        case kProperty_Skew:{
            CCSize size = NEAnimData::getSize(frameData);
            node->setSkewX(size.width);
            node->setSkewY(size.height);
        }
            break;
        case kProperty_Rotation:{
            CCPoint rot = NEAnimData::getPoint(frameData);
            node->setRotationX(rot.x);
            node->setRotationY(rot.y);
        }
            break;
        case kProperty_AnchorPoint:{
            node->setAnchorPoint(NEAnimData::getPoint(frameData));
        }
            break;

        case kProperty_Visible:{
            node->setVisible(NEAnimData::getBool(frameData));
        }
            break;

        case kProperty_Color:{
            CCRGBAProtocol * sprite = dynamic_cast<CCRGBAProtocol *>(node);
            if (sprite) {
                sprite->setColor(NEAnimData::getColor(frameData));
            }
        }
            break;

        case kProperty_Alpha:{
            CCRGBAProtocol * sprite = dynamic_cast<CCRGBAProtocol *>(node);
            if (sprite) {
                sprite->setOpacity(NEAnimData::getFloat(frameData));
            }
        }
            break;
        case kProperty_Texture: {
            int xid = NEAnimData::getInt(frameData);
            if (m_xidLinks.find(xid) != m_xidLinks.end()) {
                if (xid != m_xidLinks[xid]) {
                    xid = m_xidLinks[xid];
                }
            }
            CCSpriteFrame * frame = m_sharedData->getTextureByID(xid);

            CCSprite * sprite = dynamic_cast<CCSprite *>(node);
            if (sprite) {
                NEAnimNode * animRootNode = dynamic_cast<NEAnimNode *>(node);
                if (animRootNode) {
                    break;
                }
   
                if (!frame) {
                    sprite->setTextureRect(CCRect(0, 0, 0, 0));
                    sprite->setContentSize(CCSizeMake(0, 0)); 
                }
                else {
                    sprite->setDisplayFrame(frame);
                }
            }
            else {
                if (!frame) {
                    break;
                }
                CCScale9Sprite * sprite9 = dynamic_cast<CCScale9Sprite *>(node);
                if (sprite9) {
                    sprite9->setSpriteFrame(frame);
                }
            }
        }
            break;
        case kProperty_FontSize: {
            CCLabelTTF * label = (CCLabelTTF *)node;
            float size = m_scaleFactor * NEAnimData::getFloat(frameData);
            label->setFontSize(size);
        }
            break;
        case kProperty_ZDepth: { 
            int z = NEAnimData::getInt(frameData);
            if (node->getParent()) {
                node->getParent()->reorderChild(node, z);
            }
        }
            break;
        case kProperty_Callback: {
            int callIndex = NEAnimData::getInt(frameData);
            if (callIndex == -1) {
                break;
            }
            if (m_delegate) {
                CCString * callback = m_sharedData->getStringByID(callIndex);
                if (callback && strcmp(callback->getCString(), "") != 0) {
                    m_delegate->animationCallback(this, m_currentAnimData->m_animName.c_str(), callback->getCString());
                }
                CCCallFunc * callfunc = (CCCallFunc *)m_callbacks->objectForKey(callback->getCString());
                if (callfunc) {
                    callfunc->execute();
                }
            }
        }
            break;
        case kProperty_Sound:
        {
            int index = NEAnimData::getInt(frameData);
            if (index != -1) {
                CCString * sound = m_sharedData->getStringByID(index);
                if (sound) {
                    NEAnimManager::sharedManager()->playSound(sound->getCString());
                }
            }
        }
            break;
        case kProperty_StringValue:
        {
            int index = NEAnimData::getInt(frameData);
            if (index != -1) {
                CCString * text = m_sharedData->getStringByID(index);
                if (text) {
                    const char * str = NEAnimManager::sharedManager()->getLocalizedString(text->getCString());
                    CCLabelBMFont * label = (CCLabelBMFont *)node;
                    label->setString(str);
                }
            }
        }
            break;
        case kProperty_ContentSize:
        {
            CCScale9Sprite * sprite = dynamic_cast<CCScale9Sprite *>(node);
            if (sprite) {
                CCSize size = NEAnimData::getSize(frameData);
                sprite->setPreferredSize(size);
            }
        }
            break;
        case kProperty_Insets:
        {
            CCScale9Sprite * sprite = dynamic_cast<CCScale9Sprite *>(node);
            if (sprite) {
                CCRect rect = NEAnimData::getRect(frameData);
                CCSize originalSize = sprite->getOriginalSize();
                float left = originalSize.width * rect.origin.x;
                float bottom = originalSize.height * rect.origin.y;
                float width = originalSize.width * rect.size.width - left;
                float height = originalSize.height * rect.size.height - bottom;
                if (originalSize.width != 0.f && originalSize.height != 0.f ) {
                    sprite->setCapInsets(CCRect(left, bottom, width, height));
                }

            }
        }
            break;
        case kProperty_BlendSrc: {
            int b = NEAnimData::getInt(frameData);
            CCSprite * sprite = dynamic_cast<CCSprite *>(node);
            if (sprite) {
                ccBlendFunc blend = sprite->getBlendFunc();
                blend.src = b;
                sprite->setBlendFunc(blend);
            }
        }
            break;
        case kProperty_BlendDst: {
            int b = NEAnimData::getInt(frameData);
            CCSprite * sprite = dynamic_cast<CCSprite *>(node);
            if (sprite) {
                ccBlendFunc blend = sprite->getBlendFunc();
                blend.dst = b;
                sprite->setBlendFunc(blend);
            }
        }
            break;
        case kProperty_AnimSkin:
        {
            neanim::NEAnimNode * animNode = (neanim::NEAnimNode *)node;
            int sid = NEAnimData::getInt(frameData);
            
            CCString * animName = this->sharedData()->getStringByID(sid);
            if (!animName) {
                break;
            }
            animNode->useSkin(animName->getCString());
        }
            break;
        case kProperty_AnimationControl:
        {
            float * animData = frameData->data;
            
            bool pause = animData[0] == 1;
            pause = m_paused ? true : pause;
            int animsid = (int)animData[1];
            
            if (animsid == -1) {
                break;
            }
            int specifiedIndex = (int)animData[2];
            bool freeTex = (int)animData[3] == 1;
            NEAnimNode * anim = dynamic_cast<NEAnimNode *>(node);
            if (anim) {
                NEAnimFileData * sharedData = anim->sharedData();
                if (!sharedData) {
                    break;
                }
                CCString * animName = this->sharedData()->getStringByID(animsid);
                if (animName) {
                    const char * animNameChars = animName->getCString();
                    bool willContinue = specifiedIndex == -1 && anim->isPlayingAnimation(animNameChars);
                    if (specifiedIndex == -1) {
                        specifiedIndex = 0;
                    }
                    else {
                        specifiedIndex --;
                    }
                    anim->playAnimation(animName->getCString(), specifiedIndex, pause, willContinue);
                }
                else {
                    CCLOG("cannot find anim name!");
                }
            }

        }
            break;
        default:
            break;
    }
}

void NEAnimNode::loadFileData()
{
    //create node structure
    destroyNodeStructure();
    createNodeStructure();
}

void NEAnimNode::destroyNodeStructure()
{
//    std::vector<int> & nodeOrder = m_sharedData->getNodeOrder();
//    for (int i=nodeOrder.size()-1; i>= 0; i--) {
//        int nodeid = nodeOrder.at(i);
//        CCNode * node = m_nodeMap[nodeid];
//        if (node) {
//            node->removeFromParentAndCleanup(true);            
//        } 
//    }
    //remove all custom variable keyframes
    std::map<std::string, std::map<int, NEFrame * > > m_customFrames;
    for (std::map<std::string, std::map<int, NEFrame * > >::iterator it = m_customFrames.begin(); it != m_customFrames.end(); it++) {
        std::string key = it->first;
        std::map<int, NEFrame * > & frames = it->second;
        for (std::map<int, NEFrame *>::iterator it2 = frames.begin(); it2 != frames.end(); it2++) {
            NEFrame * frame = it2->second;
            delete frame;
        }
    }
    m_customFrames.clear();
    
    for (std::map<int, CCNode *>::iterator it = m_nodeMap.begin(); it != m_nodeMap.end(); it++) {
        CCNode * node = it->second;
        if (node == this) {
            continue;
        }
        node->removeFromParentAndCleanup(true);
    }
    for (std::map<int, CCNode *>::iterator it = m_nodeMap.begin(); it != m_nodeMap.end(); it++) {
        CCNode * node = it->second;
        if (node == this) {
            continue;
        }
        node->release();
    }
    m_nodeMap.clear();
    m_nodeIDMap.clear();
    m_releaseControlNodes.clear();
}

void NEAnimNode::createNodeStructure()
{
    if (m_sharedData) {
        CCArray * nodeStructureData = m_sharedData->getDataNodeStructure();
        for (int i=0; i<nodeStructureData->count(); i++) {
            CCString * structure = (CCString *)nodeStructureData->objectAtIndex(i);
            std::string structureString = std::string(structure->getCString());
            std::vector<std::string> splits;
            std::string split = std::string("|");
            stringsplit(structureString, split, &splits );

            int nodeIDFrom = atoi(((std::string)splits.at(0)).c_str());
            int nodeIDTo = atoi(splits.at(1).c_str());
            NENodeType type = (NENodeType)atoi(splits.at(2).c_str());
            if (splits.size() > 3) {
                std::string name = std::string(splits.at(3).c_str());
                m_indexMap[name] = nodeIDTo;
            }

            CCNode * node = NULL;
            switch (type) {
                case kNode_Default:
                case kNode_Root:
                case kNode_Sprite:
                {
                    node = CCSprite::create();
//                    node->setVisible(false);
                }
                    break;
                case kNode_Particle:
                {

                }
                    break;
                case kNode_NEAnimNode:
                {
                    node = new NEAnimNode;
                    node->autorelease();
                }
                    break;
                case kNode_Label:
                {
                    CCLabelBMFont * label = CCLabelBMFont::create();
                    node = label;
                }
                    break;
                case kNode_Sprite9:
                {
                    node = CCScale9Sprite::create();
                }
                    break;
                default:
                    break;
            }
            if (nodeIDFrom == -1) {
                //root node, don't need to add
                m_nodeMap[nodeIDTo] = this;
                m_nodeIDMap[this] = nodeIDTo;
            }
            else {
                CCNode * parent = getNodeByNodeID(nodeIDFrom);
                if (parent) {
                    parent->addChild(node, 0);
                    //node->retain();
                    m_nodeMap[nodeIDTo] = node;
                    m_nodeIDMap[node] = nodeIDTo;
                    node->retain();
                }
                else {
                    CCLOG("Node Structure Error! from:%d to:%d type:%d", nodeIDFrom, nodeIDTo, type);
                }
            }
        }
    }
}

CCNode * NEAnimNode::getNodeByNodeID(int nodeID)
{
    if (m_nodeMap.find(nodeID) != m_nodeMap.end()) {
        return m_nodeMap[nodeID];
    }
    return NULL;
}
    
int NEAnimNode::getNodeIDByNode(cocos2d::CCNode *node)
{
    if (m_nodeIDMap.find(node) != m_nodeIDMap.end()) {
        return m_nodeIDMap[node];
    }
    return -1;
}
    
CCNode * NEAnimNode::getNodeByName(const char *nodeName)
{
    std::string key(nodeName);
    if (m_indexMap.find(key) != m_indexMap.end()) {
        return getNodeByNodeID(m_indexMap[key]);
    }
    return NULL;
}
    
void NEAnimNode::replaceNode(const char *nodeName, cocos2d::CCNode *node)
{ 
    std::string key(nodeName);
    std::map<std::string, int>::iterator it = m_indexMap.find(key); 
    if (it != m_indexMap.end()) {
        int nodeID = m_indexMap[key];
        CCNode * rNode = getNodeByNodeID(nodeID);
        
        //remove all nodes that in this node
        removeNodeRecursively(rNode);
        m_nodeIDMap.erase(rNode);
        
        CCNode * parent = rNode->getParent();
        rNode->release();
        rNode->removeFromParentAndCleanup(true);
        parent->addChild(node);
        node->retain();
        
        m_nodeMap[nodeID] = node;
        m_nodeIDMap[node] = nodeID; 
    } 
}
    
void NEAnimNode::removeNodeRecursively(CCNode * node)
{
    CCObject * child = NULL;
    CCARRAY_FOREACH(node->getChildren(), child) {
        CCNode * n = (CCNode *)child; 
        int nodeID = getNodeIDByNode(n);
        if (nodeID != -1 ) {
            m_nodeMap.erase(nodeID);
            m_nodeIDMap.erase(n); 
        }
        removeNodeRecursively(n);
    }
}

void NEAnimNode::loadAnimation(const char *animationName)
{
    if (m_currentAnimData) {
        if (m_currentAnimData->m_animName.compare(animationName) == 0) {
            return;
        }
        unloadCurrentAnimation();
    }
    m_currentAnimData = m_sharedData->getAnimData(animationName);
    m_customFPS = m_currentAnimData->m_fps;
    NEAnimManager * manager = NEAnimManager::sharedManager();
    for (int i=0; i<m_currentAnimData->m_usedTextureFiles->count(); i++) {
        CCString * texFile = (CCString *)m_currentAnimData->m_usedTextureFiles->objectAtIndex(i);
        if (strcmp(texFile->getCString(), "") == 0) {
            continue;
        }
        manager->useSpriteframesFromFile(texFile);
    }
    //load anim nodes
    for (std::map<CCNode *, int>::iterator it = m_nodeIDMap.begin(); it!=m_nodeIDMap.end(); it++){
        CCNode * n = it->first;
        NEAnimNode * anim = dynamic_cast<NEAnimNode *>(n);
        if (anim) {
            int nodeID = it->second;
            if (!isPropertyInControl(nodeID, kProperty_Animation)) {
                continue;
            }
            NEFrame * fr = m_currentAnimData->getFrame(nodeID, kProperty_Animation, 0);
            int sid = NEAnimData::getInt(fr);
            CCString * name = m_sharedData->getStringByID(sid);
            if (name && strcmp(name->getCString(), "") != 0 ) {
                CCString * f = CCString::createWithFormat("%s.ani", name->getCString());
                //if (isFileExist(f->getCString())) {
                    anim->useAnimFile(f->getCString());
                //}
            }
        }
        
        CCLabelBMFont * label = dynamic_cast<CCLabelBMFont *>(n);
        if (label) {
            int nodeID = it->second;
            if (!isPropertyInControl(nodeID, kProperty_FNTFile)) {
                continue;
            }
            NEFrame * fr = m_currentAnimData->getFrame(nodeID, kProperty_FNTFile, 0);
            int sid = NEAnimData::getInt(fr);
            CCString * name = m_sharedData->getStringByID(sid);
            if (name && strcmp(name->getCString(), "") != 0 ) {
                CCString * f = CCString::createWithFormat("%s.fnt", name->getCString());
                label->setFntFile(f->getCString()); 
            }
        }
    }
}

void NEAnimNode::unloadCurrentAnimation()
{
    if (m_currentAnimData) {
        NEAnimManager * manager = NEAnimManager::sharedManager();
        for (int i=0; i<m_currentAnimData->m_usedTextureFiles->count(); i++) {
            CCString * texFile = (CCString *)m_currentAnimData->m_usedTextureFiles->objectAtIndex(i);
            if (strcmp(texFile->getCString(), "") == 0) {
                continue;
            }
            manager->unusedSpriteframesFromFile(texFile);
        }
        m_currentAnimData = NULL;
    }
}
    
void NEAnimNode::xidChange(int xid, int linkxid)
{
    m_xidLinks[xid] = linkxid;
}
    
int NEAnimNode::getXidLink(int xid)
{
    if (m_xidLinks.find(xid) != m_xidLinks.end()) {
        return m_xidLinks[xid];
    }
    return -1;
}
    
void NEAnimNode::setCallback(const char *callback, cocos2d::CCCallFunc *callfunc)
{
    m_callbacks->setObject(callfunc, callback);
}
    
void NEAnimNode::releaseControl(const char *nodeName, NEPropertyType propType)
{
    std::map<std::string, int>::iterator it = m_indexMap.find(std::string(nodeName));
    if (it != m_indexMap.end()) {
        int nodeID = it->second;
        std::set<int> & types = m_releaseControlNodes[nodeID];
        if (types.find(propType) == types.end()) {
            types.insert(propType);
        }
    }
}
    
void NEAnimNode::ownControl(const char *nodeName, NEPropertyType propType)
{
    std::map<std::string, int>::iterator it = m_indexMap.find(std::string(nodeName));
    if (it != m_indexMap.end()) {
        int nodeID = it->second;
        if (m_releaseControlNodes.find(nodeID) == m_releaseControlNodes.end()) {
            return;
        }
        std::set<int> & types = m_releaseControlNodes[nodeID];
        if (types.find(propType) != types.end()) {
            types.erase(propType);
        }
    }
}
    
float NEAnimNode::getPlayingTime(const char * animName)
{
    NEAnimData * data = NULL;
    float fps = m_customFPS;
    if (animName == NULL) {
        //find current animation
        data = m_currentAnimData;
    }
    else {
        data = m_sharedData->getAnimData(animName);
        fps = data->m_fps;
    }
    
    if (data) {
        int totalFrames = data->m_length;
        float time = totalFrames / fps;
        return time;
    }
    else
        return 0.f;
}
    
void NEAnimNode::setPlayingTime(float time)
{
    if (time <= 0.f || !m_currentAnimData) {
        //do nothing
    }
    else {
        int totalFrames = m_currentAnimData->m_length;
        m_customFPS = totalFrames / time;
    }
}
    
bool NEAnimNode::isCurrentAnimationLoop()
{
    if (m_currentAnimData) {
        return m_currentAnimData->m_loop;
    }
    return false;
}
    
void NEAnimNode::useSkin(const char *skinName)
{
    if (m_sharedData) {
        if (m_sharedData->isSkinExist(skinName)) {
            m_currentSkinName = skinName;
            if (m_currentAnimData) {
                setCurrentFrameIndex(m_currentFrameIndex);
            }
            return;
        }
    }
    m_currentSkinName = std::string("");
}

const char * NEAnimNode::getCurrentSkinName()
{
    return m_currentSkinName.c_str();
}

NEFrame * NEAnimNode::getVariableKeyframe(const char *skinName, const char *varName)
{
    if (!skinName || !m_sharedData) {
        return NULL;
    }
    std::string key = std::string(skinName);
    int vid = m_sharedData->getVariableID(varName);
    if ((m_customFrames.find(key) != m_customFrames.end()) && (m_customFrames[key].find(vid) != m_customFrames[key].end())) {
        return m_customFrames[key][vid];
    }
    
    if (m_sharedData->isSkinExist(skinName) && m_sharedData->isVariableExist(varName)) {
        NEFrame * orif = m_sharedData->getVariableFrame(skinName, vid);
        NEFrame * f = new NEFrame;
        if (orif) {
            f->fill(orif);
        }
        m_customFrames[key][vid] = f;
        return f;
    }
    return NULL;
}

void NEAnimNode::removeVariableKeyframe(const char *skinName, const char *varName)
{
    std::string key = std::string(skinName);
    if (m_customFrames.find(key) != m_customFrames.end()) {
        std::map<int, NEFrame *> &frames = m_customFrames[key];
        int vid = m_sharedData->getVariableID(varName);
        if (frames.find(vid) != frames.end()) {
            frames.erase(vid);
        }
    }
}
    
NEFrame * NEAnimNode::getVariableKeyframe(int vid)
{
    if (m_currentSkinName.compare("") == 0) {
        return NULL;
    }

    if (m_customFrames.find(m_currentSkinName) != m_customFrames.end()) {
        std::map<int, NEFrame *> &frames = m_customFrames[m_currentSkinName];
        if (frames.find(vid) != frames.end()) {
            return frames[vid];
        }
    }
    return NULL;
}
    
bool NEAnimNode::isPropertyInControl(int nodeID, NEPropertyType type)
{
    std::set<int> * releaseTypes = NULL;
    if (m_releaseControlNodes.find(nodeID) != m_releaseControlNodes.end()) {
        releaseTypes = &(m_releaseControlNodes[nodeID]);
    }
    if (releaseTypes) {
        if (releaseTypes->find(kProperty_All) != releaseTypes->end()) {
            //skip all properties
            return false;
        }
        if (releaseTypes->find(type) != releaseTypes->end()) {
            //skip this property
            return false;
        }
    }
    return true;
}
///////////////////////
// NEEaseInterpolate //
///////////////////////

float NEEaseInterpolate::getValue(NEEaseType type, NEEaseClass c, float t)
{
    switch (type) {
        case kEase_NoChange:
            return 0;
        case kEase_Linear:
            return t;
        case kEase_SlowFast:
            return NEEaseInterpolate::getSlowFast(c, t);
        case kEase_FastSlow:
            return NEEaseInterpolate::getFastSlow(c,t);
        default:
            break;
    }
    return 0;
}

float NEEaseInterpolate::getSlowFast(NEEaseClass c, float t)
{
    switch (c) {
        case kEase_Sine:
            return sinf(t * (float)M_PI_2);
        case kEase_Expo:
            return t == 1 ? 1 : (-powf(2, -10 * t / 1) + 1);
        case kEase_Quad:
            return powf(t, 1/2.f);
        case kEase_Cubic:
            return powf(t, 1/3.f);
        case kEase_Quart:
            return powf(t, 1/4.f);
        case kEase_Quint:
            return powf(t, 1/5.f);
        case kEase_Circle:
            return sqrt(1 - (t-1)* (t-1));
        default:
            return 0;
    }
}

float NEEaseInterpolate::getFastSlow(NEEaseClass c, float t)
{
    switch (c) {
        case kEase_Sine:
            return -1 * cosf(t * (float)M_PI_2) + 1;
        case kEase_Expo:
            return t == 0.f ? 0.f : powf(2, 10 * (t/1 - 1)) - 1 * 0.001f;
        case kEase_Quad:
            return powf(t, 2);
        case kEase_Cubic:
            return powf(t, 3);
        case kEase_Quart:
            return powf(t, 4);
        case kEase_Quint:
            return powf(t, 5);
        case kEase_Circle:
            return -1 * (sqrt(1 - t* t) -1);

        default:
            return 0;
    }
}
    
#pragma mark - CCActions
NEAnimationDoneAction::NEAnimationDoneAction() :
    m_animNode(NULL),
    m_animName(""),
    m_animStart(false)
{
}
    
NEAnimationDoneAction * NEAnimationDoneAction::create(neanim::NEAnimNode *animNode, const char *animName, float duration)
{
    NEAnimationDoneAction * action = new NEAnimationDoneAction;
    if (action->initWithAnimation(animNode, animName, duration)) {
        action->autorelease();
        return action;
    }
    else {
        delete action;
        return NULL;
    }
}

bool NEAnimationDoneAction::initWithAnimation(neanim::NEAnimNode *animNode, const char *animName, float duration)
{
    //find duration
    if (!animNode) {
        return false;
    }
    m_animNode = animNode;
    
    if (!m_animNode->sharedData()->hasAnimationNamed(animName)) {
        return false;
    }
    m_animName = std::string(animName);
    
    float animLength = m_animNode->getPlayingTime(animName);
    if (duration == -1.f) {
        duration = animLength;
    }
    
    if (CCActionInterval::initWithDuration(duration))
    {
        return true;
    }
    
    return false;
}

void NEAnimationDoneAction::update(float time)
{
    if (!m_animStart) {
        m_animStart = true;
        m_animNode->playAnimation(m_animName.c_str());
        if (!m_animNode->isCurrentAnimationLoop()) {
            m_animNode->setPlayingTime(this->m_fDuration);
        }
    }
}
    
    
    
    
NEAnimationPlaybackAction::NEAnimationPlaybackAction(float duration, const char * animName, bool pause, int startindex, bool isContinue)
{
    initWithDuration(duration);
    m_animName = std::string(animName);
    m_isPaused = pause;
    m_startIndex = startindex;
    m_isContinue = isContinue;
}
    
NEAnimationPlaybackAction * NEAnimationPlaybackAction::create(float duration, const char *animName, bool pause, int startindex, bool isContinue)
{
    NEAnimationPlaybackAction * action = new NEAnimationPlaybackAction(duration, animName, pause, startindex, isContinue);
    action->autorelease();
    return action;
}

void NEAnimationPlaybackAction::startWithTarget(cocos2d::CCNode *pTarget)
{
    CCFiniteTimeAction::startWithTarget(pTarget);
    NEAnimNode * anim = (NEAnimNode *)pTarget;
    anim->playAnimation(m_animName.c_str(), m_startIndex, m_isPaused, m_isContinue);
    m_elapsed = 0.0f;
    m_bFirstTick = true;
}
    
}

void NEAnimNodeLoader::onHandlePropTypeInteger(cocos2d::CCNode *pNode, cocos2d::CCNode *pParent, const char *pPropertyName, int pInteger, cocos2d::extension::CCBReader *pCCBReader)
{
    CCNodeLoader::onHandlePropTypeInteger(pNode, pParent, pPropertyName, pInteger, pCCBReader);
}

void NEAnimNodeLoader::onHandlePropTypeString(cocos2d::CCNode *pNode, cocos2d::CCNode *pParent, const char *pPropertyName, const char *pString, cocos2d::extension::CCBReader *pCCBReader)
{ 
    if(strcmp(pPropertyName, "file") == 0) {
        ((neanim::NEAnimNode *)pNode)->changeFile(pString);
    }
    else if (strcmp(pPropertyName, "anim") == 0) {
        ((neanim::NEAnimNode *)pNode)->playAnimation(pString);
    }
    else if (strcmp(pPropertyName, "skin") == 0) {
        ((neanim::NEAnimNode *)pNode)->useSkin(pString);
    }
}


void NEAnimNodeLoader::onHandlePropTypeColor3(CCNode * pNode, CCNode * pParent, const char* pPropertyName, ccColor3B pCCColor3B, CCBReader * pCCBReader) {
}
void NEAnimNodeLoader::onHandlePropTypeByte(CCNode * pNode, CCNode * pParent, const char * pPropertyName, unsigned char pByte, CCBReader * pCCBReader) {
}

void NEAnimNodeLoader::onHandlePropTypeBlendFunc(CCNode * pNode, CCNode * pParent, const char * pPropertyName, ccBlendFunc pCCBlendFunc, CCBReader * pCCBReader) {
}
void NEAnimNodeLoader::onHandlePropTypeSize(CCNode * pNode, CCNode * pParent, const char* pPropertyName, CCSize pSize, CCBReader * pCCBReader) {
}