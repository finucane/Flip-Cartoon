//
//  UIImage+Additions.m
//  Flip
//
//  Created by Finucane on 6/10/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#import "UIImage+Additions.h"

@implementation UIImage (Additions)

/*
  shamelessy ripped off from stack overflow w/out reading it too closely
*/
-(UIImage*) imageWithUnsaturatedPixels
{
  const int RED = 1, GREEN = 2, BLUE = 3;
  
  CGRect imageRect = CGRectMake(0, 0, self.size.width*2, self.size.height*2);
  
  int width = imageRect.size.width, height = imageRect.size.height;
  
  uint32_t * pixels = (uint32_t *) malloc(width*height*sizeof(uint32_t));
  memset(pixels, 0, width * height * sizeof(uint32_t));
  
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  CGContextRef context = CGBitmapContextCreate(pixels, width, height, 8, width * sizeof(uint32_t), colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedLast);
  
  CGContextDrawImage(context, CGRectMake(0, 0, width, height), [self CGImage]);
  
  for(int y = 0; y < height; y++) {
    for(int x = 0; x < width; x++) {
      uint8_t * rgbaPixel = (uint8_t *) &pixels[y*width+x];
      uint32_t gray = (0.3*rgbaPixel[RED]+0.59*rgbaPixel[GREEN]+0.11*rgbaPixel[BLUE]);
      
      rgbaPixel[RED] = gray;
      rgbaPixel[GREEN] = gray;
      rgbaPixel[BLUE] = gray;
    }
  }
  
  CGImageRef newImage = CGBitmapContextCreateImage(context);
  
  CGContextRelease(context);
  CGColorSpaceRelease(colorSpace);
  free(pixels);
  
  UIImage * resultUIImage = [UIImage imageWithCGImage:newImage scale:2 orientation:0];
  CGImageRelease(newImage);
  
  return resultUIImage;
}

-(UIImage*) imageWithTintedColor:(UIColor *)color withIntensity:(float)alpha
{
  CGSize size = self.size;
  
  UIGraphicsBeginImageContextWithOptions(size, FALSE, 2);
  CGContextRef context = UIGraphicsGetCurrentContext();
  
  [self drawAtPoint:CGPointZero blendMode:kCGBlendModeNormal alpha:1.0];
  
  CGContextSetFillColorWithColor(context, color.CGColor);
  CGContextSetBlendMode(context, kCGBlendModeSourceIn);
  CGContextSetAlpha(context, alpha);
  
  CGContextFillRect(UIGraphicsGetCurrentContext(), CGRectMake(CGPointZero.x, CGPointZero.y, self.size.width, self.size.height));
  
  UIImage * tintedImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  
  return tintedImage;
}

-(UIImage*)imageWithTintColor:(UIColor*)color
{
  UIImage*image = [self imageWithUnsaturatedPixels];
  return [image imageWithTintedColor:color withIntensity:1.0];
}
@end
