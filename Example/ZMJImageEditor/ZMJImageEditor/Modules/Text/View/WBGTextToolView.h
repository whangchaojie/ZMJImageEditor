//
//  WBGTextToolView.h
//  CLImageEditorDemo
//
//  Created by Jason on 2017/3/2.
//  Copyright © 2017年 CALACULU. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WBGTextTool.h"
#import "WBGTextToolOverlapView.h"

@interface WBGTextToolView : UIView
@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) UIFont *font;
@property (nonatomic, strong) UIColor *fillColor;
@property (nonatomic, strong) UIColor *borderColor;
@property (nonatomic, assign) CGFloat borderWidth;
@property (nonatomic, assign) NSTextAlignment textAlignment;
@property (nonatomic, strong) UIImage *image;

@property (nonatomic, strong) WBGTextToolOverlapView *archerBGView;

+ (void)setActiveTextView:(WBGTextToolView *)view;
+ (void)setInactiveTextView:(WBGTextToolView *)view;
+ (void)hideTextBorder;

- (instancetype)initWithTool:(WBGTextTool *)tool text:(NSString *)text font:(UIFont *)font orImage:(UIImage *)image;
- (void)rotate:(CGFloat)angle;
- (void)setScale:(CGFloat)scale;
- (void)sizeToFitWithMaxWidth:(CGFloat)width lineHeight:(CGFloat)lineHeight;

@end

@interface WBGTextLabel : UILabel
@property (nonatomic, strong) UIColor *outlineColor;
@property (nonatomic, assign) CGFloat outlineWidth;
@end
