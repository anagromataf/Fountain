//
//  FTAdapterPrepareHandler.h
//  Fountain
//
//  Created by Tobias Kräntzer on 09.12.14.
//  Copyright (c) 2014 Tobias Kräntzer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FTAdapterPrepareHandler : NSObject

#pragma mark Life-cycle
- (instancetype)initWithPredicate:(NSPredicate *)predicate
                  reuseIdentifier:(NSString *)reuseIdentifier
                            block:(id)block;

#pragma mark Properties
@property (nonatomic, readonly) NSString *reuseIdentifier;
@property (nonatomic, readonly) NSPredicate *predicate;
@property (nonatomic, readonly) id block;

@end
