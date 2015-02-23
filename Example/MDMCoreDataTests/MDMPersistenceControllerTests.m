//
//  MDMPersistenceControllerTests.m
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

#import <XCTest/XCTest.h>
#import <MDMCoreData.h>

NSString * const kTestEntityName = @"Test";

@interface MDMPersistenceControllerTests : XCTestCase

@property (nonatomic, strong) MDMPersistenceController *persistenceController;
@property (nonatomic, strong) NSURL *storeURL;
@property (nonatomic) NSUInteger notificationCounter;
@property (nonatomic, strong) XCTestExpectation *backgroundSaveNotificationExpectation;

@end

@implementation MDMPersistenceControllerTests

- (void)setUp {
    
    [super setUp];
    
    self.notificationCounter = 0;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedNotification) name:MDMPersistenceControllerDidInitialize object:nil];
    
    self.storeURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"test.sqlite"]];
    
    // Build model programmatically
    NSManagedObjectModel *mom = [[NSManagedObjectModel alloc] init];
    NSEntityDescription *testEntity = [[NSEntityDescription alloc] init];
    [testEntity setName:kTestEntityName];
    NSAttributeDescription *stringAttribute = [[NSAttributeDescription alloc] init];
    [stringAttribute setName:@"testString"];
    [stringAttribute setAttributeType:NSStringAttributeType];
    [testEntity setProperties:@[stringAttribute]];
    [mom setEntities:@[testEntity]];
    
    self.persistenceController = [[MDMPersistenceController alloc] initWithStoreURL:self.storeURL model:mom];
}

- (void)tearDown {

    [super tearDown];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // Delete temp SQLite files
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *storeDirectory = [self.storeURL URLByDeletingLastPathComponent];
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtURL:storeDirectory
                                          includingPropertiesForKeys:nil
                                                             options:0
                                                        errorHandler:NULL];
    NSString *storeName = [self.storeURL.lastPathComponent stringByDeletingPathExtension];
    for (NSURL *url in enumerator) {
        if ([url.lastPathComponent hasPrefix:storeName] == NO) {
            continue;
        }
        [fileManager removeItemAtURL:url error:NULL];
    }
}

- (void)testInitializer {
    
    XCTAssertNotNil(self.persistenceController, @"Should have a persistence controller");
}

- (void)testManagedObjectContext {
    
    XCTAssertNotNil(self.persistenceController.managedObjectContext, @"Should have a managed object context");
    XCTAssertNotNil(self.persistenceController.managedObjectContext.parentContext, @"Should have a parent managed object context");
    XCTAssertNotNil(self.persistenceController.managedObjectContext.parentContext.persistentStoreCoordinator, @"Should have a persistent store coordinator");
    NSPersistentStore *persistentStore = self.persistenceController.managedObjectContext.parentContext.persistentStoreCoordinator.persistentStores[0];
    XCTAssertNotNil(persistentStore, @"Should have a persistent store");
    XCTAssertEqualObjects(persistentStore.type, NSSQLiteStoreType, @"Should be a SQLite store");
    XCTAssertNil(self.persistenceController.managedObjectContext.undoManager, @"Should not have an undo manager");
}

- (void)testPrivateChildManagedObjectContext {
    
    NSManagedObjectContext *privateContext = [self.persistenceController newPrivateChildManagedObjectContext];
    XCTAssertNotNil(privateContext, @"Should have a managed object context");
    XCTAssertEqualObjects(privateContext.parentContext, self.persistenceController.managedObjectContext, @"Should have a parent context");
}

- (void)testChildManagedObjectContext {
    
    NSManagedObjectContext *childContext = [self.persistenceController newChildManagedObjectContext];
    XCTAssertNotNil(childContext, @"Should have a managed object context");
    XCTAssertEqualObjects(childContext.parentContext, self.persistenceController.managedObjectContext, @"Should have a parent context");
}

- (void)testInitializationNotification {
 
    XCTAssertEqual((NSUInteger)1, self.notificationCounter, @"Should have received 1 notification that the persistence controller initialized");
}

- (void)testSaveContext {
 
    NSEntityDescription *testEntityDescription = [NSEntityDescription entityForName:kTestEntityName
                                                             inManagedObjectContext:self.persistenceController.managedObjectContext];
    NSManagedObject *testObject = [[NSManagedObject alloc] initWithEntity:testEntityDescription
                                           insertIntoManagedObjectContext:self.persistenceController.managedObjectContext];
    [testObject setValue:@"dummy" forKey:@"testString"];
    
    XCTAssertNotNil(testObject, @"Should not have nil object");
    
    [self.persistenceController saveContextAndWait:YES completion:nil];
    [self.persistenceController.managedObjectContext reset];
    
    NSFetchRequest *fetchRequst = [[NSFetchRequest alloc] initWithEntityName:[testEntityDescription name]];
    NSArray *results = [self.persistenceController.managedObjectContext executeFetchRequest:fetchRequst error:NULL];
    NSManagedObject *persistedTestObject = [results lastObject];
    
    XCTAssertEqual([results count], (NSUInteger)1, @"Should have one item");
    XCTAssertEqualObjects([persistedTestObject valueForKey:@"testString"], @"dummy", @"Should have a value of dummy");
}

