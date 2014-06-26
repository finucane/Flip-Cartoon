//
//  g_geometry.h
//  Flip
//
//  Created by Finucane on 5/29/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#ifndef g_geometry_h
#define g_geometry_h

#import <UIKit/UIKit.h>

CGFloat g_area (CGPoint*points, int num_points);
void g_centroid (CGPoint*points, int num_points, CGFloat*x, CGFloat*y);
void g_move (CGPoint*points, int num_points, CGFloat x, CGFloat y);
void g_rotate (CGPoint*points, int num_points, CGFloat radians);
CGFloat g_magnitude (CGPoint point);
CGFloat g_distance (CGPoint a, CGPoint b);
BOOL g_point_inside_polygon (CGPoint*points, int num_points, CGPoint out_point, CGPoint p);
CGFloat g_intersection (CGPoint a, CGPoint b, CGPoint c, CGPoint d, CGPoint*p);
BOOL g_lines_intersect (CGPoint a, CGPoint b, CGPoint c, CGPoint d);
BOOL g_line_and_circle_intersect (CGPoint a, CGPoint b, CGPoint c, CGFloat radius);
BOOL g_polygon_inside (CGPoint*a, int num_a, CGPoint*b, int num_b);
BOOL g_polygon_intersection (CGPoint*a, int num_a, CGPoint*b, int num_b, BOOL*inside);
double g_normalize_angle (double a);
#endif