import SwiftUI
import Auth0
import SimpleKeychain

struct MainView: View {
    @State var profile = Profile.empty
    @State var loggedIn = false
    @State var credentialsManager = CredentialsManager(authentication: Auth0.authentication())
    @State var rtAvailable = false
    
    
    var body: some View {
        if loggedIn {
            VStack {
                ProfileView(profile: self.$profile)
                Button("Logout", action: self.logout)
            }
        } else {
            VStack {
                CustomHeroView()

                Button("Login", action: self.login)
            }.onAppear {
                
                if(credentialsManager.canRenew()) {
                    credentialsManager.enableBiometrics(withTitle: "Touch or enter passcode to Login")
                    credentialsManager.credentials { result in
                        switch result {
                        case .success(let credentials):
                            self.profile = Profile.from(credentials.idToken)
                            loggedIn = true
                        case .failure(let error):
                            loggedIn = false
                            print("Failed with: \(error)")
                        }
                    }
                    
                }
                else {
                    self.loggedIn = false
                }

            }
        }
    }
    
}

struct CustomHeroView: View {
    var body: some View {
        VStack {
            Image("aaa-logo-color") // Replace "your_local_image_name" with the actual image name in your project
                .resizable()
                .frame(width: 300, height: 200) // Adjust the size as needed
                .aspectRatio(contentMode: .fit)
        }
          
    }
}










extension MainView {
    
     func login() {

        Auth0
            .webAuth()
            //.useEphemeralSession() - No SSO
            .scope("openid profile email offline_access")
            .start { result in
                switch result {
                case .success(let credentials):
                    self.loggedIn = credentialsManager.store(credentials: credentials)
                    self.profile = Profile.from(credentials.idToken)
                    if(credentials.refreshToken != nil) {rtAvailable = true}
                case .failure(let error):
                    print("Failed with: \(error)")
                }
            }
    }

    func logout() {
        _ = credentialsManager.clear()
        self.loggedIn = false
        //Below code clears the SSO session cookie
        //If we are using EphermeralSession() then there is no need for this code as SSO session cookie is not created at the time of login/signup
       Auth0
            .webAuth()
            .clearSession { result in
                switch result {
                case .success:
                    
                    self.loggedIn = false
                case .failure(let error):
                    print("Failed with: \(error)")
                }
            }
    }
    
}
