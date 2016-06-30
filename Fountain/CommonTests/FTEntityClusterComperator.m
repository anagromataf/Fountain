//
//  FTEntityClusterComperator.m
//  FTFountain
//
//  Created by Tobias Kraentzer on 27.08.15.
//  Copyright (c) 2015 Tobias Kräntzer. All rights reserved.
//

#import "FTEntity.h"

#import "FTEntityClusterComperator.h"

@implementation FTEntityClusterComperator

- (BOOL)compareObject:(FTEntity *)object1 toObject:(FTEntity *)object2
{
    return labs([object2.value integerValue] - [object1.value integerValue]) < 10;
}

@end