- (void)receivedNotification {
 
    self.notificationCounter += 1;
}

- (void)testDeleteAndSave {
    
    NSEntityDescription *testEntityDescription = [NSEntityDescription entityForName:kTestEntityName
                                                             inManagedObjectContext:self.persistenceController.managedObjectContext];
    NSManagedObject *testObject = [[NSManagedObject alloc] initWithEntity:testEntityDescription
                                           insertIntoManagedObjectContext:self.persistenceController.managedObjectContext];
    [testObject setValue:@"dummy" forKey:@"testString"];
    
    XCTAssertNotNil(testObject, @"Should not have nil object");
    
    [self.persistenceController saveContextAndWait:YES completion:nil];
    
    [self.persistenceController deleteObject:testObject saveContextAndWait:YES completion:nil];
    
    NSFetchRequest *fetchRequst = [[NSFetchRequest alloc] initWithEntityName:[testEntityDescription name]];
    NSArray *results = [self.persistenceController.managedObjectContext executeFetchRequest:fetchRequst error:NULL];
    
    XCTAssertEqual(results, @[], @"Results should be empty");
}

- (void)testExecuteFetchRequest {
    
    NSEntityDescription *testEntityDescription = [NSEntityDescription entityForName:kTestEntityName
                                                             inManagedObjectContext:self.persistenceController.managedObjectContext];
    NSManagedObject *testObject = [[NSManagedObject alloc] initWithEntity:testEntityDescription
                                           insertIntoManagedObjectContext:self.persistenceController.managedObjectContext];
    [testObject setValue:@"dummy" forKey:@"testString"];
    
    XCTAssertNotNil(testObject, @"Should not have nil object");
    
    [self.persistenceController saveContextAndWait:YES completion:nil];
    [self.persistenceController.managedObjectContext reset];
    
    NSFetchRequest *fetchRequst = [[NSFetchRequest alloc] initWithEntityName:[testEntityDescription name]];
    NSArray *results = [self.persistenceController executeFetchRequest:fetchRequst error:^(NSError *error) {
        XCTAssertNotNil(error, @"Error should never be nil here");
    }];
    NSManagedObject *persistedTestObject = [results lastObject];
    
    XCTAssertEqual([results count], (NSUInteger)1, @"Should have one item");
    XCTAssertEqualObjects([persistedTestObject valueForKey:@"testString"], @"dummy", @"Should have a value of dummy");
}

#pragma mark - PrivateManagedObjectContext With New PersistentStoreCoordinator

/** 
 Helper to create test entity. Caller should call in appropriate context queue (thread/perform block).
 */
- (void)createTestEntityObject:(NSEntityDescription *)testEntityDescription withNumberValue:(NSUInteger)value inContext:(NSManagedObjectContext *)context {
    NSManagedObject *testObject = [[NSManagedObject alloc] initWithEntity:testEntityDescription
                                           insertIntoManagedObjectContext:context];
    NSString *stringValue = [NSString stringWithFormat:@"Item%lu", (unsigned long)value];
    [testObject setValue:stringValue forKey:@"testString"];
    
    XCTAssertNotNil(testObject, @"Should not have nil object");
}

/**
 Helper to perform simple fetch operation and optionally validate object count and fetch time.
 Negative values for validateObjectCount skips validation of object count.
 Negative values for validateMaxFetchTime skips validation of fetch time.
 Caller should call in appropriate context queue (thread/perform block).
 */
- (void)fetchInContext:(NSManagedObjectContext *)context  validateObjectCount:(NSInteger)objectCount validateMaxFetchTime:(NSTimeInterval) maxFetchTime{

    NSEntityDescription *testEntityDescription = [NSEntityDescription entityForName:kTestEntityName
                                                             inManagedObjectContext:context];
    
    NSDate *fetchStartTime = [NSDate date];
    //NSLog(@"Fetch start time %@", fetchStartTime);
    NSFetchRequest *fetchRequst = [[NSFetchRequest alloc] initWithEntityName:[testEntityDescription name]];
    NSError *error;
    NSUInteger fetchedObjectCount = [context countForFetchRequest:fetchRequst error:&error];
    XCTAssert( error==nil, @"Should have succeeded fetching");
    if(objectCount>=0) {
        XCTAssertEqual(fetchedObjectCount, objectCount, @"Should have same object count");
    }
    if(maxFetchTime>=0) {
        NSTimeInterval fetchTime = -[fetchStartTime timeIntervalSinceNow];
        NSLog(@"Fetch took %f", fetchTime);
        //if time taken more than max expected then fail!
        XCTAssert( (fetchTime < maxFetchTime), @"Expected not to take more than %f seconds for fetch", maxFetchTime);
    }
    return;
}

