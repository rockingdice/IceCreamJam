#ifndef NEANIMNODE_H
#define NEANIMNODE_H

//
//  NEAnimNode.h
//  AnimReader
//
//  Created by James Lee on 13-1-8.
//  Copyright (c) 2013年 James Lee. All rights reserved.
//
//  Version 0.5.3.1

#include "cocos2d.h"
#include "cocos-ext.h"
#include <libxml/parser.h>
#include <libxml/tree.h>

using namespace cocos2d;
using namespace cocos2d::extension;

namespace neanim {

typedef enum {
    kNode_Default = 0,
    kNode_Root = 1,
    kNode_Sprite = 2,
    kNode_Label,
    kNode_Particle,
    kNode_NEAnimNode = 5,
    kNode_Sprite9,
    kNode_Max
} NENodeType;

typedef enum {
    kProperty_All = -10,
    kProperty_Null = -1,
    kProperty_Position = 0, //Tween
    kProperty_Scale,
    kProperty_Skew,
    kProperty_Rotation,
    kProperty_Color,

    kProperty_Alpha,
    kProperty_AnchorPoint,  //Instant
    kProperty_Visible,
    kProperty_Texture,
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
    kProperty_FNTFile,
    kProperty_ContentSize,

    kProperty_Insets,
    kProperty_AnimSkin,
    
    kProperty_Num
} NEPropertyType;

typedef enum {
    kEase_NoChange,
    kEase_Linear,
    kEase_SlowFast,
    kEase_FastSlow,
    kEase_Pulse,
    kEase_UpdateEnd,
    kEase_TypeMax
} NEEaseType;

typedef enum {
    kEase_NA,
    kEase_Sine,
    kEase_Quad,
    kEase_Cubic,
    kEase_Quart,
    kEase_Quint,
    kEase_Expo,
    kEase_Circle,
    //kEase_Back,
    //kEase_Elastic,
    //kEase_Bounce,
    kEase_ClassMax
} NEEaseClass;

struct NEAnimDataRef {
    int refCount;
    CCDictionary * data;
};

class NEAnimNode;
class NEAnimData;
class NEAnimFileData;
class NEAnimSoundDelegate;
class NEAnimStringDelegate;

class NEAnimManager
{
private:
    NEAnimManager();
    ~NEAnimManager();
public:
    static NEAnimManager * sharedManager();
    static void destroyManager();
private:

    //map: {key: NSString* value:NSNumber*}
    //NSString*: texture file path
    //NSNumber*: texture reference count
    CCDictionary * m_textureFileRefCount;
    bool m_autoRemoveTexture;

    //map: {key: NSString* value:NEAnimData*}
    //NSString*: animation file name
    //NEAnimData*: animation file shared data, with reference count in it.
    CCDictionary * m_sharedDataRefCount;
    bool m_autoRemoveSharedAnimData;

    CCDictionary * m_textureMap;
    
    NEAnimSoundDelegate * m_soundDelegate;
    NEAnimStringDelegate * m_stringDelegate;
public:
    //user functions
    void preloadTextureForAnimFile(const char * fileName, const char * animationName);
    void setScaleFactor(float scaleFactor);
    float getScaleFactor();
    void setAutoRemoveTexture(bool isAuto);
    void setAutoRemoveSharedAnimData(bool isAuto);
    void cleanMemory();
    void removeUnusedTextures();
    void removeUnusedData();

    NEAnimFileData * getSharedDataForFile(const char * fileName);
    //2013.8.14
    void reloadDataWithFile(const char * fileName);
    
    void useSpriteframesFromFile(CCString * filePath);
    void unusedSpriteframesFromFile(CCString * filePath);
    bool loadSpriteframesFromFile(CCString * filePath);
    
    //sound
    void setSoundDelegate(NEAnimSoundDelegate * delegate);
    void playSound(const char * sound);
    
