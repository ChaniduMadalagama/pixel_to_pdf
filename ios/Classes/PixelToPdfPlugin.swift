import Flutter
import UIKit
import VisionKit
import PhotosUI

public class PixelToPdfPlugin: NSObject, FlutterPlugin, VNDocumentCameraViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, PHPickerViewControllerDelegate, UIDocumentPickerDelegate {
    private var result: FlutterResult?
    private var hostViewController: UIViewController?
    private var isMultiSelectionSession: Bool = false

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "pixel_to_pdf/scanner", binaryMessenger: registrar.messenger())
        let instance = PixelToPdfPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        self.result = result
        self.hostViewController = UIApplication.shared.delegate?.window??.rootViewController
        if self.hostViewController == nil {
            if #available(iOS 13.0, *) {
                let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
                self.hostViewController = windowScene?.windows.first(where: { $0.isKeyWindow })?.rootViewController
            }
        }

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
            autoreleasepool {
                let image = scan.imageOfPage(at: i)
                if let path = saveImageToTemp(image: image) {
                    paths.append(path)
                }
            }
        }
        let flResult = self.result
        self.result = nil
        controller.dismiss(animated: true) {
            flResult?(paths)
        }
    }

    public func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        let flResult = self.result
        self.result = nil
        controller.dismiss(animated: true) {
            flResult?(nil)
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

    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        print("native: imagePickerController didFinishPickingMediaWithInfo")
        let flResult = self.result
        self.result = nil

        let image = (info[.originalImage] as? UIImage) ?? (info[.editedImage] as? UIImage)
        if let img = image {
            print("native: processing image to temp file")
            let path = saveImageToTemp(image: img)
            print("native: temp file path = \(path ?? "null")")
            picker.dismiss(animated: true) {
                print("native: camera finished, returning path")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    flResult?(path)
                }
            }
        } else {
            print("native: no image found in info")
            picker.dismiss(animated: true) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    flResult?(nil)
                }
            }
        }
    }

    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        let flResult = self.result
        self.result = nil
        picker.dismiss(animated: true) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                flResult?(nil)
            }
        }
    }

    // ── Picker ─────────────────────────────────────────────────────────────

    private func startPicker(isMulti: Bool) {
        self.isMultiSelectionSession = isMulti
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = isMulti ? 0 : 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        hostViewController?.present(picker, animated: true)
    }

    public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        let flResult = self.result
        self.result = nil

        if results.isEmpty {
            picker.dismiss(animated: true) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    flResult?(nil)
                }
            }
            return
        }

        let group = DispatchGroup()
        var paths = [String]()

        for r in results {
            group.enter()
            r.itemProvider.loadObject(ofClass: UIImage.self) { (object, error) in
                autoreleasepool {
                    if let image = object as? UIImage {
                        if let p = self.saveImageToTemp(image: image) {
                            paths.append(p)
                        }
                    }
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            picker.dismiss(animated: true) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    if self.isMultiSelectionSession {
                        flResult?(paths)
                    } else {
                        flResult?(paths.first)
                    }
                }
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
        let flResult = self.result
        self.result = nil
        flResult?(urls.first?.path)
    }

    // ── Helper ─────────────────────────────────────────────────────────────

    private func saveImageToTemp(image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        let fileName = UUID().uuidString + ".jpg"
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let url = tempDir.appendingPathComponent(fileName)
        do {
            try data.write(to: url)
            return url.path
        } catch {
            return nil
        }
    }
}
