//
//  WBGImageEditorViewController.m
//  CLImageEditorDemo
//
//  Created by Jason on 2017/2/27.
//  Copyright © 2017年 CALACULU. All rights reserved.
//

#import "WBGImageEditorViewController.h"
#import "WBGImageToolBase.h"
#import "WBGColorfullButton.h"
#import "WBGDrawTool.h"
#import "WBGTextTool.h"
#import "TOCropViewController.h"
#import "UIImage+CropRotate.h"
#import "WBGTextToolView.h"
#import "UIView+YYAdd.h"
#import "WBGImageEditor.h"
#import "WBGMoreKeyboard.h"
#import "WBGMosicaViewController.h"
#import "XXNibBridge.h"
#import "YYCategories.h"
#import "WBGMosicaTool.h"


#pragma mark - WBGImageEditorViewController

@interface WBGImageEditorViewController () <UINavigationBarDelegate,
UIScrollViewDelegate, TOCropViewControllerDelegate, WBGMoreKeyboardDelegate, WBGKeyboardDelegate>

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *topBarTop;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *bottomBarBottom;

@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *finishButton;
@property (weak, nonatomic) IBOutlet UIView *bottomBar;
@property (weak, nonatomic) IBOutlet UIView *topBar;

@property (nonatomic, assign) WBGEditorMode currentMode;
@property (strong, nonatomic) WBGColorPanel *colorPanel;

@property (strong, nonatomic) UIView *topBannerView;
@property (strong, nonatomic) UIView *bottomBannerView;

@property (weak,   nonatomic) IBOutlet UIImageView *imageView;
@property (weak,   nonatomic) IBOutlet UIScrollView *scrollView;

@property (strong, nonatomic) UIImageView *drawingView;
@property (strong, nonatomic) WBGScratchView *mosicaView;

@property (weak, nonatomic) IBOutlet UIButton *panButton;
@property (weak, nonatomic) IBOutlet UIButton *textButton;
@property (weak, nonatomic) IBOutlet UIButton *clipButton;
@property (weak, nonatomic) IBOutlet UIButton *paperButton;

@property (nonatomic, strong) WBGImageToolBase *currentTool;
@property (nonatomic, strong) WBGDrawTool *drawTool;
@property (nonatomic, strong) WBGTextTool *textTool;
@property (nonatomic, strong) WBGMosicaTool *mosicaTool;

@property (nonatomic, copy) UIImage *originImage;

@property (nonatomic, assign) CGFloat clipInitScale;
@property (nonatomic, assign) BOOL barsHiddenStatus;
@property (nonatomic, strong) WBGMoreKeyboard *keyboard;

@end

@implementation WBGImageEditorViewController

- (id)init
{
    self = [self initWithNibName:@"WBGImageEditorViewController"
                          bundle:[NSBundle bundleForClass:self.class]];
    
    return self;
}

- (id)initWithImage:(UIImage *)image
{
    return [self initWithImage:image delegate:nil dataSource:nil];
}

- (id)initWithImage:(UIImage*)image
           delegate:(id<WBGImageEditorDelegate>)delegate
         dataSource:(id<WBGImageEditorDataSource>)dataSource;
{
    self = [self init];
    
    if (self)
    {
        _originImage = image;
        self.delegate = delegate;
        self.dataSource = dataSource;
    }
    return self;
}

- (id)initWithDelegate:(id<WBGImageEditorDelegate>)delegate
{
    self = [self init];
    if (self){
        
        self.delegate = delegate;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    @weakify(self);
    self.colorPanel = [WBGColorPanel xx_instantiateFromNib];
    [self.colorPanel setUndoButtonTappedBlock:^{
        @strongify(self);
        [self undoAction];
    }];
    
    // self.undoButton.hidden = YES;
    
    //self.colorPan.frame = CGRectMake([UIScreen mainScreen].bounds.size.width - 60, 100, self.colorPan.bounds.size.width, self.colorPan.bounds.size.height);
    self.colorPanel.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height-99, [UIScreen mainScreen].bounds.size.width, 50);
    self.colorPanel.dataSource = self.dataSource;
    [self.view addSubview:_colorPanel];
    
    [self initImageScrollView];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                 (int64_t)(.25 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        @strongify(self)
        if ([self.dataSource respondsToSelector:@selector(imageEditorCompoment)] &&
            ([self.dataSource imageEditorCompoment] & WBGImageEditorDrawComponent))
        {
            [self.panButton sendActionsForControlEvents:UIControlEventTouchUpInside];
        }
    });
    
    self.panButton.hidden = YES;
    self.textButton.hidden = YES;
    self.clipButton.hidden = YES;
    self.paperButton.hidden = YES;
    self.colorPanel.hidden = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //ShowBusyIndicatorForView(self.view);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      //  HideBusyIndicatorForView(self.view);
        [self refreshImageView];
    });
    
    //获取自定制组件 - fecth custom config
    [self configCustomComponent];
}