    //localization
    void setStringDelegate(NEAnimStringDelegate * delegate);
    const char * getLocalizedString(const char * string);
private:
    bool isPlistFile(CCString *filePath);
    CCString * getTextureFileFromPlistFile(CCString * pszPlist);
    CCArray * getFrameNamesFromPlistFile(CCString * pszPlist);
    CCDictionary * getFramesFromPlistFile(CCString * pszPlist, CCTexture2D * pobTexture);

};

//@interface NEAnimManager : NSObject
//{
//    //map: {key: NSString* value:NSNumber*}
//    //NSString*: texture file path
//    //NSNumber*: texture reference count
//    NSMutableDictionary * m_textureFileRefCount;
//    bool m_autoRemoveTexture;

//    //map: {key: NSString* value:NEAnimData*}
//    //NSString*: animation file name
//    //NEAnimData*: animation file shared data, with reference count in it.
//    NSMutableDictionary * m_sharedDataRefCount;
//    bool m_autoRemoveSharedAnimData;

//    NSMutableDictionary * m_textureMap;
//}
//+ (id) manager;
//+ (void) destroy;

////user functions
//- (void) preloadTextureForAnimFile:(NSString*)fileName Animation:(NSString*)animationName;
//- (void) setScaleFactor:(float)scaleFactor;
//- (float) scaleFactor;

////if auto remove is true, unused textures will be removed from cache.
//- (void) setAutoRemoveTexture:(bool)isAuto;
//- (void) setAutoRemoveSharedAnimData:(bool)isAuto;
//- (void) cleanMemory;
//- (void) removeUnusedTextures;
//- (void) removeUnusedData;


//- (NEAnimFileData *) getSharedDataForFile:(NSString *)fileName;
////will add reference to file
//- (void) useSpriteframesFromFile:(NSString *) filePath;
//- (void) unuseSpriteframesFromFile:(NSString *) filePath;
////load file, don't modify the reference
//- (void) loadSpriteframesFromFile:(NSString *) filePath;


////helper:
//- (bool) isPlistFile:(NSString *) filePath;
//- (NSString *) getTextureFileFromPlistFile:(NSString *)pszPlist;

//- (NSArray *) getFrameNamesFromPlistFile:(NSString *) pszPlist;
//- (NSDictionary *) getFramesFromPlistFile:(NSString *) pszPlist texture:(CCTexture2D *)pobTexture;
//@end



typedef struct NEFrame {
    int         index;
    int         ref;
    NEEaseType    easeType;
    NEEaseClass   easeClass;
    float       data[4];
    NEFrame() {
        index = 0;
        ref = -1;
        easeType = kEase_NoChange;
        easeClass = kEase_NA;
        memset(data, 0, sizeof(float) * 4);
    }
    void fill(NEFrame * frame) {
        index = frame->index;
        easeType = frame->easeType;
        easeClass = frame->easeClass;
        for (int i=0; i<4; i++) {
            data[i] = frame->data[i];
        }
    }
    //2013.12.16
    void setDataPosition(CCPoint p) { data[0] = p.x; data[1] = p.y; }
    void setDataBool(bool b) { data[0] = b ? 1 : 0; }
    void setDataIndex(int index) { data[0] = index; }
    void setDataFloat(float * d, int num) {
        int count = MIN(4, num);
        for (int i=0; i<count; i++) {
            data[i] = d[i];
        }
    }
    void setEaseType(NEEaseType t) { easeType = t; }
    void setEaseClass(NEEaseClass c) { easeClass = c; }
} NEFrame;

    
template <class _typeT>
class CCValue : public cocos2d::CCObject
{
public:
    CCValue()
    : cocos2d::CCObject()
    {
        memset(&m_type, 0, sizeof(_typeT));
    }
    
    static CCValue* valueWithValue(const _typeT &value)
    {
        CCValue<_typeT> *newValue = new CCValue<_typeT>;
        if (newValue && newValue->initWithValue(value))
        {
            newValue->autorelease();
            return newValue;
        }
        CC_SAFE_RELEASE_NULL(newValue);
        return NULL;
    }
    
    static CCValue* valueWithValue(const CCValue<_typeT> *rhs)
    {
        return valueWithValue(rhs->getValue());
    }
    
    inline bool initWithValue(const _typeT &value)
    {
        memcpy(&m_type, &value, sizeof(_typeT));
        return true;
    }
    
