//
//  MDMFetchedResultsCollectionDataSource.m
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

#import <CoreData/CoreData.h>
#import "MDMFetchedResultsCollectionDataSource.h"
#import "MDMCoreDataMacros.h"

@interface MDMFetchedResultsCollectionDataSource ()
@property(nonatomic, weak) UICollectionView *collectionView;
@property(nonatomic, strong) NSMutableArray *objectChanges;
@property(nonatomic, strong) NSMutableArray *sectionChanges;
@end

@implementation MDMFetchedResultsCollectionDataSource

- (id)initWithCollectionView:(UICollectionView *)collectionView
    fetchedResultsController:(NSFetchedResultsController *)fetchedResultsController {
    self = [super init];
    if(self) {

        _collectionView = collectionView;
        _sectionChanges = [NSMutableArray array];
        _objectChanges = [NSMutableArray array];
        _fetchedResultsController = fetchedResultsController;
        
        [self setupFetchedResultsController:fetchedResultsController];
    }

    return self;
}

#pragma mark - Private Methods

- (void)setupFetchedResultsController:(NSFetchedResultsController *)fetchedResultsController {

    fetchedResultsController.delegate = self;
    BOOL fetchSuccess = [fetchedResultsController performFetch:NULL];
    ZAssert(fetchSuccess, @"Fetch request does not include sort descriptor that uses the section name.");
    [self.collectionView reloadData];
}

- (id)itemAtIndexPath:(NSIndexPath *)path {

    return [self.fetchedResultsController objectAtIndexPath:path];
}

#pragma mark - Public Setters

- (void)setFetchedResultsController:(NSFetchedResultsController *)fetchedResultsController {

    if(_fetchedResultsController != fetchedResultsController) {

        _fetchedResultsController = fetchedResultsController;
        [self setupFetchedResultsController:fetchedResultsController];
    }
}

- (void)setPaused:(BOOL)paused {

    _paused = paused;
    if(paused) {
        self.fetchedResultsController.delegate = nil;
    } else {
        self.fetchedResultsController.delegate = self;
        [self.fetchedResultsController performFetch:NULL];
        [self.collectionView reloadData];
    }
}

#pragma mark - Public Methods

- (id)selectedItem {

    NSIndexPath *path = [self.collectionView indexPathsForSelectedItems].firstObject;

    return path ? [self itemAtIndexPath:path] : nil;
}

- (NSUInteger)numberOfRowsInSection:(NSUInteger)section {

    if(section < [self.fetchedResultsController.sections count]) {

        return [self.fetchedResultsController.sections[section] numberOfObjects];
    }

    return 0; // If section doesn't exist return 0
}

- (NSUInteger)numberOfRowsInAllSections {

    NSUInteger totalRows = 0;
    NSUInteger totalSections = [self.fetchedResultsController.sections count];

    for(NSUInteger section = 0; section < totalSections; section++) {
        totalRows = totalRows + [self numberOfRowsInSection:section];
    }

    return totalRows;
}

- (NSIndexPath *)indexPathForObject:(id)object {

    return [self.fetchedResultsController indexPathForObject:object];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {

    return self.fetchedResultsController.sections.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {

    return [self numberOfRowsInSection:(NSUInteger)section];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {

    id object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    NSString *reuseIdentifier = self.reuseIdentifier;
    
    if (reuseIdentifier == nil) {
        ZAssert([self.delegate respondsToSelector:@selector(dataSource:reuseIdentifierForObject:atIndexPath:)], @"You need to set the `reuseIdentifier` property or implement the optional dataSource:reuseIdentifierForObject:atIndexPath: delegate method.");
        reuseIdentifier = [self.delegate dataSource:self reuseIdentifierForObject:object atIndexPath:indexPath];
    }
    
    ZAssert(reuseIdentifier, @"You need to set the `reuseIdentifier` property or return a string value from the `dataSource:reuseIdentifierForObject:atIndexPath:` delegate method.");
    
    id cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    [self.delegate dataSource:self configureCell:cell withObject:object];

    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    
    NSString *reuseIdentifier = [self reuseIdentifierForSupplementaryViewOfKind:kind atIndexPath:indexPath];
    id view = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    if ([self.delegate respondsToSelector:@selector(dataSource:configureSupplementaryView:ofKind:atIndexPath:)]) {
        [self.delegate dataSource:self configureSupplementaryView:view ofKind:kind atIndexPath:indexPath];
    }
    
    return view;
}

- (NSString *)reuseIdentifierForSupplementaryViewOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    
    NSString *reuseIdentifier = nil;
    
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        
        reuseIdentifier = [self headerReuseIdentifierAtIndexPath:indexPath];
    } else if ([kind isEqualToString:UICollectionElementKindSectionFooter]) {
        
        reuseIdentifier = [self footerReuseIdentifierAtIndexPath:indexPath];
    }
    
    return reuseIdentifier;
}

- (NSString *)headerReuseIdentifierAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *reuseIdentifier = self.headerReuseIdentifier;
    
    if (reuseIdentifier == nil) {
        
        ZAssert([self.delegate respondsToSelector:@selector(dataSource:reuseIdentifierForSupplementaryViewOfKind:atIndexPath:)], @"You need to set the `headerReuseIdentifier` property or implmenet the `dataSource:reuseIdentifierOfKind:atIndexPath:` delegate method.");
        reuseIdentifier = [self.delegate dataSource:self reuseIdentifierForSupplementaryViewOfKind:UICollectionElementKindSectionHeader atIndexPath:indexPath];
    }
    
    ZAssert(reuseIdentifier, @"You need to set the `headerReuseIdentifier` property or return a string value from the `dataSource:reuseIdentifierOfKind:atIndexPath:` delegate method.");
    
    return reuseIdentifier;
}

