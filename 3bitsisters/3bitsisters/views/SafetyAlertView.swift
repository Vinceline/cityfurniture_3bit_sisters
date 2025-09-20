import SwiftUI

struct SafetyAlertView: View {
    let prediction: SafetyPrediction?
    let willRain: Bool
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: willRain ? "cloud.rain.fill" : "shield.checkered")
                    .foregroundColor(willRain ? .blue : .orange)
                    .font(.title2)
                
                Text(willRain ? "Weather Alert" : "Safety Alert")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
            
            Divider()
            
            if willRain {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Rain Expected")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    
                    Text("Rain is expected along your route in the next 2 hours. Consider:")
                        .font(.body)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Bringing an umbrella", systemImage: "umbrella.fill")
                        Label("Wearing waterproof clothing", systemImage: "drop.fill")
                        Label("Planning indoor alternatives", systemImage: "house.fill")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            
            if let prediction = prediction, prediction.safetyScore < 0.6  {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Safety Concern")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                    
                    Text("This area has a lower safety score (\(Int(prediction.safetyScore * 100))%). Consider:")
                        .font(.body)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Walking in groups", systemImage: "person.2.fill")
                        Label("Staying in well-lit areas", systemImage: "lightbulb.fill")
                        Label("Avoiding walking at night", systemImage: "moon.fill")
                        Label("Considering alternative routes", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            
            // Action Button
            Button(action: {
                isPresented = false
            }) {
                Text("Got It")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 10)
        .padding(.horizontal)
    }
}