    inline int compare(const CCValue<_typeT> *rhs)
    {
        return memcmp((void*)&m_type, (void*)&rhs->m_type, sizeof(_typeT));
    }
    
    inline bool isEqualToValue(const CCValue<_typeT> *rhs)
    {
        return compare(rhs) == 0 ? 1 : 0;
    }
    
    inline bool isEqualToValue(const CCValue<_typeT> *rhs, int fpCmp(const _typeT &t1, const _typeT &t2))
    {
        return fpCmp(m_type, rhs->m_type) == 0 ? 1 : 0;
    }
    
    CC_SYNTHESIZE_READONLY(_typeT, m_type, Value);
    
protected:
    ~CCValue()
    {
        
    }
private:
    
};

    
    
class NEAnimData : public CCObject
{
public:
    NEAnimData();
    ~NEAnimData();

    int m_length;
    int m_fps;
    float m_spf;
    bool m_loop;
    std::string m_animName;
    //texture files used in this animation:
    //array: {NSString*}
    //NSString*: texture file name
    CCArray * m_usedTextureFiles;

    //key frames data
    //map:{key:int value:map:{key:int value:array:{NEFrame*}}}
    //int: nodeID
    //int: propertyType
    //NEFrame*: keyframe data
    CCDictionary * m_keyframesData;
    void getFrameData(NEFrame * frameData, int nodeID, int type, int oIndex, float fIndex, bool * arriveAtNew, bool * needUpdate, bool * updateEnd, NEAnimNode * nodeData);
    NEFrame * getFrame(int nodeID, int type, int oIndex);
    static CCValue<NEFrame *> * getDefaultFrame(int type);
    static int getKeyframeIndexFromArray(CCArray * frames, int frameIndex);

    static CCPoint getPoint(NEFrame * frame);
    static CCSize getSize(NEFrame * frame);
    static CCRect getRect(NEFrame * frame);
    static float getFloat(NEFrame * frame);
    static int getInt(NEFrame * frame);
    static bool getBool(NEFrame * frame);
    static ccColor3B getColor(NEFrame * frame);
    static int getKeyframe(CCArray * frames, int first, int last, int index);
    static NEFrame * getRefFrame(NEFrame * frame, NEAnimNode * nodeData);
};

//@interface NEAnimData : NSObject
//{
//@public
//    int m_length;
//    int m_fps;
//    float m_spf;
//    NSString * m_animName;
//    //texture files used in this animation:
//    //array: {NSString*}
//    //NSString*: texture file name
//    NSMutableArray * m_usedTextureFiles;

//    //key frames data
//    //map:{key:int value:map:{key:int value:array:{NEFrame*}}}
//    //int: nodeID
//    //int: propertyType
//    //NEFrame*: keyframe data
//    NSMutableDictionary * m_keyframesData;
//}
//- (bool) getFrameData:(NEFrame *)frameData node:(int)nodeID type:(int)type frameObjectIndex:(int)oIndex frameIndex:(float)fIndex;
//+ (int) getKeyframeIndexFromArray:(NSArray *)frames beforeFrameIndex:(int)frameIndex;
//@end

class NEAnimFileData : public CCObject
{
public:
    NEAnimFileData();
    ~NEAnimFileData();
private:
    //animation file name
    std::string m_fileName;

    //ref count to used instances
    //array: {NEAnimNode*}
//    CCArray * m_refs;
    std::set<NEAnimNode *> m_refs;

    //data for creating node structure
    //array: {array: {int, int, int}}
    //int: create from node id
    //int: create node id
    //int: node type
    CCArray * m_nodeStructData;
//    CCArray * m_nodeOrder;
    
    //set: {int}
    //int: node id
    std::vector<int> m_nodeOrder;

    //textures map, to get CCSpriteFrame instance
    //map: {key:int value:CCSpriteFrame *}
    //int: texture id
    //CCSpriteFrame*: tex instance
    CCDictionary * m_texturesMap;

    //strings cache
    //map: {key: int value: NSString *}
    //int: stringID
    //NSString*: string
    CCDictionary * m_stringsCache;

