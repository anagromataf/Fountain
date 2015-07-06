//
//  FTFetchedResultsDataSource.m
//  Fountain
//
//  Created by Tobias Kraentzer on 12.01.15.
//  Copyright (c) 2015 Tobias Kräntzer. All rights reserved.
//

#import <objc/runtime.h>

#import "FTFetchedResultsDataSource.h"

typedef enum {
    FTFetchedResultsDataSourceSectionBehaviourDEFAULT = 0,
    FTFetchedResultsDataSourceSectionBehaviourRELATIONSHIP,
    FTFetchedResultsDataSourceSectionBehaviourATTRIBUTE
} FTFetchedResultsDataSourceSectionBehaviour;

@interface FTFetchedResultsDataSource () <NSFetchedResultsControllerDelegate>
@property (nonatomic, readonly) NSFetchedResultsController *fetchedResultsController;

#pragma mark Section Behaviour
@property (nonatomic, readonly) FTFetchedResultsDataSourceSectionBehaviour sectionBehaviour;
@property (nonatomic, readonly) NSAttributeDescription *sectionAttributeDescription;
@end

@implementation FTFetchedResultsDataSource {
    NSHashTable *_observers;
}

#pragma mark Life-cycle

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)context
                                     request:(NSFetchRequest *)request
                          sectionNameKeyPath:(NSString *)sectionNameKeyPath
{
    return [self initWithManagedObjectContext:context
                                      request:request
                           sectionNameKeyPath:sectionNameKeyPath
                             sectionBehaviour:FTFetchedResultsDataSourceSectionBehaviourDEFAULT];
}

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)context
                                     request:(NSFetchRequest *)request
                          sectionNameKeyPath:(NSString *)sectionNameKeyPath
                            sectionBehaviour:(FTFetchedResultsDataSourceSectionBehaviour)sectionBehaviour
{
    self = [super init];
    if (self) {
        _observers = [NSHashTable weakObjectsHashTable];
        _context = context;
        _request = request;
        _sectionBehaviour = sectionBehaviour;
        
        _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:self.request
                                                                        managedObjectContext:self.context
                                                                          sectionNameKeyPath:sectionNameKeyPath
                                                                                   cacheName:nil];
        _fetchedResultsController.delegate = self;
    }
    return self;
}

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)context
                                     request:(NSFetchRequest *)request
                 sectionAttributeDescription:(NSAttributeDescription *)attributeDescription
{
    NSParameterAssert(attributeDescription.attributeType != NSUndefinedAttributeType);
    NSParameterAssert(attributeDescription.attributeType != NSObjectIDAttributeType);
    NSParameterAssert(attributeDescription.attributeType != NSTransformableAttributeType);
    NSParameterAssert(attributeDescription.attributeType != NSBinaryDataAttributeType);
    NSParameterAssert(attributeDescription.attributeType != NSDecimalAttributeType);
    NSParameterAssert([request.entityName isEqual:attributeDescription.entity.name]);
    
    NSString *sectionKeyPath = [NSString stringWithFormat:@"FTFetchedResultsDataSource_%@_%@", attributeDescription.entity.name, attributeDescription.name];
    Class managedObjectClass = NSClassFromString([attributeDescription.entity managedObjectClassName]);
    SEL selector = NSSelectorFromString(sectionKeyPath);
    
    if ([managedObjectClass instancesRespondToSelector:selector] == NO) {
        
        switch (attributeDescription.attributeType) {
                
            case NSInteger16AttributeType:
            case NSInteger32AttributeType:
            case NSInteger64AttributeType:
            case NSDoubleAttributeType:
            case NSFloatAttributeType:
            case NSBooleanAttributeType:
            {
                class_addMethod(managedObjectClass, selector, imp_implementationWithBlock(^(NSManagedObject *self) {
                    NSNumber *value = [self valueForKey:attributeDescription.name];
                    if (value) {
                        return [value stringValue];
                    } else {
                        return @"";
                    }
                }), "@@:");
                break;
            }
                
            case NSDateAttributeType:
            {
                class_addMethod(managedObjectClass, selector, imp_implementationWithBlock(^(NSManagedObject *self) {
                    NSDate *value = [self valueForKey:attributeDescription.name];
                    if (value) {
                        NSTimeInterval timeInterval = [value timeIntervalSinceReferenceDate];
                        return [NSString stringWithFormat:@"%lf", timeInterval];
                    } else {
                        return @"";
                    }
                }), "@@:");
                break;
            }
                
            case NSStringAttributeType:
            default:
            {
                class_addMethod(managedObjectClass, selector, imp_implementationWithBlock(^(NSManagedObject *self) {
                    return [self valueForKey:attributeDescription.name];
                }), "@@:");
                break;
            }
        }
    }
    
    self = [self initWithManagedObjectContext:context
                                      request:request
                           sectionNameKeyPath:sectionKeyPath
                             sectionBehaviour:FTFetchedResultsDataSourceSectionBehaviourATTRIBUTE];
    if (self) {
        _sectionAttributeDescription = attributeDescription;
    }
    return self;
}


- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)context
                                     request:(NSFetchRequest *)request
              sectionRelationshipDescription:(NSRelationshipDescription *)relationshipDescription
{
    NSParameterAssert([request.entityName isEqual:relationshipDescription.entity.name]);
    NSParameterAssert([relationshipDescription isToMany] == NO);
    
    NSString *sectionKeyPath = [NSString stringWithFormat:@"FTFetchedResultsDataSource_%@_%@", relationshipDescription.entity.name, relationshipDescription.name];
    
    Class managedObjectClass = NSClassFromString([relationshipDescription.entity managedObjectClassName]);
    SEL selector = NSSelectorFromString(sectionKeyPath);
    
    if ([managedObjectClass instancesRespondToSelector:selector] == NO) {
        class_addMethod(managedObjectClass, selector, imp_implementationWithBlock(^(NSManagedObject *self) {
            NSManagedObject *relatedObject = [self valueForKey:relationshipDescription.name];
            if (relatedObject) {
                return [[relatedObject.objectID URIRepresentation] absoluteString];
            } else {
                return @"";
            }
        }), "@@:");
    }
    
    return [self initWithManagedObjectContext:context
                                      request:request
                           sectionNameKeyPath:sectionKeyPath
                             sectionBehaviour:FTFetchedResultsDataSourceSectionBehaviourRELATIONSHIP];
}

#pragma mark Getting Item and Section Metrics

- (NSInteger)numberOfSections
{
    return [self.fetchedResultsController.sections count];
}

- (NSInteger)numberOfItemsInSection:(NSInteger)section
{
    id<NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController.sections objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

#pragma mark Getting Items and Index Paths

- (id)itemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.fetchedResultsController objectAtIndexPath:indexPath];
}

- (NSArray *)indexPathsOfItem:(id)item
{
    NSIndexPath *indexPath = [self.fetchedResultsController indexPathForObject:item];
    if (indexPath) {
        return @[indexPath];
    } else {
        return @[];
    }
}

#pragma mark Getting Section Item

- (id)itemForSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController.sections objectAtIndex:section];
    if (sectionInfo) {
        switch (self.sectionBehaviour) {
            case FTFetchedResultsDataSourceSectionBehaviourRELATIONSHIP:
                if ([sectionInfo.name hasPrefix:@"x-coredata://"]) {
                    NSURL *URL = [NSURL URLWithString:sectionInfo.name];
                    NSManagedObjectID *managedObjectID = [self.context.persistentStoreCoordinator managedObjectIDForURIRepresentation:URL];
                    NSError *error = nil;
                    NSManagedObject *sectionObject = [self.context existingObjectWithID:managedObjectID error:&error];
                    NSAssert(error == nil, [error localizedDescription]);
                    return sectionObject;
                } else {
                    return nil;
                }
                
            case FTFetchedResultsDataSourceSectionBehaviourATTRIBUTE:
                if ([sectionInfo.name length] == 0) {
                    return nil;
                } else {
                    switch (self.sectionAttributeDescription.attributeType) {
                        case NSInteger16AttributeType:
                        case NSInteger32AttributeType:
                        case NSInteger64AttributeType:
                            return @([sectionInfo.name integerValue]);
                            
                        case NSDoubleAttributeType:
                        case NSFloatAttributeType:
                            return @([sectionInfo.name doubleValue]);
                            
                        case NSBooleanAttributeType:
                            return @([sectionInfo.name boolValue]);
                            
                        case NSDateAttributeType:
                            return [NSDate dateWithTimeIntervalSinceReferenceDate:[sectionInfo.name doubleValue]];
                            
                        default:
                            return sectionInfo.name;
                    }
                }
                
            default:
                return sectionInfo.name;
                break;
        }
    } else {
        return nil;
    }
}

