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
    
    private var formattingAttributes: CurrencyFormattingAttributes!
    private let maxAmount: Double = 10_000_000.00
    
    private let currencyFormatter = NumberFormatter()
    
    private var displayString: String = "" {
        didSet{
            if self.shouldShowCurrencySymbol && !self.displayString.contains(formattingAttributes.currencySymbol){
                self.textField.text = self.formattingAttributes.currencySymbolPositon == .Leading ? self.formattingAttributes.currencySymbol + " " + displayString : displayString + " " + self.formattingAttributes.currencySymbol
            }else{
                self.textField.text = displayString
            }
        }
    }
    
    @IBInspectable var defaultValue: Double = 0
    
    var font: UIFont?{
        didSet{
            self.setFont()
        }
    }
    
    var shouldShowCurrencySymbol = true {
        didSet{
            self.displayString = self.displayString + ""
        }
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        //initializing and setting up subviews
        self.setupSubviews()
        
        //Identifying Decimal & Group Separator from System Locale
        self.formattingAttributes = self.getCurrencyFormattingAttributesFromCurrentLocale()
        
        //Displaying default value with formatting
        let defaultValue = String(format: "%.2f", self.defaultValue)
        let parts = defaultValue.components(separatedBy: ".")
        var defaultDisplayString = defaultValue
        if let integerPart = parts.first{
            defaultDisplayString = self.getNumericIntValue(amountString: integerPart)!.inCurrencyFormatWithCurrencySymbol("")
        }
        
        //checking if default value has decimal part
        if parts.count == 2{
            if let decimalPart = parts.last{
                defaultDisplayString += self.formattingAttributes.decimalSeparator + decimalPart
            }
        }
        
        self.displayString = defaultDisplayString
        
        
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
    
    private func setFont(){
        guard let font = self.font else { return }
        self.textField.font = font
    }
    
    @IBAction func blockingViewTapped(sender: UITapGestureRecognizer){
        _ = self.textField.becomeFirstResponder()
    }
 
    func getCurrencyFormattingAttributesFromCurrentLocale() -> CurrencyFormattingAttributes {
        let currencyFormatter = NumberFormatter()
        currencyFormatter.usesGroupingSeparator = true
        currencyFormatter.numberStyle = .currency
        currencyFormatter.locale = Locale.current
        return CurrencyFormattingAttributes(groupingSeparator: currencyFormatter.currencyGroupingSeparator, groupingSize: currencyFormatter.groupingSize, decimalSeparator: currencyFormatter.currencyDecimalSeparator, currencySymbol: currencyFormatter.currencySymbol, currencySymbolPositon: .Leading)
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
        
        //removing formatting
        updatedText = updatedText.replacingOccurrences(of: self.formattingAttributes.currencySymbol, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        updatedText = updatedText.replacingOccurrences(of: self.formattingAttributes.groupingSeparator, with: "")
        
        if updatedText.isEmpty{
            self.displayString = ""
            return false
        }
        
        
        if let newAmount = getNumericDoubleValue(amountString: updatedText){
            if newAmount > self.maxAmount{
                return false
            }
        }
        
        //Checking if user is trying to enter "." (decimal point) multiple times.
        if currentText.contains(self.formattingAttributes.decimalSeparator) && string.elementsEqual(self.formattingAttributes.decimalSeparator){
            return false
        }
        
        //Checking if first char entered is a decimal point
        //if yes add "0" as prefix.
        if currentText.isEmpty && string.elementsEqual(self.formattingAttributes.decimalSeparator){
            self.displayString = "0" + self.formattingAttributes.decimalSeparator
            return false
        }
        
        //checking if user entered "." (decimal point)
        if updatedText.hasSuffix(self.formattingAttributes.decimalSeparator){
            return true
        }
        
        let parts = updatedText.components(separatedBy: self.formattingAttributes.decimalSeparator)
        
        var decimalPart : String?
        
        //Checking is user is entering the decimal part
        if parts.count == 2{
            decimalPart = parts.last
            if decimalPart!.count <= 2 {
                if let newAmount = getNumericDoubleValue(amountString: updatedText){
                    self.displayString = currentText.components(separatedBy: self.formattingAttributes.decimalSeparator).first! + self.formattingAttributes.decimalSeparator + String(newAmount).components(separatedBy: ".").last!
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
            displayStr += self.formattingAttributes.decimalSeparator + decimalPart
        }
        self.displayString = displayStr
        return false
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        guard let amountText = textField.text, !amountText.isEmpty else { return }
        
        //checking if last char was decimal separator
        //if yes, drop the decimal separator.
        if amountText.hasSuffix(self.formattingAttributes.decimalSeparator){
            if let integerPart = amountText.components(separatedBy: self.formattingAttributes.decimalSeparator).first{
                self.displayString = integerPart
            }
        }
        
    }
    
    
}

extension Int {
    
    func inCurrencyFormatWithCurrencySymbol(_ symbol: String) -> String {
        let currencyFormatter = NumberFormatter()
        currencyFormatter.usesGroupingSeparator = true
        currencyFormatter.numberStyle = .currency
        currencyFormatter.locale = Locale.current
        currencyFormatter.currencySymbol = symbol
        if let formattedString = currencyFormatter.string(from: NSNumber(value: self)){
            if let integerPart = formattedString.trimmingCharacters(in: .whitespaces).components(separatedBy: currencyFormatter.decimalSeparator).first{
                return integerPart
            }
        }
        return symbol + " 0"
    }
    
}


struct CurrencyFormattingAttributes {
    let groupingSeparator: String
    let groupingSize: Int
    let decimalSeparator: String
    let currencySymbol: String
    let currencySymbolPositon: CurrenySymbolPosition
}

enum CurrenySymbolPosition {
    case Leading
//    case Trailing
}
