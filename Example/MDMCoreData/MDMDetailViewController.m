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
#import "Event.h"

@interface MDMDetailViewController ()

@end

@implementation MDMDetailViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    [self configureView];
    self.detailDescriptionLabel.userInteractionEnabled = YES;
    UISwipeGestureRecognizer *leftSwipe = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(goToNext:)];
    leftSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
    leftSwipe.numberOfTouchesRequired = 1;
    
    UISwipeGestureRecognizer *rightSwipe = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(goToLast:)];
    rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
    rightSwipe.numberOfTouchesRequired = 1;
    
    [self.detailDescriptionLabel addGestureRecognizer:rightSwipe];
    [self.detailDescriptionLabel addGestureRecognizer:leftSwipe];
}

- (void)configureView {
    
    if (self.detailItem) {
        self.detailDescriptionLabel.text = [self.detailItem.timeStamp description];
    }
}

- (void)setDetailItem:(id)newDetailItem {
    
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        [self configureView];
    }
}

- (IBAction)update:(UIBarButtonItem *)sender {
    self.detailItem.timeStamp = [NSDate date];
    [self.persistenceController saveContextAndWait:YES completion:^(NSError *error) {
        if (!error) {
            [self.navigationController popToRootViewControllerAnimated:YES];
        }
    }];
}

- (IBAction)delete:(UIBarButtonItem *)sender {
    
    [self.persistenceController deleteObject:self.detailItem saveContextAndWait:YES completion:^(NSError *error) {
        
        if(!error) {
            
            [UIView animateKeyframesWithDuration:1 delay:0 options:UIViewKeyframeAnimationOptionCalculationModeCubic animations:^{
                [UIView addKeyframeWithRelativeStartTime:0 relativeDuration:0.5 animations:^{
                    self.detailDescriptionLabel.frame = CGRectOffset(self.detailDescriptionLabel.frame, 30, -50);
                    self.detailDescriptionLabel.transform = CGAffineTransformMakeScale(1.15, 1.15);
                }];
                [UIView addKeyframeWithRelativeStartTime:0.5 relativeDuration:0.5 animations:^{
                    self.detailDescriptionLabel.frame = CGRectOffset(self.detailDescriptionLabel.frame, 30, CGRectGetHeight(self.view.frame));
                    self.detailDescriptionLabel.transform = CGAffineTransformMakeScale(0.2, 0.2);
                }];
            } completion:^(BOOL finished) {
                
                [self.navigationController popToRootViewControllerAnimated:YES];
            }];
        } else {
            
         ALog(@"%@", error.localizedDescription);
        }
    }];
}

- (void)goToNext:(UISwipeGestureRecognizer *)recognizer {
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[Event MDMCoreDataAdditionsEntityName]];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timeStamp" ascending:YES];
    [fetchRequest setSortDescriptors:@[sortDescriptor]];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"timeStamp > %@", self.detailItem.timeStamp]];
    
    Event *event = [[self.persistenceController executeFetchRequest:fetchRequest error:^(NSError *error) {
        
        ALog(@"%@", error.localizedDescription);
    }] firstObject];
    
    if(event) {
        
        [UIView animateKeyframesWithDuration:1 delay:0 options:UIViewKeyframeAnimationOptionCalculationModeCubic animations:^{
            [UIView addKeyframeWithRelativeStartTime:0 relativeDuration:.5 animations:^{
                self.detailDescriptionLabel.frame = CGRectOffset(self.detailDescriptionLabel.frame, -50, 0);
            }];
            [UIView addKeyframeWithRelativeStartTime:.5 relativeDuration:.3 animations:^{
                self.detailDescriptionLabel.frame = CGRectOffset(self.detailDescriptionLabel.frame, 70, 0);
            }];
            [UIView addKeyframeWithRelativeStartTime:.8 relativeDuration:.2 animations:^{
                self.detailDescriptionLabel.frame = CGRectOffset(self.detailDescriptionLabel.frame, -20, 0);
            }];
        } completion:^(BOOL finished) {
            
            self.detailDescriptionLabel.text = [event.timeStamp description];
            self.detailItem = event;
        }];
    }
}

- (void)goToLast:(UISwipeGestureRecognizer *)recognizer {
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[Event MDMCoreDataAdditionsEntityName]];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timeStamp" ascending:NO];
    [fetchRequest setSortDescriptors:@[sortDescriptor]];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"timeStamp < %@", self.detailItem.timeStamp]];
    
    Event *event = [[self.persistenceController executeFetchRequest:fetchRequest error:^(NSError *error) {
        
        ALog(@"%@", error.localizedDescription);
    }] firstObject];
    
    if(event) {
        
        [UIView animateKeyframesWithDuration:1 delay:0 options:UIViewKeyframeAnimationOptionCalculationModeCubic animations:^{
           
            [UIView addKeyframeWithRelativeStartTime:0 relativeDuration:0.5 animations:^{
                self.detailDescriptionLabel.frame = CGRectOffset(self.detailDescriptionLabel.frame, 50, 0);
            }];
            [UIView addKeyframeWithRelativeStartTime:0.5 relativeDuration:0.3 animations:^{
                self.detailDescriptionLabel.frame = CGRectOffset(self.detailDescriptionLabel.frame, -70, 0);
            }];
            [UIView addKeyframeWithRelativeStartTime:0.8 relativeDuration:0.2 animations:^{
                self.detailDescriptionLabel.frame = CGRectOffset(self.detailDescriptionLabel.frame, 20, 0);
            }];
        } completion:^(BOOL finished) {
            
            self.detailDescriptionLabel.text = [event.timeStamp description];
            self.detailItem = event;
        }];
    }
}

@end
