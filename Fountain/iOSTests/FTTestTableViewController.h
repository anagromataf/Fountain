//
//  FTTestTableViewController.h
//  Fountain
//
//  Created by Tobias Kraentzer on 10.08.15.
//  Copyright © 2015 Tobias Kräntzer. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FTTableViewAdapter;

@interface FTTestTableViewController : UITableViewController

@property (nonatomic, readonly) FTTableViewAdapter *adapter;

@end
