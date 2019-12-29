//
//  RScanResult.m
//  r_scan
//
//  Created by 李鹏辉 on 2019/12/28.
//

#import "RScanResult.h"

@implementation RScanResult

+(NSDictionary*) toMap:(AVMetadataMachineReadableCodeObject*) obj{
    if (obj == nil) {
        return nil;
    }
    NSMutableDictionary * result =[NSMutableDictionary dictionary];
    [result setValue:obj.stringValue forKey:@"message"];
    [result setValue:[self getType:obj.type] forKey:@"type"];
    [result setValue:obj.corners forKey:@"points"];
    return result;
}

+(NSNumber*) getType:(AVMetadataObjectType)type{
    if (type == AVMetadataObjectTypeAztecCode) {
        return @(0);
    }else if (type == AVMetadataObjectTypeCode39Code) {
        return @(2);
    }else if (type == AVMetadataObjectTypeCode93Code) {
        return @(3);
    }else if (type == AVMetadataObjectTypeCode128Code) {
        return @(4);
    }else if (type == AVMetadataObjectTypeDataMatrixCode) {
        return @(5);
    }else if (type == AVMetadataObjectTypeEAN8Code) {
        return @(6);
    }else if (type == AVMetadataObjectTypeEAN13Code) {
        return @(7);
    }else if (type == AVMetadataObjectTypeITF14Code) {
        return @(8);
    }else if (type == AVMetadataObjectTypePDF417Code) {
        return @(10);
    }else if (type == AVMetadataObjectTypeQRCode) {
        return @(11);
    }else if (type == AVMetadataObjectTypeUPCECode) {
        return @(15);
    }else{
        return nil;
    }
}

@end
