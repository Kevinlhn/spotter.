//
//  MuscleGroup.swift
//  spotter.
//
//  Created by Kevin Hernandez-Nino on 9/26/25.
//
import Foundation

enum MuscleGroup: String, Codable, CaseIterable {
    // Upper Body - Push
    case chestUpper
    case chestMiddle
    case chestLower
    case shouldersFront
    case shouldersSide
    case shouldersRear
    case tricepsLong
    case tricepsLateral
    case tricepsMedial

    // Upper Body - Pull
    case lats
    case trapsUpper
    case trapsLower
    case rhomboids
    case rearDelts
    case bicepsLong
    case bicepsShort
    case forearms

    // Core
    case absUpper
    case absLower
    case obliques
    case erectorSpinae // lower back

    // Lower Body
    case quads
    case hamstrings
    case glutes
    case calvesGastrocnemius
    case calvesSoleus
    case hipFlexors
    case adductors
    case abductors
}
