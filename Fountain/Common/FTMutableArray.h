//
//  FTMutableArray.h
//  Fountain
//
//  Created by Tobias Kraentzer on 24.07.15.
//  Copyright © 2015 Tobias Kräntzer. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FTDataSource.h"
#import "FTReverseDataSource.h"

/*! <code>FTMutableArray</code> is a subclass of <code>NSMutableArray</code> that conforms
    to the <code>FTDataSource</code> and the <code>FTReverseDataSource</code> protocols.
 */
@interface FTMutableArray : NSMutableArray <FTDataSource, FTReverseDataSource>

- (void)replaceAllObejctsWithObjects:(NSArray *)objects;

@end
