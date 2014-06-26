//
//  g_geometry.m
//  Flip
//
//  Created by Finucane on 5/29/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#include "geometry.h"
#include "insist.h"

CGFloat g_area (CGPoint*points, int num_points)
{
  insist (points && num_points > 0);
  
  CGFloat a = 0;
  for (int i = 0; i < num_points; i++)
  {
    int n = (i+1) % num_points;
    a += points [i].x * points [n].y - points [n].x * points [i].y;
  }
  return a / 2.0;
}

void g_centroid (CGPoint*points, int num_points, CGFloat*x, CGFloat*y)
{
  insist (points && num_points > 0 && x && y);
  
  *x = *y = 0.0;
  
  CGFloat a = 6.0 * g_area (points, num_points);
  insist (a);
  
  for (int i = 0; i < num_points; i++)
  {
    int n = (i + 1) % num_points;
    *x += (points [i].x + points [n].x) * (points [i].x * points [n].y - points [n].x * points [i].y);
    *y += (points [i].y + points [n].y) * (points [i].x * points [n].y - points [n].x * points [i].y);
  }
  
  *x /= a;
  *y /= a;
}

/*this assumes the polygon is centered at the origin*/
void g_rotate (CGPoint*points, int num_points, CGFloat radians)
{
  insist (points && num_points);
  
  /*do our trigonometry*/
  CGFloat s = sin (radians);
  CGFloat c = cos (radians);
  
  /*rotate*/
  for (int i = 0; i < num_points; i++)
  {
    CGFloat x = points [i].x;
    CGFloat y = points [i].y;
    
    points [i].x = c * x - s * y;
    points [i].y = s * x + c * y;
  }
}

void g_move (CGPoint*points, int num_points, CGFloat x, CGFloat y)
{
  insist (points && num_points > 0);
  
  for (int i = 0; i < num_points; i++)
  {
    points [i].x += x;
    points [i].y += y;
  }
}

CGFloat g_magnitude (CGPoint point)
{
  return sqrt (point.x * point.x + point.y * point.y);
}

CGFloat g_distance (CGPoint a, CGPoint b)
{
  return sqrt ((a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y));
}

/*return:
 < 0 if ab and cd are parallel
 > 1 if ab and cd do not intersect
 [0..1] where along ab the segments intersect
 
 optionally put in "p" the intersection point, if any
*/
 
CGFloat g_intersection (CGPoint a, CGPoint b, CGPoint c, CGPoint d, CGPoint*p)
{
  CGFloat tcX, tcY, scX, scY, conX, conY, det, con, s, t;
  
  tcX = b.x - a.x; tcY = b.y - a.y;
  scX = c.x - d.x; scY = c.y - d.y;
  conX = c.x - a.x; conY = c.y - a.y;

  det = (tcY * scX - tcX * scY);
  if (det == 0)
    return -1; //segments are parallel
  
  con = tcY * conX - tcX * conY;
  s = con/det;
  if (s < 0 || s > 1) return 2; // something > 1
  
  if (tcX != 0)
    t = (conX - s * scX) / tcX;
  else
    t = (conY - s * scY) / tcY;
  if (t < 0 || t > 1) return 2; //something > 1
  
  /*get the intersection point*/
  if (p)
  {
    p->x = a.x + t * (b.x - a.x);
    p->y = a.y + t * (b.y - a.y);
  }
  /*return [0..1]*/
  return t;
}

BOOL g_lines_intersect (CGPoint a, CGPoint b, CGPoint c, CGPoint d)
{
  if (a.x == c.x && a.y == c.y && b.x == d.x && b.y == d.y)
  {
    return YES;
  }
  if (b.x == c.x && b.y == c.y && a.x == d.x && a.y == d.y)
  {
    return YES;
  }
  
  double dd = (d.y - c.y) * (b.x - a.x) - (d.x - c.x) * (b.y - a.y);
  double an = (d.x - c.x) * (a.y - c.y) - (d.y - c.y) * (a.x - c.x);
  double bn = (b.x - a.x) * (a.y - c.y) - (b.y - a.y) * (a.x - c.x);
  
  if (dd == 0 && an == 0 && bn == 0) return YES;
  if (dd == 0) return NO;

  double ua = an / dd;
  double ub = bn / dd;
  return (ua > 0 && ua < 1 && ub > 0 && ub < 1);
}

