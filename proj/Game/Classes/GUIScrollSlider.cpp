//
//  GUIScrollSlider.m
//  TapCar
//
//  Created by James Lee on 12-3-7.
//  Copyright (c) 2012年 topgame.com. All rights reserved.
//

#include "GUIScrollSlider.h"

typedef enum {
    kBoundIn,
    kBoundTop,
    kBoundBottom,
    kBoundLeft,
    kBoundRight,
} kBoundDirection;

GUIScrollSlider::GUIScrollSlider()
{
    
}

GUIScrollSlider::~GUIScrollSlider()
{
    m_showPool->release();
    m_showPool = NULL;
}

GUIScrollSlider::GUIScrollSlider(CCSize contentSize, CCRect viewFrame, float itemHeight, GUIScrollSliderDelegate * delegate, bool vertical, int tag) :
    m_isPageEnable(false),
    m_enableBounce(true),
    m_isBouncing(false),
    m_isEnabled(true),
    m_flagMultitouch(false),
    m_fingerMoved(false),
    m_isReverted(false),
    m_isVertical(vertical),
    m_scrollInertia(0.f),
    m_crossBorderEnable(true)
{
    setTag(tag);
    m_delegate = delegate;
    m_scrollInertia = 0.f;
    
    m_size = contentSize;
    m_viewFrame = viewFrame;
    
    setContentSize(contentSize);
    m_itemHeight = itemHeight;
    m_sizeHeight = fabsf(getSingleValueFromSize(contentSize));
    m_cullingHeight = fabsf(getSingleValueFromSize(viewFrame.size));
    m_needItemsCount =  ceil(m_cullingHeight / (float)m_itemHeight) + 2;
    CCNode * holder = CCNode::create();
    holder->setPosition(CCPointZero);
    
    m_offsetNode = CCNode::create();
    m_offsetNode->setPosition(getPointFromSingleValue(m_sizeHeight* 0.5f));
    
    m_mainNode = CCNode::create();
    m_mainNode->setAnchorPoint(ccp(0.5f, 0.5f));
    m_mainNode->setPosition(CCPointZero);
    
    
    holder->addChild(m_offsetNode);
    m_offsetNode->addChild(m_mainNode);
    addChild(holder, 0 , 9913);
    
    m_nodeParent = CCNode::create();
    m_mainNode->addChild(m_nodeParent);
    
    m_standbyNode = CCNode::create();
//    m_standbyNode->retain();
    addChild(m_standbyNode);
    m_standbyNode->setVisible(false);
    m_standbyNode->setPosition(ccp(1000000.f, 1000000.f));
//    m_standbyNode->setPosition(ccp(1000000.f, 1000000.f));
    
    //create items
    for (int i=0; i<m_needItemsCount; i++) {
        CCNode * item = m_delegate->createItemForSlider(this);
        m_standbyNode->addChild(item);
    }
    
    m_showPool = CCDictionary::create();
    m_showPool->retain();
    m_showRange = CCRange(0, 0);
    
//    setTouchEnabled(true);
//    setTouchMode(kCCTouchesOneByOne);
//    setTouchPriority(kCCMenuHandlerPriority-1);
    setTouchEnabled(true);
}

void GUIScrollSlider::updateContentHeight()
{
    if (m_isPageEnable) {
        m_maxHeight = (m_cachedItemsCount - 1) * m_itemHeight;
        m_minHeight = 0.f;
    }
    else {
        float length = m_cachedItemsCount * m_itemHeight - m_sizeHeight; 
        m_minHeight = 0.f;
        m_maxHeight = length;
    }
}

void GUIScrollSlider::updateOffsetNodePosition()
{
    float f = m_isPageEnable ? m_itemHeight * 0.5f : m_sizeHeight * 0.5f;
    m_offsetNode->setPosition(getPointFromSingleValue(f));
}

void GUIScrollSlider::setRevertDirection(bool revert)
{
    m_isReverted = revert;
    updateContentHeight();
    updateOffsetNodePosition();
}

void GUIScrollSlider::setPageMode(bool pageMode)
{
    m_isPageEnable = pageMode;
    updateOffsetNodePosition();
    updateContentHeight();
}

