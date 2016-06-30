//
//  FTTestTableViewController.m
//  Fountain
//
//  Created by Tobias Kraentzer on 10.08.15.
//  Copyright © 2015 Tobias Kräntzer. All rights reserved.
//

#import <Fountain/Fountain.h>

#import "FTTestTableViewController.h"

@interface FTTestTableViewController () {
    FTTableViewAdapter *_adapter;
}

@end

@implementation FTTestTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    _adapter = [[FTTableViewAdapter alloc] initWithTableView:self.tableView];
}

@end