/*
  return if ab intersects (or is inside) circle centered at c
  stolen from : http://www.openprocessing.org/sketch/65771
 
  and modified to work in the case where a = b.
*/
BOOL g_line_and_circle_intersect (CGPoint a, CGPoint b, CGPoint c, CGFloat radius)
{
  
  /*if the line is really a point, return point-inside-circle*/
  if (CGPointEqualToPoint (a, b))
  {
    return (a.x - c.x) * (a.x - c.x) + (a.y - c.y) * (a.y - c.y) <= radius * radius;
  }
  
  /*translate everything to origin*/
  CGFloat A = b.x-a.x; // line segment end point horizontal coordinate
  CGFloat B = b.y-a.y; // line segment end point vertical coordinate
  CGFloat C = c.x-a.x; // circle center horizontal coordinate
  CGFloat D = c.y-a.y; // circle center vertical coordinate

  /*if collision is possible...*/
  if ((D*A - C*B)*(D*A - C*B) <= radius*radius*(A*A + B*B))
  {
    /*line segment start point is inside the circle*/
    if (C*C + D*D <= radius*radius)
      return YES;
    
    /*line segment end point is inside the circle*/
    if ((A-C)*(A-C) + (B-D)*(B-D) <= radius*radius)
      return YES;
    
    /*line segment inside circle*/
    if (C*A + D*B >= 0 && C*A + D*B <= A*A + B*B)
      return YES;
  }
  return NO;
}

BOOL g_point_inside_polygon (CGPoint*points, int num_points, CGPoint out_point, CGPoint p)
{
  /*check the point being on a vertex case*/
  for (int i = 0; i < num_points; i++)
  {
    if (p.x == points [i].x && p.y == points [i].y)
      return YES;
  }
  if (out_point.x == 0 && out_point.y == 0)
  {
    /*pick an arbitrary (but nonzero) point outside the poly*/
    CGFloat mx = points [0].x;
    for (int i = 1; i < num_points; i++)
    {
      if (mx < points [i].x)
        mx = points [i].x;
    }
    out_point = CGPointMake (mx + 10.0, 0.0);
  }
  
  /*count the number of intersections along the ray from point to outpoint*/
  int num_intersections = 0;
  for (int i = 0; i < num_points; i++)
  {
    if (g_lines_intersect (points [i], points [(i + 1) % num_points], p, out_point))
      num_intersections++;
  }
  
  /*if the ray crossed an odd number of times the point was inside*/
  return num_intersections % 2;
}


/*see if 2 polygons overlap exactly*/
BOOL polygons_coincide (CGPoint*a, int num_a, CGPoint*b, int num_b)
{
  if (num_a == num_b)
  {
    for (int i = 0; i < num_a; i++)
    {
      int j;
      for (j = 0; j < num_a; j++)
      {
        int n = (j + i) % num_a;
        if (a[j].x != b[n].x || a[j].y != b[n].y)
          break;
      }
      if (j == num_a)
        return YES;
    }
  }
  
  /*there is no rotation of b that lines up with a*/
  return NO;
}

/*return yes if a is totally inside b. not just coincident*/
BOOL g_polygon_inside (CGPoint*a, int num_a, CGPoint*b, int num_b)
{
  /*handle the pathological case of the 2 polys being exactly stacked*/
  if (polygons_coincide (a, num_a, b, num_b))
    return NO;
  
  /*see if all points in a are inside b*/
  for (int i = 0; i < num_a; i++)
  {
    CGPoint out_point;
    out_point.x = out_point.y = 0;
    if (!g_point_inside_polygon (b, num_b, out_point, a[i]))
      return NO;
  }
  return YES;
}


/*return yes if the 2 polys intersect. assume that one is not totally inside the other
  but they can overlap exactly and this counts as an intersection. return an
  intersection point if there is one.*/


BOOL g_polygon_intersection (CGPoint*a, int num_a, CGPoint*b, int num_b, BOOL*inside)
{
  insist (a && b && num_a > 0 && num_b);
  
  /*first handle the pathological case of the 2 polys being exactly stacked*/
  if (polygons_coincide (a, num_a, b, num_b))
    return YES;
  
  /*now for each segment in a check to see if it intersects a segment in b*/
  for (int i = 0; i < num_a; i++)
  {
    for (int j = 0; j < num_b; j++)
    {
      if (g_lines_intersect (a[i], a[(i+1) % num_a], b[j], b[(j+1) % num_b]))
        return YES;
    }
  }
  return NO;
}
/*make the angle between 0 - 2PI)*/
double g_normalize_angle (double a)
{
  a = fmod (a, 2*M_PI);
  if (a < 0) a += 2*M_PI;
  return a;
}