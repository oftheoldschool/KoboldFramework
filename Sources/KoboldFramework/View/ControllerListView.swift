import SwiftUI

public struct KControllerListView: View {
    @ObservedObject
    public var controllerInput: KControllerInput

    public init(controllerInput: KControllerInput) {
        self.controllerInput = controllerInput
    }

    public var body: some View {
        HStack {
            Text("Available Controllers")
            Spacer()
        }
        VStack(alignment: .leading) {
            ForEach(controllerInput.allControllers, id: \.self) { controller in
                KControllerRow(
                    controller: controller,
                    isActive: controllerInput.activeController?.id == controller.id,
                    onTap: controllerInput.activeController?.id != controller.id ? {
                        controllerInput.enableControllerById(controller.id)
                    } : nil
                )
                .padding(.horizontal)
            }
        }
    }
}

public struct KControllerRow: View {
    public let controller: KController
    public let isActive: Bool
    public let onTap: (() -> Void)?

    public var body: some View {
        if let onTap = onTap {
            Button(action: onTap) {
                controllerDescriptionView
            }.buttonStyle(PlainButtonStyle())
        } else {
            controllerDescriptionView
        }
    }

    private var controllerDescriptionView: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(controller.description)
                Text(isActive ? "Connected" : "Disconnected")
                    .foregroundColor(isActive ? .green : .adaptiveGray)
                    .bold()
            }
            Spacer()
            Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isActive ? .green : .adaptiveGray)
        }
        .contentShape(Rectangle())
        .padding(.vertical, 4)
    }
}