CCRange GUIScrollSlider::getShowRange(float p)
{
    if (m_isPageEnable) {
        p = p - m_sizeHeight * 0.5f + m_itemHeight * 0.5f;
    }
    float diff = (m_cullingHeight - m_sizeHeight) * 0.5f;
    int startRow = ( p - diff ) / m_itemHeight;
    float offsetFromStartRow =  p - startRow * m_itemHeight;
    int endRow = startRow + (m_sizeHeight + diff * 2.f + offsetFromStartRow) / (float) m_itemHeight;
    if (startRow < 0) {
        startRow = 0;
    }
    int itemCount = getItemsCount();
    if (endRow >= itemCount) {
        endRow = itemCount -1;
    }
    int length = endRow - startRow + 1;
    if (length < 0) {
        length = 0;
    }
    return CCRange(startRow, length);
}

int GUIScrollSlider::getItemIndex(cocos2d::CCPoint p)
{
    float pos = getSingleValue(p);
    return floor(-pos / m_itemHeight);
}

void GUIScrollSlider::validateVisibleArea(float pos)
{
    cleanShowPool();
    m_showRange = getShowRange(pos);
    for (int i=m_showRange.location; i<m_showRange.maxRange(); i++) {
        takeInRow(i);
    }
    if (m_isPageEnable) {
        int currentPage = floor(getSingleValue(m_mainNode->getPosition()) / m_itemHeight + 0.5f);
        CCArray * pageIndices = m_showPool->allKeys();
        for (int i=0; i<pageIndices->count(); i++) {
            CCInteger * num = (CCInteger *)pageIndices->objectAtIndex(i);
            int index = num->getValue();
            if (index == currentPage) {
                enterPage(index);
            }
            else {
                leavePage(index);
            }
        }
    }

}


float GUIScrollSlider::checkBoundary(float p)
{
    if (p < m_minHeight) {
        p = m_minHeight;
    }
    else if (p > m_maxHeight) {
        p = m_maxHeight;
    }
    return p;
}

void GUIScrollSlider::moveOffset(float offset)
{
    //base on moved distance, calculate which rows disappeared, which rows entered
    float newPos = getSingleValue(m_mainNode->getPosition()) + offset;
    if (!m_crossBorderEnable) {
        newPos = checkBoundary(newPos);
    }
    m_mainNode->setPosition(getPointFromSingleValue(newPos));
    updateShowRange(getSingleValue(m_mainNode->getPosition()));
}

void GUIScrollSlider::updateShowRange(float position)
{
//    CCLog("update show range, %f", position);
    if (m_isPageEnable) {
        int pageIndex = floor(position / m_itemHeight + 0.5f);
        if (pageIndex != m_pageIndex) {
            leavePage(m_pageIndex);
            m_pageIndex = pageIndex;
            enterPage(m_pageIndex);
        }
    }
    
    CCRange newRange = getShowRange(position);

    for (int i=m_showRange.location; i<m_showRange.maxRange(); i++) {
        if (!newRange.locationInRange(i)) {
            takeOutRow(i);
        }
    }
    
    for (int i=newRange.location; i<newRange.maxRange(); i++) { 
        if (!m_showRange.locationInRange(i)) {
            takeInRow(i);
        }
    }
    m_showRange = newRange;

}

void GUIScrollSlider::cleanShowPool()
{
    CCArray * deleted = CCArray::create();
    for (int i=0; i<m_nodeParent->getChildrenCount(); i++) {
        CCNode * node = (CCNode *)m_nodeParent->getChildren()->objectAtIndex(i);
        deleted->addObject(node);
    }
    for (int i=0; i<deleted->count(); i++) {
        CCNode * item = (CCNode *)deleted->objectAtIndex(i);
        m_nodeParent->removeChild(item, false);
        m_standbyNode->addChild(item);
    }
    m_showPool->removeAllObjects();
}

void GUIScrollSlider::takeOutRow(int index)
{
    CCNode * item = (CCNode *)m_showPool->objectForKey(index);
    if (item) {
        //take out
        item->retain();
        item->removeFromParentAndCleanup(false);
        m_standbyNode->addChild(item);
        item->release();
        
        m_showPool->removeObjectForKey(index);
    } 

}

