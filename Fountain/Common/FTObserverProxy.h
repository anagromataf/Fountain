//
//  FTObserverProxy.h
//  Fountain
//
//  Created by Tobias Kraentzer on 25.04.16.
//  Copyright © 2016 Tobias Kräntzer. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FTDataSourceObserver.h"

/*! <code>FTObserverProxy</code> is a poxy which forwards delegate calls as invoked by the
    configured object. It can be used, if for example <code>FTMutableSet</code> is used as
    a backing sotre in another data source and the delegate calls for the data source
    changes should be forwarded to the observer of the data source.
 */
@interface FTObserverProxy : NSObject <FTDataSourceObserver>

#pragma mark Object
@property (nonatomic, weak) id object;

#pragma mark Observer
- (NSArray *)observers;
- (void)addObserver:(id<FTDataSourceObserver>)observer;
- (void)removeObserver:(id<FTDataSourceObserver>)observer;

@end
