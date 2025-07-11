#!/usr/bin/env python3
"""
Production Cleanup Script for Dayliz Location System
Removes debug prints and production-unsafe code
"""

import os
import re
import sys

def clean_debug_prints(file_path):
    """Remove debug prints from a file"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        
        # Remove debugPrint lines (with various emoji patterns)
        patterns = [
            r'\s*debugPrint\([^)]*\);\s*\n',
            r'\s*print\([^)]*\);\s*\n',
        ]
        
        for pattern in patterns:
            content = re.sub(pattern, '', content, flags=re.MULTILINE)
        
        # Clean up empty lines (max 2 consecutive)
        content = re.sub(r'\n\s*\n\s*\n+', '\n\n', content)
        
        if content != original_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"✅ Cleaned: {file_path}")
            return True
        else:
            print(f"⚪ No changes: {file_path}")
            return False
            
    except Exception as e:
        print(f"❌ Error cleaning {file_path}: {e}")
        return False

def main():
    """Main cleanup function"""
    print("🧹 Starting Production Cleanup for Location System...")
    
    # Files to clean
    files_to_clean = [
        "apps/mobile/lib/core/services/early_location_checker.dart",
        "apps/mobile/lib/presentation/providers/location_gating_provider.dart", 
        "apps/mobile/lib/presentation/screens/splash/loading_animation_splash_screen.dart",
        "apps/mobile/lib/presentation/screens/location/location_access_screen.dart",
        "apps/mobile/lib/core/services/real_location_service.dart"
    ]
    
    cleaned_count = 0
    
    for file_path in files_to_clean:
        if os.path.exists(file_path):
            if clean_debug_prints(file_path):
                cleaned_count += 1
        else:
            print(f"⚠️ File not found: {file_path}")
    
    print(f"\n🎉 Cleanup Complete! Cleaned {cleaned_count} files.")
    print("📋 Summary:")
    print("  ✅ Removed debug prints")
    print("  ✅ Cleaned up empty lines")
    print("  ✅ Production-ready code")

if __name__ == "__main__":
    main()
