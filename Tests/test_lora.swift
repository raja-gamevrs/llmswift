#!/usr/bin/env swift

import Foundation

// Consolidated LoRA test script
// This script verifies files exist and provides test information
// For actual inference tests, use: swift test --filter LoRATests

print("""
============================================================
          LoRA Adapter Test Script
          Testing Hermes 3 + Gandalf Adapter
============================================================
""")

let modelPath = "models/hermes3/base/Hermes-3-Llama-3.2-3B_q4_0.gguf"
let adapterPath = "models/hermes3/adapters/gandalf_Hermes-3-Llama-3.2-3B_adapter.gguf"

// Check if files exist
print("\n[1/2] Checking files...")
let fm = FileManager.default
let currentDir = fm.currentDirectoryPath

let modelURL = URL(fileURLWithPath: currentDir).appendingPathComponent(modelPath)
let adapterURL = URL(fileURLWithPath: currentDir).appendingPathComponent(adapterPath)

var filesOK = true

if fm.fileExists(atPath: modelURL.path) {
    let fileSize = try? fm.attributesOfItem(atPath: modelURL.path)[.size] as? Int64
    let sizeMB = (fileSize ?? 0) / 1_048_576
    print("  [OK] Base model: \(modelPath) (\(sizeMB) MB)")
} else {
    print("  [ERROR] Base model NOT found: \(modelURL.path)")
    filesOK = false
}

if fm.fileExists(atPath: adapterURL.path) {
    let fileSize = try? fm.attributesOfItem(atPath: adapterURL.path)[.size] as? Int64
    let sizeMB = (fileSize ?? 0) / 1_048_576
    print("  [OK] LoRA adapter: \(adapterPath) (\(sizeMB) MB)")
} else {
    print("  [ERROR] LoRA adapter NOT found: \(adapterURL.path)")
    filesOK = false
}

if !filesOK {
    print("\n[ERROR] Required files not found. Please check paths.")
    exit(1)
}

print("\n[2/2] File verification complete!")
print("\n" + String(repeating: "=", count: 60))

// Display test information
print("\nAVAILABLE TESTS:")
print("----------------")
print("Run the full test suite:")
print("  swift test --filter LoRATests")
print("")
print("Individual tests:")
print("  1. testBaseModelInference")
print("     - Tests base model inference (works)")
print("     - Command: swift test --filter testBaseModelInference")
print("")
print("  2. testLoRAAdapterInference")
print("     - Tests LoRA adapter inference (currently blocked)")
print("     - Command: swift test --filter testLoRAAdapterInference")
print("")
print("  3. testCompareBaseVsAdapter")
print("     - Compares base vs adapter responses")
print("     - Command: swift test --filter testCompareBaseVsAdapter")
print("")
print("  4. testAdapterSwapping")
print("     - Tests hot-swapping adapters")
print("     - Command: swift test --filter testAdapterSwapping")
print("")
print("  5. testAdapterScaleAdjustment")
print("     - Tests adapter scale adjustment")
print("     - Command: swift test --filter testAdapterScaleAdjustment")

print("\n" + String(repeating: "=", count: 60))
print("\nKNOWN LIMITATION:")
print("  LoRA inference currently crashes due to llama.cpp graph size")
print("  limitation (2048 nodes). Base model and LoRA management APIs")
print("  work perfectly. See QUICK_START.md for solutions.")
print("\n" + String(repeating: "=", count: 60))
print("\nAll files verified and ready for testing!")
