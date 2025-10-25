//
//  Profile.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 10/2/25.
//

import SwiftUI

struct Profile: View {
    var body: some View {
        ScrollView {
            VStack{
                
                // MARK: - App Title
                Text("spotter for")
                    .foregroundStyle(Color(hex: "1E5A66"))
                    .font(.headline)
                    .fontWeight(.bold)

                    Text("Kevin Hernandez") // <- Replace with @State later
                        .font(.title3)
                        .fontWeight(.semibold)
            
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .foregroundColor(Color(hex: "1E5A66").opacity(0.8))

                    
                    
                
                // MARK: - Stats
                HStack(spacing: 40) {
                    StatBlock(title: "Weight", value: "230 lbs")
                    StatBlock(title: "Height", value: "5'11\"")
                }
                .padding(.top, 10)
                
                Divider()
                    .padding(.vertical, 10)
                
                // MARK: - Profile Options
                VStack(spacing: 16) {
                    ProfileRow(icon: "pencil", title: "Edit Profile")
                    ProfileRow(icon: "gearshape", title: "Settings")
                    ProfileRow(icon: "lock.fill", title: "Privacy")
                    ProfileRow(icon: "arrow.right.square", title: "Log Out", isDestructive: true)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Small Components
struct StatBlock: View {
    var title: String
    var value: String
    
    var body: some View {
        VStack {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(Color(hex: "1E5A66"))
            Text(title)
                .font(.footnote)
                .foregroundColor(.gray)
        }
    }
}

struct ProfileRow: View {
    var icon: String
    var title: String
    var isDestructive: Bool = false
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(isDestructive ? .red : Color(hex: "1E5A66"))
            Text(title)
                .foregroundColor(isDestructive ? .red : .black)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
    }
}

struct Profile_Previews: PreviewProvider {
    static var previews: some View {
        Profile()
    }
}