    //nodes index map
    //map: {key: int value: int}
    //int: stringid
    //int: nodeid
//    CCDictionary * m_nodesIndexMap;

    //animation data
    //map: {key: NSString* value:NEAnimData*}
    //NSString*: animation name
    //NEAnimData*: animation data pointer
    CCDictionary * m_animationDataMap;
    
    //skin keyframes data
    //std::string: skin name
    //int: variable vid
    //NEFrame*: variable keyframe
    std::map<std::string, std::map<int, NEFrame * > > m_skins;
    
    //variable data
    //std::string: variable name
    //int: Frame VID
    std::map<std::string, int> m_variables;

public:
    static NEAnimFileData * createFromFile(const char * fileName);

    std::string getFileName();
    int getRefCount();
    CCArray * getDataNodeStructure();
    std::vector<int> & getNodeOrder(); 
    CCArray * getAnimationNames();
    NEAnimData * getAnimData(const char * animationName);
    CCString * getStringByID(int stringID);
    int getIDByString(const char * animName);
    CCSpriteFrame * getTextureByID(int texID);
    void registAnimNode(NEAnimNode * rootNode);
    void unregistAnimNode(NEAnimNode * rootNode);
    //2013.7.15
    bool hasAnimationNamed(const char * animationName);
    //2013.8.14
    void changeToAnimData(NEAnimFileData * animData);
    //2013.11.29
    bool isSkinExist(const char * skinName);
    bool isVariableExist(const char * varName);
    NEFrame * getVariableFrame(const char * skinName, int vid);
    int getVariableID(const char * varName);
private:
    void initWithFile(const char * fileName);
    void parseXMLContent(xmlDocPtr doc);
};

////use for animation file
//@interface NEAnimFileData : NSObject
//{
//    //animation file name
//    NSString * m_fileName;

//    //ref count to used instances
//    //array: {NEAnimNode*}
//    NSMutableArray * m_refs;

//    //data for creating node structure
//    //array: {array: {int, int, int}}
//    //int: create from node id
//    //int: create node id
//    //int: node type
//    NSMutableArray * m_nodeStructData;
//    NSMutableArray * m_nodeOrder;

//    //textures map, to get CCSpriteFrame instance
//    //map: {key:int value:CCSpriteFrame *}
//    //int: texture id
//    //CCSpriteFrame*: tex instance
//    NSMutableDictionary * m_texturesMap;

//    //strings cache
//    //map: {key: int value: NSString *}
//    //int: stringID
//    //NSString*: string
//    NSMutableDictionary * m_stringsCache;

//    //nodes index map
//    //map: {key: int value: int}
//    //int: stringid
//    //int: nodeid
//    NSMutableDictionary * m_nodesIndexMap;

//    //animation data
//    //map: {key: NSString* value:NEAnimData*}
//    //NSString*: animation name
//    //NEAnimData*: animation data pointer
//    NSMutableDictionary * m_animationDataMap;
//}
////will parse the animation file.
//+ (id) createWithFile:(NSString *) fileName;
//- (id) initWithFile:(NSString *) fileName;

//- (NSString *) fileName;
//- (int) refCount;
//- (NSArray *) getDataNodeStructure;
//- (NSArray *) getNodeOrder;
//- (NSArray *) getAnimationNames;
//- (NEAnimData *) getAnimData:(NSString *)animationName;
//- (NSString *) getStringByID:(int)stringID;
//- (CCSpriteFrame *) getTextureByID:(int)texID;

////node reference, will give the node instance shared data pointer
////when node created or change anim, will regist
//- (void) registAnimNode:(NEAnimNode *)rootNode;

////when node destruct, or use other shared anim data, will unregist.
//- (void) unregistAnimNode:(NEAnimNode *)rootNode;
//@end


class NEAnimCallback
{
public:
    virtual void animationEnded(NEAnimNode * node, const char * animName) = 0;
    virtual void animationCallback(NEAnimNode * node, const char * animName, const char * callback) = 0;
};

//@protocol NEAnimCallback <NSObject>
//- (void) animationEnded:(NSString *)animName;
//- (void) animation:(NSString *) animName callback:(NSString *) callback;
//@end
    
class NEAnimSoundDelegate
{
public:
    virtual void animationWillPlaySound(const char * fileName) = 0;
};
    
class NEAnimStringDelegate
{
public:
    virtual const char * animationGetLocalizedString(const char * string) = 0;
};

class NEAnimNode : public CCSprite
{
    friend class NEAnimData;
public:
    NEAnimNode(void);
    ~NEAnimNode(void);
private:
    /*! variables */
        bool m_isAutoRemove;
        bool m_paused;
        bool m_smoothAnimation; 
        float m_time;
        float m_lastFrameIndex;
        float m_currentFrameIndex;
        NEAnimData * m_currentAnimData;

    
        struct updateData {
            int nodeID;
            int propType;
            int index;
        };
        std::vector<updateData> m_updateArray;
//        CCArray * m_updateArray;
        //the properties of nodes in this array will be updated each frame
        //when a property meets 'End' keyframe, will be removed from this array.
        //array: { map{key: int value:int} }
        //int: nodeID
        //int: propertyType


