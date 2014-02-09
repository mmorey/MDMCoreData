//
//  MDMMasterViewController.m
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

#import "MDMMasterViewController.h"
#import "MDMDetailViewController.h"
#import <MDMCoreData.h>
#import "MDMCoreDataFatalErrorAlertView.h"

@interface MDMMasterViewController () <MDMFetchedResultsTableDataSourceDelegate>

@property (nonatomic, strong) MDMFetchedResultsTableDataSource *tableDataSource;
@property (nonatomic, strong) MDMCoreDataFatalErrorAlertView *fatalErrorAlertView;

@end

@implementation MDMMasterViewController

#pragma mark - View Lifecycle

- (void)viewDidLoad {
    
    [super viewDidLoad];

    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject:)];
    self.navigationItem.rightBarButtonItem = addButton;
    
    [self setupTableDataSource];
}

- (void)setupTableDataSource {

    ZAssert(self.persistenceController.managedObjectContext, @"Forgot to set managed object context");
    
    self.tableDataSource = [[MDMFetchedResultsTableDataSource alloc] initWithTableView:self.tableView
                                                              fetchedResultsController:[self fetchedResultsController]];
    self.tableDataSource.delegate = self;
    self.tableDataSource.reuseIdentifier = @"Cell";
    self.tableView.dataSource = self.tableDataSource;
}

#pragma mark - MDMFetchedResultsTableDataSourceDelegate

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
    [self save];
}

#pragma mark - Insert New Object

- (void)insertNewObject:(id)sender {
    
    NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
    NSEntityDescription *entity = [[self.fetchedResultsController fetchRequest] entity];
    NSManagedObject *newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:[entity name] inManagedObjectContext:context];
    [newManagedObject setValue:[NSDate date] forKey:@"timeStamp"];
    [self save];
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController {
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Event" inManagedObjectContext:self.persistenceController.managedObjectContext];
    [fetchRequest setEntity:entity];
    [fetchRequest setFetchBatchSize:20];
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
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSManagedObject *object = [[self fetchedResultsController] objectAtIndexPath:indexPath];
        [[segue destinationViewController] setDetailItem:object];
    }
}

@end
