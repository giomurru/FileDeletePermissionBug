//
//  ViewController.swift
//  FileDeletePermissionBug
//
//  Created by Giovanni Murru on 03/12/24.
//

import UIKit

class ViewController: UIViewController {

    let temporaryFolderURL = FileManager.default.temporaryDirectory.appendingPathComponent("MyTemporaryFolder")
    let subTemporaryFolderURL = FileManager.default.temporaryDirectory.appendingPathComponent("MyTemporaryFolder").appendingPathComponent("SubTemporaryFolder")

    
    var currentItemURL: URL? {
        didSet {
            deleteFileButton?.isEnabled = currentItemURL != nil
            deleteFolderButton?.isEnabled = currentItemURL != nil
            latestErrorMessage.text = ""
        }
    }
    
    weak var deleteFileButton : UIButton!
    weak var deleteFolderButton : UIButton!
    weak var immutableFileSwitch : UISwitch!
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
        
        // Create and configure the "Delete Folder" button
        let deleteFolderButton = UIButton(type: .system)
        deleteFolderButton.setTitle("Delete Folder", for: .normal)
        deleteFolderButton.isEnabled = false
        deleteFolderButton.addTarget(self, action: #selector(deleteFolder), for: .touchUpInside)
        deleteFolderButton.translatesAutoresizingMaskIntoConstraints = false
        
        let immutableFileSwitchLabel = UILabel()
        immutableFileSwitchLabel.text = "Remove Immutable Flag"
        immutableFileSwitchLabel.sizeToFit()
        immutableFileSwitchLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let immutableFileSwitch = UISwitch()
        immutableFileSwitch.isOn = false
        immutableFileSwitch.translatesAutoresizingMaskIntoConstraints = false
        
        
        let switchStack = UIStackView(arrangedSubviews: [immutableFileSwitchLabel, immutableFileSwitch])
        switchStack.axis = .horizontal
        switchStack.spacing = 10
        switchStack.distribution = .equalSpacing
        switchStack.alignment = .center
        switchStack.translatesAutoresizingMaskIntoConstraints = false
        
        
        let buttonsStack = UIStackView(arrangedSubviews: [openFileButton, deleteFileButton, deleteFolderButton])
        buttonsStack.axis = .horizontal
        buttonsStack.spacing = 20
        buttonsStack.distribution = .equalSpacing
        buttonsStack.alignment = .center
        buttonsStack.translatesAutoresizingMaskIntoConstraints = false
        
        // Stack view for buttons
        let btnStackView = UIStackView(arrangedSubviews: [buttonsStack, switchStack])
        btnStackView.axis = .vertical
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
        self.deleteFolderButton = deleteFolderButton
        self.latestErrorMessage = latestErrorMessage
        self.immutableFileSwitch = immutableFileSwitch
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
        do {
            if immutableFileSwitch.isOn {
                // setting the immutable attribute to false allows us to delete the file and fixes the issue
                let newPerms = [FileAttributeKey.immutable : false as NSNumber]
                try FileManager.default.setAttributes(newPerms, ofItemAtPath: currentItemURL.path)
            }
            print("INFO: deleting file \(currentItemURL.lastPathComponent)")
            try FileManager.default.removeItem(at: currentItemURL)
            print("INFO: file \(currentItemURL.lastPathComponent) deleted successfully")
            // This fixes the issue with the Operation Not Permitted when deleting the file.
            self.currentItemURL = nil
        } catch {
            errorDeletingItem(error: error as NSError, temporaryItemURL: currentItemURL)
            return
        }
        
    }
    
    func resetImmutableFlag(directoryURL: URL, includeSubdirectories: Bool = true) {
        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: directoryURL.path)
            for f in files {
                let fileURL = directoryURL.appendingPathComponent(f)
                var isDirectory : ObjCBool = false
                if FileManager.default.fileExists(atPath: fileURL.path, isDirectory: &isDirectory) {
                    if isDirectory.boolValue && includeSubdirectories {
                        resetImmutableFlag(directoryURL: fileURL, includeSubdirectories: includeSubdirectories)
                    } else {
                        let newPerms = [FileAttributeKey.immutable : false as NSNumber]
                        try FileManager.default.setAttributes(newPerms, ofItemAtPath: fileURL.path)
                    }
                }
            }
            let newPerms = [FileAttributeKey.immutable : false as NSNumber]
            try FileManager.default.setAttributes(newPerms, ofItemAtPath: directoryURL.path)
        } catch {
            print("ERROR: error resetting immutable flag: \(error.localizedDescription)")
        }
    }
    
    @objc func deleteFolder(_ sender: UIButton) {
        guard currentItemURL != nil else {
            return
        }
        do {
            if immutableFileSwitch.isOn {
                // setting the immutable attribute to false allows us to delete the folder and fixes the issue
                resetImmutableFlag(directoryURL: temporaryFolderURL)
            }
            print("INFO: deleting folder \(temporaryFolderURL.lastPathComponent)")
            try FileManager.default.removeItem(at: temporaryFolderURL)
            print("INFO: folder \(temporaryFolderURL.lastPathComponent) deleted successfully")
            self.currentItemURL = nil
        } catch {
            errorDeletingItem(error: error as NSError, temporaryItemURL: temporaryFolderURL)
            return
        }
        
    }
    
    func errorDeletingItem(error: NSError, temporaryItemURL: URL) {
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
        
        
        if !FileManager.default.fileExists(atPath: subTemporaryFolderURL.path) {
            do {
                try FileManager.default.createDirectory(at: subTemporaryFolderURL, withIntermediateDirectories: true)
                print("INFO: MyTemporaryFolder created successfully")
            } catch {
                print("ERROR: could not create MyTemporaryFolder: \(error.localizedDescription)")
            }
        }
        
        let temporaryItemURL = subTemporaryFolderURL.appendingPathComponent(sourceItemURL.lastPathComponent)
        
        if FileManager.default.fileExists(atPath: temporaryItemURL.path) {
            print("WARNING: Temporary item already exists.")
            currentItemURL = temporaryItemURL
            return
        }
        
        print("INFO: Copying source item to temporary directory")
        do {
            let securityScoped = sourceItemURL.startAccessingSecurityScopedResource()
            try FileManager.default.copyItem(at: sourceItemURL, to: temporaryItemURL)
            print("INFO: Source item copied to temporary directory successfully")
            currentItemURL = temporaryItemURL
            if securityScoped {
                sourceItemURL.stopAccessingSecurityScopedResource()
            }
        } catch {
            print("ERROR: Could not copy source item to temporary directory: \(error)")
            return
        }
    }
}

