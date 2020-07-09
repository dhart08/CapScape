//
//  ViewController.swift
//  customViewTest
//
//  Created by David on 9/25/19.
//  Copyright © 2019 David Hartzog. All rights reserved.
//

import UIKit

class AttributeCell: UITableViewCell, UITextFieldDelegate {
    
    @IBOutlet weak var attributeLabel: UILabel!
    @IBOutlet weak var inputTextField: UITextField!
    @IBOutlet weak var deleteButton: UIButton!
    
    var attributeLabelClickHandler: (String) -> () = { _ in }
    var deleteButtonHandler: () -> () = {}
    var textInputHandler: () -> () = {}
    
    func initialize() {
        // add tap gesture recognizer to attributeLabel
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(attributeLabelClick))
        attributeLabel.addGestureRecognizer(gestureRecognizer)
        
        inputTextField.delegate = self
        
        
        
        //inputTextField.addTarget(self, action: #selector(inputTextChanged), for: UIControl.Event.editingChanged)
        
        //inputTextField.addTarget(self, action: #selector(textFieldReturnPressed), for: UIControl.Event.editingDidEnd)
    }
    
    @objc func attributeLabelClick(_ sender: UITapGestureRecognizer) {
        attributeLabelClickHandler(attributeLabel.text!)
    }
    
    @IBAction func deleteButtonClick(_ sender: Any) {
        deleteButtonHandler()
    }
    
//    @objc func inputTextChanged(sender: UITextField) {
//        //print("inputTextChanged()")
//        textInputHandler()
//    }
    
    @IBAction func inputTextFieldChanged(_ sender: UITextField) {
        textInputHandler()
        
        print("textInputHandler")
        
//        if let labelText = attributeLabel.text {
//            let settingsKey = "autocomplete_" + labelText
//
//            if let autocompleteList: [String] = UserDefaults.standard.array(forKey: settingsKey) as? [String] {
//
//                for str in autocompleteList {
//                    let inputText = inputTextField.text
//                    let len = inputTextField.text?.count
//                    if inputText == "\(str[...str.index(str.startIndex, offsetBy: len!)])" {
//                        inputTextField.text = str
//
//                        // select end of string here
//                        inputTextField.becomeFirstResponder()
//                        inputTextField.setMarkedText("hello", selectedRange: NSRange(location: len!, length: len!))
//                    }
//                }
//            }
//            else {
//                print("no autocomplete_\(labelText) found")
//            }
//        }
    }
    
    @IBAction func userTouched(_ sender: Any) {
        let selectedRange = inputTextField.selectedTextRange;
        let startPosition = selectedRange?.start
        let endPosition = selectedRange?.end
        
        print("selectedRange: \(selectedRange)", "\t\t\(startPosition)" , "\t\t\(endPosition)")
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        return true
    }
    
}

//-------------------------------------------------------

class AttributeViewController: UIViewController, UITableViewDataSource {
    
    @IBOutlet weak var okButton: UIBarButtonItem!
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    @IBOutlet weak var addButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    
    var storedAttributeKeyName = "AttributeKeyList"
    var tableDataKeys: [String] = []
    var tableDataValues: [String] = []
    var dataReturnHandler: (String?) -> () = { _ in }
    
    //var tableDataKeys: [String] = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"]
    //var tableDataValues: [String] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        //UserDefaults.standard.set([], forKey: storedAttributeKeyName)
        
        let storedAttributeKeyList = UserDefaults.standard.stringArray(forKey: storedAttributeKeyName)
        
        if storedAttributeKeyList != nil {
            tableDataKeys = storedAttributeKeyList!
            
            for _ in tableDataKeys {
                tableDataValues.append("")
            }
        }
        
        tableView.dataSource = self
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        UserDefaults.standard.set(tableDataKeys, forKey: storedAttributeKeyName)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        let info = notification.userInfo

