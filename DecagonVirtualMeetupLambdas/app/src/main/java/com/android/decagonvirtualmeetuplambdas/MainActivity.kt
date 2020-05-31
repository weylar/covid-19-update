package com.android.decagonvirtualmeetuplambdas

import androidx.appcompat.app.AppCompatActivity
import android.os.Bundle

class MainActivity : AppCompatActivity() {

	override fun onCreate(savedInstanceState: Bundle?) {
		super.onCreate(savedInstanceState)
		setContentView(R.layout.activity_main)



	}

	private fun plus(first: Int, second: Int ):Int{
		val res = first + second
		return res
	}





}
