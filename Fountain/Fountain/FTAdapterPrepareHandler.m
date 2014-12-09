//
//  FTAdapterPrepareHandler.m
//  Fountain
//
//  Created by Tobias Kräntzer on 09.12.14.
//  Copyright (c) 2014 Tobias Kräntzer. All rights reserved.
//

#import "FTAdapterPrepareHandler.h"

@implementation FTAdapterPrepareHandler

#pragma mark Life-cycle

- (instancetype)initWithPredicate:(NSPredicate *)predicate
                  reuseIdentifier:(NSString *)reuseIdentifier
                            block:(id)block
{
    self = [super init];
    if (self) {
        _predicate = predicate;
        _reuseIdentifier = reuseIdentifier;
        _block = block;
    }
    return self;
}

@end