- (void)configCustomComponent
{
    NSMutableArray *valibleCompoment = [NSMutableArray new];
    WBGImageEditorComponent curComponent = [self.dataSource respondsToSelector:@selector(imageEditorCompoment)] ? [self.dataSource imageEditorCompoment] : 0;
    
    if (curComponent == 0)
    {
        curComponent = WBGImageEditorALLComponent;
    }
    
    if (curComponent & WBGImageEditorDrawComponent)
    {
        self.panButton.hidden = NO;
        [valibleCompoment addObject:self.panButton];
    }
    
    if (curComponent & WBGImageEditorTextComponent)
    {
        self.textButton.hidden = NO;
        [valibleCompoment addObject:self.textButton];
    }
    
    if (curComponent & WBGImageEditorPaperComponent)
    {
        self.paperButton.hidden = NO;
        [valibleCompoment addObject:self.paperButton];
    }
    
    if (curComponent & WBGImageEditorClipComponent)
    {
        self.clipButton.hidden = NO;
        [valibleCompoment addObject:self.clipButton];
    }
    
    if (curComponent & WBGImageEditorColorPanComponent)
    {
        self.colorPanel.hidden = NO;
    }
    
    [valibleCompoment enumerateObjectsUsingBlock:^(UIButton * _Nonnull button,
                                                   NSUInteger idx,
                                                   BOOL * _Nonnull stop)
    {
        CGRect originFrame = button.frame;
        originFrame.origin.x = idx == 0 ?(idx + 1) * 30.f : (idx + 1) * 30.f + originFrame.size.width * idx;
        button.frame = originFrame;
    }];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    if (!self.mosicaView)
    {
        self.mosicaView = [[WBGScratchView alloc] initWithFrame:self.imageView.superview.frame];
        self.mosicaView.surfaceImage = self.originImage;
        self.mosicaView.backgroundColor = [UIColor clearColor];
        [self.imageView.superview addSubview:self.mosicaView];
    }
    
    if (!self.drawingView)
    {
        self.drawingView = [[UIImageView alloc] initWithFrame:self.imageView.superview.frame];
        self.drawingView.contentMode = UIViewContentModeCenter;
        self.drawingView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin;
        [self.imageView.superview addSubview:self.drawingView];
        self.drawingView.userInteractionEnabled = YES;
    }
    
    self.topBannerView.frame = CGRectMake(0, 0, self.imageView.width, CGRectGetMinY(self.imageView.frame));
    self.bottomBannerView.frame = CGRectMake(0, CGRectGetMaxY(self.imageView.frame), self.imageView.width, self.drawingView.height - CGRectGetMaxY(self.imageView.frame));
}

- (UIView *)topBannerView
{
    if (!_topBannerView)
    {
        _topBannerView =
        ({
            UIView *view = [[UIView alloc] init];
            view.backgroundColor = self.scrollView.backgroundColor;
            [self.imageView.superview addSubview:view];
            view;
        });
    }
    
    return _topBannerView;
}

- (UIView *)bottomBannerView
{
    if (!_bottomBannerView)
    {
        _bottomBannerView =
        ({
            UIView *view = [[UIView alloc] init];
            view.backgroundColor = self.scrollView.backgroundColor;
            [self.imageView.superview addSubview:view];
            view;
        });
    }
    return _bottomBannerView;
}

