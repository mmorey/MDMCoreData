# MDMCoreData CHANGELOG

## 1.0.0

* Initial release.

## 1.0.1
* Fixed table view data source init bug

## 1.1.0
* Added collection view data source and an example

## 1.1.1
* Improved the way UITableView rows are moved

## 1.2.0
* Add supplement view support to MDMFetchedResultsCollectionDataSource
* Added delegate call back support for multiple reuse identifiers for MDMFetchedResultsCollectionDataSource

## 1.3.0
* Added delegate call back support for multiple reuse identifiers for MDMFetchedResultsTableDataSource

## 1.3.1
* Calling completion(nil) in the event of no changes to MOC or WOC
* Removed check for self.managedObjectContext
* Created assertion if init is called on MDMPersistanceController

## 1.3.2
* Minor README updates
* Check for block existence before calling it