        if let keyboardSize = (info?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {

            let newTableViewFrame = CGRect(x: tableView.frame.origin.x,
                                  y: tableView.frame.origin.y,
                                  width: tableView.frame.width,
                                  height: tableView.frame.height - keyboardSize.height)
            tableView.frame = newTableViewFrame
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        let info = notification.userInfo

        if let keyboardSize = (info?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            let newFrame = CGRect(x: tableView.frame.origin.x,
                                  y: tableView.frame.origin.y,
                                  width: tableView.frame.width,
                                  height: tableView.frame.height + keyboardSize.height)
            tableView.frame = newFrame
        }
    }
    
    @IBAction func okButtonClick(_ sender: Any) {
        if tableView.numberOfRows(inSection: 0) == 0 {
            dataReturnHandler(nil)
            dismiss(animated: true, completion: nil)
            return
        }
        
        func packageAttributesToJSON() -> String {
            
            var jsonString = "{\n"
            
            for i in 0...tableView.numberOfRows(inSection: 0) - 1 {
                let key = tableDataKeys[i]
                let value = tableDataValues[i]
                
                jsonString.append("\t\"\(key)\": \"\(value)\",\n")
            }
            
            jsonString = jsonString.trimmingCharacters(in: [",", "\n"])
            jsonString.append("\n}")
            
            return jsonString
        }
        
        let data = packageAttributesToJSON()
        
        dataReturnHandler(data)
        
//        for i in 0...tableView.numberOfRows(inSection: 0) - 1 {
//            let cell = tableView.cellForRow(at: IndexPath(row: i, section: 0)) as! AttributeCell
//            print("cell: \(cell.attributeLabel.text!)")
//        }
        
        for key in tableDataKeys {
            let storedKeyName = "autocomplete_\(key)"
            
            // if key info is already stored on device
            if let storedKeyValues = UserDefaults.standard.stringArray(forKey: storedKeyName) {
                print("\(storedKeyName) found!")
                
                if let idx = tableDataKeys.index(of: key) {
                    let value = tableDataValues[idx]
                    
                    if value != "" {
                        // if value already stored in array on device
                        if let _ = storedKeyValues.index(of: value) {
                            // do nothing
                        }
                        else {
                            var newStoredKeyValues = storedKeyValues
                            newStoredKeyValues.append(value)
                            
                            UserDefaults.standard.set(newStoredKeyValues, forKey: storedKeyName)
                            
                            print("value stored: \(value)")
                        }
                    }
                }
            }
                // key info is not stored on the device
            else {
                print("\(storedKeyName) not found")
                
                if let idx = tableDataKeys.index(of: key) {
                    let value = tableDataValues[idx]
                    
                    if value != "" {
                        let valuesArray: [String] = ["\(value)"]
                        
                        UserDefaults.standard.set(valuesArray, forKey: storedKeyName)
                        
                        print("add new key store: \(storedKeyName)")
                    }
                }
            }
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancelButtonClick(_ sender: Any) {
        dataReturnHandler(nil)
        dismiss(animated: true, completion: nil)
    }

    @IBAction func addButtonClick(_ sender: Any) {
        let alert = UIAlertController(title: "Add Attribute", message: "Enter the name of the new attribute:", preferredStyle: .alert)
        
        alert.addTextField(configurationHandler: nil)
        
        let addAction = UIAlertAction(title: "Add", style: .default) { _ in
            //add code to add new cell here
            
            let newAttribute = alert.textFields![0].text!
            
            if newAttribute != "" {
                
                //check for existing attribute
                if self.findCellIndexByAttribute(attribute: newAttribute) != -1 {
                    return
                }
                
                self.tableDataKeys.append(newAttribute)
                self.tableDataValues.append("")
                
                self.tableView.beginUpdates()
                self.tableView.insertRows(at: [IndexPath(row: self.tableDataKeys.count - 1, section: 0)], with: .automatic)
                self.tableView.endUpdates()
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(addAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
    
    func findCellIndexByAttribute(attribute: String) -> Int {
        var index = 0
        
        for key in tableDataKeys {
            if key == attribute {
                return index
            }
            
            index += 1
        }
        
        return -1
    }
    
    func deleteCellByIndex(index: Int) {
        tableDataKeys.remove(at: index)
        tableDataValues.remove(at: index)
        
        tableView.beginUpdates()
        tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
        tableView.endUpdates()
    }
    
    func deleteCellByAttribute(name: String) {
        let index = findCellIndexByAttribute(attribute: name)
        
        deleteCellByIndex(index: index)
    }
    
    func renameCellAttribute(oldAttribute: String?) {
        let alert = UIAlertController(title: "Rename Attribute", message: "Enter the new attribute name:", preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.placeholder = "Attribute"
            textField.text = oldAttribute
        }
        
        let okAction = UIAlertAction(title: "OK", style: .default) { (_) in
            //rename cell here
            let newAttribute = alert.textFields![0].text!
            let index = self.findCellIndexByAttribute(attribute: oldAttribute!)
            
            if newAttribute != "" && index != -1 {
                (self.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as! AttributeCell).attributeLabel.text = newAttribute
                
                self.tableDataKeys[index] = newAttribute
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
        
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: TableView Functions
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableDataKeys.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellReuseIdentifier", for: indexPath) as! AttributeCell
        
        cell.attributeLabel.text = (tableDataKeys[indexPath.row])
        cell.inputTextField.text = tableDataValues[indexPath.row]
        cell.initialize()
        cell.attributeLabelClickHandler = { attribute in
            self.renameCellAttribute(oldAttribute: attribute)
        }
        cell.deleteButtonHandler = { self.deleteCellByAttribute(name: cell.attributeLabel.text!) }
        cell.textInputHandler = {
            self.tableDataValues[indexPath.row] = cell.inputTextField.text!
        }
        
        return cell
    }
    
}
