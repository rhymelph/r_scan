//
//  RScanView.h
//  r_scan
//
//  Created by rhymelph on 2019/11/23.
//

#import <UiKit/UiKit.h>
#import <Flutter/Flutter.h>

@interface RScanView : UIView

-(instancetype)initWithFrame:(CGRect)frame viewIdentifier:(int64_t)viewId arguments:(id)args binaryMessenger:(NSObject<FlutterBinaryMessenger> *)messenger;


@end

@interface FlutterRScanViewEventChannel : NSObject<FlutterStreamHandler>

@property(nonatomic , strong)FlutterEventSink events;
@property(nonatomic , strong)RScanView* rsView;

-(void)getResult:(NSDictionary *)msg;


@end
