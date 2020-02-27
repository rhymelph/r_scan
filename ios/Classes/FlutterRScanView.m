//
//  FlutterRScanView.m
//  r_scan
//
//  Created by rhymelph on 2019/11/21.
//

#import "FlutterRScanView.h"
#import "RScanView.h"
static NSString * scanViewType=@"com.rhyme_lph/r_scan_view";

@implementation FlutterRScanViewFactory{
 
    NSObject<FlutterBinaryMessenger>* _messenger;
}

- (instancetype)initWithMessenger:(NSObject<FlutterBinaryMessenger> *)messenger{
    self = [super init];
    if (self) {
        _messenger=messenger;
    }
    return self;
}

- (NSObject<FlutterMessageCodec> *)createArgsCodec{
    return [FlutterStandardMessageCodec sharedInstance];
}
- (NSObject<FlutterPlatformView> *)createWithFrame:(CGRect)frame viewIdentifier:(int64_t)viewId arguments:(id)args{
    FlutterRScanView * scanView=[[FlutterRScanView alloc]initWithFrame:frame viewindentifier:viewId arguments:args binaryMessenger:_messenger];
    return scanView;
    
}
@end

@interface FlutterRScanView()
@property(nonatomic , strong)RScanView * view;


@end
@implementation FlutterRScanView{

}

- (instancetype)initWithFrame:(CGRect)frame viewindentifier:(int64_t)viewId arguments:(id)args binaryMessenger:(NSObject<FlutterBinaryMessenger> *)messenger{
    if(self = [super init]){
        _view=[[RScanView alloc]initWithFrame:frame viewIdentifier:viewId arguments:args binaryMessenger:messenger];
        _view.backgroundColor=[UIColor clearColor];
        _view.frame=frame;
        
    }
    return self;
}
- (nonnull UIView *)view {
    return _view;
}


@end



