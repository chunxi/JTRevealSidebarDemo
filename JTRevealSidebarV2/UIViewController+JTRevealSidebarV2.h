/*
 * This file is part of the JTRevealSidebar package.
 * (c) James Tang <mystcolor@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <UIKit/UIKit.h>
extern const CGFloat RevealAnimationDuration;
extern const CGFloat RevealNavigationSideBarWidth;
typedef enum {
    JTRevealedStateNo,
    JTRevealedStateLeft,
    JTRevealedStateRight,
} JTRevealedState;

typedef enum {
    RevealAnimationNone,
    RevealAnimationNormal,
    RevealAnimationOpenFullThenClose
} RevealAnimation;

@interface UIViewController (JTRevealSidebarV2)

@property (nonatomic, assign) JTRevealedState revealedState;
- (void)setRevealedState:(JTRevealedState)revealedState withAnimation:(RevealAnimation)animation;
- (CGAffineTransform)baseTransform;

@end


@interface UINavigationController (JTRevealSidebarV2)
- (UIViewController *)selectedViewController;
@end