    /*! data: */

        //shared data reference
        NEAnimFileData * m_sharedData;

        //map: {key:int value:CCNode*}
        //int: nodeID
        //CCNode*: node instance
        std::map<int, CCNode *> m_nodeMap;
    
        //map: {key:CCNode* value:int}
        //CCNode*: node pointer
        //int: node id
        std::map<CCNode *, int> m_nodeIDMap;

        //map: {key:std::string value:int}
        //std::string: name of node
        //int: node id
        std::map<std::string, int> m_indexMap;

        std::map<int, int> m_xidLinks;
        //map: {key:int value:int}
        //int: xid in keyframe data, this will not change
        //int: new xid

        //callback delegate
        NEAnimCallback * m_delegate;
      
        //callback ref
        CCDictionary * m_callbacks;
    
        std::map<int, std::set<int> > m_releaseControlNodes;
    
        //custom fps
        float m_customFPS;
    
        //skins
        std::map<std::string, std::map<int, NEFrame * > > m_customFrames;
        std::string m_currentSkinName;
public:
        static NEAnimNode * create();
        static NEAnimNode * createNodeFromFile(const char * fileName);
        void changeFile(const char * fileName);
        void setSmoothPlaying(bool smooth);
        bool isSmoothPlaying();
        void setDelegate(NEAnimCallback * delegate);
        void playAnimation(const char *animationName, int frameIndex = 0, bool isPaused = false, bool isContinue = false);
        void playAnimationCallback(CCString * animationName);
        bool isPaused();
        void pauseAnimation(bool paused = true);
        void resumeAnimation();
        void stopAnimation();
        bool isPlayingAnimation(const char * animationName = NULL);

        //2013.5.3
        void xidChange(int xid, int linkxid);
    
        //2013.5.12
        CCNode * getNodeByName(const char * nodeName);
        void replaceNode(const char * nodeName, CCNode * node);
        //2013.7.6
        void removeNodeRecursively(CCNode * node); 
    
        //2013.5.14
        void setAutoRemove(bool autoRemove) { m_isAutoRemove = autoRemove; }
    
        //2013.6.18
        void setCallback(const char * callback , CCCallFunc * callfunc);
    
        //2013.7.15
        NEAnimFileData * sharedData() { return m_sharedData; }
    
        //2013.7.17
        void ownControl(const char * nodeName, NEPropertyType propType = kProperty_All);
        void releaseControl(const char * nodeName, NEPropertyType propType = kProperty_All);
    
        //2013.8.14
        void replaceWithAnimData(NEAnimFileData * sharedData);
    
        //2013.9.4
        int getXidLink(int xid);
    
        //2013.10.31
        float getPlayingTime(const char * animName = NULL);
        void setPlayingTime(float time);
    
        //2013.11.24
        bool isCurrentAnimationLoop();
    
        //2013.11.29
        void useSkin(const char * skinName);
        const char * getCurrentSkinName();
        NEFrame * getVariableKeyframe(const char * skinName, const char * varName);
        void removeVariableKeyframe(const char * skinName, const char * varName);
    
