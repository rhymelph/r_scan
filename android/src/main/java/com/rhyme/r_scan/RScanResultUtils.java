package com.rhyme.r_scan;

import com.google.zxing.Result;
import com.google.zxing.ResultPoint;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class RScanResultUtils {


    public static Map<String,Object> toMap(Result result){
        if(result == null) return  null;
        Map<String,Object> data = new HashMap<>();
        data.put("message",result.getText());
        data.put("type",result.getBarcodeFormat().ordinal());
        if(result.getResultPoints()!=null){
            List<Map<String,Object>>  resultPoints = new ArrayList<>();
            for (ResultPoint point :result.getResultPoints()){
                Map<String,Object> pointMap = new HashMap<>();
                pointMap.put("X",point.getX());
                pointMap.put("Y",point.getY());
                resultPoints.add(pointMap);
            }
            data.put("points",resultPoints);
        }
        return  data;
    }
}
