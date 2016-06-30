//
//  FTTestClusterComperator.m
//  FTFountain
//
//  Created by Tobias Kraentzer on 27.08.15.
//  Copyright (c) 2015 Tobias Kräntzer. All rights reserved.
//

#import "FTTestItem.h"

#import "FTTestItemClusterComperator.h"

@implementation FTTestItemClusterComperator

- (BOOL)compareObject:(FTTestItem *)object1 toObject:(FTTestItem *)object2
{
    return labs(object1.value - object2.value) < 10;
}

@end
