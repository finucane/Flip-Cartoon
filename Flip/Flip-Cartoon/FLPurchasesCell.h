//
//  FLPurchasesCell.h
//  Flip
//
//  Created by Finucane on 6/20/14.
//  Copyright (c) 2014 David Finucane. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FLPurchasesCell : UITableViewCell
@property (nonatomic, retain) IBOutlet UILabel*title;
@property (nonatomic, retain) IBOutlet UILabel*_description;
@property (nonatomic, retain) IBOutlet UILabel*price;
@property (nonatomic, retain) IBOutlet UILabel*status;
@property (nonatomic, retain) IBOutlet UIButton*purchaseButton;
@property (nonatomic, retain) IBOutlet UIButton*restoreButton;
@end
