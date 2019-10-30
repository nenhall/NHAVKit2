//
//  NHVideoRecordViewController.m
//  NHCaptureDemo
//
//  Created by nenhall on 2019/3/11.
//  Copyright © 2019 nenhall. All rights reserved.
//

#import "NHVideoRecordViewController.h"
#import <NHPlayKit/NHPlayKit.h>
#import <NHCaptureKit/NHCaptureKit.h>
#import "NHVideoProgress.h"


#define VIDEO_FILE @"test.mov"
#define kMoveSourcesPath  [[NSBundle mainBundle] pathForResource:@"I’m-so-sick-1080P—Apink" ofType:@"mp4"]

@interface NHVideoRecordViewController ()<NHCaptureSessionProtocol,GPUImageMovieDelegate>
@property (weak, nonatomic) IBOutlet NHGPUImageView *previewView;
@property (weak, nonatomic) IBOutlet UIButton *playBtn;
@property (weak, nonatomic) IBOutlet UIButton *backBtn;
@property (nonatomic, strong) NHAVCapture  *captureSession;
@property (nonatomic, strong) NSMutableArray *videos;
@property (nonatomic, strong) NHVideoProgress *videoProgressView;
@property (nonatomic, strong) NHAVPlayer *player;

@end

@implementation NHVideoRecordViewController {
    GPUImageBilateralFilter*pixellateFilter;
    GPUImageMovie*movieFile;
    GPUImageMovieWriter*movieWriter;
    GPUImageVideoCamera *_videoCamera;
    NHImageBeautifyFilter*beautifyFilter;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    self.videoProgressView.frame = CGRectMake(10, NHStatusBarHeight, self.view.width - 20, 20);

}


- (NHVideoProgress *)videoProgressView {
    if (!_videoProgressView) {
        _videoProgressView = [[NHVideoProgress alloc] initWithFrame:CGRectMake(10, NHStatusBarHeight, self.view.width - 20, 10)];
        [self.view addSubview:_videoProgressView];
    }
    return _videoProgressView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _videos = [[NSMutableArray alloc] initWithCapacity:3];
    
    [self initializeAVSession];
//    [self GPUImageMovie];
//    [self GPUCamera];
  
    [self videoProgressView];

}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
  [_captureSession setOutputType:NHOutputTypeMovieFileStillImage];
}

- (void)initializeAVSession {
    _captureSession = [NHAVCapture sessionWithPreviewView:_previewView outputType:NHOutputTypeStillImage];
    _captureSession.autoLayoutSubviews = NO;
    _captureSession.outputURL = [NSURL fileURLWithPath:[self outputURL]];
    _captureSession.delegate = self;
    [_captureSession startCapture];
    
}

- (void)GPUCamera {
    _videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720 cameraPosition:AVCaptureDevicePositionFront];
    _videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    _videoCamera.horizontallyMirrorFrontFacingCamera = YES;
//    ///添加加载输入输出流（用来解决 解决获取视频第一帧图片黑屏问题，不加也行，哈哈）
    [_videoCamera addAudioInputsAndOutputs];

//    //初始化滤镜
    beautifyFilter = [[NHImageBeautifyFilter alloc] init];
    [_videoCamera addTarget:beautifyFilter];
    [beautifyFilter addTarget:_previewView];
    [_videoCamera startCameraCapture];

    NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.mp4"];
    unlink([pathToMovie UTF8String]);
    NSURL *movieURL = [NSURL fileURLWithPath:pathToMovie];
    
    movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(720, 1280)];
    [beautifyFilter addTarget:movieWriter];
    // 是否不处理视频中的音频
    
    movieWriter.shouldPassthroughAudio = YES;
    _videoCamera.audioEncodingTarget = movieWriter;
    

}

- (void)GPUImageMovie {
//    movieFile = [[GPUImageMovie alloc] initWithURL:[NSURL fileURLWithPath:kMoveSourcesPath]];
    AVAsset *asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:kMoveSourcesPath]];
    
    NHAVPlayer *player = [NHAVPlayer playerWithView:nil playUrl:kMoveSourcesPath];
    _player = player;
    movieFile = [[GPUImageMovie alloc] init];
    movieFile.delegate = self;
    GPUImageFilter *pixellateFilter = [[GPUImageSketchFilter alloc] init];
    [pixellateFilter addTarget:_previewView];
    [movieFile addTarget:pixellateFilter];
    // 按视频真实帧率播放
