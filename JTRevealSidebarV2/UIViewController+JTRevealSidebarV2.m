/*
 * This file is part of the JTRevealSidebar package.
 * (c) James Tang <mystcolor@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "UIViewController+JTRevealSidebarV2.h"
#import "UINavigationItem+JTRevealSidebarV2.h"
#import "JTRevealSidebarV2Delegate.h"
#import <objc/runtime.h>

@interface UIViewController (JTRevealSidebarV2Private)
- (void)revealLeftSidebar:(BOOL)showLeftSidebar withAnimation:(RevealAnimation)animation;
- (void)revealRightSidebar:(BOOL)showRightSidebar withAnimation:(RevealAnimation)animation;

@end

@implementation UIViewController (JTRevealSidebarV2)

static char *revealedStateKey;
const CGFloat RevealAnimationDuration = .3f;
const CGFloat RevealNavigationSideBarWidth = 50.f;

- (void)setRevealedState:(JTRevealedState)revealedState{
    [self setRevealedState:revealedState withAnimation:RevealAnimationNone];
}

- (void)setRevealedState:(JTRevealedState)revealedState withAnimation:(RevealAnimation)animation {
    
    JTRevealedState currentState = self.revealedState;

    objc_setAssociatedObject(self, &revealedStateKey, [NSNumber numberWithInt:revealedState], OBJC_ASSOCIATION_RETAIN);

    switch (currentState) {
        case JTRevealedStateNo:
            if (revealedState == JTRevealedStateLeft) {
                [self revealLeftSidebar:YES withAnimation:animation];
            } else {
                [self revealLeftSidebar:YES withAnimation:animation];
            }
            break;
        case JTRevealedStateLeft:
            if (revealedState == JTRevealedStateNo) {
                [self revealLeftSidebar:NO withAnimation:animation];
            } else {
                [self revealLeftSidebar:NO withAnimation:animation];
                [self revealRightSidebar:YES withAnimation:animation];
            }
            break;
        case JTRevealedStateRight:
            if (revealedState == JTRevealedStateNo) {
                [self revealRightSidebar:NO withAnimation:animation];
            } else {
                [self revealRightSidebar:NO withAnimation:animation];
                [self revealLeftSidebar:YES withAnimation:animation];
            }
        default:
            break;
    }
}

- (JTRevealedState)revealedState {
    return (JTRevealedState)[objc_getAssociatedObject(self, &revealedStateKey) intValue];
}

- (CGAffineTransform)baseTransform {
    CGAffineTransform baseTransform;
    switch (self.interfaceOrientation) {
        case UIInterfaceOrientationPortrait:
            baseTransform = CGAffineTransformIdentity;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            baseTransform = CGAffineTransformMakeRotation(-M_PI/2);
            break;
        case UIInterfaceOrientationLandscapeRight:
            baseTransform = CGAffineTransformMakeRotation(M_PI/2);
            break;
        default:
            baseTransform = CGAffineTransformMakeRotation(M_PI);
            break;
    }
    return baseTransform;
}

@end

@implementation UIViewController (JTRevealSidebarV2Private)

- (UIViewController *)selectedViewController {
    return self;
}

- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
    UIView *view = (UIView *)context;
    [view removeFromSuperview];
}

- (void)revealLeftSidebar:(BOOL)showLeftSidebar withAnimation:(RevealAnimation)animation{
    id <JTRevealSidebarV2Delegate> delegate = [self selectedViewController].navigationItem.revealSidebarDelegate;

    if (![delegate respondsToSelector:@selector(viewForLeftSidebar)]) {
        return;
    }
    
    UIView *revealedView = [delegate viewForLeftSidebar];
    [self.view.layer removeAllAnimations];
    [revealedView.layer removeAllAnimations];
    
    __block CGRect main_frame = [[UIScreen mainScreen] applicationFrame];
    if (showLeftSidebar) {
        [self.view.superview insertSubview:revealedView belowSubview:self.view];
        if(animation != RevealAnimationNone){
            [UIView animateWithDuration:RevealAnimationDuration delay:.0f options:UIViewAnimationCurveEaseOut animations:^(){
                self.view.transform = CGAffineTransformTranslate([self baseTransform], floorf(CGRectGetWidth(main_frame) - RevealNavigationSideBarWidth), 0);
                /*CGRect bar_frame = revealedView.frame;
                bar_frame.size.width = floorf(CGRectGetWidth(main_frame) - RevealNavigationSideBarWidth);
                revealedView.frame = bar_frame;*/
            }completion:^(BOOL finished){
                if ([delegate respondsToSelector:@selector(sidebarDidChangeState)]) {
                    [delegate sidebarDidChangeState];
                }
            }];
        }
        else{
            self.view.transform = CGAffineTransformTranslate([self baseTransform], floorf(CGRectGetWidth(main_frame) - RevealNavigationSideBarWidth), 0);
            if ([delegate respondsToSelector:@selector(sidebarDidChangeState)]) {
                [delegate sidebarDidChangeState];
            }
        }
    } else {
        if(animation == RevealAnimationNone){
            self.view.transform = CGAffineTransformTranslate([self baseTransform], 0, 0); 
            if ( [delegate respondsToSelector:@selector(sidebarDidChangeState)]) {
                [delegate sidebarDidChangeState];
            }
        }
        else if(animation == RevealAnimationOpenFullThenClose){
            [UIView animateWithDuration:RevealAnimationDuration * .5f delay:.0f options:UIViewAnimationCurveEaseIn animations:^(){
                self.view.transform = CGAffineTransformTranslate([self baseTransform], CGRectGetWidth(main_frame), 0);
                CGRect bar_frame = revealedView.frame;
                bar_frame.size.width = floorf(CGRectGetWidth(main_frame));
                revealedView.frame = bar_frame;
            }completion:^(BOOL finished){
                if(finished){
                    if([delegate respondsToSelector:@selector(sidebarDidMoveAside)]){
                        [delegate sidebarDidMoveAside];
                    }
                }
                [UIView animateWithDuration:RevealAnimationDuration delay:.0f options:UIViewAnimationCurveEaseOut animations:^(){
                    self.view.transform = CGAffineTransformTranslate([self baseTransform], 0, 0); 
                    /*CGRect bar_frame = revealedView.frame;
                    bar_frame.size.width = floorf(CGRectGetWidth(main_frame) - RevealNavigationSideBarWidth);
                    revealedView.frame = bar_frame;*/
                }completion:^(BOOL finished){
                    if(finished){
                        [revealedView removeFromSuperview];
                        if ( [delegate respondsToSelector:@selector(sidebarDidChangeState)]) {
                            [delegate sidebarDidChangeState];
                        }
                    }
                }];
            }];
        }
        else{
            [UIView animateWithDuration:RevealAnimationDuration delay:.0f options:UIViewAnimationCurveEaseOut animations:^(){
                self.view.transform = CGAffineTransformTranslate([self baseTransform], 0, 0); 
            }completion:^(BOOL finished){
                if(finished){
                    [revealedView removeFromSuperview];
                    if ( [delegate respondsToSelector:@selector(sidebarDidChangeState)]) {
                        [delegate sidebarDidChangeState];
                    }
                }
            }];
        }
    }
}