- (NSString *)footerReuseIdentifierAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *reuseIdentifier = self.footerReuseIdentifier;
    
    if (reuseIdentifier == nil) {
        
        ZAssert([self.delegate respondsToSelector:@selector(dataSource:reuseIdentifierForSupplementaryViewOfKind:atIndexPath:)], @"You need to set the `footerReuseIdentifier` property or implmenet the `dataSource:reuseIdentifierOfKind:atIndexPath:` delegate method.");
        reuseIdentifier = [self.delegate dataSource:self reuseIdentifierForSupplementaryViewOfKind:UICollectionElementKindSectionFooter atIndexPath:indexPath];
    }
    
    ZAssert(reuseIdentifier, @"You need to set the `footerReuseIdentifier` property or return a string value from the `dataSource:reuseIdentifierOfKind:atIndexPath:` delegate method.");
    
    return reuseIdentifier;
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {

    NSMutableDictionary *change = [NSMutableDictionary new];

    switch(type) {
        case NSFetchedResultsChangeInsert:
            change[@(type)] = @(sectionIndex);
            break;
        case NSFetchedResultsChangeDelete:
            change[@(type)] = @(sectionIndex);
            break;
        case NSFetchedResultsChangeMove:
            break;
        case NSFetchedResultsChangeUpdate:
            DLog(@"update");
            break;
    }

    [self.sectionChanges addObject:change];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {

    NSMutableDictionary *change = [NSMutableDictionary new];
    switch(type) {
        case NSFetchedResultsChangeInsert:
            change[@(type)] = newIndexPath;
            break;
        case NSFetchedResultsChangeDelete:
            change[@(type)] = indexPath;
            break;
        case NSFetchedResultsChangeUpdate:
            change[@(type)] = indexPath;
            break;
        case NSFetchedResultsChangeMove:
            change[@(type)] = @[indexPath, newIndexPath];
            break;
    }
    [self.objectChanges addObject:change];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    if(self.sectionChanges.count > 0) {
        [self.collectionView performBatchUpdates:^{

            for(NSDictionary *change in self.sectionChanges) {
                [change enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, id obj, BOOL *stop) {

                    NSFetchedResultsChangeType type = [key unsignedIntegerValue];
                    switch(type) {
                        case NSFetchedResultsChangeInsert:
                            [self.collectionView insertSections:[NSIndexSet indexSetWithIndex:[obj unsignedIntegerValue]]];
                            break;
                        case NSFetchedResultsChangeDelete:
                            [self.collectionView deleteSections:[NSIndexSet indexSetWithIndex:[obj unsignedIntegerValue]]];
                            break;
                        case NSFetchedResultsChangeUpdate:
                            [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:[obj unsignedIntegerValue]]];
                            break;
                        case NSFetchedResultsChangeMove:
                            break;
                    }
                }];
            }
        }                             completion:nil];
    }

    if(self.objectChanges.count > 0 && self.sectionChanges.count == 0) {

        if([self shouldReloadCollectionViewToPreventKnownIssue] || self.collectionView.window == nil) {
            // This is to prevent a bug in UICollectionView from occurring.
            // The bug presents itself when inserting the first object or deleting the last object in a collection view.
            // http://stackoverflow.com/questions/12611292/uicollectionview-assertion-failure
            // This code should be removed once the bug has been fixed, it is tracked in OpenRadar
            // http://openradar.appspot.com/12954582
            [self.collectionView reloadData];

        } else {

            [self.collectionView performBatchUpdates:^{

                for(NSDictionary *change in self.objectChanges) {
                    [change enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, id obj, BOOL *stop) {

                        NSFetchedResultsChangeType type = [key unsignedIntegerValue];
                        switch(type) {
                            case NSFetchedResultsChangeInsert:
                                [self.collectionView insertItemsAtIndexPaths:@[obj]];
                                break;
                            case NSFetchedResultsChangeDelete:
                                [self.collectionView deleteItemsAtIndexPaths:@[obj]];
                                break;
                            case NSFetchedResultsChangeUpdate:
                                [self.collectionView reloadItemsAtIndexPaths:@[obj]];
                                break;
                            case NSFetchedResultsChangeMove:
                                [self.collectionView moveItemAtIndexPath:obj[0] toIndexPath:obj[1]];
                                break;
                        }
                    }];
                }
            }                             completion:nil];
        }
    }

    [self.sectionChanges removeAllObjects];
    [self.objectChanges removeAllObjects];
}

- (BOOL)shouldReloadCollectionViewToPreventKnownIssue {
    __block BOOL shouldReload = NO;
    for(NSDictionary *change in self.objectChanges) {
        [change enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            NSFetchedResultsChangeType type = [key unsignedIntegerValue];
            NSIndexPath *indexPath = obj;
            switch(type) {
                case NSFetchedResultsChangeInsert:
                    shouldReload = [self.collectionView numberOfItemsInSection:indexPath.section] == 0;
                    break;
                case NSFetchedResultsChangeDelete:
                    shouldReload = [self.collectionView numberOfItemsInSection:indexPath.section] == 1;
                    break;
                case NSFetchedResultsChangeUpdate:
                    shouldReload = NO;
                    break;
                case NSFetchedResultsChangeMove:
                    shouldReload = NO;
                    break;
            }
        }];
    }

    return shouldReload;
}

@end
