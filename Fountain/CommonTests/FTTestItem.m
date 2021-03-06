//
//  FTTestItem.m
//  Fountain
//
//  Created by Tobias Kraentzer on 23.08.15.
//  Copyright (c) 2015 Tobias Kräntzer. All rights reserved.
//

#import "FTTestItem.h"

@implementation FTTestItem

- (instancetype)initWithValue:(NSInteger)value
{
    self = [super init];
    if (self) {
        _value = value;
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<FTTestItem: %p, value: %ld>", self, (long)_value];
}

@end
