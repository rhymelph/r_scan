#import "RScanPlugin.h"
#import "FlutterRScanView.h"
#import "RScanResult.h"
#import "RScanCamera.h"
#import "ZBarSDK.h"
#import "ZXingObjC.h"
@implementation RScanPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:@"com.rhyme_lph/r_scan"
                                     binaryMessenger:[registrar messenger]];
    RScanPlugin* instance = [[RScanPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
    
    FlutterRScanViewFactory * rScanView=[[FlutterRScanViewFactory alloc]initWithMessenger:registrar.messenger];
    [registrar registerViewFactory:rScanView withId:@"com.rhyme_lph/r_scan_view"];
    
    FlutterMethodChannel* cameraChannel = [FlutterMethodChannel
                                           methodChannelWithName:@"com.rhyme_lph/r_scan_camera/method" binaryMessenger:[registrar messenger]];
    
    RScanCamera* camera = [[RScanCamera alloc]initWithRegistry:[registrar textures] messenger:[registrar messenger]];
    [registrar addMethodCallDelegate:camera channel:cameraChannel];
    
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

-(NSDictionary *)zXingScan:(NSData *)data{
    CGImageRef cgImage;
    
    // Fallback on earlier versions
    CGImageSourceRef sourceRef = CGImageSourceCreateWithData((CFDataRef)data, NULL);
    
    cgImage = CGImageSourceCreateImageAtIndex(sourceRef, 0, NULL);
    
    ZXLuminanceSource *source = [[ZXCGImageLuminanceSource alloc] initWithCGImage:cgImage];
    ZXBinaryBitmap *bitmap = [ZXBinaryBitmap binaryBitmapWithBinarizer:[ZXHybridBinarizer binarizerWithSource:source]];
    
    NSError *error = nil;
    
    ZXDecodeHints *hints = [ZXDecodeHints hints];
    
    ZXMultiFormatReader *reader = [ZXMultiFormatReader reader];
    ZXResult *result = [reader decode:bitmap hints:hints error:&error];
    NSLog(@"zXing scan start");
    if(result){
        NSMutableDictionary *dict =[NSMutableDictionary dictionary];
        NSString* contents = result.text;
        ZXBarcodeFormat format = result.barcodeFormat;
        [dict setValue:contents forKey:@"message"];
        [dict setValue:[RScanResult getZXingType:format] forKey:@"type"];
        NSArray* points = result.resultPoints;
        NSMutableArray<NSDictionary *> * pointMap = [NSMutableArray array];
        for(ZXResultPoint* poin in points){
            [pointMap addObject:[self pointsToMap2:poin.x y:poin.y]];
        }
        [dict setValue:pointMap forKey:@"points"];
        return dict;
    }
    return nil;
}


-(NSDictionary *)zbarScan:(NSData *)data{
    CGImageRef cgImage;
    
    // Fallback on earlier versions
    CGImageSourceRef sourceRef = CGImageSourceCreateWithData((CFDataRef)data, NULL);
    
    cgImage = CGImageSourceCreateImageAtIndex(sourceRef, 0, NULL);

    ZBarImage * zbarImage =[[ZBarImage alloc]initWithCGImage:cgImage];
    ZBarImageScanner* scanner = [[ZBarImageScanner alloc]init];
    
    [scanner setSymbology:ZBAR_NONE config:ZBAR_CFG_ENABLE to:1];
    NSInteger resultInt = [scanner scanImage:zbarImage];

    NSLog(@"zbar scan count:%ld",(long)resultInt);
    
    if (resultInt == 0) {
        return nil;
    }else{
        ZBarSymbolSet* symbols = scanner.results;
        ZBarSymbol *symbol = nil;
        
        for(symbol in symbols){
            break;
        }

        NSString* resultStr = symbol.data;
        NSLog(@"zbar scan result data:%@ , type:%@",resultStr,symbol.typeName);
        if (resultStr!=nil) {
            NSMutableDictionary *dict =[NSMutableDictionary dictionary];
            [dict setValue:resultStr forKey:@"message"];
            [dict setValue:[RScanResult getZBarType:symbol.type] forKey:@"type"];
            NSMutableArray<NSDictionary *> * points = [NSMutableArray array];
            CGPoint topLeft=symbol.bounds.origin;
            CGPoint topRight=symbol.bounds.origin;
            topRight.x +=symbol.bounds.size.width;
            CGPoint bottomLeft=symbol.bounds.origin;
            bottomLeft.y +=symbol.bounds.size.height;
            
            CGPoint bottomRight=symbol.bounds.origin;
            bottomRight.x+=symbol.bounds.size.width;
            bottomRight.y+=symbol.bounds.size.height;
            
            [points addObject:[self pointsToMap:topLeft]];
            [points addObject:[self pointsToMap:topRight]];
            [points addObject:[self pointsToMap:bottomLeft]];
            [points addObject:[self pointsToMap:bottomRight]];
            [dict setValue:points forKey:@"points"];
            return dict;
        }
    }
    return nil;
}

-(NSDictionary *)nativeScan:(NSData *)data{
    CIImage * detectImage=[CIImage imageWithData:data];
    CIDetector*detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{CIDetectorAccuracy: CIDetectorAccuracyHigh}];
    
    NSArray* feature = [detector featuresInImage:detectImage options: nil];
    NSLog(@"native scan count:%lu",(unsigned long)feature.count);
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
    return nil;
}

-(NSDictionary *) getQrCode:(NSData *)data{
    if (data) {
        NSDictionary * result = [self zbarScan:data];
        if(result==nil){
            result =[self zXingScan:data];
        }
        if(result==nil){
            result = [self nativeScan:data];
        }
        return result;
    }
    return nil;
}

-(NSDictionary*) pointsToMap:(CGPoint) point{
    NSMutableDictionary * dict = [NSMutableDictionary dictionary];
    [dict setValue:@(point.x) forKey:@"X"];
    [dict setValue:@(point.y) forKey:@"Y"];
    return dict;
}

-(NSDictionary*) pointsToMap2:(float)x y:(float)y{
    NSMutableDictionary * dict = [NSMutableDictionary dictionary];
    [dict setValue:@(x) forKey:@"X"];
    [dict setValue:@(y) forKey:@"Y"];
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

