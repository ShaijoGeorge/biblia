# Keep Generic Signatures (Critical for Gson/TypeToken)
-keepattributes Signature

# Keep Gson classes
-keep class com.google.gson.** { *; }
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken

# Keep Flutter Local Notifications plugin classes
-keep class com.dexterous.flutterlocalnotifications.** { *; }