void GUIScrollSlider::takeInRow(int index)
{
    CCNode * item = (CCNode *)m_showPool->objectForKey(index); 
    if (!item) {
        //take in
        //take a standby row 
        CCNode * idleItem = (CCNode *)m_standbyNode->getChildren()->objectAtIndex(0);
        idleItem->retain();
        idleItem->removeFromParentAndCleanup(false);
        idleItem->setPosition(getPointFromSingleValue(-m_itemHeight * (0.5f + index)));
        
        //put it into show pool
        m_nodeParent->addChild(idleItem);
//        CCLog("take in row %x, %d", idleItem,index);

        m_delegate->sliderUpdate(this, index, idleItem);
        
        m_nodeParent->reorderChild(idleItem, idleItem->getZOrder());
        
        idleItem->release();
        
        //update show pool range
        m_showPool->setObject(idleItem, index);
    }
}

void GUIScrollSlider::onEnter()
{
    CCLayer::onEnter();
    getItemsCount();
    updateContentHeight();
    validateVisibleArea(getSingleValue(m_mainNode->getPosition()));
}
extern float deviceScaleFactor;
void GUIScrollSlider::visit()
{
	glEnable(GL_SCISSOR_TEST);
    float scale = getScale();
    float f = CC_CONTENT_SCALE_FACTOR() / deviceScaleFactor;
    CCRect frame = CCRectMake(m_viewFrame.origin.x * f * scale,
                              m_viewFrame.origin.y * f * scale,
                              m_viewFrame.size.width * f * scale,
                              m_viewFrame.size.height * f * scale) ;
	CCPoint pos = getParent()->convertToWorldSpace(getPosition());	//get world point to set the culling
    pos = ccp(pos.x * f, pos.y * f);
	frame.origin = ccpAdd(pos, frame.origin);
	glScissor(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);
    CCNode::visit();
	glDisable(GL_SCISSOR_TEST);
}

void GUIScrollSlider::registerWithTouchDispatcher()
{ 
    CCTouchDispatcher* pDispatcher = CCDirector::sharedDirector()->getTouchDispatcher();
    pDispatcher->addTargetedDelegate(this, getTouchPriority()-1, false);
}

void GUIScrollSlider::scrollTo(cocos2d::CCPoint p, bool check)
{
    if (check) {
        float f = getSingleValue(p);
        f = checkBoundary(f);
        p = getPointFromSingleValue(f);
    }
    m_isBouncing  = true;
    CCMoveTo * move = CCMoveTo::create(0.5f, p);
    CCEaseExponentialOut * ease = CCEaseExponentialOut::create(move);
    CCCallFunc * end = CCCallFunc::create(this, callfunc_selector(GUIScrollSlider::endMovingAction));
    CCSequence * seq = CCSequence::create(ease, end, NULL); 
    seq->setTag(94);
    m_mainNode->runAction(seq);
}
void GUIScrollSlider::setMainNodePosition(CCPoint p)
{
    m_mainNode->setPosition(p);
}

void GUIScrollSlider::update(float delta)
{
	//移动惯性设置
	if (m_enableBounce) {
        if (m_isBouncing) {
            float currentPos = getSingleValue(m_mainNode->getPosition());
            updateShowRange(currentPos);
            return;
        }
         
        //根据方向判断如果当body位置小于某些值的时候停止自主移动
        float currentPos = getSingleValue(m_mainNode->getPosition());
        if (currentPos > m_maxHeight || currentPos < m_minHeight) {
            m_scrollInertia = 0.f;
        }
        //衰减移动矢量
        m_scrollInertia *= 0.9f;
        
        //根据获得的矢量缓速移动
        moveOffset(m_scrollInertia);
        
        float pos = getSingleValue(m_mainNode->getPosition());
        
        if (m_isPageEnable) {
            if (fabsf(m_scrollInertia) < 16.f) {
                m_scrollInertia = 0.f;
                m_pageIndex = floor(pos / m_itemHeight + 0.5f);
                pos = m_pageIndex * m_itemHeight;
                m_isBouncing = true;
            }
        }
        else {
            //保护系统，防止计算出来的数值无限小
            if (fabsf(m_scrollInertia) < 0.1f) {
                m_scrollInertia = 0.f;
            }
        }
        
        //如果自主移动已经结束，那么判断是否执行归位的action
		if (m_scrollInertia == 0) {
            stopActions();
            bool overLap = false;
            if (pos >= m_maxHeight) {
                pos = m_maxHeight;
                overLap = true;
            }
            if (pos <= m_minHeight) {
                pos = m_minHeight;
                overLap = true;
            }
            
            if (overLap || m_isBouncing) {
                CCPoint p = getPointFromSingleValue(pos);
                scrollTo(p, false);
            }
            else {
                //stop
                unscheduleUpdate();
            }
             
		} 
	}

}

