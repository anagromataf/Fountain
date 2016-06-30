//
//  FTTestCollectionViewController.h
//  Fountain
//
//  Created by Tobias Kraentzer on 13.08.15.
//  Copyright © 2015 Tobias Kräntzer. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FTCollectionViewAdapter;

@interface FTTestCollectionViewController : UICollectionViewController
@property (nonatomic, readonly) FTCollectionViewAdapter *adapter;
@end