//    movieFile.playAtActualSpeed = YES;

    NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.mp4"];
    unlink([pathToMovie UTF8String]);
    NSURL *movieURL = [NSURL fileURLWithPath:pathToMovie];
    
    movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(1920.0, 1080.0)];
    [pixellateFilter addTarget:movieWriter];
    // 是否不处理视频中的音频
    movieWriter.shouldPassthroughAudio = YES;
    movieFile.audioEncodingTarget = movieWriter;
    
    [movieFile enableSynchronizedEncodingUsingMovieWriter:movieWriter];
    
    [movieFile startProcessing];
    [_player play];
    [movieWriter startRecording];
    [movieWriter setCompletionBlock:^{
        NSLog(@"写入完成");
    }];
    
}

#pragma mark - GPUImageMovieDelegate
- (void)didCompletePlayingMovie {
    [movieWriter finishRecording];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [_captureSession layoutSubviews];
}

- (BOOL)shouldAutorotate {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return YES;
    }
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return UIInterfaceOrientationMaskAll;
    }
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return UIInterfaceOrientationPortrait;
    }
    return UIInterfaceOrientationPortrait;
}


//- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
//    [[_previewLayer connection] setVideoOrientation:[self currentVideoOrientation]];
//}


- (IBAction)playVideo:(UIButton *)sender {
    
}

//镜像切换
- (IBAction)changeCaptureImage:(UIButton*)button {
    [_captureSession setCameraMirrored:!_captureSession.cameraMirrored];
}

/** 相机设置 */
- (IBAction)caputerSetting:(id)sender {
    [_captureSession setFlashMode:AVCaptureFlashModeOn];
    
    static float p = 0.1;
    if (p == 0.2 || p == 0.4) {
        [_videoProgressView setDrawProgress:p color:[UIColor redColor]];

    } else {
        [_videoProgressView setDrawProgress:p color:[UIColor orangeColor]];
    }
    p += 0.1;


}

- (IBAction)back:(UIButton *)sender {
    [movieFile endProcessing];
    [movieWriter cancelRecording];
    [self dismissViewControllerAnimated:YES completion:nil];
}

/** 切换摄像头 */
- (IBAction)changeCameras:(UIButton *)button {
    [_captureSession rotateCamera];
}

/** 拍照 */
- (IBAction)takePhoto:(UIButton *)button {
  [_captureSession takePhotoSavedPhotosAlbum:YES isScaling:NO complete:^(UIImage * _Nonnull image) {
    
  }];
}

/**
 开始捕捉
 */
- (IBAction)startCapture:(UIButton *)button {
    if (button.selected) {
        button.selected = NO;
//        [_captureSession stopCapture];
        [_captureSession finishRecording];
        
        [movieWriter finishRecordingWithCompletionHandler:^{
            NSLog(@"");
        }];

    } else {
        button.selected = YES;
//        [_captureSession startCapture];
        [movieWriter startRecording];
        [_captureSession startWriteMovieToFileWithOutputURL:[NSURL fileURLWithPath:[self outputURL]]];

    }
}

#pragma mark - NHCaptureSessionProtocol
#pragma mark -
- (void)captureDidOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer outputType:(NHOutputType)outputType {
//  kNSLog(@"");
    [movieFile processMovieFrame:sampleBuffer];
}

- (void)captureShouldBeginWriteMovieToFileAtURL:(NSURL *)fileURL {
    
}

- (void)captureDidFailedWriteMovieToFile:(NSError *)error {
    
}

