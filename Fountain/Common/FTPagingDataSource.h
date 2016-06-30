//
//  FTPagingDataSource.h
//  FTFountain
//
//  Created by Tobias Kraentzer on 13.08.15.
//  Copyright © 2015 Tobias Kräntzer. All rights reserved.
//

#import "FTDataSource.h"

@protocol FTPagingDataSource <FTDataSource>

- (BOOL)hasItemsBeforeFirstItem;
- (void)loadMoreItemsBeforeFirstItemCompletionHandler:(void (^)(BOOL success, NSError *error))completionHandler;

- (BOOL)hasItemsAfterLastItem;
- (void)loadMoreItemsAfterLastItemCompletionHandler:(void (^)(BOOL success, NSError *error))completionHandler;

@end
