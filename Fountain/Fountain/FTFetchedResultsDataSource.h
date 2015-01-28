//
//  FTFetchedResultsDataSource.h
//  Fountain
//
//  Created by Tobias Kraentzer on 12.01.15.
//  Copyright (c) 2015 Tobias Kräntzer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "FTDataSource.h"

@interface FTFetchedResultsDataSource : NSObject <FTDataSource>

#pragma mark Life-cycle
- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)context
                                     request:(NSFetchRequest *)request
                          sectionNameKeyPath:(NSString *)sectionNameKeyPath;

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)context
                                     request:(NSFetchRequest *)request
                 sectionAttributeDescription:(NSAttributeDescription *)attributeDescription;

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)context
                                     request:(NSFetchRequest *)request
              sectionRelationshipDescription:(NSRelationshipDescription *)relationshipDescription;

#pragma mark Context & Request
@property (nonatomic, readonly) NSManagedObjectContext *context;
@property (nonatomic, readonly) NSFetchRequest *request;

@end
