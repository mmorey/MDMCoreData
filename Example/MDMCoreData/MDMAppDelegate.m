//
//  MDMAppDelegate.m
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

#import "MDMAppDelegate.h"
#import "MDMPersistenceControllerViewControllerProtocol.h"
#import <MDMCoreData.h>
#import "MDMCoreDataFatalErrorAlertView.h"

@interface MDMAppDelegate ()

@property (nonatomic, strong) MDMPersistenceController *persistenceController;
@property (nonatomic, strong) MDMCoreDataFatalErrorAlertView *fatalErrorAlertView;

@end

@implementation MDMAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // Inject Persistence Controller into top ViewControllers.
    UITabBarController *tabBarController = (UITabBarController *)self.window.rootViewController;
    
    [tabBarController.viewControllers enumerateObjectsUsingBlock:^(UINavigationController *navigationController, NSUInteger idx, BOOL *stop) {
        
        if ([navigationController.topViewController conformsToProtocol:@protocol(MDMPersistenceControllerViewControllerProtocol)]) {
            id<MDMPersistenceControllerViewControllerProtocol> viewController = (id<MDMPersistenceControllerViewControllerProtocol>)navigationController.topViewController;
            [viewController setPersistenceController:self.persistenceController];
        }
    }];
    
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application {

    [self.persistenceController saveContextAndWait:YES completion:nil];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
   
    [self.persistenceController saveContextAndWait:YES completion:nil];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    
    [self.persistenceController saveContextAndWait:YES completion:nil];
}

#pragma mark - Persistence Controller

- (MDMPersistenceController *)persistenceController {
    
    if (_persistenceController == nil) {
        NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"MDMCoreData.sqlite"];
        NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"MDMCoreData" withExtension:@"momd"];
        _persistenceController = [[MDMPersistenceController alloc] initWithStoreURL:storeURL modelURL:modelURL];
        if (_persistenceController == nil) {
            
            ALog(@"ERROR: Persistence controller could not be created");
            [self.fatalErrorAlertView showAlert];
        }
    }
    
    return _persistenceController;
}

#pragma mark - Application's Documents directory

- (NSURL *)applicationDocumentsDirectory {
    
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

#pragma mark - Fatal Error Alert

- (MDMCoreDataFatalErrorAlertView *)fatalErrorAlertView {
    
    if (_fatalErrorAlertView == nil) {
        _fatalErrorAlertView = [[MDMCoreDataFatalErrorAlertView alloc] init];
    }
    
    return _fatalErrorAlertView;
}

@end
