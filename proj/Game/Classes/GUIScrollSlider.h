//
//  GUIScrollSlider.h
//  TapCar
//
//  Created by James Lee on 12-3-7.
//  Copyright (c) 2012年 topgame.com. All rights reserved.
//

#ifndef __FarmMania__GUIScrollSlider__
#define __FarmMania__GUIScrollSlider__

#include "cocos2d.h"

using namespace cocos2d;
 

//  
//@class GUIScrollSlider;
//@protocol GUIScrollSliderDelegate <NSObject>
//@required
////create uniform items for the slider
//- (CCNode *) createItemForSlider:(GUIScrollSlider *) slider; 
////rows count
//- (int) itemsCountForSlider:(GUIScrollSlider *)slider;
////modify all items in this function
//- (void) slider:(GUIScrollSlider *)slider willShowRow:(int) rowIndex item:(CCNode *)node; 
//@optional
////item click callback
//- (void) slider:(GUIScrollSlider *)slider clickItem:(int) rowIndex item:(CCNode *)node;
////enter page callback
//- (void) slider:(GUIScrollSlider *)slider enterPage:(int) rowIndex item:(CCNode *)node;
////leave page callback
//- (void) slider:(GUIScrollSlider *)slider leavePage:(int) rowIndex item:(CCNode *)node;
//
//@end

struct CCRange {
    int location;
    int length;
    CCRange() {
        location = -1;
        length = 0;
    }
    
    CCRange(int i, int l) {
        location = i;
        length = l;
    }
    
    int maxRange() {
        return location + length;
    }
    
    bool locationInRange(int loc) {
        return loc >= location && loc - location < length;
    }
};

class GUIScrollSliderDelegate;
class GUIScrollSlider : public CCLayer {
public:
    GUIScrollSlider();
    ~GUIScrollSlider();
    
    GUIScrollSlider(CCSize contentSize, CCRect viewFrame, float itemHeight, GUIScrollSliderDelegate * delegate, bool vertical, int tag = -1);
private:
    GUIScrollSliderDelegate *   m_delegate;
    CCNode *                    m_mainNode;     //content size, anchor 0.5, 1, children items
    CCNode *                    m_nodeParent;
    CCNode *                    m_offsetNode;
    CCNode *                    m_standbyNode;
    
    int                         m_needItemsCount;
    int                         m_cachedItemsCount;
    CCSize                      m_size;
    CCRect                      m_viewFrame;
    float                       m_minHeight;
    float                       m_maxHeight;
    float                       m_sizeHeight;
    float                       m_cullingHeight;
    
    CCDictionary *              m_showPool;
    CCRange                     m_showRange;
    
    CCPoint                     m_touchBeginPoint;
    CCPoint                     m_touchPointLastFrame;
    bool                        m_fingerMoved;
    
    bool                        m_isVertical;
    bool                        m_isPageEnable;
    bool                        m_isEnabled;
    bool                        m_isBouncing;
    bool                        m_isReverted;
    bool                        m_flagMultitouch;
    
    //scrolling FROM Yangjie's code
    CCPoint                     m_scrollStartVector;
    CCPoint                     m_scrollLastVector;
    float                       m_scrollInertia; 
    bool                        m_enableBounce;
    bool                        m_enableSlider;
    int                         m_pageIndex;
    
    cc_timeval                  m_startMoveInterval;
    float                       m_itemHeight;
    bool                        m_crossBorderEnable;
public:
    void setEnabled(bool enabled) { m_isEnabled = enabled; }
    bool isEnabled() { return m_isEnabled; }
    int getPageIndex() { return m_pageIndex; }
    void setPageIndex(int index);
    void scrollToRow(int index);
    CCActionInterval * scrollToRowAction(int index);
    bool isScrolling() { return m_scrollInertia != 0.f; }
    void setCrossBorderEnable(bool flag = true) {m_crossBorderEnable = flag;}
private:
    void updateContentHeight();
    void updateOffsetNodePosition();
    void moveOffset(float offset);
    void endMovingAction();
    
public:
    float checkBoundary(float p);
    void setPageMode(bool pageMode);
    void setRevertDirection(bool revert);
    CCRange getShowRange(float p);
    void updateShowRange(float position);
    int getItemIndex(CCPoint p);
    void cleanShowPool();
    void takeOutRow(int index);
    void takeInRow(int index);
    void validateVisibleArea(float pos);
    void updateBody(float delta);
    void stopActions();
    void moveSliders();
    int pageIndex(); 
    void leavePage(int pageIndex);
    void enterPage(int pageIndex);
    CCPoint getRowPosition(int rowIndex);
    CCNode * getItemForRow(int rowIndex);
    int getItemsCount();
    CCPoint getPointFromSingleValue(float f);
    void setMainNodePosition(CCPoint p);
    float getSingleValue(CCPoint p);
    float getSingleValueFromSize(CCSize s);
    void refresh();
    void updateCurrentPosition();
    void scrollTo(CCPoint p, bool check);
    
    cc_timeval getCurrentTime();
    CCNode * getMainNode() { return m_mainNode; }
    CCNode * getOffsetNode() { return m_offsetNode; }
    static GUIScrollSlider * getParentScrollSlider(CCNode * node);
    
    void showItem(int rowIndex);
    void purgeCachedItems();
    void createItems();
    void printShowList();
protected:
    virtual void visit();
    virtual void update(float delta);
    virtual void onEnter();
    virtual void registerWithTouchDispatcher();
    virtual bool ccTouchBegan(CCTouch *pTouch, CCEvent *pEvent);
    virtual void ccTouchMoved(CCTouch *pTouch, CCEvent *pEvent);
    virtual void ccTouchEnded(CCTouch *pTouch, CCEvent *pEvent);
    virtual void ccTouchCancelled(CCTouch *pTouch, CCEvent *pEvent);
};

class GUIScrollSliderDelegate {
    friend class GUIScrollSlider;
protected:
    virtual CCNode * createItemForSlider(GUIScrollSlider * slider) = 0;
    virtual int itemsCountForSlider(GUIScrollSlider * slider) = 0;
    virtual void sliderUpdate(GUIScrollSlider * slider, int rowIndex, CCNode * node){}
    //enter page callback
    virtual void sliderEnterPage(GUIScrollSlider * slider, int rowIndex, CCNode * node) {}
    //leave page callback
    virtual void sliderLeavePage(GUIScrollSlider * slider, int rowIndex, CCNode * node) {}
    virtual void sliderStopInPage(GUIScrollSlider * slider, int rowIndex, CCNode * node) {}
    virtual bool sliderCanScroll(GUIScrollSlider * slider) {return true;}
    virtual void sliderIsScrollingByTouch(GUIScrollSlider * slider) {}
    virtual void sliderTouchEnd() {}
};
#endif
