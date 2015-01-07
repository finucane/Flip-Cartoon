//
//  FLPurchasesViewController.m
//  Flip
//
//  Created by Finucane on 6/20/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#import "SKProduct+Additions.h"
#import "FLPurchasesCell.h"
#import "FLPurchasesViewController.h"
#import "FLAppDelegate.h"
#import "insist.h"

static NSString*const PURCHASE_CELL_REUSE_ID = @"PurchaseCell";
static CGFloat const PURCHASE_CELL_HEIGHT = 161;

/*
  the assumption here is that the underlying purchases information (number of products etc)
  is not going to change while this view controller is around.
 
  that's going to be the case because we only ever collect purchase information once, when
  this app launches. but a more complicated app would have this view controller copying
  its underlying data or preventing that data from changing from underneath it.
*/

@implementation FLPurchasesViewController

/* 
  on view will appear, register for purchase updates
*/
-(void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];

  [[NSNotificationCenter defaultCenter] addObserverForName:kFLPurchasesNotification
                                                    object:App.purchases
                                                     queue:[NSOperationQueue mainQueue]
                                                usingBlock:^(NSNotification*n) {
                                           
                                                  [tableView reloadData];
                                                  
                                                }];
}

/*
 on view will appear, de-register for purchase updates
*/
-(void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
  
  [[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:nil];
}

#pragma mark - UITableViewDataSource

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return App.purchases.products.count;
}

-(NSInteger)tableView:(UITableView*)aTableView numberOfRowsInSection:(NSInteger)section
{
  return 1;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
  return PURCHASE_CELL_HEIGHT;
}

-(UITableViewCell*)tableView:(UITableView*)aTableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  insist (aTableView == tableView);
  FLPurchasesCell*cell = [tableView dequeueReusableCellWithIdentifier:PURCHASE_CELL_REUSE_ID];
  insist (cell);
  insist (indexPath.section >= 0 && indexPath.section < App.purchases.products.count);

  SKProduct*product = App.purchases.products [indexPath.section];

  cell.title.text = product.localizedTitle;
  cell._description.text = product.localizedDescription;
  cell.price.text = product.formattedPriceInUserCurrency; //from category
  
  /*disable the buy buttons if the product is bought (or can't be bought) and set the status text*/
  FLPurchasesState state = [App.purchases stateForProductID:product.productIdentifier];
  cell.purchaseButton.enabled = cell.restoreButton.enabled = state == FL_PURCHASES_NOT_PURCHASED || state == FL_PURCHASES_FAILED;
  cell.status.text = [self localizedStatusForState:state];
  
  return cell;
}

#pragma mark - not UITableViewDataSource anymore

-(NSString*)localizedStatusForState:(FLPurchasesState)state
{
  switch (state)
  {
    case FL_PURCHASES_PURCHASED: return NSLocalizedString (@"(Purchased)", nil);
    case FL_PURCHASES_REQUEST_SENT: return NSLocalizedString (@"(Pending)", nil);
    case FL_PURCHASES_FAILED:return NSLocalizedString (@"(Purchase Failed)", nil);
    case FL_PURCHASES_NOT_PURCHASED:
    default: return @"    "; //autolayout
  }
  return @"";
}
/*
  get the indexPath for a control inside a cell. this works by 
  starting at the control and going up the view hierarchy until
  finding a view that's a cell and then calling the tableview
  method for getting the index path.
*/
-(NSIndexPath*)indexPathOfSubviewInCell:(id)sender
{
  insist (sender);
  UIView*v = sender;
  while (v && ![v isKindOfClass:[UITableViewCell class]])
    v = v.superview;
  
  insist (v);
  insist (tableView); //why we have it as an outlet
  
  return [tableView indexPathForCell:(UITableViewCell*)v];
}

-(IBAction)purchase:(id)sender
{
  NSIndexPath*indexPath = [self indexPathOfSubviewInCell:sender];
  insist (indexPath);

  insist (indexPath.section >= 0 && indexPath.section < App.purchases.products.count);
  
  /*start the purchase transaction*/
  [App.purchases buy:App.purchases.products [indexPath.section]];
   
  /*reload tableView to reflect change in purchase state*/
  [tableView reloadData];
}
-(IBAction)restore:(id)sender
{
  [App.purchases restore];
}


@end
