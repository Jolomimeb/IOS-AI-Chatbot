import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @StateObject private var secrets = Secrets.shared
    
    var body: some View {
        NavigationView {
            if authManager.isAuthenticated {
                HomeView()
                    .environmentObject(secrets)
            } else {
                loginView
            }
        }
    }

    var loginView: some View {
        VStack(spacing: 20) {
            Text("Welcome to MebAssistant!")
                .font(.title)
                .padding()

            // Button changed to NavigationLink
            NavigationLink(destination: SignInView()) {
                            Text("Sign In")
                                .foregroundColor(.white)
                                .padding()
                                .frame(width: 200, height: 50)
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
            .padding(.horizontal)

            NavigationLink("Sign Up", destination: SignUpView())
                .foregroundColor(.blue)
        }
        .navigationTitle("MebAssistant")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
        .environmentObject(AuthenticationManager()) // Ensure the preview environment has access to an AuthenticationManager
    }
}

