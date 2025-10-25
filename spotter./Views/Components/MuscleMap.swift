//
//  MuscleMap.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 9/26/25.
//
import SwiftUI

struct MuscleMap: View {
    var body: some View {
        VStack{
            // MARK: - Weekly Muscle Coverage Heatmap
                Image(.muscleMap)
                    .resizable()
                    .scaledToFit()
                    .shadow(color: Color.black, radius: 5, x: 0, y: 3)
        }
    }
}

struct MuscleMap_Previews: PreviewProvider {
    static var previews: some View {
        MuscleMap()
    }
}
