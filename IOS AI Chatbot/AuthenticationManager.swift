import Foundation
import FirebaseAuth

class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false

    init() {
        checkAuthentication()
    }

    func checkAuthentication() {
        DispatchQueue.main.async {
            self.isAuthenticated = Auth.auth().currentUser != nil
        }
    }

    func signIn(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error signing in: \(error.localizedDescription)")
                    self?.isAuthenticated = false
                } else {
                    self?.isAuthenticated = true
                }
            }
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                self.isAuthenticated = false
                print("signed out")
            }
        } catch let signOutError as NSError {
            print("Error signing out: \(signOutError.localizedDescription)")
        }
    }
}