- (void)captureDidFinishWriteMovieToFile:(NSURL *)outputURL {
    NHExportConfig *config = [[NHExportConfig alloc] init];
    config.exportUrl = [NSURL fileURLWithPath:[self exportURL]];
    // [framework] CUIThemeStore: No theme registered with id=0
    __weak typeof(self) weakself = self;
    [_captureSession exportVidelWithUrl:outputURL exportConfig:config progress:^(CGFloat value) {
        NSLog(@"%f",value);
        nh_safe_dispatch_main_q(^{
            [MBProgressHUD showDownToView:self.view progressStyle:NHHUDProgressAnnularDeterminate title:@"正在导出" progress:^(MBProgressHUD *hud) {
                hud.progress = value;
            }];
        });
        
    } completed:^(NSURL * _Nonnull exportURL, NSError * _Nonnull error) {
        [self.videos addObject:outputURL];

        nh_safe_dispatch_main_q(^{
            [MBProgressHUD hideHUDForView:self.view];
            [MBProgressHUD showSuccess:@"导出成功" toView:self.view];
            [weakself gotoVideoProcess];
        });
        
    } savedPhotosAlbum:YES];
}

- (void)gotoVideoProcess {
//    NHVideoProcessController *process = [[NHVideoProcessController alloc] init];
//    process.videos = self.videos;
//    [self.navigationController pushViewController:process animated:YES];
}


#pragma mark - Recoding Destination URL
- (NSString *)outputURL {
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:VIDEO_FILE];
    return filePath;
}

- (NSString *)exportURL {
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%ld.mp4",[NSDate timeStamp]]];
    return filePath;
}

/**
 
 
 //创建数据流协调
 _capSession = [[AVCaptureSession alloc] init];
 _capSession.sessionPreset = AVCaptureSessionPreset1280x720;
 
 //输入设备
 AVCaptureDevice *capDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
 NSError *capLockError;
 BOOL lock = [capDevice lockForConfiguration:&capLockError];
 if (lock) {
 AVCaptureDeviceFormat *format = capDevice.formats.firstObject;
 NSLog(@"%ld----%@",capDevice.formats.count,format.videoSupportedFrameRateRanges);
 //设置视频帧率
 capDevice.activeVideoMaxFrameDuration = CMTimeMake(1, 10);
 [capDevice unlockForConfiguration];
 }
 
 
 //音频输入
 AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
 AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:nil];
 
 AVCaptureAudioDataOutput *audioOutput = [[AVCaptureAudioDataOutput alloc] init];
 [audioOutput setSampleBufferDelegate:self queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
 
 
 //输入端口管理
 NSError *capDevError;
 AVCaptureDeviceInput *capDevInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self cameraWithPosition:AVCaptureDevicePositionFront] error:&capDevError];;
 _capDevInput = capDevInput;
 
 // Setup the still image file output
 // 将输出流设置成JPEG的图片格式输出，这里输出流的设置参数AVVideoCodecJPEG参数表示以JPEG的图片格式输出图片
 AVCaptureStillImageOutput *stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
 [stillImageOutput setOutputSettings:@{AVVideoCodecKey : AVVideoCodecJPEG}];
 _stillImageOutput = stillImageOutput;
 
 
 //创建输出流
 AVCaptureVideoDataOutput *videoDataOut = [[AVCaptureVideoDataOutput alloc] init];
 dispatch_queue_t videoDataOutQueue_c = dispatch_queue_create("videoDataOutQueue", DISPATCH_QUEUE_SERIAL);
 [videoDataOut setSampleBufferDelegate:self queue:videoDataOutQueue_c];
 _videoDataOut = videoDataOut;
 videoDataOut.videoSettings = [NSDictionary dictionaryWithObject:
 [NSNumber numberWithInt:kCVPixelFormatType_32BGRA]
 forKey:(id)kCVPixelBufferPixelFormatTypeKey];
 
 
 [_capSession beginConfiguration];
 
 if ([self.capSession canAddOutput:stillImageOutput]) {
 [self.capSession addOutput:stillImageOutput];
 }
 
 if ([_capSession canAddInput:capDevInput]) {
 [_capSession addInput:capDevInput];
 }
 
 if ([_capSession canAddInput:audioInput]) {
 [_capSession addInput:audioInput];
 }
 
 if ([_capSession canAddOutput:audioOutput]) {
 [_capSession addOutput:audioOutput];
 }
 
 if ([_capSession canAddOutput:videoDataOut]) {
 [_capSession addOutput:videoDataOut];
 }
 
 [self setupFaceSessionOutput:_capSession];
 
 [_capSession commitConfiguration];
 [_capSession startRunning];
 */

@end
