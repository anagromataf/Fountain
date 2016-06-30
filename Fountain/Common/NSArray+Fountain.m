//
//  NSArray+Fountain.m
//  FTFountain
//
//  Created by Tobias Kraentzer on 10.06.16.
//  Copyright © 2016 Tobias Kräntzer. All rights reserved.
//

#import "NSArray+Fountain.h"

@implementation NSArray (Fountain)

+ (NSArray *)ft_arrayBySortingObjects:(NSSet *)objects
                   usingSortDescriptors:(NSArray *)sortDescriptors
    orderAmbiguousObjectsByOrderInArray:(NSArray *)referenceArray
{
    return [[objects allObjects] sortedArrayUsingComparator:^(id firstObject, id secondObject) {

        // Early return, if the first object is the second object

        if (firstObject == secondObject) {
            return NSOrderedSame;
        }

        // Sort objects by the sort descriptors

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

        // If the sort order is ambiguous (based on the sort descriptors),
        // order the objects by the order in the backing store.

        NSInteger firstIndex = [referenceArray indexOfObject:firstObject];
        NSInteger secondIndex = [referenceArray indexOfObject:secondObject];

        if (firstIndex == secondIndex) {
            return NSOrderedSame; // should never happen
        } else if (firstIndex < secondIndex) {
            return NSOrderedAscending;
        } else {
            return NSOrderedDescending;
        }

    }];
}

+ (NSArray *)ft_arrayBySortingObjects:(NSSet *)objects
                       byOrderInArray:(NSArray *)referenceArray
{
    return [[objects allObjects] sortedArrayUsingComparator:^(id firstObject, id secondObject) {

        // Early return, if the first object is the second object

        if (firstObject == secondObject) {
            return NSOrderedSame;
        }

        // Order the objects by the order in the backing store.

        NSInteger firstIndex = [referenceArray indexOfObject:firstObject];
        NSInteger secondIndex = [referenceArray indexOfObject:secondObject];

        if (firstIndex == secondIndex) {
            return NSOrderedSame; // should never happen
        } else if (firstIndex < secondIndex) {
            return NSOrderedAscending;
        } else {
            return NSOrderedDescending;
        }
    }];
}

@end
