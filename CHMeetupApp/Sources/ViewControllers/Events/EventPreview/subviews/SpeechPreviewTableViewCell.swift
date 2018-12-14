//
//  SpeechPreviewTableViewCell.swift
//  CHMeetupApp
//
//  Created by Maxim Globak on 17.03.17.
//  Copyright © 2017 CocoaHeads Community. All rights reserved.
//

import UIKit

class SpeechPreviewTableViewCell: PlateTableViewCell, TempalateView {

  var isTemplate: Bool = false {
    didSet {
      if oldValue == false && isTemplate == true {
        animateWithFade()
      }
    }
  }

  @IBOutlet var avatarImageView: UIImageView! {
    didSet {
      avatarImageView.roundCorners()
      avatarImageView.backgroundColor = UIColor(.lightGray)
    }
  }

  @IBOutlet var fullNameLabel: TemplatableLabel! {
    didSet {
      fullNameLabel.font = UIFont.appFont(.avenirNextDemiBold(size: 17))
      fullNameLabel.textColor = UIColor(.black)
    }
  }

  @IBOutlet var topicLabel: TemplatableLabel! {
    didSet {
      topicLabel.font = UIFont.appFont(.systemFont(size: 17))
      topicLabel.textColor = UIColor(.black)
    }
  }

  @IBOutlet var seporatorLineView: UIView! {
    didSet {
      seporatorLineView.backgroundColor = UIColor(.lightGray)
    }
  }

  @IBOutlet var speachDescriptionLabel: TemplatableLabel! {
    didSet {
      speachDescriptionLabel.font = UIFont.appFont(.systemFont(size: 15))
      speachDescriptionLabel.textColor = UIColor(.darkGray)
      speachDescriptionLabel.numberOfLines = 3
    }
  }

  override func awakeFromNib() {
    super.awakeFromNib()

    let traits = super.accessibilityTraits
    accessibilityTraits = UIAccessibilityTraits(rawValue: traits.rawValue | UIAccessibilityTraits.button.rawValue)

    roundType = .all
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    avatarImageView.roundCorners()
  }
}
