//
//  FTTableViewAdapter+Subclassing.h
//  Fountain
//
//  Created by Tobias Kraentzer on 09.07.15.
//  Copyright (c) 2015 Tobias Kräntzer. All rights reserved.
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
