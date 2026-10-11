import Foundation

enum ExerciseGuidance {
    static func cue(for name: String) -> String {
        switch name.lowercased() {
        case "goblet squat": return "Hold a dumbbell close to your chest. Bend your knees and hips, keeping your feet planted. Stand up with control."
        case "bodyweight squat": return "Stand with your feet comfortably apart. Bend at your knees and hips, then stand back up. Use a comfortable range of motion."
        case "dumbbell floor press": return "Lie on your back with knees bent and a dumbbell in each hand. Press up, then lower until your upper arms gently meet the floor."
        case "dumbbell row": return "Support one hand on a sturdy bench. Pull the dumbbell toward your hip, then lower with control. Log reps per side."
        case "romanian deadlift", "dumbbell romanian deadlift": return "Keep a slight bend in your knees. Move your hips backward as you lower the weight close to your legs, then stand tall."
        case "incline push-up": return "Place your hands on a sturdy raised surface. Keep your body in a straight line as you lower your chest and press back up."
        case "glute bridge", "hip thrust": return "Press through your feet to lift your hips. Pause briefly at the top, then lower with control."
        case "reverse lunge": return "Step one foot back, bend both knees, then return to standing. Alternate sides and log reps per side."
        case "lat pulldown": return "Sit tall and pull the bar toward your upper chest. Return it slowly without swinging your torso."
        case "seated cable row": return "Sit tall, pull the handle toward your lower ribs, then reach forward with control."
        case "lateral raise": return "With a slight bend in your elbows, raise your arms out to the sides to a comfortable height. Lower slowly."
        case "standing calf raise": return "Use a stable support for balance. Rise onto your toes, pause, and lower your heels with control."
        case "leg press": return "Keep your back supported and feet planted on the platform. Bend your knees within a comfortable range, then press away without locking your knees."
        case "barbell bench press": return "Keep your feet planted and upper back supported. Lower the bar with control, then press up. Use a spotter or safety bars."
        default: return "Use a controlled pace and a comfortable range of motion. Record the repetitions you complete in each set."
        }
    }
}
