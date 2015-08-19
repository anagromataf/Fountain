//
//  FTMutableArray.h
//  FTFountain
//
//  Created by Tobias Kraentzer on 24.07.15.
//  Copyright © 2015 Tobias Kräntzer. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FTDataSource.h"
#import "FTReverseDataSource.h"

/** <code>FTMutableArray</code> is a subclass of <code>NSMutableArray</code> that conforms to the protocols <code>FTDataSource</code> and <code>FTReverseDataSource</code>.
 
    It is recommended to perform all operations in a block passed to <code>performBatchUpdates:</code> because also single calls of operations may cause multiple changes of the state. If thous operations are not performed in a batch update, the observer methods <code>dataSourceWillChange:</code> and <code>dataSourceDidChange:</code> are called several times. The following example would notify the observer for each insertion in a separate change notification.
 
<pre>
FTMutableArray *array = [FTMutableArray array];
        
[array addObjectsFromArray:@[@"one", @"two", @"three"]];
</pre>

    An observer would get the following sequence of method calls:
 
<ul>
 <li>dataSourceWillChange:</li>
  <li>dataSource:didInsertItemsAtIndexPaths:</li>
  <li>dataSourceDidChange:</li>
 <li>dataSourceWillChange:</li>
 <li>dataSource:didInsertItemsAtIndexPaths:</li>
 <li>dataSourceDidChange:</li>
 <li>dataSourceWillChange:</li>
 <li>dataSource:didInsertItemsAtIndexPaths:</li>
 <li>dataSourceDidChange:</li>
 </ul>

 Nesting the operation into a batch update would result into the following sequence.
 
<pre>
FTMutableArray *array = [FTMutableArray array];
 
[array performBatchUpdates:^{
 
    [array addObjectsFromArray:@[@"one", @"two", @"three"]];

}];
</pre>
 
 <ul>
 <li>dataSourceWillChange:</li>
 <li>dataSource:didInsertItemsAtIndexPaths:</li>
 <li>dataSource:didInsertItemsAtIndexPaths:</li>
 <li>dataSource:didInsertItemsAtIndexPaths:</li>
 <li>dataSourceDidChange:</li>
 </ul>
 
 */
@interface FTMutableArray : NSMutableArray <FTDataSource, FTReverseDataSource>

#pragma mark Batch Updates

/** Combines multiple insert, delete, and replace operations to one change.
 
    You can use this method in cases where you want to make multiple changes to the array and want to treat them as a single change. Use the blocked passed in the updates parameter to specify all of the operations you want to perform. The observer methods <code>dataSourceWillChange:</code> and <code>dataSourceDidChange:</code> are only called once for all operations performed in the batch update.
 
    @note This method may safely be called reentrantly.
 
    @param updates The block that performs the relevant insert, delete, and replace operations.
 */
- (void)performBatchUpdates:(void (^)(void))updates;

@end
