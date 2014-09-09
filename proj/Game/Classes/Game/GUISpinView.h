//
//  GUISpinView.h
//  JellyMania
//
//  Created by lipeng on 14-4-16.
//
//

#ifndef __JellyMania__GUISpinView__
#define __JellyMania__GUISpinView__

#include <iostream>
#include "cocos2d.h"
using namespace cocos2d;

class GUISpinViewDelegate;
class GUISpinView : public CCLayer {
public:
    GUISpinView();
    ~GUISpinView();
    
    GUISpinView(CCRect viewFrame, float itemHeight, GUISpinViewDelegate * delegate);
private:
    GUISpinViewDelegate *   m_delegate;
    CCNode *                    m_mainNode;
    
    CCRect                      m_viewFrame;
    int                         m_itemCount;
    int                         m_targetRow;
    int                         m_currentRow;
    float                       m_itemHeight;
    float                       m_currentVelocity;
public:
    void refresh();
    void scrollTo(int rowIndex);
    void scrollFinish();
private:
    
protected:
    virtual void visit();
    virtual void update(float delta);
};

class GUISpinViewDelegate {
    friend class GUISpinView;
protected:
    virtual CCNode * createItemForSpinView(GUISpinView * spinView, int index) = 0;
    virtual int itemsCountForSpinView(GUISpinView * spinView) = 0;
    virtual void spinFinished(int index) = 0;
};

#endif /* defined(__JellyMania__GUISpinView__) */