        //2014.1.7
        bool isPropertyInControl(int nodeID, NEPropertyType type);
private:
        NEFrame * getVariableKeyframe(int vid);
private:
        void setCurrentFrameIndex(int frameIndex);
        void setNodeProperty(NEFrame * frameData, NEPropertyType type, CCNode * node);
        void createNodeStructure();
        void destroyNodeStructure();
        void loadFileData();
        CCNode * getNodeByNodeID(int nodeID);
        int getNodeIDByNode(CCNode * node);

        void useAnimFile(const char * fileName);
        void loadAnimation(const char * animationName);
        void unloadCurrentAnimation();
protected:
        virtual void update(float delta);
        virtual void onEnter();
        virtual void onExit();
public:
//    virtual void retain();
//    virtual void release();
    
    virtual void draw() { CCSprite::draw(); };
};
    
class NEAnimationAction : public CCActionInstant
{
private:
    std::string m_animName;
public:
    NEAnimationAction(const char * animName) {m_animName = std::string(animName);}
    virtual void update(float time) { NEAnimNode * node = (NEAnimNode *)m_pTarget; node->playAnimation(m_animName.c_str()); }
    static NEAnimationAction * create(const char * animName) { NEAnimationAction * action = new NEAnimationAction(animName);
        action->autorelease();
        return action;}
};
    
class NEAnimationDoneAction : public CCActionInterval
{
private:
    NEAnimNode * m_animNode;
    std::string m_animName;
    bool m_animStart;
    NEAnimationDoneAction();
public:

    bool initWithAnimation(NEAnimNode * animNode, const char * animName, float duration = -1.f);
    static NEAnimationDoneAction * create(NEAnimNode * animNode, const char * animName, float duration = -1.f);
    virtual void update(float time);
};
    
class NEAnimationPlaybackAction : public CCActionInterval
{
private:
    std::string m_animName;
    bool m_isPaused;
    int m_startIndex;
    bool m_isContinue;
public:
    NEAnimationPlaybackAction(float duration, const char * animName, bool pause = false, int startindex = 0, bool isContinue = true);
    static NEAnimationPlaybackAction * create(float duration, const char * animName, bool pause = false, int startindex = 0, bool isContinue = true);
public: 
    virtual void startWithTarget(CCNode *pTarget);
};

class NEEaseInterpolate
{
public:
    static float getValue(NEEaseType type, NEEaseClass c, float t);
    static float getSlowFast(NEEaseClass c, float t);
    static float getFastSlow(NEEaseClass c, float t);
};

}


class NEAnimNodeLoader : public CCNodeLoader
{
public:
    CCB_STATIC_NEW_AUTORELEASE_OBJECT_METHOD(NEAnimNodeLoader, loader);
    
    CCB_VIRTUAL_NEW_AUTORELEASE_CREATECCNODE_METHOD(neanim::NEAnimNode);
    
protected:
    virtual void onHandlePropTypeString(CCNode * pNode, CCNode * pParent, const char * pPropertyName, const char * pString, CCBReader * pCCBReader);
    virtual void onHandlePropTypeInteger(CCNode * pNode, CCNode * pParent, const char* pPropertyName, int pInteger, CCBReader * pCCBReader);
    virtual void onHandlePropTypeColor3(CCNode * pNode, CCNode * pParent, const char* pPropertyName, ccColor3B pCCColor3B, CCBReader * pCCBReader);
    virtual void onHandlePropTypeByte(CCNode * pNode, CCNode * pParent, const char * pPropertyName, unsigned char pByte, CCBReader * pCCBReader);
    virtual void onHandlePropTypeBlendFunc(CCNode * pNode, CCNode * pParent, const char * pPropertyName, ccBlendFunc pCCBlendFunc, CCBReader * pCCBReader);
    virtual void onHandlePropTypeSize(CCNode * pNode, CCNode * pParent, const char* pPropertyName, CCSize pSize, CCBReader * pCCBReader);
};

#endif // NEANIMNODE_H
