package com.example.board_plugin;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public record MethodCallContext(MethodCall call, MethodChannel.Result result) {
}
