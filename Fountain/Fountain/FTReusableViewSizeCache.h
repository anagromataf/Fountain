//
//  FTReusableViewSizeCache.h
//  Fountain
//
//  Created by Tobias Kraentzer on 05.01.15.
//  Copyright (c) 2015 Tobias Kräntzer. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol FTReusableViewSizeCache <NSObject>

+ (void)cacheSize:(CGSize)size ofItem:(id)item forPreferredMaxLayoutWidth:(CGFloat)width;
+ (CGSize)cachedSizeOfItem:(id)item forPreferredMaxLayoutWidth:(CGFloat)width;
+ (void)invalidateCachedSizeOfItem:(id)item;
+ (void)invalidateAllCachedSizes;

@end
