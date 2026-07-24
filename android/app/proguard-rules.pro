# Required by sqflite_sqlcipher when Android code shrinking is enabled.
-keep class net.sqlcipher.** { *; }
-dontwarn net.sqlcipher.**
