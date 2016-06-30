//
//  NSSortDescriptor+Fountain.m
//  Fountain
//
//  Created by Tobias Kraentzer on 10.06.16.
//  Copyright © 2016 Tobias Kräntzer. All rights reserved.
//

#import "NSSortDescriptor+Fountain.h"

@implementation NSSortDescriptor (Fountain)

+ (NSComparator)ft_comperatorUsingSortDescriptors:(NSArray *)sortDescriptors
{
    return ^(id firstObject, id secondObject) {
        for (NSSortDescriptor *sortDescriptor in sortDescriptors) {
            NSComparisonResult result = [sortDescriptor compareObject:firstObject toObject:secondObject];
            switch (result) {
            case NSOrderedAscending:
            case NSOrderedDescending:
                return result;
            default:
                break;
            }
        }
        return NSOrderedSame;
    };
}

@end