void GUIScrollSlider::endMovingAction()
{
    unschedule(schedule_selector(GUIScrollSlider::updateCurrentPosition));
    float f = getSingleValue(m_mainNode->getPosition());
    updateShowRange(f);
    
    if (m_isPageEnable) {
        int pageIndex = floor(f / m_itemHeight + 0.5f);
        if (m_delegate) {
            m_delegate->sliderStopInPage(this, pageIndex, (CCNode *)m_showPool->objectForKey(pageIndex));
        }
    }
}

void GUIScrollSlider::stopActions()
{
    m_mainNode->stopAllActions();
}

cc_timeval GUIScrollSlider::getCurrentTime()
{
    struct cc_timeval now;
    CCTime::gettimeofdayCocos2d(&now, NULL);
    return now;
}

#pragma mark - touch
bool GUIScrollSlider::ccTouchBegan(CCTouch *pTouch, CCEvent *pEvent)
{
    if (m_delegate) {
        if (!m_delegate->sliderCanScroll(this)) {
            return false;
        }
    }
    if (!m_isEnabled) {
        return false;
    }
    CCSize csize = getContentSize();
    CCRect box = CCRectMake(-csize.width * 0.5f, -csize.height * 0.5f, csize.width, csize.height);
    
    
    CCPoint p = pTouch->getLocation();
    CCPoint localp = convertToNodeSpace(p);
    bool contains = localp.x > box.origin.x && localp.y > box.origin.y && localp.x < box.origin.x+box.size.width && localp.y < box.origin.y + box.size.height;
    if (contains) {
        if (m_flagMultitouch) {
            return false;
        }
        m_flagMultitouch = true;
        
        unscheduleAllSelectors();
        m_isBouncing = false;
        
        m_touchBeginPoint = p;
        m_touchPointLastFrame = m_touchBeginPoint;
        m_fingerMoved = false;
        CCNode * parent = this;
        
        while (parent != NULL) {
            if (parent->isVisible()) {
                //recursively check parent visible
                parent = parent->getParent();
            }
            else {
                //invisible parent exist, don't touch
                return false;
            }
        }
        
        stopActions();
        
        m_startMoveInterval = getCurrentTime();
        m_scrollInertia = 0.f;
        m_scrollStartVector = m_scrollLastVector = m_touchBeginPoint;
        
        return true;
    }
    
    
    return false;

}

void GUIScrollSlider::ccTouchMoved(CCTouch *pTouch, CCEvent *pEvent)
{
    if (m_delegate) {
        if (!m_delegate->sliderCanScroll(this)) {
            return;
        }
    }

    CCPoint p = pTouch->getLocation();

    if (!m_fingerMoved) {
        m_fingerMoved = true;
        //trigger start move
    }
    
    cc_timeval time = getCurrentTime();
    double mmtime = CCTime::timersubCocos2d(&m_startMoveInterval, &time);
    //    NSLog(@"start time: %f, current time: %f", m_startMoveInterval, tnow);
    if (mmtime > 300.f) {
        m_startMoveInterval = time;
        m_startMoveInterval.tv_usec -= 0.3f * 1000000.f;
        m_scrollLastVector = p;
    }
    float diff = getSingleValue(ccpSub(p, m_touchPointLastFrame));
    if (abs(diff) > 1.f) {
        if (m_delegate) {
            m_delegate->sliderIsScrollingByTouch(this);
        }
    }
    //如果超过边界区域，移动减半
    float pos = getSingleValue(m_mainNode->getPosition());

    if (pos > m_maxHeight || pos < m_minHeight) {
        if (!m_crossBorderEnable) {
            diff = 0;
        }else{
            diff *= 0.4f;
        }
    }
    //设置body当前位置
    moveOffset(diff);
    
    m_touchPointLastFrame = p;
}

