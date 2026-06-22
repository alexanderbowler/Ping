import SwiftUI
import ContactsUI

struct ContactPickerRepresentable: UIViewControllerRepresentable {
    @Binding var selectedName: String
    @Binding var selectedPhone: String
    @Binding var selectedEmail: String
    @Binding var selectedCompany: String
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIViewController {
        let wrapper = UIViewController()
        wrapper.view.backgroundColor = .clear
        return wrapper
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if uiViewController.presentedViewController == nil {
            let picker = CNContactPickerViewController()
            picker.delegate = context.coordinator
            DispatchQueue.main.async {
                uiViewController.present(picker, animated: true)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, CNContactPickerDelegate {
        let parent: ContactPickerRepresentable

        init(_ parent: ContactPickerRepresentable) {
            self.parent = parent
        }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            let name = [contact.givenName, contact.familyName]
                .filter { !$0.isEmpty }
                .joined(separator: " ")
            parent.selectedName = name

            if let phone = contact.phoneNumbers.first?.value.stringValue {
                parent.selectedPhone = phone
            }

            if let email = contact.emailAddresses.first?.value as String? {
                parent.selectedEmail = email
            }

            if !contact.organizationName.isEmpty {
                parent.selectedCompany = contact.organizationName
            }

            parent.dismiss()
        }

        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            parent.dismiss()
        }
    }
}
