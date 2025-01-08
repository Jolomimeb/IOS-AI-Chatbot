import SwiftUI
import FirebaseAuth
import AVFoundation
import GoogleGenerativeAI
import Speech

struct HomeView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showCommands = false
    @State private var useText = false // start with text mode for demonstration
    @State private var userName = "User"
    @State private var inputText = ""
    @State private var commands: [String] = []
    @State private var speechText = "Ready to receive commands"
    @EnvironmentObject var secrets: Secrets
    
    private let synthesizer = AVSpeechSynthesizer()
    var model: GenerativeModel {
            GenerativeModel(name: "gemini-1.5-flash", apiKey: secrets.apiKey)
        }

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack {
                    HStack {
                        Text("Welcome back, \(userName)")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding(.leading, 20)
                        Spacer()
                    }
                    if !useText {
                        Button(action: {
                            // Placeholder for speech action
                            print("Tap to Speak action")
                            startListening()
                        }) {
                            Text("Tap to Speak")
                                .font(.largeTitle)
                                .foregroundColor(.white)
                                .frame(width: geometry.size.width * 0.6, height: geometry.size.width * 0.6)
                                .background(Circle().fill(Color.blue))
                                .shadow(radius: 10)
                        }
                        // Display formatted speech text
                        ResponseTextView(responseText: speechText)
                            .padding()
                        Spacer()
                        .padding(.bottom, 50)
                        
                    } else {
                        TextField("Enter command", text: $inputText, onCommit: sendCommand)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                            .foregroundColor(.black)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(10)
                        
                        // Display formatted speech text.
                        ResponseTextView(responseText: speechText)
                            .padding()
                        Spacer()
                    }
                    Button("Switch to \(useText ? "Speech" : "Text")") {
                        useText.toggle()
                    }
                    .foregroundColor(.blue)
                    .padding()
                    
                    Spacer()
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .background(Color.black.edgesIgnoringSafeArea(.all))
                
                CommandSheet(showCommands: $showCommands, commands: commands)
                    .offset(y: showCommands ? geometry.size.height * 0.3 : geometry.size.height)
                    .animation(.spring(), value: showCommands)
            }
            .navigationBarItems(trailing: Button(action: authManager.signOut) {
                Image(systemName: "power").foregroundColor(.red)
            })
            .navigationBarTitle("Home", displayMode: .inline)
            //.onAppear(perform: fetchUserName)
            .onAppear {
                fetchUserName()
                requestSpeechAuthorization()
            }
        }
    }

    private func sendCommand() {
        if !inputText.isEmpty {
            let command = inputText
            commands.append(command)
            inputText = ""
            processCommand(command)
        }
    }

    private func processCommand(_ command: String) {
        DispatchQueue.main.async {
            Task {
                do {
                    let response = try await model.generateContent(command)
                    if let text = response.text {
                        self.speechText = "Response: \(text)"
                        self.speakText(self.speechText)
                    } else {
                        self.speechText = "Error: No response received from Gemini."
                        self.speakText(self.speechText)
                    }
                } catch {
                    self.speechText = "Error communicating with Gemini: \(error)"
                    self.speakText(self.speechText)
                }
            }
        }
    }

    private func speakText(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        synthesizer.speak(utterance)
    }

    private func fetchUserName() {
        if let user = Auth.auth().currentUser {
            userName = user.displayName ?? "User"
        }
    }
    
    private func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            // Handle authorization status as needed
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    speechText = "Ready to receive commands."
                default:
                    speechText = "Speech recognition not authorized."
                }
            }
        }
    }
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    private func startListening() {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            speechText = "Stopped listening."
        } else {
            try? startSpeechRecognition()
            speechText = "I'm listening..."
        }
    }

    private func startSpeechRecognition() throws {
        recognitionTask?.cancel()
        recognitionTask = nil

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        let inputNode = audioEngine.inputNode

        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }

        recognitionRequest.shouldReportPartialResults = true

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false

            if let result = result {
                self.inputText = result.bestTranscription.formattedString
                isFinal = result.isFinal
                if isFinal {
                    self.sendCommand()
                    self.speechText = "Tap to speak again."
                }
            }

            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
            }
        }

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()
    }

}

// Custom view for displaying the response text
struct ResponseTextView: View {
    var responseText: String

    var body: some View {
        Text(responseText)
            .font(.body) // Customize the font as needed
            .fontWeight(.medium)
            .foregroundColor(Color.white)
            .padding()
            .background(Color.blue.opacity(0.2))
            .cornerRadius(12)
            .shadow(radius: 4)
    }
}

// Reusable component for showing commands
struct CommandSheet: View {
    @Binding var showCommands: Bool
    let commands: [String]

    var body: some View {
        VStack {
            Capsule()
                .frame(width: 50, height: 5)
                .foregroundColor(.gray)
                .padding()
                .gesture(DragGesture().onEnded(toggleSheet))

            VStack(spacing: 15) {
                Text("Commands").font(.headline).padding()
                ScrollView {
                    ForEach(commands, id: \.self) { Text($0).foregroundColor(.gray).padding() }
                }
            }
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .cornerRadius(20)
        }
        .frame(height: 300)
        .background(Color(UIColor.secondarySystemBackground))
    }

    private func toggleSheet(_ drag: DragGesture.Value) {
        withAnimation {
            showCommands = drag.translation.height < 0 || drag.translation.height > 50 ? !showCommands : showCommands
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView().environmentObject(AuthenticationManager())
    }
}

