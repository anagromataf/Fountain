//
//  FTDynamicHeightTableViewAdapter.h
//  Fountain
//
//  Created by Tobias Kräntzer on 06.07.15.
//  Copyright © 2015 Tobias Kräntzer. All rights reserved.
//

#import "FTTableViewAdapter.h"

@interface FTDynamicHeightTableViewAdapter : FTTableViewAdapter

#pragma mark Heights
@property (nonatomic, assign) CGFloat estimatedRowHeight;
@property (nonatomic, assign) CGFloat rowHeight;

@end
