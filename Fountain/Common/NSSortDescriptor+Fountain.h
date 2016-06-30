//
//  NSSortDescriptor+Fountain.h
//  Fountain
//
//  Created by Tobias Kraentzer on 10.06.16.
//  Copyright © 2016 Tobias Kräntzer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSSortDescriptor (Fountain)

+ (NSComparator)ft_comperatorUsingSortDescriptors:(NSArray *)sortDescriptors;

@end