void GUIScrollSlider::ccTouchEnded(CCTouch *pTouch, CCEvent *pEvent)
{
    m_flagMultitouch = false;

    if (m_delegate) {
        if (!m_delegate->sliderCanScroll(this)) {
            return;
        }
        m_delegate->sliderTouchEnd();
    }

    CCPoint p = pTouch->getLocation();
    if (!m_fingerMoved) {

    }
    
    CCPoint touchLocation = pTouch->getLocation();
    CCPoint moveLength = ccpSub(touchLocation, m_scrollLastVector);

    //    NSLog(@"%f, %f", moveLength.x, moveLength.y);//
    //如果最后一次手指移开与手指落下时间间隔大于一定时间，那么判断这次操作无效
//    CCLOG("current time: %f, start: %f", getCurrentTime(), m_startMoveInterval);
    cc_timeval currentTime = getCurrentTime();
    double time = CCTime::timersubCocos2d( &m_startMoveInterval, &currentTime);
    if ( time < 300.f) {
        //设置移动矢量，并且乘以一个小于1的系数，让他移动的不这么快
        //            NSLog(@"sinertia : %f", m_scrollInertia);
        m_scrollInertia = m_scrollInertia + getSingleValue(ccpMult(moveLength, 0.3f)); //ccpAdd(m_scrollInertia, ccpMult(moveLength, 0.3f));
//        CCLOG("inertia : %f", m_scrollInertia);
        //总移动距离小于10的时候清空移动矢量并触发点击事件
        if (ccpDistance(touchLocation, m_scrollStartVector) < 10) {
            //这里判断矢量于0之间的距离如果小于上边10点的位移再乘以衰减系数(用来判断是否是在滑动过程中的点击)
            if ( m_scrollInertia <= 10.0f * 0.4f) {
                //如果移动矢量小于一定数值发送点击事件
                CCPoint touchp = m_mainNode->convertToNodeSpace(p);
                int itemIndex = getItemIndex(touchp);
                if (itemIndex < getItemsCount()) {
//                    CCNode * item = (CCNode *)m_showPool->objectForKey(itemIndex);
//                    if (m_delegate respondsToSelector:@selector(slider:clickItem:item:)]) {
//                        [m_delegate slider:self clickItem:itemIndex item:item];
//                    }
                }

            }
            m_scrollInertia = 0.f;
        }
    } else {
        //否则清空移动矢量
        m_scrollInertia = 0.f;
    }
    //NSLog(@"diff desc:%f -- %f", diff.x, diff.y);
    
    //NSLog(@"距离：%f", ccpDistance(touchLocation, m_scrollLastVector));
    if (m_scrollInertia != 0.f) {
        scheduleUpdateWithPriority(-1);
    }
    else {
        update(0.f);
    }
    

}

