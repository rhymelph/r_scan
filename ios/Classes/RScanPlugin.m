#import "RScanPlugin.h"
#import "FlutterRScanView.h"
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

-(NSString *) getQrCode:(NSData *)data{
    if (data) {
        CIImage * detectImage=[CIImage imageWithData:data];
        CIDetector*detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{CIDetectorAccuracy: CIDetectorAccuracyHigh}];
        NSArray* feature = [detector featuresInImage:detectImage options: nil];
        if(feature.count==0){
            return @"";
        }else{
            for(int index=0;index<[feature count];index ++){
                CIQRCodeFeature * qrCode=[feature objectAtIndex:index];
                NSString *resultStr=qrCode.messageString;
                if(resultStr!=nil){
                    NSLog(@"识别到的二维码内容为:%@",resultStr);
                    return resultStr;
                }
                
            }
        }
    }
    return @"";
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

