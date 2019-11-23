//
//  RScanView.m
//  r_scan
//
//  Created by 李鹏辉 on 2019/11/23.
//

#import "RScanView.h"
#import <AVFoundation/AVFoundation.h>
@interface RScanView()<AVCaptureMetadataOutputObjectsDelegate>

@property(nonatomic , strong)AVCaptureSession * session;
@property(nonatomic , strong)FlutterMethodChannel * _channel;
@property(nonatomic , strong)FlutterRScanViewEventChannel * _event;
@property(nonatomic , strong)AVCaptureVideoPreviewLayer * captureLayer;

- (void)onMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result;

@end

@implementation RScanView

- (AVCaptureSession *)session{
    if(!_session){
        _session=[[AVCaptureSession alloc]init];
    }
    return _session;
}

- (instancetype)initWithFrame:(CGRect)frame viewIdentifier:(int64_t)viewId arguments:(id)args binaryMessenger:(NSObject<FlutterBinaryMessenger> *)messenger{
    if(self = [super initWithFrame:frame]){
        
       NSString * channelName=[NSString stringWithFormat:@"r_scan/com.rhyme/r_scan_view__%lld/method",viewId];
        self._channel=[FlutterMethodChannel methodChannelWithName:channelName binaryMessenger:messenger];
        __weak __typeof__(self) weakSelf = self;
        [weakSelf._channel setMethodCallHandler:^(FlutterMethodCall * _Nonnull call, FlutterResult  _Nonnull result) {
            [weakSelf onMethodCall:call result:result];
        }];
        
        NSString * eventChannelName=[NSString stringWithFormat:@"r_scan/com.rhyme/r_scan_view_%lld/event",viewId];
        FlutterEventChannel * _evenChannel = [FlutterEventChannel eventChannelWithName:eventChannelName binaryMessenger:messenger];
        self._event=[FlutterRScanViewEventChannel new];
        [self._event setRsView:self];
        [_evenChannel setStreamHandler:self._event];
        
        AVCaptureVideoPreviewLayer * layer=[AVCaptureVideoPreviewLayer layerWithSession:self.session];
        self.captureLayer=layer;
        
        layer.backgroundColor=[UIColor blackColor].CGColor;
        [self.layer addSublayer:layer];
        layer.videoGravity=AVLayerVideoGravityResizeAspectFill;
        
        AVCaptureDevice * device=[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        AVCaptureDeviceInput * input=[[AVCaptureDeviceInput alloc] initWithDevice:device error:nil];
        AVCaptureMetadataOutput * output=[[AVCaptureMetadataOutput alloc]init];
        [self.session addInput:input];
        [self.session addOutput:output];
        self.session.sessionPreset=AVCaptureSessionPresetHigh;
        
        output.metadataObjectTypes=output.availableMetadataObjectTypes;
        [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
        [output setMetadataObjectTypes:@[AVMetadataObjectTypeUPCECode, AVMetadataObjectTypeCode39Code, AVMetadataObjectTypeCode39Mod43Code,
        AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode93Code, AVMetadataObjectTypeCode128Code,
        AVMetadataObjectTypePDF417Code, AVMetadataObjectTypeQRCode, AVMetadataObjectTypeAztecCode]];
        
        [self.session startRunning];
    }
    return self;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    self.captureLayer.frame=self.bounds;
}

-(void)onMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([call.method isEqualToString:@"startScan"]) {
        [self resume];
    }else if([call.method isEqualToString:@"stopScan"]){
        [self pause];
    }
}

-(void)resume{
    if(![self.session isRunning]){
        [self.session startRunning];
    }
}

-(void)pause{
    if ([self.session isRunning]) {
        [self.session stopRunning];
    }
}

- (void)captureOutput:(AVCaptureOutput *)output didOutputMetadataObjects:(NSArray<__kindof AVMetadataObject *> *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    if (metadataObjects.count>0) {
        AVMetadataMachineReadableCodeObject * metaObject=metadataObjects[0];
        NSString * value=metaObject.stringValue;
        NSLog(@"扫描到的二维码为：%@",value);
        if(value.length&&self._event){
            [self._event getResult:value];
        }
    }
}
@end



@implementation FlutterRScanViewEventChannel

- (FlutterError *)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)events{
    self.events = events;
    if(self.rsView){
        NSNumber * isPlay=[arguments valueForKey:@"isPlay"];
        if(isPlay){
            if (isPlay.boolValue) {
                [self.rsView resume];
            }else{
                [self.rsView pause];
            }
        }
    }
    return nil;
}

- (FlutterError * _Nullable)onCancelWithArguments:(id _Nullable)arguments {
    if(self.rsView){
        [self.rsView pause];
    }
    return nil;
}

- (void)getResult:(NSString *)msg{
    if(self.events){
        self.events(msg);
    }
}

- (void)setRsView:(RScanView *)rsView{
    self.rsView=rsView;
}
@end
