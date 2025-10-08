import Testing
import Foundation
@testable import LLM

/// Tests for LoRA adapter functionality
/// Run with: swift test --filter LoRATests
struct LoRATests {
    
    let modelPath = "models/hermes3/base/Hermes-3-Llama-3.2-3B_q4_0.gguf"
    let adapterPath = "models/hermes3/adapters/gandalf_Hermes-3-Llama-3.2-3B_adapter.gguf"
    let testPrompt = "Tell me about wizards in 2 sentences."
    
    /// Test 1: Load base model and generate inference
    @Test("Load base model and infer")
    func testBaseModelInference() async throws {
        print("\n=== TEST 1: Base Model Inference ===")
        
        // Get absolute paths
        let baseURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent(modelPath)
        
        guard FileManager.default.fileExists(atPath: baseURL.path) else {
            print("[ERROR] Model not found at: \(baseURL.path)")
            throw TestError.modelNotFound
        }
        
        print("[OK] Model found at: \(baseURL.path)")
        
        // Initialize LLM with base model
        guard let llm = LLM(
            from: baseURL,
            template: .chatML("You are a helpful assistant."),
            maxTokenCount: 512
        ) else {
            print("[ERROR] Failed to initialize LLM")
            throw TestError.initializationFailed
        }
        
        print("[OK] LLM initialized successfully")
        print("Prompt: \(testPrompt)")
        print("Generating response (base model only)...\n")
        
        // Generate response
        let response = await llm.getCompletion(from: llm.preprocess(testPrompt, []))
        
        print("Base Model Response:")
        print("-------------------------------------")
        print(response)
        print("-------------------------------------")
        print("[OK] Base model inference completed")
        print("Response length: \(response.count) characters\n")
        
        #expect(!response.isEmpty, "Response should not be empty")
    }
    
    /// Test 2: Load base model + LoRA adapter and generate inference
    @Test("Load base model + LoRA adapter and infer")
    func testLoRAAdapterInference() async throws {
        print("\n=== TEST 2: Base Model + LoRA Adapter Inference ===")
        
        // Get absolute paths
        let baseURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent(modelPath)
        let adapterURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent(adapterPath)
        
        guard FileManager.default.fileExists(atPath: baseURL.path) else {
            print("[ERROR] Model not found at: \(baseURL.path)")
            throw TestError.modelNotFound
        }
        
        guard FileManager.default.fileExists(atPath: adapterURL.path) else {
            print("[ERROR] Adapter not found at: \(adapterURL.path)")
            throw TestError.adapterNotFound
        }
        
        print("[OK] Model found at: \(baseURL.path)")
        print("[OK] Adapter found at: \(adapterURL.path)")
        
        // Initialize LLM with base model
        guard let llm = LLM(
            from: baseURL,
            template: .chatML("You are a helpful assistant."),
            maxTokenCount: 512
        ) else {
            print("[ERROR] Failed to initialize LLM")
            throw TestError.initializationFailed
        }
        
        print("[OK] LLM initialized successfully")
        
        // Load LoRA adapter
        print("Loading Gandalf LoRA adapter...")
        do {
            let adapterName = try await llm.loadLoRAAdapter(
                from: adapterURL,
                scale: 1.0,
                name: "gandalf"
            )
            print("[OK] LoRA adapter '\(adapterName)' loaded successfully")
            print("[OK] Active adapters: \(llm.activeLoRAAdapterNames)")
        } catch {
            print("[ERROR] Failed to load LoRA adapter: \(error)")
            throw error
        }
        
        print("Prompt: \(testPrompt)")
        print("Generating response (with Gandalf adapter)...\n")
        
        // Generate response with adapter
        let response = await llm.getCompletion(from: llm.preprocess(testPrompt, []))
        
        print("With Gandalf Adapter Response:")
        print("-------------------------------------")
        print(response)
        print("-------------------------------------")
        print("[OK] LoRA adapter inference completed")
        print("Response length: \(response.count) characters")
        print("Active adapters: \(llm.activeLoRAAdapterNames)\n")
        
        #expect(!response.isEmpty, "Response should not be empty")
        #expect(llm.activeLoRAAdapterNames.contains("gandalf"), "Gandalf adapter should be active")
    }
    
