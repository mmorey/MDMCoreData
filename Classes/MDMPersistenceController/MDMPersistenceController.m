//
//  MDMPersistenceController.m
//
//  Copyright (c) 2014 Matthew Morey.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "MDMPersistenceController.h"
#import "MDMCoreDataMacros.h"

NSString *const MDMPersistenceControllerDidInitialize = @"MDMPersistenceControllerDidInitialize";
NSString *const MDMIndependentManagedObjectContextDidSaveNotification = @"MDMIndependentManagedObjectContextDidSaveNotification";

@interface MDMPersistenceController ()

@property (nonatomic, strong, readwrite) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSManagedObjectContext *writerObjectContext;
@property (nonatomic, copy) NSString *storeType;
@property (nonatomic, strong) NSURL *storeURL;
@property (nonatomic, strong) NSManagedObjectModel *model;

@end

@implementation MDMPersistenceController

- (instancetype)initWithStoreURL:(NSURL *)storeURL model:(NSManagedObjectModel *)model {
    
    self = [super init];
    if (self) {
        _storeType = NSSQLiteStoreType;
        _storeURL = storeURL;
        _model = model;
        if ([self setupPersistenceStack] == NO) {
            return nil;
        }
    }
    
    return self;
}

- (instancetype)initInMemoryTypeWithModel:(NSManagedObjectModel *)model {
    
    self = [super init];
    if (self) {
        _storeType = NSInMemoryStoreType;
        _model = model;
        if ([self setupPersistenceStack] == NO) {
            return nil;
        }
    }
    
    return self;
}

- (instancetype)initWithStoreURL:(NSURL *)storeURL modelURL:(NSURL *)modelURL {
    
    NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    ZAssert(model, @"ERROR: NSManagedObjectModel is nil");
    
    return [self initWithStoreURL:storeURL model:model];
}

- (instancetype)initInMemoryTypeWithModelURL:(NSURL *)modelURL {
    
    NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    ZAssert(model, @"ERROR: NSManagedObjectModel is nil");
    
    return [self initInMemoryTypeWithModel:model];
}

- (instancetype)init {
    
    ALog(@"ERROR: Ensure MDMPersistenceController is instantiated using the designated initializer(s)");
    
    return nil;
}

- (NSPersistentStoreCoordinator *)setupNewPersistentStoreCoordinatorWithStoreType:(NSString *)storeType {
    
    if (self.model == nil) {
        // App is useless without a data model
        ALog(@"ERROR: Cannot create a new persistent store coordinator as model is nil");
        return nil;
    }
    
    // Create persistent store coordinator
    NSPersistentStoreCoordinator *persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.model];
    ZAssert(persistentStoreCoordinator, @"ERROR: NSPersistentStoreCoordinator is nil");
    
    // Add persistent store to store coordinator
    NSDictionary *persistentStoreOptions = @{ // Light migration
                                             NSInferMappingModelAutomaticallyOption:@YES,
                                             NSMigratePersistentStoresAutomaticallyOption:@YES
                                             };
    NSError *persistentStoreError;
    NSPersistentStore *persistentStore = [persistentStoreCoordinator addPersistentStoreWithType:storeType
                                                                                  configuration:nil
                                                                                            URL:self.storeURL
                                                                                        options:persistentStoreOptions
                                                                                          error:&persistentStoreError];
    if (persistentStore == nil && [storeType isEqualToString:NSSQLiteStoreType]) {
        
        // Model has probably changed, lets delete the old one and try again
        NSError *removeSQLiteFilesError = nil;
        if ([self removeSQLiteFilesAtStoreURL:self.storeURL error:&removeSQLiteFilesError]) {
            
            persistentStoreError = nil;
            persistentStore = [persistentStoreCoordinator addPersistentStoreWithType:storeType
                                                                       configuration:nil
                                                                                 URL:self.storeURL
                                                                             options:persistentStoreOptions
                                                                               error:&persistentStoreError];
        } else {
            
            ALog(@"ERROR: Could not remove SQLite files\n%@", [removeSQLiteFilesError localizedDescription]);
            
            return nil;
        }
    }
    
    if (persistentStore == nil) {
        
        // Something really bad is happening
        ALog(@"ERROR: NSPersistentStore is nil: %@\n%@", [persistentStoreError localizedDescription], [persistentStoreError userInfo]);
        
        return nil;
    }
    
    return persistentStoreCoordinator;
}

