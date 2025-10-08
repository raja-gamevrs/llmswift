import SwiftUI
import LLM

/// Example: iOS Persona Chat App with Hot-Swappable LoRA Adapters
/// This demonstrates how to build an offline persona chat app with real-time adapter switching

// MARK: - Persona Bot Implementation

class PersonaBot: LLM {
    
    /// Initialize with a base model
    convenience init?(modelPath: String) {
        let url = URL(fileURLWithPath: modelPath)
        self.init(
            from: url,
            template: .chatML("You are a helpful AI assistant."),
            maxTokenCount: 2048
        )
    }
    
    /// Switch to a different persona by loading its LoRA adapter
    func switchPersona(to persona: Persona) async throws {
        // Clear any existing adapters
        await clearAllLoRAAdapters()
        
        // Load the new persona's adapter if available
        if let adapterPath = persona.adapterPath {
            try await loadLoRAAdapter(
                from: adapterPath,
                scale: persona.scale,
                name: persona.name
            )
        }
        
        // Update system prompt if needed
        if let template = persona.template {
            self.template = template
        }
    }
    
    /// Blend multiple personas by loading multiple adapters
    func blendPersonas(_ personas: [(Persona, Float)]) async throws {
        await clearAllLoRAAdapters()
        
        for (persona, scale) in personas {
            if let adapterPath = persona.adapterPath {
                try await loadLoRAAdapter(
                    from: adapterPath,
                    scale: scale,
                    name: persona.name
                )
            }
        }
    }
}

// MARK: - Persona Model

struct Persona: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let description: String
    let adapterPath: String?
    let scale: Float
    let template: Template?
    let icon: String
    
    static let examples: [Persona] = [
        Persona(
            name: "Default",
            description: "Standard helpful assistant",
            adapterPath: nil,
            scale: 1.0,
            template: .chatML("You are a helpful AI assistant."),
            icon: "brain"
        ),
        Persona(
            name: "Friendly",
            description: "Warm and casual conversation style",
            adapterPath: "/path/to/friendly-adapter.gguf",
            scale: 1.0,
            template: .chatML("You are a friendly and warm AI companion. Use casual language and show empathy."),
            icon: "heart.fill"
        ),
        Persona(
            name: "Professional",
            description: "Formal and business-oriented",
            adapterPath: "/path/to/professional-adapter.gguf",
            scale: 1.0,
            template: .chatML("You are a professional business assistant. Be formal, precise, and efficient."),
            icon: "briefcase.fill"
        ),
        Persona(
            name: "Creative",
            description: "Imaginative and artistic",
            adapterPath: "/path/to/creative-adapter.gguf",
            scale: 1.2,
            template: .chatML("You are a creative and imaginative AI. Think outside the box and be artistic."),
            icon: "paintbrush.fill"
        ),
        Persona(
            name: "Technical",
            description: "Expert in programming and technology",
            adapterPath: "/path/to/technical-adapter.gguf",
            scale: 1.0,
            template: .chatML("You are a technical expert specializing in programming and technology."),
            icon: "chevron.left.forwardslash.chevron.right"
        )
    ]
}

// MARK: - Chat Message Model

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: Role
    let content: String
    let timestamp: Date
    
    var isUser: Bool {
        role == .user
    }
}

// MARK: - Main Chat View

struct PersonaChatView: View {
    @StateObject private var bot: PersonaBot
    @State private var selectedPersona: Persona = Persona.examples[0]
    @State private var inputText = ""
    @State private var messages: [ChatMessage] = []
    @State private var isLoading = false
    @State private var showPersonaSelector = false
    
    init(modelPath: String) {
        _bot = StateObject(wrappedValue: PersonaBot(modelPath: modelPath)!)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Persona selector bar
                personaSelectorBar
                
                Divider()
                
                // Chat messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(messages) { message in
                                ChatBubble(message: message)
                                    .id(message.id)
                            }
                            
