//
//  RegistrationFormDataCollection.swift
//  CHMeetupApp
//
//  Created by Maxim Globak on 05.03.17.
//  Copyright © 2017 CocoaHeads Community. All rights reserved.
//

import UIKit

protocol FormDisplayCollectionDelegate: class {
  func formDisplayRequestTo(selectItemsAt selectionIndexPaths: [IndexPath],
                            deselectItemsAt deselectIndexPaths: [IndexPath])
  func formDisplayRequestCell(at indexPath: IndexPath) -> UITableViewCell?
  func formDisplayRequestTouchGeuster(enable: Bool)
}

final class FormDisplayCollection: NSObject, DisplayCollection, DisplayCollectionAction {
  static var modelsForRegistration: [CellViewAnyModelType.Type] {
    return [OptionTableViewCellModel.self, TextFieldPlateTableViewCellModel.self]
  }

  init(formData: FormData? = nil) {
    self.formData = formData
  }

  var formData: FormData!
  weak var delegate: FormDisplayCollectionDelegate?
  weak var displayCollectionWithTableViewDelegate: DisplayCollectionWithTableViewDelegate?

  var numberOfSections: Int {
    return formData?.sections.count ?? 0
  }

  func numberOfRows(in section: Int) -> Int {
    return formData.sections[section].fieldAnswers.count
  }

  func model(for indexPath: IndexPath) -> CellViewAnyModelType {
    let section = formData.sections[indexPath.section]
    let answerCell = section.fieldAnswers[indexPath.row]
    let (boolAnswer, stringAnswer) = answerCell.answer.parseAnswers()
    switch section.type {
    case .checkbox:
      return OptionTableViewCellModel(id: answerCell.id, text: answerCell.value, type: .checkbox, result: boolAnswer)
    case .radio:
      return OptionTableViewCellModel(id: answerCell.id, text: answerCell.value, type: .radio, result: boolAnswer)
    case .string:
      return TextFieldPlateTableViewCellModel(value: stringAnswer,
                                              placeholder: answerCell.value,
                                              textFieldDelegate: self,
                                              valueChanged: { [weak answerCell] value in
                                                answerCell?.answer = .string(value: value)
                                                self.delegate?.formDisplayRequestTouchGeuster(enable: true)
      })
    }
  }

  func headerHeight(for section: Int) -> CGFloat {
    guard let delegate = displayCollectionWithTableViewDelegate else {
      assertionFailure("Subscribe to this delegate")
      return 0
    }
    let insets = DefaultTableHeaderView.titleInsets
    let attributedTitle = headerTitle(for: section)
    let width = delegate.getTableViewSize().width - insets.left - insets.right
    let height = TextFrameAttributes(attributedString: attributedTitle, width: width).textHeight
    return height + insets.top + insets.bottom
  }

  func headerTitle(for section: Int) -> NSAttributedString {
    let cell = formData.sections[section]
    let attributes = [NSAttributedString.Key.font: DefaultTableHeaderView.font]
    let attributtedString = NSMutableAttributedString(string: cell.name, attributes: attributes)
    let char = "*"
    if cell.isRequired {
      let mutableAttributedString = NSMutableAttributedString(string: char)
      mutableAttributedString.addAttribute(.foregroundColor,
                                           value: UIColor(.red), range: NSRange(location: 0, length: 1))
      attributtedString.append(mutableAttributedString)
    }
    return attributtedString
  }

  func didSelect(indexPath: IndexPath) {
    let section = formData.sections[indexPath.section]
    let answerCell = section.fieldAnswers[indexPath.row]
    let (boolAnswer, _) = answerCell.answer.parseAnswers()
    switch section.type {
    case .checkbox:
      answerCell.answer = .selection(isSelected: !boolAnswer)
      processCheckbox(at: indexPath, with: boolAnswer)
    case .radio:
      answerCell.answer = .selection(isSelected: !boolAnswer)
      processRadio(at: indexPath, with: !boolAnswer)
    case .string:
      delegate?.formDisplayRequestTo(selectItemsAt: [], deselectItemsAt: [indexPath])
      let cell = delegate?.formDisplayRequestCell(at: indexPath)
      if let cell = cell as? TextFieldPlateTableViewCell {
        cell.textField.becomeFirstResponder()
      }
    }
  }

  private func processCheckbox(at indexPath: IndexPath, with value: Bool) {
    if value {
      delegate?.formDisplayRequestTo(selectItemsAt: [], deselectItemsAt: [indexPath])
    } else {
      delegate?.formDisplayRequestTo(selectItemsAt: [indexPath], deselectItemsAt: [])
    }
  }

  private func processRadio(at indexPath: IndexPath, with value: Bool) {
    var deselectIndex: Int?

    for (index, value) in formData.sections[indexPath.section].fieldAnswers.enumerated() {
      let result = value.answer.parseAnswers().boolValue
      if result == true, index != indexPath.row {
        deselectIndex = index
        value.answer = .selection(isSelected: false)
      }
    }

    var deselectIndexPaths: [IndexPath] = []
    var selectedIndexPath: [IndexPath] = []
    if let index = deselectIndex {
      deselectIndexPaths.append(IndexPath(row: index, section: indexPath.section))
    }

    if value == true {
      selectedIndexPath.append(indexPath)
    } else {
      deselectIndexPaths.append(indexPath)
    }

    delegate?.formDisplayRequestTo(selectItemsAt: selectedIndexPath, deselectItemsAt: deselectIndexPaths)
  }

  var isFormLoaded: Bool {
    return formData != nil
  }

  var failedSection: Int? {
    for (index, section) in formData.sections.enumerated() where section.isRequired {
      var checked = false
      for row in section.fieldAnswers {
        checked = row.answer.parseAnswers().boolValue || row.answer.parseAnswers().stringValue.count > 0
        if checked { break }
      }
      if !checked {
        return index
      }
    }
    return nil
  }

}

extension FormDisplayCollection: UITextFieldDelegate {
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    return true
  }

  func textFieldDidBeginEditing(_ textField: UITextField) {
    delegate?.formDisplayRequestTouchGeuster(enable: true)
  }

  func textFieldDidEndEditing(_ textField: UITextField) {
    delegate?.formDisplayRequestTouchGeuster(enable: false)
  }
}
