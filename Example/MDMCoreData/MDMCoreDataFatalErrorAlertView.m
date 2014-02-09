//
//  MDMCoreDataFatalErrorAlertView.m
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

#import "MDMCoreDataFatalErrorAlertView.h"

@interface MDMCoreDataFatalErrorAlertView () <UIAlertViewDelegate>

@end

@implementation MDMCoreDataFatalErrorAlertView

- (void)showAlert {
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Could Not Save Data", @"Title for fatal save error")
                                                        message:NSLocalizedString(@"There was a problem saving your data. It is not your fault. If you restart the app, you can try again. Please contact support and notify them of this issue.", @"Message for fatal save error")
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Ok", @"Ok button for fatal save error")
                                              otherButtonTitles:nil];
    [self showFatalErrorAlert:alertView];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    
    //
    // Good place to log (Hockey App, Testflight, Crashlytics, ...) relevant data to help with debugging.
    //
    abort();
}

- (void)showFatalErrorAlert:(UIAlertView *)alertView {
    
    if ([NSThread isMainThread] == NO) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [alertView show];
        });
    } else {
        
        [alertView show];
    }
}

@end