- (BOOL)setupPersistenceStack {

    // Setup persistent store coordinator
    NSPersistentStoreCoordinator *persistentStoreCoordinator = [self setupNewPersistentStoreCoordinatorWithStoreType:self.storeType];
    if (persistentStoreCoordinator == nil) {
        return NO;
    }
    
    // Create managed object contexts
    self.writerObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [self.writerObjectContext setPersistentStoreCoordinator:persistentStoreCoordinator];
    if (self.writerObjectContext == nil) {
        
        // App is useless if a writer managed object context cannot be created
        ALog(@"ERROR: NSManagedObjectContext is nil");
        
        return NO;
    }
    
    self.managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [self.managedObjectContext setParentContext:self.writerObjectContext];
    if (self.managedObjectContext == nil) {
        
        // App is useless if a managed object context cannot be created
        ALog(@"ERROR: NSManagedObjectContext is nil");
        
        return NO;
    }
    
    // Context is fully initialized, notify view controllers
    [self persistenceStackInitialized];
    
    return YES;
}

- (BOOL)removeSQLiteFilesAtStoreURL:(NSURL *)storeURL error:(NSError * __autoreleasing *)error {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *storeDirectory = [storeURL URLByDeletingLastPathComponent];
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtURL:storeDirectory
                                          includingPropertiesForKeys:nil
                                                             options:0
                                                        errorHandler:nil];
    
    NSString *storeName = [storeURL.lastPathComponent stringByDeletingPathExtension];
    for (NSURL *url in enumerator) {
        
        if ([url.lastPathComponent hasPrefix:storeName] == NO) {
            continue;
        }
        
        NSError *fileManagerError = nil;
        if ([fileManager removeItemAtURL:url error:&fileManagerError] == NO) {
           
            if (error != NULL) {
                *error = fileManagerError;
            }
            
            return NO;
        }
    }
    
    return YES;
}

- (void)saveContextAndWait:(BOOL)wait completion:(void (^)(NSError *error))completion {
    
    if ([self managedObjectContextHasChanges:self.managedObjectContext] || [self managedObjectContextHasChanges:self.writerObjectContext]) {
        
        [self.managedObjectContext performBlockAndWait:^{
            
            NSError *mainContextSaveError = nil;
            if ([self.managedObjectContext save:&mainContextSaveError] == NO) {
                
                ALog(@"ERROR: Could not save managed object context -  %@\n%@", [mainContextSaveError localizedDescription], [mainContextSaveError userInfo]);
                if (completion) {
                    completion(mainContextSaveError);
                }
                return;
            }
            
            if ([self managedObjectContextHasChanges:self.writerObjectContext]) {
               
                if (wait) {
                    [self.writerObjectContext performBlockAndWait:[self savePrivateWriterContextBlockWithCompletion:completion]];
                } else {
                    [self.writerObjectContext performBlock:[self savePrivateWriterContextBlockWithCompletion:completion]];
                }
                
                return;
            }
            
            if (completion) {
                completion(nil);
            }
        }]; // Managed Object Context block
    } else {
        // No changes to either managedObjectContext or writerObjectContext
        if (completion) {
            completion(nil);
        }
    }
}

- (BOOL)managedObjectContextHasChanges:(NSManagedObjectContext *)context {
    
    __block BOOL hasChanges;
    
    [context performBlockAndWait:^{
        hasChanges = [context hasChanges];
    }];
    
    return hasChanges;
    
}

