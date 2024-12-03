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
    var latestErrorMessage : UILabel!
    
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
        
        // Create a UIScrollView for the error message label
        let errorScrollView = UIScrollView()
        errorScrollView.translatesAutoresizingMaskIntoConstraints = false
        
        // Create a container view for the error message inside the scroll view
        let errorContentView = UIView()
        errorContentView.translatesAutoresizingMaskIntoConstraints = false
        errorScrollView.addSubview(errorContentView)
        
        // Create a label for the error message
        let latestErrorMessage = UILabel()
        latestErrorMessage.text = ""
        latestErrorMessage.numberOfLines = 0
        latestErrorMessage.textAlignment = .left
        latestErrorMessage.translatesAutoresizingMaskIntoConstraints = false
        errorContentView.addSubview(latestErrorMessage)
        
        // Add views to the main view
        view.addSubview(instructionsLabel)
        view.addSubview(btnStackView)
        view.addSubview(errorScrollView)
        
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
            
            // Scroll view for the error message below the button stack view
            errorScrollView.topAnchor.constraint(equalTo: btnStackView.bottomAnchor, constant: 20),
            errorScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            errorScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            errorScrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            
            // Content view inside the scroll view
            errorContentView.topAnchor.constraint(equalTo: errorScrollView.topAnchor),
            errorContentView.leadingAnchor.constraint(equalTo: errorScrollView.leadingAnchor),
            errorContentView.trailingAnchor.constraint(equalTo: errorScrollView.trailingAnchor),
            errorContentView.bottomAnchor.constraint(equalTo: errorScrollView.bottomAnchor),
            errorContentView.widthAnchor.constraint(equalTo: errorScrollView.widthAnchor),
            
            // Error message label inside the content view
            latestErrorMessage.topAnchor.constraint(equalTo: errorContentView.topAnchor),
            latestErrorMessage.leadingAnchor.constraint(equalTo: errorContentView.leadingAnchor),
            latestErrorMessage.trailingAnchor.constraint(equalTo: errorContentView.trailingAnchor),
            latestErrorMessage.bottomAnchor.constraint(equalTo: errorContentView.bottomAnchor)
        ])
        
        // Store the delete button and latest error message for later use
        self.deleteFileButton = deleteFileButton
        self.latestErrorMessage = latestErrorMessage
    }

    @objc func openFile(_ sender: UIButton) {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.movie, .text, .pdf, .image])
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
            try FileManager.default.removeItem(at: currentItemURL)
            self.currentItemURL = nil
        } catch {
            errorDeletingFile(error: error as NSError, temporaryItemURL: currentItemURL)
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
        
        let temporaryItemURL = FileManager.default.temporaryDirectory.appendingPathComponent(sourceItemURL.lastPathComponent)
        
        if FileManager.default.fileExists(atPath: temporaryItemURL.path) {
            print("WARNING: Temporary item already exists.")
            currentItemURL = temporaryItemURL
            return
        }
        
        print("INFO: Trying to copy source item to temporary directory")
        do {
            let securityScoped = sourceItemURL.startAccessingSecurityScopedResource()
            try FileManager.default.copyItem(at: sourceItemURL, to: temporaryItemURL)
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

