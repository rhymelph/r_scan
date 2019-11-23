//
//  FlutterRScanView.h
//  r_scan
//
//  Created by rhymelph on 2019/11/21.
//


#import <Flutter/Flutter.h>
#import <AVFoundation/AVFoundation.h>

@interface FlutterRScanView : NSObject<FlutterPlatformView>

-(instancetype _Nullable )initWithFrame:(CGRect)frame viewindentifier:(int64_t)viewId arguments:(id _Nullable)args binaryMessenger:(NSObject<FlutterBinaryMessenger> *_Nonnull)messenger;

-(nonnull UIView*) view;

@end

@interface FlutterRScanViewFactory : NSObject<FlutterPlatformViewFactory>

-(instancetype _Nullable )initWithMessenger:(NSObject<FlutterBinaryMessenger>*_Nonnull)messenger;

@end




