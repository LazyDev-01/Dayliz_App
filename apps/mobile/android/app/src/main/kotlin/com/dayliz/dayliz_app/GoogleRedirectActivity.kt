package com.dayliz.dayliz_app

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.util.Log

/**
 * Activity to handle Google OAuth redirects
 */
class GoogleRedirectActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        val intent = intent
        val data = intent.data
        
        if (data != null) {
            Log.d("GoogleRedirectActivity", "Received redirect: $data")
            
            // Create a new intent with the modified URI
            val redirectUri = Uri.parse("com.dayliz.dayliz_app://login")
                .buildUpon()
                .appendQueryParameter("code", data.getQueryParameter("code"))
                .appendQueryParameter("state", data.getQueryParameter("state"))
                .build()
            
            // Create a new intent with the modified URI
            val redirectIntent = Intent(Intent.ACTION_VIEW, redirectUri)
            redirectIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            
            // Start the main activity with the redirect
            startActivity(redirectIntent)
        }
        
        // Always finish this activity
        finish()
    }
}
