//
//  FTStaticDataSource.h
//  Fountain
//
//  Created by Tobias Kraentzer on 13.04.15.
//  Copyright (c) 2015 Tobias Kräntzer. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FTDataSource.h"

@interface FTStaticDataSource : NSObject <FTDataSource, FTReverseDataSource>

#pragma mark Relaod
- (void)reloadWithItems:(NSArray *)sectionItems
      completionHandler:(void (^)(BOOL success, NSError *error))completionHandler;

@end
