//
//  ViewController.swift
//  FileDeletePermissionBug
//
//  Created by Giovanni Murru on 03/12/24.
//

import UIKit

class ViewController: UIViewController {

    var currentItemURL: URL? {
        didSet {
            deleteFileButton?.isEnabled = currentItemURL != nil
            latestErrorMessage.text = ""
        }
    }
    
    weak var deleteFileButton : UIButton!
    var latestErrorMessage : UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create and configure the label
        let instructionsLabel = UILabel()
        instructionsLabel.text = """
        INSTRUCTIONS:
        1) Open a file that has been shared to you through iCloud Drive. 
        2) When the file is open it is copied to the temporary directory. 
        3) You can then try to delete the file to get the error.
        """
        instructionsLabel.numberOfLines = 0
        instructionsLabel.textAlignment = .left
        instructionsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Create and configure the "Open File" button
        let openFileButton = UIButton(type: .system)
        openFileButton.setTitle("Open File", for: .normal)
        openFileButton.addTarget(self, action: #selector(openFile), for: .touchUpInside)
        openFileButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Create and configure the "Delete File" button
        let deleteFileButton = UIButton(type: .system)
        deleteFileButton.setTitle("Delete File", for: .normal)
        deleteFileButton.isEnabled = false
        deleteFileButton.addTarget(self, action: #selector(deleteFile), for: .touchUpInside)
        deleteFileButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Stack view for buttons
        let btnStackView = UIStackView(arrangedSubviews: [openFileButton, deleteFileButton])
        btnStackView.axis = .horizontal
        btnStackView.spacing = 20
        btnStackView.distribution = .equalSpacing
        btnStackView.alignment = .center
        btnStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Create a text view for the error message
        let latestErrorMessage = UITextView()
        latestErrorMessage.font = instructionsLabel.font
        latestErrorMessage.text = ""
        latestErrorMessage.isEditable = false           // Prevent editing
        latestErrorMessage.isSelectable = true          // Allow text selection
        latestErrorMessage.isScrollEnabled = true       // Enable scrolling
        latestErrorMessage.translatesAutoresizingMaskIntoConstraints = false
        latestErrorMessage.backgroundColor = .systemBackground
        latestErrorMessage.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10) // Add padding
        
        // Add views to the main view
        view.addSubview(instructionsLabel)
        view.addSubview(btnStackView)
        view.addSubview(latestErrorMessage)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            // Instructions label at the top
            instructionsLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            instructionsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            instructionsLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Button stack view below the instructions label
            btnStackView.topAnchor.constraint(equalTo: instructionsLabel.bottomAnchor, constant: 20),
            btnStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            btnStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Error message text view below the button stack view
            latestErrorMessage.topAnchor.constraint(equalTo: btnStackView.bottomAnchor, constant: 20),
            latestErrorMessage.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            latestErrorMessage.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            latestErrorMessage.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20)
        ])
        
        // Store the delete button and latest error message for later use
        self.deleteFileButton = deleteFileButton
        self.latestErrorMessage = latestErrorMessage
        
        if let testfileURL = Bundle.main.url(forResource: "testfile", withExtension: "txt") {
            print("\n")
            print("INFO: FILE ATTRIBUTES FOR BUNDLED TEST FILE AT \(testfileURL.path)")
            printFileAttributes(path: testfileURL.path)
            let temporaryItemURL = FileManager.default.temporaryDirectory.appendingPathComponent(testfileURL.lastPathComponent)
            try? FileManager.default.removeItem(at: temporaryItemURL)
            try? FileManager.default.copyItem(atPath: testfileURL.path, toPath: temporaryItemURL.path)
            print("\n")
            print("INFO: FILE ATTRIBUTES FOR SANDBOXED TEST FILE AT \(testfileURL.path)")
            printFileAttributes(path: temporaryItemURL.path)
        }
    }
    
    func printFileAttributes(path: String) {
        
        if let fileAttributes = try? FileManager.default.attributesOfItem(atPath: path) {
            if let owner = fileAttributes[.ownerAccountID] {
                print("INFO: Owner: \(owner)")
            }
            if let group = fileAttributes[.groupOwnerAccountID] {
                print("INFO: Group: \(group)")
            }
            if let permissions = fileAttributes[.posixPermissions] as? NSNumber {
                let octalPermissions = String(permissions.intValue, radix: 8)
                print("INFO: POSIX Permissions: \(octalPermissions)")
            }
        } else {
            print("WARNING: could not retrieve file attributes")
        }
        print("\n")
    }

    
    func changeFilepermission(to permissions: Int, at path: String) throws {
        let fileManager = FileManager.default
        
        // Define the new attributes for the file
        let newAttributes: [FileAttributeKey: Any] = [
            .posixPermissions: NSNumber(value: permissions)
        ]
        try fileManager.setAttributes(newAttributes, ofItemAtPath: path)
    }

    @objc func openFile(_ sender: UIButton) {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.movie, .text, .pdf, .image], asCopy: false)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        documentPicker.shouldShowFileExtensions = true
        documentPicker.modalPresentationStyle = .fullScreen
        present(documentPicker, animated: true)
    }
    
    @objc func deleteFile(_ sender: UIButton) {
        guard let currentItemURL = currentItemURL else {
            return
        }
        print("\n")
        print("INFO: FILE ATTRIBUTES FOR SANDBOXED DELETE FILE AT \(currentItemURL.path)")
        printFileAttributes(path: currentItemURL.path)
        do {
            try FileManager.default.removeItem(at: currentItemURL)
            self.currentItemURL = nil
        } catch {
            print("WARNING: Couldn't delete file at \(currentItemURL.path).")
            print("WARNING: Trying to change permissions to 644 even if this shouldn't be necessary because I am the owner of the file...")
            do {
                // Set the new attributes
                try changeFilepermission(to: 0o644, at: currentItemURL.path)
                print("INFO: File permissions successfully updated to 644.")
                do {
                    try FileManager.default.removeItem(at: currentItemURL)
                    self.currentItemURL = nil
                } catch {
                    errorDeletingFile(error: error as NSError, temporaryItemURL: currentItemURL)
                }
            } catch {
                print("ERROR: Failed to update file permissions: \(error.localizedDescription)")
                errorDeletingFile(error: error as NSError, temporaryItemURL: currentItemURL)
            }
            return
        }
        
    }
    
    func errorDeletingFile(error: NSError, temporaryItemURL: URL) {
        let errorDescription = "\(error.localizedDescription)\n\nError code: \(error.code)\n\nError domain: \(error.domain)\n\nError userInfo: \(error.userInfo)"
        latestErrorMessage.text = "ERROR: \(errorDescription)"
    }
}