#pragma mark - 初始化 &getter
- (WBGDrawTool *)drawTool
{
    if (_drawTool == nil)
    {
        _drawTool = [[WBGDrawTool alloc] initWithImageEditor:self];
        
        __weak typeof(self)weakSelf = self;
        _drawTool.drawToolStatus = ^(BOOL canPrev) {
            //if (canPrev) {
            //    weakSelf.undoButton.hidden = NO;
            //} else {
            //    weakSelf.undoButton.hidden = YES;
            //}
        };
        _drawTool.drawingCallback = ^(BOOL isDrawing) {
            [weakSelf hiddenTopAndBottomBar:isDrawing animation:YES];
        };
        _drawTool.drawingDidTap = ^(void) {
            [weakSelf hiddenTopAndBottomBar:!weakSelf.barsHiddenStatus animation:YES];
        };
        _drawTool.pathWidth = [self.dataSource respondsToSelector:@selector(imageEditorDrawPathWidth)] ? [self.dataSource imageEditorDrawPathWidth].floatValue : 5.0f;
    }
    
    return _drawTool;
}

- (WBGTextTool *)textTool
{
    if (_textTool == nil)
    {
        _textTool = [[WBGTextTool alloc] initWithImageEditor:self];
        __weak typeof(self)weakSelf = self;
        _textTool.dissmissTextTool = ^(NSString *currentText)
        {
            [weakSelf hiddenColorPan:NO animation:YES];
            weakSelf.currentMode = WBGEditorModeNone;
            weakSelf.currentTool = nil;
        };
    }
    
    return _textTool;
}

- (WBGMosicaTool *)mosicaTool
{
    if (_mosicaTool == nil)
    {
        _mosicaTool = [[WBGMosicaTool alloc] initWithImageEditor:self];
    }
    
    return _mosicaTool;
}

- (void)initImageScrollView
{
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.delegate = self;
    self.scrollView.clipsToBounds = NO;
    self.scrollView.backgroundColor = [UIColor blackColor];

}

- (void)refreshImageView
{
    if (self.imageView.image == nil)
    {
        self.imageView.image = self.originImage;
    }
    
    [self resetImageViewFrame];
    [self resetZoomScaleWithAnimated:NO];
    [self viewDidLayoutSubviews];
}

- (void)resetImageViewFrame
{
    CGSize size = (_imageView.image) ? _imageView.image.size : _imageView.frame.size;
    if(size.width > 0 && size.height > 0 )
    {
        CGFloat ratio = MIN(_scrollView.frame.size.width / size.width, _scrollView.frame.size.height / size.height);
        CGFloat W = ratio * size.width * _scrollView.zoomScale;
        CGFloat H = ratio * size.height * _scrollView.zoomScale;
        
        _imageView.frame = CGRectMake(MAX(0, (_scrollView.width-W)/2), MAX(0, (_scrollView.height-H)/2), W, H);
    }
}

- (void)resetZoomScaleWithAnimated:(BOOL)animated
{
    CGFloat Rw = _scrollView.frame.size.width / _imageView.frame.size.width;
    CGFloat Rh = _scrollView.frame.size.height / _imageView.frame.size.height;
    
    //CGFloat scale = [[UIScreen mainScreen] scale];
    CGFloat scale = 1;
    Rw = MAX(Rw, _imageView.image.size.width / (scale * _scrollView.frame.size.width));
    Rh = MAX(Rh, _imageView.image.size.height / (scale * _scrollView.frame.size.height));
    
    _scrollView.contentSize = _imageView.frame.size;
    _scrollView.minimumZoomScale = 1;
    _scrollView.maximumZoomScale = MAX(MAX(Rw, Rh), 3);
    
    [_scrollView setZoomScale:_scrollView.minimumZoomScale animated:animated];
    [self scrollViewDidZoom:_scrollView];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

#pragma mark- ScrollView delegate
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return _imageView.superview;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    
}

#pragma mark - Property
- (void)setCurrentTool:(WBGImageToolBase *)currentTool
{
    if(_currentTool != currentTool)
    {
        [_currentTool cleanup];
        _currentTool = currentTool;
        [_currentTool setup];
        
    }
    
    [self swapToolBarWithEditting];
}

#pragma mark- ImageTool setting
+ (NSString*)defaultIconImagePath
{
    return nil;
}

+ (CGFloat)defaultDockedNumber
{
    return 0;
}

+ (NSString *)defaultTitle
{
    return @"";
}

+ (BOOL)isAvailable
{
    return YES;
}

+ (NSArray *)subtools
{
    return [NSArray new];
}

+ (NSDictionary*)optionalInfo
{
    return nil;
}

#pragma mark - Undo
- (void)undoAction
{
    if (self.currentMode == WBGEditorModeDraw)
    {
        WBGDrawTool *tool = (WBGDrawTool *)self.currentTool;
        [tool backToLastDraw];
    }
}


