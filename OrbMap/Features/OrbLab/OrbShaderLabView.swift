import SwiftUI
import PhotosUI
import UIKit

struct OrbShaderLabView: View {
    private let previewSize: CGFloat = 320

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isShowingCamera = false
    private let parameters = OrbShaderParameters()

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    orbPreview
                        .padding(.top, 36)

                    Text("Effect-style ORB Pipeline")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.55))

                    PhotosPicker(
                        selection: $selectedPhoto,
                        matching: .images
                    ) {
                        Label("选择测试照片", systemImage: "photo.on.rectangle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.white)
                    .foregroundStyle(.black)

                    Button {
                        isShowingCamera = true
                    } label: {
                        Label("拍摄测试照片", systemImage: "camera")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.white)
                    .foregroundStyle(.white)
                    .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))

                    if !UIImagePickerController.isSourceTypeAvailable(.camera) {
                        Text("当前设备没有可用相机")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.45))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .task(id: selectedPhoto) {
            await loadSelectedPhoto()
        }
        .fullScreenCover(isPresented: $isShowingCamera) {
            CameraCaptureView(image: $selectedImage)
                .ignoresSafeArea()
        }
    }

    @ViewBuilder
    private var orbPreview: some View {
        if let image = selectedImage ?? loadSampleImage() {
            OrbImageView(
                image: Image(uiImage: image),
                imageAspectRatio: image.size.width / image.size.height,
                size: previewSize,
                parameters: parameters
            )
        } else {
            ContentUnavailableView(
                "找不到测试照片",
                systemImage: "photo",
                description: Text("请将 sample_photo 或 orb_lab_image 加入 OrbMap Target。")
            )
            .foregroundStyle(.white)
            .frame(width: previewSize, height: previewSize)
        }
    }

    private func loadSampleImage() -> UIImage? {
        let candidates = [
            (name: "sample_photo", extension: "jpg"),
            (name: "sample_photo", extension: "png"),
            (name: "orb_lab_image", extension: "jpg")
        ]

        for candidate in candidates {
            if let url = Bundle.main.url(
                forResource: candidate.name,
                withExtension: candidate.extension
            ), let image = UIImage(contentsOfFile: url.path) {
                return image
            }
        }

        return nil
    }

    private func loadSelectedPhoto() async {
        guard let selectedPhoto else {
            return
        }

        guard let data = try? await selectedPhoto.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else {
            return
        }

        selectedImage = image
    }
}

private struct CameraCaptureView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    @Binding var image: UIImage?

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(
        _ uiViewController: UIImagePickerController,
        context: Context
    ) {
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(image: $image, dismiss: dismiss)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        private let image: Binding<UIImage?>
        private let dismiss: DismissAction

        init(image: Binding<UIImage?>, dismiss: DismissAction) {
            self.image = image
            self.dismiss = dismiss
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let capturedImage = info[.originalImage] as? UIImage {
                image.wrappedValue = capturedImage
            }

            dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss()
        }
    }
}

#Preview {
    OrbShaderLabView()
}
