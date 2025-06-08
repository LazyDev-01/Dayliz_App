# Google Places API Setup & Cost Control Guide

## 🎯 Overview

This guide explains how to set up Google Places API for location search with built-in cost controls to prevent unexpected charges.

## 💰 Cost Control Features

### **Built-in Safeguards:**
- ✅ **Rate Limiting**: 10 requests/minute, 100/hour, 500/day
- ✅ **Caching**: 1-hour cache to reduce API calls
- ✅ **Input Validation**: Minimum 2 characters to prevent spam
- ✅ **Fallback System**: Local results when API unavailable
- ✅ **Usage Monitoring**: Real-time usage statistics

### **Expected Costs:**
- **Google Places API**: $17 per 1000 requests
- **With our limits**: Maximum $8.50/day (500 requests)
- **With caching**: Estimated $2-4/day in production

## 🔧 Setup Instructions

### **Step 1: Get Google Places API Key**

1. **Go to Google Cloud Console**: https://console.cloud.google.com/
2. **Create/Select Project**: Choose your Dayliz project
3. **Enable Places API**:
   - Go to "APIs & Services" → "Library"
   - Search for "Places API"
   - Click "Enable"
4. **Create API Key**:
   - Go to "APIs & Services" → "Credentials"
   - Click "Create Credentials" → "API Key"
   - Copy the generated key

### **Step 2: Secure Your API Key**

1. **Restrict the API Key**:
   - Click on your API key in credentials
   - Under "API restrictions" → Select "Restrict key"
   - Choose "Places API"
   - Under "Application restrictions" → Choose "Android apps" or "iOS apps"
   - Add your app's package name and SHA-1 fingerprint

2. **Set Usage Quotas**:
   - Go to "APIs & Services" → "Quotas"
   - Find "Places API"
   - Set daily quota to 500 requests (our app limit)

### **Step 3: Configure in App**

1. **Add API Key to Environment**:
   ```bash
   # For development
   export GOOGLE_PLACES_API_KEY="your_api_key_here"
   
   # For production (use secure environment variables)
   ```

2. **Or Update Configuration File**:
   ```dart
   // In apps/mobile/lib/core/config/api_config.dart
   static const String googlePlacesApiKey = 'your_api_key_here';
   ```

## 📊 Cost Monitoring

### **Usage Statistics**
The app provides real-time usage monitoring:

```dart
final stats = GooglePlacesService.getUsageStats();
print('Requests this hour: ${stats['requests_last_hour']}');
print('Cached results: ${stats['cache_entries']}');
```

### **Daily Cost Estimation**
- **Light Usage** (50 searches/day): ~$0.85/day
- **Medium Usage** (200 searches/day): ~$3.40/day  
- **Heavy Usage** (500 searches/day): ~$8.50/day

## 🛡️ Security Best Practices

### **API Key Security**
1. **Never commit API keys** to version control
2. **Use environment variables** for production
3. **Restrict API key** to specific APIs and apps
4. **Monitor usage** regularly in Google Cloud Console
5. **Set billing alerts** for unexpected charges

### **Rate Limiting**
The app automatically:
- ✅ Blocks requests when limits exceeded
- ✅ Shows fallback results instead of errors
- ✅ Caches results to reduce API calls
- ✅ Validates input to prevent spam

## 🔄 Fallback System

When API is unavailable, the app shows:
- **Local Tura locations** for Meghalaya searches
- **Cached results** from previous searches
- **User-friendly messages** instead of errors

## 🚨 Emergency Controls

### **If Costs Get Too High:**

1. **Immediate Actions**:
   ```dart
   // Reduce limits in api_config.dart
   'maxRequestsPerHour': 50,  // Reduce from 100
   'maxRequestsPerDay': 200,  // Reduce from 500
   ```

2. **Disable API Temporarily**:
   ```dart
   // Set empty API key to force fallback mode
   static const String googlePlacesApiKey = '';
   ```

3. **Monitor in Google Cloud**:
   - Set billing alerts at $5, $10, $20
   - Check usage daily during initial rollout

## 📈 Production Recommendations

### **Launch Strategy**
1. **Start with low limits** (50 requests/day)
2. **Monitor usage patterns** for first week
3. **Gradually increase limits** based on actual usage
4. **Set billing alerts** at multiple thresholds

### **Optimization Tips**
- ✅ **Cache popular searches** longer
- ✅ **Use autocomplete** instead of full search when possible
- ✅ **Implement search suggestions** to reduce API calls
- ✅ **Encourage saved addresses** to bypass search

## 🎯 Expected User Experience

### **With API Configured:**
- **Real-time search** of any location in India
- **Accurate addresses** with coordinates
- **Fast autocomplete** suggestions

### **Without API (Fallback):**
- **Local Tura locations** still work
- **Saved addresses** work perfectly
- **Manual coordinate entry** as backup

## 📞 Support

If you encounter issues:
1. **Check API key configuration** in Google Cloud Console
2. **Verify usage limits** haven't been exceeded
3. **Check app logs** for detailed error messages
4. **Monitor billing** in Google Cloud Console

The system is designed to **fail gracefully** - users can always use saved addresses or GPS detection even if Places API is unavailable.