- (void)revealRightSidebar:(BOOL)showRightSidebar withAnimation:(RevealAnimation)animation{
    id <JTRevealSidebarV2Delegate> delegate = [self selectedViewController].navigationItem.revealSidebarDelegate;
    
    if ( ! [delegate respondsToSelector:@selector(viewForRightSidebar)]) {
        return;
    }

    UIView *revealedView = [delegate viewForRightSidebar];
    __block CGRect main_frame = [[UIScreen mainScreen] applicationFrame];
    
    [self.view.layer removeAllAnimations];
    [revealedView.layer removeAllAnimations];
    if (showRightSidebar) {
        [self.view.superview insertSubview:revealedView belowSubview:self.view];

        if(animation == RevealAnimationNone){
            self.view.transform = CGAffineTransformTranslate([self baseTransform], -floorf(CGRectGetWidth(main_frame) - 50.f), 0);
        }
        else{
            [UIView animateWithDuration:RevealAnimationDuration delay:.0f options:UIViewAnimationCurveEaseOut animations:^(){
                self.view.transform = CGAffineTransformTranslate([self baseTransform], -floorf(CGRectGetWidth(main_frame) - RevealNavigationSideBarWidth), 0);
            }completion:nil];
            
        }
    } else {
        if(animation == RevealAnimationNone){
            self.view.transform = CGAffineTransformTranslate([self baseTransform], 0, 0);
            [revealedView removeFromSuperview];
        }
        else if(animation == RevealAnimationOpenFullThenClose){
            [UIView animateWithDuration:RevealAnimationDuration * .5f delay:.0f options:UIViewAnimationCurveEaseIn animations:^(){
                self.view.transform = CGAffineTransformTranslate([self baseTransform], -CGRectGetWidth(main_frame), 0);
            }completion:^(BOOL finished){
                [UIView animateWithDuration:RevealAnimationDuration delay:.0f options:UIViewAnimationCurveEaseOut animations:^(){
                    self.view.transform = CGAffineTransformTranslate([self baseTransform], 0, 0); 
                }completion:^(BOOL finished){
                    [revealedView removeFromSuperview];
                }];
            }];
        }
        else{
            [UIView animateWithDuration:RevealAnimationDuration delay:.0f options:UIViewAnimationCurveEaseOut animations:^(){
                self.view.transform = CGAffineTransformTranslate([self baseTransform], 0, 0); 
            }completion:^(BOOL finished){
                [revealedView removeFromSuperview];
            }];
        }
    }
	if ( [delegate respondsToSelector:@selector(sidebarDidChangeState)]) {
		[delegate sidebarDidChangeState];
	}
}

@end


@implementation UINavigationController (JTRevealSidebarV2)

- (UIViewController *)selectedViewController {
    return self.topViewController;
}

@end