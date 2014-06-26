//
//  FLText.m
//  Flip
//
//  Created by Finucane on 6/8/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#import <CoreText/CoreText.h>
#import "FLAppDelegate.h"
#import "FLText.h"
#import "FLCartoon.h"
#import "geometry.h"
#import "insist.h"

@implementation FLText

@dynamic text;
@dynamic x;
@dynamic y;
@dynamic width;
@dynamic height;
@dynamic fontSize;
@dynamic outlineX, outlineY, outlineWidth, outlineHeight;

static CGFloat const CORNER_HEIGHT = 4;
static CGFloat const CORNER_WIDTH = 4;
static CGFloat const MAX_FONT_SIZE = 50; //we always want to allow big fonts
static CGFloat const INSET_PIXELS = 0;



-(void)fault
{
  [self.managedObjectContext refreshObject:self mergeChanges:NO];
}


/*
 so the text doesn't look crappy, we make sure its outline height fits whatever the user types in.
 this is done by shrinking the text's box a bit in the height direction if there was extra space
 in what the user drew with the text tool.
 
 outline is that possibly smaller rectangle than what the user selected. this is dynamic and is
 recomputed every time the string changes.
 
 it's used for hit calculations.
 
 since this thing is transient keep track of it outside of the moc (it's recomputed as a side effect
 of recomputeFontSize.
 
 */
-(void)awakeFromInsert
{
  [super awakeFromInsert];
  self.text = @""; //can't set empty string default in xcode
}
-(void)awakeFromFetch
{
  [super awakeFromFetch];
}

/*
  outline is stored in core data as 4 primitives and accessed through these accessors
*/
-(CGRect)outline
{
  return CGRectMake (self.outlineX, self.outlineY, self.outlineWidth, self.outlineHeight);
}

-(void)setOutline:(CGRect)rect
{
  self.outlineX = rect.origin.x;
  self.outlineY = rect.origin.y;
  self.outlineWidth = rect.size.width;
  self.outlineHeight = rect.size.height;
}

/*
 set dimensions using 2 points. this is used to change the size of the text
 box while the user is dragging his finger with the text tool.
 
 a - a point
 b - another point
 */
-(void)setWithPoint:(CGPoint)a b:(CGPoint)b
{
  self.x = MIN (a.x, b.x); //defined in NSObjCRuntime.h
  self.y = MIN (a.y, b.y);
  self.width = fabs (b.x - a.x);
  self.height = fabs (b.y - a.y);
  self.outline = CGRectMake (self.x, self.y, self.width, self.height);
}


/*
 return YES if a circle intersects self.
 
 point - center of circle
 radius - radius of circle
 
 returns: stroke if hit, nil otherwise
 */
-(BOOL)hitsPoint:(CGPoint)point radius:(CGFloat)radius
{
  insist (radius > 0);
  
  CGRect outline = self.outline;
  
  if (g_line_and_circle_intersect (CGPointMake (outline.origin.x, outline.origin.y),
                                   CGPointMake (outline.origin.x, outline.origin.y + outline.size.height), point, radius))
    return YES; //left
  if (g_line_and_circle_intersect (CGPointMake (outline.origin.x, outline.origin.y),
                                   CGPointMake (outline.origin.x + outline.size.width, outline.origin.y), point, radius))
    return YES; //bottom
  if (g_line_and_circle_intersect (CGPointMake (outline.origin.x, outline.origin.y + outline.size.height),
                                   CGPointMake (outline.origin.x + outline.size.width, outline.origin.y + outline.size.height), point, radius))
    return YES; //top
  if (g_line_and_circle_intersect (CGPointMake (outline.origin.x + outline.size.width, outline.origin.y),
                                   CGPointMake (outline.origin.x + outline.size.width, outline.origin.y + outline.size.height), point, radius))
    return YES; //right
  
  return NO;
}


/*
 return true if a line segment intersects self.
 
 a - start of line segment
 b - end of line segment
 
 returns: stroke if hit, nil otherwise
 */
-(BOOL)hitsLine:(CGPoint)a to:(CGPoint)b
{
  CGRect outline = self.outline;

  if (g_lines_intersect (CGPointMake (outline.origin.x, outline.origin.y),
                         CGPointMake (outline.origin.x, outline.origin.y + outline.size.height), a, b))
    return YES; //left
  if (g_lines_intersect (CGPointMake (outline.origin.x, outline.origin.y),
                         CGPointMake (outline.origin.x + outline.size.width, outline.origin.y), a, b))
    return YES; //bottom
  if (g_lines_intersect (CGPointMake (outline.origin.x, outline.origin.y + outline.size.height),
                         CGPointMake (outline.origin.x + outline.size.width, outline.origin.y + outline.size.height), a, b))
    return YES; //top
  if (g_lines_intersect (CGPointMake (outline.origin.x + outline.size.width, outline.origin.y),
                         CGPointMake (outline.origin.x + outline.size.width, outline.origin.y + outline.size.height), a, b))
    return YES; //right
  return NO;
}