#pragma mark - Actions
///发送
- (IBAction)sendAction:(UIButton *)sender
{

    [self buildClipImageShowHud:YES clipedCallback:^(UIImage *clipedImage) {
        if ([self.delegate respondsToSelector:@selector(imageEditor:didFinishEdittingWithImage:)]) {
            [self.delegate imageEditor:self didFinishEdittingWithImage:clipedImage];
        }
    }];
    
}

///涂鸦模式
- (IBAction)panAction:(UIButton *)sender
{
    if (_currentMode == WBGEditorModeDraw)
    {
        return;
    }
    //先设置状态，然后在干别的
    self.currentMode = WBGEditorModeDraw;
    
    self.currentTool = self.drawTool;
}

///裁剪模式
- (IBAction)clipAction:(UIButton *)sender
{
    
    [self buildClipImageShowHud:NO
                 clipedCallback:^(UIImage *clipedImage)
     {
        TOCropViewController *cropController = [[TOCropViewController alloc] initWithCroppingStyle:TOCropViewCroppingStyleDefault image:clipedImage];
        cropController.delegate = self;
        __weak typeof(self) weakSelf = self;
         
        CGRect viewFrame = [self.view convertRect:self.imageView.frame
                                           toView:self.navigationController.view];
         
        [cropController presentAnimatedFromParentViewController:self
                                                      fromImage:clipedImage
                                                       fromView:nil
                                                      fromFrame:viewFrame
                                                          angle:0
                                                   toImageFrame:CGRectZero
                                                          setup:^{
                                                              [weakSelf refreshImageView];
                                                              weakSelf.colorPanel.hidden = YES;
                                                              weakSelf.currentMode = WBGEditorModeClip;
                                                              [weakSelf setCurrentTool:nil];
                                                          }
                                                     completion:^{
                                                     }];
    }];
    
}

//文字模式
- (IBAction)textAction:(UIButton *)sender
{
    if (_currentMode == WBGEditorModeText)
    {
        return;
    }
    //先设置状态，然后在干别的
    self.currentMode = WBGEditorModeText;
    
    self.currentTool = self.textTool;
    [self hiddenColorPan:YES animation:YES];
}

//马赛克模式
- (IBAction)paperAction:(UIButton *)sender {
    if (_currentMode == WBGEditorModeMosica)
    {
        return;
    }
    
    self.currentMode = WBGEditorModeMosica;
    self.currentTool = self.mosicaTool;
}

- (IBAction)backAction:(UIButton *)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)undoAction:(UIButton *)sender
{
    if (self.currentMode == WBGEditorModeDraw)
    {
        WBGDrawTool *tool = (WBGDrawTool *)self.currentTool;
        [tool backToLastDraw];
    }
}

- (void)editTextAgain
{
    //WBGTextTool 钩子调用
    
    if (_currentMode == WBGEditorModeText)
    {
        return;
    }
    //先设置状态，然后在干别的
    self.currentMode = WBGEditorModeText;
    
    if(_currentTool != self.textTool)
    {
        [_currentTool cleanup];
        _currentTool = self.textTool;
        [_currentTool setup];

    }
    
    [self hiddenColorPan:YES animation:YES];
}

- (IBAction)onFinishButtonTapped:(UIButton *)sender
{
    
}

//贴图模块
- (IBAction)onPicButtonTapped:(UIButton *)sender
{
    NSArray<WBGMoreKeyboardItem *> *sources = nil;
    if (self.dataSource) {
        sources = [self.dataSource imageItemsEditor:self];
    }
    
    [self.keyboard setChatMoreKeyboardData:sources.mutableCopy];
    [self.keyboard showInView:self.view withAnimation:YES];
}

- (void)resetCurrentTool
{
    self.currentMode = WBGEditorModeNone;
    self.currentTool = nil;
}

- (WBGMoreKeyboard *)keyboard
{
    if (!_keyboard)
    {
        WBGMoreKeyboard *keyboard = [WBGMoreKeyboard keyboard];
        [keyboard setKeyboardDelegate:self];
        [keyboard setDelegate:self];
        _keyboard = keyboard;
    }
    
    return _keyboard;
}

