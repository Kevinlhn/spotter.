//
//  WelcomeVIew.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 10/2/25.
//

import SwiftUI

struct WelcomeView: View {
    @State private var animate = false
    @State private var goToTabBar = false
    
    var body: some View {
        ZStack {
            if goToTabBar {
                TabBar()
                    .transition(.opacity)
            } else {
                Color(hex: "1E5A66")
                    .ignoresSafeArea()
                
                VStack{
                    Text("Welcome.")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(Color(hex: "C6DEE2"))
                        .opacity(animate ? 1 : 0)
                        .animation(
                            .easeInOut(duration: 3.5),
                            value: animate
                        )
                    Text("Let’s workout!")
                        .font(.footnote)
                        .foregroundColor(.white)
                        .opacity(animate ? 1 : 0)
                        .animation(
                            .easeInOut(duration: 3.5)
                            ,value: animate
                        )
                }
            }
        }
        .onAppear {
            animate = true
            // Auto-transition to TabBar after 2.5 sec
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                withAnimation {
                    goToTabBar = true
                }
            }
        }
    }
}

struct WelcomeView_Previews: PreviewProvider{
    static var previews: some View{
        WelcomeView()
    }
}
