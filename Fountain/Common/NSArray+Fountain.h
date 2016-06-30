//
//  NSArray+Fountain.h
//  Fountain
//
//  Created by Tobias Kraentzer on 10.06.16.
//  Copyright © 2016 Tobias Kräntzer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (Fountain)

// Returns sorted array of the objects of the given set ordered by the sort descriptors. If the sort
// order of two objects is ambiguous, used the given reference array as a hint for the order.
+ (NSArray *)ft_arrayBySortingObjects:(NSSet *)objects
                   usingSortDescriptors:(NSArray *)sortDescriptors
    orderAmbiguousObjectsByOrderInArray:(NSArray *)referenceArray;

+ (NSArray *)ft_arrayBySortingObjects:(NSSet *)objects
                       byOrderInArray:(NSArray *)referenceArray;

@end