/*
  return true if point is within radius of the lower right corner of text.
  this is used for resizing. lower right is higher than the origin because
  iOS draws upside down.
 
  point - a point
  radius - a radius
*/
 
-(BOOL)lowerRightHitsPoint:(CGPoint)point radius:(CGFloat)radius
{
  insist (radius > 0);
  CGRect outline = self.outline;

  CGPoint lowerRight = CGPointMake (outline.origin.x + outline.size.width, outline.origin.y + outline.size.height);
  return g_distance(lowerRight, point) < radius;
}

/*
 move self by dx, dy
 
 dx - amount in x direction to move
 dy - amount in y direction to move
 */
-(void)moveBy:(CGFloat)dx dy:(CGFloat)dy
{
  CGRect outline = self.outline;
  self.x += dx;
  self.y += dy;
  outline.origin.x += dx;
  outline.origin.y += dy;
  self.outline = outline;
}


/*
 update the bb so that it contains self
 
 return YES if the bb changed.
 */
-(BOOL)updateBB:(CGRect*)bb
{
  return [FLStroke updateBB:bb withRect:CGRectMake (self.x, self.y, self.width, self.height)];
}

/*
 make a copy of self and add to shape
 
 returns new stroke
 */
-(FLStroke*)cloneToShape:(FLShape*)shape
{
  insist (shape);
  
  FLCoreData*coreData = App.coreData;
  insist (coreData);
  
  FLText*newText = [coreData newTextForShape:shape];
  insist (newText);
  
  newText.text = self.text;
  newText.x = self.x;
  newText.y = self.y;
  newText.width = self.width;
  newText.height = self.height;
  newText.fontSize = self.fontSize;
  newText.outline = self.outline;
  
  return newText;
}


/*
 return the largest "y" coordinate of the path
 */
-(CGPoint)largestYPoint
{
  return CGPointMake (self.x, self.y + self.height);
}


/*
 return attributed string for text using cartoon font and size "size"
 */
- (NSAttributedString*)attributedStringForSize:(CGFloat)size type:(FLDrawType)drawType
{
  FLCoreData*coreData = App.coreData;
  insist (coreData);
  insist (self.shape);
  FLCartoon*cartoon = self.shape.cartoon;
  insist (cartoon);
  
  NSString*fontName = cartoon.fontName;
  insist (fontName);
  
  NSMutableParagraphStyle*style = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
  insist (style);
  style.lineBreakMode = NSLineBreakByWordWrapping;
  style.lineSpacing = 0;
  style.alignment = NSTextAlignmentCenter;
  style.lineHeightMultiple = 1.0;
  
  UIFont*font = [coreData fontForName:fontName size:size];
  NSAttributedString*s = [[NSAttributedString alloc] initWithString:self.text
                                                         attributes: @{NSFontAttributeName : font,
                                                                       (__bridge id)kCTForegroundColorAttributeName:(__bridge id)[self cgColorForType:drawType],
                                                                       NSParagraphStyleAttributeName : style}];
  insist (s);
  return s;
}


/**
 set the fontSize to the largest size allowing the text string to fit inside
 the text rectangle.
 
 this should be called whenever the text string or the text rectangle is modified
 so that drawRect can draw the string correctly.
 
 this works by trying font sizes, starting at MAX_FONT_SIZE, until the string fits.
 if this turns out to be slow, do a binary search.
 
 if text is empty, or if the text rectangle is too small to be insetted by INSET_PIXELS
 fontSize is set to 0.
 
 this method also recomputes "outline", which is the rect that's actually drawn around
 the string -- it might be smaller than the user's original text rect it the string
 didn't use up all of the height.
 
 */

-(void)recomputeFontSize
{
  insist (self.text);
  if (self.text.length == 0)
  {
    self.outline = CGRectMake (self.x, self.y, self.width, self.height);
    self.fontSize = 0;
    return;
  }
  
  /* get the rect we are allowed to draw text to, if it ends up 0 that means the text rect was too small to inset*/
  CGRect inset = [self inset];
  if (CGRectIsNull (inset))
  {
    self.outline = CGRectMake (self.x, self.y, self.width, self.height);
    self.fontSize = 0;
    return;
  }
  
  CGFloat size = MAX_FONT_SIZE;
  for (; size > 1; size -= 1.0)
  {
    /*make an attributed string of font/size "size" that word wraps*/
    
    NSAttributedString*s = [self attributedStringForSize:size type:FLDrawNormal];
    insist (s);
    
    /*compute the bounding rect for the text*/
    CGSize stringSize = [self sizeForAttributedString:s];
    
    insist (stringSize.width > 0);
    
    /*width will always fit, it's the height that varies as we shrink the font*/
    
    if (stringSize.width < inset.size.width && stringSize.height < inset.size.height)
    {
      /*recompute the height of outline*/
      CGRect outline = self.outline;
      outline.size.height = stringSize.height + INSET_PIXELS;
      self.outline = outline;
      self.fontSize = size;
      return;
    }
  }
  self.fontSize = 0;
}

