import Flutter
import UIKit
import VisionKit
import PhotosUI

public class AttachmentStudioPlugin: NSObject, FlutterPlugin, VNDocumentCameraViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, PHPickerViewControllerDelegate, UIDocumentPickerDelegate {
    private var result: FlutterResult?
    private var hostViewController: UIViewController?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "pixel_to_pdf/scanner", binaryMessenger: registrar.messenger())
        let instance = AttachmentStudioPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        self.result = result
        self.hostViewController = UIApplication.shared.keyWindow?.rootViewController

        switch call.method {
        case "scanDocument":
            startScan()
        case "takeImage":
            startCamera()
        case "pickImage":
            startPicker(isMulti: false)
        case "pickMultiImage":
            startPicker(isMulti: true)
        case "pickFile":
            startFilePicker()
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // ── Document Scanner ───────────────────────────────────────────────────

    private func startScan() {
        guard VNDocumentCameraViewController.isSupported else {
            result?(FlutterError(code: "NOT_SUPPORTED", message: "Document scanner not supported on this device", details: nil))
            return
        }
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = self
        hostViewController?.present(scanner, animated: true)
    }

    public func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        var paths = [String]()
        for i in 0..<scan.pageCount {
            let image = scan.imageOfPage(at: i)
            if let path = saveImageToTemp(image: image) {
                paths.append(path)
            }
        }
        controller.dismiss(animated: true) {
            self.result?(paths)
        }
    }

    public func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        controller.dismiss(animated: true) {
            self.result?(nil)
        }
    }

    // ── Camera ─────────────────────────────────────────────────────────────

    private func startCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            result?(FlutterError(code: "NOT_SUPPORTED", message: "Camera not available", details: nil))
            return
        }
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        hostViewController?.present(picker, animated: true)
    }

    public func imagePickerController(_ picker: UIImagePickerController, didFinishWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            let path = saveImageToTemp(image: image)
            picker.dismiss(animated: true) {
                self.result?(path)
            }
        }
    }

    // ── Picker ─────────────────────────────────────────────────────────────

    private func startPicker(isMulti: Bool) {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = isMulti ? 0 : 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        hostViewController?.present(picker, animated: true)
    }

    public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        if results.isEmpty {
            self.result?(nil)
            return
        }

        let group = DispatchGroup()
        var paths = [String]()

        for result in results {
            group.enter()
            result.itemProvider.loadObject(ofClass: UIImage.self) { (object, error) in
                if let image = object as? UIImage {
                    if let path = self.saveImageToTemp(image: image) {
                        paths.append(path)
                    }
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            if results.count == 1 {
                self.result?(paths.first)
            } else {
                self.result?(paths)
            }
        }
    }

    // ── File Picker ────────────────────────────────────────────────────────

    private func startFilePicker() {
        let picker = UIDocumentPickerViewController(documentTypes: ["public.item"], in: .import)
        picker.delegate = self
        hostViewController?.present(picker, animated: true)
    }

    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        self.result?(urls.first?.path)
    }

    // ── Helper ─────────────────────────────────────────────────────────────

    private func saveImageToTemp(image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        let fileName = UUID().uuidString + ".jpg"
        let path = NSTemporaryDirectory().appending(fileName)
        let url = URL(fileURLWithPath: path)
        try? data.write(to: url)
        return path
    }
}