void GUIScrollSlider::ccTouchCancelled(CCTouch *pTouch, CCEvent *pEvent)
{
    m_flagMultitouch = false;
    if (m_delegate) {
        if (!m_delegate->sliderCanScroll(this)) {
            return;
        }
        m_delegate->sliderTouchEnd();
    }
    
    CCPoint p = pTouch->getLocation();
    if (!m_fingerMoved) {
        
    }
    
    CCPoint touchLocation = pTouch->getLocation();
    CCPoint moveLength = ccpSub(touchLocation, m_scrollLastVector);
    
    //    NSLog(@"%f, %f", moveLength.x, moveLength.y);//
    //如果最后一次手指移开与手指落下时间间隔大于一定时间，那么判断这次操作无效
    //    CCLOG("current time: %f, start: %f", getCurrentTime(), m_startMoveInterval);
    cc_timeval currentTime = getCurrentTime();
    double time = CCTime::timersubCocos2d( &m_startMoveInterval, &currentTime);
    if ( time < 300.f) {
        //设置移动矢量，并且乘以一个小于1的系数，让他移动的不这么快
        //            NSLog(@"sinertia : %f", m_scrollInertia);
        m_scrollInertia = m_scrollInertia + getSingleValue(ccpMult(moveLength, 0.3f)); //ccpAdd(m_scrollInertia, ccpMult(moveLength, 0.3f));
        //        CCLOG("inertia : %f", m_scrollInertia);
        //总移动距离小于10的时候清空移动矢量并触发点击事件
        if (ccpDistance(touchLocation, m_scrollStartVector) < 10) {
            //这里判断矢量于0之间的距离如果小于上边10点的位移再乘以衰减系数(用来判断是否是在滑动过程中的点击)
            if ( m_scrollInertia <= 10.0f * 0.4f) {
                //如果移动矢量小于一定数值发送点击事件
                CCPoint touchp = m_mainNode->convertToNodeSpace(p);
                int itemIndex = getItemIndex(touchp);
                if (itemIndex < getItemsCount()) {
                    //                    CCNode * item = (CCNode *)m_showPool->objectForKey(itemIndex);
                    //                    if (m_delegate respondsToSelector:@selector(slider:clickItem:item:)]) {
                    //                        [m_delegate slider:self clickItem:itemIndex item:item];
                    //                    }
                }
                
            }
            m_scrollInertia = 0.f;
        }
    } else {
        //否则清空移动矢量
        m_scrollInertia = 0.f;
    }
    //NSLog(@"diff desc:%f -- %f", diff.x, diff.y);
    
    //NSLog(@"距离：%f", ccpDistance(touchLocation, m_scrollLastVector));
    if (m_scrollInertia != 0.f) {
        scheduleUpdateWithPriority(-1);
    }
    else {
        update(0.f);
    }
    
    

}

int GUIScrollSlider::getItemsCount()
{
    int count = m_delegate->itemsCountForSlider(this);
    if (count != m_cachedItemsCount) {
        m_cachedItemsCount = count;
        updateContentHeight();
    }
    return m_cachedItemsCount;
}

CCPoint GUIScrollSlider::getPointFromSingleValue(float f)
{
    float v = m_isReverted ? -f : f;
    if (m_isVertical) {
        return ccp(0, v);
    }
    else {
        return ccp(v, 0);
    }
}

float GUIScrollSlider::getSingleValue(cocos2d::CCPoint p)
{
    float f;
    if (m_isVertical) {
        f = p.y;
    }
    else {
        f = p.x;
    }
    return m_isReverted ? -f : f;
}

float GUIScrollSlider::getSingleValueFromSize(cocos2d::CCSize s)
{
    float f;
    if (m_isVertical) {
        f = s.height;
    }
    else {
        f = s.width;
    }
    return m_isReverted ? -f : f;
}

#pragma mark - public funtions

void GUIScrollSlider::setPageIndex(int index)
{
    m_pageIndex = index;
    float pos = m_itemHeight * index;
    m_mainNode->setPosition(getPointFromSingleValue(pos));
    validateVisibleArea(pos);
    
    if (m_isPageEnable) {
        if (m_delegate) {
            m_delegate->sliderStopInPage(this, m_pageIndex, (CCNode *)m_showPool->objectForKey(m_pageIndex));
        }
    }
}

CCPoint GUIScrollSlider::getRowPosition(int rowIndex)
{
    CCPoint pos = getPointFromSingleValue(m_itemHeight * rowIndex);
    return pos;
}

CCNode * GUIScrollSlider::getItemForRow(int rowIndex)
{
//    static CCNode * cachedNode = NULL;
//    if (!cachedNode) {
//        cachedNode = m_delegate->createItemForSlider(this);
//    }
//    CCNode * node = (CCNode *)cachedNode;
//    m_delegate->sliderUpdate(this, rowIndex, node);
//    return node;

    if (m_showPool->count() == 0) {
        float f = getSingleValue(getRowPosition(rowIndex));
        validateVisibleArea(f);
    }
    CCNode * node = (CCNode *)m_showPool->objectForKey(rowIndex);
    return node;
}

void GUIScrollSlider::showItem(int rowIndex)
{
    if (m_showPool->objectForKey(rowIndex)) {
        return;
    }
    float pos = rowIndex * m_itemHeight;
    updateShowRange(pos);
//    m_mainNode->setPosition(p);
}

