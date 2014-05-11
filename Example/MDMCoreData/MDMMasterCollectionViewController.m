//
//  MDMMasterCollectionViewController.m
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

#import "MDMMasterCollectionViewController.h"
#import <MDMCoreData.h>
#import "MDMCoreDataFatalErrorAlertView.h"
#import "MDMDetailViewController.h"
#import "MDMCollectionViewCell.h"
#import "Event.h"

@interface MDMMasterCollectionViewController () <MDMFetchedResultsCollectionDataSourceDelegate>

@property (nonatomic, strong) MDMFetchedResultsCollectionDataSource *collectionDataSource;
@property (nonatomic, strong) MDMCoreDataFatalErrorAlertView *fatalErrorAlertView;
@property (nonatomic, strong) NSDateFormatter *titleDateFormatter;
@property (nonatomic, strong) NSDateFormatter *subtitleDateFormatter;

@end

@implementation MDMMasterCollectionViewController

#pragma mark - View Lifecycle

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    UIBarButtonItem *pauseButton = [[UIBarButtonItem alloc] initWithTitle:@"Pause" style:UIBarButtonItemStylePlain target:self action:@selector(pauseUpdates:)];
    self.navigationItem.leftBarButtonItem = pauseButton;
    
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject:)];
    self.navigationItem.rightBarButtonItem = addButton;

    [self setupDateFormatters];
    [self setupCollectionDataSource];
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    [self.collectionViewLayout layoutAttributesForElementsInRect:self.collectionView.bounds];
    [self.collectionViewLayout invalidateLayout];
    
    [self updatePauseBarButton:self.navigationItem.leftBarButtonItem];
}

- (void)setupDateFormatters {
    
    self.titleDateFormatter = [[NSDateFormatter alloc] init];
    [self.titleDateFormatter setDateStyle:NSDateFormatterMediumStyle];
    
    self.subtitleDateFormatter = [[NSDateFormatter alloc] init];
    [self.subtitleDateFormatter setDateFormat:@"HH:mm:ss"];
}

- (void)setupCollectionDataSource {
    
    ZAssert(self.persistenceController.managedObjectContext, @"Forgot to set managed object context");
    
    self.collectionDataSource = [[MDMFetchedResultsCollectionDataSource alloc] initWithCollectionView:self.collectionView
                                                                             fetchedResultsController:[self fetchedResultsController]];
                                 
    self.collectionDataSource.delegate = self;
    self.collectionDataSource.reuseIdentifier = @"CollectionViewCell";
    self.collectionView.dataSource = self.collectionDataSource;
}

#pragma mark - MDMFetchedResultsCollectionDataSourceDelegate

- (void)dataSource:(MDMFetchedResultsCollectionDataSource *)dataSource
     configureCell:(id)cell
        withObject:(id)object {
    
    MDMCollectionViewCell *collectionViewCell = (MDMCollectionViewCell *)cell;
    Event *event = (Event *)object;
    collectionViewCell.titleLabel.text = [self.titleDateFormatter stringFromDate:event.timeStamp];
    collectionViewCell.subtitleLabel.text = [self.subtitleDateFormatter stringFromDate:event.timeStamp];
}

- (void)dataSource:(MDMFetchedResultsCollectionDataSource *)dataSource
      deleteObject:(id)object
       atIndexPath:(NSIndexPath *)indexPath {
    
    [self.persistenceController.managedObjectContext deleteObject:object];
    [self save];
}

#pragma mark - Insert New Object

- (void)insertNewObject:(id)sender {
    
    Event *newEvent = [Event MDMCoreDataAdditionsInsertNewObjectIntoContext:[self.fetchedResultsController managedObjectContext]];
    newEvent.timeStamp = [NSDate date];
    [self save];
}

#pragma mark - Pause
- (void)pauseUpdates:(UIBarButtonItem *)sender {
    
    self.collectionDataSource.paused = !self.collectionDataSource.paused;
    [self updatePauseBarButton:sender];
}

- (void)updatePauseBarButton:(UIBarButtonItem *)pauseButton {
    NSDictionary *titleTextAttributes = (self.collectionDataSource.paused) ? @{ NSFontAttributeName : [UIFont boldSystemFontOfSize:14.0f],
                                                                                NSForegroundColorAttributeName : [UIColor redColor] } : nil;
    [pauseButton setTitleTextAttributes:titleTextAttributes forState:UIControlStateNormal];
    pauseButton.title = (self.collectionDataSource.paused) ? @"Resume" : @"Pause";
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController {
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[Event MDMCoreDataAdditionsEntityName]];
    [fetchRequest setFetchBatchSize:100];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timeStamp" ascending:NO];
    NSArray *sortDescriptors = @[sortDescriptor];
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                               managedObjectContext:self.persistenceController.managedObjectContext
                                                                                                 sectionNameKeyPath:nil
                                                                                                          cacheName:nil];
    
	NSError *error = nil;
	if ([fetchedResultsController performFetch:&error] == NO) {
	    ALog(@"Unresolved error %@, %@", error, [error userInfo]);
	}
    
    return fetchedResultsController;
}

#pragma mark - Saving

- (void)save {
    
    __weak typeof(self) weakSelf = self;
    [self.persistenceController saveContextAndWait:NO completion:^(NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        if (error) {
            ALog(@"ERROR: Data could not be saved %@", [error localizedDescription]);
            [strongSelf.fatalErrorAlertView showAlert];
        }
    }];
}

#pragma mark - Fatal Error Alert

- (MDMCoreDataFatalErrorAlertView *)fatalErrorAlertView {
    
    if (_fatalErrorAlertView == nil) {
        _fatalErrorAlertView = [[MDMCoreDataFatalErrorAlertView alloc] init];
    }
    
    return _fatalErrorAlertView;
}

#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        
        Event *selectedEvent = [self.collectionDataSource selectedItem];
        MDMDetailViewController *detailVC = segue.destinationViewController;
        detailVC.detailItem = selectedEvent;
        detailVC.persistenceController = self.persistenceController;
    }
}

@end
