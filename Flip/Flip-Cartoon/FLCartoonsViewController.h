//
//  FLCartoonsViewTableViewController.h
//  Flip
//
//  Created by Finucane on 5/28/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FLCartoonsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
{
  @private
  IBOutlet UITableView*tableView;
}

-(IBAction)add:(id)sender;
-(IBAction)flip:(id)sender;
@end
