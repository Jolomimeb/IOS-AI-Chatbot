import SwiftUI
import FirebaseAuth
import GoogleSignIn

struct SignInView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var showingResetPassword = false

    var body: some View {
        VStack(spacing: 15) {
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .autocapitalization(.none)
                .keyboardType(.emailAddress)

            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }

            Button("Sign In") {
                signIn()
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .cornerRadius(8)
            .padding(.horizontal)
            
            Button("Sign in with Google") {
                signInWithGoogle()
            }
            .foregroundColor(.blue)

            Button("Forgot Password?") {
                self.resetPassword()
            }
            .foregroundColor(.blue)
            .padding()
        }
        .navigationTitle("Sign In")
        .alert(isPresented: $showingResetPassword) {
            Alert(
                title: Text("Reset Password"),
                message: Text("Password reset link sent successfully. Check your email to continue."),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    func signIn() {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                errorMessage = error.localizedDescription
            } else {
                authManager.isAuthenticated = true
            }
        }
    }

    func resetPassword() {
        guard !email.isEmpty else {
            errorMessage = "Please enter your email address to reset your password."
            return
        }

        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                errorMessage = "Failed to send reset: \(error.localizedDescription)"
            } else {
                showingResetPassword = true
            }
        }
    }

    func signInWithGoogle() {
        print("Sign in with google")
    }

}

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView().environmentObject(AuthenticationManager())
    }
}

