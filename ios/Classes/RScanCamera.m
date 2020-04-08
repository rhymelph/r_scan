//
//  RScanCamera.m
//  r_scan
//
//  Created by 李鹏辉 on 2020/2/24.
//

#import "RScanCamera.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreMotion/CoreMotion.h>
#import <libkern/OSAtomic.h>
#import "RScanResult.h"
// Mirrors ResolutionPreset in camera.dart
typedef enum {
    veryLow,
    low,
    medium,
    high,
    veryHigh,
    ultraHigh,
    max,
} ResolutionPreset;

static ResolutionPreset getResolutionPresetForString(NSString *preset) {
    if ([preset isEqualToString:@"veryLow"]) {
        return veryLow;
    } else if ([preset isEqualToString:@"low"]) {
        return low;
    } else if ([preset isEqualToString:@"medium"]) {
        return medium;
    } else if ([preset isEqualToString:@"high"]) {
        return high;
    } else if ([preset isEqualToString:@"veryHigh"]) {
        return veryHigh;
    } else if ([preset isEqualToString:@"ultraHigh"]) {
        return ultraHigh;
    } else if ([preset isEqualToString:@"max"]) {
        return max;
    } else {
        NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain
                                             code:NSURLErrorUnknown
                                         userInfo:@{
                                             NSLocalizedDescriptionKey : [NSString
                                                                          stringWithFormat:@"Unknown resolution preset %@", preset]
                                         }];
        @throw error;
    }
}
//获取错误
static FlutterError *getFlutterError(NSError *error) {
    return [FlutterError errorWithCode:[NSString stringWithFormat:@"%d", (int)error.code]
                               message:error.localizedDescription
                               details:error.domain];
}

@interface RScanFLTCam : NSObject<FlutterTexture,AVCaptureMetadataOutputObjectsDelegate,AVCaptureVideoDataOutputSampleBufferDelegate,FlutterStreamHandler>
@property(readonly, nonatomic) int64_t textureId;
@property(assign, nonatomic) ResolutionPreset resolutionPreset;
//链接相机用的
@property(readonly, nonatomic) AVCaptureSession *captureSession;
//获取相机设备
@property(readonly, nonatomic) AVCaptureDevice *captureDevice;
//视频输入
@property(readonly, nonatomic) AVCaptureInput *captureVideoInput;
//视频输出
@property(readonly, nonatomic) AVCaptureMetadataOutput * captureOutput;
//视频输出2
@property(readonly, nonatomic) AVCaptureVideoDataOutput *captureVideoOutput;
@property(readonly, nonatomic) CGSize previewSize;

@property(nonatomic) FlutterEventSink eventSink;
@property(readonly) CVPixelBufferRef volatile latestPixelBuffer;
//第一帧回掉
@property(nonatomic, copy) void (^onFrameAvailable)(void);
//channel用于返回数据给data
@property(nonatomic) FlutterEventChannel *eventChannel;
@end

