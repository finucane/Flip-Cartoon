//
//  FLCartoonsViewController.m
//  Flip
//
//  Created by Finucane on 5/28/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#import "FLCartoonsViewController.h"
#import "FLAppDelegate.h"
#import "FLCartoonCell.h"
#import "FLCartoonDetailViewController.h"
#import "FLCoreData.h"
#import "UIAlertView+Additions.h"
#import "insist.h"

static NSString*const CARTOONS_CELL_REUSE_ID = @"CartoonsCell";
static NSString*const PURCHASES_CELL_REUSE_ID = @"PurchasesCell";
static NSString*const CARTOON_DETAIL_SEGUE_ID = @"CartoonDetail";
static NSString*const CHECKMARK_IMAGE_NAME = @"checkmark";
static const CGFloat CARTOON_CELL_HEIGHT = 64;
static const CGFloat PURCHASES_CELL_HEIGHT = 44;

@implementation FLCartoonsViewController


-(IBAction)add:(id)sender
{
  insist (tableView);
  
  FLCoreData*coreData = App.coreData;
  insist (coreData);
  
  NSError*error;
  
  /*
    if the user hasn't purchaed unlimited cartoons, he can't add any.
  */
  if (!App.purchases.unlimitedCartoons)
  {
    [UIAlertView showAlertWithTitle:NSLocalizedString (@"Cartoon Limit", nil)
                             format:NSLocalizedString (@"You may only have one cartoon at a time. Use In-App Purchases to remove this limit.", nil), kFLPurchasesFrameLimit];
    return;
  }

  /*
    make a new cartoon. we don't actually care about the reference to it, just
    adding it to core data and refreshing the table is enough.
  */
  if (!([coreData newCartoonWithError:&error]))
  {
    [UIAlertView showError:error];
    return;
  }
  
  [tableView reloadData];

}

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender
{
  insist (segue && sender);
  
  FLCoreData*coreData = App.coreData;
  insist (coreData);
  
  /*
    if it's a cartoon detail segue, set the cartoon detail vc's cartoon property to
    the cartoon at the indexPath referenced by the "sender" pointer.
    also set the detail vc's table view to our table view (the detail vc
    will use that to force the tableView to reload if the user made changes in
    the detailView).
  */
  if ([[segue identifier] isEqualToString:CARTOON_DETAIL_SEGUE_ID])
  {
    /*get the indexPath for the cell*/
    insist ([sender isKindOfClass:[UITableViewCell class]]);
    NSIndexPath*indexPath = [tableView indexPathForCell:(UITableViewCell*) sender];
    insist (indexPath);
    insist (indexPath.row < coreData.cartoons.count);

    FLCartoonDetailViewController*vc = [segue destinationViewController];
    insist (vc);
    
    vc.cartoon = coreData.cartoons [indexPath.row];
    vc.tableView = tableView;
  }
}
/*
 flip to the other top level viewController (the drawing one)
*/
-(IBAction)flip:(id)sender
{
  [App flipViewControllers];
}

- (void)tableView:(UITableView*)aTableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  insist (tableView && aTableView == tableView);
  
  if (indexPath.section == 0)
    return;
  
  NSInteger row = indexPath.row;

  if (tableView.editing)
  {
    [self performSegueWithIdentifier:CARTOON_DETAIL_SEGUE_ID sender:self];
  }
  else
  {
    /*set currentCartoon to be that of the selected row*/
    FLCoreData*coreData = App.coreData;
    insist (coreData);
    insist (row < coreData.cartoons.count);
    NSError*error;
    if (![coreData setCurrentCartoon:coreData.cartoons [row] withError:&error])
    {
      [UIAlertView showError:error];
      return;
    }
    [tableView reloadData];
  }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
  /*the in app purchases section has just 1 item so it can't have a header*/
  if (section == 0)
    return @"";
  else
    return NSLocalizedString (@"Cartoons", nil);
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
  if (indexPath.section == 0)
    return PURCHASES_CELL_HEIGHT;
  else
    return CARTOON_CELL_HEIGHT;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return 2;
}
- (NSInteger)tableView:(UITableView*)aTableView numberOfRowsInSection:(NSInteger)section
{
  insist (tableView && aTableView == tableView);
  
  FLCoreData*coreData = App.coreData;
  insist (coreData);
  
  if (section == 0)
  {
    return 1;
  }

  return coreData.cartoons.count;
}

- (UITableViewCell*)tableView:(UITableView*)aTableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  insist (tableView && aTableView == tableView);
  
  if (indexPath.section == 0)
  {
    return [tableView dequeueReusableCellWithIdentifier:PURCHASES_CELL_REUSE_ID];
  }
  
  NSInteger row = indexPath.row;

  FLCoreData*coreData = App.coreData;
  insist (coreData);
  insist (row < coreData.cartoons.count);
  
  FLCartoon*cartoon = coreData.cartoons [row];
  
  FLCartoonCell*cell = [tableView dequeueReusableCellWithIdentifier:CARTOONS_CELL_REUSE_ID];
  insist (cell);
  
  cell.title.text = cartoon.title;
  
  if (cartoon == coreData.currentCartoon)
    cell.checkmarkImageView.image = [UIImage imageNamed:CHECKMARK_IMAGE_NAME];
  else
    cell.checkmarkImageView.image = nil;
  
  return cell;
}

- (UITableViewCellEditingStyle)tableView:(UITableView*)aTableView editingStyleForRowAtIndexPath:(NSIndexPath*)indexPath
{
  return indexPath.section == 0 ? UITableViewCellEditingStyleNone : UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView*)aTableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath
{
  insist (tableView && aTableView == tableView);

  
  /*we only care about deleting here*/
  if (editingStyle != UITableViewCellEditingStyleDelete)
    return;
  
  /*delete the cartoon corresponding to row and force table to redraw itself*/
  NSInteger row = indexPath.row;
  
  FLCoreData*coreData = App.coreData;
  insist (coreData);
  NSArray*cartoons = coreData.cartoons;
  insist (row < cartoons.count);

  /*remember if the deleted cartoon was checked, so we can select something else*/
  BOOL wasChecked = cartoons [row] == coreData.currentCartoon;
  unsigned checkedIndex = coreData.currentCartoon.index;
  
  NSError*error;
  if (![coreData deleteCartoon:coreData.cartoons [row] withError:&error])
  {
    [UIAlertView showError:error];
    return;
  }
  
  /*check some other cartoon if we deleted the previous selection*/
  if (wasChecked)
  {
    /*get updated cartoons list*/
    cartoons = coreData.cartoons;
    insist (cartoons.count);
    
    /*check the previous cartoon in the list, if possible, otherwise check the 0th again*/
    if (checkedIndex > 0)
      checkedIndex--;
    if (![coreData setCurrentCartoon:cartoons [checkedIndex] withError:&error])
    {
      [UIAlertView showError:error];
      return;
    }
  }
  
  [tableView reloadData];
}
@end