#pragma mark - WBGMoreKeyboardDelegate
- (void)moreKeyboard:(id)keyboard didSelectedFunctionItem:(WBGMoreKeyboardItem *)funcItem
{
    WBGMoreKeyboard *kb = (WBGMoreKeyboard *)keyboard;
    [kb dismissWithAnimation:YES];
    
    
    WBGTextToolView *view = [[WBGTextToolView alloc] initWithTool:self.textTool text:@"" font:nil orImage:funcItem.image];
    view.borderColor = [UIColor whiteColor];
    view.image = funcItem.image;
    view.center = [self.imageView.superview convertPoint:self.imageView.center toView:self.drawingView];
    view.userInteractionEnabled = YES;
    [self.drawingView addSubview:view];
    [WBGTextToolView setActiveTextView:view];
    
}

#pragma mark - Cropper Delegate
- (void)cropViewController:(TOCropViewController *)cropViewController
            didCropToImage:(UIImage *)image
                  withRect:(CGRect)cropRect angle:(NSInteger)angle
{
    [self updateImageViewWithImage:image fromCropViewController:cropViewController];
}

- (void)updateImageViewWithImage:(UIImage *)image fromCropViewController:(TOCropViewController *)cropViewController
{
    self.imageView.image = image;
    __unused CGFloat drawingWidth = self.drawingView.bounds.size.width;
    CGRect bounds = cropViewController.cropView.foregroundImageView.bounds;
    bounds.size = CGSizeMake(bounds.size.width/self.clipInitScale, bounds.size.height/self.clipInitScale);
    
    [self refreshImageView];
    [self viewDidLayoutSubviews];


    self.navigationItem.rightBarButtonItem.enabled = YES;
    __weak typeof(self)weakSelf = self;
    if (cropViewController.croppingStyle != TOCropViewCroppingStyleCircular) {

        [cropViewController dismissAnimatedFromParentViewController:self
                                                   withCroppedImage:image
                                                             toView:self.imageView
                                                            toFrame:CGRectZero
                                                              setup:^{
                                                                  [weakSelf refreshImageView];
                                                                  [weakSelf viewDidLayoutSubviews];
                                                                  weakSelf.colorPanel.hidden = NO;
                                                              }
                                                         completion:^{
                                                             weakSelf.colorPanel.hidden = NO;
                                                         }];
    }
    else
    {
        
        [cropViewController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    }
    
    //生成图片后，清空画布内容
    [self.drawTool.allLineMutableArray removeAllObjects];
    [self.drawTool drawLine];
    [_drawingView removeAllSubviews];
}

- (void)cropViewController:(TOCropViewController *)cropViewController didFinishCancelled:(BOOL)cancelled {
    
    __weak typeof(self)weakSelf = self;
    [cropViewController dismissAnimatedFromParentViewController:self
                                               withCroppedImage:self.imageView.image
                                                         toView:self.imageView
                                                        toFrame:CGRectZero
                                                          setup:^{
                                                              [weakSelf refreshImageView];
                                                              [weakSelf viewDidLayoutSubviews];
                                                              weakSelf.colorPanel.hidden = NO;
                                                          }
                                                     completion:^{
                                                         [UIView animateWithDuration:.3f animations:^{
                                                             weakSelf.colorPanel.hidden = NO;
                                                         }];
                                                         
                                                     }];
}

#pragma mark -
- (void)swapToolBarWithEditting
{
    switch (_currentMode)
    {
        case WBGEditorModeDraw:
        {
            self.panButton.selected = YES;
            if (self.drawTool.allLineMutableArray.count > 0)
            {
                //self.undoButton.hidden  = NO;
            }
        }
            break;
        case WBGEditorModeText:
        case WBGEditorModeClip:
        case WBGEditorModeNone:
        {
            self.panButton.selected = NO;
            //self.undoButton.hidden  = YES;
        }
            break;
        default:
            break;
    }
}

- (void)hiddenTopAndBottomBar:(BOOL)isHide
                    animation:(BOOL)animation
{
    if (self.keyboard.isShow)
    {
        [self.keyboard dismissWithAnimation:YES];
        return;
    }
    
    [UIView animateWithDuration:animation ? .25f : 0.f
                          delay:0
         usingSpringWithDamping:1
          initialSpringVelocity:1
                        options:isHide ? UIViewAnimationOptionCurveEaseOut : UIViewAnimationOptionCurveEaseIn
                     animations:^{
        if (isHide) {
            _bottomBarBottom.constant = -49.f;
            _topBarTop.constant = -64.f;
            self.colorPanel.hidden = YES;
        } else {
            _bottomBarBottom.constant = 0;
            _topBarTop.constant = 0;
            self.colorPanel.hidden = NO;
        }
        _barsHiddenStatus = isHide;
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        
    }];
}

- (void)hiddenColorPan:(BOOL)yesOrNot
             animation:(BOOL)animation
{
    UIViewAnimationOptions options = yesOrNot ? UIViewAnimationOptionCurveEaseOut : UIViewAnimationOptionCurveEaseIn;
    
    [UIView animateWithDuration:animation ? .25f : 0.f
                          delay:0
         usingSpringWithDamping:1
          initialSpringVelocity:1
                        options:options
                     animations:^{
        self.colorPanel.hidden = yesOrNot;
    } completion:^(BOOL finished) {
    
    }];
}

+ (UIImage *)createViewImage:(UIView *)shareView
{
    UIGraphicsBeginImageContextWithOptions(shareView.bounds.size, NO, [UIScreen mainScreen].scale);
    [shareView.layer renderInContext:UIGraphicsGetCurrentContext()];
    shareView.layer.affineTransform = shareView.transform;
    UIImage * image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)buildClipImageShowHud:(BOOL)showHud
               clipedCallback:(void(^)(UIImage *clipedImage))clipedCallback
{
    if (showHud)
    {
        // ShowBusyTextIndicatorForView(self.view, @"生成图片中...", nil);
    }
    
    CGFloat WS = self.imageView.width/ self.drawingView.width;
    CGFloat HS = self.imageView.height/ self.drawingView.height;

    UIGraphicsBeginImageContextWithOptions(self.imageView.size,
                                           NO,
                                           self.imageView.image.scale);

    [self.imageView.image drawAtPoint:CGPointZero];
    CGFloat viewToimgW = self.imageView.width/self.imageView.image.size.width;
    CGFloat viewToimgH = self.imageView.height/self.imageView.image.size.height;
    __unused CGFloat drawX = self.imageView.left/viewToimgW;
    CGFloat drawY = self.imageView.top/viewToimgH;
    [_drawingView.image drawInRect:CGRectMake(0, -drawY, self.imageView.image.size.width/WS, self.imageView.image.size.height/HS)];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        for (UIView *subV in _drawingView.subviews)
        {
            if ([subV isKindOfClass:[WBGTextToolView class]])
            {
                WBGTextToolView *textLabel = (WBGTextToolView *)subV;
                //进入正常状态
                [WBGTextToolView setInactiveTextView:textLabel];
                
                //生成图片
                __unused UIView *tes = textLabel.archerBGView;
                UIImage *textImg = [self.class screenshot:textLabel.archerBGView orientation:UIDeviceOrientationPortrait usePresentationLayer:YES];
                CGFloat rotation = textLabel.archerBGView.layer.transformRotationZ;
                textImg = [textImg imageRotatedByRadians:rotation];
                
                CGFloat selfRw = self.imageView.bounds.size.width / self.imageView.image.size.width;
                CGFloat selfRh = self.imageView.bounds.size.height / self.imageView.image.size.height;
                
                CGFloat sw = textImg.size.width / selfRw;
                CGFloat sh = textImg.size.height / selfRh;
                
                [textImg drawInRect:CGRectMake(textLabel.left/selfRw, (textLabel.top/selfRh) - drawY, sw, sh)];
            }
        }
    });
    
    UIImage *tmp = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    dispatch_async(dispatch_get_main_queue(), ^{
        //HideBusyIndicatorForView(self.view);
        UIImage *image = [UIImage imageWithCGImage:tmp.CGImage scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
        clipedCallback(image);
        
    });
}

+ (UIImage *)screenshot:(UIView *)view
            orientation:(UIDeviceOrientation)orientation
   usePresentationLayer:(BOOL)usePresentationLayer
{
    __block CGSize targetSize = CGSizeZero;
    dispatch_async(dispatch_get_main_queue(), ^{
        CGSize size = view.bounds.size;
        targetSize = CGSizeMake(size.width * view.layer.transformScaleX, size.height *  view.layer.transformScaleY);
    });
    
    UIGraphicsBeginImageContextWithOptions(targetSize, NO, [UIScreen mainScreen].scale);
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);
    dispatch_async(dispatch_get_main_queue(), ^{
        [view drawViewHierarchyInRect:CGRectMake(0, 0, targetSize.width, targetSize.height) afterScreenUpdates:NO];
    });
    CGContextRestoreGState(ctx);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

@end
