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

+(NSNumber*) getZXingType:(ZXBarcodeFormat)format{
    switch (format) {
        case kBarcodeFormatAztec:
            return @(0);
        case kBarcodeFormatCodabar:
            return @(1);
        case kBarcodeFormatCode39:
            return @(2);
        case kBarcodeFormatCode93:
            return @(3);
        case kBarcodeFormatCode128:
            return @(4);
        case kBarcodeFormatDataMatrix:
            return @(5);
        case kBarcodeFormatEan8:
            return @(6);
        case kBarcodeFormatEan13:
            return @(7);
        case kBarcodeFormatITF:
            return @(8);
        case kBarcodeFormatMaxiCode:
            return @(9);
        case kBarcodeFormatPDF417:
            return @(10);
        case kBarcodeFormatQRCode:
            return @(11);
        case kBarcodeFormatRSS14:
            return @(12);
        case kBarcodeFormatRSSExpanded:
            return @(13);
        case kBarcodeFormatUPCA:
            return @(14);
        case kBarcodeFormatUPCE:
            return @(15);
        case kBarcodeFormatUPCEANExtension:
            return @(16);
    }
    return nil;
}

+ (NSNumber *)getZBarType:(zbar_symbol_type_t)format{
    switch (format) {
//        case kBarcodeFormatAztec:
//            return @(0);
        case ZBAR_CODABAR:
            return @(1);
        case ZBAR_CODE39:
            return @(2);
        case ZBAR_CODE93:
            return @(3);
        case ZBAR_CODE128:
            return @(4);
        case ZBAR_DATABAR_EXP:
            return @(5);
        case ZBAR_EAN8:
            return @(6);
        case ZBAR_EAN13:
            return @(7);
        case ZBAR_COMPOSITE:
            return @(8);
//        case kBarcodeFormatMaxiCode:
//            return @(9);
        case ZBAR_PDF417:
            return @(10);
        case ZBAR_QRCODE:
            return @(11);
//        case kBarcodeFormatRSS14:
//            return @(12);
//        case kBarcodeFormatRSSExpanded:
//            return @(13);
        case ZBAR_UPCA:
            return @(14);
        case ZBAR_UPCE:
            return @(15);
//        case kBarcodeFormatUPCEANExtension:
//            return @(16);
        default:
            break;
    }
    return nil;
}
@end