- (NSIndexSet *)sectionsForItem:(id)item
{
    return [NSIndexSet indexSet];
}

#pragma mark Relaod

- (void)reloadWithCompletionHandler:(void(^)(BOOL success, NSError *error))completionHandler
{
    for (id<FTDataSourceObserver> observer in self.observers) {
        if ([observer respondsToSelector:@selector(dataSourceWillReload:)]) {
            [observer dataSourceWillReload:self];
        }
    }
    
    NSError *error = nil;
    BOOL success = [self.fetchedResultsController performFetch:&error];
    
    for (id<FTDataSourceObserver> observer in self.observers) {
        if ([observer respondsToSelector:@selector(dataSourceDidReload:)]) {
            [observer dataSourceDidReload:self];
        }
    }
    
    if (completionHandler) {
        completionHandler(success, error);
    }
}

#pragma mark Observer

- (NSArray *)observers
{
    return [_observers allObjects];
}

- (void)addObserver:(id<FTDataSourceObserver>)observer
{
    [_observers addObject:observer];
}

- (void)removeObserver:(id<FTDataSourceObserver>)observer
{
    [_observers removeObject:observer];
}

#pragma mark NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    for (id<FTDataSourceObserver> observer in self.observers) {
        if ([observer respondsToSelector:@selector(dataSourceWillChange:)]) {
            [observer dataSourceWillChange:self];
        }
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch (type) {
        case NSFetchedResultsChangeInsert:
            for (id<FTDataSourceObserver> observer in self.observers) {
                if ([observer respondsToSelector:@selector(dataSource:didInsertSections:)]) {
                    [observer dataSource:self didInsertSections:[NSIndexSet indexSetWithIndex:sectionIndex]];
                }
            }
            break;
            
        case NSFetchedResultsChangeDelete:
            for (id<FTDataSourceObserver> observer in self.observers) {
                if ([observer respondsToSelector:@selector(dataSource:didDeleteSections:)]) {
                    [observer dataSource:self didInsertSections:[NSIndexSet indexSetWithIndex:sectionIndex]];
                }
            }
            break;
        
        default:
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    switch (type) {
        case NSFetchedResultsChangeInsert:
            for (id<FTDataSourceObserver> observer in self.observers) {
                if ([observer respondsToSelector:@selector(dataSource:didInsertItemsAtIndexPaths:)]) {
                    [observer dataSource:self didInsertItemsAtIndexPaths:@[newIndexPath]];
                }
            }
            break;
            
        case NSFetchedResultsChangeMove:
            for (id<FTDataSourceObserver> observer in self.observers) {
                if ([observer respondsToSelector:@selector(dataSource:didMoveItemAtIndexPath:toIndexPath:)]) {
                    [observer dataSource:self didMoveItemAtIndexPath:indexPath toIndexPath:newIndexPath];
                }
            }
            break;
            
        case NSFetchedResultsChangeDelete:
            for (id<FTDataSourceObserver> observer in self.observers) {
                if ([observer respondsToSelector:@selector(dataSource:didDeleteItemsAtIndexPaths:)]) {
                    [observer dataSource:self didDeleteItemsAtIndexPaths:@[indexPath]];
                }
            }
            break;
            
        case NSFetchedResultsChangeUpdate:
            for (id<FTDataSourceObserver> observer in self.observers) {
                if ([observer respondsToSelector:@selector(dataSource:didReloadItemsAtIndexPaths:)]) {
                    [observer dataSource:self didReloadItemsAtIndexPaths:@[indexPath]];
                }
            }
            break;
            
        default:
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    for (id<FTDataSourceObserver> observer in self.observers) {
        if ([observer respondsToSelector:@selector(dataSourceDidChange:)]) {
            [observer dataSourceDidChange:self];
        }
    }
}


@end