/**
 Helper to create specified number of test entities in given context.
 This method returns after all entities are created.
 */
- (void)createTestEntitiesAndWaitWithContext:(NSManagedObjectContext *)context objectCount:(NSUInteger)objectCount {
    
    [context performBlockAndWait:^{
        //NSLog(@"Creation of %lu entities start time %@", (unsigned long)objectCount, [NSDate date]);
        NSEntityDescription *testEntityDescriptionBG = [NSEntityDescription entityForName:kTestEntityName
                                                                   inManagedObjectContext:context];
        for (NSUInteger itemIndex =1; itemIndex <=objectCount; itemIndex++) {
            [self createTestEntityObject:testEntityDescriptionBG withNumberValue:itemIndex inContext:context];
        }
        //NSLog(@"Creation of %lu entities completion time %@", (unsigned long)objectCount, [NSDate date]);
        XCTAssert(context.hasChanges, @"Should have changes for objects added in above loop");
    }];
}

/**
 Receive notification of any backgroundMOC saves and indicate fullfilment of expectation.
 */
- (void)backgroundManagedObjectContextDidSaveNotification:(NSNotification *)notification {

    [self.backgroundSaveNotificationExpectation fulfill];
}

/**
 Test fetching in foreground context without any waiting while background context is saving (writing).
 */
- (void)testPrivateManagedObjectContextWithNewPersistentStoreCoordinator {
    
    NSManagedObjectContext *foregroundMOC = self.persistenceController.managedObjectContext;
    //Register to receive background save notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(backgroundManagedObjectContextDidSaveNotification:) name:MDMIndpendentManagedObjectContextDidSaveNotification object:nil];
    
    //Initialize expectation for receiving background save notification 
    self.backgroundSaveNotificationExpectation = [self expectationWithDescription:@"Should have received background save notification"];
    
    //Create independent background context
    NSManagedObjectContext * backgroundMOC = [self.persistenceController newIndependentManagedObjectContext];
    //To test fail scenario - uncomment the below line to use a context that has the same PersistentStoreCoordinator as the foregroundMOC
    //NSManagedObjectContext *backgroundMOC = [self.persistenceController performSelector:sel_getUid("writerObjectContext")];
    XCTAssertNotNil(backgroundMOC, @"Should not fail creation of background context");
    
    //Create many objects on background context (wait for this to complete)
    NSUInteger objCountBG =1000000;
    [self createTestEntitiesAndWaitWithContext:backgroundMOC objectCount:objCountBG];
    
    //Start concurrent operations - one for background save and another for foreground fetch
    //  Time taken for foreground retrieve should not exceed 1 second (observed around 0.0002 seconds
    //  for fetch vs 12 seconds for saving 1 million Test entities on a Mac Book Pro 2.8GHz Intel Core
    //  i7 based iPhone Simulator debug mode)
    //  It is feasible to calibrate for the expected fetch time on current running device - but a max of 1 second should suffice for this test.
    
    //Concurrent Op 1: Background Save
    [backgroundMOC performBlock:^{
        NSLog(@"Background save start time %@", [NSDate date]);
        NSError *backgroundMOCError;
        [backgroundMOC save:&backgroundMOCError];
        XCTAssertNil(backgroundMOCError, @"Should not fail saving background context changes");
        NSLog(@"Background save completion time %@", [NSDate date]);
    }];
    
    //Concurrent Op 2: Foreground Fetch
    NSTimeInterval maxExpectedFetchTime = 1.0;
    NSDate * multifetchStartTime = [NSDate date];
    NSLog(@"Foreground Multiple Fetch start time %@", multifetchStartTime);
    // Looping demonstrates the typical use case where fetches continue to happen in the
    // foreground triggered by user interaction - while a background save is in progress.
    for (int index =0; index<3; index++) {
        sleep(0.05); //user interaction
        [foregroundMOC reset];
        [self fetchInContext:foregroundMOC validateObjectCount:-1.0 validateMaxFetchTime:maxExpectedFetchTime];
    }
    NSDate *multifetchCompletionTime = [NSDate date];
    NSLog(@"Foreground Multiple Fetch completion time %@. Time taken %f", multifetchCompletionTime, [multifetchCompletionTime timeIntervalSinceDate:multifetchStartTime] );

    //wait for background save to complete if still running
    [backgroundMOC performBlockAndWait:^{
        NSLog(@"Validating completion of background save operation at %@", [NSDate date]);
    }];
    
    //Validate all objects created in backgroundMOC are known to the foregroundMOC
    [foregroundMOC reset];
    [self fetchInContext:foregroundMOC validateObjectCount:objCountBG validateMaxFetchTime:-1];
    
    // Run the main queue loop for some time to allow processing of notification from background save operation completion.
    // After specified time interval if expectations not met, the test will fail specifying the failed expectation.
    [self waitForExpectationsWithTimeout:1 handler:^(NSError *error) {
    }];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MDMIndpendentManagedObjectContextDidSaveNotification object:nil];
}


@end
