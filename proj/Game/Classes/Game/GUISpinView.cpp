//
//  GUISpinView.cpp
//  JellyMania
//
//  Created by lipeng on 14-4-16.
//
//
static float kMoveTime = 3.3f;
static float kMoveRound = 2;
#include "GUISpinView.h"
GUISpinView::GUISpinView()
{
    
}
GUISpinView::~GUISpinView()
{
    
}

GUISpinView::GUISpinView(CCRect viewFrame, float itemHeight, GUISpinViewDelegate * delegate):
m_delegate(NULL),
m_mainNode(NULL),
m_itemHeight(0),
m_itemCount(0),
m_targetRow(0),
m_currentRow(0)
{
    m_delegate = delegate;
    m_viewFrame = viewFrame;
    m_itemHeight = itemHeight;
    
    m_mainNode = CCNode::create();
    m_mainNode->setAnchorPoint(ccp(0.5f, 0.5f));
    m_mainNode->setPosition(ccpAdd(viewFrame.origin, ccp(viewFrame.size.width/2, viewFrame.size.height/2)));
    addChild(m_mainNode);
    
    m_itemCount = m_delegate->itemsCountForSpinView(this);
    for (int i = 0; i < m_itemCount; i++) {
        CCNode * node = m_delegate->createItemForSpinView(this, i);
        m_mainNode->addChild(node, 0, i);
        node->setAnchorPoint(ccp(0, 0.5f));
        CCPoint p = ccp(0, - m_itemHeight * i);
        if (p.y + m_itemHeight * 0.5f < - m_viewFrame.size.height * 0.5f) {
            p.y = m_itemHeight * (m_itemCount - i);
        }
        node->setPosition(p);
    }
}

extern float deviceScaleFactor;
void GUISpinView::visit()
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

void GUISpinView::update(float delta)
{
    CCArray * array = m_mainNode->getChildren();
    if (array) {
        for (int i = 0; i < array->count(); i++) {
            CCNode * node = (CCNode *)array->objectAtIndex(i);
            CCPoint p = node->getPosition();
            if (p.y + m_itemHeight * 0.5f < - m_viewFrame.size.height * 0.5f) {
                p.y += m_itemCount * m_itemHeight;
                node->setPosition(p);
            }
        }
    }
}
void GUISpinView::refresh()
{
    m_mainNode->removeAllChildren();
    m_itemCount = m_delegate->itemsCountForSpinView(this);
    for (int i = 0; i < m_itemCount; i++) {
        CCNode * node = m_delegate->createItemForSpinView(this, i);
        m_mainNode->addChild(node, 0, i);
        node->setAnchorPoint(ccp(0, 0.5f));
        CCPoint p = ccp(0, - m_itemHeight * i);
        if (p.y + m_itemHeight * 0.5f < - m_viewFrame.size.height * 0.5f) {
            p.y = m_itemHeight * (m_itemCount - i);
        }
        node->setPosition(p);
    }
}
void GUISpinView::scrollTo(int rowIndex)
{
    
    m_targetRow = rowIndex;
    if (m_targetRow >= m_itemCount || m_targetRow < 0) {
        return;
    }
    CCNode * node = m_mainNode->getChildByTag(m_targetRow);
    float h = node->getPosition().y;
    float dis = -h - (kMoveRound * m_itemCount * m_itemHeight);
    int th = m_itemHeight;
    float r = rand()% (th-10);
    r -= (th-10) * 0.5f;
    CCArray * array = m_mainNode->getChildren();
    if (array) {
        for (int i = 0; i < array->count(); i++) {
            CCNode * node = (CCNode *)array->objectAtIndex(i);
            CCMoveBy * move = CCMoveBy::create(kMoveTime, CCPoint(0, dis + r));
            CCEaseSineOut * easeout = CCEaseSineOut::create(move);
            CCDelayTime * delay = CCDelayTime::create(0.2f);
            CCMoveBy * move2 = CCMoveBy::create(0.2f, ccp(0, -r));
            CCSequence * seq = CCSequence::create(easeout,delay,move2,NULL);
            if (node->getTag() == m_targetRow) {
                node->runAction(CCSequence::create(seq,CCDelayTime::create(0.2f),CCCallFunc::create(this, callfunc_selector(GUISpinView::scrollFinish)), NULL));
            }else{
                node->runAction(seq);
            }
        }
    }
    scheduleUpdate();
}
void GUISpinView::scrollFinish()
{
    unscheduleUpdate();
    m_delegate->spinFinished(m_targetRow);
}