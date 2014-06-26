//
//  FLPurchasesViewController.h
//  Flip
//
//  Created by Finucane on 6/20/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FLPurchasesViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
{
  @private
  IBOutlet UITableView*tableView;
}

-(IBAction)purchase:(id)sender;
-(IBAction)restore:(id)sender;

@end
