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

@interface MDMPersistenceControllerTests : XCTestCase

@property (nonatomic, strong) MDMPersistenceController *persistenceController;
@property (nonatomic, strong) NSURL *storeURL;
@property (nonatomic) NSUInteger notificationCounter;

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
    [testEntity setName:@"Test"];
    [testEntity setManagedObjectClassName:@"Test"];
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
 
    NSEntityDescription *testEntityDescription = [NSEntityDescription entityForName:@"Test"
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

@end