    /// Test 3: Compare base vs adapter responses
    @Test("Compare base model vs LoRA adapter responses")
    func testCompareBaseVsAdapter() async throws {
        print("\n=== TEST 3: Comparison Test ===")
        
        let baseURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent(modelPath)
        let adapterURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent(adapterPath)
        
        // Test base model
        print("Testing BASE MODEL...")
        guard let llmBase = LLM(from: baseURL, template: .chatML("You are a helpful assistant."), maxTokenCount: 512) else {
            throw TestError.initializationFailed
        }
        let baseResponse = await llmBase.getCompletion(from: llmBase.preprocess(testPrompt, []))
        
        // Test with adapter
        print("Testing WITH GANDALF ADAPTER...")
        guard let llmAdapter = LLM(from: baseURL, template: .chatML("You are a helpful assistant."), maxTokenCount: 512) else {
            throw TestError.initializationFailed
        }
        _ = try await llmAdapter.loadLoRAAdapter(from: adapterURL, scale: 1.0, name: "gandalf")
        let adapterResponse = await llmAdapter.getCompletion(from: llmAdapter.preprocess(testPrompt, []))
        
        print("\nCOMPARISON RESULTS:")
        print("=====================================")
        print("\nBASE MODEL:")
        print(baseResponse)
        print("\nWITH GANDALF ADAPTER:")
        print(adapterResponse)
        print("\n=====================================")
        print("Base length: \(baseResponse.count) chars")
        print("Adapter length: \(adapterResponse.count) chars")
        print("Responses differ: \(baseResponse != adapterResponse)")
        print("[OK] Comparison test completed\n")
        
        #expect(!baseResponse.isEmpty, "Base response should not be empty")
        #expect(!adapterResponse.isEmpty, "Adapter response should not be empty")
    }
    
    /// Test 4: Test adapter swapping
    @Test("Test LoRA adapter swapping")
    func testAdapterSwapping() async throws {
        print("\n=== TEST 4: Adapter Swapping Test ===")
        
        let baseURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent(modelPath)
        let adapterURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent(adapterPath)
        
        guard let llm = LLM(from: baseURL, template: .chatML("You are a helpful assistant."), maxTokenCount: 512) else {
            throw TestError.initializationFailed
        }
        
        print("[OK] LLM initialized")
        print("Initial active adapters: \(llm.activeLoRAAdapterNames)")
        
        // Load adapter
        print("\nLoading Gandalf adapter...")
        _ = try await llm.loadLoRAAdapter(from: adapterURL, scale: 1.0, name: "gandalf")
        print("[OK] Adapter loaded")
        print("Active adapters: \(llm.activeLoRAAdapterNames)")
        #expect(llm.activeLoRAAdapterNames.contains("gandalf"), "Gandalf should be active")
        
        // Remove adapter
        print("\nRemoving Gandalf adapter...")
        try await llm.removeLoRAAdapter(named: "gandalf")
        print("[OK] Adapter removed")
        print("Active adapters: \(llm.activeLoRAAdapterNames)")
        #expect(llm.activeLoRAAdapterNames.isEmpty, "No adapters should be active")
        
        // Load again (should use cache)
        print("\nLoading Gandalf adapter again (from cache)...")
        _ = try await llm.loadLoRAAdapter(from: adapterURL, scale: 1.0, name: "gandalf")
        print("[OK] Adapter loaded from cache")
        print("Active adapters: \(llm.activeLoRAAdapterNames)")
        #expect(llm.activeLoRAAdapterNames.contains("gandalf"), "Gandalf should be active again")
        
        // Clear all
        print("\nClearing all adapters...")
        await llm.clearAllLoRAAdapters()
        print("[OK] All adapters cleared")
        print("Active adapters: \(llm.activeLoRAAdapterNames)")
        #expect(llm.activeLoRAAdapterNames.isEmpty, "No adapters should be active")
        
        print("[OK] Adapter swapping test completed\n")
    }
    
    /// Test 5: Test adapter scale adjustment
    @Test("Test LoRA adapter scale adjustment")
    func testAdapterScaleAdjustment() async throws {
        print("\n=== TEST 5: Adapter Scale Adjustment Test ===")
        
        let baseURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent(modelPath)
        let adapterURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent(adapterPath)
        
        guard let llm = LLM(from: baseURL, template: .chatML("You are a helpful assistant."), maxTokenCount: 512) else {
            throw TestError.initializationFailed
        }
        
        // Load with scale 1.0
        print("Loading adapter with scale 1.0...")
        _ = try await llm.loadLoRAAdapter(from: adapterURL, scale: 1.0, name: "gandalf")
        if let info = llm.activeLoRAAdapters["gandalf"] {
            print("[OK] Adapter loaded with scale: \(info.scale)")
            #expect(info.scale == 1.0, "Scale should be 1.0")
        }
        
        // Update scale to 0.5
        print("\nUpdating adapter scale to 0.5...")
        try await llm.updateLoRAAdapterScale(named: "gandalf", scale: 0.5)
        if let info = llm.activeLoRAAdapters["gandalf"] {
            print("[OK] Adapter scale updated to: \(info.scale)")
            #expect(info.scale == 0.5, "Scale should be 0.5")
        }
        
        // Update scale to 1.5
        print("\nUpdating adapter scale to 1.5...")
        try await llm.updateLoRAAdapterScale(named: "gandalf", scale: 1.5)
        if let info = llm.activeLoRAAdapters["gandalf"] {
            print("[OK] Adapter scale updated to: \(info.scale)")
            #expect(info.scale == 1.5, "Scale should be 1.5")
        }
        
        print("[OK] Scale adjustment test completed\n")
    }
}

enum TestError: Error {
    case modelNotFound
    case adapterNotFound
    case initializationFailed
}
