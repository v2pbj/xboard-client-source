package com.follow.clash.common

import android.content.ComponentName

object Components {
    const val PACKAGE_NAME = "com.follow.clash"

    // Platform channels are addressed by the installed application id, which the rebranded
    // build ships as com.bearbooster.client, while PACKAGE_NAME stays the upstream namespace
    // that the Kotlin class names and their R import live under.
    const val CHANNEL_PACKAGE = "com.bearbooster.client"

    val mainActivity =
        ComponentName(GlobalState.packageName, "${PACKAGE_NAME}.MainActivity")

    val quickActionActivity =
        ComponentName(GlobalState.packageName, "${PACKAGE_NAME}.QuickActionActivity")

    val serviceBroadcastReceiver =
        ComponentName(GlobalState.packageName, "${PACKAGE_NAME}.ServiceBroadcastReceiver")
}
