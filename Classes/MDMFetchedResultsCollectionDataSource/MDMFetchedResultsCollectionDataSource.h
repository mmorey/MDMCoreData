//
//  MDMFetchedResultsCollectionDataSource.h
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

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <UIKit/UIKit.h>

@class MDMFetchedResultsCollectionDataSource;

/**
 A delegate of a `MDMFetchedResultsCollectionDataSource` object must adopt the
 `MDMFetchedResultsCollectionDataSource` protocol.
 */
@protocol MDMFetchedResultsCollectionDataSourceDelegate <NSObject>

@required
/**
 Tells the delegate to configure the collection cell with the given object.

 @param cell The UICollectionViewCell to be configured by the delegate.
 @param object The object to be used to configure the cell.
 */
- (void)dataSource:(MDMFetchedResultsCollectionDataSource *)dataSource configureCell:(id)cell withObject:(id)object;

/**
 Asks the delegate to delete the specified object.

 @param object The object to be deleted by the delegate.
 @param indexPath The indexPath of the cell representing the object.
 */
- (void)dataSource:(MDMFetchedResultsCollectionDataSource *)dataSource deleteObject:(id)object atIndexPath:(NSIndexPath *)indexPath;

@optional
/**
 Asks the delegate for a reuse identifier to be used to dequeue a cell. This method will only get called if the `reuseIdentifier` property is nil. Use this method when you want to make use of different kinds of cells.
 
 @param object The object that will be eventually used to configure the dequeued cell.
 @param indexPath The index path for the cell to be dequeued.
 */
- (NSString *)dataSource:(MDMFetchedResultsCollectionDataSource *)dataSource reuseIdentifierForObject:(id)object atIndexPath:(NSIndexPath *)indexPath;

/**
 Asks the delegate for a reuse identifier to be used to dequeue a supplementary view. This method will only get called if the `headerReuseIdentifier` and/or `footerReuseIdentifier` properties are nil. Use this method when you want to make use of different kinds of supplementary views for a given kind.
 
 @param kind The kind of UICollectionReusableView (UICollectionElementKindSectionHeader or UICollectionElementKindSectionFooter).
 @param indexPath The index path for the supplementary view to be dequeued.
 */
- (NSString *)dataSource:(MDMFetchedResultsCollectionDataSource *)dataSource reuseIdentifierForSupplementaryViewOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath;

/**
 Tells the delegate to configure the supplementary view.
 
 @param view The UICollectionReusableView to be configured by the delegate.
 @param kind The kind of UICollectionReusableView (UICollectionElementKindSectionHeader or UICollectionElementKindSectionFooter).
 @param indexPath The index path for the supplementary view to be dequeued.
 */
- (void)dataSource:(MDMFetchedResultsCollectionDataSource *)dataSource configureSupplementaryView:(id)view ofKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath;

@end

@interface MDMFetchedResultsCollectionDataSource : NSObject <UICollectionViewDataSource, NSFetchedResultsControllerDelegate>

/**
 The `NSFetchedResultsController` to be used by the data source.
 */
@property(nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

/**
 The reuse identifier of the cell being modified by the data source. If you prefer to use multiple identifiers, do not set this property and implement the `dataSource:reuseIdentifierForObject:atIndexPath:` delegate method instead.
 */
@property(nonatomic, copy) NSString *reuseIdentifier;

/**
 The reuse identifier of the header being modified by the data source. If you prefer to use multiple identifiers, do not set this property and implement the `dataSource:reuseIdentifierForSupplementaryViewOfKind:atIndexPath:` delegate method instead.
 */
@property(nonatomic, copy) NSString *headerReuseIdentifier;

/**
 The reuse identifier of the footer being modified by the data source. If you prefer to use multiple identifiers, do not set this property and implement the `dataSource:reuseIdentifierForSupplementaryViewOfKind:atIndexPath:` delegate method instead.
 */
@property(nonatomic, copy) NSString *footerReuseIdentifier;

/**
 A Boolean value that determines whether the receiver will update automatically when the model changes.
 */
@property(nonatomic) BOOL paused;

/**
 The object that acts as the delegate of the receiving data source.
 */
@property(nonatomic, weak) id <MDMFetchedResultsCollectionDataSourceDelegate> delegate;

/**
 Returns a fetched results collectionView data source initialized with the given arguments.

 @param collectionView The collectionView view using this data source.
 @param fetchedResultsController The fetched results controller the data source should use.

 @return The newly-initialized collectionView data source.
 */
- (id)initWithCollectionView:(UICollectionView *)collectionView fetchedResultsController:(NSFetchedResultsController *)fetchedResultsController;

/**
 Returns the currently selected item from the collectionView.

 @return The selected item. If multiple items are selected it returns the first item.
 */
- (id)selectedItem;

/**
 Asks the data source to return the number of rows in the section.

 @param section An index number identifying a section for the internally managed collectionView view.

 @return The number of rows in `section`. If section doesn't exist returns 0.
 */
- (NSUInteger)numberOfRowsInSection:(NSUInteger)section;

/**
 Asks the data source to return the total number of rows in all sections.

 @return Total number of rows.
 */
- (NSUInteger)numberOfRowsInAllSections;

/**
 Returns the item object at the specified index path.

 @param path The index path that specifies the section and row of the cell.

 @return The item object at the corresponding index path or `nil` if the index path is out of range.
 */
- (id)itemAtIndexPath:(NSIndexPath *)path;

/**
 Returns the index path of a given object.

 @param object An object in the receiver's fetch results.

 @return The index path of `object` in the receiver's fetch results, or nil if `object` could not be found.
 */
- (NSIndexPath *)indexPathForObject:(id)object;

@end
