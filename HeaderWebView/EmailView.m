//
//  EmailView.m
//  HeaderWebView
//
//  Created by Catalina Turlea on 4/13/15.
//  Copyright (c) 2015 Catalina Turlea. All rights reserved.
//

#import "EmailView.h"
#import <objc/runtime.h>

@interface EmailView () <UIScrollViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, weak) UIView *innerHeaderView;
@property (nonatomic, weak) UIView *innerFooterView;
@property (nonatomic, strong) IBOutlet UIView *headerView;
@property (nonatomic, strong) IBOutlet UIView *footerView;

@property (nonatomic, weak) IBOutlet UIWebView *webView;

@property (nonatomic, getter = isFullScreen) BOOL fullScreen;
@property (nonatomic, getter = isZooming) BOOL zooming;
@property (nonatomic, getter = didSwitchToFullScreen) BOOL switchToFullScreen;
@property (nonatomic, getter = didTapToFullScreen) BOOL tapToFullScreen;

@end

@implementation EmailView

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self createHeaderView];
    [self createFooterView];
    
    [self.webView setScalesPageToFit:YES];
    self.webView.scrollView.bounces = false;
    [self.webView.scrollView setDelaysContentTouches:NO];
    self.webView.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal;
    
    [self.webView.scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionInitial context:nil];
    
    [self.webView.scrollView setDelegate:self];
    [self.webView.scrollView setShowsVerticalScrollIndicator:NO];
    
    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didDoubleTapOnView:)];
    [gesture setDelegate:self];
    [self.webView.scrollView addGestureRecognizer:gesture];
}

#pragma mark -
#pragma mark - Interface layout

- (void)updateLayout
{
    // Update the frame of the header view so that it scrolls with the webview content
    CGRect newHeaderFrame = self.headerView.frame;
    
    newHeaderFrame.origin.y = -CGRectGetMinY([self.webView convertRect:self.innerHeaderView.frame toView:self.webView.scrollView]);
    [self.headerView setFrame:newHeaderFrame];
    
    
    // the footer view frame should reduce the origin.y value until visible, when scrolling all the way down
    CGRect newFooterFrame = self.footerView.frame;
    newFooterFrame.origin.y = CGRectGetMaxX(self.webView.frame) + (self.webView.scrollView.contentSize.height - (CGRectGetMaxY([self.webView convertRect:self.innerFooterView.frame toView:self.webView.scrollView])));
    
    [self.footerView setFrame:newFooterFrame];
    
    if ([self  didTapToFullScreen])
    {
        // The delegate was already called in this case, in the tap gesture callback method
        return;
    }
    
    BOOL fullScreen = (newHeaderFrame.origin.y < 0);
    if (([self isZooming] && [self didSwitchToFullScreen]) || (fullScreen == [self isFullScreen]))
    {
        return;
    }
    
    [self setSwitchToFullScreen:fullScreen];
    [self setFullScreen:fullScreen];
    
    // Call the delegate for the full screen
    [self.fullScreenDelegate emailView:self showFullScreen:fullScreen];
}

#pragma mark -
#pragma mark - NSKeyObserving

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [self updateLayout];

}

#pragma mark -
#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale
{
    [self setZooming:NO];
    [self setSwitchToFullScreen:(scale > 1)];
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view
{
    [self setSwitchToFullScreen:NO];
    [self setZooming:YES];
    [self setTapToFullScreen:NO];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self setTapToFullScreen:NO];
}

#pragma mark -
#pragma mark - UITapGestureRecognizer callback

- (void)didDoubleTapOnView:(UITapGestureRecognizer *)sender
{
    [self setFullScreen:![self isFullScreen]];
    [self setSwitchToFullScreen:[self isFullScreen]];
    [self setTapToFullScreen:YES];
    [self.fullScreenDelegate emailView:self showFullScreen:[self isFullScreen]];
}

#pragma mark -
#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

#pragma mark -
#pragma mark - Custom methods

- (void)createHeaderView
{
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.frame), 60)];
    [headerView setBackgroundColor:[UIColor clearColor]];
    
    [self.webView.scrollView addSubview:headerView];
    [self setInnerHeaderView:headerView];
    
    [self addSubview:self.headerView];
}

- (void)createFooterView
{
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, self.webView.scrollView.contentSize.height - 60, CGRectGetWidth(self.frame), 60)];
    [footerView setBackgroundColor:[UIColor blackColor]];
    
    [self.webView.scrollView addSubview:footerView];
    [self setInnerFooterView:footerView];
    
    [self addSubview:self.footerView];
}


#pragma mark -
#pragma mark - Custom layouting

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    for (UIView *subview in self.webView.scrollView.subviews)
    {
        CGRect newFrame = subview.frame;
        if ([subview isEqual:self.innerHeaderView] || [subview isEqual:self.innerFooterView])
        {
            continue;
        }
        
        newFrame.origin.y = CGRectGetHeight(self.headerView.frame);
        [subview setFrame:newFrame];
    }
    
    [self updateLayout];
    
}

#pragma mark -
#pragma mark - Dealloc

- (void)dealloc
{
    [self.webView.scrollView removeObserver:self forKeyPath:@"contentOffset"];
}

@end
