# iOS 18.1.1 File Permission Bug Reproduction

This repository contains a sample project that demonstrates a bug in **iOS 18.1.1**. 

## Bug Description

The issue affects devices running **iOS 18.1.1** and pertains to the behavior of the `FileManager.default.copyItem(at:to:)` method. Specifically, the bug occurs when copying files into the app sandbox under the following conditions:

1. The source file is located in an **iCloud shared folder**.
2. The folder is **not owned by the user** but shared with **read-only permissions**.
3. The user attempts to copy the file to the app sandbox using the `copyItem(at:to:)` method.

### Observed Behavior
- When the file is copied to the app sandbox, the **permissions of the source file** in the iCloud shared folder are incorrectly propagated to the copied file.
- As a result, when attempting to delete the file in the app sandbox, the following error occurs:

  `NSCocoaErrorDomain, Code 513: "The file couldn’t be removed because you don’t have permission to access it."`

## How to Use the Sample App

### Prerequisites

- **iCloud Shared Folder**: You need access to an **iCloud shared folder** that:
  - Is owned by another iCloud user.
  - Has been shared with **read-only permissions**.
  - Contains at least one file (e.g., image, video, text, or PDF).

### Steps to Reproduce

1. Build and run the app on a device running **iOS 18.1.1**.
2. Tap **"Open File"** and select a file from the shared iCloud folder.
3. Tap **"Delete File"**.
4. Observe the error log, which will display the permission issue.

## Workaround

Until this issue is resolved in a future iOS update, you can bypass the problem by following this approach:

- Initialize the `UIDocumentPickerViewController` with the `asCopy: true` parameter:

  `UIDocumentPickerViewController(forOpeningContentTypes: contentTypes, asCopy: true)`

This ensures that files returned in the UIDocumentPickerDelegate have correct permission.
