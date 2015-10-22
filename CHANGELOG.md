# MDMCoreData CHANGELOG

## 1.5.1
* Fixed cell move issue (http://www.hitmaroc.net/1166896-9192-how-reload-programmatically-moved-row.html)

## 1.5.0
* Added NSInMemoryStoreType option (Matt Glover)
* Cleaned up method names (Parmeshwar Bayappu)

## 1.4.0
* Added feature: Create a new independent managed object context with a concurrency type of
NSPrivateQueueConcurrencyType using the same managed object model and persistent store as
the main context but a NEW persistent store coordinator. This is useful when performing
large (time consuming) updates to the database in the background. The main context can
continue to read from the store but will have to wait to perform any updates - this uses
the WAL feature of SQLite (default SQLite mode from iOS7 onwards). (Parmeshwar Bayappu)

## 1.3.5
* Import UIKit now that new Xcode projects don't come with precompiled headers (Dan Berry)

## 1.3.4
* Concurrency fixes (thanks Craig Marvelley)
* Example project Cocoapods fixes

## 1.3.3
* Call completion block if writerObjectContext doesn't have changes to save (thanks Craig Marvelley).

## 1.3.2
* Minor README updates
* Check for block existence before calling it

## 1.3.1
* Calling completion(nil) in the event of no changes to MOC or WOC
* Removed check for self.managedObjectContext
* Created assertion if init is called on MDMPersistanceController

## 1.3.0
* Added delegate call back support for multiple reuse identifiers for MDMFetchedResultsTableDataSource

## 1.2.0
* Add supplement view support to MDMFetchedResultsCollectionDataSource
* Added delegate call back support for multiple reuse identifiers for MDMFetchedResultsCollectionDataSource

## 1.1.1
* Improved the way UITableView rows are moved

## 1.1.0
* Added collection view data source and an example

## 1.0.1
* Fixed table view data source init bug

## 1.0.0
* Initial release