extension ViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        
        guard let sourceItemURL = urls.first else {
            return
        }
        
        
        print("INFO: documentPicker did pick source item at url \(sourceItemURL)")
        
        let securityScoped = sourceItemURL.startAccessingSecurityScopedResource()
        print("\n")
        print("INFO: FILE ATTRIBUTES FOR PICKED DOCUMENT AT \(sourceItemURL.path)")
        printFileAttributes(path: sourceItemURL.path)
        if securityScoped {
            sourceItemURL.stopAccessingSecurityScopedResource()
        }
        
        let temporaryItemURL = FileManager.default.temporaryDirectory.appendingPathComponent(sourceItemURL.lastPathComponent)
        
        if FileManager.default.fileExists(atPath: temporaryItemURL.path) {
            print("WARNING: Temporary item already exists.")
            currentItemURL = temporaryItemURL
            print("\n")
            print("INFO: FILE ATTRIBUTES FOR SANDBOXED PICKED DOCUMENT AT \(temporaryItemURL.path)")
            printFileAttributes(path: temporaryItemURL.path)
            return
        }
        
        print("INFO: Trying to copy source item to temporary directory")
        do {
            let securityScoped = sourceItemURL.startAccessingSecurityScopedResource()
            try FileManager.default.copyItem(at: sourceItemURL, to: temporaryItemURL)
            currentItemURL = temporaryItemURL
            print("\n")
            print("INFO: FILE ATTRIBUTES FOR SANDBOXED PICKED DOCUMENT AT \(temporaryItemURL.path)")
            printFileAttributes(path: temporaryItemURL.path)
            if securityScoped {
                sourceItemURL.stopAccessingSecurityScopedResource()
            }
        } catch {
            print("ERROR: Could not copy source item to temporary directory: \(error)")
            return
        }
    }
}

