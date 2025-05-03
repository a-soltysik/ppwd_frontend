package com.example.board_plugin;

import android.content.Context;

public class ResourceHelper {
    public static int getResourceId(Context context, String resourceName, String resourceType) {
        return context.getResources().getIdentifier(
                resourceName,
                resourceType,
                context.getPackageName());
    }

    public static int getAppIconResourceId(Context context) {
        return getResourceId(context, "ic_launcher", "mipmap");
    }
}