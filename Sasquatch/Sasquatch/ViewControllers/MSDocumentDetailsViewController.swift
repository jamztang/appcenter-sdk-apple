// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import UIKit

class MSDocumentDetailsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
  var documentType: String?
  
  enum TimeToLiveMode: String {
    case Default = "Default"
    case NoCache = "NoCache"
    case TwoSeconds = "2 seconds"
    case Infinite = "Infinite"
    static let allValues = [Default, NoCache, TwoSeconds, Infinite]
  }
  var document: TestDocument?
  var writeOptions: MSWriteOptions?
  var documentId: String?
  var documentTimeToLive: String? = TimeToLiveMode.Default.rawValue
  var userDocumentAddPropertiesSection: EventPropertiesTableSection!
  let userType: String = MSStorageViewController.StorageType.User.rawValue
  var documentContent: MSDocumentWrapper<TestDocument>?
  private var kUserDocumentAddPropertiesSectionIndex: Int = 0
  private var timeToLiveModePicker: MSEnumPicker<TimeToLiveMode>?

  @IBOutlet weak var timeToLiveBoard: UILabel!
  @IBOutlet weak var backButton: UIButton!
  @IBOutlet weak var docIdField: UITextField!
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var timeToLiveField: UITextField!

  override func viewDidLoad() {
    super.viewDidLoad()
    docIdField.placeholder = "Please input an user document id"
    docIdField.text = documentId
    timeToLiveField.text = documentTimeToLive
    self.tableView.delegate = self
    self.tableView.dataSource = self
    self.tableView.setEditing(true, animated: false)
  }

  override func loadView() {
    super.loadView()
    if documentContent == nil || documentId == nil {
      docIdField.isEnabled = true
    }
    if documentContent != nil {
      timeToLiveField.isHidden = true
      timeToLiveBoard.isHidden = true
    }
    userDocumentAddPropertiesSection = EventPropertiesTableSection(tableSection: 0, tableView: self.tableView)
    self.timeToLiveModePicker = MSEnumPicker<TimeToLiveMode> (
      textField: self.timeToLiveField,
      allValues: TimeToLiveMode.allValues,
      onChange: { index in
        self.documentTimeToLive = TimeToLiveMode.allValues[index].rawValue
      }
    )
    self.timeToLiveField.delegate = self.timeToLiveModePicker
    self.timeToLiveField.text = self.timeToLiveField.text
    self.timeToLiveField.tintColor = UIColor.clear
  }

  @IBAction func backButtonClicked(_ sender: Any) {
    self.presentingViewController?.dismiss(animated: true, completion: nil)
  }

  func numberOfSections(in tableView: UITableView) -> Int {
    if documentType != userType {
      return 1
    } else if (documentId != nil && documentId!.isEmpty) {
      return 2
    }
    return 3
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if documentType == userType && section == kUserDocumentAddPropertiesSectionIndex {
      return userDocumentAddPropertiesSection.tableView(tableView, numberOfRowsInSection: section)
    } else if documentContent == nil {
      return 1
    } else if documentType == userType && section == 1 {
      return 0
    }
    return 4
  }

  func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    if documentType == userType && indexPath.section == kUserDocumentAddPropertiesSectionIndex {
      return userDocumentAddPropertiesSection.tableView(tableView, canEditRowAt:indexPath)
    } else if documentType == userType && (documentContent == nil){
      return true
    }
    return false
  }

  func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
    if documentType == userType && indexPath.section == kUserDocumentAddPropertiesSectionIndex {
      return userDocumentAddPropertiesSection.tableView(tableView, editingStyleForRowAt: indexPath)
    }
    return .none
  }

  func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    if documentType == userType && indexPath.section == kUserDocumentAddPropertiesSectionIndex {
      userDocumentAddPropertiesSection.tableView(tableView, commit: editingStyle, forRowAt: indexPath)
    }
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    if documentType == userType && indexPath.section == kUserDocumentAddPropertiesSectionIndex && userDocumentAddPropertiesSection.isInsertRow(indexPath) {
      self.tableView(tableView, commit: .insert, forRowAt: indexPath)
    }
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if documentType == userType && indexPath.section == kUserDocumentAddPropertiesSectionIndex {
      return userDocumentAddPropertiesSection.tableView(tableView, cellForRowAt:indexPath)
    } else if documentContent != nil {
      let cell = tableView.dequeueReusableCell(withIdentifier: "property", for: indexPath)
      var cellText = ""
      switch indexPath.row {
        case 0:
          cellText = "Document ID: " + (String(describing:documentContent?.documentId))
        break
        case 1:
          cellText = "Partion: " + (String(describing:documentContent?.lastUpdatedDate))
        break
        case 2:
          cellText = "Date: " + (String(describing:documentContent?.lastUpdatedDate))
        break
        case 3:
          cellText = "Document content: " + (String(describing:documentContent?.jsonValue))
        break
      default:
        cellText = "nil"
      }
      cell.textLabel?.text = cellText
      return cell
    } else {
      let cell = tableView.dequeueReusableCell(withIdentifier: "property", for: indexPath)
      return cell
    }
  }
  
  func convertTimeToLiveConstantToValue(_ constValue : String) -> Int {
    switch constValue {
      case TimeToLiveMode.Infinite.rawValue:
      return -1
      case TimeToLiveMode.NoCache.rawValue:
      return 0
      case TimeToLiveMode.TwoSeconds.rawValue:
      return 2000
    default:
      return 60 * 60 * 24
    }
  }
  
  func prepareToSaveFile() {
    var prop = [AnyHashable: Any]()
    if !((docIdField.text?.isEmpty)!) {
      documentId = docIdField.text
      let docProperties = userDocumentAddPropertiesSection.typedProperties
      for property in docProperties {
        switch property.type {
        case .String:
          prop[property.value as! String] = property.key
        case .Double:
          prop[property.value as! Double] = property.key
        case .Long:
          prop[property.value as! Int64] = property.key
        case .Boolean:
          prop[property.value as! Bool] = property.key
        case .DateTime:
          prop[property.value as! Date] = property.key
        }
      }
    }
    self.document = TestDocument.init(from: prop)
    self.writeOptions = MSWriteOptions.init(deviceTimeToLive:self.convertTimeToLiveConstantToValue(self.documentTimeToLive!))
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?)  {
    if segue.identifier == "SaveDocument" {
      prepareToSaveFile()
    }
  }
}
