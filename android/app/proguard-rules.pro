# ProGuard rules for Flutter release build

# Stripe SDK optional push provisioning missing classes ignore rules
-dontwarn com.stripe.android.pushProvisioning.**
-keep class com.stripe.android.** { *; }
