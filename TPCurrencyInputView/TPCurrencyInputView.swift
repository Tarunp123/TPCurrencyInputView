//
//  TPCurrencyInputView.swift
//  TPCurrencyInputView
//
//  Created by Tarun on 28/07/19.
//  Copyright © 2019 Tarun. All rights reserved.
//

import UIKit

class TPCurrencyInputView: UIView {

    private var textField: UITextField!
    private var transparentOverlay: UIView!
    
    private var groupingSeperator: String!
    private var decimalSeperator: String!
    private var groupingSize: Int = -1
    private let maxAmount: Double = 10_000_000.00
    
    private let currencyFormatter = NumberFormatter()
    
    @IBInspectable var defaultValue: Double = 0
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.setupSubviews()
        self.textField.text = "\(self.defaultValue)"
        
        let groupingSeperatorAndDecimalSeperator = self.getCurrencyGroupingSeperatorAndDecimalSeperator()
        self.groupingSeperator = groupingSeperatorAndDecimalSeperator.first
        if let size = Int(groupingSeperatorAndDecimalSeperator[1]){
            self.groupingSize = size
        }
        self.decimalSeperator = groupingSeperatorAndDecimalSeperator.last
    }
    
    private func setupSubviews(){
        //creating currency textfield
        self.textField = UITextField()
        self.textField.delegate = self
        self.textField.keyboardType = .decimalPad
        self.textField.isUserInteractionEnabled = true
        self.addSubview(self.textField)
        self.textField.translatesAutoresizingMaskIntoConstraints = false
        self.textField.leadingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leadingAnchor).isActive = true
        self.textField.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor).isActive = true
        self.textField.trailingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.trailingAnchor).isActive = true
        self.textField.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor).isActive = true
        
        //creating transparent overlay
        self.transparentOverlay = UIView()
        self.transparentOverlay.backgroundColor = .clear
        self.transparentOverlay.isUserInteractionEnabled = true
        self.addSubview(self.transparentOverlay)
        self.transparentOverlay.translatesAutoresizingMaskIntoConstraints = false
        self.transparentOverlay.leadingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leadingAnchor).isActive = true
        self.transparentOverlay.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor).isActive = true
        self.transparentOverlay.trailingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.trailingAnchor).isActive = true
        self.transparentOverlay.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor).isActive = true
        
        let tapGR = UITapGestureRecognizer(target: self, action: #selector(blockingViewTapped(sender:)))
        self.transparentOverlay.addGestureRecognizer(tapGR)
        
    }
    
    @IBAction func blockingViewTapped(sender: UITapGestureRecognizer){
        _ = self.textField.becomeFirstResponder()
    }
 
    func getCurrencyGroupingSeperatorAndDecimalSeperator() -> [String] {
        currencyFormatter.usesGroupingSeparator = true
        currencyFormatter.numberStyle = .currency
        currencyFormatter.locale = Locale.current
        return [currencyFormatter.currencyGroupingSeparator, String(currencyFormatter.groupingSize), currencyFormatter.currencyDecimalSeparator]
    }
    
    
    private func getNumericIntValue(amountString: String) -> Int?{
        currencyFormatter.usesGroupingSeparator = false
        currencyFormatter.currencySymbol = ""
        currencyFormatter.numberStyle = .currency
        currencyFormatter.locale = Locale.current
        if let finalNumber = currencyFormatter.number(from: amountString){
            return finalNumber.intValue
        }
        return nil
    }
    
    private func getNumericDoubleValue(amountString: String) -> Double?{
        currencyFormatter.usesGroupingSeparator = false
        currencyFormatter.currencySymbol = ""
        currencyFormatter.numberStyle = .currency
        currencyFormatter.locale = Locale.current
        if let finalNumber = currencyFormatter.number(from: amountString){
            return finalNumber.doubleValue
        }
        return nil
    }
    
}


extension TPCurrencyInputView: UITextFieldDelegate{
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return false }
        
        var updatedText = currentText.replacingCharacters(in: stringRange, with: string)
        
        if updatedText.isEmpty{
            textField.text = ""
            return false
        }
        
        //removing formatting
        updatedText = updatedText.replacingOccurrences(of: groupingSeperator, with: "")
        
        if let newAmount = getNumericDoubleValue(amountString: updatedText){
            if newAmount > self.maxAmount{
                return false
            }
        }
        
        //Checking if user is trying to enter "." (decimal point) multiple times.
        if currentText.contains(decimalSeperator) && string.elementsEqual(decimalSeperator){
            return false
        }
        
        //Checking if first char entered is a decimal point
        //if yes add "0" as prefix.
        if currentText.isEmpty && string.elementsEqual(decimalSeperator){
            textField.text = "0" + decimalSeperator
            return false
        }
        
        //checking if user entered "." (decimal point)
        if updatedText.hasSuffix(decimalSeperator){
            return true
        }
        
        let parts = updatedText.components(separatedBy: decimalSeperator)
        
        var decimalPart : String?
        
        //Checking is user is entering the decimal part
        if parts.count == 2{
            decimalPart = parts.last
            if decimalPart!.count <= 2 {
                if let newAmount = getNumericDoubleValue(amountString: updatedText){
                    textField.text = currentText.components(separatedBy: decimalSeperator).first! + decimalSeperator + String(newAmount).components(separatedBy: ".").last!
                    return false
                }
                return true
            }else{
                return false
            }
        }
        
        //user is entering the integer part
        let integerPart = parts.first!
        var displayStr = getNumericIntValue(amountString: integerPart)!.inCurrencyFormatWithCurrencySymbol("")
        if let decimalPart = decimalPart{
            displayStr += self.decimalSeperator + decimalPart
        }
        textField.text = displayStr
        return false
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        guard let amountText = textField.text, !amountText.isEmpty else { return }
        
        //checking if last char was decimal seperator
        //if yes, drop the decimal seperator.
        if amountText.hasSuffix(decimalSeperator){
            if let integerPart = amountText.components(separatedBy: decimalSeperator).first{
                textField.text = integerPart
            }
        }
        
    }
    
    
}

extension Int {
    
    func inCurrencyFormatWithCurrencySymbol(_ symbol: String) -> String {
        let currencySymbol = " " + symbol + " "
        let currencyFormatter = NumberFormatter()
        currencyFormatter.usesGroupingSeparator = true
        currencyFormatter.numberStyle = .currency
        currencyFormatter.locale = Locale.current
        currencyFormatter.currencySymbol = currencySymbol
        if let formattedString = currencyFormatter.string(from: NSNumber(value: self)){
            if let integerPart = formattedString.trimmingCharacters(in: .whitespaces).components(separatedBy: currencyFormatter.decimalSeparator).first{
                return integerPart
            }
        }
        return currencySymbol + " 0"
    }
    
}
