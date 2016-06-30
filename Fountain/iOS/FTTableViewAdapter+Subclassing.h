//
//  FTTableViewAdapter+Subclassing.h
//  FTFountain
//
//  Created by Tobias Kraentzer on 12.08.15.
//  Copyright © 2015 Tobias Kräntzer. All rights reserved.
//

#import "FTTableViewAdapter.h"

@interface FTTableViewAdapter (Subclassing)

- (void)rowPreperationForItemAtIndexPath:(NSIndexPath *)indexPath
                               withBlock:(void (^)(NSString *reuseIdentifier,
                                                   FTTableViewAdapterCellPrepareBlock prepareBlock,
                                                   id item))block;

- (void)headerPreperationForSection:(NSUInteger)section
                          withBlock:(void (^)(NSString *reuseIdentifier,
                                              FTTableViewAdapterHeaderFooterPrepareBlock prepareBlock,
                                              id item))block;

- (void)footerPreperationForSection:(NSUInteger)section
                          withBlock:(void (^)(NSString *reuseIdentifier,
                                              FTTableViewAdapterHeaderFooterPrepareBlock prepareBlock,
                                              id item))block;

@end
