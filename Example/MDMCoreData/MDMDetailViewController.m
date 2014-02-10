//
//  MDMDetailViewController.m
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

#import "MDMDetailViewController.h"
#import <MDMCoreData.h>

@interface MDMDetailViewController ()

@end

@implementation MDMDetailViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    [self configureView];
}

- (void)configureView {
    
    if (self.detailItem) {
        self.detailDescriptionLabel.text = [[self.detailItem valueForKey:@"timeStamp"] description];
    }
}

- (void)setDetailItem:(id)newDetailItem {
    
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        [self configureView];
    }
}

- (IBAction)delete:(UIBarButtonItem *)sender {
    [self.persistenceController deleteObject:self.detailItem saveContextAndWait:YES completion:^(NSError *error) {
        if(!error) {
            [UIView animateKeyframesWithDuration:1 delay:0 options:UIViewKeyframeAnimationOptionCalculationModeCubic animations:^{
                [UIView addKeyframeWithRelativeStartTime:0 relativeDuration:.5 animations:^{
                    self.detailDescriptionLabel.frame = CGRectOffset(self.detailDescriptionLabel.frame, 30, -50);
                    self.detailDescriptionLabel.transform = CGAffineTransformMakeScale(1.15, 1.15);
                }];
                [UIView addKeyframeWithRelativeStartTime:.5 relativeDuration:.5 animations:^{
                    self.detailDescriptionLabel.frame = CGRectOffset(self.detailDescriptionLabel.frame, 30, CGRectGetHeight(self.view.frame));
                    self.detailDescriptionLabel.transform = CGAffineTransformMakeScale(.2, .2);
                }];
            } completion:^(BOOL finished) {
                [self.navigationController popToRootViewControllerAnimated:YES];
            }];
        }
        else NSLog(@"%@", error.localizedDescription);
    }];
}
@end