/*
 return dimensions of self as a CGRect
 */
-(CGRect)cgRect
{
  return CGRectMake(self.x, self.y, self.width, self.height);
}

/*
 return rect where text should be drawn to, inset from the text rect itself.
 this can be the null rect if the text rect is too small to be inset.
 */
-(CGRect)inset
{
  return CGRectInset(self.cgRect, INSET_PIXELS, INSET_PIXELS);
}

/*
 return size for attributed string when it's rendered on screen. the string
 is constrained by self.width inset a bit: if our width is too small to be
 inset, the empty size is returned.
 
 attributed - attributed string for our text (multi-line, font, font size, etc).
 
 returns size.
 */
-(CGSize)sizeForAttributedString:(NSAttributedString*)attributed
{
  insist (attributed);
  
  CGRect inset = [self inset];
  if (CGRectIsNull (inset))
    return CGSizeMake(0, 0);
  
  /*make a framesetter for the string, we just us that to get the frame size*/
  CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString ((CFAttributedStringRef)attributed);
  CFRange dc;
  CGSize size = CTFramesetterSuggestFrameSizeWithConstraints (framesetter, CFRangeMake (0,0), 0, CGSizeMake(inset.size.width, CGFLOAT_MAX), &dc);
  
  CFRelease (framesetter);
  return size;
}

/*
 draw self to context
 
 bounds - bounds of view (for transformations if we have to draw text)
 context - context to draw to
 
 subclasses should override
 */

-(void)drawContext:(CGContextRef) context type:(FLDrawType)drawType
{
  CGRect outline = self.outline;
  
  /*
   documentation through core data assertion failure:
   Assertion failed: (corner_height >= 0 && 2 * corner_height <= CGRectGetHeight(rect))
   */
  
  /*
    if the rect is too small to render text into, just draw the rect. otherwise
    it will disappear
  */
  if (outline.size.height < 2 * CORNER_HEIGHT || outline.size.width < 2 * CORNER_WIDTH)
  {
    CGContextSaveGState(context);
    CGContextBeginPath (context);

    CGContextSetFillColorWithColor (context, [[UIColor whiteColor] CGColor]);
    CGContextSetStrokeColorWithColor (context, [self cgColorForType:drawType]);

    CGPathRef path = CGPathCreateWithRect (outline, 0);
    CGContextAddPath (context, path);
    CGContextDrawPath (context, kCGPathFillStroke);
    CGPathRelease (path);
    CGContextRestoreGState (context);
    return;
  }
  
  CGContextSaveGState(context);
  CGContextBeginPath (context);
  
  CGPathRef path = CGPathCreateWithRoundedRect (outline, CORNER_WIDTH,CORNER_HEIGHT, 0);
  
  CGContextAddPath (context, path);
  CGContextSetFillColorWithColor (context, [[UIColor whiteColor] CGColor]);
  CGContextSetStrokeColorWithColor (context, [self cgColorForType:drawType]);
  
  CGContextDrawPath (context, kCGPathFillStroke);
 
  CGPathRelease (path);

  if (self.fontSize > 0 && self.text.length > 0)
  {
    NSAttributedString*attributed = [self attributedStringForSize:self.fontSize type:drawType];
    insist (attributed);
    
    /*make a rect that's a bit smaller than the text rect.*/
    CGRect inset = self.inset;
    insist (!CGRectIsNull (inset));
    
    /*make a framesetter (whateve that is, and a path and a frame*/
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString ((CFAttributedStringRef)attributed);
    path = CGPathCreateWithRect (inset, NULL);
    CTFrameRef frame = CTFramesetterCreateFrame (framesetter, CFRangeMake(0, 0), path, 0);
    
    /*flip text upside down*/
    
    CGContextTranslateCTM(context, 0, inset.origin.y);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextTranslateCTM(context, 0, - (inset.origin.y + inset.size.height));
    
    CTFrameDraw (frame, context);
    CFRelease (frame);
    CGPathRelease (path);
    CFRelease (framesetter);
  }
  CGContextRestoreGState(context);
}


@end