                            if isLoading {
                                HStack {
                                    ProgressView()
                                    Text("Thinking...")
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                            }
                        }
                        .padding()
                    }
                    .onChange(of: messages.count) { _ in
                        if let lastMessage = messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                Divider()
                
                // Input bar
                inputBar
            }
            .navigationTitle("Persona Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showPersonaSelector.toggle()
                    } label: {
                        Image(systemName: selectedPersona.icon)
                    }
                }
            }
            .sheet(isPresented: $showPersonaSelector) {
                PersonaSelectorSheet(
                    personas: Persona.examples,
                    selectedPersona: $selectedPersona,
                    onSelect: { persona in
                        Task {
                            await switchPersona(to: persona)
                        }
                    }
                )
            }
        }
    }
    
    private var personaSelectorBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Persona.examples) { persona in
                    PersonaChip(
                        persona: persona,
                        isSelected: persona.id == selectedPersona.id
                    ) {
                        Task {
                            await switchPersona(to: persona)
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
    }
    
    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField("Message", text: $inputText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...5)
                .disabled(isLoading)
            
            Button {
                sendMessage()
            } label: {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(inputText.isEmpty ? .gray : .blue)
            }
            .disabled(inputText.isEmpty || isLoading)
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    private func switchPersona(to persona: Persona) async {
        selectedPersona = persona
        isLoading = true
        
        do {
            try await bot.switchPersona(to: persona)
            
            // Add system message
            await MainActor.run {
                messages.append(ChatMessage(
                    role: .bot,
                    content: "Switched to \(persona.name) persona",
                    timestamp: Date()
                ))
            }
        } catch {
            print("Failed to switch persona: \(error)")
        }
        
        isLoading = false
    }
    
    private func sendMessage() {
        guard !inputText.isEmpty else { return }
        
        let userMessage = inputText
        inputText = ""
        
        // Add user message
        messages.append(ChatMessage(
            role: .user,
            content: userMessage,
            timestamp: Date()
        ))
        
        isLoading = true
        
        Task {
            // Get bot response
            await bot.respond(to: userMessage)
            
            // Add bot response
            await MainActor.run {
                messages.append(ChatMessage(
                    role: .bot,
                    content: bot.output,
                    timestamp: Date()
                ))
                isLoading = false
            }
        }
    }
}

// MARK: - Supporting Views

struct ChatBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser { Spacer() }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(12)
                    .background(message.isUser ? Color.blue : Color(.systemGray5))
                    .foregroundColor(message.isUser ? .white : .primary)
                    .cornerRadius(16)
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if !message.isUser { Spacer() }
        }
    }
}

struct PersonaChip: View {
    let persona: Persona
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: persona.icon)
                Text(persona.name)
                    .font(.subheadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color(.systemGray5))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
}

struct PersonaSelectorSheet: View {
    let personas: [Persona]
    @Binding var selectedPersona: Persona
    let onSelect: (Persona) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List(personas) { persona in
                Button {
                    selectedPersona = persona
                    onSelect(persona)
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: persona.icon)
                            .frame(width: 30)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(persona.name)
                                .font(.headline)
                            Text(persona.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if persona.id == selectedPersona.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Select Persona")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Advanced Example: Blended Personas

struct BlendedPersonaView: View {
    @StateObject private var bot: PersonaBot
    @State private var friendlyScale: Float = 0.5
    @State private var professionalScale: Float = 0.5
    
    init(modelPath: String) {
        _bot = StateObject(wrappedValue: PersonaBot(modelPath: modelPath)!)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Blend Personas")
                .font(.title)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Friendly: \(friendlyScale, specifier: "%.2f")")
                Slider(value: $friendlyScale, in: 0...1)
                
                Text("Professional: \(professionalScale, specifier: "%.2f")")
                Slider(value: $professionalScale, in: 0...1)
            }
            .padding()
            
            Button("Apply Blend") {
                Task {
                    let friendly = Persona.examples[1]
                    let professional = Persona.examples[2]
                    
                    try? await bot.blendPersonas([
                        (friendly, friendlyScale),
                        (professional, professionalScale)
                    ])
                }
            }
            .buttonStyle(.borderedProminent)
            
            Text("Active Adapters: \(bot.activeLoRAAdapterNames.joined(separator: ", "))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

// MARK: - App Entry Point Example

@main
struct PersonaChatApp: App {
    var body: some Scene {
        WindowGroup {
            PersonaChatView(modelPath: "/path/to/your/base-model.gguf")
        }
    }
}
