# MDMCoreData

A collection of lightweight Core Data classes for iOS and OS X as seen on [NSScreencast](http://nsscreencast.com/episodes/109-mdmcoredata). Support future development of this project by purchasing [Core Data by Tutorials](http://www.raywenderlich.com/store/core-data-tutorials-ios-8-swift-edition?source=matthewmorey).

[![Version](https://cocoapod-badges.herokuapp.com/v/MDMCoreData/badge.png)](http://cocoadocs.org/docsets/MDMCoreData)
[![Platform](https://cocoapod-badges.herokuapp.com/p/MDMCoreData/badge.png)](http://cocoadocs.org/docsets/MDMCoreData)
[![License](http://img.shields.io/badge/license-MIT-green.svg?style=flat)](https://github.com/mmorey/MDMCoreData/blob/master/LICENSE)
[![Twitter: @xzolian](https://img.shields.io/badge/contact-@xzolian-blue.svg?style=flat)](https://twitter.com/xzolian)


MDMCoreData is a growing collection of classes that make working with Core Data easier. It does not try to hide Core Data but instead enforces best practices and reduce boiler plate code. It is a much better alternative to using the Xcode Core Data Template. All classes are documented and a majority are unit tested.

* __MDMPersistenceController (iOS, OS X)__ - A handy controller that sets up an efficient Core Data stack with support for creating multiple child managed object contexts. It has a built-in private managed object context that does asynchronous saving for you with a SQLite store.

* __MDMFetchedResultsTableDataSource (iOS)__ -  A class mostly full of boiler plate that implements the fetched results controller delegate and a table data source.

* __MDMFetchedResultsCollectionDataSource (iOS)__ - A class mostly full of boiler plate that implements the fetched results controller delegate and a collection data source.

* __NSManagedObject+MDMCoreDataAdditions (iOS, OS X)__ - A category on managed objects that provides helper methods for eliminating boiler plate code.

|   | iOS | OS X | Documented | Tested  |
|--:|:-:|:-:|:-:|:-:|
| __MDMPersistenceController__                    | ✓ | ✓ | ✓ | ✓ |
| __MDMFetchedResultsTableDataSource__            | ✓ |   | ✓ |   |
| __MDMFetchedResultsCollectionDataSource__       | ✓ |   | ✓ |   |
| __NSManagedObject+MDMCoreDataAdditions__        | ✓ | ✓ | ✓ |   |

## Table of Contents

* [Usage](https://github.com/mmorey/MDMCoreData#usage)
* [Installation](https://github.com/mmorey/MDMCoreData#installation)
* [Contributing](https://github.com/mmorey/MDMCoreData#contributing)
* [Author](https://github.com/mmorey/MDMCoreData#author)
* [License](https://github.com/mmorey/MDMCoreData#license)
* [Attribution](https://github.com/mmorey/MDMCoreData#attribution)

## Usage

To run the example project clone the repo and open `MDMCoreData.xcworkspace`. A video tutorial is available at [NSScreencast](http://nsscreencast.com/episodes/109-mdmcoredata).

* [MDMPersistenceController](https://github.com/mmorey/MDMCoreData#mdmpersistencecontroller)
* [MDMFetchedResultsTableDataSource](https://github.com/mmorey/MDMCoreData/blob/master/README.md#mdmfetchedresultstablecollectiondatasource)
* [MDMFetchedResultsCollectionDataSource](https://github.com/mmorey/MDMCoreData/blob/master/README.md#mdmfetchedresultstablecollectiondatasource)
* [NSManagedObject+MDMCoreDataAdditions](https://github.com/mmorey/MDMCoreData#nsmanagedobjectmdmcoredataadditions)

### MDMPersistenceController

#### Store type - SQLite (`NSSQLiteStoreType`)
The typical store type used when utilizing Core Data is `SQLite`. To create a new `MDMPersistenceController` call `initWithStoreURL:modelURL:` with the URLs of the SQLite file and data model.

```objective-c
NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"MDMCoreData.sqlite"];
NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"MDMCoreData" withExtension:@"momd"];
self.persistenceController = [[MDMPersistenceController alloc] initWithStoreURL:storeURL
                                                                       modelURL:modelURL];
```

#### Store type - InMemory (`NSInMemoryStoreType`)
An alternative (not a widely used) store type is an `InMemory` store. This type of store is particularly useful when long term persistence is not required e.g. testing.  
To create a new `MDMPersistenceController` (backed by an inMemoryStore type) call ` initInMemoryTypeWithModelURL:modelURL` with the URL of the data model.

```objective-c
NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"MDMCoreData" withExtension:@"momd"];
self.persistenceController = [[MDMPersistenceController alloc] initInMemoryTypeWithModelURL:modelURL];
```

#### Managed Object Context
Easily access the main queue managed object context via the public `managedObjectContext` property.

```objective-c
self.persistenceController.managedObjectContext
```

To save changes, call `saveContextAndWait:completion:` with an optional completion block. If the first parameter is set to `NO`, saving is done asynchronously.

```objective-c
[self.persistenceController saveContextAndWait:NO completion:^(NSError *error) {

    if (error == nil) {
        NSLog(@"Successfully saved all the things!");
    }
}];
```

#### Child contexts
New child contexts can be created with the main queue or a private queue for background work.

```objective-c
NSManagedObjectContext *privateContextForScratchPadWork = [self.persistenceController newChildManagedObjectContext];

NSManagedObjectContext *privateContextForDoingBackgroundWork = [self.persistenceController newPrivateChildManagedObjectContext];
```
An independent context (a private queue with a new persistent store coordinator) can be created for scenarios where the background save (file write) operation takes significant time but should not block the fetches (file read) on the main (UI) context.

```objective-c
NSManagedObjectContext *independentContextForDoingBackgroundWork = [self.persistenceController newIndependentManagedObjectContextWithNewPersistentStoreCoordinator];
```
For more information please see the [documentation](http://cocoadocs.org/docsets/MDMCoreData).

### MDMFetchedResults[Table|Collection]DataSource

To create a new `MDMFetchedResultsTableDataSource` or `MDMFetchedResultsCollectionViewDataSource` call `initWithTableView:fetchedResultsController:` or `initWithCollectionView:fetchedResultsController:`with a table view or collection view and fetched results controller. You also need to set the `delegate` and `reuseIdentifier`.

```objective-c
self.tableDataSource = [[MDMFetchedResultsTableDataSource alloc] initWithTableView:self.tableView
                                                          fetchedResultsController:[self fetchedResultsController]];
self.tableDataSource.delegate = self;
self.tableDataSource.reuseIdentifier = @"Cell";
self.tableView.dataSource = self.tableDataSource;
```

For cell configuration and object deletion, `MDMFetchedResultsTableDataSource` requires that all `MDMFetchedResultsTableDataSourceDelegate` methods be implemented.

```objective-c
- (void)dataSource:(MDMFetchedResultsTableDataSource *)dataSource
     configureCell:(id)cell
        withObject:(id)object {

    UITableViewCell *tableCell = (UITableViewCell *)cell;
    tableCell.textLabel.text = [[object valueForKey:@"timeStamp"] description];
}

- (void)dataSource:(MDMFetchedResultsTableDataSource *)dataSource
      deleteObject:(id)object
       atIndexPath:(NSIndexPath *)indexPath {

    [self.persistenceController.managedObjectContext deleteObject:object];
}
```

During large data imports you can easily pause `MDMFetchedResultsTableDataSource` for improved performance.

```objective-c
self.tableDataSource.paused = YES;
```

For more information please see the [documentation](http://cocoadocs.org/docsets/MDMCoreData).

### NSManagedObject+MDMCoreDataAdditions

Instead of hardcoding an entity name you can call `MDMCoreDataAdditionsEntityName`.

```objective-c
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[Event MDMCoreDataAdditionsEntityName]];
```

New managed objects can be created with only one line of code.

```objective-c
Event *newEvent = [Event MDMCoreDataAdditionsInsertNewObjectIntoContext:[self.fetchedResultsController managedObjectContext]];
```

For more information please see the [documentation](http://cocoadocs.org/docsets/MDMCoreData).

## Installation

### CocoaPods

MDMCoreData is available through [CocoaPods](http://cocoapods.org), to install it simply add the following line to your Podfile.

    pod "MDMCoreData"

If you don't need everything, you can install only what you need using separate sub-pods.

    pod "MDMCoreData/MDMPersistenceController"
    pod "MDMCoreData/MDMFetchedResultsTableDataSource"

### Manually

To install manually, just copy everything in the `Classes` directory into your Xcode project.

_**Important:**_ If your project doesn't use ARC you must add the `-fobjc-arc` compiler flag to all MDMCoreData implementation files in Target Settings > Build Phases > Compile Sources.

## Contributing

Pull request are welcomed. To add functionality or to make changes:

1. Fork this repo.
2. Open `MDMCoreData.xcworkspace` in the Example directory.
3. Make changes to the necessary files in the Pods sub project.
4. Ensure new public methods are documented and tested.
5. Submit a pull request.

You can also support future development of this project by purchasing [Core Data by Tutorials](http://www.raywenderlich.com/store/core-data-tutorials-ios-8-swift-edition?source=matthewmorey).

## Author

Created by [Matthew Morey](http://matthewmorey.com), [Terry Lewis II](http://ifnotapps.com/), [Matt Glover](http://twitter.com/mattglover) and other [contributors](https://github.com/mmorey/MDMCoreData/graphs/contributors).

## License

MDMCoreData is available under the MIT license. See the [LICENSE](https://github.com/mmorey/MDMCoreData/LICENSE) file for more information. If you're using MDMCoreData in your project, attribution would be nice.

## Attribution

MDMCoreData is based on and inspired by the work of many:

* [objc.io Issue #4 Core Data](http://www.objc.io/issue-4/)
* [Marcus Zarra](https://twitter.com/mzarra)
* [High Performance Core Data](http://highperformancecoredata.com/)
* [NSScreencast](http://nsscreencast.com/episodes/109-mdmcoredata)
