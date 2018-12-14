//
//  ProfileEditDisplayCollection.swift
//  CHMeetupApp
//
//  Created by Kirill Averyanov on 18/04/2017.
//  Copyright © 2017 CocoaHeads Community. All rights reserved.
//

import UIKit
import SVProgressHUD

class ProfileEditDisplayCollection: NSObject, DisplayCollection {
  var canSkip: Bool

  init(canSkip: Bool = true) {
    self.canSkip = canSkip
  }

  class EditableField {
    var value: String
    var title: String
    var isValid: (String) -> Bool
    var save: (String) -> Void

    init(value: String?, title: String, isValid: @escaping (String) -> Bool, save: @escaping (String) -> Void) {
      self.value = value ?? ""
      self.title = title
      self.isValid = isValid
      self.save = save
    }
  }

  static var modelsForRegistration: [CellViewAnyModelType.Type] {
    return [ChooseProfilePhotoTableViewCellModel.self,
            AlertHeaderTableViewCellModel.self,
            EditableLabelTableViewModel.self]
  }

  enum `Type` {
    case userHeader
    case userEditableField
    case info
  }

  fileprivate var photoCell: ChooseProfilePhotoTableViewCell!
  fileprivate var sections: [Type] = [.userHeader, .userEditableField]

  var user: UserEntity! {
    didSet {
      var editableFields: [EditableField] = []

      let name = EditableField(value: user.name, title: "Имя".localized, isValid: { name -> Bool in
        return name.count > 1
      }, save: { [weak self] value in
        realmWrite {
          self?.user.name = value
          self?.user.statusValue = UserEntity.UserStatus.complete.rawValue
        }
      })

      let lastname = EditableField(value: user.lastName, title: "Фамилия".localized, isValid: { lastname -> Bool in
        return lastname.count > 1
      }, save: { [weak self] value in
        realmWrite {
          self?.user.lastName = value
        }
      })

      let phone = EditableField(value: user.phone, title: "Телефон".localized, isValid: { phone -> Bool in
        return true
        // Right now we don't want to check phone because there are couple of format 
        // reasons for this (users can copy +7 (926)...)
        // return StringValidation.isValid(string: phone, type: .phone)
      }, save: { [weak self] value in
        realmWrite {
          self?.user.phone = value
        }
      })

      let email = EditableField(value: user.email, title: "Email".localized, isValid: { email -> Bool in
        return StringValidation.isValid(string: email, type: .mail)
      }, save: { [weak self] value in
        realmWrite {
          self?.user.email = value
        }
      })

      let company = EditableField(value: user.company, title: "Компания".localized, isValid: { _ -> Bool in
        return true
      }, save: { [weak self] value in
        realmWrite {
          self?.user.company = value
        }
      })

      let position = EditableField(value: user.position, title: "Позиция".localized, isValid: { _ -> Bool in
        return true
      }, save: { [weak self] value in
        realmWrite {
          self?.user.position = value
        }
      })

      editableFields.append(name)
      editableFields.append(lastname)
      editableFields.append(phone)
      editableFields.append(email)
      editableFields.append(company)
      editableFields.append(position)
      self.editableFields = editableFields

      sections = [.userHeader]

      if !canSkip {
        sections = [.info]
      } else {
        sections = [.userHeader]
      }

      sections += Array(repeating: .userEditableField, count: editableFields.count)
    }
  }

  var editableFields: [EditableField]!

  weak var delegate: ProfileHierarhyViewControllerType?

  var numberOfSections: Int {
    return sections.count
  }

  func numberOfRows(in section: Int) -> Int {
    switch sections[section] {
    case .userHeader, .info, .userEditableField:
      return 1
    }
  }

  func model(for indexPath: IndexPath) -> CellViewAnyModelType {
    switch sections[indexPath.section] {
    case .userHeader:
      return ChooseProfilePhotoTableViewCellModel(userEntity: user, delegate: self)
    case .info:
      // swiftlint:disable:next line_length
      return AlertHeaderTableViewCellModel(alertType: .warning, message: "Для вашего профиля не хватает одного или нескольких обязательных полей. Пожалуйста, введите корректную информацию, чтобы мы могли добавить вас в список гостей.".localized)
    case .userEditableField:
      guard let firstIndex = sections.index(of: .userEditableField) else {
        fatalError("No index for current section")
      }
      let field = editableFields[indexPath.section - firstIndex]
      return EditableLabelTableViewModel(description: field.value,
                                         placeholder: field.title,
                                         textFieldDelegate: self,
                                         valueChanged: { changedValue in
                                          field.value = changedValue
      })
    }
  }

}

extension ProfileEditDisplayCollection: ChooseProfilePhotoTableViewCellDelegate {
  func chooseProfilePhotoCellDidPressOnPhoto(_ cell: ChooseProfilePhotoTableViewCell) {
    photoCell = cell
    let viewController = delegate?.getViewController()
    if let viewController = viewController as? ProfileEditViewController {
      PermissionsManager.requireAccess(from: viewController, to: .photosLibrary,
                                       completion: { _ in
                                        ImagePickerController.showImagePicker(on: viewController)
      })
    }
  }

  func didReciveMedia(_ picker: UIImagePickerController, info: [UIImagePickerController.InfoKey: Any]) {
    if let image = info[.editedImage] as? UIImage {
      changeCheckedImage(image: image)
    }
    picker.dismiss(animated: true, completion: nil)
  }

  func changeCheckedImage(image: UIImage) {
    // TODO: - Give ability to cancel request
    let data = image.pngData()
    if let data = data {
      let updateRequest = RequestPlainObject.Requests.updatePhoto(photo: data)
      SVProgressHUD.show()
      Server.standard.request(updateRequest) { response, _ in
        if let success = response?.success, success == true {
          let token = (UserPreferencesEntity.value.currentUser?.token)!
          ProfileController.updateUser(withToken: token, completion: { _ in })
          self.photoCell.mainButton.photoImageView?.image = image
        }
        SVProgressHUD.dismiss()
      }
    } else {
      assertionFailure("Image can't be parsed to data")
    }
  }

  func headerHeight(for section: Int) -> CGFloat {
    switch sections[section] {
    case .userEditableField:
      return 40
    case .userHeader, .info:
      return UITableView.automaticDimension
    }
  }

  func height(for indexPath: IndexPath) -> CGFloat {
    switch sections[indexPath.section] {
    case .userHeader:
      return 166.0
    case .info, .userEditableField:
      return UITableView.automaticDimension
    }
  }

  func headerTitle(for section: Int) -> String {
    switch sections[section] {
    case .userHeader, .info:
      return ""
    case .userEditableField:
      guard let firstIndex = sections.index(of: .userEditableField) else {
        fatalError("No index for current section")
      }
      let index = section - firstIndex
      return editableFields[index].title
    }
  }
}

extension ProfileEditDisplayCollection: UITextFieldDelegate {
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    return true
  }
}

extension ProfileEditDisplayCollection {

  var failedField: IndexPath? {
    for (index, field) in editableFields.enumerated() {
      if !field.isValid(field.value) {
        guard let firstIndex = sections.index(of: .userEditableField) else {
          fatalError("No index for current section")
        }
        return IndexPath(row: 0, section: firstIndex + index)
      }
    }
    return nil
  }

  func update() {
    for field in editableFields {
      if field.isValid(field.value) {
        field.save(field.value)
      }
    }
  }
}
