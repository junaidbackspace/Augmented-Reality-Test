import SwiftUI
import RealityKit
import ARKit

struct ARViewContainer: UIViewRepresentable {
    let modelName: String

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        // Configure AR session for plane detection
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        arView.session.run(configuration)

        // Add gesture recognizers
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)

        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handlePan(_:)))
        arView.addGestureRecognizer(panGesture)

        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handlePinch(_:)))
        arView.addGestureRecognizer(pinchGesture)

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        return Coordinator(modelName: modelName)
    }
}

class Coordinator: NSObject {
    var modelEntity: ModelEntity?
    var anchorEntity: AnchorEntity?
    let modelName: String

    init(modelName: String) {
        self.modelName = modelName
    }

    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let arView = gesture.view as? ARView else { return }
        let location = gesture.location(in: arView)

        // Hit test to find a location to place the model
        let results = arView.hitTest(location, types: [.existingPlaneUsingExtent])
        if let result = results.first {
            if let anchor = anchorEntity {
                // If anchor already exists, remove it
                arView.scene.removeAnchor(anchor)
                anchorEntity = nil
                modelEntity = nil
            } else {
                // Create a new anchor entity for the model
                anchorEntity = AnchorEntity(world: simd_make_float3(result.worldTransform.columns.3.x,
                                                                    result.worldTransform.columns.3.y,
                                                                    result.worldTransform.columns.3.z))

                // Load the model
                if let modelEntity = try? ModelEntity.loadModel(named: modelName) {
                    modelEntity.scale = [0.01, 0.01, 0.01] // Initial scale
                    anchorEntity?.addChild(modelEntity)
                    self.modelEntity = modelEntity // Keep a reference for resizing
                } else {
                    print("Failed to load model")
                }

                // Add the new anchor to the scene
                if let anchor = anchorEntity {
                    arView.scene.anchors.append(anchor)
                }
            }
        }
    }

    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let arView = gesture.view as? ARView, gesture.state == .changed, let modelEntity = modelEntity else { return }
        let location = gesture.location(in: arView)

        // Hit test to find a new location to move the model
        let results = arView.hitTest(location, types: [.existingPlaneUsingExtent])
        if let result = results.first {
            modelEntity.position = simd_make_float3(result.worldTransform.columns.3.x,
                                                     result.worldTransform.columns.3.y + (modelEntity.visualBounds(relativeTo: nil).extents.y / 2),
                                                     result.worldTransform.columns.3.z)
        }
    }

    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let modelEntity = modelEntity else { return }

        if gesture.state == .changed {
            let scale = gesture.scale
            modelEntity.scale *= Float(scale) // Scale the model
            gesture.scale = 1.0 // Reset scale for smooth resizing
        }
    }
}
