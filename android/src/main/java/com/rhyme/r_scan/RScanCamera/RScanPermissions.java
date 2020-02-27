package com.rhyme.r_scan.RScanCamera;

import android.Manifest.permission;
import android.app.Activity;
import android.content.pm.PackageManager;

import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import io.flutter.plugin.common.PluginRegistry.RequestPermissionsResultListener;

public final class RScanPermissions {
    public interface PermissionsRegistry {
        void addListener(RequestPermissionsResultListener handler);
    }

    interface ResultCallback {
        void onResult(String errorCode, String errorDescription);
    }

    private static final int CAMERA_REQUEST_ID = 9796;
    private boolean ongoing = false;

    void requestPermissions(
            Activity activity,
            PermissionsRegistry permissionsRegistry,
            final ResultCallback callback) {
        if (ongoing) {
            callback.onResult("cameraPermission", "Camera permission request ongoing");
        }
        if (!hasCameraPermission(activity)) {
            permissionsRegistry.addListener(
                    new RScanRequestPermissionsListener(new ResultCallback() {
                        @Override
                        public void onResult(String errorCode, String errorDescription) {
                            ongoing = false;
                            callback.onResult(errorCode, errorDescription);
                        }
                    }));
            ongoing = true;
            ActivityCompat.requestPermissions(
                    activity, new String[]{permission.CAMERA},
                    CAMERA_REQUEST_ID);
        } else {
            // Permissions already exist. Call the callback with success.
            callback.onResult(null, null);
        }
    }

    private boolean hasCameraPermission(Activity activity) {
        return ContextCompat.checkSelfPermission(activity, permission.CAMERA)
                == PackageManager.PERMISSION_GRANTED;
    }


    private static class RScanRequestPermissionsListener
            implements RequestPermissionsResultListener {

        final ResultCallback callback;

        private RScanRequestPermissionsListener(ResultCallback callback) {
            this.callback = callback;
        }

        @Override
        public boolean onRequestPermissionsResult(int id, String[] permissions, int[] grantResults) {
            if (id == CAMERA_REQUEST_ID) {
                if (grantResults[0] != PackageManager.PERMISSION_GRANTED) {
                    callback.onResult("rScanPermission", "MediaRecorderCamera permission not granted");
                } else {
                    callback.onResult(null, null);
                }
                return true;
            }
            return false;
        }
    }
}
