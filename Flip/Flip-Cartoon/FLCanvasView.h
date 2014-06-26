//
//  FLCanvasView.h
//  Flip
//
//  Created by Finucane on 5/30/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FLPolygon.h"
#import "FLCartoon.h"
#import "FLShape.h"
#import "FLText.h"
#import "DFPanGestureRecognizer.h"
/*
  protocol to pass user events out of FLCanvasView.
*/
@class FLCanvasView;
@protocol FLCanvasViewDelegate <NSObject>
-(void)canvasViewSwipedRight:(FLCanvasView*)canvasView;
-(void)canvasViewSwipedLeft:(FLCanvasView*)canvasView;
@end

typedef enum FLCanvasState : NSUInteger
{
  FLCanvasStateNone,
  FLCanvasStateDraw,
  FLCanvasStatePolygon,
  FLCanvasStateErase,
  FLCanvasStateFinger,
  FLCanvasStateText,
  FLCanvasStateVideo
}FLCanvasState;


typedef enum FLCanvasPanState : NSUInteger
{
  FLCanvasPanStateNone,
  FLCanvasPanStateAddingPath,
  FLCanvasPanStateSizingTextBox,
  FLCanvasPanStateMovingShape,
  FLCanvasPanStatePanningView,
  FLCanvasPanStateErasing
}FLCanvasPanState;

@interface FLCanvasView : UIView <UITextInputTraits, UIKeyInput>
{
  @private
  BOOL layerIsDirty;
  CGLayerRef layerRef;
  FLText*selectedText;
  CGPoint textOrigin;
  NSMutableString*keyInputString;
  FLCanvasState state;
  FLCanvasPanState panState;
  CGFloat pinchScale;
  CGFloat fixedScale;
  CGPoint origin;
  CGPoint touchPoint;
  CGPoint previousPoint;
  CGPoint previousTranslation; //for moving shape
  UITapGestureRecognizer*singleTapRecognizer;
  UITapGestureRecognizer*doubleTapRecognizer;
  DFPanGestureRecognizer*panRecognizer;
  UIPinchGestureRecognizer*pinchRecognizer;
  UISwipeGestureRecognizer*rightSwipeRecognizer;
  UISwipeGestureRecognizer*leftSwipeRecognizer;
}

@property (nonatomic, weak) IBOutlet id<FLCanvasViewDelegate> canvasViewDelegate;

-(id)initWithFrame:(CGRect)aRect;
-(FLCanvasState)state;
-(void)setState:(FLCanvasState)state;
-(void)refresh;
-(CGSize)frameSize;

@end
