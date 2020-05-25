package com.weylar.covidtracker

import io.flutter.app.FlutterApplication
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugins.firebasemessaging.FlutterFirebaseMessagingService


class CovidApplication : FlutterApplication(), PluginRegistry
.PluginRegistrantCallback {
	override fun onCreate() {
		super.onCreate()
		FlutterFirebaseMessagingService.setPluginRegistrant(this)
	}


	override fun registerWith(registry: PluginRegistry?) {
		io.flutter.plugins.firebasemessaging.FirebaseMessagingPlugin
				.registerWith(registry?.registrarFor("io.flutter.plugins.firebasemessaging.FirebaseMessagingPlugin"));
	}
}