void GUIScrollSlider::scrollToRow(int index)
{
    float pos = index * m_itemHeight;
    CCPoint p = getPointFromSingleValue(pos);
    CCMoveTo * move = CCMoveTo::create(0.5f, p);
    CCEaseExponentialOut * ease = CCEaseExponentialOut::create(move);
    CCCallFunc * end = CCCallFunc::create(this, callfunc_selector(GUIScrollSlider::endMovingAction));
    CCSequence * seq = CCSequence::create(ease, end, NULL); 
    schedule(schedule_selector(GUIScrollSlider::updateCurrentPosition));
    m_mainNode->stopAllActions();
    m_mainNode->runAction(seq);
}

CCActionInterval * GUIScrollSlider::scrollToRowAction(int index)
{
    float pos = index * m_itemHeight;
    CCPoint p = getPointFromSingleValue(pos);
    CCMoveTo * move = CCMoveTo::create(0.5f, p);
    CCEaseExponentialOut * ease = CCEaseExponentialOut::create(move);
    CCCallFunc * end = CCCallFunc::create(this, callfunc_selector(GUIScrollSlider::endMovingAction));
    CCSequence * seq = CCSequence::create(ease, end, NULL);
    return seq;
}
 
#pragma mark - delgate functions

void GUIScrollSlider::leavePage(int pageIndex)
{
    if (m_delegate) {
        m_delegate->sliderLeavePage(this, pageIndex, (CCNode *)m_showPool->objectForKey(pageIndex));
    }
//    if ([m_delegate respondsToSelector:@selector(slider:leavePage:item:)]) {
//        if (pageIndex < 0) {
//            pageIndex = 0;
//        }
//        if (pageIndex >= m_cachedItemsCount) {
//            pageIndex = m_cachedItemsCount-1;
//        }
//        CCNode * node = [m_showPool objectForKey:[NSNumber numberWithInt:pageIndex]];
//        [m_delegate slider:self leavePage:pageIndex item:node];
//    }
}

void GUIScrollSlider::enterPage(int pageIndex)
{
    if (m_delegate) {
        m_delegate->sliderEnterPage(this, pageIndex, (CCNode *)m_showPool->objectForKey(pageIndex));
    }
//    if ([m_delegate respondsToSelector:@selector(slider:enterPage:item:)]) {
//        if (pageIndex < 0) {
//            pageIndex = 0;
//        }
//        if (pageIndex >= m_cachedItemsCount) {
//            pageIndex = m_cachedItemsCount-1;
//        }
//        CCNode * node = [m_showPool objectForKey:[NSNumber numberWithInt:pageIndex]];
//        [m_delegate slider:self enterPage:pageIndex item:node];
//    }
}

#pragma mark - slider  

void GUIScrollSlider::updateCurrentPosition()
{
    updateShowRange(getSingleValue(m_mainNode->getPosition()));
}

void GUIScrollSlider::refresh()
{
    validateVisibleArea(getSingleValue(m_mainNode->getPosition()));
    update(0.f);
}


GUIScrollSlider * GUIScrollSlider::getParentScrollSlider(cocos2d::CCNode *node)
{
    CCNode * parent = node->getParent();
    while (parent) {
        GUIScrollSlider * slider = dynamic_cast<GUIScrollSlider *>(parent);
        if (slider) {
            return slider;
        }
        parent = parent->getParent();
    }
    return NULL;
}

void GUIScrollSlider::purgeCachedItems()
{
    cleanShowPool();
    m_standbyNode->removeAllChildren();
}

void GUIScrollSlider::createItems()
{
    //create items
    for (int i=0; i<m_needItemsCount; i++) {
        CCNode * item = m_delegate->createItemForSlider(this);
        m_standbyNode->addChild(item);
    }
}

void GUIScrollSlider::printShowList()
{
    CCDictElement * pElement = NULL;
    CCDICT_FOREACH(m_showPool, pElement) {
        int key = pElement->getIntKey();
        CCNode * n = (CCNode *)m_showPool->objectForKey(key);
        CCLog("key: %d, node: %x", key, n);
    }
}