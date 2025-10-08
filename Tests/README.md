# Test Scripts

## Test Files

### LoRATests.swift (Swift Testing Suite)
Comprehensive test suite for LoRA functionality using Swift Testing framework:

**Tests:**
- `testBaseModelInference` - Test base model (works)
- `testLoRAAdapterInference` - Test LoRA inference (blocked by graph size)
- `testCompareBaseVsAdapter` - Compare base vs adapter responses
- `testAdapterSwapping` - Test hot-swapping adapters
- `testAdapterScaleAdjustment` - Test adapter scale adjustment

**Run with:**
```bash
# Run all LoRA tests
swift test --filter LoRATests

# Run specific test
swift test --filter testBaseModelInference
```

### test_lora.swift (Standalone Script)
Consolidated verification script that:
- Checks if model and adapter files exist
- Shows file sizes
- Lists all available tests
- Provides test commands
- Shows known limitations

**Run with:**
```bash
# From project root
swift Tests/test_lora.swift
```

## Test Results

| Component | Status | Notes |
|-----------|--------|-------|
| Base Model Inference | ✅ Works | Perfect, no issues |
| LoRA Adapter Loading | ✅ Works | Loads successfully |
| LoRA Management APIs | ✅ Works | All functions work |
| LoRA Inference | ❌ Blocked | Graph size limitation |

## Known Limitation

LoRA inference crashes due to llama.cpp computation graph size limit (2048 nodes). This is a limitation of the prebuilt xcframework, not the implementation. See QUICK_START.md for solutions.

## Quick Test

```bash
# Verify files exist
swift Tests/test_lora.swift

# Test base model (works)
swift test --filter testBaseModelInference

# Test LoRA management (works)
swift test --filter testAdapterSwapping
```