@implementation RScanFLTCam{
    dispatch_queue_t _dispatchQueue;
}
FourCharCode const rScanVideoFormat = kCVPixelFormatType_32BGRA;
- (instancetype)initWitchCameraName:(NSString*)cameraName resolutionPreset:(NSString*)resolutionPreset dispatchQueue:(dispatch_queue_t)dispatchQueue error:(NSError **)error{
    self = [super init];
    NSAssert(self, @"super init cannot be nil");
    @try {
        _resolutionPreset =getResolutionPresetForString(resolutionPreset);
    } @catch (NSError *e) {
        *error = e;
    }
    _dispatchQueue =dispatchQueue;
    _captureSession=[[AVCaptureSession alloc]init];
    _captureDevice = [AVCaptureDevice deviceWithUniqueID:cameraName];
    
    NSError *localError =nil;
    _captureVideoInput = [AVCaptureDeviceInput deviceInputWithDevice:_captureDevice error:&localError];
    
    if(localError){
        *error = localError;
        return nil;
    }
   
    _captureVideoOutput = [AVCaptureVideoDataOutput new];
    _captureVideoOutput.videoSettings = @{(NSString*)kCVPixelBufferPixelFormatTypeKey: @(rScanVideoFormat)};
    [_captureVideoOutput setAlwaysDiscardsLateVideoFrames:YES];
    [_captureVideoOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    
    //链接
    AVCaptureConnection* connection =[AVCaptureConnection connectionWithInputPorts:_captureVideoInput.ports output:_captureVideoOutput];
    
    if ([_captureDevice position] == AVCaptureDevicePositionFront) {
        connection.videoMirrored = YES;
    }
    if([connection isVideoOrientationSupported]){
        connection.videoOrientation =AVCaptureVideoOrientationPortrait;
    }
    [_captureSession addInputWithNoConnections:_captureVideoInput];
    [_captureSession addOutputWithNoConnections:_captureVideoOutput];
    
    _captureOutput=[[AVCaptureMetadataOutput alloc]init];

    
    //设置代理，在主线程刷新
    [_captureOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    [_captureSession addOutput:_captureOutput];
    _captureOutput.metadataObjectTypes=_captureOutput.availableMetadataObjectTypes;
    //扫码区域的大小
    AVCaptureVideoPreviewLayer *layer = [AVCaptureVideoPreviewLayer layerWithSession:_captureSession];
    layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
//    layer.frame = CGRectMake(left, top, size, size);
//        [_captureOutput rectOfInterest];
    [_captureOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    [_captureOutput setMetadataObjectTypes:@[AVMetadataObjectTypeAztecCode,AVMetadataObjectTypeCode39Code,
                                     AVMetadataObjectTypeCode93Code,AVMetadataObjectTypeCode128Code, AVMetadataObjectTypeDataMatrixCode,AVMetadataObjectTypeEAN8Code,AVMetadataObjectTypeEAN13Code,AVMetadataObjectTypeITF14Code,AVMetadataObjectTypePDF417Code,AVMetadataObjectTypeQRCode,AVMetadataObjectTypeUPCECode]];
    [_captureSession addConnection:connection];
    [self setCaptureSessionPreset:_resolutionPreset];
    
    return self;
}
- (void)setCaptureSessionPreset:(ResolutionPreset)resolutionPreset {
    switch (resolutionPreset) {
        case max:
            if ([_captureSession canSetSessionPreset:AVCaptureSessionPresetHigh]) {
                _captureSession.sessionPreset = AVCaptureSessionPresetHigh;
                _previewSize =
                CGSizeMake(_captureDevice.activeFormat.highResolutionStillImageDimensions.width,
                           _captureDevice.activeFormat.highResolutionStillImageDimensions.height);
                break;
            }
        case ultraHigh:
            if ([_captureSession canSetSessionPreset:AVCaptureSessionPreset3840x2160]) {
                _captureSession.sessionPreset = AVCaptureSessionPreset3840x2160;
                _previewSize = CGSizeMake(3840, 2160);
                break;
            }
        case veryHigh:
            if ([_captureSession canSetSessionPreset:AVCaptureSessionPreset1920x1080]) {
                _captureSession.sessionPreset = AVCaptureSessionPreset1920x1080;
                _previewSize = CGSizeMake(1920, 1080);
                break;
            }
        case high:
            if ([_captureSession canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
                _captureSession.sessionPreset = AVCaptureSessionPreset1280x720;
                _previewSize = CGSizeMake(1280, 720);
                break;
            }
        case medium:
            if ([_captureSession canSetSessionPreset:AVCaptureSessionPreset640x480]) {
                _captureSession.sessionPreset = AVCaptureSessionPreset640x480;
                _previewSize = CGSizeMake(640, 480);
                break;
            }
        case low:
            if ([_captureSession canSetSessionPreset:AVCaptureSessionPreset352x288]) {
                _captureSession.sessionPreset = AVCaptureSessionPreset352x288;
                _previewSize = CGSizeMake(352, 288);
                break;
            }
        default:
            if ([_captureSession canSetSessionPreset:AVCaptureSessionPresetLow]) {
                _captureSession.sessionPreset = AVCaptureSessionPresetLow;
                _previewSize = CGSizeMake(352, 288);
            } else {
                NSError *error =
                [NSError errorWithDomain:NSCocoaErrorDomain
                                    code:NSURLErrorUnknown
                                userInfo:@{
                                    NSLocalizedDescriptionKey :
                                        @"No capture session available for current capture session."
                                }];
                @throw error;
            }
    }
}

- (void)captureOutput:(AVCaptureOutput *)output didOutputMetadataObjects:(NSArray<__kindof AVMetadataObject *> *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    if (metadataObjects.count>0) {
        AVMetadataMachineReadableCodeObject * metaObject=metadataObjects[0];
        NSString * value=metaObject.stringValue;
        if(value.length&&_eventSink){
            _eventSink([RScanResult toMap:metaObject]);
        }
    }

}

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    if (output == _captureVideoOutput) {
           CVPixelBufferRef newBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
           CFRetain(newBuffer);
           CVPixelBufferRef old = _latestPixelBuffer;
           while (!OSAtomicCompareAndSwapPtrBarrier(old, newBuffer, (void **)&_latestPixelBuffer)) {
               old = _latestPixelBuffer;
           }
           if (old != nil) {
               CFRelease(old);
           }
           if (_onFrameAvailable) {
               _onFrameAvailable();
           }
       }
}


- (void)start{
    [_captureSession startRunning];
}

- (void)stop{
    [_captureSession stopRunning];
}
-(void)resume{
    if(![_captureSession isRunning]){
        [_captureSession startRunning];
    }
}

-(void)pause{
    if ([_captureSession isRunning]) {
        [_captureSession stopRunning];
    }
}

-(BOOL)setFlashMode:(BOOL) isOpen{
    [_captureDevice lockForConfiguration:nil];
    BOOL isSuccess = YES;
    if ([_captureDevice hasFlash]) {
        if (isOpen) {
            _captureDevice.flashMode=AVCaptureFlashModeOn;
            _captureDevice.torchMode=AVCaptureTorchModeOn;
        }else{
            _captureDevice.flashMode = AVCaptureFlashModeOff;
            _captureDevice.torchMode = AVCaptureTorchModeOff;
        }
    }else{
        isSuccess=NO;
    }
    [_captureDevice unlockForConfiguration];
    
    return isSuccess;
    
}
-(BOOL)getFlashMode{
    [_captureDevice lockForConfiguration:nil];
    BOOL isSuccess = _captureDevice.flashMode==AVCaptureFlashModeOn&&
    _captureDevice.torchMode==AVCaptureTorchModeOn;
    [_captureDevice unlockForConfiguration];
    return isSuccess;
}

- (void)close {
    [_captureSession stopRunning];
    for (AVCaptureInput *input in [_captureSession inputs]) {
        [_captureSession removeInput:input];
    }
    for (AVCaptureOutput *output in [_captureSession outputs]) {
        [_captureSession removeOutput:output];
    }
}
- (CVPixelBufferRef _Nullable)copyPixelBuffer {
    CVPixelBufferRef pixelBuffer = _latestPixelBuffer;
    while (!OSAtomicCompareAndSwapPtrBarrier(pixelBuffer, nil, (void **)&_latestPixelBuffer)) {
        pixelBuffer = _latestPixelBuffer;
    }
    
    return pixelBuffer;
}

- (FlutterError * _Nullable)onCancelWithArguments:(id _Nullable)arguments {
    _eventSink = nil;
    [_eventChannel setStreamHandler:nil];
    return nil;
}

- (FlutterError * _Nullable)onListenWithArguments:(id _Nullable)arguments eventSink:(nonnull FlutterEventSink)events {
    _eventSink =events;
    return nil;
}

@end

@interface RScanCamera()
@property(readonly, nonatomic) RScanFLTCam *camera;
@end

@implementation RScanCamera{
    dispatch_queue_t _dispatchQueue;
}

- (instancetype)initWithRegistry:(NSObject<FlutterTextureRegistry> *)registry
                       messenger:(NSObject<FlutterBinaryMessenger> *)messenger {
    self = [super init];
    NSAssert(self, @"super init cannot be nil");
    _registry = registry;
    _messenger = messenger;
    return self;
}

+ (void)registerWithRegistrar:(nonnull NSObject<FlutterPluginRegistrar> *)registrar {
    
}
- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result{
    if ([@"availableCameras" isEqualToString:call.method]) {
        [self availableCameras:call result:result];
    }else if([@"initialize" isEqualToString:call.method]){
        [self initialize:call result:result];
    }else if([@"dispose" isEqualToString:call.method]){
        [self dispose:call result:result];
    }else if ([call.method isEqualToString:@"startScan"]) {
        [_camera resume];
        result(nil);
    }else if([call.method isEqualToString:@"stopScan"]){
        [_camera pause];
        result(nil);
    }else if ([call.method isEqualToString:@"setFlashMode"]){
        NSNumber * isOpen = [call.arguments valueForKey:@"isOpen"];
        result([NSNumber numberWithBool:[_camera setFlashMode:[isOpen boolValue]]]);
    }else if ([call.method isEqualToString:@"getFlashMode"]){
        result([NSNumber numberWithBool:[_camera getFlashMode]]);
    }else{
        result(FlutterMethodNotImplemented);
    }
}


/**
 获取可用的摄像头
 */
-(void)availableCameras:(FlutterMethodCall *)call result:(FlutterResult)result{
    AVCaptureDeviceDiscoverySession *discoverySession = [AVCaptureDeviceDiscoverySession
                                                         discoverySessionWithDeviceTypes:@[ AVCaptureDeviceTypeBuiltInWideAngleCamera ]
                                                         mediaType:AVMediaTypeVideo
                                                         position:AVCaptureDevicePositionUnspecified];
    NSArray<AVCaptureDevice *> *devices = discoverySession.devices;
    NSMutableArray<NSDictionary<NSString *, NSObject *> *> *reply =
    [[NSMutableArray alloc] initWithCapacity:devices.count];
    for (AVCaptureDevice *device in devices) {
        NSString *lensFacing;
        switch ([device position]) {
            case AVCaptureDevicePositionBack:
                lensFacing = @"back";
                break;
            case AVCaptureDevicePositionFront:
                lensFacing = @"front";
                break;
            case AVCaptureDevicePositionUnspecified:
                lensFacing = @"external";
                break;
        }
        [reply addObject:@{
            @"name" : [device uniqueID],
            @"lensFacing" : lensFacing
        }];
    }
    result(reply);
}

/**
 初始化相机
 */
-(void)initialize:(FlutterMethodCall *)call result:(FlutterResult)result {
    NSString *cameraName = call.arguments[@"cameraName"];
    NSString *resolutionPreset = call.arguments[@"resolutionPreset"];
    NSError * error;
    RScanFLTCam* cam =[[RScanFLTCam alloc]initWitchCameraName:cameraName resolutionPreset:resolutionPreset dispatchQueue:_dispatchQueue error:&error];
    if(error){
        result(getFlutterError(error));
        return;
    }else{
        if(_camera){
            [_camera close];
        }
        int64_t textureId = [_registry registerTexture:cam];
        _camera =cam;
        cam.onFrameAvailable = ^{
            [self->_registry textureFrameAvailable:textureId];
        };
        
        FlutterEventChannel *eventChannel = [FlutterEventChannel eventChannelWithName:[NSString  stringWithFormat:@"com.rhyme_lph/r_scan_camera_%lld/event",textureId] binaryMessenger:_messenger];
        [eventChannel setStreamHandler:cam];
        cam.eventChannel = eventChannel;
        result(@{
            @"textureId":@(textureId),
            @"previewWidth":@(cam.previewSize.width),
            @"previewHeight":@(cam.previewSize.height)
        });
        
        [cam start];
    }
    
    
}

/**
 销毁相机
 */
-(void)dispose:(FlutterMethodCall *)call result:(FlutterResult)result {
    NSDictionary *argsMap = call.arguments;
       NSUInteger textureId = ((NSNumber *)argsMap[@"textureId"]).unsignedIntegerValue;
    [_registry unregisterTexture:textureId];
    [_camera close];
    _dispatchQueue = nil;
    result(nil);
}


@end