- (void(^)())savePrivateWriterContextBlockWithCompletion:(void (^)(NSError *))completion {
    
    void (^savePrivate)(void) = ^{
        
        NSError *privateContextError = nil;
        if ([self.writerObjectContext save:&privateContextError] == NO) {
            
            ALog(@"ERROR: Could not save managed object context - %@\n%@", [privateContextError localizedDescription], [privateContextError userInfo]);
            if (completion) {
                completion(privateContextError);
            }
        } else {
            if (completion) {
                completion(nil);
            }
        }
    };
    
    return savePrivate;
}

#pragma mark - Child NSManagedObjectContext

- (NSManagedObjectContext *)newPrivateChildManagedObjectContext {
    
    NSManagedObjectContext *privateChildManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [privateChildManagedObjectContext setParentContext:self.managedObjectContext];
    
    return privateChildManagedObjectContext;
}

- (NSManagedObjectContext *)newChildManagedObjectContext {
    
    NSManagedObjectContext *childManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [childManagedObjectContext setParentContext:self.managedObjectContext];
    
    return childManagedObjectContext;
}

#pragma mark - Independent Context 

- (NSManagedObjectContext *)newIndependentManagedObjectContext {
    //Based on https://github.com/mmorey/MDMHPCoreData
    
    if (self.managedObjectContext == nil) {
        // The primary persistent stack should have been initialized as part of this object's initialization - did it fail?
        ALog(@"WARNING: Main context should have already been initialized by now!");
        //return nil;
    }
    
    // Setup new persistent store coordinator
    NSPersistentStoreCoordinator *persistentStoreCoordinator = [self setupNewPersistentStoreCoordinatorWithStoreType:self.storeType];
    if (persistentStoreCoordinator == nil) {
        return nil;
    }
    
    // Create private managed object context
    NSManagedObjectContext *privateContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [privateContext setPersistentStoreCoordinator:persistentStoreCoordinator];
    if (privateContext == nil) {
        ALog(@"ERROR: Failed to create managed object context");
        return nil;
    }
    
    // Setup observer to receive this context's save operation completion and further broadcast using predefined notification name.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(independentManagedObjectContextDidSaveNotification:)
                                                 name:NSManagedObjectContextDidSaveNotification
                                               object:privateContext];

    return privateContext;
}

/**
 Called whenever any independent context (created thru this class) completes save operation and further
 broadcasts using a predefined notification name.
 */
- (void)independentManagedObjectContextDidSaveNotification:(NSNotification *)notification {

    if([NSThread isMainThread] == NO) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:MDMIndependentManagedObjectContextDidSaveNotification
                                                                object:notification.object];
        });
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:MDMIndependentManagedObjectContextDidSaveNotification
                                                        object:notification.object];
    }
}

#pragma mark - NSNotificationCenter

- (void)persistenceStackInitialized {
    
    if ([NSThread isMainThread] == NO) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self postPersistenceStackInitializedNotification];
        });
    } else {
        [self postPersistenceStackInitializedNotification];
    }
}

- (void)postPersistenceStackInitializedNotification {
    
    [[NSNotificationCenter defaultCenter] postNotificationName:MDMPersistenceControllerDidInitialize object:self];
}

#pragma mark - Execute Fetch Request

- (NSArray *)executeFetchRequest:(NSFetchRequest *)request error:(void (^)(NSError *error))errorBlock {
    
    NSError *error;
    NSArray *results = [self.managedObjectContext executeFetchRequest:request error:&error];
    if(error && errorBlock) {
        errorBlock(error);
        return nil;
    }
    
    return results;
}

#pragma mark - Delete Object

- (void)deleteObject:(NSManagedObject *)object saveContextAndWait:(BOOL)saveAndWait completion:(void (^)(NSError *error))completion {
    
    [self.managedObjectContext deleteObject:object];
    [self saveContextAndWait:saveAndWait completion:completion];
}

@end
