#import "RScanPlugin.h"
#import "FlutterRScanView.h"
#import "RScanResult.h"

@implementation RScanPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:@"r_scan"
                                     binaryMessenger:[registrar messenger]];
    RScanPlugin* instance = [[RScanPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
    
    FlutterRScanViewFactory * rScanView=[[FlutterRScanViewFactory alloc]initWithMessenger:registrar.messenger];
    [registrar registerViewFactory:rScanView withId:@"com.rhyme/r_scan_view"];
    
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"scanImagePath" isEqualToString:call.method]) {
        [self scanImagePath:call result:result];
    }else if ([@"scanImageUrl" isEqualToString:call.method]) {
        [self scanImageUrl:call result:result];
    }if ([@"scanImageMemory" isEqualToString:call.method]) {
        [self scanImageMemory:call result:result];
    } else {
        result(FlutterMethodNotImplemented);
    }
}


- (void)scanImagePath:(FlutterMethodCall*)call result:(FlutterResult)result{
    NSString * path=[call.arguments valueForKey:@"path"];
    if([path isKindOfClass:[NSNull class]]){
        result(@"");
        return;
    }
    //加载文件
    NSFileHandle * fh=[NSFileHandle fileHandleForReadingAtPath:path];
    NSData * data=[fh readDataToEndOfFile];
    result([self getQrCode:data]);
}

-(NSDictionary *) getQrCode:(NSData *)data{
    if (data) {
        CIImage * detectImage=[CIImage imageWithData:data];
        CIDetector*detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{CIDetectorAccuracy: CIDetectorAccuracyHigh}];
        NSArray* feature = [detector featuresInImage:detectImage options: nil];
        if(feature.count==0){
            return nil;
        }else{
            for(int index=0;index<[feature count];index ++){
                CIQRCodeFeature * qrCode=[feature objectAtIndex:index];
                NSString *resultStr=qrCode.messageString;
                if(resultStr!=nil){
                    NSMutableDictionary *dict =[NSMutableDictionary dictionary];
                    [dict setValue:resultStr forKey:@"message"];
                    [dict setValue:[RScanResult getType:AVMetadataObjectTypeQRCode] forKey:@"type"];
                    NSMutableArray<NSDictionary *> * points = [NSMutableArray array];
                    CGPoint topLeft=qrCode.topLeft;
                    CGPoint topRight=qrCode.topRight;
                    CGPoint bottomLeft=qrCode.bottomLeft;
                    CGPoint bottomRight=qrCode.bottomRight;
                    [points addObject:[self pointsToMap:topLeft]];
                     [points addObject:[self pointsToMap:topRight]];
                     [points addObject:[self pointsToMap:bottomLeft]];
                     [points addObject:[self pointsToMap:bottomRight]];
                    [dict setValue:points forKey:@"points"];
                    return dict;
                }
                
            }
        }
    }
    return nil;
}

-(NSDictionary*) pointsToMap:(CGPoint) point{
    NSMutableDictionary * dict = [NSMutableDictionary dictionary];
    [dict setValue:@(point.x) forKey:@"X"];
    [dict setValue:@(point.y) forKey:@"Y"];
    return dict;
}


- (void)scanImageUrl:(FlutterMethodCall*)call result:(FlutterResult)result{
    NSString * url = [call.arguments valueForKey:@"url"];
    NSURL* nsUrl=[NSURL URLWithString:url];
    NSData * data=[NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:nsUrl] returningResponse:nil error:nil];
    result([self getQrCode:data]);
}

- (void)scanImageMemory:(FlutterMethodCall*)call result:(FlutterResult)result{
    FlutterStandardTypedData * uint8list=[call.arguments valueForKey:@"uint8list"];
    result([self getQrCode:uint8list.data]);
}
@end

